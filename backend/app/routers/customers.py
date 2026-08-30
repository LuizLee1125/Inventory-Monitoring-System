"""Customer master file, statements and ledger."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from .. import config, db
from ..deps import check_version, clean, money, paged_response, paging, require, require_fields

router = APIRouter(prefix="/customers", tags=["customers"])

SORTABLE = {"code": "code", "name": "name", "balance": "balance",
            "city": "city", "salesman": "salesman", "last": "last_txn"}


@router.get("")
def list_customers(
    q: str = "",
    salesman: str = "",
    status: str = "active",
    flag: str = "",                 # owing | overlimit | inactive12m
    sort: str = "name",
    direction: str = "asc",
    page: int = 1,
    page_size: int = 50,
    _user: dict = Depends(require("customer:read")),
) -> dict:
    where: list[str] = []
    params: list = []

    if q:
        term = f"%{q.strip().upper()}%"
        where.append("(code LIKE ? OR name LIKE ? OR city LIKE ?)")
        params += [term, term, term]
    if salesman:
        where.append("salesman = ?")
        params.append(salesman.upper())
    if status == "active":
        where.append("is_active = 1")
    elif status == "inactive":
        where.append("is_active = 0")

    if flag == "owing":
        where.append("balance > 0.005")
    elif flag == "overlimit":
        where.append("credit_limit > 0 AND balance > credit_limit")
    elif flag == "inactive12m":
        where.append("(last_txn IS NULL OR last_txn < date('now', '-12 month'))")

    clause = f"WHERE {' AND '.join(where)}" if where else ""
    order = SORTABLE.get(sort, "name")
    order_dir = "DESC" if direction.lower() == "desc" else "ASC"
    page, page_size = paging(page, page_size)

    total = db.scalar(f"SELECT COUNT(*) FROM customers {clause}", params, 0)
    rows = db.query(
        f"SELECT * FROM customers {clause} ORDER BY {order} {order_dir}, code "
        f"LIMIT ? OFFSET ?", params + [page_size, (page - 1) * page_size])
    return paged_response(rows, total, page, page_size)


@router.get("/lookup")
def lookup(q: str = "", limit: int = 20,
           _user: dict = Depends(require("customer:read"))) -> list[dict]:
    term = f"%{q.strip().upper()}%"
    return db.query(
        "SELECT code, name, address, city, price_cat, terms_text, terms_days, "
        "credit_limit, balance, salesman FROM customers "
        "WHERE is_active = 1 AND (code LIKE ? OR name LIKE ?) "
        "ORDER BY name LIMIT ?", (term, term, max(1, min(limit, 50))))


@router.get("/salesmen")
def salesmen(_user: dict = Depends(require("customer:read"))) -> list[dict]:
    return db.query(
        "SELECT salesman AS code, COUNT(*) AS customers, "
        "ROUND(SUM(balance), 2) AS balance FROM customers "
        "WHERE salesman <> '' GROUP BY salesman ORDER BY salesman")


@router.get("/{code}")
def get_customer(code: str, _user: dict = Depends(require("customer:read"))) -> dict:
    row = db.query_one("SELECT * FROM customers WHERE code = ?", (code.upper(),))
    if row is None:
        raise HTTPException(status_code=404, detail=f"No customer {code!r}.")
    row["open_invoices"] = db.scalar(
        "SELECT COUNT(*) FROM invoices WHERE customer_code = ? AND balance > 0.005",
        (row["code"],), 0)
    row["last_payment"] = db.query_one(
        "SELECT col_no, col_date, net_amount FROM collections "
        "WHERE customer_code = ? ORDER BY col_date DESC LIMIT 1", (row["code"],))
    return row


@router.get("/{code}/ledger")
def customer_ledger(code: str, limit: int = 200,
                    _user: dict = Depends(require("customer:read"))) -> list[dict]:
    """Invoices, returns and payments interleaved in date order."""
    code = code.upper()
    rows = db.query(
        """
        SELECT inv_date AS date, 'INVOICE' AS kind, inv_no AS document,
               remarks, net_amount AS charge, 0 AS credit, balance, status
        FROM invoices WHERE customer_code = ?
        UNION ALL
        SELECT sr_date, 'RETURN', sr_no, remarks, 0, net_amount, 0, status
        FROM sales_returns WHERE customer_code = ?
        UNION ALL
        SELECT col_date, 'PAYMENT', col_no, remarks, 0, net_amount, 0, status
        FROM collections WHERE customer_code = ?
        ORDER BY date DESC, document DESC LIMIT ?
        """,
        (code, code, code, max(1, min(limit, 1000))),
    )
    return rows


@router.get("/{code}/aging")
def customer_aging(code: str,
                   _user: dict = Depends(require("customer:read"))) -> dict:
    b1, b2, b3 = config.AGING_BUCKETS
    row = db.query_one(
        f"""
        SELECT
          ROUND(SUM(CASE WHEN julianday('now') - julianday(inv_date) <= {b1}
                    THEN balance ELSE 0 END), 2) AS current,
          ROUND(SUM(CASE WHEN julianday('now') - julianday(inv_date) > {b1}
                     AND julianday('now') - julianday(inv_date) <= {b2}
                    THEN balance ELSE 0 END), 2) AS d{b1},
          ROUND(SUM(CASE WHEN julianday('now') - julianday(inv_date) > {b2}
                     AND julianday('now') - julianday(inv_date) <= {b3}
                    THEN balance ELSE 0 END), 2) AS d{b2},
          ROUND(SUM(CASE WHEN julianday('now') - julianday(inv_date) > {b3}
                    THEN balance ELSE 0 END), 2) AS d{b3},
          ROUND(SUM(balance), 2) AS total
        FROM invoices WHERE customer_code = ? AND balance > 0.005
        """,
        (code.upper(),),
    )
    return row or {}


@router.get("/{code}/monthly")
def customer_monthly(code: str, years: int = 3,
                     _user: dict = Depends(require("customer:read"))) -> list[dict]:
    return db.query(
        "SELECT year, month, sales, returns FROM customer_monthly "
        "WHERE customer_code = ? AND year >= CAST(strftime('%Y', 'now') AS INTEGER) - ? "
        "ORDER BY year DESC, month DESC", (code.upper(), max(0, years)))


def _customer_values(payload: dict) -> dict:
    return {
        "name": clean(payload.get("name")),
        "address": clean(payload.get("address")),
        "city": clean(payload.get("city")),
        "contact_person": clean(payload.get("contact_person")),
        "phone": clean(payload.get("phone")),
        "terms_text": clean(payload.get("terms_text")),
        "terms_days": int(payload.get("terms_days") or 0),
        "price_cat": (clean(payload.get("price_cat"), upper=True) or "A")[:1],
        "credit_limit": money(payload.get("credit_limit")),
        "salesman": clean(payload.get("salesman"), upper=True),
        "tin": clean(payload.get("tin")),
        "business_style": clean(payload.get("business_style")),
        "remarks": clean(payload.get("remarks")),
        "is_active": 1 if payload.get("is_active", True) else 0,
    }


@router.post("", status_code=201)
def create_customer(payload: dict,
                    user: dict = Depends(require("customer:write"))) -> dict:
    code = clean(payload.get("code"), upper=True)
    require_fields({"code": code, "name": payload.get("name")}, "code", "name")
    values = _customer_values(payload)
    with db.transaction() as conn:
        if conn.execute("SELECT 1 FROM customers WHERE code = ?", (code,)).fetchone():
            raise HTTPException(status_code=409, detail=f"Customer {code} already exists.")
        conn.execute(
            f"INSERT INTO customers(code, {', '.join(values)}, date_started, "
            f"updated_at, updated_by) VALUES (?, {', '.join('?' * len(values))}, ?, ?, ?)",
            [code, *values.values(), db.today(), db.now(), user["username"]])
        db.audit(conn, user["username"], "create", "customer", code)
    return get_customer(code, _user=user)


@router.put("/{code}")
def update_customer(code: str, payload: dict,
                    user: dict = Depends(require("customer:write"))) -> dict:
    code = code.upper()
    values = _customer_values(payload)
    with db.transaction() as conn:
        row = conn.execute("SELECT * FROM customers WHERE code = ?", (code,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail=f"No customer {code!r}.")
        check_version(row, payload.get("version"), "customer")
        conn.execute(
            f"UPDATE customers SET {', '.join(f'{k} = ?' for k in values)}, "
            f"version = version + 1, updated_at = ?, updated_by = ? WHERE code = ?",
            [*values.values(), db.now(), user["username"], code])
        db.audit(conn, user["username"], "update", "customer", code)
    return get_customer(code, _user=user)
