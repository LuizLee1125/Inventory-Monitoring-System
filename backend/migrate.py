#!/usr/bin/env python3
"""
Migrate the legacy FoxPro .DBF files into the web application's SQLite database.

    python backend/migrate.py                    # everything
    python backend/migrate.py --since 2020-01-01 # limit the movement ledger
    python backend/migrate.py --skip-moves       # masters and documents only
    python backend/migrate.py --reset            # drop and rebuild first

The legacy files are only ever read. Nothing here writes to a .DBF.

Passwords cannot be carried across as-is (the legacy PASSFYL stores them in
plaintext), so each one is hashed on the way in and the account is flagged
`must_change_password`. Staff keep the password they know; it stops being
recoverable from the database.
"""

from __future__ import annotations

import argparse
import sys
import time
from datetime import date, datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from app import config, db, security

try:
    from dbfread import DBF, FieldParser
except ImportError:
    sys.exit("dbfread is not installed.  Run:  pip install -r backend/requirements.txt")


class TolerantParser(FieldParser):
    """Twenty-five years of data contain numerics holding a bare '.' and other
    debris FoxPro tolerated. Bad cells become None instead of aborting."""

    def parse(self, field, data):
        try:
            return super().parse(field, data)
        except Exception:
            return None


def table(name: str) -> DBF | None:
    path = config.LEGACY_DIR / f"{name}.DBF"
    if not path.exists():
        print(f"  ! {name}.DBF not found, skipped")
        return None
    return DBF(str(path), encoding="cp437", char_decode_errors="replace",
               ignore_missing_memofile=True, parserclass=TolerantParser, load=False)


# --------------------------------------------------------------------------- #
# value helpers
# --------------------------------------------------------------------------- #

def S(value, upper: bool = False) -> str:
    text = "" if value is None else str(value).strip()
    return text.upper() if upper else text


def N(value) -> float:
    try:
        return round(float(value or 0), 2)
    except (TypeError, ValueError):
        return 0.0


def INT(value) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def D(value) -> str | None:
    if isinstance(value, (date, datetime)):
        iso = value.isoformat()[:10]
        # FoxPro happily stored year 0001 and similar in blank date fields.
        return iso if "0001-01-01" < iso < "2100-01-01" else None
    text = S(value)
    return text[:10] if len(text) >= 10 else None


def progress(label: str, n: int) -> None:
    print(f"  {label:<26}{n:>10,}")


# --------------------------------------------------------------------------- #
# per-table migrations
# --------------------------------------------------------------------------- #

def migrate_users(conn) -> int:
    src = table("PASSFYL")
    if src is None:
        return 0
    count = 0
    for rec in src:
        username = S(rec.get("USER_M"), upper=True)
        if not username:
            continue
        legacy_menu = S(rec.get("ACCESMNU"), upper=True)
        role = security.LEGACY_MENU_TO_ROLE.get(legacy_menu, "viewer")
        password = S(rec.get("PASSWORD")) or username
        # PASSFYL held one row per user *per access code*, so the same name can
        # appear several times. The first row wins; count only real inserts.
        cursor = conn.execute(
            """
            INSERT INTO users(username, password_hash, full_name, role,
                              is_active, must_change_password,
                              legacy_access_code, created_at)
            VALUES (?, ?, ?, ?, 1, 1, ?, ?)
            ON CONFLICT(username) DO NOTHING
            """,
            (username, security.hash_password(password), username.title(), role,
             S(rec.get("ACCESS_C"), upper=True), db.now()),
        )
        count += cursor.rowcount or 0
    return count


def migrate_suppliers(conn) -> int:
    src = table("SPLYRFYL")
    if src is None:
        return 0
    count = 0
    for rec in src:
        code = S(rec.get("SPLYR_N"), upper=True)
        if not code:
            continue
        conn.execute(
            """
            INSERT INTO suppliers(code, name, address, city, contact, phone,
                                  terms_text, terms_days, credit_limit,
                                  purchases, payments, balance, remarks,
                                  last_txn, updated_at, updated_by)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(code) DO NOTHING
            """,
            (code, S(rec.get("SPLYR_M")), S(rec.get("SPLYR_AD")),
             S(rec.get("SPLYR_CT")), S(rec.get("SPLYR_CP")), S(rec.get("SPLYR_P")),
             S(rec.get("SPLYR_TP")), INT(rec.get("SPLYR_T")), N(rec.get("SPLYR_CL")),
             N(rec.get("SPLYR_PUR")), N(rec.get("SPLYR_PAY")), N(rec.get("SPLYR_BAL")),
             S(rec.get("SPLYR_REM")), D(rec.get("SPLYR_LT")), db.now(), "migration"),
        )
        count += 1
    return count


