# Marina Trading — Inventory Monitoring System (Web Edition)

A multi-user inventory, invoicing and receivables system for a wholesale distribution business,
served over the office network and used from any browser.

It is a ground-up rebuild of a FoxPro/DOS application that ran the business from **1999 to 2024** —
same business rules, same 25 years of data, now a Python API with a JavaScript front end instead of
an 80×25 character grid. The original system and its architecture are documented in
[README-LEGACY.md](README-LEGACY.md).

```
Backend    Python 3.10+ · FastAPI · Uvicorn · SQLite (WAL)
Frontend   Vanilla JavaScript (ES modules) · HTML · CSS — no build step, no npm
Data       Migrated from 67 legacy .DBF tables: 1,735 customers, 2,137 stock items,
           84,781 invoices, 365,780 payments, 2.5 million stock movements
```

---

## At a glance

- **Runs on one PC, used from all of them.** Start the server on any Windows machine on the network;
  everyone else opens a browser and works at the same time.
- **No installation on the workstations.** Any modern browser, including phones and tablets.
- **Real multi-user safety.** Every save is one database transaction, and edits use optimistic
  locking so two clerks can never silently overwrite each other.
- **Proper accounts.** Salted PBKDF2 password hashes and a role/permission matrix replace the legacy
  plaintext passwords and single "which menu can you open" field.
- **A full audit trail.** Who changed what, when, and from where.
- **One search box for everything.** `Ctrl K` from any screen searches stock, customers and
  invoices at once and takes you to the record — the DOS system made you pick the right screen
  first.
- **Light by default**, dark when the operating system asks for it, and a print stylesheet for
  invoices and reports. The palette, radii, shadows and the Manrope/Inter pairing are taken from
  `NTC-TMS-Tauri` so the two applications read as one family; the fonts load from Google Fonts with
  a full system fallback, since this server often runs on a LAN with no route out.

---

## Quick start (Windows)

### 1. Install Python, once

```bash
winget install Python.Python.3.12
```

Version 3.10 or newer. Nothing else needs installing — no database server, no Node.js, no web server.

### 2. Load the legacy data

```bash
start.bat
```

Run it once and close it. That creates `backend\.venv` and installs the dependencies. Then migrate
the DOS data into the application database:

```bash
backend\.venv\Scripts\python.exe backend\migrate.py
```

It reads the `.DBF` files from `legacy\` and writes `database\ims.sqlite`, taking about seven minutes
for the full 2.5-million-row movement ledger. Variants:

| Command | Effect |
| --- | --- |
| `migrate.py` | Everything, including the movement ledger and reconstructed invoice lines |
| `migrate.py --skip-moves` | Masters and documents only — under two minutes, but no line detail |
| `migrate.py --since 2020-01-01` | Limit the movement ledger to recent years |
| `migrate.py --reset` | Delete the existing database and rebuild from scratch |

The legacy `.DBF` files are only ever read. Nothing writes back to them.

### 3. Start the server

```bash
.\start.bat
```

It prints where it is listening:

```
  Marina Trading - Inventory Monitoring System 1.0.0
  Database : C:\Projects\Inventory-Monitoring-System\database\ims.sqlite
  Local    : http://localhost:8080
  Network  : http://192.168.100.17:8080
