-- ----------------------------------------------------------------- ledger --
-- The stock movement ledger - the successor to STKREC, the 658 MB .DBF that
-- was the largest file in the legacy system. Every document that touches an
-- item writes a signed row here; `stock.qty_on_hand` is the running total.

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
