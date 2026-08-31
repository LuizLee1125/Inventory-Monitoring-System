"""Sales returns: goods coming back from a customer (successor to SRFYL.PRG).

A return puts stock back on the shelf and reduces what the customer owes. If it
names an original invoice, the credit is applied to that invoice first.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from .. import db, events, replenishment
from .. import notifications as alerts
from ..deps import check_version, clean, money, paged_response, paging, require

router = APIRouter(prefix="/returns", tags=["returns"])


def _load(sr_no: str) -> dict:
    header = db.query_one("SELECT * FROM sales_returns WHERE sr_no = ?", (sr_no,))
    if header is None:
        raise HTTPException(status_code=404, detail=f"No sales return {sr_no!r}.")
    header["lines"] = db.query(
        "SELECT * FROM sales_return_lines WHERE sr_no = ? ORDER BY line_no, id", (sr_no,))
    return header


@router.get("")
def list_returns(
    q: str = "",
    customer: str = "",
    date_from: str = "",
    date_to: str = "",
    page: int = 1,
    page_size: int = 50,
    _user: dict = Depends(require("return:read")),
) -> dict:
    where: list[str] = []
    params: list = []
    if q:
        term = f"%{q.strip().upper()}%"
        where.append("(sr_no LIKE ? OR customer_name LIKE ? OR ref_invoice LIKE ?)")
        params += [term, term, term]
    if customer:
        where.append("customer_code = ?")
        params.append(customer.upper())
    if date_from:
        where.append("sr_date >= ?")
        params.append(date_from)
    if date_to:
        where.append("sr_date <= ?")
        params.append(date_to)

    clause = f"WHERE {' AND '.join(where)}" if where else ""
    page, page_size = paging(page, page_size)
    total = db.scalar(f"SELECT COUNT(*) FROM sales_returns {clause}", params, 0)
    summary = db.query_one(
        f"SELECT ROUND(SUM(net_amount), 2) AS net FROM sales_returns {clause}",
        params) or {}
    rows = db.query(
        f"SELECT sr_no, ref_invoice, customer_code, customer_name, sr_date, "
        f"net_amount, status FROM sales_returns {clause} "
        f"ORDER BY sr_date DESC, sr_no DESC LIMIT ? OFFSET ?",
        params + [page_size, (page - 1) * page_size])
    result = paged_response(rows, total, page, page_size)
    result["summary"] = {"net": summary.get("net") or 0}
    return result


@router.get("/{sr_no}")
def get_return(sr_no: str, _user: dict = Depends(require("return:read"))) -> dict:
    return _load(sr_no.upper())


@router.post("", status_code=201)
def create_return(payload: dict,
                  user: dict = Depends(require("return:write"))) -> dict:
    customer_code = clean(payload.get("customer_code"), upper=True)
    raw_lines = payload.get("lines") or []
    if not customer_code:
        raise HTTPException(status_code=400, detail="Choose a customer.")
    if not raw_lines:
        raise HTTPException(status_code=400, detail="Add at least one line.")

    sr_date = clean(payload.get("sr_date")) or db.today()
    ref_invoice = clean(payload.get("ref_invoice"), upper=True)

    with db.transaction() as conn:
        customer = conn.execute(
            "SELECT * FROM customers WHERE code = ?", (customer_code,)).fetchone()
        if customer is None:
            raise HTTPException(status_code=404, detail=f"No customer {customer_code!r}.")

        invoice = None
        if ref_invoice:
            invoice = conn.execute(
                "SELECT * FROM invoices WHERE inv_no = ?", (ref_invoice,)).fetchone()
            if invoice is None:
                raise HTTPException(status_code=404,
                                    detail=f"No invoice {ref_invoice!r} to return against.")
            if invoice["customer_code"] != customer_code:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invoice {ref_invoice} belongs to {invoice['customer_code']}, "
                           f"not {customer_code}.")

        prepared: list[dict] = []
        # On hand as each line leaves it, so a return listing the same code
        # twice writes two ascending `balance_after` values on the ledger rather
        # than the same pre-return figure twice. Same fix as `invoices.py`.
        running: dict[str, float] = {}

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

            unit_price = money(raw.get("unit_price"))
            if not unit_price and invoice is not None:
                original = conn.execute(
                    "SELECT unit_price FROM invoice_lines WHERE inv_no = ? "
                    "AND stock_code = ? LIMIT 1", (ref_invoice, code)).fetchone()
                unit_price = original["unit_price"] if original else item["price_a"]
            unit_price = unit_price or item["price_a"]

            new_qty = round(running.get(code, item["qty_on_hand"]) + qty, 2)
            running[code] = new_qty

            prepared.append({
                "line_no": len(prepared) + 1, "stock_code": code,
                "description": item["name"], "qty": qty,
                "unit": clean(raw.get("unit"), upper=True) or item["unit"],
                "unit_price": unit_price, "line_total": round(qty * unit_price, 2),
                "new_qty": new_qty,
                "division": item["division"], "category": item["category"],
                "unit_cost": item["cost"],
            })

        if not prepared:
            raise HTTPException(status_code=400, detail="Add at least one line.")

        net = round(sum(line["line_total"] for line in prepared), 2)
        sr_no = clean(payload.get("sr_no"), upper=True) or \
            db.next_document_number(conn, "return")
        if conn.execute("SELECT 1 FROM sales_returns WHERE sr_no = ?", (sr_no,)).fetchone():
            raise HTTPException(status_code=409, detail=f"Return {sr_no} already exists.")

        conn.execute(
            "INSERT INTO sales_returns(sr_no, ref_invoice, customer_code, customer_name,"
            " sr_date, remarks, gross, net_amount, applied_amt, status, posted_at,"
            " created_at, created_by) VALUES (?,?,?,?,?,?,?,?,0,'OPEN',?,?,?)",
            (sr_no, ref_invoice, customer_code, customer["name"], sr_date,
             clean(payload.get("remarks")), net, net, db.now(), db.now(),
             user["username"]))

        stamp = db.now()
        for line in prepared:
            conn.execute(
                "INSERT INTO sales_return_lines(sr_no, line_no, stock_code, description,"
                " qty, unit, unit_price, line_total) VALUES (?,?,?,?,?,?,?,?)",
                (sr_no, line["line_no"], line["stock_code"], line["description"],
                 line["qty"], line["unit"], line["unit_price"], line["line_total"]))
            conn.execute(
                "INSERT INTO stock_moves(move_type, doc_no, doc_date, stock_code,"
                " description, qty, unit, unit_cost, unit_price, line_total,"
                " customer_code, division, category, balance_after, created_at, created_by) "
                "VALUES ('RETURN',?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (sr_no, sr_date, line["stock_code"], line["description"], line["qty"],
                 line["unit"], line["unit_cost"], line["unit_price"], line["line_total"],
                 customer_code, line["division"], line["category"], line["new_qty"],
                 stamp, user["username"]))
            conn.execute(
                "UPDATE stock SET qty_on_hand = qty_on_hand + ?, last_txn = ?, "
                "version = version + 1 WHERE code = ?",
                (line["qty"], sr_date, line["stock_code"]))

        # Credit the original invoice first, then the customer's balance.
        applied = 0.0
        if invoice is not None and invoice["balance"] > 0.005:
            applied = min(net, invoice["balance"])
            balance = round(invoice["balance"] - applied, 2)
            conn.execute(
                "UPDATE invoices SET balance = ?, adjustment = ROUND(adjustment + ?, 2), "
                "status = ?, version = version + 1 WHERE inv_no = ?",
                (balance, applied, "PAID" if balance <= 0.005 else "OPEN", ref_invoice))
            conn.execute(
                "UPDATE sales_returns SET applied_amt = ?, "
                "status = ? WHERE sr_no = ?",
                (applied, "PAID" if applied >= net - 0.005 else "OPEN", sr_no))

        conn.execute(
            "UPDATE customers SET balance = ROUND(balance - ?, 2), "
            "returns_total = ROUND(returns_total + ?, 2), last_txn = ?, "
            "version = version + 1 WHERE code = ?",
            (net, net, sr_date, customer_code))
        # Goods coming back are goods on the shelf, so a return can settle a
        # refill note as surely as a delivery can - which is the common case
        # when the wrong item was picked and the right one was sold short.
        refilled = replenishment.resolve_settled(
            conn, [line["stock_code"] for line in prepared],
            username=user["username"])

        db.audit(conn, user["username"], "create", "return", sr_no,
                 f"{customer_code} {net:,.2f} applied {applied:,.2f}")

    if refilled:
        alerts.sweep_kind("stock.refill")

    batch = events.batch()
    batch.add("return:created",
              {"sr_no": sr_no, "customer_code": customer_code,
               "ref_invoice": ref_invoice, "net_amount": net,
               "by": user["username"]},
              permission="return:read")
    if ref_invoice and applied:
        batch.add("invoice:updated", {"inv_no": ref_invoice, "reason": "return"},
                  permission="invoice:read")
    batch.stock_changed(*(line["stock_code"] for line in prepared))
    batch.flush()
    return _load(sr_no)


@router.put("/{sr_no}")
def update_return(sr_no: str, payload: dict,
                  user: dict = Depends(require("return:write"))) -> dict:
    sr_no = sr_no.upper()
    with db.transaction() as conn:
        row = conn.execute(
            "SELECT * FROM sales_returns WHERE sr_no = ?", (sr_no,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail=f"No sales return {sr_no!r}.")
        check_version(row, payload.get("version"), "sales return")
        conn.execute(
            "UPDATE sales_returns SET remarks = ?, version = version + 1 WHERE sr_no = ?",
            (clean(payload.get("remarks")), sr_no))
        db.audit(conn, user["username"], "update", "return", sr_no)
    return _load(sr_no)
