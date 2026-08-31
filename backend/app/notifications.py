"""Alerts the server raises for itself.

The office runs this on a PC in the corner, and the things worth knowing about
— an item reaching its reorder point, a lot coming up to expiry, a scheduled
backup that failed — all become true while nobody is looking at the screen. A
toast cannot carry any of them, so they are raised here, stored, and read back
per user whenever somebody next signs in.

Two kinds of alert, and the difference matters:

*Conditions* are swept. `sweep()` asks each source what is true right now,
opens what is newly true and closes what no longer is. Nothing outside this
module decides when they start or stop.

*Events* are raised by whoever noticed — `raise_alert()` from the backup
scheduler — and closed the same way with `resolve()`. Nothing sweeps them,
because there is no query that could ask "did the backup fail?" after the fact.
"""

from __future__ import annotations

from collections.abc import Callable, Iterable, Sequence
from typing import Any

from . import config, db

# --------------------------------------------------------------------------- #
# conditions
# --------------------------------------------------------------------------- #
# Each source is a query plus the three functions that turn one of its rows into
# an alert. The SQL is deliberately the same shape as the report that shows the
# same thing (`routers/reports.py` `depleted()` and `expiring()`): if the two
# ever disagree about what "below reorder point" means, the screen and the bell
# are telling the office different things.


class Condition:
    """One query, plus how to say what it found.

    `report` is where the interface should send somebody who wants the whole
    list, and it is what the rolled-up form links to.
    """

    def __init__(self, kind: str, permission: str, entity: str, sql: str,
                 params: Sequence[Any], key: Callable[[dict], str],
                 title: Callable[[dict], str], body: Callable[[dict], str],
                 report: str, rollup: Callable[[int], str],
                 severity: Callable[[dict], str] | str = "warn"):
        self.kind = kind
        self.permission = permission
        self.entity = entity
        self.sql = sql
        self.params = params
        self.key = key
        self.title = title
        self.body = body
        self.report = report
        self.rollup = rollup
        self._severity = severity

    def severity(self, row: dict) -> str:
        return self._severity(row) if callable(self._severity) else self._severity

    @property
    def rollup_key(self) -> str:
        """The single row a rolled-up condition occupies. `:*` cannot collide
        with a per-item key, because a stock code never contains an asterisk."""
        return f"{self.kind}:*"


def _qty(row: dict, field: str = "qty_on_hand") -> str:
    value = float(row.get(field) or 0)
    text = f"{value:,.2f}".rstrip("0").rstrip(".")
    return text or "0"


