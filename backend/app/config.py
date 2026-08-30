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
SCHEMA_PATH = APP_DIR / "schema.sql"

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