```

Open **Local** on this PC, or the **Network** address from any other PC on the same network. Closing
the window stops the server. To use a different port:

```bash
.\start.bat 9000
```

### 4. Sign in

Everyone from the legacy `PASSFYL` is migrated with the password they already knew — now stored as a
PBKDF2 hash rather than plaintext — and is required to change it at first sign-in. If no
administrator account exists, the migration creates `ADMIN` with the password `changeme`.

**One person, one login.** The DOS system worked differently: it gave a person one row per access
code, each with its own password, and *the password you typed chose which menu you got*. `ADMIN`
alone had eight — `MNUMAIN` opened the main menu, `MNUINVS` the inventory system, `MNUAR` accounts
receivable, and so on. A web account cannot work that way, so each name collapses to a single login
that carries the **widest role that person held**, and keeps that row's password. The other
passwords for the same name stop working.

So if an old password is rejected, it is probably one of the discarded ones rather than a fault. To
see which row won for each person, read the legacy file directly:

```bash
backend\.venv\Scripts\python.exe legacy\tools\ims.py head PASSFYL -n 30 -f USER_M,PASSWORD,ACCESMNU,ACCESS_C
```

Match the `ACCESMNU` values against the role table under [Roles and permissions](#roles-and-permissions);
the surviving password is the one on the most privileged row for that user.

**Case does not matter for a migrated password.** The DOS login upper-cased every keystroke, so
nobody ever had to think about it, and every migrated password is stored upper-case. An account that
has not yet chosen a new password will therefore also accept the lower-case form. That concession
disappears the moment the user sets their own password.

If a member of staff is locked out, sign in as an administrator and use **Users & Audit → Reset
password**.

### Locked out of the administrator account

There is a console recovery path, for when nobody can sign in at all. Run it on the server itself:

```bash
backend\.venv\Scripts\python.exe backend\reset_password.py
```

With no arguments it lists every account with its role, whether it is enabled, and when it last
signed in. To set a password:

```bash
backend\.venv\Scripts\python.exe backend\reset_password.py ADMIN
```

It prompts twice, closes that account's open sessions, and requires them to choose their own
password at the next sign-in. `--make-admin` also restores the admin role and re-enables a disabled
account, and `--password` sets one non-interactively for scripting.

This grants nothing that running it does not already imply — anyone who can execute it already has
the database file in their hands. Keep it on the server, and never expose it.

---

## Checking for errors

### Lint both halves

```bash
lint.bat
```

One command, one verdict — `CLEAN` and exit code 0, or `FAILED` and exit code 1 with the findings
listed. It installs what it needs on first run. To apply the fixes that can be applied
automatically:

```bash
lint.bat --fix
```

Node.js is needed only for the frontend half; without it that half is skipped with a note and the
backend is still checked. Details and the rule exemptions are under [Linting](#linting).

### Check the code parses, with nothing installed

Useful on a machine that has neither ruff nor ESLint:

```bash
backend\.venv\Scripts\python.exe -m compileall -q backend/app backend/migrate.py
```

```bash
for %f in (frontend\js\*.js frontend\js\views\*.js) do @node --check "%f"
```

Silence means everything parses. This catches typos, not code smells.

### Runtime errors

| Where to look | What you get |
| --- | --- |
| The `start.bat` window | Every request, and a full traceback for anything that fails. This is the first place to look when a screen misbehaves. |
| Browser developer tools, Console tab (F12) | Frontend errors. The interface also shows a red toast for anything the API rejects. |
| `http://localhost:8080/api/docs` | Interactive API reference — call any endpoint directly to see whether the problem is the backend or the interface. |
| **Users & Audit** screen | Who changed what and when, plus live sessions and row counts per table. |

An edit that fails with *"changed by another user"* is not a fault: it is the optimistic-locking
guard doing its job. Reload the record and reapply the change.

### Check the database is sound

```bash
backend\.venv\Scripts\python.exe -c "import sqlite3,pathlib; print(sqlite3.connect(pathlib.Path('database/ims.sqlite')).execute('PRAGMA integrity_check').fetchone()[0])"
```

`ok` means the file is intact.

---

## Before going live: stock opening balances

One thing the legacy data cannot supply is **how much stock is actually on the shelf**.

`STKFYL.DBF` holds `QTY_R = 0` for all 2,137 items — the DOS system did not keep a running quantity
in the master file. The movement ledger cannot fill the gap either: the surviving `STKREC` starts in
March 2010 and contains 2.5 million sales against only 64,000 purchase lines, because the receipt
side was purged over the years. Netting it produces large negative numbers for most items, which
would be worse than admitting the figure is unknown.

So the migration carries stock in at zero, and the first job after go-live is a **physical count**:

1. Count the warehouse.
2. For each item, open **Stock → the item → Adjust quantity** and enter the counted figure as the
   change, with "Opening physical count" as the reason.
3. Every adjustment posts a movement with an author, a date and a reason, so the opening balance is
   auditable rather than assumed.

From then on the balance maintains itself: invoices take stock out, purchases and returns put it
back, and adjustments record anything else. Until the count is done, expect the dashboard to report
every item as depleted — that is the data being honest, not a fault.