def _conditions() -> list[Condition]:
    """Built per call so a changed `NOTIFY_EXPIRY_DAYS` is picked up."""
    return [
        # Depleted and below-reorder are one list each, and they do not overlap:
        # `qty_on_hand > 0` on the second. An item that is both is one problem,
        # not two — the same call `dashboard()` makes when it counts
        # `needs_attention` as a distinct count.
        Condition(
            kind="stock.depleted",
            permission="stock:read",
            entity="stock",
            sql="SELECT code, name, unit FROM stock "
                "WHERE is_active = 1 AND qty_on_hand <= 0 ORDER BY code",
            params=(),
            key=lambda r: f"stock.depleted:{r['code']}",
            title=lambda r: f"{r['name']} is out of stock",
            body=lambda r: f"{r['code']} — nothing on hand.",
            report="/reports/depleted",
            rollup=lambda n: f"{n:,} items show nothing on hand",
            severity="error",
        ),
        Condition(
            kind="stock.reorder",
            permission="stock:read",
            entity="stock",
            sql="SELECT code, name, unit, qty_on_hand, reorder_point, reorder_qty "
                "FROM stock WHERE is_active = 1 AND reorder_point > 0 "
                "AND qty_on_hand > 0 AND qty_on_hand <= reorder_point ORDER BY code",
            params=(),
            key=lambda r: f"stock.reorder:{r['code']}",
            title=lambda r: f"{r['name']} is at its reorder point",
            body=lambda r: (f"{r['code']} — {_qty(r)} {r['unit'] or ''}".rstrip()
                            + f" on hand, reorder point {_qty(r, 'reorder_point')}."),
            report="/reports/depleted",
            rollup=lambda n: f"{n:,} items are at their reorder point",
            severity="warn",
        ),
        # The lot is part of the key: two lots of one item expire on different
        # days and are two things to act on.
        Condition(
            kind="stock.expiring",
            permission="stock:read",
            entity="stock",
            sql="SELECT code, name, unit, lot_no, expiry_date, qty_on_hand, "
                "CAST(julianday(expiry_date) - julianday('now') AS INTEGER) AS days_left "
                "FROM stock WHERE is_active = 1 AND expiry_date IS NOT NULL "
                "AND qty_on_hand > 0 AND expiry_date <= date('now', ?) "
                "ORDER BY expiry_date",
            params=(f"+{config.NOTIFY_EXPIRY_DAYS} day",),
            key=lambda r: f"stock.expiring:{r['code']}:{r['lot_no'] or '-'}",
            title=lambda r: (
                f"{r['name']} has expired" if (r["days_left"] or 0) < 0
                else f"{r['name']} expires in {r['days_left']} days"),
            body=lambda r: (
                f"{r['code']}"
                + (f", lot {r['lot_no']}" if r["lot_no"] else "")
                + f" — {_qty(r)} {r['unit'] or ''}".rstrip()
                + f" on hand, dated {r['expiry_date']}."),
            report="/reports/expiring",
            rollup=lambda n: f"{n:,} items are near or past their expiry date",
            # An item already past its date is not the same message as one with
            # two months left, and the row is raised once, so the difference has
            # to be in the severity rather than left to the reader.
            severity=lambda r: "error" if (r["days_left"] or 0) < 0 else "warn",
        ),
    ]


# --------------------------------------------------------------------------- #
# raising and closing
# --------------------------------------------------------------------------- #

def raise_alert(kind: str, title: str, *, body: str = "", severity: str = "warn",
                permission: str = "report:read", entity: str = "",
                entity_id: str = "", key: str | None = None) -> None:
    """Open an alert, or refresh it if it is already open.

    Safe to call repeatedly: `dedupe_key` is unique, so the tenth failed backup
    in a row updates one row rather than adding a tenth.
    """
    with db.transaction() as conn:
        _upsert(conn, key or kind, kind=kind, severity=severity, title=title,
                body=body, entity=entity, entity_id=entity_id,
                permission=permission)


def resolve(key: str) -> None:
    """Close an alert by its key, if it is open. A no-op when it is not."""
    with db.transaction() as conn:
        conn.execute(
            "UPDATE notifications SET resolved_at = ? "
            "WHERE dedupe_key = ? AND resolved_at IS NULL",
            (db.now(), key),
        )


def _upsert(conn, key: str, **fields: Any) -> None:
    """Insert, refresh or re-open one alert.

    Re-opening is the case worth spelling out. A resolved row is reused rather
    than a second one being inserted — the key is unique — so it gets a new
    `raised_at` and its read rows are cleared. Without that clear, an item
    restocked and then run down again would arrive already-read for everybody
    who saw it the first time, which is the one outcome that makes the whole
    feature untrustworthy.
    """
    existing = conn.execute(
        "SELECT id, resolved_at FROM notifications WHERE dedupe_key = ?", (key,)
    ).fetchone()

    if existing is None:
        conn.execute(
            "INSERT INTO notifications"
            "(kind, severity, title, body, entity, entity_id, permission,"
            " dedupe_key, raised_at) "
            "VALUES (:kind, :severity, :title, :body, :entity, :entity_id,"
            " :permission, :key, :raised_at)",
            {**fields, "key": key, "raised_at": db.now()},
        )
        return

    if existing["resolved_at"] is not None:
        conn.execute(
            "UPDATE notifications SET severity = :severity, title = :title, "
            "body = :body, raised_at = :raised_at, resolved_at = NULL "
            "WHERE id = :id",
            {**fields, "id": existing["id"], "raised_at": db.now()},
        )
        conn.execute("DELETE FROM notification_reads WHERE notification_id = ?",
                     (existing["id"],))
        return

    # Open already: keep `raised_at` — this is still the same event — but let
    # the wording follow the figures, so a quantity that fell further is not
    # reported at the number it had a fortnight ago.
    conn.execute(
        "UPDATE notifications SET severity = :severity, title = :title, "
        "body = :body WHERE id = :id",
        {**fields, "id": existing["id"]},
    )


