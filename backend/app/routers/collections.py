"""Collections: customer payments applied to open invoices (successor to COLCFYL.PRG).

A payment can be applied to invoices explicitly, or left to settle the oldest
open invoices first - the way the clerks worked the ledger by hand.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from .. import db, events
from ..deps import clean, money, paged_response, paging, require

router = APIRouter(prefix="/collections", tags=["collections"])


def _load(col_no: str) -> dict:
    header = db.query_one("SELECT * FROM collections WHERE col_no = ?", (col_no,))
    if header is None:
        raise HTTPException(status_code=404, detail=f"No collection {col_no!r}.")
    header["applications"] = db.query(
        "SELECT ca.*, i.inv_date, i.net_amount AS invoice_amount, i.balance "
        "FROM collection_applications ca "
        "LEFT JOIN invoices i ON i.inv_no = ca.inv_no "
        "WHERE ca.col_no = ? ORDER BY ca.id", (col_no,))
    return header


@router.get("")
def list_collections(
    q: str = "",
    customer: str = "",
    method: str = "",
    date_from: str = "",
    date_to: str = "",
    page: int = 1,
    page_size: int = 50,
    _user: dict = Depends(require("collection:read")),
) -> dict:
    where: list[str] = []
    params: list = []
    if q:
        term = f"%{q.strip().upper()}%"
        where.append("(col_no LIKE ? OR customer_name LIKE ? OR reference LIKE ?)")
        params += [term, term, term]
    if customer:
        where.append("customer_code = ?")
        params.append(customer.upper())
    if method:
        where.append("method = ?")
        params.append(method.upper())
    if date_from:
        where.append("col_date >= ?")
        params.append(date_from)
    if date_to:
        where.append("col_date <= ?")
        params.append(date_to)

    clause = f"WHERE {' AND '.join(where)}" if where else ""
    page, page_size = paging(page, page_size)
    total = db.scalar(f"SELECT COUNT(*) FROM collections {clause}", params, 0)
    summary = db.query_one(
        f"SELECT ROUND(SUM(net_amount), 2) AS net FROM collections {clause}",
        params) or {}
    rows = db.query(
        f"SELECT col_no, customer_code, customer_name, col_date, method, reference, "
        f"net_amount, applied_amt, status FROM collections {clause} "
        f"ORDER BY col_date DESC, col_no DESC LIMIT ? OFFSET ?",
        params + [page_size, (page - 1) * page_size])
    result = paged_response(rows, total, page, page_size)
    result["summary"] = {"net": summary.get("net") or 0}
    return result


@router.get("/open-invoices/{customer_code}")
def open_invoices(customer_code: str,
                  _user: dict = Depends(require("collection:read"))) -> list[dict]:
    """What this customer still owes, oldest first - the payment screen's worklist."""
    return db.query(
        "SELECT inv_no, inv_date, due_date, net_amount, paid_amount, balance, "
        "CAST(julianday('now') - julianday(inv_date) AS INTEGER) AS age_days "
        "FROM invoices WHERE customer_code = ? AND balance > 0.005 "
        "AND status <> 'CANCELLED' ORDER BY inv_date, inv_no",
        (customer_code.upper(),))


@router.get("/{col_no}")
def get_collection(col_no: str,
                   _user: dict = Depends(require("collection:read"))) -> dict:
    return _load(col_no.upper())