Cost and the five selling price tiers **did** migrate intact, so pricing works from day one.

---

## Making it reachable on the network

The server binds to `0.0.0.0`, so it accepts connections from other machines as soon as Windows
Firewall allows the port. Run once, as administrator:

```bash
netsh advfirewall firewall add rule name="Marina IMS" dir=in action=allow protocol=TCP localport=8080
```

Give the server PC a **static or reserved IP address** on the router so the URL does not change, then
put `http://<that-address>:8080` on everyone's bookmark bar.

Notes on scope and safety:

- This is designed for a **local network**. Do not port-forward it to the public internet as it
  stands — sessions travel over plain HTTP. If remote access is needed, put it behind a VPN, or
  behind a reverse proxy (Caddy or nginx) that terminates HTTPS.
- Change the port with `start.bat 9000` or the `IMS_PORT` environment variable.

---

## What it does

### Home

The successor to the DOS main menu, and the first thing everyone sees.

The three columns are kept — **Transactions, Reports, Maintenance** — because after twenty-five
years that grouping is how the office thinks about the work. So are the **letter keys**: pressing
`G` for Collections or `D` for Invoices is muscle memory for people who have done it every working
day since 1999, and it still works. Each tile shows its key, and the keys are only bound while Home
is open.

What the character-mode menu could never do is tell you anything before you opened a screen. Here
the tiles carry live counts — how many invoices are open, how many items are below their reorder
point, how long since the last backup — above a strip showing receivables, over-90 exposure, sales
this month and stock needing attention.

Above it sits a fixed bar carrying the search box, an alert bell counting what needs a person
(overdue money, short stock, expiring lots), and the account menu.

The screen is not the same for everyone. Each role gets the one action it performs all day as a
button in the header, its own tiles floated to the top of the column, and only the tiles its
permissions allow:

| Role | Header action | First in Transactions |
| --- | --- | --- |
| `admin` | — (everything is available) | Stock, Customers, Suppliers, … |
| `manager` | Open accounts receivable | Stock, Invoices |
| `invoicing` | Raise an invoice | Invoices, Customers, Sales Returns |
| `ar` | Record a payment | Collections, Customers, Invoices |
| `sales` | Look up an item | Stock, Customers, Invoices |
| `inventory` | Receive a delivery | Stock, Purchases, Suppliers |

### Transactions

| Screen | What it does |
| --- | --- |
| **Overview** | Receivables, over-90 exposure, month and year sales, stock value and alerts, 12-month sales chart, latest invoices and payments |
| **Invoices** | Browse and filter, view with full line detail and payment history, create with live stock and customer lookup, edit the header, cancel with full reversal |
| **Collections** | Record a payment, apply it to specific open invoices or auto-allocate oldest first, reverse a bounced payment |
| **Sales Returns** | Return goods to stock and credit the original invoice, defaulting to that invoice's prices |
| **Purchases** | Receive supplier deliveries into stock, roll the moving-average cost forward, record supplier payments |
| **Archived Records** | The legacy `O_*` files, browsable and searchable: 413,361 archived invoices, 39,179 purchases, 30,987 returns, 38,782 collections and 895,023 movements, with the line detail behind each. Read-only — this is the record of what happened |

### Master files

| Screen | What it does |
| --- | --- |
| **Stock** | Search and filter (by division, category, below reorder point, depleted, expiring, expired), five price tiers, lot and expiry, inventory adjustment posted to the ledger, full movement history per item |
| **Customers** | Search, credit limit and terms, per-customer aging, interleaved invoice/return/payment ledger, monthly sales history |
| **Suppliers** | Search, terms and payables, items supplied, purchase history |

### Reports

The DOS Reports column, item for item, keeping its letters:

| Key | Report | What it gives you |
| --- | --- | --- |
| N | Price Inquiry | All five tiers side by side with cost, margin and mark-up; name a customer and it shows the tier they actually buy on |
| O | Stock Inquiry | Search items, see the movement ledger |
| P | Inventory | Valuation at cost, item by item |
| Q | Customer List | Balances, terms, salesmen |
| R | Supplier List | Suppliers and payables |
| S | Sales Summary | By month, customer, salesman, division or category |
| T | Purchase Summary | By supplier |
| U | Purchased Items | By item rather than by document, with average cost and last bought |
| V | Sales Return Summary | By item, customer or month |
| W | Accounts Receivable | Aging: current / 31-60 / 61-90 / over 90 |
| X | Collection Summary | Cash and cheques by month |
| Y | Inactive Customers | No trade in twelve months |
| Z | Overview | Charts and recent activity (new — the character menu had no equivalent) |

