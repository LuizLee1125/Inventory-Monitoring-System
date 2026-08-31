"""System maintenance: backups and database housekeeping.

The DOS menu's Maintenance column had "Back-up Files" (a Monday-to-Saturday
rotation onto floppies) and "ReIndex Files" (rebuild every .IDX, which required
everyone to be out of the system). Both survive here in the form they take on a
single-file database - but neither needs the office to stop working.
"""

from __future__ import annotations

import shutil
import sqlite3
import tempfile
import time
import zipfile
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import datetime, timedelta
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse

from .. import config, db
from ..deps import require

router = APIRouter(prefix="/maintenance", tags=["maintenance"])

BACKUP_DIR = config.BACKUP_DIR

# The database inside the zip is always called this, whatever the zip is called,
# so a person who opens one knows immediately what they are looking at.
MEMBER_NAME = "ims.sqlite"

# A backup being written carries this until it is complete. The rename at the
# end is atomic, so a power cut leaves a .part nobody will mistake for a backup
# rather than a truncated .zip that looks like one.
PART_SUFFIX = ".part"


class BackupSpaceError(RuntimeError):
    """Not enough room on disk to hold another copy of the database."""


def _disk_free_mb(path: Path) -> float:
    return shutil.disk_usage(path).free / 1_048_576


def _backup_files() -> list[Path]:
    """Newest first. The timestamp is in the name, so the sort is the order.

    Both formats are listed. New backups are always zips, but an office
    upgrading to this version has a folder of plain `.sqlite` copies that are
    perfectly good backups of its real business — hiding them because the format
    changed would be the worst possible way to introduce a new one.
    """
    if not BACKUP_DIR.exists():
        return []
    found = [*BACKUP_DIR.glob("ims-*.zip"), *BACKUP_DIR.glob("ims-*.sqlite")]
    # By the clock, not by the name. The name now leads with a readable date
    # (8-31-2026), which does not sort - 10-1-2026 would come before 8-31-2026 -
    # and the modified time is what retention and "last backup" already read, so
    # ordering by it makes the whole feature agree with itself.
    return sorted(found, key=lambda p: (p.stat().st_mtime, p.name), reverse=True)


@contextmanager
def open_backup(path: Path) -> Iterator[Path]:
    """Yield the database inside a backup, whatever the backup is wrapped in.

    A zip is expanded to a temporary file and cleaned up afterwards; a plain
    `.sqlite` from before the format changed is handed over as it is, and must
    not be deleted on the way out.
    """
    if path.suffix == ".sqlite":
        yield path
        return

    work = Path(tempfile.mkdtemp(prefix="ims-backup-"))
    try:
        yield extract_backup(path, work)
    finally:
        shutil.rmtree(work, ignore_errors=True)


def tidy_backup_dir() -> dict:
    """Startup housekeeping: move the old folder in, sweep away half-written files.

    Both halves exist because the server is a PC in an office, not a datacentre.
    It gets switched off at the wall, and it gets upgraded by copying a new
    folder over the old one.
    """
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    moved, swept = [], []

    # A backup interrupted by the power going off. It is not a backup; it is the
    # first part of one, and leaving it would put a file in the list that cannot
    # be restored from.
    for part in BACKUP_DIR.glob(f"*{PART_SUFFIX}"):
        swept.append(part.name)
        part.unlink()

    legacy = config.LEGACY_BACKUP_DIR
    if legacy.exists() and legacy.resolve() != BACKUP_DIR:
        for old in sorted(legacy.iterdir()):
            if not old.is_file():
                continue
            target = BACKUP_DIR / old.name
            if target.exists():
                continue
            try:
                # A rename inside one drive moves nothing and needs no space.
                # Across drives it fails, and the backup stays where it is
                # rather than being half-copied.
                old.rename(target)
                moved.append(old.name)
            except OSError as exc:
                print(f"  Backups : could not move {old.name} - {exc}", flush=True)

    return {"moved": moved, "swept": swept}


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
            # The filename carries the kind, so the screen can say at a glance
            # whether the week filled itself, was filled by hand, or holds the
            # database as it was just before somebody restored over it.
            "automatic": path.stem.endswith("-auto"),
            "kind": ("automatic" if path.stem.endswith("-auto")
                     else "prerestore" if path.stem.endswith("-prerestore")
                     else "manual"),
        })
    return rows


