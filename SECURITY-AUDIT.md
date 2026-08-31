# Security Audit — Inventory Monitoring System

**Scope** `backend/app/**` (15 routers, security, db, events, notifications), `backend/migrate.py`,
`backend/reset_password.py`, `backend/dump_db.py`, `frontend/js/**`, `desktop/src-tauri/**`,
`start.bat`, schema parts, `.gitignore`.
**Excluded** `backend/.venv/`, `node_modules/`, `desktop/src-tauri/target/`, `legacy/*.DBF`.

**Commit** `659eb95` · **Branch** `main` · **Date** 2026-09-01

**Deployment assumed** single office PC serving `0.0.0.0:8080` over plain HTTP to counter PCs on a
LAN, plus a Tauri desktop shell that either hosts that server or connects to one.

---

## Summary

The application layer is in good shape. Every request-borne value reaches SQLite through a bound
parameter, every interpolated SQL identifier comes from a server-side allowlist, the frontend has no
HTML injection sink at all, and only four endpoints are reachable without a session — three of them
deliberately.

The exposure is concentrated in two places: **the desktop update channel**, which downloads and
executes an unsigned binary fetched over plain HTTP from a host the user types in, and **the
maintenance permission**, which lets a non-administrator read and replace the entire database —
including the `users` and `sessions` tables — and so reach `admin` two different ways.

| # | Finding | Severity | Where |
|---|---------|----------|-------|
| 1 | Unsigned installer over HTTP, auto-executed → RCE on desktop clients | **Critical** | `desktop/src-tauri/src/lib.rs:544` |
| 2 | All traffic cleartext, including passwords and session cookies | **Critical** | `backend/app/config.py:100`, `backend/app/routers/auth.py:38` |
| 3 | `manager` → `admin` via backup import + restore | **High** | `backend/app/routers/maintenance.py:628,749` |
| 4 | `manager` → `admin` via backup download (plaintext session tokens) | **High** | `backend/app/routers/maintenance.py:554` |
| 5 | No brute-force protection, against known-weak migrated passwords | **High** | `backend/app/routers/auth.py:13` |
| 6 | `must_change_password` enforced only in the browser | **High** | `backend/app/deps.py:31` |
| 7 | Collection over-application desynchronizes the ledger | **Medium** | `backend/app/routers/collections.py:124` |
| 8 | Live SSE streams hold a stale permission snapshot | **Medium** | `backend/app/events.py:203` |
| 9 | Client-supplied prices, discounts and document numbers unvalidated | **Medium** | `backend/app/routers/invoices.py:196` |
| 10 | Interactive API docs public | **Low** | `backend/app/main.py:157` |
| 11 | Unauthenticated installer distribution | **Low** | `backend/app/routers/desktop.py:101` |
| 12 | No decompression limit on backup import | **Low** | `backend/app/routers/maintenance.py:454` |
| 13 | No security response headers on the browser app | **Low** | `backend/app/main.py:167` |

---

## Critical

### 1. Unsigned installer downloaded over plain HTTP and executed → RCE on every desktop client

**Where** `desktop/src-tauri/src/lib.rs:544` (`run_installer`), reached from
`lib.rs:641` (`on_navigation`) and `lib.rs:813` (`install_update`).

`run_installer` fetches `{base}/api/desktop/download`, writes it to the temp directory, and runs it:

```rust
// lib.rs:582
Command::new(&target)
    .spawn()
    .map_err(|e| format!("Could not start the installer: {e}"))?;
```

There is no signature check, no hash check, and no TLS — `ureq` is built with
`default-features = false` (`desktop/src-tauri/Cargo.toml`), which excludes the TLS stack entirely,
so `base` is always an `http://` origin. `base` is whatever the user typed on the launcher in client
mode (`lib.rs:836`), normalized but not otherwise constrained.

Three ways in, in rising order of how little the attacker needs:

1. **Typed address.** A clerk is told "the server moved, use 192.168.1.99". The rogue host answers
   `/api/meta` with anything containing `"app"` and `"version"` (`lib.rs:269` — that is the whole
   identity check), reports a higher version on `/api/desktop`, and serves a payload on
   `/api/desktop/download`.
2. **On-path attacker.** ARP spoofing or a rogue DHCP/DNS entry on the office LAN. Plain HTTP means
   nothing detects the substitution.
