"""Reports: the successors to the LST*.PRG and REP_*.PRG family."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from .. import config, db
from ..deps import require

router = APIRouter(prefix="/reports", tags=["reports"])

B1, B2, B3 = config.AGING_BUCKETS


@router.get("/dashboard")
def dashboard(_user: dict = Depends(require("report:read"))) -> dict:
    """The landing screen: what the owner would ask about first thing."""
    receivable = db.query_one(
        f"""
        SELECT
          ROUND(SUM(balance), 2) AS total,
          ROUND(SUM(CASE WHEN julianday('now') - julianday(inv_date) > {B3}
                    THEN balance ELSE 0 END), 2) AS over_{B3},
          COUNT(*) AS open_invoices,
          COUNT(DISTINCT customer_code) AS customers
        FROM invoices WHERE balance > 0.005 AND status <> 'CANCELLED'
        """) or {}

    month = db.query_one(
        "SELECT COUNT(*) AS invoices, ROUND(SUM(net_amount), 2) AS sales "
        "FROM invoices WHERE status <> 'CANCELLED' "
        "AND inv_date >= date('now', 'start of month')") or {}

    year = db.query_one(
        "SELECT ROUND(SUM(net_amount), 2) AS sales FROM invoices "
        "WHERE status <> 'CANCELLED' AND inv_date >= date('now', 'start of year')") or {}

    # `needs_attention` is a distinct count: an item that is both depleted and
    # below its reorder point is one problem, not two. Summing the two columns
    # overstates it, which on this data reported more items than exist.
    stock = db.query_one(
        "SELECT COUNT(*) AS items, "
        "ROUND(SUM(qty_on_hand * cost), 2) AS value, "
        "SUM(CASE WHEN reorder_point > 0 AND qty_on_hand <= reorder_point "
        "    THEN 1 ELSE 0 END) AS below_reorder, "
        "SUM(CASE WHEN qty_on_hand <= 0 THEN 1 ELSE 0 END) AS depleted, "
        "SUM(CASE WHEN qty_on_hand <= 0 "
        "      OR (reorder_point > 0 AND qty_on_hand <= reorder_point) "
        "    THEN 1 ELSE 0 END) AS needs_attention, "
        "SUM(CASE WHEN expiry_date IS NOT NULL AND expiry_date < date('now', '+90 day') "
        "    THEN 1 ELSE 0 END) AS expiring "
        "FROM stock WHERE is_active = 1") or {}

    # The trend normally covers the last twelve calendar months. On a database
    # whose newest invoice is older than that - a freshly migrated archive, for
    # instance - fall back to the last twelve months that actually have sales,
    # so the chart shows the business rather than an empty axis.
    trend = db.query(
        "SELECT substr(inv_date, 1, 7) AS period, ROUND(SUM(net_amount), 2) AS sales, "
        "COUNT(*) AS invoices FROM invoices WHERE status <> 'CANCELLED' "
        "AND inv_date >= date('now', '-12 month') GROUP BY period ORDER BY period")
    trend_is_recent = True
    if len(trend) < 2:
        trend_is_recent = False
        trend = list(reversed(db.query(
            "SELECT substr(inv_date, 1, 7) AS period, ROUND(SUM(net_amount), 2) AS sales, "
            "COUNT(*) AS invoices FROM invoices WHERE status <> 'CANCELLED' "
            "AND inv_date >= '1990-01-01' GROUP BY period ORDER BY period DESC LIMIT 12")))

    return {
        "receivable": receivable,
        "month": month,
        "year": year,
        "stock": stock,
        "sales_trend": trend,
        "trend_is_recent": trend_is_recent,
        "recent_invoices": db.query(
            "SELECT inv_no, customer_name, inv_date, net_amount, balance, status "
            "FROM invoices ORDER BY inv_date DESC, inv_no DESC LIMIT 8"),
        "recent_payments": db.query(
            "SELECT col_no, customer_name, col_date, net_amount FROM collections "
            "ORDER BY col_date DESC, col_no DESC LIMIT 8"),
    }


@router.get("/aging")
def aging(salesman: str = "", min_balance: float = 0.005,
          page_size: int = Query(200, le=2000),
          _user: dict = Depends(require("report:read"))) -> dict:
    """Accounts receivable aging - the successor to LSTAR / LST30 / LST60 / LST90."""
    where = ["i.balance > ?", "i.status <> 'CANCELLED'"]
    params: list = [min_balance]
    if salesman:
        where.append("i.salesman = ?")
        params.append(salesman.upper())
    clause = " AND ".join(where)

    rows = db.query(
        f"""
        SELECT i.customer_code, i.customer_name, c.salesman, c.credit_limit,
               ROUND(SUM(CASE WHEN julianday('now') - julianday(i.inv_date) <= {B1}
                         THEN i.balance ELSE 0 END), 2) AS current,
               ROUND(SUM(CASE WHEN julianday('now') - julianday(i.inv_date) > {B1}
                          AND julianday('now') - julianday(i.inv_date) <= {B2}
                         THEN i.balance ELSE 0 END), 2) AS bucket1,
               ROUND(SUM(CASE WHEN julianday('now') - julianday(i.inv_date) > {B2}
                          AND julianday('now') - julianday(i.inv_date) <= {B3}
                         THEN i.balance ELSE 0 END), 2) AS bucket2,
               ROUND(SUM(CASE WHEN julianday('now') - julianday(i.inv_date) > {B3}
                         THEN i.balance ELSE 0 END), 2) AS bucket3,
               ROUND(SUM(i.balance), 2) AS total,
               COUNT(*) AS invoices
        FROM invoices i LEFT JOIN customers c ON c.code = i.customer_code
        WHERE {clause}
        GROUP BY i.customer_code, i.customer_name
        ORDER BY total DESC LIMIT ?
        """, params + [page_size])

    totals = {key: round(sum(r[key] or 0 for r in rows), 2)
              for key in ("current", "bucket1", "bucket2", "bucket3", "total")}
    return {"buckets": [f"Current ({B1} days)", f"{B1}-{B2}", f"{B2}-{B3}", f"Over {B3}"],
            "rows": rows, "totals": totals}


@router.get("/sales")
def sales(date_from: str = "", date_to: str = "",
          group_by: str = "month",     # month | customer | salesman | division | category
          limit: int = Query(200, le=2000),
          _user: dict = Depends(require("report:read"))) -> dict:
    date_from = date_from or "1900-01-01"
    date_to = date_to or "2999-12-31"

    if group_by in ("division", "category"):
        column = group_by
        rows = db.query(
            f"""
            SELECT m.{column} AS label, ROUND(SUM(m.line_total), 2) AS sales,
                   ROUND(SUM(-m.qty), 2) AS quantity, COUNT(DISTINCT m.doc_no) AS invoices
            FROM stock_moves m
            WHERE m.move_type = 'SALE' AND m.doc_date BETWEEN ? AND ?
            GROUP BY label ORDER BY sales DESC LIMIT ?
            """, (date_from, date_to, limit))
    else:
        label = {"month": "substr(inv_date, 1, 7)",
                 "customer": "customer_name",
                 "salesman": "salesman"}.get(group_by, "substr(inv_date, 1, 7)")
        order = "label" if group_by == "month" else "sales DESC"
        rows = db.query(
            f"""
            SELECT {label} AS label, ROUND(SUM(net_amount), 2) AS sales,
                   ROUND(SUM(cost_amount), 2) AS cost, COUNT(*) AS invoices
            FROM invoices WHERE status <> 'CANCELLED' AND inv_date BETWEEN ? AND ?
            GROUP BY label ORDER BY {order} LIMIT ?
            """, (date_from, date_to, limit))

    return {
        "group_by": group_by,
        "rows": rows,
        "totals": {"sales": round(sum(r.get("sales") or 0 for r in rows), 2),
                   "invoices": sum(r.get("invoices") or 0 for r in rows)},
    }


@router.get("/purchases")
def purchases_report(date_from: str = "", date_to: str = "",
                     limit: int = Query(200, le=2000),
                     _user: dict = Depends(require("report:read"))) -> dict:
    rows = db.query(
        """
        SELECT supplier_code AS label, supplier_name,
               ROUND(SUM(net_amount), 2) AS purchases, COUNT(*) AS documents,
               ROUND(SUM(balance), 2) AS payable
        FROM purchases WHERE pur_date BETWEEN ? AND ?
        GROUP BY supplier_code ORDER BY purchases DESC LIMIT ?
        """, (date_from or "1900-01-01", date_to or "2999-12-31", limit))
    return {"rows": rows,
            "totals": {"purchases": round(sum(r["purchases"] or 0 for r in rows), 2),
                       "payable": round(sum(r["payable"] or 0 for r in rows), 2)}}


@router.get("/inventory")
def inventory(division: str = "", category: str = "",
              limit: int = Query(500, le=5000),
              _user: dict = Depends(require("report:read"))) -> dict:
    where = ["is_active = 1"]
    params: list = []
    if division:
        where.append("division = ?")
        params.append(division.upper())
    if category:
        where.append("category = ?")
        params.append(category.upper())
    clause = " AND ".join(where)

    rows = db.query(
        f"SELECT code, name, division, category, unit, qty_on_hand, cost, price_a, "
        f"ROUND(qty_on_hand * cost, 2) AS value, reorder_point, expiry_date "
        f"FROM stock WHERE {clause} ORDER BY value DESC LIMIT ?", params + [limit])
    total = db.query_one(
        f"SELECT COUNT(*) AS items, ROUND(SUM(qty_on_hand * cost), 2) AS value "
        f"FROM stock WHERE {clause}", params) or {}
    return {"rows": rows, "totals": total}


@router.get("/expiring")
def expiring(days: int = 90, include_expired: bool = True,
             _user: dict = Depends(require("report:read"))) -> list[dict]:
    floor = "date('1900-01-01')" if include_expired else "date('now')"
    return db.query(
        f"SELECT code, name, lot_no, expiry_date, qty_on_hand, unit, cost, "
        f"ROUND(qty_on_hand * cost, 2) AS value, "
        f"CAST(julianday(expiry_date) - julianday('now') AS INTEGER) AS days_left "
        f"FROM stock WHERE is_active = 1 AND expiry_date IS NOT NULL "
        f"AND expiry_date >= {floor} AND expiry_date <= date('now', ?) "
        f"AND qty_on_hand > 0 ORDER BY expiry_date", (f"+{int(days)} day",))


@router.get("/depleted")
def depleted(_user: dict = Depends(require("report:read"))) -> list[dict]:
    return db.query(
        "SELECT code, name, division, unit, qty_on_hand, reorder_point, reorder_qty, "
        "supplier_code, cost FROM stock WHERE is_active = 1 "
        "AND (qty_on_hand <= 0 OR (reorder_point > 0 AND qty_on_hand <= reorder_point)) "
        "ORDER BY qty_on_hand, name LIMIT 1000")


@router.get("/movers")
def movers(days: int = 90, direction: str = "top", limit: int = 50,
           _user: dict = Depends(require("report:read"))) -> list[dict]:
    """Fast and slow moving stock, from the movement ledger."""
    order = "quantity DESC" if direction == "top" else "quantity ASC"
    return db.query(
        f"""
        SELECT s.code, s.name, s.qty_on_hand, s.unit,
               ROUND(COALESCE(SUM(-m.qty), 0), 2) AS quantity,
               ROUND(COALESCE(SUM(m.line_total), 0), 2) AS sales
        FROM stock s
        LEFT JOIN stock_moves m ON m.stock_code = s.code AND m.move_type = 'SALE'
             AND m.doc_date >= date('now', ?)
        WHERE s.is_active = 1
        GROUP BY s.code ORDER BY {order}, s.name LIMIT ?
        """, (f"-{int(days)} day", max(1, min(limit, 500))))


@router.get("/collections")
def collections_report(date_from: str = "", date_to: str = "",
                       _user: dict = Depends(require("report:read"))) -> dict:
    rows = db.query(
        """
        SELECT substr(col_date, 1, 7) AS label, method,
               ROUND(SUM(net_amount), 2) AS collected, COUNT(*) AS payments
        FROM collections WHERE status <> 'REVERSED' AND col_date BETWEEN ? AND ?
        GROUP BY label, method ORDER BY label DESC, method
        """, (date_from or "1900-01-01", date_to or "2999-12-31"))
    return {"rows": rows,
            "totals": {"collected": round(sum(r["collected"] or 0 for r in rows), 2)}}


@router.get("/inactive-customers")
def inactive_customers(months: int = 12,
                       _user: dict = Depends(require("report:read"))) -> list[dict]:
    return db.query(
        "SELECT code, name, city, salesman, balance, last_txn FROM customers "
        "WHERE is_active = 1 AND (last_txn IS NULL OR last_txn < date('now', ?)) "
        "ORDER BY balance DESC, name LIMIT 1000", (f"-{int(months)} month",))
