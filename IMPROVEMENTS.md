# Improvement Plan

What to fix, add, refine and polish — in the order it should be done.

Companion to [SECURITY-AUDIT.md](SECURITY-AUDIT.md). Security work leads: the audit's findings
occupy P0 and P1, and nothing below them should jump the queue. Everything after that is ordered by
what protects the business next — correctness of the money, then the ability to find out what
happened, then the experience of using it.

**Baseline** commit `659eb95` · ~15,800 lines across `backend/app`, `frontend/js`,
`desktop/src-tauri/src`, `desktop/ui`.

**Effort key** `XS` under 30 min · `S` 1–2 h · `M` half a day · `L` several days.

---

## Priority board

| P | Item | Effort | Source |
|---|------|--------|--------|
| **P0** | 1. Server-side `must_change_password` gate | XS | Audit #6 |
| **P0** | 2. Hash session tokens at rest | S | Audit #4 |
| **P0** | 3. Admin-only permission for restore / import | XS | Audit #3 |
| **P0** | 4. Reject non-positive collection applications | XS | Audit #7 |
| **P1** | 5. Login throttling + constant-time miss | S | Audit #5 |
| **P1** | 6. Fix blank-legacy-password → username in `migrate.py` | XS | Audit #5 |
| **P1** | 7. Installer integrity check + origin-check `on_navigation` | M | Audit #1 |
| **P1** | 8. TLS on the LAN, `secure` cookie | M | Audit #2 |
| **P1** | 9. Close SSE streams when the session dies | S | Audit #8 |
| **P1** | 10. Bound prices and discounts | XS | Audit #9 |
| **P2** | 11. A test suite — starting with the money | L | — |
| **P2** | 12. Real logging, to a file that survives the window closing | M | — |
| **P2** | 13. Global exception handler | S | — |
| **P2** | 14. Restore drill, automated | M | — |
| **P2** | 15. Ledger reconciliation check | M | — |
| **P2** | 16. CI that runs ruff, eslint and the tests | S | — |
| **P3** | 17. Lock down `/api/docs`, add security headers | XS | Audit #10, #13 |
| **P3** | 18. Zip-bomb guard on import | XS | Audit #12 |
| **P3** | 19. Accessibility: modal focus trap, live-region toasts | M | — |
| **P3** | 20. Index `audit_log(username)` and `(action)` | XS | — |
| **P3** | 21. Document-number allocation: drop or gate the override | S | Audit #9 |
| **P3** | 22. Operational polish (health endpoint, backup alert routing) | S | — |

**P0 is the afternoon's work.** Items 1–4 together are roughly 30 lines and close both
privilege-escalation paths, the standing default-credential exposure, and the ledger bug.

---

## P0 — do first

### 1. Enforce `must_change_password` on the server

`backend/app/deps.py:31`. Today the forced-change modal exists only in
`frontend/js/app.js:483`; the API never checks the flag, so `ADMIN` / `changeme` and every migrated
account still holding its legacy password work indefinitely against `curl`.

In `current_user`, after resolving the session, reject with 403 when the flag is set — allowlisting
only the three routes needed to get out of the state:

```python
ALLOWED_WHILE_LOCKED = {"/api/me", "/api/logout", "/api/change-password"}

def current_user(request: Request) -> dict:
    ...
    if user["must_change_password"] and request.url.path not in ALLOWED_WHILE_LOCKED:
        raise HTTPException(403, "Set a new password before using the system.")
    return user
```

The frontend already handles this shape — `api.js:49` surfaces the detail, and the modal is already
raised from `/api/me`. Check that the 403 does not trigger the unauthorized listeners.

**Effort** XS · **Blast radius** every route · **Test** sign in as a `must_change_password` account,
confirm `GET /api/stock` returns 403 and `POST /api/change-password` still works.

### 2. Store a hash of the session token, not the token

`backend/app/security.py:161-213`, `backend/app/schema/010_security.sql:19`. Backups are full copies
of the database, so today every backup contains every live session token in plaintext — and any
`maintenance:run` holder can download one.

The token already carries 256 bits of entropy, so no work factor is needed; a bare SHA-256 is
enough. `create_session` returns the plaintext to the caller and stores `sha256(token).hexdigest()`;
`resolve_session` and `destroy_session` hash the incoming cookie before the lookup.

