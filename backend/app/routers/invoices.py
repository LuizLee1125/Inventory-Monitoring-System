"""Sales invoices: the successor to SIFYL.PRG and its print programs.

Creating an invoice is one transaction that writes the header, the lines, a
stock movement per line, decrements stock on hand, and raises the customer's
balance. Either all of it lands or none of it does - the legacy system could
leave a half-posted invoice behind if a workstation died mid-save.

**Two clerks, one item.** An item shows 100. One clerk invoices 80 and saves;
the second, whose screen was fetched before that save, invoices 50. The second
invoice goes through. That is deliberate: for anything the office can reorder
quickly, a sale is worth more than a tidy stock figure, and the clerk was
looking at a number that was correct when it was drawn.

What must not happen is that it goes through *silently*. The 30 that were
promised and are not there become a row in `stock_shortfalls`, a refill alert to
whoever buys, and a line on the invoice marked short. `stock.allow_oversell`
turns the concession off per item, for the few that genuinely cannot be
promised; see the schema comment beside the column.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from .. import db, events, replenishment
from .. import notifications as alerts
from ..deps import check_version, clean, money, paged_response, paging, require

router = APIRouter(prefix="/invoices", tags=["invoices"])

PRICE_COLUMN = {"A": "price_a", "B": "price_b", "C": "price_c",
                "D": "price_d", "E": "price_e"}


def discounted(amount: float, d1: float, d2: float, d3: float) -> float:
    """Successive percentage discounts, the way the DOS screens applied them."""
    for pct in (d1, d2, d3):
        if pct:
            amount *= (1 - pct / 100)
    return round(amount, 2)


def _load(inv_no: str) -> dict:
    header = db.query_one("SELECT * FROM invoices WHERE inv_no = ?", (inv_no,))
    if header is None:
        raise HTTPException(status_code=404, detail=f"No invoice {inv_no!r}.")
    header["lines"] = db.query(
        "SELECT * FROM invoice_lines WHERE inv_no = ? ORDER BY line_no, id", (inv_no,))
    header["payments"] = db.query(
        "SELECT ca.col_no, c.col_date, ca.amount, c.method, ca.check_no "
        "FROM collection_applications ca JOIN collections c ON c.col_no = ca.col_no "
        "WHERE ca.inv_no = ? ORDER BY c.col_date", (inv_no,))
    # Only fetched for the few invoices that have any. `short_lines` is on the
    # header precisely so the list screen never has to ask this question.
    header["shortfalls"] = (replenishment.open_for_document(inv_no)
                            if header.get("short_lines") else [])
    return header


@router.get("")
def list_invoices(
    q: str = "",
    customer: str = "",
    salesman: str = "",
    status: str = "",
    date_from: str = "",
    date_to: str = "",
    unpaid_only: bool = False,
    sort: str = "date",
    direction: str = "desc",
    page: int = 1,
    page_size: int = 50,
    _user: dict = Depends(require("invoice:read")),
) -> dict:
    where: list[str] = []
    params: list = []
    if q:
        term = f"%{q.strip().upper()}%"
        where.append("(inv_no LIKE ? OR customer_name LIKE ? OR customer_code LIKE ?)")
        params += [term, term, term]
    if customer:
        where.append("customer_code = ?")
        params.append(customer.upper())
    if salesman:
        where.append("salesman = ?")
        params.append(salesman.upper())
    if status:
        where.append("status = ?")
        params.append(status.upper())
    if date_from:
        where.append("inv_date >= ?")
        params.append(date_from)
    if date_to:
        where.append("inv_date <= ?")
        params.append(date_to)
    if unpaid_only:
        where.append("balance > 0.005")

    clause = f"WHERE {' AND '.join(where)}" if where else ""
    order = {"date": "inv_date", "number": "inv_no", "amount": "net_amount",
             "balance": "balance", "customer": "customer_name"}.get(sort, "inv_date")
    order_dir = "ASC" if direction.lower() == "asc" else "DESC"
    page, page_size = paging(page, page_size)

    total = db.scalar(f"SELECT COUNT(*) FROM invoices {clause}", params, 0)
    summary = db.query_one(
        f"SELECT ROUND(SUM(net_amount), 2) AS net, ROUND(SUM(balance), 2) AS balance "
        f"FROM invoices {clause}", params) or {}
    rows = db.query(
        f"SELECT inv_no, customer_code, customer_name, inv_date, due_date, salesman, "
        f"net_amount, paid_amount, balance, status FROM invoices {clause} "
        f"ORDER BY {order} {order_dir}, inv_no {order_dir} LIMIT ? OFFSET ?",
        params + [page_size, (page - 1) * page_size])

    result = paged_response(rows, total, page, page_size)
    result["summary"] = {"net": summary.get("net") or 0,
                         "balance": summary.get("balance") or 0}
    return result


@router.get("/{inv_no}")
def get_invoice(inv_no: str, _user: dict = Depends(require("invoice:read"))) -> dict:
    return _load(inv_no.upper())


@router.post("", status_code=201)
def create_invoice(payload: dict,
                   user: dict = Depends(require("invoice:write"))) -> dict:
    customer_code = clean(payload.get("customer_code"), upper=True)
    raw_lines = payload.get("lines") or []
    if not customer_code:
        raise HTTPException(status_code=400, detail="Choose a customer.")
    if not raw_lines:
        raise HTTPException(status_code=400, detail="Add at least one line.")

    inv_date = clean(payload.get("inv_date")) or db.today()
    d1, d2, d3 = (money(payload.get(k)) for k in ("disc1", "disc2", "disc3"))

    with db.transaction() as conn:
        customer = conn.execute(
            "SELECT * FROM customers WHERE code = ?", (customer_code,)).fetchone()
        if customer is None:
            raise HTTPException(status_code=404,
                                detail=f"No customer {customer_code!r}.")

        price_cat = (clean(payload.get("price_cat"), upper=True)
                     or customer["price_cat"] or "A")[:1]
        price_column = PRICE_COLUMN.get(price_cat, "price_a")

        prepared: list[dict] = []
        gross = 0.0
        cost_total = 0.0

        # Stock on hand as each line leaves it, keyed by code.
        #
        # This is not about the other clerk - `db.transaction()` is
        # BEGIN IMMEDIATE, so two savers genuinely serialise and the balance
        # arithmetic is safe. It is about *this* document: an invoice listing
        # the same code on two lines used to write the pre-invoice balance on
        # both, because every line re-read the row fetched at the top. One
        # clerk, one document, and the ledger's `balance_after` was wrong.
        running: dict[str, float] = {}

        for index, raw in enumerate(raw_lines, start=1):
            code = clean(raw.get("stock_code"), upper=True)
            qty = money(raw.get("qty"))
            if not code:
                continue
            if qty <= 0:
                # The DOS version stopped accepting qty <= 0 in April 1999.
                raise HTTPException(status_code=400,
                                    detail=f"Line {index}: quantity must be positive.")
            item = conn.execute("SELECT * FROM stock WHERE code = ?", (code,)).fetchone()
            if item is None:
                raise HTTPException(status_code=404,
                                    detail=f"Line {index}: no stock item {code}.")

            available = running.get(code, item["qty_on_hand"])
            short = replenishment.shortfall(available, qty)

            # The one case that refuses. An item marked not-oversellable cannot
            # be promised from stock that is not there, so the clerk is told the
            # real number rather than discovering it at the loading bay.
            if short > 0 and not item["allow_oversell"]:
                raise HTTPException(
                    status_code=409,
                    detail=f"Line {index}: {code} has {max(0.0, available):,.2f} "
                           f"{item['unit'] or ''}".rstrip()
                           + f" on hand and this line needs {qty:,.2f}. "
                             f"This item cannot be sold beyond what is in stock — "
                             f"reduce the quantity or receive the purchase first.")

            new_qty = round(available - qty, 2)
            running[code] = new_qty

            unit_price = money(raw.get("unit_price")) or item[price_column]
            ld1, ld2, ld3 = (money(raw.get(k)) for k in ("disc1", "disc2", "disc3"))
            line_total = discounted(qty * unit_price, ld1, ld2, ld3)
            gross += round(qty * unit_price, 2)
            cost_total += round(qty * item["cost"], 2)

            prepared.append({
                "line_no": len(prepared) + 1, "stock_code": code,
                "description": item["name"], "qty": qty,
                "unit": clean(raw.get("unit"), upper=True) or item["unit"],
                "unit_price": unit_price, "unit_cost": item["cost"],
                "disc1": ld1, "disc2": ld2, "disc3": ld3, "line_total": line_total,
                "lot_no": item["lot_no"], "expiry_date": item["expiry_date"],
                "division": item["division"], "category": item["category"],
                "new_qty": new_qty,
                "available": max(0.0, available), "qty_short": short,
            })

        if not prepared:
            raise HTTPException(status_code=400, detail="Add at least one line.")

        short_lines = [line for line in prepared if line["qty_short"] > 0]

        subtotal = round(sum(line["line_total"] for line in prepared), 2)
        net = discounted(subtotal, d1, d2, d3)
        terms_days = int(payload.get("terms_days") or customer["terms_days"] or 0)
        inv_no = clean(payload.get("inv_no"), upper=True) or \
            db.next_document_number(conn, "invoice")

        if conn.execute("SELECT 1 FROM invoices WHERE inv_no = ?", (inv_no,)).fetchone():
            raise HTTPException(status_code=409,
                                detail=f"Invoice {inv_no} already exists.")

        conn.execute(
            """
            INSERT INTO invoices(inv_no, customer_code, customer_name, address, city,
                                 inv_date, due_date, terms_text, terms_days, price_cat,
                                 salesman, remarks, gross, disc1, disc2, disc3,
                                 discount_amt, net_amount, cost_amount, paid_amount,
                                 balance, status, short_lines,
                                 posted_at, created_at, created_by)
            VALUES (?,?,?,?,?,?,date(?, ?),?,?,?,?,?,?,?,?,?,?,?,?,0,?,'OPEN',?,?,?,?)
            """,
            (inv_no, customer_code, customer["name"], customer["address"],
             customer["city"], inv_date, inv_date, f"+{terms_days} day",
             clean(payload.get("terms_text")) or customer["terms_text"], terms_days,
             price_cat, clean(payload.get("salesman"), upper=True) or customer["salesman"],
             clean(payload.get("remarks")), round(gross, 2), d1, d2, d3,
             round(gross - net, 2), net, round(cost_total, 2), net, len(short_lines),
             db.now(), db.now(), user["username"]),
        )

        stamp = db.now()
        for line in prepared:
            conn.execute(
                "INSERT INTO invoice_lines(inv_no, line_no, stock_code, description,"
                " qty, unit, unit_price, unit_cost, disc1, disc2, disc3, line_total,"
                " lot_no, expiry_date, qty_short) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (inv_no, line["line_no"], line["stock_code"], line["description"],
                 line["qty"], line["unit"], line["unit_price"], line["unit_cost"],
                 line["disc1"], line["disc2"], line["disc3"], line["line_total"],
                 line["lot_no"], line["expiry_date"], line["qty_short"]))
            if line["qty_short"] > 0:
                # In the same transaction as the movement that caused it, so the
                # obligation and the negative balance can never disagree.
                replenishment.record(
                    conn, doc_no=inv_no, doc_date=inv_date,
                    stock_code=line["stock_code"], description=line["description"],
                    unit=line["unit"], qty_requested=line["qty"],
                    qty_available=line["available"], qty_short=line["qty_short"],
                    on_hand_after=line["new_qty"], customer_code=customer_code,
                    username=user["username"])
            conn.execute(
                "INSERT INTO stock_moves(move_type, doc_no, doc_date, stock_code,"
                " description, qty, unit, unit_cost, unit_price, line_total,"
                " customer_code, division, category, lot_no, expiry_date,"
                " balance_after, created_at, created_by) "
                "VALUES ('SALE',?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (inv_no, inv_date, line["stock_code"], line["description"],
                 -line["qty"], line["unit"], line["unit_cost"], line["unit_price"],
                 line["line_total"], customer_code, line["division"], line["category"],
                 line["lot_no"], line["expiry_date"], line["new_qty"], stamp,
                 user["username"]))
            conn.execute(
                "UPDATE stock SET qty_on_hand = qty_on_hand - ?, last_txn = ?, "
                "version = version + 1 WHERE code = ?",
                (line["qty"], inv_date, line["stock_code"]))

        conn.execute(
            "UPDATE customers SET balance = ROUND(balance + ?, 2), "
            "purchases = ROUND(purchases + ?, 2), last_txn = ?, version = version + 1 "
            "WHERE code = ?", (net, net, inv_date, customer_code))
        db.audit(conn, user["username"], "create", "invoice", inv_no,
                 f"{customer_code} {net:,.2f}"
                 + (f" — {len(short_lines)} line(s) short" if short_lines else ""))

    # Everything below here is after the commit, and deliberately so: an alert or
    # an event published inside the transaction would be visible to a client that
    # then asked for an invoice the readers cannot see yet, and would survive a
    # rollback as an announcement of something that never happened.

    if short_lines:
        # Straight through the ordinary sweep rather than a hand-written
        # `raise_alert`, so the wording, the severity and the roll-up threshold
        # are the same ones the fifteen-minute timer would produce. Two code
        # paths writing the same alert differently would flip-flop every quarter
        # of an hour as each rewrote the other.
        alerts.sweep_kind("stock.refill")

    batch = events.batch()
    batch.add("invoice:created",
              {"inv_no": inv_no, "customer_code": customer_code,
               "customer_name": customer["name"], "net_amount": net,
               "short_lines": len(short_lines), "by": user["username"]},
              permission="invoice:read")
    batch.stock_changed(*(line["stock_code"] for line in prepared))
    if short_lines:
        # Its own event, so a screen can react to *this* without listening to
        # every stock movement in the building. The permission matches the alert:
        # the answer to a shortfall is a purchase order.
        batch.add("stock:short",
                  {"inv_no": inv_no, "by": user["username"],
                   "items": [{"code": line["stock_code"],
                              "name": line["description"],
                              "qty_short": line["qty_short"],
                              "on_hand": line["new_qty"]}
                             for line in short_lines]},
                  permission="purchase:read")
    batch.flush()

    invoice = _load(inv_no)
    # Named separately from `shortfalls` on the loaded document: this is what
    # went short *on this save*, which is what the clerk who just pressed the
    # button needs told, and it stays right even if the item is refilled a
    # minute later and the stored rows resolve.
    invoice["short_now"] = [
        {"stock_code": line["stock_code"], "description": line["description"],
         "unit": line["unit"], "qty": line["qty"], "available": line["available"],
         "qty_short": line["qty_short"], "on_hand_after": line["new_qty"]}
        for line in short_lines
    ]
    return invoice


@router.put("/{inv_no}")
def update_invoice(inv_no: str, payload: dict,
                   user: dict = Depends(require("invoice:write"))) -> dict:
    """Header-level edits only. Lines are immutable once posted; correct an
    invoice with a sales return or cancel and reissue, which is what the
    business did on paper anyway."""
    inv_no = inv_no.upper()
    with db.transaction() as conn:
        row = conn.execute("SELECT * FROM invoices WHERE inv_no = ?", (inv_no,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail=f"No invoice {inv_no!r}.")
        check_version(row, payload.get("version"), "invoice")
        if row["status"] == "CANCELLED":
            raise HTTPException(status_code=400, detail="This invoice is cancelled.")

        conn.execute(
            "UPDATE invoices SET remarks = ?, salesman = ?, terms_text = ?, "
            "terms_days = ?, due_date = date(inv_date, ?), version = version + 1 "
            "WHERE inv_no = ?",
            (clean(payload.get("remarks")), clean(payload.get("salesman"), upper=True),
             clean(payload.get("terms_text")), int(payload.get("terms_days") or 0),
             f"+{int(payload.get('terms_days') or 0)} day", inv_no))
        db.audit(conn, user["username"], "update", "invoice", inv_no)
    events.publish("invoice:updated", {"inv_no": inv_no, "by": user["username"]},
                   permission="invoice:read")
    return _load(inv_no)


@router.post("/{inv_no}/cancel")
def cancel_invoice(inv_no: str, payload: dict,
                   user: dict = Depends(require("invoice:write"))) -> dict:
    """Reverse the whole document: stock back in, customer balance down."""
    inv_no = inv_no.upper()
    reason = clean(payload.get("reason")) or "Cancelled"

    with db.transaction() as conn:
        row = conn.execute("SELECT * FROM invoices WHERE inv_no = ?", (inv_no,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail=f"No invoice {inv_no!r}.")
        check_version(row, payload.get("version"), "invoice")
        if row["status"] == "CANCELLED":
            raise HTTPException(status_code=400, detail="Already cancelled.")
        if row["paid_amount"] > 0.005:
            raise HTTPException(
                status_code=400,
                detail="Payments have been applied to this invoice. "
                       "Reverse the payment before cancelling.")

        stamp = db.now()
        touched: list[str] = []
        for line in conn.execute(
                "SELECT * FROM invoice_lines WHERE inv_no = ?", (inv_no,)).fetchall():
            touched.append(line["stock_code"])
            conn.execute(
                "UPDATE stock SET qty_on_hand = qty_on_hand + ?, version = version + 1 "
                "WHERE code = ?", (line["qty"], line["stock_code"]))
            conn.execute(
                "INSERT INTO stock_moves(move_type, doc_no, doc_date, stock_code,"
                " description, qty, unit, unit_price, line_total, customer_code,"
                " remarks, created_at, created_by) "
                "VALUES ('ADJUST',?,?,?,?,?,?,?,?,?,?,?,?)",
                (inv_no, db.today(), line["stock_code"], line["description"],
                 line["qty"], line["unit"], line["unit_price"], -line["line_total"],
                 row["customer_code"], f"Cancelled invoice: {reason}", stamp,
                 user["username"]))

        conn.execute(
            "UPDATE customers SET balance = ROUND(balance - ?, 2), "
            "purchases = ROUND(purchases - ?, 2), version = version + 1 WHERE code = ?",
            (row["balance"], row["net_amount"], row["customer_code"]))
        conn.execute(
            "UPDATE invoices SET status = 'CANCELLED', balance = 0, short_lines = 0, "
            "remarks = TRIM(remarks || ' [cancelled: ' || ? || ']'), "
            "version = version + 1 WHERE inv_no = ?", (reason, inv_no))

        # The stock is back on the shelf, so whatever this document was short of
        # is no longer owed to anybody. Without this the refill note raised by
        # the very invoice being cancelled would stand until somebody bought
        # stock nobody needs.
        replenishment.resolve_document(conn, inv_no, user["username"])
        replenishment.resolve_settled(conn, touched, username=user["username"])

        db.audit(conn, user["username"], "cancel", "invoice", inv_no, reason)

    alerts.sweep_kind("stock.refill")
    batch = events.batch()
    batch.add("invoice:cancelled",
              {"inv_no": inv_no, "customer_code": row["customer_code"],
               "reason": reason, "by": user["username"]},
              permission="invoice:read")
    batch.stock_changed(*touched)
    batch.flush()
    return _load(inv_no)


@router.get("/{inv_no}/print")
def print_view(inv_no: str, _user: dict = Depends(require("invoice:read"))) -> dict:
    """Everything a printable invoice needs in one call."""
    invoice = _load(inv_no.upper())
    invoice["customer"] = db.query_one(
        "SELECT code, name, address, city, tin, business_style, terms_text "
        "FROM customers WHERE code = ?", (invoice["customer_code"],))
    return invoice
