"""System maintenance: backups and database housekeeping.

The DOS menu's Maintenance column had "Back-up Files" (a Monday-to-Saturday
rotation onto floppies) and "ReIndex Files" (rebuild every .IDX, which required
everyone to be out of the system). Both survive here in the form they take on a
single-file database - but neither needs the office to stop working.
"""

from __future__ import annotations

import shutil
import sqlite3
import time
from datetime import datetime, timedelta
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException

from .. import config, db
from ..deps import require

router = APIRouter(prefix="/maintenance", tags=["maintenance"])

BACKUP_DIR = config.BACKUP_DIR


class BackupSpaceError(RuntimeError):
    """Not enough room on disk to hold another copy of the database."""


def _disk_free_mb(path: Path) -> float:
    return shutil.disk_usage(path).free / 1_048_576


def _backup_files() -> list[Path]:
    """Newest first. The timestamp is in the name, so the sort is the order."""
    if not BACKUP_DIR.exists():
        return []
    return sorted(BACKUP_DIR.glob("ims-*.sqlite"), reverse=True)


def _backup_rows() -> list[dict]:
    now = datetime.now().astimezone()
    rows = []
    for path in _backup_files():
        stat = path.stat()
        # Local time, because a backup is filed by the day the office took it.
        taken = datetime.fromtimestamp(stat.st_mtime).astimezone()
        rows.append({
            "name": path.name,
            "size_mb": round(stat.st_size / 1_048_576, 1),
            "created_at": taken.isoformat(timespec="seconds"),
            "age_days": round((now - taken).total_seconds() / 86400, 1),
            # The scheduled ones say so in the filename, so the screen can show
            # at a glance whether the week filled itself or was filled by hand.
            "automatic": path.stem.endswith("-auto"),
        })
    return rows


def prune_backups() -> list[str]:
    """Delete backups older than the retention window.

    Age decides, but never past the floor: `BACKUP_KEEP_MIN` most recent files
    survive however old they are. An office that closes for a fortnight must not
    come back to a backup folder that has tidied itself empty.
    """
    files = _backup_files()
    # Epoch seconds on both sides: st_mtime is one, so the comparison never has
    # to care which timezone the office is in or whether it just changed.
    cutoff = time.time() - config.BACKUP_KEEP_DAYS * 86400
    keep = {path for path in files if path.stat().st_mtime >= cutoff}
    keep.update(files[:config.BACKUP_KEEP_MIN])

    removed = []
    for path in files:
        if path not in keep:
            removed.append(path.name)
            path.unlink()
    return removed


def take_backup(username: str, *, automatic: bool = False) -> dict:
    """Copy the database, then prune. Used by the button and by the schedule.

    SQLite's own backup API copies a live database safely, which the DOS system
    could never do - back-ups there meant everybody out of the files first.
    """
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    size_mb = config.DB_PATH.stat().st_size / 1_048_576
    free_mb = _disk_free_mb(BACKUP_DIR)
    if free_mb < size_mb * 1.1:
        raise BackupSpaceError(
            f"Not enough disk space: the database is {size_mb:,.0f} MB and only "
            f"{free_mb:,.0f} MB is free. Delete some older backups first.")

    stamp = datetime.now().astimezone().strftime("%Y%m%d-%H%M%S")
    target = BACKUP_DIR / f"ims-{stamp}{'-auto' if automatic else ''}.sqlite"

    # A fresh connection rather than the thread-local one: this runs on a worker
    # thread when the schedule calls it, and `db.get_connection()` would hand
    # that thread a connection of its own anyway.
    source = db.get_connection()
    destination = sqlite3.connect(target)
    try:
        source.backup(destination)
    finally:
        destination.close()

    removed = prune_backups()
    written_mb = round(target.stat().st_size / 1_048_576, 1)

    with db.transaction() as conn:
        db.audit(conn, username, "backup", "database", target.name,
                 f"{written_mb:,.1f} MB"
                 + (f", removed {len(removed)} past "
                    f"{config.BACKUP_KEEP_DAYS} days" if removed else ""))

    return {
        "name": target.name,
        "size_mb": written_mb,
        "automatic": automatic,
        "removed": removed,
        "backups": _backup_rows(),
    }


def backup_is_due() -> bool:
    """True when the newest backup is older than the interval, or there is none."""
    if not config.BACKUP_EVERY_HOURS:
        return False
    files = _backup_files()
    if not files:
        return True
    age_hours = (time.time() - files[0].stat().st_mtime) / 3600
    return age_hours >= config.BACKUP_EVERY_HOURS


def run_scheduled_backup() -> dict | None:
    """One tick of the schedule. Returns what it took, or None if nothing was due.

    Runs on a worker thread - copying 1.2 GB takes several seconds, and doing it
    on the event loop would stop the office from working for exactly as long as
    the backup is meant to avoid.
    """
    if not backup_is_due():
        return None
    try:
        result = take_backup("SYSTEM", automatic=True)
    except (BackupSpaceError, OSError, sqlite3.Error) as exc:
        # A failed backup must never take the server down with it. It is logged,
        # the maintenance screen keeps showing the real last-backup time, and the
        # next tick tries again.
        print(f"  Backup : scheduled backup failed - {exc}", flush=True)
        return None
    print(f"  Backup : {result['name']} ({result['size_mb']:,.1f} MB)"
          + (f", removed {len(result['removed'])}" if result["removed"] else ""),
          flush=True)
    return result


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
        "backup_policy": {
            "keep_days": config.BACKUP_KEEP_DAYS,
            "keep_min": config.BACKUP_KEEP_MIN,
            "every_hours": config.BACKUP_EVERY_HOURS,
            "next_due": _next_due(backups),
            "total_mb": round(sum(row["size_mb"] for row in backups), 1),
        },
        "sessions_open": db.scalar(
            "SELECT COUNT(*) FROM sessions WHERE expires_at > ?", (db.now(),), 0),
    }


def _next_due(backups: list[dict]) -> str | None:
    """When the schedule will next take one, or None if it is switched off."""
    if not config.BACKUP_EVERY_HOURS:
        return None
    if not backups:
        return datetime.now().astimezone().isoformat(timespec="seconds")
    latest = datetime.fromisoformat(backups[0]["created_at"])
    return (latest + timedelta(hours=config.BACKUP_EVERY_HOURS)).isoformat(
        timespec="seconds")


@router.post("/backup")
def backup(user: dict = Depends(require("maintenance:run"))) -> dict:
    """Take a copy now, on top of whatever the schedule has already taken."""
    try:
        return take_backup(user["username"])
    except BackupSpaceError as exc:
        raise HTTPException(status_code=507, detail=str(exc)) from exc


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