Existing sessions cannot be migrated — they will simply stop resolving, which signs everyone out
once. Do this at the end of a day, or pair it with a note on the sign-in screen.

**Effort** S · **Test** sign in, confirm the `sessions` row no longer matches the cookie value, and
that the cookie still authenticates.

### 3. Put restore and import behind an admin-only permission

`backend/app/security.py:68-119`, `backend/app/routers/maintenance.py:628,749`. `manager` holds
`maintenance:run`, which today includes replacing the entire database — `users` table and all — from
a file they uploaded themselves.

Add `maintenance:restore` to `PERMISSIONS`, grant it to `admin` only, and change the two endpoints'
dependencies. `manager` keeps backup, check, compact, purge and retention, which is what the role is
actually for.

Consider also preserving the live `users` and `sessions` rows across a restore, so the operation can
never be a route to an account even for an administrator who should not have one.

**Effort** XS · **Test** sign in as `manager`, confirm 403 on `POST /api/maintenance/restore` and
200 on `POST /api/maintenance/backup`.

### 4. Reject non-positive collection applications

`backend/app/routers/collections.py:121-127`. The guard sums the requested applications *including*
negatives, and the posting loop then skips them (`:150`), so `amount: 100` with
`[{A: 5000}, {B: -4900}]` writes 5,000 off invoice A while reducing the customer balance by 100.

Validate before the sum, not during the loop:

```python
targets = [...]
if any(amount <= 0 for _, amount in targets):
    raise HTTPException(400, "Every applied amount must be positive.")
if round(sum(a for _, a in targets), 2) > net + 0.005:
    raise HTTPException(400, "The amounts applied exceed the payment total.")
```

Then drop the now-dead `if apply_amount <= 0: continue` at `:150`, and add an assertion that
`applied_total <= net` after the loop as a second gate.

While here: check `returns.py` for the same shape. The refund path applies amounts the same way.

**Effort** XS · **Test** the payload above should 400; a normal split payment across two invoices
should still post.

---

## P1 — this sprint

### 5. Login throttling and a constant-time miss

`backend/app/routers/auth.py:13`. No rate limit, no lockout, no backoff anywhere in the codebase.
PBKDF2 at 260,000 rounds throttles an attacker, but not enough when the password may be the
username (see item 6).

Two changes, one table:

- A `login_attempts(username, ip, at, ok)` table, swept on the housekeeping tick that already runs
  in `main.py:64`. After five failures for a username *or* an IP inside fifteen minutes, refuse with
  429 and a retry-after. Persisted rather than in-memory so a restart is not a reset.
- Run PBKDF2 against a fixed dummy hash when the user is not found. Today a missing user returns in
  microseconds and a real one takes ~100 ms, which reopens the enumeration the identical error
  message was written to close (`auth.py:24`).

Surface the lockout on the sign-in screen in the system's own voice — "Too many attempts. Try again
in a few minutes, or ask an administrator to reset the password."

**Effort** S

### 6. Stop `migrate.py` turning a blank legacy password into the username

`backend/migrate.py:729`:

```python
"password": S(rec.get("PASSWORD")) or username,
```

A PASSFYL row with an empty password field becomes an account whose password *is* the person's
name — and names are on the admin screen and in every audit row. Write an unusable hash instead
(a sentinel such as `"!"` fails `verify_password` cleanly — `security.py:52-61` catches the unpack) and print the affected
usernames at the end of the migration so an administrator sets them deliberately.

An account nobody can sign into is a better failure than one anybody can.

**Effort** XS · Also worth a one-off script to find any such account already in the live database.

### 7. Verify the installer before executing it

`desktop/src-tauri/src/lib.rs:544,642`. The shell downloads an `.exe` over plain HTTP and spawns it
with no integrity check, and `on_navigation` fires that path on any navigation to `/__ims-update`
without checking the origin — so the remote page can trigger it unprompted.

Smallest change that closes the on-path case: publish a SHA-256 on `/api/desktop`
(`backend/app/routers/desktop.py:88`, one line in `_describe`) and verify it after the download,
before the rename, in `run_installer`. Refuse and report on a mismatch.

Then, independently of the hash:

- Restrict `on_navigation` to navigations whose origin matches the URL the shell itself opened.
- Raise the confirmation from the shell, not the page — a native dialog naming the version and the
  server, so the install is always a decision somebody made.

