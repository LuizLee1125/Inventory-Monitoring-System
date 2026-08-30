"""Supplier master file."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from .. import db
from ..deps import check_version, clean, money, paged_response, paging, require, require_fields

router = APIRouter(prefix="/suppliers", tags=["suppliers"])

SORTABLE = {"code": "code", "name": "name", "balance": "balance", "city": "city"}


@router.get("")
def list_suppliers(
    q: str = "",
    status: str = "active",
    sort: str = "name",
    direction: str = "asc",
    page: int = 1,
    page_size: int = 50,
    _user: dict = Depends(require("supplier:read")),
) -> dict:
    where: list[str] = []
    params: list = []
    if q:
        term = f"%{q.strip().upper()}%"
        where.append("(code LIKE ? OR name LIKE ? OR city LIKE ?)")
        params += [term, term, term]
    if status == "active":
        where.append("is_active = 1")
    elif status == "inactive":
        where.append("is_active = 0")

    clause = f"WHERE {' AND '.join(where)}" if where else ""
    order = SORTABLE.get(sort, "name")
    order_dir = "DESC" if direction.lower() == "desc" else "ASC"
    page, page_size = paging(page, page_size)

    total = db.scalar(f"SELECT COUNT(*) FROM suppliers {clause}", params, 0)
    rows = db.query(
        f"SELECT * FROM suppliers {clause} ORDER BY {order} {order_dir}, code "
        f"LIMIT ? OFFSET ?", params + [page_size, (page - 1) * page_size])
    return paged_response(rows, total, page, page_size)


@router.get("/lookup")
def lookup(q: str = "", limit: int = 20,
           _user: dict = Depends(require("supplier:read"))) -> list[dict]:
    term = f"%{q.strip().upper()}%"
    return db.query(
        "SELECT code, name, city, terms_text, terms_days, balance FROM suppliers "
        "WHERE is_active = 1 AND (code LIKE ? OR name LIKE ?) ORDER BY name LIMIT ?",
        (term, term, max(1, min(limit, 50))))


@router.get("/{code}")
def get_supplier(code: str, _user: dict = Depends(require("supplier:read"))) -> dict:
    row = db.query_one("SELECT * FROM suppliers WHERE code = ?", (code.upper(),))
    if row is None:
        raise HTTPException(status_code=404, detail=f"No supplier {code!r}.")
    row["items_supplied"] = db.scalar(
        "SELECT COUNT(*) FROM stock WHERE supplier_code = ?", (row["code"],), 0)
    row["purchases_12m"] = db.scalar(
        "SELECT ROUND(SUM(net_amount), 2) FROM purchases WHERE supplier_code = ? "
        "AND pur_date >= date('now', '-12 month')", (row["code"],), 0)
    return row


@router.get("/{code}/items")
def supplier_items(code: str, _user: dict = Depends(require("supplier:read"))) -> list[dict]:
    return db.query(
        "SELECT code, name, unit, qty_on_hand, cost, price_a FROM stock "
        "WHERE supplier_code = ? ORDER BY name", (code.upper(),))


@router.get("/{code}/purchases")
def supplier_purchases(code: str, limit: int = 100,
                       _user: dict = Depends(require("purchase:read"))) -> list[dict]:
    return db.query(
        "SELECT pur_no, pur_date, net_amount, balance, status FROM purchases "
        "WHERE supplier_code = ? ORDER BY pur_date DESC LIMIT ?",
        (code.upper(), max(1, min(limit, 500))))


def _supplier_values(payload: dict) -> dict:
    return {
        "name": clean(payload.get("name")),
        "address": clean(payload.get("address")),
        "city": clean(payload.get("city")),
        "contact": clean(payload.get("contact")),
        "phone": clean(payload.get("phone")),
        "terms_text": clean(payload.get("terms_text")),
        "terms_days": int(payload.get("terms_days") or 0),
        "credit_limit": money(payload.get("credit_limit")),
        "remarks": clean(payload.get("remarks")),
        "is_active": 1 if payload.get("is_active", True) else 0,
    }


@router.post("", status_code=201)
def create_supplier(payload: dict,
                    user: dict = Depends(require("supplier:write"))) -> dict:
    code = clean(payload.get("code"), upper=True)
    require_fields({"code": code, "name": payload.get("name")}, "code", "name")
    values = _supplier_values(payload)
    with db.transaction() as conn:
        if conn.execute("SELECT 1 FROM suppliers WHERE code = ?", (code,)).fetchone():
            raise HTTPException(status_code=409, detail=f"Supplier {code} already exists.")
        conn.execute(
            f"INSERT INTO suppliers(code, {', '.join(values)}, updated_at, updated_by) "
            f"VALUES (?, {', '.join('?' * len(values))}, ?, ?)",
            [code, *values.values(), db.now(), user["username"]])
        db.audit(conn, user["username"], "create", "supplier", code)
    return get_supplier(code, _user=user)


@router.put("/{code}")
def update_supplier(code: str, payload: dict,
                    user: dict = Depends(require("supplier:write"))) -> dict:
    code = code.upper()
    values = _supplier_values(payload)
    with db.transaction() as conn:
        row = conn.execute("SELECT * FROM suppliers WHERE code = ?", (code,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail=f"No supplier {code!r}.")
        check_version(row, payload.get("version"), "supplier")
        conn.execute(
            f"UPDATE suppliers SET {', '.join(f'{k} = ?' for k in values)}, "
            f"version = version + 1, updated_at = ?, updated_by = ? WHERE code = ?",
            [*values.values(), db.now(), user["username"], code])
        db.audit(conn, user["username"], "update", "supplier", code)
    return get_supplier(code, _user=user)
