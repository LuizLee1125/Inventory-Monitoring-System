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
- **Light and dark themes**, and a print stylesheet for invoices and reports.

---

## Quick start (Windows)

Install Python once, if it is not already there:

```bash
winget install Python.Python.3.12
```

Then start the system:

```bash
start.bat
```

The first run creates `backend\.venv`, installs the dependencies, and starts the server. It prints
something like:

```
  Marina Trading - Inventory Monitoring System 1.0.0
  Database : C:\Projects\Dad Project\database\ims.sqlite
  Local    : http://localhost:8080
  Network  : http://192.168.100.17:8080
```

Open the **Network** address from any other PC on the same network.

### Loading the legacy data first

Before the first start, migrate the DOS data into the application database:

```bash
backend\.venv\Scripts\python.exe backend\migrate.py
```

It reads the `.DBF` files from `legacy\` and writes `database\ims.sqlite`. Useful variants:

| Command | Effect |
| --- | --- |
| `migrate.py` | Everything, including the 2.5-million-row movement ledger (about 7 minutes) |
| `migrate.py --skip-moves` | Masters and documents only — fast, but no invoice line detail |
| `migrate.py --since 2020-01-01` | Limit the movement ledger to recent years |
| `migrate.py --reset` | Delete the existing database and rebuild from scratch |

The legacy `.DBF` files are only ever read. Nothing writes back to them.

### Signing in

Every user from the legacy `PASSFYL` is migrated with the password they already knew — now stored as
a PBKDF2 hash rather than plaintext — and is required to change it at first sign-in. If no
administrator account exists, the migration creates `ADMIN` with the password `changeme`.

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

### Transactions

| Screen | What it does |
| --- | --- |
| **Dashboard** | Receivables, over-90 exposure, month and year sales, stock value and alerts, 12-month sales chart, latest invoices and payments |
| **Invoices** | Browse and filter, view with full line detail and payment history, create with live stock and customer lookup, edit the header, cancel with full reversal |
| **Collections** | Record a payment, apply it to specific open invoices or auto-allocate oldest first, reverse a bounced payment |
| **Sales Returns** | Return goods to stock and credit the original invoice, defaulting to that invoice's prices |
| **Purchases** | Receive supplier deliveries into stock, roll the moving-average cost forward, record supplier payments |

### Master files

| Screen | What it does |
| --- | --- |
| **Stock** | Search and filter (by division, category, below reorder point, depleted, expiring, expired), five price tiers, lot and expiry, inventory adjustment posted to the ledger, full movement history per item |
| **Customers** | Search, credit limit and terms, per-customer aging, interleaved invoice/return/payment ledger, monthly sales history |
| **Suppliers** | Search, terms and payables, items supplied, purchase history |

### Reports

AR aging (current / 31-60 / 61-90 / over 90, by customer and salesman) · Sales (by month, customer,
salesman, division or category) · Purchases by supplier · Inventory valuation · Expiring and expired
stock · Depleted and below reorder point · Fast and slow movers · Collections by month and method ·
Inactive customers.

Every report prints from the browser with a dedicated print stylesheet.

### System

Users and roles, live sessions ("who is signed in right now" — something the DOS system could never
show), the audit trail, and database row counts.

---

## Roles and permissions

The legacy system had one field, `ACCESMNU`, naming the menu a user was allowed to open. That maps
onto explicit roles:

| Role | Legacy equivalent | Can do |
| --- | --- | --- |
| `admin` | H — Main Menu | Everything, including user management |
| `manager` | E — Inventory System | Everything except user management |
| `inventory` | D, J — Inventory Monitoring | Read all; write stock, suppliers, purchases |
| `invoicing` | C, I — Invoicing System | Read all; write invoices, customers, returns |
| `ar` | G — Accounts Receivable | Read all; write collections |
| `sales` | A, B — Sales Order / Monitoring | Read stock, customers, invoices, reports |
| `viewer` | — | Read only |

Permissions are checked on every API call, not just hidden in the interface. The last active
administrator cannot be demoted or disabled.

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

Full definitions with indexes are in [backend/app/schema.sql](backend/app/schema.sql).

### What the migration changes on purpose

| Legacy | Web edition | Why |
| --- | --- | --- |
| Plaintext `PASSWORD` field | PBKDF2-SHA256 hash, forced change at first sign-in | The old file exposed every password to anyone who could open a `.DBF` |
| `ACCESMNU` menu name | `role` plus a permission matrix | Menu visibility is not access control |
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
  .venv/                created on first run (gitignored)
  app/
    main.py             app factory, routing, frontend hosting
    config.py           settings, all overridable by environment variable
    db.py               connections, WAL, transactions, sequences, audit
    security.py         password hashing, sessions, roles and permissions
    deps.py             auth dependencies, optimistic-locking helpers, paging
    schema.sql          the full relational schema
    routers/            auth, stock, customers, suppliers, invoices,
                        purchases, returns, collections, reports, admin

frontend/               browser application, no build step
  index.html            the shell
  css/app.css           the whole stylesheet, light and dark
  js/
    api.js              fetch wrapper, 401 and 409 handling
    ui.js               DOM helpers, tables, modals, toasts, type-ahead
    router.js           hash router
    app.js              bootstrap, session, navigation
    views/              one module per screen

database/               ims.sqlite lives here (gitignored)

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

One command checks both halves and returns a single pass/fail:

```bash
lint.bat
```

```bash
lint.bat --fix
```

It installs what it needs on first run, and skips the frontend with a note if Node.js is absent —
Node is required only for linting, never to run the application.

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