def migrate_customers(conn) -> int:
    src = table("CUSTFYL")
    if src is None:
        return 0
    count = 0
    for rec in src:
        code = S(rec.get("CUST_N"), upper=True)
        if not code:
            continue
        conn.execute(
            """
            INSERT INTO customers(code, name, address, city, contact_person, phone,
                                  terms_text, terms_days, price_cat, credit_limit,
                                  purchases, payments, returns_total, balance,
                                  salesman, tin, business_style, date_started,
                                  remarks, last_txn, updated_at, updated_by)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(code) DO NOTHING
            """,
            (code, S(rec.get("CUST_M")), S(rec.get("CUST_AD")), S(rec.get("CUST_CT")),
             S(rec.get("CUST_CP")), S(rec.get("CUST_P")), S(rec.get("CUST_TP")),
             INT(rec.get("CUST_T")), S(rec.get("CUST_PC"), upper=True) or "A",
             N(rec.get("CUST_CL")), N(rec.get("CUST_PUR")), N(rec.get("CUST_PAY")),
             N(rec.get("CUST_SR")), N(rec.get("CUST_BAL")),
             S(rec.get("CUST_S"), upper=True), S(rec.get("TIN")),
             S(rec.get("BUS_STYLE")), D(rec.get("CUST_SD")), S(rec.get("CUST_REM")),
             D(rec.get("CUST_LT")), db.now(), "migration"),
        )
        count += 1
    return count


def migrate_stock(conn) -> int:
    src = table("STKFYL")
    if src is None:
        return 0
    count = 0
    for rec in src:
        code = S(rec.get("STK_N"), upper=True)
        if not code:
            continue
        # STK_AC is the running average cost, STK_PC the last purchase cost.
        cost = N(rec.get("STK_AC")) or N(rec.get("STK_PC"))
        conn.execute(
            """
            INSERT INTO stock(code, name, division, category, unit, pack_qty,
                              pack_unit, lot_no, expiry_date, qty_on_hand,
                              reorder_point, reorder_qty, supplier_code, cost,
                              price_a, price_b, price_c, price_d, price_e,
                              remarks, last_txn, price_updated, updated_at, updated_by)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(code) DO NOTHING
            """,
            (code, S(rec.get("STK_M")), S(rec.get("STK_DV"), upper=True),
             S(rec.get("STK_CAT"), upper=True), S(rec.get("QTY_U"), upper=True),
             INT(rec.get("QTY_PQ")), S(rec.get("QTY_PU"), upper=True),
             S(rec.get("LOT_N")), D(rec.get("EXPIRY_D")), N(rec.get("QTY_R")),
             N(rec.get("QTY1")), N(rec.get("QTY2")),
             S(rec.get("SPLYR_N"), upper=True), cost,
             N(rec.get("PRYS_A")), N(rec.get("PRYS_B")), N(rec.get("PRYS_C")),
             N(rec.get("PRYS_D")), N(rec.get("PRYS_E")), S(rec.get("STK_REM")),
             D(rec.get("STK_LT")), D(rec.get("PRYS_UD")), db.now(), "migration"),
        )
        count += 1

    # Divisions and categories were never separate files; derive them.
    conn.execute("INSERT OR IGNORE INTO divisions(code, name) "
                 "SELECT DISTINCT division, division FROM stock WHERE division <> ''")
    conn.execute("INSERT OR IGNORE INTO categories(code, name) "
                 "SELECT DISTINCT category, category FROM stock WHERE category <> ''")
    return count