def _chunks(values: Sequence[Any], size: int = 400) -> Iterable[Sequence[Any]]:
    """SQLite caps the parameters in one statement, and a first sweep against a
    real database can produce thousands of ids."""
    for start in range(0, len(values), size):
        yield values[start:start + size]


def sweep() -> dict:
    """One pass over every condition. Returns what changed, for the log.

    Runs on a worker thread from the same tick as the backup schedule, so it
    must not assume a request context and must not raise: a failing sweep is a
    missing alert, and it must never take the server down with it.

    A condition matching more than `NOTIFY_ROLLUP_AT` rows collapses to a single
    alert carrying the count and a link to the report. That is not a cap or a
    truncation — nothing is dropped, the report still lists every line — it is
    the recognition that a bell holding two thousand rows tells you less than
    one row saying "two thousand". The two forms are mutually exclusive per
    kind, and crossing the threshold in either direction closes the other.
    """
    opened = 0
    closed = 0

    for condition in _conditions():
        rows = db.query(condition.sql, condition.params)
        rolled = len(rows) > config.NOTIFY_ROLLUP_AT

        if rolled:
            # One row, and the examples in the body so it is not just a number.
            examples = ", ".join(str(r.get("code") or "") for r in rows[:3])
            wanted = {
                condition.rollup_key: dict(
                    kind=condition.kind,
                    severity=max((condition.severity(r) for r in rows),
                                 key=lambda s: ("info", "warn", "error").index(s)),
                    title=condition.rollup(len(rows)),
                    body=f"Including {examples}"
                         + (f" and {len(rows) - 3:,} more." if len(rows) > 3 else "."),
                    entity="report",
                    entity_id=condition.report,
                    permission=condition.permission,
                )
            }
        else:
            wanted = {
                condition.key(row): dict(
                    kind=condition.kind,
                    severity=condition.severity(row),
                    title=condition.title(row),
                    body=condition.body(row),
                    entity=condition.entity,
                    entity_id=str(row.get("code") or ""),
                    permission=condition.permission,
                )
                for row in rows
            }

        with db.transaction() as conn:
            known = {r["dedupe_key"]: r["id"] for r in conn.execute(
                "SELECT id, dedupe_key FROM notifications "
                "WHERE kind = ? AND resolved_at IS NULL", (condition.kind,))}

            # Close first, in batches: a first sweep after the threshold is
            # crossed has two thousand per-item rows to retire, and SQLite caps
            # the parameters one statement may carry.
            stale = [id_ for key, id_ in known.items() if key not in wanted]
            for batch in _chunks(stale):
                conn.execute(
                    f"UPDATE notifications SET resolved_at = ? WHERE id IN "
                    f"({','.join('?' * len(batch))})",
                    (db.now(), *batch),
                )
            closed += len(stale)

            for key, fields in wanted.items():
                if key not in known:
                    opened += 1
                _upsert(conn, key, **fields)

    return {"opened": opened, "closed": closed}


# --------------------------------------------------------------------------- #
# reading
# --------------------------------------------------------------------------- #
# Visibility is by permission, not by role. A notification names the permission
# needed to see it and the query filters on what the signed-in user holds, so a
# sales clerk is never told the backup failed and nothing has to be kept in step
# with a second list of roles.

