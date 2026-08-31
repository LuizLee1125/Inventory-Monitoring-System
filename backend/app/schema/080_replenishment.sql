-- ---------------------------------------------------------- replenishment --
-- What was sold that was not on the shelf, and therefore has to be bought.
--
-- The case this exists for: an item shows 100 on hand. One clerk invoices 80
-- and saves. A second clerk, looking at a screen fetched before that save,
-- invoices 50. The second invoice is *allowed to go through* — for anything the
-- office can reorder quickly, a sale is worth more than a tidy stock figure, and
-- refusing it would turn a delivery delay into a lost customer.
--
-- But it must not go through silently. The 30 that were promised and do not
-- exist are a job for whoever buys, and one row here is that job: what was
-- wanted, what there was, what is owed, and whether it has been covered since.
--
-- The alternative — reading it back off `stock.qty_on_hand` being negative — was
-- rejected. A negative balance says only that *something* went short, not which
-- document did it, not for how much, and it is erased by the very next receipt,
-- taking the evidence with it.

CREATE TABLE IF NOT EXISTS stock_shortfalls (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Which document created the obligation. 'INVOICE' today; the column exists
    -- because a sales order or a delivery receipt could do the same thing later,
    -- and a table called stock_shortfalls should not have to be renamed for it.
    doc_type      TEXT    NOT NULL DEFAULT 'INVOICE',
    doc_no        TEXT    NOT NULL,
    doc_date      TEXT    NOT NULL,

    stock_code    TEXT    NOT NULL,
    description   TEXT    NOT NULL DEFAULT '',
    unit          TEXT    NOT NULL DEFAULT '',

    -- The three numbers, kept separately rather than derived from each other.
    -- `qty_available` is what the shelf held at the moment of the save, which is
    -- the number nobody can reconstruct afterwards and the one the buyer asks
    -- about first: "how far under were we?"
    qty_requested REAL    NOT NULL DEFAULT 0,
    qty_available REAL    NOT NULL DEFAULT 0,
    qty_short     REAL    NOT NULL DEFAULT 0,
    on_hand_after REAL    NOT NULL DEFAULT 0,

    -- Who sold it, so the buyer can ask. Not a blame column: the clerk was
    -- looking at a screen that was correct when it was drawn.
    customer_code TEXT    NOT NULL DEFAULT '',
    created_at    TEXT    NOT NULL,
    created_by    TEXT    NOT NULL DEFAULT '',

    -- Closed, never deleted, for the same reason `notifications.resolved_at` is:
    -- an item that ran short in March and again in June is two events and should
    -- read as two. Stamped when a purchase brings the item back to zero or
    -- above, or when the invoice behind it is cancelled.
    resolved_at   TEXT,
    resolved_by   TEXT    NOT NULL DEFAULT ''
);

-- No REFERENCES on `stock_code` or `doc_no`. The schema folder's rule is that a
-- foreign key never crosses a part file (see 000_conventions.sql and
-- system_architecture.md): `stock` is declared in 020 and `invoices` in 030, so
-- either key would work today and break the day somebody reorders the folder.
-- The same trade `notification_reads.user_id` makes.

-- The report and the sweep both ask "what is still open, newest first", and the
-- resolve path asks "what is open for these codes".
CREATE INDEX IF NOT EXISTS ix_shortfall_open
    ON stock_shortfalls(resolved_at, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_shortfall_code ON stock_shortfalls(stock_code);
CREATE INDEX IF NOT EXISTS ix_shortfall_doc  ON stock_shortfalls(doc_type, doc_no);