SETTING_MANUAL_DAYS = "backup.manual_keep_days"


def manual_keep_days() -> int:
    """The window the office chose for the backups it takes by hand."""
    stored = db.get_setting(SETTING_MANUAL_DAYS)
    try:
        value = int(stored)
    except (TypeError, ValueError):
        return config.BACKUP_MANUAL_KEEP_DAYS
    # A value that is no longer on offer falls back rather than being honoured:
    # the choices are what the screen can show, and an unshowable setting is one
    # nobody can correct.
    return value if value in config.BACKUP_MANUAL_KEEP_CHOICES \
        else config.BACKUP_MANUAL_KEEP_DAYS


def is_automatic(path: Path) -> bool:
    return path.stem.endswith("-auto")


def prune_backups() -> list[str]:
    """Delete backups older than the window for their kind.

    Two windows, because the two kinds mean different things: the daily
    automatic rotation is a week deep and the machine's own business, while a
    backup somebody took by hand was taken for a reason and keeps to whatever
    window the office chose.

    Age decides, but never past the floor: `BACKUP_KEEP_MIN` most recent files
    survive however old they are, and whichever kind they are. An office that
    closes for a fortnight must not come back to a backup folder that has tidied
    itself empty.
    """
    files = _backup_files()
    manual_days = manual_keep_days()
    # Epoch seconds on both sides: st_mtime is one, so the comparison never has
    # to care which timezone the office is in or whether it just changed.
    now = time.time()
    auto_cutoff = now - config.BACKUP_KEEP_DAYS * 86400
    manual_cutoff = now - manual_days * 86400

    keep = {
        path for path in files
        if path.stat().st_mtime >= (auto_cutoff if is_automatic(path) else manual_cutoff)
    }
    keep.update(files[:config.BACKUP_KEEP_MIN])

    removed = []
    for path in files:
        if path not in keep:
            removed.append(path.name)
            path.unlink()
    return removed


