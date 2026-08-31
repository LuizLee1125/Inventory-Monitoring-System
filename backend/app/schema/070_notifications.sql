-- ----------------------------------------------------------- notifications --
-- Conditions the office should know about that become true while nobody is
-- looking at the screen: an item at its reorder point, a lot about to expire, a
-- scheduled backup that failed. A toast cannot carry those — it lasts four
-- seconds and only exists if somebody happened to be on that page at that
-- moment — so they are raised by the server and stored here.

CREATE TABLE IF NOT EXISTS notifications (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    kind        TEXT    NOT NULL,                     -- 'stock.reorder', ...
    severity    TEXT    NOT NULL DEFAULT 'info',      -- info | warn | error
    title       TEXT    NOT NULL,
    body        TEXT    NOT NULL DEFAULT '',

    -- What it is about, so the row can link to the record. 'stock' + a code
    -- becomes #/stock/AMOX500 in the interface.
    entity      TEXT    NOT NULL DEFAULT '',
    entity_id   TEXT    NOT NULL DEFAULT '',

    -- Who may see it. A permission rather than a role: a sales clerk should not
    -- be told the backup failed, and expressing that as a permission means the
    -- answer follows the same matrix every endpoint already uses.
    permission  TEXT    NOT NULL DEFAULT 'report:read',

    -- The sweep runs every fifteen minutes over conditions that stay true for
    -- weeks. Without a UNIQUE key on 'kind:entity_id' a fortnight of one item
    -- sitting below its reorder point would be 1,344 identical rows.
    dedupe_key  TEXT    NOT NULL UNIQUE,

    raised_at   TEXT    NOT NULL,

    -- Closed, not deleted. The sweep stamps this when the condition no longer
    -- holds, which is what makes it safe for the same key to be raised again:
    -- restocking an item and then running it down again is two events and
    -- should read as two. It is also why the history survives being fixed.
    resolved_at TEXT
);

-- The badge asks for open rows newest-first on a timer, so that is the index.
CREATE INDEX IF NOT EXISTS ix_notifications_open
    ON notifications(resolved_at, raised_at DESC);
CREATE INDEX IF NOT EXISTS ix_notifications_kind ON notifications(kind);

-- Read state is per person: one raised condition, one row here per user who has
-- seen it. Absence means unread, so nothing has to be written when a
-- notification is created.
--
-- `user_id` deliberately carries no REFERENCES users(id). The schema folder's
-- rule is that a foreign key never crosses a part file, and `users` is declared
-- in 010_security.sql — a cross-file reference would work today and break the
-- day somebody reorders the folder. The cost is that deleting a user leaves
-- rows here; they are two integers, nothing joins back to `users`, and no read
-- is wrong because of them.
CREATE TABLE IF NOT EXISTS notification_reads (
    notification_id INTEGER NOT NULL
                    REFERENCES notifications(id) ON DELETE CASCADE,
    user_id         INTEGER NOT NULL,
    read_at         TEXT    NOT NULL,
    PRIMARY KEY (notification_id, user_id)
);
CREATE INDEX IF NOT EXISTS ix_notification_reads_user ON notification_reads(user_id);
