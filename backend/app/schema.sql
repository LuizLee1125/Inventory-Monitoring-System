-- Marina Trading IMS - Web Edition
-- Relational schema, migrated from the legacy FoxPro .DBF tables.
--
-- Conventions:
--   * every mutable business row carries `version` for optimistic locking
--     (the modern replacement for the legacy RLOCK() retry prompt)
--   * money is REAL, quantities are REAL, dates are TEXT in ISO 'YYYY-MM-DD'
--   * timestamps are TEXT in ISO 8601 UTC

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------- security --

CREATE TABLE IF NOT EXISTS users (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    username             TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    password_hash        TEXT    NOT NULL,
    full_name            TEXT    NOT NULL DEFAULT '',
    role                 TEXT    NOT NULL DEFAULT 'viewer',
    is_active            INTEGER NOT NULL DEFAULT 1,
    must_change_password INTEGER NOT NULL DEFAULT 0,
    legacy_access_code   TEXT,
    created_at           TEXT    NOT NULL,
    last_login           TEXT,
    version              INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS sessions (
    token      TEXT PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TEXT    NOT NULL,
    expires_at TEXT    NOT NULL,
    ip         TEXT,
    user_agent TEXT
);
CREATE INDEX IF NOT EXISTS ix_sessions_user ON sessions(user_id);

CREATE TABLE IF NOT EXISTS audit_log (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    at        TEXT NOT NULL,
    username  TEXT NOT NULL,
    action    TEXT NOT NULL,
    entity    TEXT NOT NULL,
    entity_id TEXT,
    detail    TEXT
);
CREATE INDEX IF NOT EXISTS ix_audit_at     ON audit_log(at DESC);
CREATE INDEX IF NOT EXISTS ix_audit_entity ON audit_log(entity, entity_id);

-- Document numbering. Incremented inside the same transaction as the insert,
-- so two clerks can never be handed the same invoice number.
CREATE TABLE IF NOT EXISTS sequences (
    name       TEXT    PRIMARY KEY,
    prefix     TEXT    NOT NULL DEFAULT '',
    next_value INTEGER NOT NULL DEFAULT 1,
    width      INTEGER NOT NULL DEFAULT 6
);

CREATE TABLE IF NOT EXISTS settings (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

-- ------------------------------------------------------------ master files --

CREATE TABLE IF NOT EXISTS divisions (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS categories (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS suppliers (
    code         TEXT PRIMARY KEY,
    name         TEXT    NOT NULL DEFAULT '',
    address      TEXT    NOT NULL DEFAULT '',
    city         TEXT    NOT NULL DEFAULT '',
    contact      TEXT    NOT NULL DEFAULT '',
    phone        TEXT    NOT NULL DEFAULT '',
    terms_text   TEXT    NOT NULL DEFAULT '',
    terms_days   INTEGER NOT NULL DEFAULT 0,
    credit_limit REAL    NOT NULL DEFAULT 0,
    purchases    REAL    NOT NULL DEFAULT 0,
    payments     REAL    NOT NULL DEFAULT 0,
    balance      REAL    NOT NULL DEFAULT 0,
    remarks      TEXT    NOT NULL DEFAULT '',
    last_txn     TEXT,
    is_active    INTEGER NOT NULL DEFAULT 1,
    version      INTEGER NOT NULL DEFAULT 1,
    updated_at   TEXT,
    updated_by   TEXT
);
CREATE INDEX IF NOT EXISTS ix_suppliers_name ON suppliers(name);

CREATE TABLE IF NOT EXISTS customers (
    code           TEXT PRIMARY KEY,
    name           TEXT    NOT NULL DEFAULT '',
    address        TEXT    NOT NULL DEFAULT '',
    city           TEXT    NOT NULL DEFAULT '',
    contact_person TEXT    NOT NULL DEFAULT '',
    phone          TEXT    NOT NULL DEFAULT '',
    terms_text     TEXT    NOT NULL DEFAULT '',
    terms_days     INTEGER NOT NULL DEFAULT 0,
    price_cat      TEXT    NOT NULL DEFAULT 'A',
    credit_limit   REAL    NOT NULL DEFAULT 0,
    purchases      REAL    NOT NULL DEFAULT 0,
    payments       REAL    NOT NULL DEFAULT 0,
    returns_total  REAL    NOT NULL DEFAULT 0,
    balance        REAL    NOT NULL DEFAULT 0,
    salesman       TEXT    NOT NULL DEFAULT '',
    tin            TEXT    NOT NULL DEFAULT '',
    business_style TEXT    NOT NULL DEFAULT '',
    date_started   TEXT,
    remarks        TEXT    NOT NULL DEFAULT '',
    last_txn       TEXT,
    is_active      INTEGER NOT NULL DEFAULT 1,
    version        INTEGER NOT NULL DEFAULT 1,
    updated_at     TEXT,
    updated_by     TEXT
);
CREATE INDEX IF NOT EXISTS ix_customers_name     ON customers(name);
CREATE INDEX IF NOT EXISTS ix_customers_salesman ON customers(salesman);
CREATE INDEX IF NOT EXISTS ix_customers_balance  ON customers(balance DESC);

-- The legacy CUSTFYL held 60 monthly history columns (JAN..DEC, JAN2..DEC2,
-- JAN_SR..DEC_SR). Those become rows.
CREATE TABLE IF NOT EXISTS customer_monthly (
    customer_code TEXT    NOT NULL REFERENCES customers(code) ON DELETE CASCADE,
    year          INTEGER NOT NULL,
    month         INTEGER NOT NULL,
    sales         REAL    NOT NULL DEFAULT 0,
    returns       REAL    NOT NULL DEFAULT 0,
    PRIMARY KEY (customer_code, year, month)
);

CREATE TABLE IF NOT EXISTS stock (
    code           TEXT PRIMARY KEY,
    name           TEXT    NOT NULL DEFAULT '',
    division       TEXT    NOT NULL DEFAULT '',
    category       TEXT    NOT NULL DEFAULT '',
    unit           TEXT    NOT NULL DEFAULT '',
    pack_qty       INTEGER NOT NULL DEFAULT 0,
    pack_unit      TEXT    NOT NULL DEFAULT '',
    lot_no         TEXT    NOT NULL DEFAULT '',
    expiry_date    TEXT,
    qty_on_hand    REAL    NOT NULL DEFAULT 0,
    qty_committed  REAL    NOT NULL DEFAULT 0,
    reorder_point  REAL    NOT NULL DEFAULT 0,
    reorder_qty    REAL    NOT NULL DEFAULT 0,
    supplier_code  TEXT,
    cost           REAL    NOT NULL DEFAULT 0,
    price_a        REAL    NOT NULL DEFAULT 0,
    price_b        REAL    NOT NULL DEFAULT 0,
    price_c        REAL    NOT NULL DEFAULT 0,
    price_d        REAL    NOT NULL DEFAULT 0,
    price_e        REAL    NOT NULL DEFAULT 0,
    remarks        TEXT    NOT NULL DEFAULT '',
    last_txn       TEXT,
    price_updated  TEXT,
    is_active      INTEGER NOT NULL DEFAULT 1,
    version        INTEGER NOT NULL DEFAULT 1,
    updated_at     TEXT,
    updated_by     TEXT
);
CREATE INDEX IF NOT EXISTS ix_stock_name     ON stock(name);
CREATE INDEX IF NOT EXISTS ix_stock_division ON stock(division);
CREATE INDEX IF NOT EXISTS ix_stock_category ON stock(category);
CREATE INDEX IF NOT EXISTS ix_stock_expiry   ON stock(expiry_date);
CREATE INDEX IF NOT EXISTS ix_stock_supplier ON stock(supplier_code);

-- ------------------------------------------------------------ transactions --

CREATE TABLE IF NOT EXISTS invoices (
    inv_no        TEXT PRIMARY KEY,
    customer_code TEXT    NOT NULL,
    customer_name TEXT    NOT NULL DEFAULT '',
    address       TEXT    NOT NULL DEFAULT '',
    city          TEXT    NOT NULL DEFAULT '',
    inv_date      TEXT    NOT NULL,
    due_date      TEXT,
    terms_text    TEXT    NOT NULL DEFAULT '',
    terms_days    INTEGER NOT NULL DEFAULT 0,
    price_cat     TEXT    NOT NULL DEFAULT 'A',
    salesman      TEXT    NOT NULL DEFAULT '',
    remarks       TEXT    NOT NULL DEFAULT '',
    gross         REAL    NOT NULL DEFAULT 0,
    disc1         REAL    NOT NULL DEFAULT 0,
    disc2         REAL    NOT NULL DEFAULT 0,
    disc3         REAL    NOT NULL DEFAULT 0,
    discount_amt  REAL    NOT NULL DEFAULT 0,
    net_amount    REAL    NOT NULL DEFAULT 0,
    cost_amount   REAL    NOT NULL DEFAULT 0,
    adjustment    REAL    NOT NULL DEFAULT 0,
    paid_amount   REAL    NOT NULL DEFAULT 0,
    balance       REAL    NOT NULL DEFAULT 0,
    status        TEXT    NOT NULL DEFAULT 'OPEN',   -- OPEN | PAID | CANCELLED
    posted_at     TEXT,
    created_at    TEXT    NOT NULL,
    created_by    TEXT    NOT NULL DEFAULT '',
    version       INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS ix_inv_customer ON invoices(customer_code);
CREATE INDEX IF NOT EXISTS ix_inv_date     ON invoices(inv_date DESC);
CREATE INDEX IF NOT EXISTS ix_inv_status   ON invoices(status);
CREATE INDEX IF NOT EXISTS ix_inv_balance  ON invoices(balance) WHERE balance > 0;

CREATE TABLE IF NOT EXISTS invoice_lines (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    inv_no      TEXT    NOT NULL REFERENCES invoices(inv_no) ON DELETE CASCADE,
    line_no     INTEGER NOT NULL DEFAULT 0,
    stock_code  TEXT    NOT NULL,
    description TEXT    NOT NULL DEFAULT '',
    qty         REAL    NOT NULL DEFAULT 0,
    unit        TEXT    NOT NULL DEFAULT '',
    unit_price  REAL    NOT NULL DEFAULT 0,
    unit_cost   REAL    NOT NULL DEFAULT 0,
    disc1       REAL    NOT NULL DEFAULT 0,
    disc2       REAL    NOT NULL DEFAULT 0,
    disc3       REAL    NOT NULL DEFAULT 0,
    line_total  REAL    NOT NULL DEFAULT 0,
    lot_no      TEXT    NOT NULL DEFAULT '',
    expiry_date TEXT
);
CREATE INDEX IF NOT EXISTS ix_invline_inv   ON invoice_lines(inv_no);
CREATE INDEX IF NOT EXISTS ix_invline_stock ON invoice_lines(stock_code);

CREATE TABLE IF NOT EXISTS purchases (
    pur_no        TEXT PRIMARY KEY,
    supplier_code TEXT    NOT NULL,
    supplier_name TEXT    NOT NULL DEFAULT '',
    pur_date      TEXT    NOT NULL,
    due_date      TEXT,
    terms_text    TEXT    NOT NULL DEFAULT '',
    terms_days    INTEGER NOT NULL DEFAULT 0,
    remarks       TEXT    NOT NULL DEFAULT '',
    gross         REAL    NOT NULL DEFAULT 0,
    disc1         REAL    NOT NULL DEFAULT 0,
    disc2         REAL    NOT NULL DEFAULT 0,
    disc3         REAL    NOT NULL DEFAULT 0,
    net_amount    REAL    NOT NULL DEFAULT 0,
    paid_amount   REAL    NOT NULL DEFAULT 0,
    balance       REAL    NOT NULL DEFAULT 0,
    status        TEXT    NOT NULL DEFAULT 'OPEN',
    posted_at     TEXT,
    created_at    TEXT    NOT NULL,
    created_by    TEXT    NOT NULL DEFAULT '',
    version       INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS ix_pur_supplier ON purchases(supplier_code);
CREATE INDEX IF NOT EXISTS ix_pur_date     ON purchases(pur_date DESC);

CREATE TABLE IF NOT EXISTS purchase_lines (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    pur_no      TEXT    NOT NULL REFERENCES purchases(pur_no) ON DELETE CASCADE,
    line_no     INTEGER NOT NULL DEFAULT 0,
    stock_code  TEXT    NOT NULL,
    description TEXT    NOT NULL DEFAULT '',
    qty         REAL    NOT NULL DEFAULT 0,
    unit        TEXT    NOT NULL DEFAULT '',
    unit_cost   REAL    NOT NULL DEFAULT 0,
    disc1       REAL    NOT NULL DEFAULT 0,
    line_total  REAL    NOT NULL DEFAULT 0,
    lot_no      TEXT    NOT NULL DEFAULT '',
    expiry_date TEXT
);
CREATE INDEX IF NOT EXISTS ix_purline_pur ON purchase_lines(pur_no);

CREATE TABLE IF NOT EXISTS sales_returns (
    sr_no         TEXT PRIMARY KEY,
    ref_invoice   TEXT,
    customer_code TEXT    NOT NULL,
    customer_name TEXT    NOT NULL DEFAULT '',
    sr_date       TEXT    NOT NULL,
    remarks       TEXT    NOT NULL DEFAULT '',
    gross         REAL    NOT NULL DEFAULT 0,
    disc1         REAL    NOT NULL DEFAULT 0,
    net_amount    REAL    NOT NULL DEFAULT 0,
    applied_amt   REAL    NOT NULL DEFAULT 0,
    status        TEXT    NOT NULL DEFAULT 'OPEN',
    posted_at     TEXT,
    created_at    TEXT    NOT NULL,
    created_by    TEXT    NOT NULL DEFAULT '',
    version       INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS ix_sr_customer ON sales_returns(customer_code);
CREATE INDEX IF NOT EXISTS ix_sr_date     ON sales_returns(sr_date DESC);

CREATE TABLE IF NOT EXISTS sales_return_lines (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    sr_no       TEXT    NOT NULL REFERENCES sales_returns(sr_no) ON DELETE CASCADE,
    line_no     INTEGER NOT NULL DEFAULT 0,
    stock_code  TEXT    NOT NULL,
    description TEXT    NOT NULL DEFAULT '',
    qty         REAL    NOT NULL DEFAULT 0,
    unit        TEXT    NOT NULL DEFAULT '',
    unit_price  REAL    NOT NULL DEFAULT 0,
    line_total  REAL    NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS ix_srline_sr ON sales_return_lines(sr_no);

CREATE TABLE IF NOT EXISTS collections (
    col_no        TEXT PRIMARY KEY,
    customer_code TEXT    NOT NULL,
    customer_name TEXT    NOT NULL DEFAULT '',
    col_date      TEXT    NOT NULL,
    method        TEXT    NOT NULL DEFAULT 'CASH',   -- CASH | CHECK | TRANSFER
    reference     TEXT    NOT NULL DEFAULT '',
    amount        REAL    NOT NULL DEFAULT 0,
    adjustment    REAL    NOT NULL DEFAULT 0,
    net_amount    REAL    NOT NULL DEFAULT 0,
    applied_amt   REAL    NOT NULL DEFAULT 0,
    remarks       TEXT    NOT NULL DEFAULT '',
    status        TEXT    NOT NULL DEFAULT 'POSTED',
    created_at    TEXT    NOT NULL,
    created_by    TEXT    NOT NULL DEFAULT '',
    version       INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS ix_col_customer ON collections(customer_code);
CREATE INDEX IF NOT EXISTS ix_col_date     ON collections(col_date DESC);

-- One row per invoice a payment was applied to. The legacy COLECREC carried
-- the check details on each application row, so they are kept here.
CREATE TABLE IF NOT EXISTS collection_applications (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    col_no     TEXT NOT NULL REFERENCES collections(col_no) ON DELETE CASCADE,
    inv_no     TEXT NOT NULL,
    amount     REAL NOT NULL DEFAULT 0,
    check_no   TEXT NOT NULL DEFAULT '',
    check_date TEXT,
    check_due  TEXT,
    check_amt  REAL NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS ix_colapp_col ON collection_applications(col_no);
CREATE INDEX IF NOT EXISTS ix_colapp_inv ON collection_applications(inv_no);

-- The stock movement ledger - the successor to STKREC.
CREATE TABLE IF NOT EXISTS stock_moves (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    move_type     TEXT NOT NULL,            -- SALE | PURCHASE | RETURN | ADJUST
    doc_no        TEXT NOT NULL DEFAULT '',
    doc_date      TEXT NOT NULL,
    stock_code    TEXT NOT NULL,
    description   TEXT NOT NULL DEFAULT '',
    qty           REAL NOT NULL DEFAULT 0,  -- signed: negative leaves the warehouse
    unit          TEXT NOT NULL DEFAULT '',
    unit_cost     REAL NOT NULL DEFAULT 0,
    unit_price    REAL NOT NULL DEFAULT 0,
    line_total    REAL NOT NULL DEFAULT 0,
    customer_code TEXT NOT NULL DEFAULT '',
    supplier_code TEXT NOT NULL DEFAULT '',
    division      TEXT NOT NULL DEFAULT '',
    category      TEXT NOT NULL DEFAULT '',
    lot_no        TEXT NOT NULL DEFAULT '',
    expiry_date   TEXT,
    balance_after REAL,
    remarks       TEXT NOT NULL DEFAULT '',
    created_at    TEXT NOT NULL,
    created_by    TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS ix_moves_stock ON stock_moves(stock_code, doc_date DESC);
CREATE INDEX IF NOT EXISTS ix_moves_doc   ON stock_moves(doc_no);
CREATE INDEX IF NOT EXISTS ix_moves_date  ON stock_moves(doc_date DESC);
CREATE INDEX IF NOT EXISTS ix_moves_type  ON stock_moves(move_type, doc_date DESC);