Plus fast and slow movers, and the two stock alerts that sat under Maintenance in the original
(Expiration Inquiry and Depleted Stocks).

Every report prints from the browser with a dedicated print stylesheet.

### Maintenance

**Users & Audit** — accounts and roles, live sessions ("who is signed in right now", something the
DOS system could never show), the audit trail, and row counts per table.

**Backup & Database** — the successor to the DOS Maintenance column, where "Back-up Files" meant a
Monday-to-Saturday rotation of floppies and "ReIndex Files" required everyone out of the system.
Neither restriction survives:

| Action | What it does |
| --- | --- |
| Back up now | Copies the live database using SQLite's own backup API, so the office keeps working. Files land in `database\backups`; the newest 14 are kept. A 1.2 GB database takes about 7 seconds. |
| Run check | Verifies every page and refreshes the query planner's statistics. There are no indexes to rebuild — SQLite maintains its own. Reads the whole file, so allow a minute or two and expect it to slow others down while it runs. |
| Compact | Reclaims free pages by rewriting the file. Needs as much spare disk as the database occupies; do it out of hours. |

A backup on the same disk does not survive that disk failing — copy them off the machine as well.

**Purging of Records** (item 2) — the original purged because `.DBF` files grew until the machine
struggled. This database holds 2.5 million movements in one file without difficulty, so purging is
now a choice rather than a chore, and most offices will never need it. When you do: pick a cut-off,
see exactly what would go, and confirm by typing `PURGE`. Only fully paid invoices, posted
collections and their movements are removed — anything still owed or cancelled is always kept — and
it refuses to run at all unless a backup exists on disk.

**Archive Inquiry** (item 8) — what the archive holds and the years it covers, with archived
invoices broken down by year. The documents themselves are browsable under **Archived Records** on
the Transactions column.

One item from the original column is gone rather than reimplemented: **Set Printer Mode**, because
printing is now the browser's own dialog. Its slot carries Change Password instead.

### Settings

Every account has one, whatever its role: click the initials at the top right and choose
**Settings**. Three sections:

| Section | What is there |
| --- | --- |
| Account | User name, full name, role and the DOS menu it replaces, how many permissions the role grants, when the account was opened, when this sign-in began. All read-only — changing somebody's account is Users & Audit, which is where the permission for it lives. |
| Password | Change your own, without going through the menu. Eight characters or more. You stay signed in on this device. |
| Appearance | **Light**, **Dark**, or **System**, which follows whatever the PC is set to and keeps following it. |

The appearance choice is remembered in that browser, on that PC — not on the account. The
warehouse terminal under fluorescent light and the office PC by the window can want different
answers, and the same clerk uses both.

Nothing here needs a permission, so a sales clerk who sees two menu options still reaches their own
settings.

---

## Roles and permissions

The legacy system had one field, `ACCESMNU`, naming the menu a user was allowed to open. That maps
onto explicit roles:

| Role | Legacy equivalent | Can do |
| --- | --- | --- |
| `admin` | H — Main Menu | Everything, including user management and maintenance |
| `manager` | E — Inventory System | Everything except user management |
| `inventory` | D, J — Inventory Monitoring | Read all; write stock, suppliers, purchases |
| `invoicing` | C, I — Invoicing System | Read all; write invoices, customers, returns |
| `ar` | G — Accounts Receivable | Read all; write collections |
| `sales` | A, B — Sales Order / Monitoring | Read stock, customers, invoices, reports |
| `viewer` | — | Read only |

Permissions are checked on every API call, not just hidden in the interface. The last active
administrator cannot be demoted or disabled.

### The sales screen

