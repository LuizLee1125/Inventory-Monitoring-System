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
from pathlib import Path
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

def schema_parts() -> list[Path]:
    """The schema files, in the order they must run.

    Filename order is load order, which is why the parts are numbered. Sorting
    plain names would put `100_` before `20_`; the fixed-width numbers make the
    obvious sort the correct one.
    """
    return sorted(config.SCHEMA_DIR.glob("*.sql"))


def reference_schema() -> sqlite3.Connection:
    """An empty in-memory database built from the parts: what the code expects.

    Comparing against a real database beats parsing the .sql files. SQLite has
    already done the parsing, and `PRAGMA table_info` answers in exactly the
    form the comparison needs.
    """
    ref = sqlite3.connect(":memory:")
    ref.row_factory = sqlite3.Row
    for part in schema_parts():
        try:
            ref.executescript(part.read_text(encoding="utf-8"))
        except sqlite3.Error as exc:
            # Name the file. One 'near "x": syntax error' out of a seven-part
            # schema is not enough to go on.
            raise RuntimeError(f"{part.name}: {exc}") from exc
    return ref


def _add_column_sql(table: str, col: sqlite3.Row) -> str:
    """One ALTER TABLE ADD COLUMN, built from the reference column definition.

    `dflt_value` comes back as the literal text as written in the schema ('0',
    "''"), which is what ALTER TABLE wants, so it goes in unquoted.
    """
    sql = f'ALTER TABLE {table} ADD COLUMN "{col["name"]}" {col["type"]}'
    if col["notnull"]:
        if col["dflt_value"] is None:
            # SQLite refuses this outright, and it is right to: there is no
            # value it could put in the existing rows.
            raise RuntimeError(
                f"{table}.{col['name']} is NOT NULL with no DEFAULT, so it "
                f"cannot be added to a database that already has rows. Give it "
                f"a DEFAULT in the schema part, or migrate the table by hand.")
        sql += " NOT NULL"
    if col["dflt_value"] is not None:
        sql += f" DEFAULT {col['dflt_value']}"
    return sql


def _reconcile_columns(conn: sqlite3.Connection,
                       ref: sqlite3.Connection) -> tuple[list[str], list[str]]:
    """Bring an existing database up to what the schema parts declare.

    `CREATE TABLE IF NOT EXISTS` builds a missing table but does nothing at all
    to a table that already exists - so a column added to a schema part would
    never reach a live database, and every read of it would fail one query at a
    time. This closes that gap: new columns are added, and anything the code no
    longer declares is reported rather than dropped.
    """
    added: list[str] = []
    unexpected: list[str] = []

    tables = [r["name"] for r in ref.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name")]

    for table in tables:
        live = {r["name"]: r for r in conn.execute(f"PRAGMA table_info({table})")}
        if not live:
            continue                      # the CREATE above has just made it
        wanted = {r["name"]: r for r in ref.execute(f"PRAGMA table_info({table})")}

        for name, col in wanted.items():
            if name not in live:
                conn.execute(_add_column_sql(table, col))
                added.append(f"{table}.{name}")

        # Never dropped. A column the code stopped declaring may still hold the
        # only copy of something, and no read is broken by its being there.
        unexpected += [f"{table}.{n}" for n in live if n not in wanted]

    return added, unexpected


def init_db() -> list[str]:
    """Build or update the schema. Safe to call on every startup.

    Returns the columns it had to add, which is empty on all but the first run
    after a schema change. Callers print it; nothing depends on it.
    """
    parts = schema_parts()
    if not parts:
        # Without this the server would come up cleanly against an empty
        # database and fail one query at a time, which is a much worse way to
        # find out that IMS_DB or the checkout is wrong.
        raise RuntimeError(f"No schema files found in {config.SCHEMA_DIR}")

    conn = get_connection()
    for part in parts:
        try:
            conn.executescript(part.read_text(encoding="utf-8"))
        except sqlite3.Error as exc:
            raise RuntimeError(f"{part.name}: {exc}") from exc

    ref = reference_schema()
    try:
        added, unexpected = _reconcile_columns(conn, ref)
    finally:
        ref.close()

    if unexpected:
        print(f"  Schema : {len(unexpected)} column(s) in the database that no "
              f"schema part declares: {', '.join(unexpected)}")

    _seed_sequences(conn)
    return added


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