def migrate_invoices(conn) -> int:
    src = table("SIFYL")
    if src is None:
        return 0
    count = 0
    for rec in src:
        inv_no = S(rec.get("INV_N"), upper=True)
        if not inv_no:
            continue
        paid = (S(rec.get("PAID"), upper=True) == "Y"
                or S(rec.get("FINALPAID"), upper=True) == "Y")
        balance = N(rec.get("INV_BAL"))
        status = "PAID" if paid or balance <= 0.005 else "OPEN"
        inv_date = D(rec.get("INV_D")) or "1900-01-01"
        terms_days = INT(rec.get("CUST_T"))
        conn.execute(
            """
            INSERT INTO invoices(inv_no, customer_code, customer_name, address, city,
                                 inv_date, due_date, terms_text, terms_days, price_cat,
                                 salesman, remarks, gross, disc1, disc2, disc3,
                                 discount_amt, net_amount, cost_amount, adjustment,
                                 paid_amount, balance, status, posted_at,
                                 created_at, created_by)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(inv_no) DO NOTHING
            """,
            (inv_no, S(rec.get("CUST_N"), upper=True), S(rec.get("CUST_M")),
             S(rec.get("CUST_AD")), S(rec.get("CUST_CT")), inv_date,
             _add_days(inv_date, terms_days), S(rec.get("CUST_TP")), terms_days,
             S(rec.get("CUST_PC"), upper=True) or "A", S(rec.get("CUST_S"), upper=True),
             S(rec.get("SI_REM")), N(rec.get("INV_A")), N(rec.get("DCOUNT1")),
             N(rec.get("DCOUNT2")), N(rec.get("DCOUNT3")),
             max(0.0, N(rec.get("INV_A")) - N(rec.get("NET_A"))), N(rec.get("NET_A")),
             N(rec.get("INV_C")), N(rec.get("INV_ADJ")), N(rec.get("INV_PAY")),
             balance, status, D(rec.get("POST_D")), db.now(),
             S(rec.get("USER_M"), upper=True)),
        )
        count += 1
    return count


def migrate_purchases(conn) -> int:
    src = table("PURFYL")
    if src is None:
        return 0
    count = 0
    for rec in src:
        pur_no = S(rec.get("INV_N"), upper=True)
        if not pur_no:
            continue
        pur_date = D(rec.get("INV_D")) or "1900-01-01"
        terms_days = INT(rec.get("SPLYR_T"))
        net = N(rec.get("NET_A"))
        conn.execute(
            """
            INSERT INTO purchases(pur_no, supplier_code, supplier_name, pur_date,
                                  due_date, terms_text, terms_days, remarks, gross,
                                  disc1, disc2, disc3, net_amount, paid_amount,
                                  balance, status, created_at, created_by)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(pur_no) DO NOTHING
            """,
            (pur_no, S(rec.get("SPLYR_N"), upper=True), S(rec.get("SPLYR_M")),
             pur_date, _add_days(pur_date, terms_days), S(rec.get("SPLYR_TP")),
             terms_days, S(rec.get("INV_REM")), N(rec.get("INV_A")),
             N(rec.get("DCOUNT1")), N(rec.get("DCOUNT2")), N(rec.get("DCOUNT3")),
             # PURFYL carried no payment fields - the DOS system tracked what it
             # owed suppliers outside this file. Historical purchases therefore
             # migrate as settled; treating 25 years of them as outstanding
             # would invent a payable that never existed. Purchases raised in
             # the web edition do track payment.
             net, net, 0.0, "PAID", db.now(), S(rec.get("USER_M"), upper=True)),
        )
        count += 1
    return count


def migrate_returns(conn) -> int:
    src = table("SRFYL")
    if src is None:
        return 0
    count = 0
    for rec in src:
        sr_no = S(rec.get("INV_N"), upper=True)
        if not sr_no:
            continue
        conn.execute(
            """
            INSERT INTO sales_returns(sr_no, ref_invoice, customer_code, customer_name,
                                      sr_date, remarks, gross, disc1, net_amount,
                                      applied_amt, status, posted_at, created_at, created_by)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(sr_no) DO NOTHING
            """,
            (sr_no, S(rec.get("RINV_N"), upper=True), S(rec.get("CUST_N"), upper=True),
             S(rec.get("CUST_M")), D(rec.get("INV_D")) or "1900-01-01",
             S(rec.get("SI_REM")), N(rec.get("INV_A")), N(rec.get("DCOUNT1")),
             N(rec.get("NET_A")), N(rec.get("INV_PAY")),
             "PAID" if S(rec.get("PAID"), upper=True) == "Y" else "OPEN",
             D(rec.get("POST_D")), db.now(), S(rec.get("USER_M"), upper=True)),
        )
        count += 1
    return count


