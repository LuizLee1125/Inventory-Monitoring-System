-- ------------------------------------------------------------------ sales --
-- What goes out and what comes back: invoices, sales returns, and the payments
-- that settle them.

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

    -- How many lines took more than was on the shelf. Zero for almost every
    -- invoice; non-zero is the flag the detail screen reads to say "this
    -- document is waiting on a delivery", without joining to stock_shortfalls
    -- for every row of the invoice list.
    short_lines   INTEGER NOT NULL DEFAULT 0,

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
    expiry_date TEXT,

    -- How much of this line was sold from stock that was not there. The line is
    -- still worth its full amount and the customer is still owed the full
    -- quantity; this is the part of it that has to be delivered from the next
    -- purchase. Kept on the line rather than only in stock_shortfalls so the
    -- printed document and the detail screen can mark it without a join.
    qty_short   REAL    NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS ix_invline_inv   ON invoice_lines(inv_no);
CREATE INDEX IF NOT EXISTS ix_invline_stock ON invoice_lines(stock_code);

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