`sales` is the one role that is deliberately shown less than its permissions allow, because its
DOS counterpart was: `ACCESMNU = A` opened `MNUSO.PRG`, a box in the middle of an empty screen
with two destinations and an exit. The home screen is built around those two options, on the same
letters — but it shows each option's work rather than drawing a list of them. A menu of three links
beside a sidebar holding the same three links is a menu of menus; the character terminal only
needed one because it could not show an invoice and a menu at the same time. So the home screen is
the latest invoices, each row one click from the printed document, next to what has come in over
the last three months. `A` and `B` still move the screen from the keyboard, `C` still signs out,
and `?` still recites them:

| Key | Option | Where it goes | Legacy program |
| --- | --- | --- | --- |
| A | Print Sales Invoice | `/invoices/print` — find one, then print the document | `SIFYL`, `SIFYLP` |
| B | View Purchases | `/reports/stock-purchases` — every delivery between two dates | `STKPURCH` |
| C | Exit | Sign out | — |

The sidebar is trimmed to match: Print Invoice, Invoices, Stock File, Customer File, Price Inquiry
and View Purchases, and nothing else. Suppliers, purchase documents, returns, collections,
receivables, the archive and maintenance are all withheld, and typing one of those addresses lands
on "Your role does not have access to this screen." This is UI shaping, done in `ROLE_SCREENS` in
`frontend/js/app.js`; the permission checks on the API remain the real boundary.

**Print Sales Invoice** (`frontend/js/views/printInvoice.js`) is the invoice as a document, not the
detail screen sent to a printer: company heading, the customer block with TIN and business style,
the lines, the three discount rates, the net amount spelled out in words, and signature rules. It
reads `GET /invoices/{no}/print`, which had been in the API since the first build with nothing
calling it. A cancelled invoice prints under a CANCELLED watermark. Every role reaches it — the
Print button on the invoice detail screen opens it — but only `sales` gets a sidebar entry for it.

**View Purchases** (`GET /reports/stock-purchases`) lists one row per delivery over a start and
stop date, the six columns `STKPURCH` printed plus the document number. It is a different question
from Purchased Items, which totals by item; both are in the Reports list.

---

## How it works

### Request flow

```
Browser (ES modules)
  │  fetch /api/... with a session cookie
  ▼
FastAPI router  ──►  permission check (Depends(require("invoice:write")))
  │
  ▼
db.transaction()  ──►  BEGIN IMMEDIATE … COMMIT
  │                    header + lines + stock movements + balances, or nothing
  ▼
SQLite (WAL)  +  audit_log row
```

### Concurrency

The DOS system called `RLOCK()` and showed *"record is being used by another user, retry?"*. The web
edition solves the same problem in two layers:

1. **Write transactions** use `BEGIN IMMEDIATE` with a 15-second busy timeout, so two clerks saving
   at the same moment serialise cleanly instead of one failing halfway through.
2. **Optimistic locking**: every editable row carries a `version`. Saving sends the version you
   loaded; if someone else saved first, the API returns `409 Conflict` and the interface says so
   plainly instead of silently discarding their work.

Document numbers are allocated from a `sequences` table inside the same transaction as the insert, so
two people creating invoices simultaneously can never be handed the same number.

### Data integrity

- Creating an invoice writes the header, the lines, one stock movement per line, decrements stock on
  hand and raises the customer balance — atomically.
- Cancelling reverses all of it and leaves the document on file marked `CANCELLED`.
- Quantities are never set directly. An inventory adjustment posts a signed movement and the balance
  follows from it, so every change to stock on hand has a reason and an author.
- Payments applied to an invoice are stored per invoice, so a reversal can put exactly the right
  amounts back.

### Database schema

| Table | Holds |
| --- | --- |
| `users`, `sessions`, `audit_log` | Accounts, live sign-ins, the change history |
| `stock`, `divisions`, `categories` | Item master and its dimensions |
| `customers`, `customer_monthly` | Customer master and derived monthly history |
| `suppliers` | Supplier master |
| `invoices`, `invoice_lines` | Sales invoices |
| `purchases`, `purchase_lines` | Purchase invoices |
| `sales_returns`, `sales_return_lines` | Returns |
| `collections`, `collection_applications` | Payments and what they settled |
| `stock_moves` | The movement ledger — successor to the 658 MB `STKREC.DBF` |
| `sequences`, `settings` | Document numbering and configuration |