3. **No user gesture at all.** The main window loads a *remote* page, and `on_navigation`
   (`lib.rs:642`) fires `run_installer` on any navigation whose path is `/__ims-update`, without
   checking the origin. A malicious or compromised server therefore triggers the download-and-execute
   itself by navigating its own page there.

`/api/desktop/download` requires no session (`backend/app/routers/desktop.py:120`), so the rogue
server needs no credentials to stage the payload.

The code comment at `lib.rs:534` argues the threat model does not need signing because "a server that
could hand over a bad installer could hand over a bad application first". That holds for the *web*
application, which is sandboxed in a webview. It does not hold for a native `.exe` spawned outside
the sandbox: the two have very different blast radii, and case 3 turns a compromised page into
native code execution.

**Fix** In order of value:
- Sign the installer and verify before spawning. A pinned public key compiled into the shell is
  enough; the private half never has to leave the build machine.
- At minimum, publish a hash on `/api/desktop` and verify it after download — this closes the on-path
  case even without signing.
- Restrict `on_navigation` to same-origin navigations from the URL the shell itself opened, and
  require a confirmation dialog raised by the shell (not the page) before any install.
- Move the whole channel to HTTPS; that requires re-enabling `ureq`'s TLS feature.

---

### 2. All traffic is cleartext, including passwords and session cookies

**Where** `backend/app/config.py:100`, `start.bat:94`, `desktop/src-tauri/src/lib.rs:371`,
`backend/app/routers/auth.py:38`.

The server binds `0.0.0.0:8080` over HTTP and the session cookie is set without `secure`:

```python
# auth.py:38
response.set_cookie(
    config.SESSION_COOKIE, token,
    max_age=config.SESSION_HOURS * 3600,
    httponly=True, samesite="lax", path="/",
)
```

`httponly` and `samesite="lax"` are both correct choices and Lax does cover this app's CSRF surface
(every state-changing route is POST/PUT/DELETE, and there is no CORS middleware). But on plain HTTP
the protections are moot for anyone with a packet capture: the `POST /api/login` body carries the
password in the clear, and every subsequent request carries the session token in the clear. Office
Wi-Fi, an unmanaged switch, or a second machine running `tcpdump` is the whole attack.

This also underpins finding 1 — the update channel is unauthenticated *and* unencrypted.

**Fix** Terminate TLS in front of uvicorn, or run uvicorn with a certificate. A self-signed cert
installed once into the workstations' trust store is workable for a fixed office LAN and is a large
improvement over nothing. Then add `secure=True` to the cookie and consider `samesite="strict"`.

---

## High

### 3. `manager` reaches `admin` by importing and restoring a crafted database

**Where** `backend/app/routers/maintenance.py:628` (`import_backup`), `:749` (`restore`).
`maintenance:run` is held by `manager` as well as `admin` (`backend/app/security.py:92`).

`restore` replaces the *entire* database, `users` table included, from a file the same user just
uploaded. The upload's validation (`_inspect_database`, `maintenance.py:485`) checks three things:
the file opens, `PRAGMA integrity_check` returns `ok`, and every table name the current schema
declares is present. None of that constrains the *contents*.

Attack, from a `manager` account:

1. Build a SQLite file with the expected table names, an empty schema otherwise, and one row in
   `users` with `role = 'admin'` and a known password hash.
2. `POST /api/maintenance/backups/import` — passes inspection.
3. `POST /api/maintenance/restore` with `{"confirm": "RESTORE", "name": "..."}`.

The typed `RESTORE` confirmation (`maintenance.py:766`) is a UI speed bump against mistakes, not an
authorization control — it is a constant in a JSON body. The restore then clears all sessions
(`maintenance.py:809`), which is noisy, but the attacker signs back in as their new admin.

Note the same primitive also destroys all business data, which a `manager` should arguably not be
able to do unilaterally either.

**Fix** Move `restore` (and ideally `backups/import`) behind a dedicated permission held only by
`admin` — e.g. `maintenance:restore` — leaving `manager` with backup, check, compact and purge.
Additionally, preserve the live `users` and `sessions` tables across a restore, or re-apply the
current `users` rows afterwards, so a restore cannot be a route to an account.

---

