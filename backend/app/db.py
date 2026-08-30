"""SQLite access layer.

SQLite in WAL mode gives many concurrent readers plus one writer, which is the
right shape for this workload: a dozen clerks browsing, a few of them saving.
Writes are short and wrapped in `transaction()`, and `busy_timeout` makes a
competing writer wait rather than fail - the quiet equivalent of the legacy
"record is being used by another user, retry?" prompt.
"""

from __future__ import annotations

import sqlite3
import threading
from collections.abc import Iterable, Iterator
from contextlib import contextmanager
from datetime import datetime, timezone
from typing import Any

from . import config

_local = threading.local()


def now() -> str:
    """Current UTC time as an ISO 8601 string."""
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def today() -> str:
    """Today's date where the business is, not in UTC.

    Document dates are business dates: an invoice raised at 8am in Manila is
    dated that day, whatever UTC says. `astimezone()` makes the machine's local
    zone explicit rather than leaving a naive datetime to be guessed at.
    """
    return datetime.now().astimezone().date().isoformat()


def get_connection() -> sqlite3.Connection:
    """One connection per thread, configured for concurrent use."""
    conn = getattr(_local, "conn", None)
    if conn is not None:
        return conn

    config.DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(
        config.DB_PATH,
        timeout=30.0,
        isolation_level=None,       # explicit transactions, see transaction()
        check_same_thread=False,
    )
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA synchronous = NORMAL")
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA busy_timeout = 15000")
    _local.conn = conn
    return conn


@contextmanager
def transaction() -> Iterator[sqlite3.Connection]:
    """Wrap a unit of work. IMMEDIATE takes the write lock up front, so two
    concurrent savers serialise cleanly instead of one failing late."""
    conn = get_connection()
    conn.execute("BEGIN IMMEDIATE")
    try:
        yield conn
    except Exception:
        conn.execute("ROLLBACK")
        raise
    else:
        conn.execute("COMMIT")


def query(sql: str, params: Iterable[Any] = ()) -> list[dict]:
    return [dict(r) for r in get_connection().execute(sql, tuple(params)).fetchall()]


def query_one(sql: str, params: Iterable[Any] = ()) -> dict | None:
    row = get_connection().execute(sql, tuple(params)).fetchone()
    return dict(row) if row else None


def scalar(sql: str, params: Iterable[Any] = (), default: Any = None) -> Any:
    row = get_connection().execute(sql, tuple(params)).fetchone()
    if row is None or row[0] is None:
        return default
    return row[0]


def execute(sql: str, params: Iterable[Any] = ()) -> sqlite3.Cursor:
    return get_connection().execute(sql, tuple(params))


# --------------------------------------------------------------------------- #
# schema and seeding
# --------------------------------------------------------------------------- #

def init_db() -> None:
    """Create the schema if it is missing. Safe to call on every startup."""
    conn = get_connection()
    conn.executescript(config.SCHEMA_PATH.read_text(encoding="utf-8"))
    _seed_sequences(conn)


def _seed_sequences(conn: sqlite3.Connection) -> None:
    defaults = [
        ("invoice", "SI", 1, 6),
        ("purchase", "PI", 1, 6),
        ("return", "SR", 1, 6),
        ("collection", "CR", 1, 6),
        ("adjustment", "ADJ", 1, 6),
    ]
    for name, prefix, start, width in defaults:
        conn.execute(
            "INSERT OR IGNORE INTO sequences(name, prefix, next_value, width) "
            "VALUES (?, ?, ?, ?)",
            (name, prefix, start, width),
        )


def next_document_number(conn: sqlite3.Connection, sequence: str) -> str:
    """Allocate the next document number.

    Must be called inside `transaction()`: the increment and the insert that
    uses the number then commit together, so a number can never be issued twice
    even with several clerks saving at the same moment.
    """
    row = conn.execute(
        "SELECT prefix, next_value, width FROM sequences WHERE name = ?", (sequence,)
    ).fetchone()
    if row is None:
        raise KeyError(f"unknown sequence {sequence!r}")
    conn.execute(
        "UPDATE sequences SET next_value = next_value + 1 WHERE name = ?", (sequence,)
    )
    return f"{row['prefix']}{row['next_value']:0{row['width']}d}"


def bump_sequence_past(conn: sqlite3.Connection, sequence: str, seen: int) -> None:
    """Keep a sequence ahead of numbers already present (used after migration)."""
    conn.execute(
        "UPDATE sequences SET next_value = MAX(next_value, ?) WHERE name = ?",
        (seen + 1, sequence),
    )


# --------------------------------------------------------------------------- #
# auditing
# --------------------------------------------------------------------------- #

def audit(conn: sqlite3.Connection, username: str, action: str,
          entity: str, entity_id: str | None = None, detail: str = "") -> None:
    conn.execute(
        "INSERT INTO audit_log(at, username, action, entity, entity_id, detail) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (now(), username, action, entity, entity_id, detail),
    )
