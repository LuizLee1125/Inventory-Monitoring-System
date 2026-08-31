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

# Backups, named ims-YYYYMMDD-HHMMSS.sqlite (with -auto for the scheduled ones).
# Defined here rather than in the router so dump_db.py can find them too.
BACKUP_DIR = DB_PATH.parent / "backups"

# How long a backup is kept. The DOS system rotated Monday-to-Saturday floppies;
# this is the same week, without anybody carrying a box to the safe.
BACKUP_KEEP_DAYS = int(os.getenv("IMS_BACKUP_DAYS", "7"))

# ...and the floor that age alone cannot go below. An office that closes for a
# fortnight would otherwise come back to a backup folder that had tidied itself
# empty, which is the one state a backup system must never reach.
BACKUP_KEEP_MIN = int(os.getenv("IMS_BACKUP_KEEP_MIN", "3"))

# Hours between automatic backups. 0 turns them off and leaves only the button
# on the maintenance screen. A week of retention means little if the only
# backups in it are the ones somebody remembered to take.
BACKUP_EVERY_HOURS = int(os.getenv("IMS_BACKUP_HOURS", "24"))

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

# Accounts receivable aging buckets, in days.
AGING_BUCKETS = (30, 60, 90)

# Rows returned by a list endpoint when the client does not say otherwise.
DEFAULT_PAGE_SIZE = 50
MAX_PAGE_SIZE = 500