def migrate_collections(conn) -> int:
    src = table("COLECFYL")
    if src is None:
        return 0
    count = 0
    for rec in src:
        col_no = S(rec.get("COLEC_N"), upper=True)
        if not col_no:
            continue
        check_total = N(rec.get("TCHK_A"))
        conn.execute(
            """
            INSERT INTO collections(col_no, customer_code, customer_name, col_date,
                                    method, amount, adjustment, net_amount,
                                    applied_amt, remarks, status, created_at, created_by)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(col_no) DO NOTHING
            """,
            (col_no, S(rec.get("CUST_N"), upper=True), S(rec.get("CUST_M")),
             D(rec.get("COLEC_D")) or "1900-01-01",
             "CHECK" if check_total else "CASH", N(rec.get("COLEC_A")),
             N(rec.get("COLEC_ADJ")), N(rec.get("NET_A")) or N(rec.get("COLEC_A")),
             N(rec.get("INV_PAY")), S(rec.get("COLEC_REM")), "POSTED",
             db.now(), S(rec.get("USER_M"), upper=True)),
        )
        count += 1
    return count


def migrate_collection_applications(conn) -> int:
    """COLECREC holds one row per invoice a payment was applied to."""
    src = table("COLECREC")
    if src is None:
        return 0
    known = {r["col_no"] for r in db.query("SELECT col_no FROM collections")}
    count = 0
    batch = []
    for rec in src:
        col_no = S(rec.get("COLEC_N"), upper=True)
        if not col_no or col_no not in known:
            continue
        batch.append((col_no, S(rec.get("INV_N"), upper=True), N(rec.get("COLEC_A")),
                      S(rec.get("CHK_N")), D(rec.get("CHK_D")), D(rec.get("CHK_DD")),
                      N(rec.get("CHK_A"))))
        if len(batch) >= 5000:
            conn.executemany(
                "INSERT INTO collection_applications"
                "(col_no, inv_no, amount, check_no, check_date, check_due, check_amt) "
                "VALUES (?,?,?,?,?,?,?)", batch)
            count += len(batch)
            batch.clear()
    if batch:
        conn.executemany(
            "INSERT INTO collection_applications"
            "(col_no, inv_no, amount, check_no, check_date, check_due, check_amt) "
            "VALUES (?,?,?,?,?,?,?)", batch)
        count += len(batch)
    return count


MOVE_TYPES = {"S": "SALE", "P": "PURCHASE", "R": "RETURN", "A": "ADJUST"}

# Rows written between commits during the movement pass. One transaction for all
# 2.5 million rows would grow a write-ahead log larger than the database itself.
COMMIT_EVERY = 200_000


