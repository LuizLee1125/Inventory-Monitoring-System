-- ------------------------------------------------------------- purchasing --
-- What comes in from suppliers. PURFYL never tracked what was paid, so the
-- payment columns here start life at zero for every migrated purchase; only
-- purchases raised in the web edition move them.

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
