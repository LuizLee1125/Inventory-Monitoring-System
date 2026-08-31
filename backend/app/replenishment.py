"""Stock that was sold and is not there: recording it, and closing it out.

The whole of the shortfall rule lives here so that invoicing, receiving, the
report and the alert cannot end up with three different opinions about what
"short" means.

The rule, in one sentence: **a line may take more than is on the shelf, and when
it does, the difference becomes an open obligation on the item until stock comes
back to zero or above.**

Why the sale is allowed at all is a business decision and it belongs in the
schema comment beside `stock.allow_oversell`, not here. What matters to this
module is the consequence: the moment an invoice goes below zero, somebody has
to buy something, and nothing in the old system said so.
"""

from __future__ import annotations

import sqlite3
from collections.abc import Sequence

from . import db


def shortfall(available: float, wanted: float) -> float:
    """How much of `wanted` is not on the shelf.

    `available` is clamped at zero first, and that is the part worth stating:
    an item already at -30 has *nothing* available, not -30 of it. Without the
    clamp a second oversell would be recorded as 30 larger than it is, and the
    buyer would be told to order stock twice over.
    """
    return round(max(0.0, wanted - max(0.0, available)), 2)


def record(conn: sqlite3.Connection, *, doc_no: str, doc_date: str,
           stock_code: str, description: str, unit: str,
           qty_requested: float, qty_available: float, qty_short: float,
           on_hand_after: float, customer_code: str, username: str,
           doc_type: str = "INVOICE") -> None:
    """One obligation. Called inside the document's own transaction, so the
    shortfall and the movement that caused it commit together or not at all."""
    conn.execute(
        "INSERT INTO stock_shortfalls(doc_type, doc_no, doc_date, stock_code,"
        " description, unit, qty_requested, qty_available, qty_short,"
        " on_hand_after, customer_code, created_at, created_by) "
        "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
        (doc_type, doc_no, doc_date, stock_code, description, unit,
         round(qty_requested, 2), round(max(0.0, qty_available), 2),
         round(qty_short, 2), round(on_hand_after, 2), customer_code,
         db.now(), username),
    )


# --------------------------------------------------------------------------- #
# closing them out
# --------------------------------------------------------------------------- #
# An obligation is discharged by stock arriving, not by anybody pressing
# anything. So there is no "mark as handled" button and no endpoint for one:
# every path that raises `qty_on_hand` calls `resolve_settled()`, and the sweep
# calls it too as a net under all of them.

def resolve_settled(conn: sqlite3.Connection, codes: Sequence[str] | None = None,
                    *, username: str = "auto") -> int:
    """Close every open shortfall whose item is back to zero or above.

    `codes` narrows it to the items a receipt just touched, which is the common
    case and one index lookup. Passing nothing sweeps the lot — used from
    `notifications.sweep()` as the safety net, because a path that raises stock
    without telling this module would otherwise leave a refill note open forever
    and the bell would go on asking for a delivery that already arrived.
    """
    where = ["resolved_at IS NULL",
             "EXISTS (SELECT 1 FROM stock s "
             "WHERE s.code = stock_shortfalls.stock_code AND s.qty_on_hand >= 0)"]
    params: list = [db.now(), username]

    if codes is not None:
        wanted = sorted({c.upper() for c in codes if c})
        if not wanted:
            return 0
        where.append(f"stock_code IN ({','.join('?' * len(wanted))})")
        params += wanted

    cur = conn.execute(
        f"UPDATE stock_shortfalls SET resolved_at = ?, resolved_by = ? "
        f"WHERE {' AND '.join(where)}", params)
    return cur.rowcount or 0


def resolve_document(conn: sqlite3.Connection, doc_no: str, username: str,
                     doc_type: str = "INVOICE") -> int:
    """Close the obligations a document created, because the document is gone.

    Cancelling an invoice puts its lines back on the shelf, so whatever it was
    short of is no longer owed to anybody. Without this, cancelling the very
    invoice that caused a refill note would leave the note standing.
    """
    cur = conn.execute(
        "UPDATE stock_shortfalls SET resolved_at = ?, resolved_by = ? "
        "WHERE doc_type = ? AND doc_no = ? AND resolved_at IS NULL",
        (db.now(), username, doc_type, doc_no))
    return cur.rowcount or 0


# --------------------------------------------------------------------------- #
# reading
# --------------------------------------------------------------------------- #

#: One row per item still owing, which is the shape both the alert and the
#: report want. Grouped, because the buyer orders per item and not per invoice —
#: three invoices short of the same box is one purchase order.
OPEN_BY_ITEM_SQL = """
SELECT f.stock_code                    AS code,
       s.name                          AS name,
       COALESCE(NULLIF(f.unit, ''), s.unit) AS unit,
       s.qty_on_hand                   AS qty_on_hand,
       s.reorder_qty                   AS reorder_qty,
       s.supplier_code                 AS supplier_code,
       ROUND(SUM(f.qty_short), 2)      AS qty_short,
       COUNT(*)                        AS documents,
       -- `doc_date`, not `created_at`. The two differ by up to a day: document
       -- dates are business dates in the office's own zone (`db.today()`) and
       -- `created_at` is a UTC timestamp (`db.now()`), so an invoice raised on
       -- the morning of the 1st in Manila was stamped late on the 31st in UTC.
       -- This column sits beside the invoice's own date in the report, and the
       -- two reading a day apart makes the screen look wrong.
       MIN(f.doc_date)                 AS since,
       MAX(f.doc_no)                   AS latest_doc
FROM stock_shortfalls f
JOIN stock s ON s.code = f.stock_code
WHERE f.resolved_at IS NULL
GROUP BY f.stock_code
ORDER BY SUM(f.qty_short) DESC, f.stock_code
"""


def open_by_item() -> list[dict]:
    return db.query(OPEN_BY_ITEM_SQL)


def open_for_document(doc_no: str, doc_type: str = "INVOICE") -> list[dict]:
    """The shortfalls one document created, for its own detail screen."""
    return db.query(
        "SELECT stock_code, description, unit, qty_requested, qty_available, "
        "qty_short, on_hand_after, created_at, resolved_at "
        "FROM stock_shortfalls WHERE doc_type = ? AND doc_no = ? "
        "ORDER BY stock_code", (doc_type, doc_no))
