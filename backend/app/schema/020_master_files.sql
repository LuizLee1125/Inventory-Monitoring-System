-- ------------------------------------------------------------ master files --
-- The records everything else points at: what we sell, who we buy it from, and
-- who we sell it to.

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