Full definitions with indexes are in [backend/app/schema/](backend/app/schema), split
into numbered parts that the server runs in filename order on startup:
[security](backend/app/schema/010_security.sql),
[master files](backend/app/schema/020_master_files.sql),
[sales](backend/app/schema/030_sales.sql),
[purchasing](backend/app/schema/040_purchasing.sql),
[ledger](backend/app/schema/050_stock_ledger.sql),
[archive](backend/app/schema/060_archive.sql).

Adding a column to one of those parts is enough: on the next start `init_db()`
compares the parts against the live database and applies the missing columns
with `ALTER TABLE ADD COLUMN`, then prints what it added. Give every new column
a `DEFAULT` — SQLite cannot add a `NOT NULL` column without one, since there
would be no value for the rows already there. Columns the database has and the
schema no longer declares are reported but never dropped.

### Reading the database

Nothing in `database/` can be opened in an editor. `ims.sqlite` is binary, the
backups are the same format, and `-wal` / `-shm` are internal SQLite structures
that are not text either. To get a readable copy:

```
python backend/dump_db.py                   # the live database
python backend/dump_db.py --backups latest  # ... and the newest backup
python backend/dump_db.py --backups all     # ... and every backup
python backend/dump_db.py --limit 0         # every row, however many
```

It writes `database/plaintext/`, one folder per database:

```
plaintext/
  live/                       the working database
    000_schema.sql            every CREATE statement, as the database stored it
    _journal.txt              what the -wal and -shm hold right now
    _manifest.txt             table, rows written, rows held, files, size
    divisions.sql             a small table: one file
    invoices/                 a big one: a folder of numbered chunks
      0001-0200.sql
      0201-0400.sql
  backups/
    ims-20260830-230617/      one folder per backup, same layout
```

The files are written to be read rather than to be compact. A table over
`--rows-per-file` rows (200 by default) becomes a folder of numbered chunks, so
no file is more than about 70 KB. Inside one, the column list is stated once per
statement instead of once per row, every file opens with a numbered column
legend, and each row is wrapped so nothing runs off the side of the editor:

```sql
-- invoices  -  rows 1 to 200 of 84,781 in the database
--
-- 27 column(s), in the order the values appear below:
--    1 inv_no         TEXT        2 customer_code  TEXT
--    3 customer_name  TEXT        4 address        TEXT
--   ...

INSERT INTO invoices
       (inv_no, customer_code, customer_name, address, city, inv_date, due_date,
        terms_text, terms_days, price_cat, salesman, remarks, gross, disc1, ...)
VALUES
       -- 1
       ('N1605-0124', 'MEC', 'MEC PHARMACY', 'A ST.PAUL SUBD.BRGY.CANALATE',
        'MALOLOS BULACAN', '2016-05-17', '2016-06-16', 'CDD-CASH', 30, 'A', ...),
```

It is still valid SQL — a dump replays into an empty database — but that is a
side effect, not the purpose.

`_journal.txt` is the closest thing to readable that a `-wal` and `-shm` have:
they hold raw database pages and a shared-memory index, not rows, so what the
report gives is the log's header, how many committed frames are sitting in it
and how much of the database they cover. The rows themselves are already in the
`.sql` files — a read of the database sees the log's contents merged in.

Row counts are capped at 2,000 per table by default; `--limit 0` writes
everything. Databases are opened read-only and a dump leaves the folder exactly
as it found it, journal files included, so this is safe to run while the server
is up.

Session tokens and password hashes are left out unless you pass
`--include-secrets`. The folder is git-ignored along with the rest of
`database/`, because a dump holds the same customer records the database does.

### What the migration changes on purpose

