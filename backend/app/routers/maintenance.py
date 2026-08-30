"""System maintenance: backups and database housekeeping.

The DOS menu's Maintenance column had "Back-up Files" (a Monday-to-Saturday
rotation onto floppies) and "ReIndex Files" (rebuild every .IDX, which required
everyone to be out of the system). Both survive here in the form they take on a
single-file database - but neither needs the office to stop working.
"""

from __future__ import annotations

import shutil
import sqlite3
from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException

from .. import config, db
from ..deps import require

router = APIRouter(prefix="/maintenance", tags=["maintenance"])

BACKUP_DIR = config.DB_PATH.parent / "backups"
KEEP_BACKUPS = 14


def _disk_free_mb(path: Path) -> float:
    return shutil.disk_usage(path).free / 1_048_576


def _backup_rows() -> list[dict]:
    if not BACKUP_DIR.exists():
        return []
    rows = []
    for path in sorted(BACKUP_DIR.glob("ims-*.sqlite"), reverse=True):
        stat = path.stat()
        rows.append({
            "name": path.name,
            "size_mb": round(stat.st_size / 1_048_576, 1),
            # Local time, because a backup is filed by the day the office took it.
            "created_at": datetime.fromtimestamp(
                stat.st_mtime).astimezone().isoformat(timespec="seconds"),
        })
    return rows


@router.get("/status")
def status(_user: dict = Depends(require("maintenance:run"))) -> dict:
    """Everything the maintenance screen needs in one call."""
    size_mb = (round(config.DB_PATH.stat().st_size / 1_048_576, 1)
               if config.DB_PATH.exists() else 0)
    backups = _backup_rows()
    return {
        "database": {
            "path": str(config.DB_PATH),
            "size_mb": size_mb,
            "journal_mode": db.scalar("PRAGMA journal_mode", (), ""),
            "page_count": db.scalar("PRAGMA page_count", (), 0),
            "freelist_pages": db.scalar("PRAGMA freelist_count", (), 0),
        },
        "disk_free_mb": round(_disk_free_mb(config.DB_PATH.parent), 0),
        "rows": {
            name: db.scalar(f"SELECT COUNT(*) FROM {name}", (), 0)
            for name in ("stock", "customers", "suppliers", "invoices", "invoice_lines",
                         "purchases", "sales_returns", "collections", "stock_moves")
        },
        "backups": backups,
        "last_backup": backups[0] if backups else None,
        "sessions_open": db.scalar(
            "SELECT COUNT(*) FROM sessions WHERE expires_at > ?", (db.now(),), 0),
    }


@router.post("/backup")
def backup(user: dict = Depends(require("maintenance:run"))) -> dict:
    """Take a consistent copy of the database while people keep working.

    SQLite's own backup API copies a live database safely, which the DOS system
    could never do - back-ups there meant everybody out of the files first.
    """
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    size_mb = config.DB_PATH.stat().st_size / 1_048_576
    free_mb = _disk_free_mb(BACKUP_DIR)
    if free_mb < size_mb * 1.1:
        raise HTTPException(
            status_code=507,
            detail=f"Not enough disk space: the database is {size_mb:,.0f} MB and only "
                   f"{free_mb:,.0f} MB is free. Delete some older backups first.")

    stamp = datetime.now().astimezone().strftime("%Y%m%d-%H%M%S")
    target = BACKUP_DIR / f"ims-{stamp}.sqlite"

    source = db.get_connection()
    destination = sqlite3.connect(target)
    try:
        source.backup(destination)
    finally:
        destination.close()

    # Keep the most recent few; the DOS system rotated six days of floppies.
    removed = []
    for old in sorted(BACKUP_DIR.glob("ims-*.sqlite"), reverse=True)[KEEP_BACKUPS:]:
        removed.append(old.name)
        old.unlink()

    with db.transaction() as conn:
        db.audit(conn, user["username"], "backup", "database", target.name,
                 f"{target.stat().st_size / 1_048_576:,.1f} MB")

    return {
        "name": target.name,
        "size_mb": round(target.stat().st_size / 1_048_576, 1),
        "removed": removed,
        "backups": _backup_rows(),
    }


@router.post("/check")
def check(user: dict = Depends(require("maintenance:run"))) -> dict:
    """The successor to "ReIndex Files".

    SQLite maintains its own indexes, so there is nothing to rebuild. What is
    still worth doing is verifying the file and refreshing the statistics the
    query planner uses.
    """
    integrity = db.scalar("PRAGMA integrity_check", (), "unknown")
    foreign_keys = db.query("PRAGMA foreign_key_check")
    db.execute("ANALYZE")
    db.execute("PRAGMA optimize")

    with db.transaction() as conn:
        db.audit(conn, user["username"], "check", "database", None, f"integrity={integrity}")

    return {
        "integrity": integrity,
        "ok": integrity == "ok" and not foreign_keys,
        "foreign_key_problems": len(foreign_keys),
        "checked_at": db.now(),
    }


