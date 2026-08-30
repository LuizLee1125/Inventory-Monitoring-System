-- ---------------------------------------------------------------- archive --
-- The legacy O_* files: documents the DOS system purged out of the working
-- set over twenty-five years. Read-only here, and deliberately without foreign
-- keys - an archived invoice often names a customer who was purged years ago,
-- and the record of what happened should survive that.

CREATE TABLE IF NOT EXISTS archived_invoices (
    inv_no        TEXT PRIMARY KEY,
    customer_code TEXT NOT NULL DEFAULT '',
    customer_name TEXT NOT NULL DEFAULT '',
    address       TEXT NOT NULL DEFAULT '',
    city          TEXT NOT NULL DEFAULT '',
    inv_date      TEXT NOT NULL,
    terms_text    TEXT NOT NULL DEFAULT '',
    salesman      TEXT NOT NULL DEFAULT '',
    remarks       TEXT NOT NULL DEFAULT '',
    gross         REAL NOT NULL DEFAULT 0,
    net_amount    REAL NOT NULL DEFAULT 0,
    cost_amount   REAL NOT NULL DEFAULT 0,
    paid_amount   REAL NOT NULL DEFAULT 0,
    balance       REAL NOT NULL DEFAULT 0,
    status        TEXT NOT NULL DEFAULT '',
    created_by    TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS ix_arcinv_cust ON archived_invoices(customer_code);
CREATE INDEX IF NOT EXISTS ix_arcinv_date ON archived_invoices(inv_date DESC);
CREATE INDEX IF NOT EXISTS ix_arcinv_name ON archived_invoices(customer_name);

CREATE TABLE IF NOT EXISTS archived_purchases (
    pur_no        TEXT PRIMARY KEY,
    supplier_code TEXT NOT NULL DEFAULT '',
    supplier_name TEXT NOT NULL DEFAULT '',
    pur_date      TEXT NOT NULL,
    terms_text    TEXT NOT NULL DEFAULT '',
    remarks       TEXT NOT NULL DEFAULT '',
    gross         REAL NOT NULL DEFAULT 0,
    net_amount    REAL NOT NULL DEFAULT 0,
    created_by    TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS ix_arcpur_date ON archived_purchases(pur_date DESC);
CREATE INDEX IF NOT EXISTS ix_arcpur_supp ON archived_purchases(supplier_code);

CREATE TABLE IF NOT EXISTS archived_returns (
    sr_no         TEXT PRIMARY KEY,
    ref_invoice   TEXT NOT NULL DEFAULT '',
    customer_code TEXT NOT NULL DEFAULT '',
    customer_name TEXT NOT NULL DEFAULT '',
    sr_date       TEXT NOT NULL,
    remarks       TEXT NOT NULL DEFAULT '',
    net_amount    REAL NOT NULL DEFAULT 0,
    status        TEXT NOT NULL DEFAULT '',
    created_by    TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS ix_arcsr_date ON archived_returns(sr_date DESC);
CREATE INDEX IF NOT EXISTS ix_arcsr_cust ON archived_returns(customer_code);

CREATE TABLE IF NOT EXISTS archived_collections (
    col_no        TEXT PRIMARY KEY,
    customer_code TEXT NOT NULL DEFAULT '',
    customer_name TEXT NOT NULL DEFAULT '',
    col_date      TEXT NOT NULL,
    remarks       TEXT NOT NULL DEFAULT '',
    amount        REAL NOT NULL DEFAULT 0,
    net_amount    REAL NOT NULL DEFAULT 0,
    created_by    TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS ix_arccol_date ON archived_collections(col_date DESC);
CREATE INDEX IF NOT EXISTS ix_arccol_cust ON archived_collections(customer_code);

-- O_TRN2 and O_STKREC: the line detail behind every archived document.
CREATE TABLE IF NOT EXISTS archived_moves (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    move_type     TEXT NOT NULL,
    doc_no        TEXT NOT NULL DEFAULT '',
    doc_date      TEXT NOT NULL,
    stock_code    TEXT NOT NULL DEFAULT '',
    description   TEXT NOT NULL DEFAULT '',
    qty           REAL NOT NULL DEFAULT 0,
    unit          TEXT NOT NULL DEFAULT '',
    unit_cost     REAL NOT NULL DEFAULT 0,
    unit_price    REAL NOT NULL DEFAULT 0,
    line_total    REAL NOT NULL DEFAULT 0,
    customer_code TEXT NOT NULL DEFAULT '',
    supplier_code TEXT NOT NULL DEFAULT '',
    lot_no        TEXT NOT NULL DEFAULT '',
    expiry_date   TEXT,
    created_by    TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS ix_arcmv_doc   ON archived_moves(doc_no);
CREATE INDEX IF NOT EXISTS ix_arcmv_stock ON archived_moves(stock_code, doc_date DESC);
CREATE INDEX IF NOT EXISTS ix_arcmv_date  ON archived_moves(doc_date DESC);

-- Master records that were purged: needed to make sense of the documents above.
CREATE TABLE IF NOT EXISTS archived_customers (
    code    TEXT PRIMARY KEY,
    name    TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    city    TEXT NOT NULL DEFAULT '',
    phone   TEXT NOT NULL DEFAULT '',
    salesman TEXT NOT NULL DEFAULT '',
    balance REAL NOT NULL DEFAULT 0,
    last_txn TEXT
);

CREATE TABLE IF NOT EXISTS archived_stock (
    code     TEXT PRIMARY KEY,
    name     TEXT NOT NULL DEFAULT '',
    division TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT '',
    unit     TEXT NOT NULL DEFAULT '',
    cost     REAL NOT NULL DEFAULT 0,
    price_a  REAL NOT NULL DEFAULT 0,
    last_txn TEXT
);

CREATE TABLE IF NOT EXISTS archived_suppliers (
    code    TEXT PRIMARY KEY,
    name    TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    city    TEXT NOT NULL DEFAULT '',
    phone   TEXT NOT NULL DEFAULT ''
);
