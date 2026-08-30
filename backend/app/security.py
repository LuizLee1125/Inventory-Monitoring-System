"""Passwords, sessions and the permission matrix.

The legacy system stored passwords in plaintext and expressed authorisation as
a single ACCESMNU field naming the menu a user was allowed to open. That is
replaced here by salted PBKDF2-SHA256 hashes and an explicit role/permission
matrix, while keeping the original access codes recorded for traceability.
"""

from __future__ import annotations

import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

from . import config, db

# --------------------------------------------------------------------------- #
# passwords
# --------------------------------------------------------------------------- #

def hash_password(password: str, *, rounds: int | None = None) -> str:
    """Return 'pbkdf2_sha256$rounds$salt$hash'."""
    rounds = rounds or config.PBKDF2_ROUNDS
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"),
                                 salt.encode("ascii"), rounds)
    return f"pbkdf2_sha256${rounds}${salt}${digest.hex()}"


def password_matches(password: str, user_row) -> bool:
    """Check a typed password against a stored hash.

    Normally an exact, case-sensitive comparison. There is one narrow
    exception: the DOS login screen upper-cased every keystroke
    (`mpass = mpass + UPPER(CHR(i))` in PASSWORD.PRG), so nobody who used the
    old system ever had to think about case, and every migrated password is
    stored upper-case. An account that has not yet chosen a new password is
    therefore also allowed to match on the upper-cased form.

    The moment the user sets their own password, `must_change_password` clears
    and this concession disappears with it.
    """
    stored = user_row["password_hash"]
    if verify_password(password, stored):
        return True
    if user_row["must_change_password"] and password != password.upper():
        return verify_password(password.upper(), stored)
    return False


def verify_password(password: str, stored: str) -> bool:
    try:
        algorithm, rounds, salt, expected = stored.split("$")
        if algorithm != "pbkdf2_sha256":
            return False
        digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"),
                                     salt.encode("ascii"), int(rounds))
        return hmac.compare_digest(digest.hex(), expected)
    except (ValueError, AttributeError):
        return False


# --------------------------------------------------------------------------- #
# roles and permissions
# --------------------------------------------------------------------------- #

PERMISSIONS = [
    "stock:read", "stock:write",
    "customer:read", "customer:write",
    "supplier:read", "supplier:write",
    "invoice:read", "invoice:write",
    "purchase:read", "purchase:write",
    "return:read", "return:write",
    "collection:read", "collection:write",
    "report:read",
    "admin:users",
    "maintenance:run",
]

_READ_ONLY = [p for p in PERMISSIONS if p.endswith(":read")]

ROLES: dict[str, dict] = {
    "admin": {
        "label": "Administrator",
        "legacy": "H - Main Menu",
        "permissions": list(PERMISSIONS),
    },
    "manager": {
        "label": "Manager",
        "legacy": "E - Inventory System",
        "permissions": [p for p in PERMISSIONS if p != "admin:users"],
    },
    "inventory": {
        "label": "Inventory / Purchasing",
        "legacy": "D, J - Inventory Monitoring",
        "permissions": _READ_ONLY + ["stock:write", "supplier:write", "purchase:write"],
    },
    "invoicing": {
        "label": "Invoicing",
        "legacy": "C, I - Invoicing System",
        "permissions": _READ_ONLY + ["invoice:write", "customer:write", "return:write"],
    },
    "ar": {
        "label": "Accounts Receivable",
        "legacy": "G - Accounts Receivable",
        "permissions": _READ_ONLY + ["collection:write"],
    },
    "sales": {
        "label": "Sales",
        "legacy": "A, B - Sales Order / Monitoring",
        "permissions": ["stock:read", "customer:read", "invoice:read", "report:read"],
    },
    "viewer": {
        "label": "Read only",
        "legacy": "-",
        "permissions": list(_READ_ONLY),
    },
}

# Most to least privileged. The DOS system gave one person several PASSFYL
# rows - one per access code, each with its own password - so a migrated
# account has to collapse to a single role: the widest one they held.
ROLE_RANK = {
    "admin": 7,
    "manager": 6,
    "inventory": 5,
    "invoicing": 4,
    "ar": 3,
    "sales": 2,
    "viewer": 1,
}

# Legacy ACCESMNU value -> new role.
LEGACY_MENU_TO_ROLE = {
    "MNUMAIN": "admin",
    "MNUINVS": "manager",
    "MNUINV2": "inventory",
    "MNUINVM": "inventory",
    "MNUNVCS": "invoicing",
    "MNUSO2": "invoicing",
    "MNUSO": "sales",
    "MNUSIM": "sales",
    "MNUAR": "ar",
    "MNUXPENS": "viewer",
}


def permissions_for(role: str) -> list[str]:
    return ROLES.get(role, ROLES["viewer"])["permissions"]


def has_permission(role: str, permission: str) -> bool:
    return permission in permissions_for(role)


# --------------------------------------------------------------------------- #
# sessions
# --------------------------------------------------------------------------- #

def create_session(user_id: int, ip: str = "", user_agent: str = "") -> tuple[str, str]:
    token = secrets.token_urlsafe(32)
    created = datetime.now(timezone.utc)
    expires = created + timedelta(hours=config.SESSION_HOURS)
    with db.transaction() as conn:
        conn.execute(
            "INSERT INTO sessions(token, user_id, created_at, expires_at, ip, user_agent) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (token, user_id, created.isoformat(timespec="seconds"),
             expires.isoformat(timespec="seconds"), ip, user_agent[:200]),
        )
    return token, expires.isoformat(timespec="seconds")


def resolve_session(token: str) -> dict | None:
    """Return the user behind a session token, or None if absent or expired."""
    if not token:
        return None
    row = db.query_one(
        """
        SELECT u.id, u.username, u.full_name, u.role, u.is_active,
               u.must_change_password, s.expires_at
        FROM sessions s JOIN users u ON u.id = s.user_id
        WHERE s.token = ?
        """,
        (token,),
    )
    if row is None:
        return None
    if row["expires_at"] < datetime.now(timezone.utc).isoformat(timespec="seconds"):
        destroy_session(token)
        return None
    if not row["is_active"]:
        return None
    row["permissions"] = permissions_for(row["role"])
    return row


def destroy_session(token: str) -> None:
    with db.transaction() as conn:
        conn.execute("DELETE FROM sessions WHERE token = ?", (token,))


def destroy_user_sessions(user_id: int) -> None:
    with db.transaction() as conn:
        conn.execute("DELETE FROM sessions WHERE user_id = ?", (user_id,))


def purge_expired_sessions() -> int:
    cutoff = datetime.now(timezone.utc).isoformat(timespec="seconds")
    with db.transaction() as conn:
        cur = conn.execute("DELETE FROM sessions WHERE expires_at < ?", (cutoff,))
    return cur.rowcount or 0