### 4. `manager` reaches `admin` by downloading a backup and replaying a session token

**Where** `backend/app/routers/maintenance.py:554` (`download_backup`),
`backend/app/schema/010_security.sql:19`.

`sessions.token` is stored verbatim:

```sql
CREATE TABLE IF NOT EXISTS sessions (
    token      TEXT PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ...
```

A backup is a byte-for-byte copy of the database, so it contains every live session token. Any
`maintenance:run` holder can download one, open it locally, and read an administrator's token
straight out of `sessions` — then set `ims_session` to that value and act as the administrator until
it expires (up to 12 hours, `config.py:96`).

The project already knows this is dangerous: `dump_db.py` skips the `sessions` table entirely and
calls its rows "live credentials" in the module docstring. The backup path has no equivalent.

**Fix** Store a hash of the token, not the token — `sha256(token)` is sufficient here since the token
is already 256 bits of entropy, so no work factor is needed. `create_session` returns the plaintext to
the client and stores the digest; `resolve_session` hashes the cookie before looking it up. A stolen
backup then yields nothing replayable. This is a small, self-contained change to
`backend/app/security.py:161-213`.

---

### 5. No brute-force protection, against a password set that is known to be weak

**Where** `backend/app/routers/auth.py:13`. There is no rate limit, lockout, backoff, or CAPTCHA
anywhere in the codebase.

On its own this would be Medium — PBKDF2 at 260,000 rounds (`config.py:105`) throttles an online
attacker considerably. What raises it is what the passwords are:

- **Migrated accounts with a blank legacy password get their username as their password.**
  `backend/migrate.py:729`:
  ```python
  "password": S(rec.get("PASSWORD")) or username,
  ```
  Usernames are people's names, are shown on the admin screens and appear in every `audit_log` row.
  Guessing `username == password` is one request per account, not a search.
- **Migrated accounts also match on the upper-cased form.** `backend/app/security.py:47`:
  ```python
  if user_row["must_change_password"] and password != password.upper():
      return verify_password(password.upper(), stored)
  ```
  This is a faithful and well-documented reproduction of the DOS login screen's behaviour, but it
  makes those passwords case-insensitive, and DOS-era passwords are typically short.
- **The seeded administrator is `ADMIN` / `changeme`** (`migrate.py:736`, announced in
  `start.bat:50`) and, per finding 6, is fully usable without ever changing it.

The login handler correctly returns an identical message for unknown user and wrong password
(`auth.py:26`), so enumeration is closed. Timing is not equalized — a missing user skips PBKDF2
entirely and returns in microseconds where a real user takes ~100ms — which reopens enumeration to
anyone measuring.

**Fix**
- Per-account and per-IP throttling on `/api/login`: exponential backoff after ~5 failures, recorded
  in a small `login_attempts` table so it survives a restart.
- Run PBKDF2 against a dummy hash when the user is not found, so both paths cost the same.
- In `migrate.py`, when the legacy `PASSWORD` field is blank, write an unusable hash rather than the
  username and require an administrator to set the password. An account nobody can sign into is a
  better failure than an account anybody can.

---

### 6. `must_change_password` is enforced only in the browser

**Where** `frontend/js/app.js:483` (client), `backend/app/deps.py:31` and
`backend/app/security.py:175` (server).

The forced-change modal has no Cancel and is a genuine block *in the UI*. The server has no
equivalent: `current_user` resolves the session and returns it, and `resolve_session` carries
`must_change_password` in the row without ever acting on it. A session flagged for change has the
full permission set of its role on every endpoint.

So the seeded `ADMIN` / `changeme` account, and every migrated account still holding its legacy
password, is usable indefinitely against the API with `curl` — the modal is simply never rendered.
This converts finding 5 from "an attacker must guess a password that will soon be replaced" into
"an attacker must guess a password that will never be replaced".

**Fix** In `deps.current_user`, reject with 403 when `must_change_password` is set, allowlisting only
`/api/me`, `/api/logout` and `/api/change-password`. Roughly six lines.

---

## Medium

### 7. Collection over-application silently desynchronizes the ledger

**Where** `backend/app/routers/collections.py:124` (validation) and `:150` (posting).

The guard sums the requested applications including negative entries:

```python
# collections.py:124
if round(sum(a for _, a in targets), 2) > net + 0.005:
    raise HTTPException(400, "The amounts applied exceed the payment total.")
```

