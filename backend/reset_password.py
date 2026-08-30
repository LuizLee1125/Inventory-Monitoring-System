#!/usr/bin/env python3
"""
Set an account's password from the server console.

The recovery path for being locked out. Anyone who can run this already has the
database file in their hands, so it grants nothing they did not already have -
but it must only ever be run on the server itself, never exposed.

    python backend/reset_password.py                       list the accounts
    python backend/reset_password.py ADMIN                 prompt for a new password
    python backend/reset_password.py ADMIN --password ...  set it directly
    python backend/reset_password.py ADMIN --make-admin    also restore the admin role

Unless --keep-flag is given, the account is required to choose its own password
at the next sign-in, and any open session for it is closed.
"""

from __future__ import annotations

import argparse
import getpass
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from app import config, db, security

MIN_LENGTH = 8


def list_accounts() -> None:
    rows = db.query(
        "SELECT username, full_name, role, is_active, must_change_password, "
        "last_login FROM users ORDER BY username")
    if not rows:
        print("No accounts exist. Run migrate.py, or start the server once to "
              "have an ADMIN account created.")
        return
    print(f"\n{'USER':<14}{'ROLE':<12}{'ACTIVE':<8}{'MUST CHANGE':<13}LAST SIGN-IN")
    print("-" * 68)
    for r in rows:
        print(f"{r['username']:<14}{r['role']:<12}"
              f"{'yes' if r['is_active'] else 'NO':<8}"
              f"{'yes' if r['must_change_password'] else 'no':<13}"
              f"{(r['last_login'] or 'never')[:19]}")
    print(f"\n{len(rows)} account(s) in {config.DB_PATH}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Set an account's password, or list the accounts.")
    parser.add_argument("username", nargs="?", help="account to reset")
    parser.add_argument("--password", help="the new password (prompted if omitted)")
    parser.add_argument("--make-admin", action="store_true",
                        help="also give the account the admin role and re-enable it")
    parser.add_argument("--keep-flag", action="store_true",
                        help="do not force a password change at next sign-in")
    args = parser.parse_args()

    db.init_db()

    if not args.username:
        list_accounts()
        return

    username = args.username.strip().upper()
    row = db.query_one("SELECT id, username, role FROM users WHERE username = ?",
                       (username,))
    if row is None:
        print(f"No account named {username!r}.")
        list_accounts()
        raise SystemExit(1)

    password = args.password
    if not password:
        password = getpass.getpass(f"New password for {username}: ")
        if password != getpass.getpass("Repeat: "):
            raise SystemExit("The two entries do not match.")
    if len(password) < MIN_LENGTH:
        raise SystemExit(f"Too short - use at least {MIN_LENGTH} characters.")

    role = "admin" if args.make_admin else row["role"]
    with db.transaction() as conn:
        conn.execute(
            "UPDATE users SET password_hash = ?, must_change_password = ?, "
            "role = ?, is_active = 1, version = version + 1 WHERE id = ?",
            (security.hash_password(password),
             0 if args.keep_flag else 1, role, row["id"]))
        closed = conn.execute("DELETE FROM sessions WHERE user_id = ?",
                              (row["id"],)).rowcount
        db.audit(conn, "console", "reset-password", "user", username,
                 f"role={role}, sessions closed={closed}")

    print(f"\nPassword set for {username} (role: {role}).")
    if closed:
        print(f"{closed} open session(s) were closed.")
    if not args.keep_flag:
        print("They will be asked to choose their own password at next sign-in.")


if __name__ == "__main__":
    main()