Proper signing (a minisign keypair, public half compiled in) is the right end state and closes the
compromised-host case too. The comment at `lib.rs:534` argues against it on the grounds that a bad
server could serve a bad application anyway; that reasoning holds for a sandboxed webview and not
for a native binary, and is worth revisiting in the code as well as in the behaviour.

**Effort** M

### 8. TLS on the office LAN

`backend/app/config.py:100`, `start.bat:94`, `backend/app/routers/auth.py:38`. Everything is
cleartext today, including the login POST body. A self-signed certificate generated once and
installed into the workstations' trust store is unglamorous and is a large improvement over nothing:

- Generate on first run, store beside the database, print the fingerprint on the console so it can
  be checked over the phone.
- `uvicorn --ssl-keyfile --ssl-certfile`, driven from `start.bat`.
- Then `secure=True` on the session cookie, and consider `samesite="strict"`.
- The Tauri shell needs `ureq`'s TLS feature re-enabled (`desktop/src-tauri/Cargo.toml` currently
  sets `default-features = false` deliberately) and its own trust decision.

Keep an HTTP listener that redirects, or the office loses its bookmarks on the day this ships.

**Effort** M · The largest piece here is the workstation trust rollout, not the code.

### 9. Close a live stream when its session ends

`backend/app/events.py:203`, `backend/app/routers/events.py:64`. `Subscriber` freezes the permission
set at subscribe time and nothing re-checks it, so **deactivating a user does not close their open
stream** — `admin.py:86` deletes their sessions, which correctly blocks new requests, while the SSE
connection keeps delivering live business events until the client disconnects.

The generator already wakes every `KEEPALIVE_SECONDS` to emit a comment frame (`routers/events.py:89`).
Re-resolve the session there — one indexed lookup per stream per tick — and return from the
generator when it is gone, or refresh `subscriber.permissions` when the role changed.

**Effort** S · **Test** open a stream, deactivate the account from another session, confirm the
stream closes within one keep-alive.

### 10. Bound prices and discounts

`backend/app/routers/invoices.py:196,35`. `money()` constrains neither sign nor magnitude, so a
negative `unit_price` is accepted and produces a negative line total; `discounted()` is unbounded, so
`disc1: 200` flips the sign too.

Overriding a price is plainly intentional and should stay. Entering a negative one is not:

- Reject `unit_price < 0` per line, naming the line number the way the existing quantity check does
  at `invoices.py:169`.
- Clamp or reject discounts outside `0..100`, at both line and document level.
- Same pass over `purchases.py` and `returns.py`.

**Effort** XS

---

## P2 — the structural gaps

### 11. A test suite, starting with the money

**There are no automated tests.** No `test_*.py`, no `conftest.py`, no `*.test.js`, no CI. This is
the single largest engineering risk in the project: ~15,800 lines running a real business's
receivables, with hand-rolled arithmetic over 84,781 invoices and 365,780 payments, and nothing that
would catch a regression.

The audit's finding #7 is the argument in miniature — a bug that lets a 100-peso payment clear 5,000
of receivable, sitting in plain sight in a well-commented function. A dozen tests over `collections`
would have caught it the day it was written.

Start where the money is, not where the coverage is easy:

1. **`pytest` + a fixture that builds a temp database from `schema/*.sql`.** `db.reference_schema()`
   already does most of this (`db.py:111`) — the same trick against a file gives every test a clean
   database in milliseconds.
2. **Invoice posting** — line totals, successive discounts, cost capture, the oversell path and the
   `allow_oversell` refusal, the same-code-twice case the comment at `invoices.py:161` describes.
3. **Collections** — split application, over-application, the negative case from item 4, the
   customer-balance and invoice-balance arithmetic agreeing afterwards.
4. **Returns and purchases** — the mirrored paths.
5. **Permissions** — a parametrised test asserting each role's access to a representative endpoint
   per permission. This is cheap and it is what makes changes to `security.ROLES` safe.
6. **Backup, import, restore** — see item 14.

Target the business logic, not the framework. Aim for confidence in `invoices`, `collections`,
`returns`, `purchases`, `stock` and `security`; the rest can follow.

**Effort** L · This is the item that makes every later item safe.

### 12. Logging that survives the console window closing

`main.py` and `maintenance.py` write operational events with `print()` — 19 calls across the
codebase, no `logging` import anywhere. The server runs in a console window in an office, and that
window gets closed. When something goes wrong at 11am, there is nothing to read at 2pm.