def take_backup(username: str, *, automatic: bool = False,
                tag: str = "") -> dict:
    """Copy the database into a zip, then prune.

    Two steps, and both matter. SQLite's own backup API copies a *live* database
    safely, which the DOS system could never do - back-ups there meant everybody
    out of the files first. The zip is what makes the result something an
    administrator on another PC can actually take away: one file, a third of the
    size, that a browser will download over the office network.
    """
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    # Room for the raw copy and the zip at once, since both exist for a moment.
    size_mb = config.DB_PATH.stat().st_size / 1_048_576
    free_mb = _disk_free_mb(BACKUP_DIR)
    if free_mb < size_mb * 1.5:
        raise BackupSpaceError(
            f"Not enough disk space: the database is {size_mb:,.0f} MB and only "
            f"{free_mb:,.0f} MB is free. Delete some older backups first.")

    # The stamp is only accurate to the second, and two backups can land inside
    # one - taking a pre-restore copy immediately before a restore does exactly
    # that. Without the counter the second write silently overwrote the first,
    # which in the restore path meant the safety copy landing on top of the file
    # it was about to restore from.
    # Just the date - `ims-8-31-2026.zip` - because that is what the file is:
    # the database as it stood on that day. A time of day in the name was noise
    # in a downloads folder, and the screen shows the exact minute anyway.
    # Built by hand rather than with strftime: dropping the leading zero is
    # %-m on Linux and %#m on Windows, and neither is portable.
    now = datetime.now().astimezone()
    stamp = f"{now.month}-{now.day}-{now.year}"
    suffix = "-auto" if automatic else (f"-{tag}" if tag else "")
    target = BACKUP_DIR / f"ims-{stamp}{suffix}.zip"
    attempt = 2
    while target.exists():
        # A second backup on the same day becomes `ims-8-31-2026-2.zip`. The
        # counter goes before the kind, so `-auto` and `-prerestore` stay at the
        # end of the stem where everything else looks for them.
        target = BACKUP_DIR / f"ims-{stamp}-{attempt}{suffix}.zip"
        attempt += 1

    raw = target.with_suffix(".sqlite.tmp")
    part = target.with_name(target.name + PART_SUFFIX)
    try:
        # A fresh connection rather than the thread-local one: this runs on a
        # worker thread when the schedule calls it, and `db.get_connection()`
        # would hand that thread a connection of its own anyway.
        source = db.get_connection()
        destination = sqlite3.connect(raw)
        try:
            source.backup(destination)
        finally:
            destination.close()
        raw_mb = raw.stat().st_size / 1_048_576

        with zipfile.ZipFile(part, "w", zipfile.ZIP_DEFLATED,
                             compresslevel=config.BACKUP_ZIP_LEVEL) as archive:
            archive.write(raw, MEMBER_NAME)

        # The last step, and the only one that is atomic: until this line there
        # is no file in the folder that looks like a finished backup.
        part.replace(target)
    finally:
        raw.unlink(missing_ok=True)
        part.unlink(missing_ok=True)

    removed = prune_backups()
    written_mb = round(target.stat().st_size / 1_048_576, 1)

    with db.transaction() as conn:
        db.audit(conn, username, "backup", "database", target.name,
                 f"{written_mb:,.1f} MB zipped from {raw_mb:,.1f} MB"
                 + (f", removed {len(removed)}" if removed else ""))

    return {
        "name": target.name,
        "size_mb": written_mb,
        "database_mb": round(raw_mb, 1),
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
            "folder": str(BACKUP_DIR),
            "keep_days": config.BACKUP_KEEP_DAYS,
            "manual_keep_days": manual_keep_days(),
            "manual_choices": list(config.BACKUP_MANUAL_KEEP_CHOICES),
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


@router.post("/retention")
def retention(payload: dict,
              user: dict = Depends(require("maintenance:run"))) -> dict:
    """Choose how long backups taken by hand are kept."""
    try:
        days = int(payload.get("manual_keep_days"))
    except (TypeError, ValueError):
        days = 0
    if days not in config.BACKUP_MANUAL_KEEP_CHOICES:
        offered = ", ".join(str(n) for n in config.BACKUP_MANUAL_KEEP_CHOICES)
        raise HTTPException(status_code=400,
                            detail=f"Choose one of {offered} days.")

    with db.transaction() as conn:
        db.set_setting(conn, SETTING_MANUAL_DAYS, days)
        db.audit(conn, user["username"], "settings", "backup", SETTING_MANUAL_DAYS,
                 f"manual backups kept {days} days")

    # Applied straight away, so a shortened window takes effect now rather than
    # at whatever hour the next backup happens to be taken.
    removed = prune_backups()
    return {"manual_keep_days": days, "removed": removed, "backups": _backup_rows()}


# --------------------------------------------------------------------------- #
# Restore
# --------------------------------------------------------------------------- #

def _find_backup(name: str) -> Path:
    """Resolve a backup by name, refusing anything that is not one of ours.

    The name arrives from the browser, so it is matched against the directory
    listing rather than joined onto a path - `../../etc/passwd` never becomes a
    path here because it is never treated as one.
    """
    for path in _backup_files():
        if path.name == name:
            return path
    raise HTTPException(status_code=404, detail=f"No backup named {name!r}.")


def extract_backup(path: Path, into: Path) -> Path:
    """Expand a backup zip to a working file. Returns the database inside it."""
    try:
        with zipfile.ZipFile(path) as archive:
            names = [n for n in archive.namelist() if n.endswith(".sqlite")]
            if not names:
                raise HTTPException(
                    status_code=400,
                    detail=f"{path.name} contains no database file. It is not a "
                           f"backup of this system.")
            archive.extract(names[0], into)
            return into / names[0]
    except zipfile.BadZipFile as exc:
        raise HTTPException(
            status_code=400,
            detail=f"{path.name} is not a readable zip ({exc}). It may have been "
                   f"cut short - check for a newer backup.") from exc


def inspect_backup(path: Path) -> dict:
    """Open a backup and decide whether it is safe to restore from.

    Restoring a truncated or half-written file over a working database would be
    worse than the problem being fixed, so nothing is overwritten until the file
    has been expanded, passed an integrity check, and been found to contain the
    tables this version of the code expects.
    """
    with open_backup(path) as inner:
        return _inspect_database(inner, path, path.stat().st_size)


def _inspect_database(inner: Path, path: Path, zipped: int) -> dict:
    try:
        conn = sqlite3.connect(f"{inner.as_uri()}?mode=ro", uri=True)
    except sqlite3.Error as exc:
        raise HTTPException(status_code=400,
                            detail=f"{path.name} cannot be opened: {exc}") from exc

    try:
        integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            raise HTTPException(
                status_code=400,
                detail=f"{path.name} failed its integrity check ({integrity}). "
                       f"It is damaged and will not be restored.")

        present = {row[0] for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type = 'table'")}
        reference = db.reference_schema()
        try:
            expected = {row["name"] for row in reference.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' "
                "AND name NOT LIKE 'sqlite_%'")}
        finally:
            reference.close()

        missing = sorted(expected - present)
        if missing:
            raise HTTPException(
                status_code=400,
                detail=f"{path.name} is missing {len(missing)} table(s) this version "
                       f"needs ({', '.join(missing[:4])}). It is from an older system.")

        counts = {}
        for table in ("invoices", "customers", "stock", "collections", "stock_moves"):
            counts[table] = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    finally:
        conn.close()

    stat = path.stat()
    return {
        "name": path.name,
        "size_mb": round(zipped / 1_048_576, 1),
        "database_mb": round(inner.stat().st_size / 1_048_576, 1),
        "taken_at": datetime.fromtimestamp(stat.st_mtime).astimezone().isoformat(
            timespec="seconds"),
        "automatic": is_automatic(path),
        "rows": counts,
    }


# GET *and* HEAD. The screen asks for the headers before pointing the browser at
# the file, so a backup that is no longer there can be reported in the page
# instead of failing silently in the downloads tray. Without HEAD registered
# here the probe falls through to the catch-all and answers 404 for every
# backup, which turns the safety check into an outage.
@router.api_route("/backups/{name}/download", methods=["GET", "HEAD"])
def download_backup(name: str,
                    user: dict = Depends(require("maintenance:run"))) -> FileResponse:
    """Send a backup to whoever asked for it.

    This is the point of the zip. The person running this system is almost never
    sitting at the server - they are at a counter PC on the office network, and
    a file written to the server's own disk is one they cannot reach, cannot
    copy to a memory stick, and cannot take home. A download turns the backup
    into something they actually hold.

    The server keeps its copy either way, so a download that fails halfway
    through - the connection drops, the power goes off - costs nothing but the
    click. Press it again.
    """
    path = _find_backup(name)
    with db.transaction() as conn:
        db.audit(conn, user["username"], "download", "backup", path.name,
                 f"{path.stat().st_size / 1_048_576:,.1f} MB")
    media = "application/zip" if path.suffix == ".zip" else "application/octet-stream"
    return FileResponse(path, media_type=media, filename=path.name)


@router.delete("/backups/{name}")
def delete_backup(name: str,
                  user: dict = Depends(require("maintenance:run"))) -> dict:
    """Remove one backup.

    Retention already sweeps up on its own, so this is for the times it does not
    fit: a copy taken before something that turned out fine, a folder filling a
    small disk, a `-prerestore` nobody needs any more. The floor that stops
    *automatic* pruning emptying the folder does not apply here - somebody
    typing a filename and confirming it means to delete that file - but the
    screen says when it is the last one left.
    """
    path = _find_backup(name)
    remaining = len(_backup_files()) - 1
    size_mb = round(path.stat().st_size / 1_048_576, 1)
    path.unlink()

    with db.transaction() as conn:
        db.audit(conn, user["username"], "delete", "backup", name,
                 f"{size_mb:,.1f} MB, {remaining} left")
    print(f"  Backups : {name} deleted by {user['username']}, "
          f"{remaining} left", flush=True)

    return {"deleted": name, "size_mb": size_mb, "remaining": remaining,
            "backups": _backup_rows()}


@router.get("/restore-preview")
def restore_preview(name: str,
                    _user: dict = Depends(require("maintenance:run"))) -> dict:
    """What restoring this backup would put back, and what it would replace."""
    backup_info = inspect_backup(_find_backup(name))
    return {
        "backup": backup_info,
        "current": {
            table: db.scalar(f"SELECT COUNT(*) FROM {table}", (), 0)
            for table in backup_info["rows"]
        },
    }


@router.post("/restore")
def restore(payload: dict, user: dict = Depends(require("maintenance:run"))) -> dict:
    """Put a backup back, over everything now in the database.

    The whole database is replaced, so this is the one action here that can lose
    work. Three things stand between a mistaken click and a bad day:

    1. the confirmation has to be typed, as it does for a purge;
    2. the file is verified before anything is overwritten;
    3. a copy of the *current* database is taken first, so the restore itself
       can be undone by restoring that copy.

    The copy is made through SQLite's backup API rather than by swapping files
    on disk: the server is running, other threads hold their own connections to
    this database, and replacing the file underneath them would leave every one
    of those connections pointing at something that no longer exists.
    """
    if str(payload.get("confirm", "")).strip().upper() != "RESTORE":
        raise HTTPException(status_code=400,
                            detail="Type RESTORE to confirm. Nothing has been changed.")

    source_path = _find_backup(str(payload.get("name", "")))
    backup_info = inspect_backup(source_path)

    # Taken before anything is touched, and tagged so it is obvious what it is.
    try:
        safety = take_backup(user["username"], tag="prerestore")
    except BackupSpaceError as exc:
        raise HTTPException(status_code=507, detail=str(exc)) from exc

    # Belt and braces on a path that cannot be allowed to eat its own source.
    # `take_backup` gives every copy a unique name, so this should be
    # unreachable; it is here because the failure it guards against is silent.
    if (BACKUP_DIR / safety["name"]).resolve() == source_path.resolve():
        raise HTTPException(
            status_code=500,
            detail="The safety copy collided with the backup being restored. "
                   "Nothing has been changed.")

    with open_backup(source_path) as inner:
        live = db.get_connection()
        source = sqlite3.connect(f"{inner.as_uri()}?mode=ro", uri=True)
        try:
            source.backup(live)
        except sqlite3.Error as exc:
            raise HTTPException(
                status_code=500,
                detail=f"The restore failed and the database is unchanged: {exc}. "
                       f"The copy taken beforehand is {safety['name']}.") from exc
        finally:
            source.close()

    # The backup may predate a schema change, so bring it up to what this code
    # expects before anything reads it.
    added = db.init_db()

    # Every session in the database is now whatever was in the backup, so nobody
    # is meaningfully signed in any more. Clearing them says so rather than
    # leaving people half-authenticated against restored rows.
    with db.transaction() as conn:
        conn.execute("DELETE FROM sessions")
        # Written after the restore, into the restored database - an entry
        # written before it would have been overwritten by the very next line.
        db.audit(conn, user["username"], "restore", "database", source_path.name,
                 f"restored from {source_path.name}; "
                 f"previous database saved as {safety['name']}")

    print(f"  Restore: {source_path.name} restored by {user['username']}; "
          f"previous database saved as {safety['name']}", flush=True)

    return {
        "restored": backup_info,
        "safety_copy": safety["name"],
        "schema_updated": added,
        "signed_out": True,
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
