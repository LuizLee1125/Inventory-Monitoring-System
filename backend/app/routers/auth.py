"""Sign in, sign out, and the current session."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request, Response

from .. import config, db, security
from ..deps import clean, current_user

router = APIRouter(tags=["auth"])


@router.post("/login")
def login(payload: dict, request: Request, response: Response) -> dict:
    username = clean(payload.get("username"), upper=True)
    password = str(payload.get("password") or "")
    if not username or not password:
        raise HTTPException(status_code=400, detail="Enter a user name and password.")

    row = db.query_one(
        "SELECT id, username, password_hash, full_name, role, is_active, "
        "must_change_password FROM users WHERE username = ?", (username,))

    # Same message either way, so the form cannot be used to enumerate users.
    if row is None or not security.password_matches(password, row):
        raise HTTPException(status_code=401, detail="User name or password is incorrect.")
    if not row["is_active"]:
        raise HTTPException(status_code=403, detail="This account has been disabled.")

    client = request.client.host if request.client else ""
    token, expires = security.create_session(
        row["id"], client, request.headers.get("user-agent", ""))

    with db.transaction() as conn:
        conn.execute("UPDATE users SET last_login = ? WHERE id = ?", (db.now(), row["id"]))
        db.audit(conn, row["username"], "login", "session", detail=client)

    response.set_cookie(
        config.SESSION_COOKIE, token,
        max_age=config.SESSION_HOURS * 3600,
        httponly=True, samesite="lax", path="/",
    )
    return {
        "username": row["username"],
        "full_name": row["full_name"],
        "role": row["role"],
        "permissions": security.permissions_for(row["role"]),
        "must_change_password": bool(row["must_change_password"]),
        "expires_at": expires,
    }


@router.post("/logout")
def logout(request: Request, response: Response) -> dict:
    token = request.cookies.get(config.SESSION_COOKIE, "")
    if token:
        user = security.resolve_session(token)
        security.destroy_session(token)
        if user:
            with db.transaction() as conn:
                db.audit(conn, user["username"], "logout", "session")
    response.delete_cookie(config.SESSION_COOKIE, path="/")
    return {"ok": True}


@router.get("/me")
def me(user: dict = Depends(current_user)) -> dict:
    # The settings screen shows when the account was opened and when it was last
    # used. `resolve_session` deliberately does not carry those: it runs on every
    # request, and this is the one endpoint that wants them.
    detail = db.query_one(
        "SELECT created_at, last_login, legacy_access_code FROM users WHERE id = ?",
        (user["id"],)) or {}

    return {
        "username": user["username"],
        "full_name": user["full_name"],
        "role": user["role"],
        "permissions": user["permissions"],
        "must_change_password": bool(user["must_change_password"]),
        "created_at": detail.get("created_at"),
        "last_login": detail.get("last_login"),
        "legacy_access_code": detail.get("legacy_access_code"),
    }


@router.post("/change-password")
def change_password(payload: dict, user: dict = Depends(current_user)) -> dict:
    current = str(payload.get("current_password") or "")
    new = str(payload.get("new_password") or "")
    if len(new) < 8:
        raise HTTPException(status_code=400,
                            detail="The new password must be at least 8 characters.")

    row = db.query_one("SELECT password_hash FROM users WHERE id = ?", (user["id"],))
    if not security.verify_password(current, row["password_hash"]):
        raise HTTPException(status_code=400, detail="Your current password is incorrect.")

    with db.transaction() as conn:
        conn.execute(
            "UPDATE users SET password_hash = ?, must_change_password = 0, "
            "version = version + 1 WHERE id = ?",
            (security.hash_password(new), user["id"]))
        db.audit(conn, user["username"], "change-password", "user", str(user["id"]))
    return {"ok": True}
