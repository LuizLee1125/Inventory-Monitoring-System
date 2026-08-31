"""Application settings.

Everything is overridable through environment variables so the same code runs
on a developer laptop and on the office server without edits.
"""

from __future__ import annotations

import os
from pathlib import Path

APP_DIR = Path(__file__).resolve().parent          # backend/app
BACKEND_DIR = APP_DIR.parent                       # backend
REPO_DIR = BACKEND_DIR.parent                      # the project root

# The database lives in its own folder, which is git-ignored, so business data
# is never accidentally committed.
DB_PATH = Path(os.getenv("IMS_DB", REPO_DIR / "database" / "ims.sqlite")).resolve()

# Folder holding the legacy .DBF files, used only by migrate.py.
LEGACY_DIR = Path(os.getenv("IMS_LEGACY_DIR", REPO_DIR / "legacy")).resolve()

# The frontend is a sibling of the backend, not a folder inside it: the API and
# the interface are separate deliverables that happen to ship together.
STATIC_DIR = Path(os.getenv("IMS_FRONTEND", REPO_DIR / "frontend")).resolve()

# The schema is a folder of numbered .sql parts, not one file: 490 lines of
# CREATE TABLE in a single document is not something anyone reads. db.init_db()
# runs the parts in filename order.
SCHEMA_DIR = APP_DIR / "schema"

# Where dump_db.py writes the database out as plain text. Inside the
# git-ignored database folder, because a dump holds the same customer records
# the database does.
PLAINTEXT_DIR = Path(
    os.getenv("IMS_PLAINTEXT_DIR", DB_PATH.parent / "plaintext")).resolve()

# Backups: zip files named ims-YYYYMMDD-HHMMSS.zip, with -auto for the scheduled
# ones and -prerestore for the copy taken before a restore.
#
# At the top of the project rather than tucked inside database\, because this is
# the one folder somebody has to be able to find in a hurry — on the worst day,
# from a machine that is not this one, possibly over somebody's shoulder on the
# phone. `backups` next to `start.bat` is a folder you can talk a person to.
BACKUP_DIR = Path(os.getenv("IMS_BACKUP_DIR", REPO_DIR / "backups")).resolve()

# Where they used to live. Anything still in here is moved on startup, so an
# upgrade does not orphan the backups the office already has.
LEGACY_BACKUP_DIR = DB_PATH.parent / "backups"

# Deflate at its fastest setting. Measured on this office's own 1,186 MB
# database: level 1 gives 387 MB in 6 seconds, level 6 gives 298 MB in 19. The
# extra 89 MB is not worth thirteen seconds of somebody watching a button.
BACKUP_ZIP_LEVEL = int(os.getenv("IMS_BACKUP_ZIP_LEVEL", "1"))

# How long an *automatic* backup is kept. The DOS system rotated
# Monday-to-Saturday floppies; this is the same week, without anybody carrying a
# box to the safe. Fixed, because the daily rotation is the machine's job.
BACKUP_KEEP_DAYS = int(os.getenv("IMS_BACKUP_DAYS", "7"))

# A backup somebody took by hand is a different thing: it was taken deliberately,
# usually just before something risky, and it should outlive the daily rotation.
# The office picks its own window on the maintenance screen; the value lives in
# the settings table, and this is only the answer until they do.
BACKUP_MANUAL_KEEP_CHOICES = (7, 14)
BACKUP_MANUAL_KEEP_DAYS = int(os.getenv("IMS_BACKUP_MANUAL_DAYS", "14"))

# ...and the floor that age alone cannot go below. An office that closes for a
# fortnight would otherwise come back to a backup folder that had tidied itself
# empty, which is the one state a backup system must never reach.
BACKUP_KEEP_MIN = int(os.getenv("IMS_BACKUP_KEEP_MIN", "3"))

# Hours between automatic backups. 0 turns them off and leaves only the button
# on the maintenance screen. A week of retention means little if the only
# backups in it are the ones somebody remembered to take.
BACKUP_EVERY_HOURS = int(os.getenv("IMS_BACKUP_HOURS", "24"))

# Where the desktop edition's installer is published for the office to fetch.
# The same reasoning as the backups folder: the person who wants the app is at a
# counter PC, not at the server, so the file has to come to them down the wire.
DESKTOP_DIR = Path(os.getenv("IMS_DESKTOP_DIR", REPO_DIR / "releases")).resolve()

# ...and, failing that, wherever `npm run build` just wrote one. A build that
# has to be copied somewhere before it can be handed out is a build somebody
# forgets to copy; looking here means the installer is downloadable the moment
# it exists. Tried in order, first match wins.
DESKTOP_BUILD_DIRS = (
    REPO_DIR / "desktop" / "src-tauri" / "target" / "release" / "bundle" / "nsis",
    REPO_DIR / "desktop" / "src-tauri" / "target" / "release" / "bundle" / "msi",
)

COMPANY_NAME = os.getenv("IMS_COMPANY", "Marina Trading")
APP_NAME = "Inventory Monitoring System"

# Session lifetime in hours; a working day plus a margin.
SESSION_HOURS = int(os.getenv("IMS_SESSION_HOURS", "12"))
SESSION_COOKIE = "ims_session"

# Bind address. 0.0.0.0 makes the server reachable from other PCs on the LAN.
HOST = os.getenv("IMS_HOST", "0.0.0.0")
PORT = int(os.getenv("IMS_PORT", "8080"))

# PBKDF2 work factor. Raise it as hardware improves; existing hashes keep
# working because the iteration count is stored alongside each hash.
PBKDF2_ROUNDS = int(os.getenv("IMS_PBKDF2_ROUNDS", "260000"))

# Notifications. The sweep rides on the backup schedule's existing tick rather
# than running a timer of its own — it is the same question ("has anything
# changed since I last looked?") asked of a different set of tables, and one
# worker thread waking every fifteen minutes is enough for both.
#
# The expiry window matches the one the dashboard already counts against
# (reports.py `dashboard()`), so the tile and the alert cannot disagree.
NOTIFY_EXPIRY_DAYS = int(os.getenv("IMS_NOTIFY_EXPIRY_DAYS", "90"))

# Above this many at once, a condition stops being a list of alerts and becomes
# one alert with a count on it. Measured against this office's own data: every
# one of its 2,137 active items currently reads zero on hand, and a bell holding
# 2,137 rows is not a bell. Past a handful the useful answer is "how many, and
# here is the report", which is one row.
NOTIFY_ROLLUP_AT = int(os.getenv("IMS_NOTIFY_ROLLUP_AT", "8"))

# Accounts receivable aging buckets, in days.
AGING_BUCKETS = (30, 60, 90)

# Rows returned by a list endpoint when the client does not say otherwise.
DEFAULT_PAGE_SIZE = 50
MAX_PAGE_SIZE = 500
