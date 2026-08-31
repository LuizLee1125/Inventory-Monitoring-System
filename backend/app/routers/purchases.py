"""Purchase invoices: receiving stock from suppliers (successor to PURFYL.PRG).

Receiving raises stock on hand and rolls the moving-average cost forward, which
is what the legacy STK_AC field held.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from .. import db, events, replenishment
from .. import notifications as alerts
from ..deps import check_version, clean, money, paged_response, paging, require
from .invoices import discounted

router = APIRouter(prefix="/purchases", tags=["purchases"])


def _load(pur_no: str) -> dict:
    header = db.query_one("SELECT * FROM purchases WHERE pur_no = ?", (pur_no,))
    if header is None:
        raise HTTPException(status_code=404, detail=f"No purchase {pur_no!r}.")
    header["lines"] = db.query(
        "SELECT * FROM purchase_lines WHERE pur_no = ? ORDER BY line_no, id", (pur_no,))
    return header


@router.get("")
def list_purchases(
    q: str = "",
    supplier: str = "",
    status: str = "",
    date_from: str = "",
    date_to: str = "",
    page: int = 1,
    page_size: int = 50,
    _user: dict = Depends(require("purchase:read")),
) -> dict:
    where: list[str] = []
    params: list = []
    if q:
        term = f"%{q.strip().upper()}%"
        where.append("(pur_no LIKE ? OR supplier_name LIKE ?)")
        params += [term, term]
    if supplier:
        where.append("supplier_code = ?")
        params.append(supplier.upper())
    if status:
        where.append("status = ?")
        params.append(status.upper())
    if date_from:
        where.append("pur_date >= ?")
        params.append(date_from)
    if date_to:
        where.append("pur_date <= ?")
        params.append(date_to)

    clause = f"WHERE {' AND '.join(where)}" if where else ""
    page, page_size = paging(page, page_size)
    total = db.scalar(f"SELECT COUNT(*) FROM purchases {clause}", params, 0)
    summary = db.query_one(
        f"SELECT ROUND(SUM(net_amount), 2) AS net, ROUND(SUM(balance), 2) AS balance "
        f"FROM purchases {clause}", params) or {}
    rows = db.query(
        f"SELECT pur_no, supplier_code, supplier_name, pur_date, due_date, "
        f"net_amount, paid_amount, balance, status FROM purchases {clause} "
        f"ORDER BY pur_date DESC, pur_no DESC LIMIT ? OFFSET ?",
        params + [page_size, (page - 1) * page_size])
    result = paged_response(rows, total, page, page_size)
    result["summary"] = {"net": summary.get("net") or 0,
                         "balance": summary.get("balance") or 0}
    return result


@router.get("/{pur_no}")
def get_purchase(pur_no: str, _user: dict = Depends(require("purchase:read"))) -> dict:
    return _load(pur_no.upper())


@router.post("", status_code=201)
def create_purchase(payload: dict,
                    user: dict = Depends(require("purchase:write"))) -> dict:
    supplier_code = clean(payload.get("supplier_code"), upper=True)
    raw_lines = payload.get("lines") or []
    if not supplier_code:
        raise HTTPException(status_code=400, detail="Choose a supplier.")
    if not raw_lines:
        raise HTTPException(status_code=400, detail="Add at least one line.")

    pur_date = clean(payload.get("pur_date")) or db.today()
    d1, d2, d3 = (money(payload.get(k)) for k in ("disc1", "disc2", "disc3"))

    with db.transaction() as conn:
        supplier = conn.execute(
            "SELECT * FROM suppliers WHERE code = ?", (supplier_code,)).fetchone()
        if supplier is None:
            raise HTTPException(status_code=404,
                                detail=f"No supplier {supplier_code!r}.")

        prepared: list[dict] = []
        gross = 0.0

        # Quantity and moving-average cost as each line leaves them.
        #
        # The same fix as the one in `invoices.py`, and it matters more here:
        # this loop writes `qty_on_hand = ?` as an absolute value, so a receipt
        # listing the same code on two lines used to compute both from the
        # pre-receipt balance and the second write discarded the first. Two
        # deliveries of one item on one supplier invoice - which is how a
        # part-shipped order is entered - silently lost a line.
        running: dict[str, tuple[float, float]] = {}

        for index, raw in enumerate(raw_lines, start=1):
            code = clean(raw.get("stock_code"), upper=True)
            qty = money(raw.get("qty"))
            if not code:
                continue
            if qty <= 0:
                raise HTTPException(status_code=400,
                                    detail=f"Line {index}: quantity must be positive.")
            item = conn.execute("SELECT * FROM stock WHERE code = ?", (code,)).fetchone()
            if item is None:
                raise HTTPException(status_code=404,
                                    detail=f"Line {index}: no stock item {code}.")

            unit_cost = money(raw.get("unit_cost")) or item["cost"]
            ld1 = money(raw.get("disc1"))
            line_total = discounted(qty * unit_cost, ld1, 0, 0)
            gross += round(qty * unit_cost, 2)

            on_hand, held_cost = running.get(
                code, (item["qty_on_hand"], item["cost"]))
            # Moving average; if stock was negative or zero, take the new cost.
            new_cost = (round((on_hand * held_cost + qty * unit_cost) / (on_hand + qty), 4)
                        if on_hand + qty > 0 and on_hand > 0 else unit_cost)
            running[code] = (round(on_hand + qty, 2), new_cost)

            prepared.append({
                "line_no": len(prepared) + 1, "stock_code": code,
                "description": item["name"], "qty": qty,
                "unit": clean(raw.get("unit"), upper=True) or item["unit"],
                "unit_cost": unit_cost, "disc1": ld1, "line_total": line_total,
                "lot_no": clean(raw.get("lot_no")) or item["lot_no"],
                "expiry_date": clean(raw.get("expiry_date")) or item["expiry_date"],
                "new_qty": round(on_hand + qty, 2), "new_cost": new_cost,
                "division": item["division"], "category": item["category"],
            })

        if not prepared:
            raise HTTPException(status_code=400, detail="Add at least one line.")

        subtotal = round(sum(line["line_total"] for line in prepared), 2)
        net = discounted(subtotal, d1, d2, d3)
        terms_days = int(payload.get("terms_days") or supplier["terms_days"] or 0)
        pur_no = clean(payload.get("pur_no"), upper=True) or \
            db.next_document_number(conn, "purchase")

        if conn.execute("SELECT 1 FROM purchases WHERE pur_no = ?", (pur_no,)).fetchone():
            raise HTTPException(status_code=409,
                                detail=f"Purchase {pur_no} already exists.")

        conn.execute(
            """
            INSERT INTO purchases(pur_no, supplier_code, supplier_name, pur_date,
                                  due_date, terms_text, terms_days, remarks, gross,
                                  disc1, disc2, disc3, net_amount, paid_amount,
                                  balance, status, posted_at, created_at, created_by)
            VALUES (?,?,?,?,date(?, ?),?,?,?,?,?,?,?,?,0,?,'OPEN',?,?,?)
            """,
            (pur_no, supplier_code, supplier["name"], pur_date, pur_date,
             f"+{terms_days} day", clean(payload.get("terms_text")) or supplier["terms_text"],
             terms_days, clean(payload.get("remarks")), round(gross, 2), d1, d2, d3,
             net, net, db.now(), db.now(), user["username"]))

        stamp = db.now()
        for line in prepared:
            conn.execute(
                "INSERT INTO purchase_lines(pur_no, line_no, stock_code, description,"
                " qty, unit, unit_cost, disc1, line_total, lot_no, expiry_date) "
                "VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                (pur_no, line["line_no"], line["stock_code"], line["description"],
                 line["qty"], line["unit"], line["unit_cost"], line["disc1"],
                 line["line_total"], line["lot_no"], line["expiry_date"]))
            conn.execute(
                "INSERT INTO stock_moves(move_type, doc_no, doc_date, stock_code,"
                " description, qty, unit, unit_cost, line_total, supplier_code,"
                " division, category, lot_no, expiry_date, balance_after,"
                " created_at, created_by) "
                "VALUES ('PURCHASE',?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (pur_no, pur_date, line["stock_code"], line["description"],
                 line["qty"], line["unit"], line["unit_cost"], line["line_total"],
                 supplier_code, line["division"], line["category"], line["lot_no"],
                 line["expiry_date"], line["new_qty"], stamp, user["username"]))
            conn.execute(
                "UPDATE stock SET qty_on_hand = ?, cost = ?, lot_no = ?, "
                "expiry_date = COALESCE(?, expiry_date), last_txn = ?, "
                "version = version + 1 WHERE code = ?",
                (line["new_qty"], line["new_cost"], line["lot_no"],
                 line["expiry_date"], pur_date, line["stock_code"]))

        conn.execute(
            "UPDATE suppliers SET balance = ROUND(balance + ?, 2), "
            "purchases = ROUND(purchases + ?, 2), last_txn = ?, version = version + 1 "
            "WHERE code = ?", (net, net, pur_date, supplier_code))
        # Stock arriving is the whole of what closes a refill note - there is no
        # "mark as handled" button anywhere, deliberately, because the obligation
        # is discharged by the delivery and not by somebody saying it was.
        # `resolve_settled` only closes the codes this receipt brought back to
        # zero or above, so a part shipment leaves the note standing.
        refilled = replenishment.resolve_settled(
            conn, [line["stock_code"] for line in prepared],
            username=user["username"])

        db.audit(conn, user["username"], "create", "purchase", pur_no,
                 f"{supplier_code} {net:,.2f}"
                 + (f" — cleared {refilled} refill note(s)" if refilled else ""))

    if refilled:
        alerts.sweep_kind("stock.refill")

    batch = events.batch()
    batch.add("purchase:created",
              {"pur_no": pur_no, "supplier_code": supplier_code,
               "supplier_name": supplier["name"], "net_amount": net,
               "by": user["username"]},
              permission="purchase:read")
    batch.stock_changed(*(line["stock_code"] for line in prepared))
    batch.flush()
    return _load(pur_no)


@router.post("/{pur_no}/pay")
def pay_purchase(pur_no: str, payload: dict,
                 user: dict = Depends(require("purchase:write"))) -> dict:
    """Record a payment against a supplier invoice."""
    pur_no = pur_no.upper()
    amount = money(payload.get("amount"))
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Enter a positive amount.")

    with db.transaction() as conn:
        row = conn.execute("SELECT * FROM purchases WHERE pur_no = ?", (pur_no,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail=f"No purchase {pur_no!r}.")
        check_version(row, payload.get("version"), "purchase")
        if amount > row["balance"] + 0.005:
            raise HTTPException(
                status_code=400,
                detail=f"Amount exceeds the outstanding balance of {row['balance']:,.2f}.")

        balance = round(row["balance"] - amount, 2)
        conn.execute(
            "UPDATE purchases SET paid_amount = ROUND(paid_amount + ?, 2), balance = ?, "
            "status = ?, version = version + 1 WHERE pur_no = ?",
            (amount, balance, "PAID" if balance <= 0.005 else "OPEN", pur_no))
        conn.execute(
            "UPDATE suppliers SET balance = ROUND(balance - ?, 2), "
            "payments = ROUND(payments + ?, 2), version = version + 1 WHERE code = ?",
            (amount, amount, row["supplier_code"]))
        db.audit(conn, user["username"], "pay", "purchase", pur_no, f"{amount:,.2f}")
    return _load(pur_no)
