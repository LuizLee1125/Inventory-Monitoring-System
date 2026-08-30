"""Archived records — the legacy O_* files, kept readable.

Twenty-five years of purges moved finished documents out of the working files
and into a parallel set of O_* tables. The DOS menu reached them two ways:
"Archived Records" on the Transactions column for browsing, and "Archive
Inquiry" on Maintenance for the overview. Both survive here.

Everything in this router is read-only. Archived documents are history; nothing
in the application writes to them.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query

from .. import db
from ..deps import paged_response, paging, require

router = APIRouter(prefix="/archive", tags=["archive"])

KINDS = {
    "invoices": {
        "table": "archived_invoices", "key": "inv_no", "date": "inv_date",
        "party": "customer_code", "party_name": "customer_name", "amount": "net_amount",
        "label": "Invoices",
    },
    "purchases": {
        "table": "archived_purchases", "key": "pur_no", "date": "pur_date",
        "party": "supplier_code", "party_name": "supplier_name", "amount": "net_amount",
        "label": "Purchases",
    },
    "returns": {
        "table": "archived_returns", "key": "sr_no", "date": "sr_date",
        "party": "customer_code", "party_name": "customer_name", "amount": "net_amount",
        "label": "Sales returns",
    },
    "collections": {
        "table": "archived_collections", "key": "col_no", "date": "col_date",
        "party": "customer_code", "party_name": "customer_name", "amount": "net_amount",
        "label": "Collections",
    },
}


@router.get("/summary")
def summary(_user: dict = Depends(require("report:read"))) -> dict:
    """Archive Inquiry: what is in the archive, and which years it covers."""
    sections = []
    for kind, spec in KINDS.items():
        row = db.query_one(
            f"SELECT COUNT(*) AS rows, MIN({spec['date']}) AS first, "
            f"MAX({spec['date']}) AS last, ROUND(SUM({spec['amount']}), 2) AS value "
            f"FROM {spec['table']}") or {}
        sections.append({"kind": kind, "label": spec["label"], **row})

    moves = db.query_one(
        "SELECT COUNT(*) AS rows, MIN(doc_date) AS first, MAX(doc_date) AS last, "
        "COUNT(DISTINCT stock_code) AS items, COUNT(DISTINCT doc_no) AS documents "
        "FROM archived_moves") or {}

    # O_TRN2 covers a narrower span than O_SIFYL, so most archived invoices kept
    # their header but not their lines. Say so plainly rather than letting an
    # empty Lines panel read as a fault.
    with_lines = db.scalar(
        "SELECT COUNT(*) FROM archived_invoices i WHERE EXISTS "
        "(SELECT 1 FROM archived_moves m WHERE m.doc_no = i.inv_no)", (), 0)
    total_invoices = db.scalar("SELECT COUNT(*) FROM archived_invoices", (), 0)

    return {
        "documents": sections,
        "movements": moves,
        "line_detail": {
            "invoices_with_lines": with_lines,
            "invoices_total": total_invoices,
            "percent": round(with_lines * 100.0 / total_invoices, 1) if total_invoices else 0,
        },
        "masters": {
            "customers": db.scalar("SELECT COUNT(*) FROM archived_customers", (), 0),
            "stock": db.scalar("SELECT COUNT(*) FROM archived_stock", (), 0),
            "suppliers": db.scalar("SELECT COUNT(*) FROM archived_suppliers", (), 0),
        },
        "by_year": db.query(
            "SELECT substr(inv_date, 1, 4) AS year, COUNT(*) AS invoices, "
            "ROUND(SUM(net_amount), 2) AS value FROM archived_invoices "
            "WHERE inv_date >= '1990-01-01' GROUP BY year ORDER BY year DESC LIMIT 30"),
    }


@router.get("/{kind}")
def browse(kind: str, q: str = "", date_from: str = "", date_to: str = "",
           page: int = 1, page_size: int = 50,
           _user: dict = Depends(require("report:read"))) -> dict:
    """Archived Records: browse one archived file."""
    spec = KINDS.get(kind)
    if spec is None:
        raise HTTPException(status_code=404, detail=f"No archived file called {kind!r}.")

    where: list[str] = []
    params: list = []
    if q:
        term = f"%{q.strip().upper()}%"
        where.append(f"({spec['key']} LIKE ? OR {spec['party_name']} LIKE ? "
                     f"OR {spec['party']} LIKE ?)")
        params += [term, term, term]
    if date_from:
        where.append(f"{spec['date']} >= ?")
        params.append(date_from)
    if date_to:
        where.append(f"{spec['date']} <= ?")
        params.append(date_to)
    clause = f"WHERE {' AND '.join(where)}" if where else ""

    page, page_size = paging(page, page_size)
    total = db.scalar(f"SELECT COUNT(*) FROM {spec['table']} {clause}", params, 0)
    summed = db.scalar(
        f"SELECT ROUND(SUM({spec['amount']}), 2) FROM {spec['table']} {clause}", params, 0)
    rows = db.query(
        f"SELECT * FROM {spec['table']} {clause} "
        f"ORDER BY {spec['date']} DESC, {spec['key']} DESC LIMIT ? OFFSET ?",
        params + [page_size, (page - 1) * page_size])

    result = paged_response(rows, total, page, page_size)
    result["summary"] = {"value": summed or 0}
    result["kind"] = kind
    result["label"] = spec["label"]
    return result


@router.get("/{kind}/{number}")
def document(kind: str, number: str,
             _user: dict = Depends(require("report:read"))) -> dict:
    """One archived document, with whatever line detail O_TRN2 still holds."""
    spec = KINDS.get(kind)
    if spec is None:
        raise HTTPException(status_code=404, detail=f"No archived file called {kind!r}.")

    number = number.upper()
    header = db.query_one(
        f"SELECT * FROM {spec['table']} WHERE {spec['key']} = ?", (number,))
    if header is None:
        raise HTTPException(status_code=404,
                            detail=f"No archived {kind[:-1]} numbered {number}.")

    header["lines"] = db.query(
        "SELECT * FROM archived_moves WHERE doc_no = ? ORDER BY id", (number,))
    header["party"] = db.query_one(
        "SELECT code, name, address, city, phone FROM archived_customers WHERE code = ?",
        (header.get("customer_code"),)) if spec["party"] == "customer_code" else None
    return header


@router.get("/moves/by-item/{stock_code}")
def moves_for_item(stock_code: str, limit: int = Query(200, le=2000),
                   _user: dict = Depends(require("stock:read"))) -> list[dict]:
    """Archived movement history for one item, for when the live ledger starts
    later than the question being asked."""
    return db.query(
        "SELECT * FROM archived_moves WHERE stock_code = ? "
        "ORDER BY doc_date DESC, id DESC LIMIT ?", (stock_code.upper(), limit))