The posting loop then discards the negatives:

```python
# collections.py:150
for inv_no, apply_amount in targets:
    if apply_amount <= 0:
        continue
```

So a payload of `amount: 100` with `applications: [{"inv_no": "SI000123", "amount": 5000},
{"inv_no": "SI000124", "amount": -4900}]` passes the check (sum = 100), writes 5,000 off invoice
SI000123, skips the negative entry, and then reduces the customer's balance by `net` — 100
(`collections.py:185`). The receivable on the invoice and the receivable on the customer disagree by
4,900, with a POSTED collection and a clean audit entry standing behind it.

Available to any `collection:write` holder: `ar`, `manager`, `admin`.

**Fix** Reject the whole request when any requested application is `<= 0`, before the sum check.
Consider asserting `applied_total <= net` after the loop as a second gate.

### 8. Live event streams keep a stale permission snapshot

**Where** `backend/app/events.py:203` (`subscribe`), `backend/app/routers/events.py:64`.

`Subscriber` freezes `permissions` at subscribe time and the SSE generator holds that subscriber for
the life of the connection. Nothing re-checks the session. So:

- Demoting a user does not narrow their stream.
- **Deactivating a user does not close their stream.** `admin.py:86` deletes their sessions, which
  correctly blocks new requests, but the open connection keeps delivering live business events until
  the client disconnects or the server restarts.

The per-event permission filter itself (`events.py:101`, `wanted_by`) is correct; it is the snapshot
that goes stale.

**Fix** Re-resolve the session on each delivery, or on the keep-alive tick (every
`KEEPALIVE_SECONDS`), and terminate the generator when the session is gone or the permissions
changed. The keep-alive already runs on a timer, so this costs one indexed lookup per stream per
tick.

### 9. Client-supplied prices, discounts and document numbers are accepted unvalidated

**Where** `backend/app/routers/invoices.py:196`, `:35`, and `collections.py:115`.

```python
# invoices.py:196
unit_price = money(raw.get("unit_price")) or item[price_column]
```

`money()` (`deps.py:85`) rounds to two places and does not constrain sign or magnitude, so a negative
unit price is accepted and produces a negative line total. Discounts go through `discounted()`
(`invoices.py:35`) with no bound, so `disc1: 200` flips the sign as well. Letting a clerk override a
price is plainly intentional — letting them enter a negative one probably is not.

Separately, `col_no` (`collections.py:115`) and the equivalent on invoices accept a caller-chosen
document number, bypassing `next_document_number` and its collision guarantees. The uniqueness check
that follows prevents an overwrite, but not an out-of-band number.

**Fix** Reject `unit_price < 0` and discounts outside `0..100` at the line level. If document numbers
are meant to be caller-assignable (for back-dated entry), gate it on a permission; otherwise drop the
payload field and always allocate from the sequence.

---

## Low

### 10. Interactive API documentation is public
`backend/app/main.py:157` serves `/api/docs` and `/api/openapi.json` with no dependency. Anyone who
can reach the port gets the full endpoint surface, parameter names and schemas before signing in.
Set both to `None` in production, or guard them with `Depends(current_user)`.

### 11. Unauthenticated installer distribution
`backend/app/routers/desktop.py:101,120`. Deliberate and well-argued in the module docstring — the
reasoning that an installer carries no customer data is sound. Worth restating that it also
publishes the deployed version number to any unauthenticated caller, and that it is the payload
delivery path in finding 1.