| Legacy | Web edition | Why |
| --- | --- | --- |
| Plaintext `PASSWORD` field | PBKDF2-SHA256 hash, forced change at first sign-in | The old file exposed every password to anyone who could open a `.DBF` |
| `ACCESMNU` menu name | `role` plus a permission matrix | Menu visibility is not access control |
| Several rows per person, one per access code, each with its own password | One login carrying the widest role that person held | The typed password used to select a menu; a web session cannot pick its privileges at sign-in |
| 60 monthly history columns on the customer record | `customer_monthly` rows recomputed from the invoices | The columns had no year attached; the derived table always agrees with the documents |
| Invoice lines living only in `STKREC` | `invoice_lines`, rebuilt from the ledger during migration | Lines belong to the invoice, not to the stock file |
| `CUST_BAL` / `SPLYR_BAL` running totals | Recomputed from the open documents | After 25 years of purges and archive runs the cached totals disagreed with the invoices they summarise. Customer balances now reconcile to the cent with the open invoices |
| Purchases with no payment fields | Migrated as settled | `PURFYL` never tracked what was paid to suppliers. Carrying them in as open would invent a payable that never existed; purchases raised in the web edition do track payment |
| `USER_M` stamp on each record | `audit_log` | Records who did what, when, from where, and what changed |
| Index rebuild as a maintenance chore | SQLite indexes, maintained automatically | `RBILDALL` needed everyone out of the system |

---

## API

The API is self-documenting: with the server running, open **`/api/docs`**.

| Group | Endpoints |
| --- | --- |
| Auth | `POST /api/login`, `POST /api/logout`, `GET /api/me`, `POST /api/change-password` |
| Stock | `GET /api/stock`, `/stock/{code}`, `/stock/{code}/moves`, `/stock/lookup`, `POST /api/stock`, `PUT /api/stock/{code}`, `POST /api/stock/{code}/adjust`, `POST /api/stock/prices` |
| Customers | `GET /api/customers`, `/{code}`, `/{code}/ledger`, `/{code}/aging`, `/{code}/monthly`, `POST`, `PUT` |
| Suppliers | `GET /api/suppliers`, `/{code}`, `/{code}/items`, `/{code}/purchases`, `POST`, `PUT` |
| Invoices | `GET /api/invoices`, `/{id}`, `/{id}/print`, `POST`, `PUT /{id}`, `POST /{id}/cancel` |
| Purchases | `GET /api/purchases`, `/{id}`, `POST`, `POST /{id}/pay` |
| Returns | `GET /api/returns`, `/{id}`, `POST`, `PUT /{id}` |
| Collections | `GET /api/collections`, `/{id}`, `/open-invoices/{customer}`, `POST`, `POST /{id}/reverse` |
| Reports | `/api/reports/dashboard`, `aging`, `sales`, `purchases`, `inventory`, `expiring`, `depleted`, `movers`, `collections`, `inactive-customers` |
| Admin | `/api/admin/users`, `roles`, `sessions`, `audit`, `stats` |
| Maintenance | `GET /api/maintenance/status`, `purge-preview`; `POST /api/maintenance/backup`, `check`, `compact`, `purge` |
| Archive | `GET /api/archive/summary`, `/api/archive/{kind}`, `/api/archive/{kind}/{number}`, `/api/archive/moves/by-item/{code}` |

---

## Project layout

```
start.bat               one-click start (creates the venv on first run)
lint.bat                lints backend and frontend, one pass/fail
eslint.config.mjs       frontend lint rules
package.json            dev-only tooling; nothing here is served to a browser
README.md               this file
README-LEGACY.md        the original FoxPro/DOS system

backend/                Python API
  pyproject.toml        ruff configuration
  requirements.txt      what the server needs to run
  requirements-dev.txt  adds ruff
  migrate.py            legacy .DBF  ->  SQLite
  dump_db.py            SQLite  ->  plain .sql text, for looking at the data
  reset_password.py     console recovery when nobody can sign in
  .venv/                created on first run (gitignored)
  app/
    main.py             app factory, routing, frontend hosting
    config.py           settings, all overridable by environment variable
    db.py               connections, WAL, transactions, sequences, audit
    security.py         password hashing, sessions, roles and permissions
    deps.py             auth dependencies, optimistic-locking helpers, paging
    schema/             the relational schema, in numbered parts run in order
                        000 conventions, 010 security, 020 master files,
                        030 sales, 040 purchasing, 050 ledger, 060 archive
    routers/            auth, stock, customers, suppliers, invoices,
                        purchases, returns, collections, reports, admin

frontend/               browser application, no build step
  index.html            the shell
  css/app.css           the whole stylesheet, light and dark
  js/
    api.js              fetch wrapper, 401 and 409 handling
    ui.js               DOM helpers, tables, modals, toasts, type-ahead
    omni.js             the top-bar search across stock, customers and invoices
    router.js           hash router
    theme.js            light / dark / follow-system, stored per browser
    app.js              bootstrap, session, navigation
    views/
      home.js           the role-aware launcher that replaces the DOS main menu
      settings.js       account details, password, light/dark appearance
      maintenance.js    backup and database housekeeping
      purge.js          purging of records
      archive.js        archived records and archive inquiry
      …                 one module per remaining screen

database/               all gitignored
  ims.sqlite            the database itself, binary
  backups/              copies taken by the maintenance screen, also binary
  plaintext/            text dump written by dump_db.py, safe to delete

legacy/                 the FoxPro/DOS system it replaces
  *.PRG                 256 source programs
  *.DBF, *.IDX          the original data (gitignored)
  MAIN.FOX              compiled entry point
  run/Run-IMS.bat       DOSBox-X launcher
  tools/ims.py          read and export the DBF tables without FoxPro
```