# --------------------------------------------------------------------------- #
# Code Revisions - item 3 on the old Maintenance menu
# --------------------------------------------------------------------------- #

# Every table and column that carries one of these codes. A rename has to reach
# all of them, which is exactly why the DOS version was a dedicated program
# rather than something you did by hand.
CODE_TARGETS = {
    "stock": {
        "master": ("stock", "code"),
        "refs": [("invoice_lines", "stock_code"), ("purchase_lines", "stock_code"),
                 ("sales_return_lines", "stock_code"), ("stock_moves", "stock_code")],
    },
    "customer": {
        "master": ("customers", "code"),
        "refs": [("invoices", "customer_code"), ("sales_returns", "customer_code"),
                 ("collections", "customer_code"), ("stock_moves", "customer_code"),
                 ("customer_monthly", "customer_code")],
    },
    "supplier": {
        "master": ("suppliers", "code"),
        "refs": [("purchases", "supplier_code"), ("stock", "supplier_code"),
                 ("stock_moves", "supplier_code")],
    },
}


@router.get("/code-usage")
def code_usage(kind: str, code: str,
               _user: dict = Depends(require("maintenance:run"))) -> dict:
    """How many rows a rename would touch, before anyone commits to it."""
    target = CODE_TARGETS.get(kind)
    if target is None:
        raise HTTPException(status_code=400, detail=f"Unknown code type {kind!r}.")

    code = code.strip().upper()
    table, column = target["master"]
    master = db.query_one(f"SELECT * FROM {table} WHERE {column} = ?", (code,))
    if master is None:
        raise HTTPException(status_code=404, detail=f"No {kind} with code {code}.")

    usage = [
        {"table": t,
         "rows": db.scalar(f"SELECT COUNT(*) FROM {t} WHERE {c} = ?", (code,), 0)}
        for t, c in target["refs"]
    ]
    return {
        "kind": kind,
        "code": code,
        "name": master.get("name", ""),
        "usage": usage,
        "total_rows": sum(u["rows"] for u in usage),
    }


@router.post("/code-revision")
def code_revision(payload: dict,
                  user: dict = Depends(require("maintenance:run"))) -> dict:
    """Rename a code everywhere it appears, in one transaction.

    Either every table changes or none does - the DOS version could leave
    orphaned detail rows behind if it was interrupted part-way.
    """
    kind = str(payload.get("kind") or "").strip()
    old = str(payload.get("old_code") or "").strip().upper()
    new = str(payload.get("new_code") or "").strip().upper()

    target = CODE_TARGETS.get(kind)
    if target is None:
        raise HTTPException(status_code=400, detail=f"Unknown code type {kind!r}.")
    if not old or not new:
        raise HTTPException(status_code=400, detail="Enter both the old and the new code.")
    if old == new:
        raise HTTPException(status_code=400, detail="The two codes are the same.")
    if len(new) > 10:
        raise HTTPException(status_code=400, detail="Codes are at most 10 characters.")

    table, column = target["master"]
    changed = {}
    with db.transaction() as conn:
        if conn.execute(f"SELECT 1 FROM {table} WHERE {column} = ?", (old,)).fetchone() is None:
            raise HTTPException(status_code=404, detail=f"No {kind} with code {old}.")
        if conn.execute(f"SELECT 1 FROM {table} WHERE {column} = ?", (new,)).fetchone():
            raise HTTPException(status_code=409,
                                detail=f"{new} is already in use by another {kind}.")

        # Foreign keys are declared without ON UPDATE CASCADE, so the detail
        # rows move first and the master last.
        for ref_table, ref_column in target["refs"]:
            cursor = conn.execute(
                f"UPDATE {ref_table} SET {ref_column} = ? WHERE {ref_column} = ?", (new, old))
            if cursor.rowcount:
                changed[ref_table] = cursor.rowcount
        conn.execute(f"UPDATE {table} SET {column} = ? WHERE {column} = ?", (new, old))
        changed[table] = 1

        db.audit(conn, user["username"], "code-revision", kind, f"{old} -> {new}",
                 ", ".join(f"{t}:{n}" for t, n in changed.items()))

    return {"kind": kind, "old_code": old, "new_code": new,
            "changed": changed, "total_rows": sum(changed.values())}


# --------------------------------------------------------------------------- #
# Purging of Records - item 2 on the old Maintenance menu
# --------------------------------------------------------------------------- #