### 12. No decompression limit on backup import
`backend/app/routers/maintenance.py:454`. `extract_backup` expands a zip member with no size cap; the
upload guard at `:664` bounds the *compressed* stream only. A zip bomb from a `maintenance:run`
holder fills the server disk. Check `ZipInfo.file_size` against free space before extracting.
(CPython's `ZipFile.extract` sanitizes member paths, so there is no Zip-Slip here.)

### 13. No security response headers on the browser application
`backend/app/main.py:167` sets only `Cache-Control`. Absent: `X-Content-Type-Options: nosniff`,
`X-Frame-Options` / `frame-ancestors`, and any CSP. The Tauri shell does define a CSP
(`desktop/src-tauri/tauri.conf.json:12`) but it applies to the local setup window, not to the remote
page the main window loads. Low today because there is no injection sink to exploit (see below) —
worth adding as defence in depth, particularly `nosniff` and a CSP that would catch a future
regression.

---

## Verified clean

These were checked specifically and found sound. Recording them so a later reviewer does not have to
re-derive the conclusion.

- **SQL injection — none.** Every request value is bound. Every interpolated identifier comes from a
  server-side allowlist: the `SORTABLE` dicts consumed via `.get(sort, default)`
  (`stock.py:13`, `customers.py:12`, `invoices.py`, `suppliers.py`, `purchases.py`, `returns.py`),
  `archive.KINDS` (`archive.py:21`), the fixed table tuples in `admin.py:152` and
  `maintenance.py:373`, and the `group_by`/`direction` mappings in `reports.py:176,296`. `direction`
  is normalized to a literal `ASC`/`DESC`. Confirmed across all 15 routers.
- **Cross-site scripting — no sink exists.** The frontend builds DOM through `el()`
  (`frontend/js/ui.js:8`) using `textContent` and `createTextNode`. The single `innerHTML` assignment
  (`ui.js:13`, the `html:` attribute) is never used anywhere in `frontend/`. No `eval`, no
  `new Function`, no `document.write`, no `insertAdjacentHTML`. This is a genuinely good property —
  keep the `html:` branch unused, or delete it.
- **Path traversal — none.** `_find_backup` (`maintenance.py:441`) matches a name against the
  directory listing instead of joining it to a path; `_import_name` (`maintenance.py:580`) reduces
  an uploaded filename to a basename over `[A-Za-z0-9._-]`; `_installer` (`desktop.py:60`) takes no
  input at all. All three carry comments explaining why, which is why they are right.
- **Unauthenticated endpoints — four, all intended.** `POST /api/login`, `POST /api/logout`,
  `GET /api/desktop`, `GET|HEAD /api/desktop/download`. Every other route carries
  `Depends(current_user)` or `Depends(require(...))`.
- **CSRF — adequately covered.** No CORS middleware, `SameSite=Lax`, and every mutating route is
  POST/PUT/DELETE, which Lax does not attach the cookie to cross-site. Revisit if a mutating GET is
  ever added.
- **Authorization filtering on notifications and events** (`notifications.py:392`, `events.py:101`)
  is correct, including the "ignore ids the user cannot see" behaviour in `mark_read`.
- **Optimistic locking** (`deps.check_version`) is applied consistently on updates, and the
  last-administrator guard (`admin.py:72`) is correct.
- **Secrets and data in git.** `.gitignore` correctly excludes `database/`, `backups/`, `releases/`,
  the legacy `.DBF`/`.IDX` files and `*.sqlite`. Nothing sensitive is tracked. `dump_db.py` redacts
  `users.password_hash` and skips `sessions` by default.
- **Password hashing.** PBKDF2-SHA256, 260,000 rounds, 128-bit salt, iteration count stored with the
  hash, compared with `hmac.compare_digest` (`security.py:22-61`). Correct.
- **Session tokens.** `secrets.token_urlsafe(32)` — 256 bits. Correct generation; see finding 4 for
  storage.

---

## Recommended order of work

1. **Finding 6** — server-side `must_change_password` gate. Smallest change, closes the standing
   default-credential exposure. (~6 lines, `deps.py`.)
2. **Finding 4** — hash session tokens at rest. Self-contained, kills the backup-to-admin path.
   (~15 lines, `security.py`.)
3. **Finding 3** — move `restore`/`import` behind an admin-only permission. (~5 lines,
   `security.py` + `maintenance.py`.)
4. **Finding 7** — reject non-positive collection applications. (~3 lines, `collections.py`.)
5. **Finding 5** — login throttling and constant-time miss; fix the blank-legacy-password rule in
   `migrate.py`.
6. **Finding 1** — hash or signature verification on the installer, and origin-check
   `on_navigation`. The largest piece of work and the one that needs a design decision about where
   the key lives.
7. **Finding 2** — TLS. Infrastructure rather than code, and the one that makes 1, 5 and the cookie
   flags meaningfully stronger.
8. Findings 8–13 as they fit.

Items 1–4 are together under an hour of work and remove both privilege-escalation paths and the
default-credential exposure.