The `audit_log` table covers *business* actions well. It does not cover: failed sign-ins, unhandled
exceptions, backup failures, restore attempts, stream churn, or anything the server said before it
died.

- `logging` with a `RotatingFileHandler` into a `logs/` folder beside `backups/`, git-ignored,
  seven days deep. Keep the console output — the banner in `lifespan()` is genuinely useful and
  should stay exactly as it reads.
- One line per request at WARNING and above, plus every 4xx on `/api/login` and every 5xx anywhere.
- Never log a password, a session token, or a cookie header.

**Effort** M

### 13. A global exception handler

`main.py:186` registers a 404 handler and nothing else. An unhandled exception anywhere becomes
FastAPI's default 500 with no correlation to anything — the traceback goes to a console nobody is
reading (item 12), and the clerk sees a bare failure.

Add a handler that logs the traceback with a short reference code and returns that code to the
client: "Something went wrong (ref 7F2A). Tell whoever looks after this system." Then the phone call
starts with a searchable string instead of "it broke".

**Effort** S · Pairs naturally with item 12.

### 14. Automate the restore drill

`maintenance.py:749` is the disaster-recovery story for a 1.2 GB database holding 25 years of
records, and it has never been exercised by anything but a person. A backup that cannot be restored
is not a backup, and the office finds that out on the worst possible day.

- A test that takes a backup, restores it into a temp database, and asserts row counts match.
- A `--verify` mode on the maintenance screen: restore the newest backup into a scratch file, run
  `PRAGMA integrity_check` and count the tables, then throw the scratch away. Report on the screen.
  `inspect_backup` (`maintenance.py:473`) already does most of the work; this is wiring it to a
  button and a schedule.
- Run it on the housekeeping tick, monthly, and raise a notification through the existing
  `notifications.raise_alert` path (`maintenance.py:336` shows the shape) if it fails.

**Effort** M

### 15. A reconciliation check for the ledger

Money is stored as SQLite `REAL` — IEEE 754 doubles (`schema/030_sales.sql:23-27`, and throughout).
Every write goes through `round(x, 2)`, which keeps individual values honest, but balances are
maintained *incrementally* — `balance = ROUND(balance - ?, 2)` (`collections.py:185`) — so an error
never self-corrects, it accumulates. Finding #7 is an existence proof that the two sides can
diverge for reasons other than floating point.

Migrating to integer minor units is the textbook answer and is a large, risky change across 67
migrated tables. The cheaper and more valuable move first is to **detect** divergence:

- A `GET /api/maintenance/reconcile` that recomputes every customer balance from its invoices and
  collections — `migrate.py:685` already has this query, in `rebuild_balances` — and reports rows
  that disagree with the stored value beyond half a centavo. Same for supplier balances and for
  `invoices.balance` against `collection_applications`.
- Run it on the monthly tick alongside item 14 and raise an alert on any mismatch.

If that report is persistently clean, the `REAL` storage is fine and the migration is not worth its
risk. If it is not clean, it will say exactly which rows and how far, which is the input any fix
needs anyway.

**Effort** M

### 16. CI

`ruff` is configured (`backend/pyproject.toml`, a considered rule set with per-file ignores) and
`eslint` is configured (`eslint.config.mjs`, likewise) — and nothing runs either automatically. A
lint config that only runs when somebody remembers is a lint config that drifts.

A single GitHub Actions workflow: `ruff check backend`, `npm run lint`, and the tests from item 11.
Under 40 lines, and it turns both existing configs from documentation into enforcement.

**Effort** S

---

## P3 — polish and hardening

### 17. Close the incidental exposure
- `main.py:157` — set `docs_url` and `openapi_url` to `None` when not in development, or guard them
  with `Depends(current_user)`. Today the full API surface is published to anyone who reaches the
  port. **XS**
- `main.py:167` — the middleware sets only `Cache-Control`. Add `X-Content-Type-Options: nosniff`,
  `X-Frame-Options: DENY` (or a `frame-ancestors` CSP), and `Referrer-Policy: same-origin`. Low
  urgency because there is no injection sink today (the frontend has none — see the audit's verified
  section) and high value as the thing that catches a future regression. **XS**

