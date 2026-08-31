"""Stock master file, price adjustment, inventory adjustment, movement ledger."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query

from .. import db, events, replenishment
from .. import notifications as alerts
from ..deps import check_version, clean, money, paged_response, paging, require, require_fields

router = APIRouter(prefix="/stock", tags=["stock"])

SORTABLE = {
    "code": "code", "name": "name", "qty": "qty_on_hand", "cost": "cost",
    "price": "price_a", "expiry": "expiry_date", "division": "division",
    "category": "category",
}

PRICE_FIELDS = ("price_a", "price_b", "price_c", "price_d", "price_e")


@router.get("")
def list_stock(
    q: str = "",
    division: str = "",
    category: str = "",
    supplier: str = "",
    status: str = "active",          # active | inactive | all
    flag: str = "",                  # low | expiring | expired | zero
    sort: str = "code",
    direction: str = "asc",
    page: int = 1,
    page_size: int = 50,
    _user: dict = Depends(require("stock:read")),
) -> dict:
    where: list[str] = []
    params: list = []

    if q:
        where.append("(code LIKE ? OR name LIKE ?)")
        term = f"%{q.strip().upper()}%"
        params += [term, term]
    if division:
        where.append("division = ?")
        params.append(division.upper())
    if category:
        where.append("category = ?")
        params.append(category.upper())
    if supplier:
        where.append("supplier_code = ?")
        params.append(supplier.upper())
    if status == "active":
        where.append("is_active = 1")
    elif status == "inactive":
        where.append("is_active = 0")

    if flag == "low":
        where.append("reorder_point > 0 AND qty_on_hand <= reorder_point")
    elif flag == "zero":
        where.append("qty_on_hand <= 0")
    elif flag == "expiring":
        where.append("expiry_date IS NOT NULL AND expiry_date <= date('now', '+90 day') "
                     "AND expiry_date >= date('now')")
    elif flag == "expired":
        where.append("expiry_date IS NOT NULL AND expiry_date < date('now')")

    clause = f"WHERE {' AND '.join(where)}" if where else ""
    order = SORTABLE.get(sort, "code")
    order_dir = "DESC" if direction.lower() == "desc" else "ASC"
    page, page_size = paging(page, page_size)

    total = db.scalar(f"SELECT COUNT(*) FROM stock {clause}", params, 0)
    rows = db.query(
        f"SELECT * FROM stock {clause} ORDER BY {order} {order_dir}, code "
        f"LIMIT ? OFFSET ?",
        params + [page_size, (page - 1) * page_size],
    )
    return paged_response(rows, total, page, page_size)


@router.get("/lookup")
def lookup(q: str = "", limit: int = 20,
           _user: dict = Depends(require("stock:read"))) -> list[dict]:
    """Type-ahead used by the invoice and purchase line editors."""
    term = f"%{q.strip().upper()}%"
    return db.query(
        # `allow_oversell` rides along so the line editor can warn before the
        # save rather than after: an item that cannot be oversold is the one
        # case where too large a quantity is refused, and finding that out at
        # the moment of saving a finished invoice is the worst time to find out.
        "SELECT code, name, unit, qty_on_hand, cost, price_a, price_b, price_c, "
        "price_d, price_e, lot_no, expiry_date, allow_oversell FROM stock "
        "WHERE is_active = 1 AND (code LIKE ? OR name LIKE ?) "
        "ORDER BY code LIMIT ?",
        (term, term, max(1, min(limit, 50))),
    )


@router.get("/divisions")
def divisions(_user: dict = Depends(require("stock:read"))) -> list[dict]:
    return db.query(
        "SELECT d.code, d.name, COUNT(s.code) AS items FROM divisions d "
        "LEFT JOIN stock s ON s.division = d.code GROUP BY d.code ORDER BY d.code")


@router.get("/categories")
def categories(_user: dict = Depends(require("stock:read"))) -> list[dict]:
    return db.query(
        "SELECT c.code, c.name, COUNT(s.code) AS items FROM categories c "
        "LEFT JOIN stock s ON s.category = c.code GROUP BY c.code ORDER BY c.code")


@router.get("/{code}")
def get_stock(code: str, _user: dict = Depends(require("stock:read"))) -> dict:
    row = db.query_one("SELECT * FROM stock WHERE code = ?", (code.upper(),))
    if row is None:
        raise HTTPException(status_code=404, detail=f"No stock item {code!r}.")
    row["supplier_name"] = db.scalar(
        "SELECT name FROM suppliers WHERE code = ?", (row["supplier_code"],), "")
    row["sold_12m"] = db.scalar(
        "SELECT ROUND(SUM(-qty), 2) FROM stock_moves WHERE stock_code = ? "
        "AND move_type = 'SALE' AND doc_date >= date('now', '-12 month')",
        (row["code"],), 0)
    # How much of this item has been sold and not delivered. Nearly always zero,
    # and the detail screen says nothing when it is.
    row["qty_short"] = db.scalar(
        "SELECT ROUND(SUM(qty_short), 2) FROM stock_shortfalls "
        "WHERE stock_code = ? AND resolved_at IS NULL", (row["code"],), 0)
    return row


@router.get("/{code}/moves")
def stock_moves(code: str, limit: int = Query(100, le=1000),
                move_type: str = "",
                _user: dict = Depends(require("stock:read"))) -> list[dict]:
    where = ["stock_code = ?"]
    params: list = [code.upper()]
    if move_type:
        where.append("move_type = ?")
        params.append(move_type.upper())
    params.append(limit)
    return db.query(
        f"SELECT * FROM stock_moves WHERE {' AND '.join(where)} "
        f"ORDER BY doc_date DESC, id DESC LIMIT ?", params)


def _stock_values(payload: dict) -> dict:
    return {
        "name": clean(payload.get("name")),
        "division": clean(payload.get("division"), upper=True),
        "category": clean(payload.get("category"), upper=True),
        "unit": clean(payload.get("unit"), upper=True),
        "pack_qty": int(payload.get("pack_qty") or 0),
        "pack_unit": clean(payload.get("pack_unit"), upper=True),
        "lot_no": clean(payload.get("lot_no")),
        "expiry_date": clean(payload.get("expiry_date")) or None,
        "reorder_point": money(payload.get("reorder_point")),
        "reorder_qty": money(payload.get("reorder_qty")),
        "supplier_code": clean(payload.get("supplier_code"), upper=True),
        "cost": money(payload.get("cost")),
        "price_a": money(payload.get("price_a")),
        "price_b": money(payload.get("price_b")),
        "price_c": money(payload.get("price_c")),
        "price_d": money(payload.get("price_d")),
        "price_e": money(payload.get("price_e")),
        "remarks": clean(payload.get("remarks")),
        # Defaults to allowed, matching the column's own default and the
        # behaviour every item had before the column existed. A form that does
        # not send the field must not silently turn selling off.
        "allow_oversell": 1 if payload.get("allow_oversell", True) else 0,
        "is_active": 1 if payload.get("is_active", True) else 0,
    }


@router.post("", status_code=201)
def create_stock(payload: dict, user: dict = Depends(require("stock:write"))) -> dict:
    code = clean(payload.get("code"), upper=True)
    require_fields({"code": code, "name": payload.get("name")}, "code", "name")

    values = _stock_values(payload)
    with db.transaction() as conn:
        if conn.execute("SELECT 1 FROM stock WHERE code = ?", (code,)).fetchone():
            raise HTTPException(status_code=409, detail=f"Stock code {code} already exists.")
        columns = ", ".join(values)
        conn.execute(
            f"INSERT INTO stock(code, {columns}, qty_on_hand, updated_at, updated_by) "
            f"VALUES (?, {', '.join('?' * len(values))}, ?, ?, ?)",
            [code, *values.values(), money(payload.get("qty_on_hand")),
             db.now(), user["username"]],
        )
        db.audit(conn, user["username"], "create", "stock", code)
    events.publish("stock:changed", {"codes": [code]}, permission="stock:read")
    return get_stock(code, _user=user)


@router.put("/{code}")
def update_stock(code: str, payload: dict,
                 user: dict = Depends(require("stock:write"))) -> dict:
    code = code.upper()
    values = _stock_values(payload)
    with db.transaction() as conn:
        row = conn.execute("SELECT * FROM stock WHERE code = ?", (code,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail=f"No stock item {code!r}.")
        check_version(row, payload.get("version"), "stock item")

        assignments = ", ".join(f"{k} = ?" for k in values)
        conn.execute(
            f"UPDATE stock SET {assignments}, version = version + 1, "
            f"updated_at = ?, updated_by = ? WHERE code = ?",
            [*values.values(), db.now(), user["username"], code],
        )
        db.audit(conn, user["username"], "update", "stock", code)
    events.publish("stock:changed", {"codes": [code]}, permission="stock:read")
    return get_stock(code, _user=user)


@router.post("/{code}/adjust")
def adjust_stock(code: str, payload: dict,
                 user: dict = Depends(require("stock:write"))) -> dict:
    """Inventory adjustment - the successor to INVADJ.PRG.

    Quantity is never set directly; a signed movement is written and the balance
    follows from it, so every change to stock on hand has an audit trail.
    """
    code = code.upper()
    qty = money(payload.get("qty"))
    reason = clean(payload.get("reason")) or "Inventory adjustment"
    if qty == 0:
        raise HTTPException(status_code=400, detail="Enter a non-zero quantity.")

    with db.transaction() as conn:
        row = conn.execute("SELECT * FROM stock WHERE code = ?", (code,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail=f"No stock item {code!r}.")

        new_qty = round(row["qty_on_hand"] + qty, 2)
        doc_no = db.next_document_number(conn, "adjustment")
        conn.execute(
            "INSERT INTO stock_moves(move_type, doc_no, doc_date, stock_code,"
            " description, qty, unit, unit_cost, line_total, division, category,"
            " balance_after, remarks, created_at, created_by) "
            "VALUES ('ADJUST', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (doc_no, db.today(), code, row["name"], qty, row["unit"], row["cost"],
             round(qty * row["cost"], 2), row["division"], row["category"],
             new_qty, reason, db.now(), user["username"]),
        )
        conn.execute(
            "UPDATE stock SET qty_on_hand = ?, version = version + 1, "
            "last_txn = ?, updated_at = ?, updated_by = ? WHERE code = ?",
            (new_qty, db.today(), db.now(), user["username"], code))
        # An adjustment upward is the other way stock comes back, so it closes
        # refill notes exactly as a receipt does.
        refilled = replenishment.resolve_settled(conn, [code],
                                                 username=user["username"])
        db.audit(conn, user["username"], "adjust", "stock", code,
                 f"{qty:+.2f} -> {new_qty:.2f}: {reason}")

    if refilled:
        alerts.sweep_kind("stock.refill")
    events.publish("stock:changed", {"codes": [code]}, permission="stock:read")
    return {"code": code, "qty_on_hand": new_qty, "document": doc_no}


@router.post("/prices")
def bulk_price_change(payload: dict,
                      user: dict = Depends(require("stock:write"))) -> dict:
    """Price adjustment across a selection - the successor to PRYSADJ.PRG.

    Either a percentage applied to the chosen tiers, or an explicit cost-plus
    markup recalculation.
    """
    codes = [clean(c, upper=True) for c in payload.get("codes") or []]
    tiers = [t for t in payload.get("tiers") or [] if t in PRICE_FIELDS]
    percent = float(payload.get("percent") or 0)
    if not codes:
        raise HTTPException(status_code=400, detail="Select at least one item.")
    if not tiers:
        raise HTTPException(status_code=400, detail="Select at least one price tier.")
    if percent == 0:
        raise HTTPException(status_code=400, detail="Enter a percentage change.")

    factor = 1 + percent / 100
    changed = 0
    with db.transaction() as conn:
        for code in codes:
            row = conn.execute("SELECT * FROM stock WHERE code = ?", (code,)).fetchone()
            if row is None:
                continue
            updates = {t: round(row[t] * factor, 2) for t in tiers}
            conn.execute(
                f"UPDATE stock SET {', '.join(f'{t} = ?' for t in updates)}, "
                f"price_updated = ?, version = version + 1, updated_at = ?, "
                f"updated_by = ? WHERE code = ?",
                [*updates.values(), db.today(), db.now(), user["username"], code])
            changed += 1
        db.audit(conn, user["username"], "price-change", "stock", None,
                 f"{changed} items, {', '.join(tiers)} {percent:+.2f}%")
    # One event carrying every code, not one per item: a price run across two
    # thousand items must not become two thousand events and two thousand
    # refetches on every open stock screen in the office.
    if changed:
        events.publish("stock:changed", {"codes": codes, "reason": "prices"},
                       permission="stock:read")
    return {"changed": changed, "percent": percent, "tiers": tiers}