def migrate_moves(conn, since: str | None) -> tuple[int, int]:
    """Stream STKREC into stock_moves, and rebuild invoice lines from it.

    STKREC is the largest file in the system (658 MB, 2.5 million rows) and is
    the only source for invoice line detail - the legacy SIFYL held headers
    only.
    """
    src = table("STKREC")
    if src is None:
        return 0, 0

    invoices = {r["inv_no"] for r in db.query("SELECT inv_no FROM invoices")}
    moves: list[tuple] = []
    lines: list[tuple] = []
    n_moves = n_lines = 0
    line_counter: dict[str, int] = {}
    stamp = db.now()

    move_sql = (
        "INSERT INTO stock_moves(move_type, doc_no, doc_date, stock_code, description,"
        " qty, unit, unit_cost, unit_price, line_total, customer_code, supplier_code,"
        " division, category, lot_no, expiry_date, created_at, created_by) "
        "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
    )
    line_sql = (
        "INSERT INTO invoice_lines(inv_no, line_no, stock_code, description, qty, unit,"
        " unit_price, unit_cost, disc1, disc2, disc3, line_total, lot_no, expiry_date) "
        "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
    )

    for rec in src:
        doc_date = D(rec.get("TRANS_D"))
        if since and (doc_date is None or doc_date < since):
            continue
        code = S(rec.get("STK_N"), upper=True)
        if not code:
            continue

        trans = S(rec.get("TRANS_C"), upper=True)
        move_type = MOVE_TYPES.get(trans, "ADJUST")
        doc_no = S(rec.get("TRANS_N"), upper=True)
        qty = N(rec.get("ISSUE_Q"))
        signed = -qty if move_type == "SALE" else qty

        moves.append((
            move_type, doc_no, doc_date or "1900-01-01", code, S(rec.get("STK_M")),
            signed, S(rec.get("ISSUE_U"), upper=True), N(rec.get("ISSUE_CP")),
            N(rec.get("ISSUE_P")), N(rec.get("T_PRYS")),
            S(rec.get("CUST_N"), upper=True), S(rec.get("SPLYR_N"), upper=True),
            S(rec.get("STK_DV"), upper=True), S(rec.get("STK_CAT"), upper=True),
            S(rec.get("LOT_N")), D(rec.get("EXPIRY_D")), stamp,
            S(rec.get("USER_M"), upper=True),
        ))

        if move_type == "SALE" and doc_no in invoices:
            line_counter[doc_no] = line_counter.get(doc_no, 0) + 1
            lines.append((
                doc_no, line_counter[doc_no], code, S(rec.get("STK_M")), qty,
                S(rec.get("ISSUE_U"), upper=True), N(rec.get("ISSUE_P")),
                N(rec.get("ISSUE_CP")), N(rec.get("DCOUNT1")), N(rec.get("DCOUNT2")),
                N(rec.get("DCOUNT3")), N(rec.get("T_PRYS")), S(rec.get("LOT_N")),
                D(rec.get("EXPIRY_D")),
            ))

        if len(moves) >= 20000:
            conn.executemany(move_sql, moves)
            n_moves += len(moves)
            moves.clear()
            print(f"    ... {n_moves:,} movements", flush=True)
            if n_moves % COMMIT_EVERY < 20000:
                # Commit and reopen: keeps the write-ahead log bounded and means
                # an interrupted migration leaves finished work behind.
                conn.execute("COMMIT")
                conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
                conn.execute("BEGIN IMMEDIATE")
        if len(lines) >= 20000:
            conn.executemany(line_sql, lines)
            n_lines += len(lines)
            lines.clear()

    if moves:
        conn.executemany(move_sql, moves)
        n_moves += len(moves)
    if lines:
        conn.executemany(line_sql, lines)
        n_lines += len(lines)
    return n_moves, n_lines


def rebuild_customer_monthly(conn) -> int:
    """The legacy CUSTFYL cached 60 months of history in columns. Recompute it
    from the invoices and returns instead, so the year is never ambiguous."""
    conn.execute("DELETE FROM customer_monthly")
    conn.execute(
        """
        INSERT INTO customer_monthly(customer_code, year, month, sales, returns)
        SELECT customer_code,
               CAST(substr(inv_date, 1, 4) AS INTEGER),
               CAST(substr(inv_date, 6, 2) AS INTEGER),
               ROUND(SUM(net_amount), 2), 0
        FROM invoices
        WHERE status <> 'CANCELLED' AND inv_date >= '1990-01-01'
          AND customer_code IN (SELECT code FROM customers)
        GROUP BY 1, 2, 3
        """
    )
    conn.execute(
        """
        INSERT INTO customer_monthly(customer_code, year, month, sales, returns)
        SELECT customer_code,
               CAST(substr(sr_date, 1, 4) AS INTEGER),
               CAST(substr(sr_date, 6, 2) AS INTEGER),
               0, ROUND(SUM(net_amount), 2)
        FROM sales_returns
        WHERE sr_date >= '1990-01-01'
          AND customer_code IN (SELECT code FROM customers)
        GROUP BY 1, 2, 3
        ON CONFLICT(customer_code, year, month)
        DO UPDATE SET returns = returns + excluded.returns
        """
    )
    return db.scalar("SELECT COUNT(*) FROM customer_monthly", default=0)


def rebuild_balances(conn) -> int:
    """Recompute customer and supplier balances from the open documents.

    The legacy CUST_BAL and SPLYR_BAL fields were running totals maintained by
    the DOS screens, and 25 years of purges, archive runs and half-finished
    saves left them disagreeing with the invoices they are supposed to
    summarise. The documents are the source of truth, so the masters are
    derived from them.
    """
    conn.execute(
        """
        UPDATE customers SET balance = ROUND(COALESCE((
            SELECT SUM(i.balance) FROM invoices i
            WHERE i.customer_code = customers.code
              AND i.status <> 'CANCELLED' AND i.balance > 0.005
        ), 0), 2)
        """
    )
    conn.execute(
        """
        UPDATE suppliers SET balance = ROUND(COALESCE((
            SELECT SUM(p.balance) FROM purchases p
            WHERE p.supplier_code = suppliers.code
              AND p.status <> 'CANCELLED' AND p.balance > 0.005
        ), 0), 2)
        """
    )
    return db.scalar("SELECT COUNT(*) FROM customers WHERE balance > 0.005", default=0)