def _visible(user: dict) -> tuple[str, list[str]]:
    permissions = list(user.get("permissions") or [])
    if not permissions:
        return "0", []
    return f"n.permission IN ({','.join('?' * len(permissions))})", permissions


def unread_count(user: dict) -> int:
    """Open and unread. A resolved alert stops counting even if it was never
    read — the badge is a count of things wanting attention, and something that
    has already fixed itself does not. It stays in the list either way."""
    clause, params = _visible(user)
    return int(db.scalar(
        f"SELECT COUNT(*) FROM notifications n "
        f"LEFT JOIN notification_reads r "
        f"  ON r.notification_id = n.id AND r.user_id = ? "
        f"WHERE n.resolved_at IS NULL AND r.notification_id IS NULL AND {clause}",
        (user["id"], *params), default=0))


def list_for(user: dict, *, unread_only: bool = False, open_only: bool = True,
             limit: int = 50, offset: int = 0) -> list[dict]:
    clause, params = _visible(user)
    where = [clause]
    if open_only:
        where.append("n.resolved_at IS NULL")
    if unread_only:
        where.append("r.notification_id IS NULL")
    return db.query(
        f"SELECT n.id, n.kind, n.severity, n.title, n.body, n.entity, n.entity_id, "
        f"       n.raised_at, n.resolved_at, "
        f"       CASE WHEN r.notification_id IS NULL THEN 0 ELSE 1 END AS is_read "
        f"FROM notifications n "
        f"LEFT JOIN notification_reads r "
        f"  ON r.notification_id = n.id AND r.user_id = ? "
        f"WHERE {' AND '.join(where)} "
        f"ORDER BY n.raised_at DESC, n.id DESC LIMIT ? OFFSET ?",
        (user["id"], *params, max(1, min(limit, 200)), max(0, offset)))


def count_for(user: dict, *, unread_only: bool = False,
              open_only: bool = True) -> int:
    clause, params = _visible(user)
    where = [clause]
    if open_only:
        where.append("n.resolved_at IS NULL")
    if unread_only:
        where.append("r.notification_id IS NULL")
    return int(db.scalar(
        f"SELECT COUNT(*) FROM notifications n "
        f"LEFT JOIN notification_reads r "
        f"  ON r.notification_id = n.id AND r.user_id = ? "
        f"WHERE {' AND '.join(where)}",
        (user["id"], *params), default=0))


def mark_read(user: dict, ids: Sequence[int]) -> int:
    """Mark specific rows read. Silently ignores ids the user cannot see, so a
    stale panel cannot be used to mark somebody else's alerts."""
    wanted = [int(i) for i in ids][:500]
    if not wanted:
        return 0
    clause, params = _visible(user)
    allowed = [row["id"] for row in db.query(
        f"SELECT n.id FROM notifications n "
        f"WHERE n.id IN ({','.join('?' * len(wanted))}) AND {clause}",
        (*wanted, *params))]
    if not allowed:
        return 0
    now = db.now()
    with db.transaction() as conn:
        conn.executemany(
            "INSERT OR IGNORE INTO notification_reads"
            "(notification_id, user_id, read_at) VALUES (?, ?, ?)",
            [(i, user["id"], now) for i in allowed],
        )
    return len(allowed)


def mark_all_read(user: dict) -> int:
    """Everything currently open and visible. Deliberately not the resolved
    history: marking a hundred closed rows read tells nobody anything, and the
    badge does not count them."""
    clause, params = _visible(user)
    now = db.now()
    with db.transaction() as conn:
        cur = conn.execute(
            f"INSERT OR IGNORE INTO notification_reads"
            f"(notification_id, user_id, read_at) "
            f"SELECT n.id, ?, ? FROM notifications n "
            f"WHERE n.resolved_at IS NULL AND {clause}",
            (user["id"], now, *params),
        )
    return cur.rowcount or 0