def _purge_scope(before: str) -> dict:
    """Documents old enough and settled enough to leave the working set."""
    return {
        "invoices": db.scalar(
            "SELECT COUNT(*) FROM invoices WHERE inv_date < ? AND balance <= 0.005 "
            "AND status <> 'CANCELLED'", (before,), 0),
        "invoice_lines": db.scalar(
            "SELECT COUNT(*) FROM invoice_lines WHERE inv_no IN "
            "(SELECT inv_no FROM invoices WHERE inv_date < ? AND balance <= 0.005 "
            " AND status <> 'CANCELLED')", (before,), 0),
        "collections": db.scalar(
            "SELECT COUNT(*) FROM collections WHERE col_date < ? AND status = 'POSTED'",
            (before,), 0),
        "stock_moves": db.scalar(
            "SELECT COUNT(*) FROM stock_moves WHERE doc_date < ?", (before,), 0),
    }


@router.get("/purge-preview")
def purge_preview(before: str = "", _user: dict = Depends(require("maintenance:run"))) -> dict:
    """What a purge would remove, and what it would leave alone.

    The DOS system purged because .DBF files grew until the machine struggled.
    SQLite does not have that problem, so this is offered as a considered
    choice rather than a chore - and it never touches anything unpaid.
    """
    if not before:
        raise HTTPException(status_code=400, detail="Choose a cut-off date.")

    scope = _purge_scope(before)
    return {
        "before": before,
        "scope": scope,
        "total_rows": sum(scope.values()),
        "kept": {
            "unpaid_invoices": db.scalar(
                "SELECT COUNT(*) FROM invoices WHERE inv_date < ? AND balance > 0.005",
                (before,), 0),
            "cancelled_invoices": db.scalar(
                "SELECT COUNT(*) FROM invoices WHERE inv_date < ? AND status = 'CANCELLED'",
                (before,), 0),
        },
        "oldest_invoice": db.scalar("SELECT MIN(inv_date) FROM invoices", (), None),
        "database_mb": round(config.DB_PATH.stat().st_size / 1_048_576, 1),
        "last_backup": (_backup_rows() or [None])[0],
    }


@router.post("/purge")
def purge(payload: dict, user: dict = Depends(require("maintenance:run"))) -> dict:
    """Remove settled history older than a cut-off. Requires a fresh backup."""
    before = str(payload.get("before") or "").strip()
    confirm = str(payload.get("confirm") or "")
    if not before:
        raise HTTPException(status_code=400, detail="Choose a cut-off date.")
    if confirm != "PURGE":
        raise HTTPException(status_code=400,
                            detail="Type PURGE to confirm. Nothing has been removed.")

    backups = _backup_rows()
    if not backups:
        raise HTTPException(
            status_code=428,
            detail="Take a backup first. Purging cannot be undone without one.")

    scope = _purge_scope(before)
    with db.transaction() as conn:
        conn.execute(
            "DELETE FROM invoice_lines WHERE inv_no IN "
            "(SELECT inv_no FROM invoices WHERE inv_date < ? AND balance <= 0.005 "
            " AND status <> 'CANCELLED')", (before,))
        conn.execute(
            "DELETE FROM invoices WHERE inv_date < ? AND balance <= 0.005 "
            "AND status <> 'CANCELLED'", (before,))
        conn.execute(
            "DELETE FROM collection_applications WHERE col_no IN "
            "(SELECT col_no FROM collections WHERE col_date < ? AND status = 'POSTED')",
            (before,))
        conn.execute(
            "DELETE FROM collections WHERE col_date < ? AND status = 'POSTED'", (before,))
        conn.execute("DELETE FROM stock_moves WHERE doc_date < ?", (before,))
        db.audit(conn, user["username"], "purge", "database", before,
                 f"{sum(scope.values()):,} rows removed")

    return {"before": before, "removed": scope, "total_rows": sum(scope.values()),
            "note": "Run Compact to give the freed space back to the disk."}


@router.post("/compact")
def compact(user: dict = Depends(require("maintenance:run"))) -> dict:
    """Reclaim free pages. Rewrites the whole file, so it is deliberate rather
    than routine - it needs as much free disk as the database occupies."""
    before = config.DB_PATH.stat().st_size
    free_mb = _disk_free_mb(config.DB_PATH.parent)
    if free_mb < (before / 1_048_576) * 1.1:
        raise HTTPException(
            status_code=507,
            detail=f"Compacting needs about {before / 1_048_576:,.0f} MB of free space and "
                   f"only {free_mb:,.0f} MB is available.")

    db.execute("VACUUM")
    after = config.DB_PATH.stat().st_size

    with db.transaction() as conn:
        db.audit(conn, user["username"], "compact", "database", None,
                 f"{(before - after) / 1_048_576:,.1f} MB reclaimed")

    return {
        "before_mb": round(before / 1_048_576, 1),
        "after_mb": round(after / 1_048_576, 1),
        "reclaimed_mb": round((before - after) / 1_048_576, 1),
    }