def align_sequences(conn) -> None:
    """Move each document sequence past the highest number already migrated so
    new documents never collide with historical ones."""
    for seq, sql in (
        ("invoice", "SELECT inv_no FROM invoices"),
        ("purchase", "SELECT pur_no FROM purchases"),
        ("return", "SELECT sr_no FROM sales_returns"),
        ("collection", "SELECT col_no FROM collections"),
    ):
        highest = 0
        for row in conn.execute(sql):
            digits = "".join(ch for ch in str(row[0]) if ch.isdigit())
            if digits:
                highest = max(highest, int(digits[-6:]))
        db.bump_sequence_past(conn, seq, highest)


def ensure_admin(conn) -> str | None:
    """Guarantee at least one account that can manage users."""
    if db.scalar("SELECT COUNT(*) FROM users WHERE role = 'admin'", default=0):
        return None
    password = "changeme"
    conn.execute(
        "INSERT INTO users(username, password_hash, full_name, role, is_active,"
        " must_change_password, created_at) VALUES (?,?,?,?,1,1,?)",
        ("ADMIN", security.hash_password(password), "Administrator", "admin", db.now()),
    )
    return password


def _add_days(iso: str, days: int) -> str | None:
    if not iso or not days:
        return iso or None
    try:
        return (date.fromisoformat(iso) + timedelta(days=days)).isoformat()
    except ValueError:
        return iso


# --------------------------------------------------------------------------- #

def main() -> None:
    parser = argparse.ArgumentParser(description="Migrate legacy DBF data into SQLite.")
    parser.add_argument("--since", help="only migrate movements on/after this date "
                                        "(YYYY-MM-DD); headers are always migrated")
    parser.add_argument("--skip-moves", action="store_true",
                        help="skip STKREC entirely (fast, but no invoice lines)")
    parser.add_argument("--reset", action="store_true",
                        help="delete the existing database first")
    args = parser.parse_args()

    if args.reset and config.DB_PATH.exists():
        for suffix in ("", "-wal", "-shm"):
            path = Path(str(config.DB_PATH) + suffix)
            if path.exists():
                path.unlink()
        print(f"Removed {config.DB_PATH}")

    print(f"Legacy data : {config.LEGACY_DIR}")
    print(f"Database    : {config.DB_PATH}\n")
    db.init_db()

    started = time.monotonic()
    with db.transaction() as conn:
        print("Master files")
        progress("users", migrate_users(conn))
        progress("suppliers", migrate_suppliers(conn))
        progress("customers", migrate_customers(conn))
        progress("stock", migrate_stock(conn))

        print("\nDocuments")
        progress("invoices", migrate_invoices(conn))
        progress("purchases", migrate_purchases(conn))
        progress("sales returns", migrate_returns(conn))
        progress("collections", migrate_collections(conn))
        progress("payment applications", migrate_collection_applications(conn))

        if not args.skip_moves:
            print("\nMovement ledger (this is the slow one)")
            n_moves, n_lines = migrate_moves(conn, args.since)
            progress("stock movements", n_moves)
            progress("invoice lines", n_lines)

        print("\nDerived data")
        progress("customer monthly history", rebuild_customer_monthly(conn))
        progress("customers with a balance", rebuild_balances(conn))
        align_sequences(conn)
        fallback = ensure_admin(conn)

    db.execute("PRAGMA optimize")
    elapsed = time.monotonic() - started
    print(f"\nDone in {elapsed:,.0f}s. Database: {config.DB_PATH}")
    if fallback:
        print(f"\nNo admin account existed, so ADMIN was created with the password "
              f"'{fallback}'. Sign in and change it immediately.")
    else:
        print("\nMigrated accounts keep their legacy password (now hashed) and are "
              "required to change it at first sign-in.")


if __name__ == "__main__":
    main()
