"""User administration and the audit trail (successor to PASSFYL.PRG)."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from .. import db, security
from ..deps import check_version, clean, current_user, paged_response, paging, require

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/roles")
def roles(_user: dict = Depends(current_user)) -> list[dict]:
    return [{"name": name, "label": role["label"], "legacy": role["legacy"],
             "permissions": role["permissions"]}
            for name, role in security.ROLES.items()]


@router.get("/users")
def list_users(_user: dict = Depends(require("admin:users"))) -> list[dict]:
    return db.query(
        "SELECT id, username, full_name, role, is_active, must_change_password, "
        "legacy_access_code, created_at, last_login, version FROM users "
        "ORDER BY username")


@router.post("/users", status_code=201)
def create_user(payload: dict, user: dict = Depends(require("admin:users"))) -> dict:
    username = clean(payload.get("username"), upper=True)
    password = str(payload.get("password") or "")
    role = clean(payload.get("role")) or "viewer"

    if not username:
        raise HTTPException(status_code=400, detail="Enter a user name.")
    if len(password) < 8:
        raise HTTPException(status_code=400,
                            detail="The password must be at least 8 characters.")
    if role not in security.ROLES:
        raise HTTPException(status_code=400, detail=f"Unknown role {role!r}.")

    with db.transaction() as conn:
        if conn.execute("SELECT 1 FROM users WHERE username = ?", (username,)).fetchone():
            raise HTTPException(status_code=409, detail=f"{username} already exists.")
        cursor = conn.execute(
            "INSERT INTO users(username, password_hash, full_name, role, is_active,"
            " must_change_password, created_at) VALUES (?,?,?,?,?,1,?)",
            (username, security.hash_password(password), clean(payload.get("full_name")),
             role, 1 if payload.get("is_active", True) else 0, db.now()))
        db.audit(conn, user["username"], "create", "user", username, f"role={role}")
        new_id = cursor.lastrowid
    return db.query_one(
        "SELECT id, username, full_name, role, is_active, must_change_password, "
        "created_at, version FROM users WHERE id = ?", (new_id,))


@router.put("/users/{user_id}")
def update_user(user_id: int, payload: dict,
                user: dict = Depends(require("admin:users"))) -> dict:
    role = clean(payload.get("role")) or "viewer"
    if role not in security.ROLES:
        raise HTTPException(status_code=400, detail=f"Unknown role {role!r}.")
    is_active = 1 if payload.get("is_active", True) else 0

    with db.transaction() as conn:
        row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="No such user.")
        check_version(row, payload.get("version"), "user")

        # Never let the last administrator be demoted or switched off.
        if row["role"] == "admin" and (role != "admin" or not is_active):
            remaining = db.scalar(
                "SELECT COUNT(*) FROM users WHERE role = 'admin' AND is_active = 1 "
                "AND id <> ?", (user_id,), 0)
            if not remaining:
                raise HTTPException(
                    status_code=400,
                    detail="This is the last active administrator. Promote another "
                           "user first.")

        conn.execute(
            "UPDATE users SET full_name = ?, role = ?, is_active = ?, "
            "version = version + 1 WHERE id = ?",
            (clean(payload.get("full_name")), role, is_active, user_id))
        if not is_active:
            conn.execute("DELETE FROM sessions WHERE user_id = ?", (user_id,))
        db.audit(conn, user["username"], "update", "user", row["username"],
                 f"role={role} active={is_active}")

    return db.query_one(
        "SELECT id, username, full_name, role, is_active, must_change_password, "
        "created_at, last_login, version FROM users WHERE id = ?", (user_id,))


@router.post("/users/{user_id}/reset-password")
def reset_password(user_id: int, payload: dict,
                   user: dict = Depends(require("admin:users"))) -> dict:
    password = str(payload.get("password") or "")
    if len(password) < 8:
        raise HTTPException(status_code=400,
                            detail="The password must be at least 8 characters.")
    with db.transaction() as conn:
        row = conn.execute("SELECT username FROM users WHERE id = ?", (user_id,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="No such user.")
        conn.execute(
            "UPDATE users SET password_hash = ?, must_change_password = 1, "
            "version = version + 1 WHERE id = ?",
            (security.hash_password(password), user_id))
        conn.execute("DELETE FROM sessions WHERE user_id = ?", (user_id,))
        db.audit(conn, user["username"], "reset-password", "user", row["username"])
    return {"ok": True, "username": row["username"]}


@router.get("/sessions")
def active_sessions(_user: dict = Depends(require("admin:users"))) -> list[dict]:
    """Who is signed in right now - the multi-user view the DOS system never had."""
    return db.query(
        "SELECT u.username, u.full_name, u.role, s.created_at, s.expires_at, s.ip "
        "FROM sessions s JOIN users u ON u.id = s.user_id "
        "WHERE s.expires_at > ? ORDER BY s.created_at DESC", (db.now(),))


@router.get("/audit")
def audit_trail(entity: str = "", username: str = "", action: str = "",
                page: int = 1, page_size: int = 100,
                _user: dict = Depends(require("admin:users"))) -> dict:
    where: list[str] = []
    params: list = []
    if entity:
        where.append("entity = ?")
        params.append(entity)
    if username:
        where.append("username = ?")
        params.append(username.upper())
    if action:
        where.append("action = ?")
        params.append(action)
    clause = f"WHERE {' AND '.join(where)}" if where else ""

    page, page_size = paging(page, page_size)
    total = db.scalar(f"SELECT COUNT(*) FROM audit_log {clause}", params, 0)
    rows = db.query(
        f"SELECT * FROM audit_log {clause} ORDER BY id DESC LIMIT ? OFFSET ?",
        params + [page_size, (page - 1) * page_size])
    return paged_response(rows, total, page, page_size)


@router.get("/stats")
def stats(_user: dict = Depends(require("admin:users"))) -> dict:
    tables = ["users", "customers", "suppliers", "stock", "invoices", "invoice_lines",
              "purchases", "sales_returns", "collections", "collection_applications",
              "stock_moves", "audit_log"]
    return {"rows": {name: db.scalar(f"SELECT COUNT(*) FROM {name}", (), 0)
                     for name in tables}}