The `legacy/` folder is documented separately in [README-LEGACY.md](README-LEGACY.md).

---

## Configuration

Every setting is an environment variable, so nothing needs editing to move between machines:

| Variable | Default | Purpose |
| --- | --- | --- |
| `IMS_DB` | `database/ims.sqlite` | Database location |
| `IMS_FRONTEND` | `frontend/` | Folder the browser application is served from |
| `IMS_LEGACY_DIR` | `legacy/` | Where `migrate.py` looks for `.DBF` files |
| `IMS_PLAINTEXT_DIR` | `database/plaintext/` | Where `dump_db.py` writes the text dump |
| `IMS_HOST` / `IMS_PORT` | `0.0.0.0` / `8080` | Bind address and port |
| `IMS_COMPANY` | `Marina Trading` | Name shown in the header and page titles |
| `IMS_SESSION_HOURS` | `12` | How long a sign-in lasts |
| `IMS_PBKDF2_ROUNDS` | `260000` | Password hashing work factor |

---

## Backups

The database is a single file. Stop the server (or use SQLite's online backup) and copy:

```bash
copy database\ims.sqlite "\\server\backups\ims-%DATE%.sqlite"
```

The legacy system rotated backups Monday to Saturday. Keeping that habit is a good idea; a scheduled
task running the line above is enough.

---

## Development

```bash
cd backend
.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8080
```

The front end has no build step — edit the files under `frontend/` and refresh. Static responses are
sent with `Cache-Control: no-cache`, so workstations that leave the app open for days still pick up
an update on reload.

### Linting

`lint.bat` checks both halves — see [Checking for errors](#checking-for-errors) for the everyday
commands. What sits behind it:

| Half | Tool | Configuration |
| --- | --- | --- |
| Backend | [ruff](https://docs.astral.sh/ruff/) | `backend/pyproject.toml`, installed from `backend/requirements-dev.txt` |
| Frontend | [ESLint](https://eslint.org/) | `eslint.config.mjs`, dev-only `package.json` |

To run them separately:

```bash
backend\.venv\Scripts\python.exe -m ruff check backend
```

```bash
npx eslint "frontend/**/*.js"
```

Two rules are switched off deliberately, and the reasons are in `backend/pyproject.toml`:

- **`B008`** (function call in a default argument) fires on all 128 route signatures, because
  `Depends(require("invoice:write"))` in the signature *is* how FastAPI declares a dependency. Left
  on, it buries every real finding.
- **`RUF005`** prefers `[*params, page_size]` over `params + [page_size]`. At the query call sites the
  concatenation reads better, and both operands are always lists.

`migrate.py` is additionally exempt from `BLE001`: its `except Exception` is the deliberate one that
turns a malformed legacy record into `None` instead of aborting a 2.5-million-row migration.

---

## Status

The application is complete and exercised end to end against the real 25-year dataset: sign-in and
permissions, all master files, invoice creation with stock and balance posting, payment application
and reversal, invoice cancellation with full reversal, optimistic-locking conflicts, and every
report. Both halves lint clean (`lint.bat`).

Automated coverage is a smoke test over the whole API surface rather than a unit-test suite; that is
the obvious next piece of work, along with PDF invoice output and a scheduled backup task.