### 18. Guard the import against a zip bomb
`maintenance.py:454`. `extract_backup` expands a member with no size cap while the upload guard at
`:664` bounds only the compressed stream. Check `ZipInfo.file_size` against `_disk_free_mb` before
extracting, and refuse with the same 507 the rest of the file uses. **XS**

### 19. Accessibility
The frontend builds clean semantic DOM and handles Escape on the modal (`ui.js:161`), which is a
good start. Missing:
- **Modal**: no `role="dialog"`, no `aria-modal`, no focus trap, no focus restore on close. Tab
  currently walks out of the dialog and into the page behind it. The forced password-change modal
  (`app.js:483`) is the one dialog a user cannot dismiss, which makes it the worst one to be able to
  tab out of.
- **Toasts**: no `role="status"` or `aria-live`, so "Saved" and "Password changed" are never
  announced. A one-attribute fix.
- **Omni search** (`omni.js`): a listbox pattern without `role="listbox"` / `aria-activedescendant`,
  so the arrow-key selection is invisible to a screen reader.
- Check contrast on the `.tag` status colours in both themes.

**Effort** M · Worth doing as one pass rather than piecemeal.

### 20. Index the audit filters
`schema/010_security.sql:38-39` indexes `at` and `(entity, entity_id)`. The admin audit screen also
filters on `username` and `action` (`admin.py:131-139`), neither of which is indexed — a full scan
of a table that only ever grows. Two `CREATE INDEX IF NOT EXISTS` lines in a new schema part; the
reconciliation in `init_db()` picks them up on the next start. **XS**

### 21. Decide about caller-supplied document numbers
`collections.py:115` and the equivalent on invoices accept a caller-chosen `col_no` / `inv_no`,
bypassing `next_document_number` and the collision guarantee its transaction provides
(`db.py:236`). The uniqueness check that follows prevents an overwrite but not an out-of-band
number.

If this exists for back-dated entry, gate it on a permission and audit it distinctly. If it is
vestigial, drop the payload field. Either is better than the current ambiguity. **S**

### 22. Operational polish
- **A real health endpoint.** `/api/meta` doubles as one today — it is what the Tauri shell probes
  (`lib.rs:269`) — but it says nothing about the database. A `/api/health` returning database
  reachability, WAL mode, free disk and last-backup age gives the office one URL to check, and gives
  the shell a better identity test than "the response contains the word version".
- **Route the backup-failed alert somewhere it will be seen.** `maintenance.py:336` raises it to
  `maintenance:run` holders, which is right — but if nobody signs in for a fortnight, nobody sees it.
  Consider surfacing last-backup age on the sign-in screen when it exceeds the interval; it is the
  one screen everybody reaches.
- **`releases/` has no checksum manifest.** Item 7 needs one anyway; publishing it also makes a
  hand-copied installer verifiable.

**Effort** S

---

## Not recommended

Things worth naming so they do not get picked up by mistake.

- **Rewriting money as integer minor units.** The textbook fix, and across 67 migrated tables and
  2.5 million stock movements it is a large migration with real risk. Do item 15 first; let the
  reconciliation report say whether this is needed.
- **Replacing SQLite.** WAL mode with `BEGIN IMMEDIATE` (`db.py:62-75`) is genuinely the right shape
  for a dozen concurrent clerks, and the reasoning in the module docstring is sound. A database
  server would add an operational burden this office cannot carry and solve nothing it has.
- **Adding a frontend build step.** The no-build, no-dependencies choice is deliberate, documented,
  and is why the frontend has no supply chain to audit. The `el()` helper is doing the job.
- **Bulk-adding tests for coverage's sake.** Item 11 is deliberately scoped to the money and the
  permissions. Tests over the router plumbing would raise a number and catch nothing.

---

## Suggested sequence

**This afternoon** — items 1, 3, 4, 10, 17, 18, 20. All XS, all independent, roughly 60 lines
between them. Closes both privilege-escalation paths, the ledger bug, and the incidental exposure.

**This week** — items 2, 5, 6, 9. The session-token change (2) signs everyone out once, so land it
at the end of a day.

**Next** — item 11, the test suite. Everything after it is safer for existing, and items 14 and 15
are partly tests anyway.

**Then** — 7 and 8 together. The installer and TLS are one conversation about the network, and the
Tauri TLS change (8) is a prerequisite for doing 7 properly rather than with a hash alone.

**Ongoing** — 12, 13, 16 as the operational floor; 19 and 22 as polish.
