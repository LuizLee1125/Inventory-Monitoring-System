-- ---------------------------------------------------------------- security --
-- Accounts, live sign-ins, the change history, and the two small tables the
-- rest of the system leans on: document numbering and configuration.

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