@router.post("", status_code=201)
def create_collection(payload: dict,
                      user: dict = Depends(require("collection:write"))) -> dict:
    customer_code = clean(payload.get("customer_code"), upper=True)
    amount = money(payload.get("amount"))
    adjustment = money(payload.get("adjustment"))
    if not customer_code:
        raise HTTPException(status_code=400, detail="Choose a customer.")
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Enter a positive amount.")

    col_date = clean(payload.get("col_date")) or db.today()
    method = clean(payload.get("method"), upper=True) or "CASH"
    net = round(amount + adjustment, 2)
    requested = payload.get("applications") or []

    with db.transaction() as conn:
        customer = conn.execute(
            "SELECT * FROM customers WHERE code = ?", (customer_code,)).fetchone()
        if customer is None:
            raise HTTPException(status_code=404, detail=f"No customer {customer_code!r}.")

        col_no = clean(payload.get("col_no"), upper=True) or \
            db.next_document_number(conn, "collection")
        if conn.execute("SELECT 1 FROM collections WHERE col_no = ?", (col_no,)).fetchone():
            raise HTTPException(status_code=409, detail=f"Collection {col_no} exists.")

        # Decide which invoices this payment settles.
        if requested:
            targets = [(clean(a.get("inv_no"), upper=True), money(a.get("amount")))
                       for a in requested if clean(a.get("inv_no"))]
            if round(sum(a for _, a in targets), 2) > net + 0.005:
                raise HTTPException(
                    status_code=400,
                    detail="The amounts applied exceed the payment total.")
        else:
            targets = []
            remaining = net
            for row in conn.execute(
                    "SELECT inv_no, balance FROM invoices WHERE customer_code = ? "
                    "AND balance > 0.005 AND status <> 'CANCELLED' "
                    "ORDER BY inv_date, inv_no", (customer_code,)).fetchall():
                if remaining <= 0.005:
                    break
                take = min(remaining, row["balance"])
                targets.append((row["inv_no"], round(take, 2)))
                remaining = round(remaining - take, 2)

        conn.execute(
            "INSERT INTO collections(col_no, customer_code, customer_name, col_date,"
            " method, reference, amount, adjustment, net_amount, applied_amt, remarks,"
            " status, created_at, created_by) VALUES (?,?,?,?,?,?,?,?,?,0,?,'POSTED',?,?)",
            (col_no, customer_code, customer["name"], col_date, method,
             clean(payload.get("reference")), amount, adjustment, net,
             clean(payload.get("remarks")), db.now(), user["username"]))

        applied_total = 0.0
        for inv_no, apply_amount in targets:
            if apply_amount <= 0:
                continue
            invoice = conn.execute(
                "SELECT * FROM invoices WHERE inv_no = ?", (inv_no,)).fetchone()
            if invoice is None:
                raise HTTPException(status_code=404, detail=f"No invoice {inv_no!r}.")
            if invoice["customer_code"] != customer_code:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invoice {inv_no} belongs to another customer.")
            if apply_amount > invoice["balance"] + 0.005:
                raise HTTPException(
                    status_code=400,
                    detail=f"{apply_amount:,.2f} exceeds the {invoice['balance']:,.2f} "
                           f"still open on invoice {inv_no}.")

            balance = round(invoice["balance"] - apply_amount, 2)
            conn.execute(
                "UPDATE invoices SET paid_amount = ROUND(paid_amount + ?, 2), "
                "balance = ?, status = ?, version = version + 1 WHERE inv_no = ?",
                (apply_amount, balance,
                 "PAID" if balance <= 0.005 else "OPEN", inv_no))
            conn.execute(
                "INSERT INTO collection_applications(col_no, inv_no, amount, check_no,"
                " check_date, check_due, check_amt) VALUES (?,?,?,?,?,?,?)",
                (col_no, inv_no, apply_amount, clean(payload.get("reference")),
                 clean(payload.get("check_date")) or None,
                 clean(payload.get("check_due")) or None,
                 amount if method == "CHECK" else 0))
            applied_total = round(applied_total + apply_amount, 2)

        conn.execute("UPDATE collections SET applied_amt = ? WHERE col_no = ?",
                     (applied_total, col_no))
        conn.execute(
            "UPDATE customers SET balance = ROUND(balance - ?, 2), "
            "payments = ROUND(payments + ?, 2), last_txn = ?, version = version + 1 "
            "WHERE code = ?", (net, net, col_date, customer_code))
        db.audit(conn, user["username"], "create", "collection", col_no,
                 f"{customer_code} {net:,.2f} applied to {len(targets)} invoice(s)")

    batch = events.batch()
    batch.add("collection:created",
              {"col_no": col_no, "customer_code": customer_code,
               "net_amount": net, "applied": applied_total,
               "by": user["username"]},
              permission="collection:read")
    # A payment changes every invoice it settles, and the invoice list is where
    # somebody watches for that. One event per settled document rather than a
    # bare "something changed", so a screen showing one invoice can tell whether
    # it is the one that moved.
    for inv_no, apply_amount in targets:
        if apply_amount > 0:
            batch.add("invoice:updated",
                      {"inv_no": inv_no, "reason": "payment"},
                      permission="invoice:read")
    batch.flush()
    return _load(col_no)


@router.post("/{col_no}/reverse")
def reverse_collection(col_no: str, payload: dict,
                       user: dict = Depends(require("collection:write"))) -> dict:
    """Undo a payment: put the balances back on the invoices and the customer."""
    col_no = col_no.upper()
    reason = clean(payload.get("reason")) or "Reversed"

    with db.transaction() as conn:
        row = conn.execute(
            "SELECT * FROM collections WHERE col_no = ?", (col_no,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail=f"No collection {col_no!r}.")
        if row["status"] == "REVERSED":
            raise HTTPException(status_code=400, detail="Already reversed.")

        restored: list[str] = []
        for application in conn.execute(
                "SELECT * FROM collection_applications WHERE col_no = ?",
                (col_no,)).fetchall():
            restored.append(application["inv_no"])
            conn.execute(
                "UPDATE invoices SET paid_amount = ROUND(paid_amount - ?, 2), "
                "balance = ROUND(balance + ?, 2), status = 'OPEN', "
                "version = version + 1 WHERE inv_no = ?",
                (application["amount"], application["amount"], application["inv_no"]))

        conn.execute(
            "UPDATE customers SET balance = ROUND(balance + ?, 2), "
            "payments = ROUND(payments - ?, 2), version = version + 1 WHERE code = ?",
            (row["net_amount"], row["net_amount"], row["customer_code"]))
        conn.execute(
            "UPDATE collections SET status = 'REVERSED', applied_amt = 0, "
            "remarks = TRIM(remarks || ' [reversed: ' || ? || ']'), "
            "version = version + 1 WHERE col_no = ?", (reason, col_no))
        db.audit(conn, user["username"], "reverse", "collection", col_no, reason)

    batch = events.batch()
    batch.add("collection:reversed",
              {"col_no": col_no, "customer_code": row["customer_code"],
               "reason": reason, "by": user["username"]},
              permission="collection:read")
    for inv_no in restored:
        batch.add("invoice:updated", {"inv_no": inv_no, "reason": "reversal"},
                  permission="invoice:read")
    batch.flush()
    return _load(col_no)
