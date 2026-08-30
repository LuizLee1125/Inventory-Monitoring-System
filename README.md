# Marina Trading — Inventory Monitoring System (IMS)

A complete, multi-user **wholesale distribution / inventory & receivables system** written in FoxPro
(xBase) for DOS. It has been in continuous production use — and continuous maintenance — from
**1999 to 2024**: 256 source programs, 67 data tables, and a live dataset of ~85,000 sales invoices,
~2.5 million stock movements, and ~366,000 collection records.

This repository is the **source code archive and documentation** of that system.

> **Status:** legacy production system. It runs today under a DOS emulator on Windows. See
> [Running it](#running-it) and [Making it window-based](#making-it-window-based).

---

## ⚠️ Read this before you push to GitHub

The working folder is **~1.7 GB** and contains real business data. Publishing it as-is would be a
data breach *and* would be rejected by GitHub.

| Problem | Detail |
| --- | --- |
| **Live customer/supplier data** | `CUSTFYL.DBF` (1,735 customers with addresses, phones, TIN, credit limits), `SPLYRFYL.DBF`, invoice history |
| **Plaintext passwords** | `PASSFYL.DBF` stores usernames and passwords as unencrypted character fields |
| **File size limits** | `STKREC.DBF` is 658 MB, `O_TRN2.DBF` 228 MB, `O_SIFYL.DBF` 158 MB — GitHub hard-blocks any file over 100 MB |

**Commit only source (`*.PRG`) plus docs.** A `.gitignore` is included that excludes every `.DBF`,
`.IDX`, and `.FOX`. If you want the repo to be runnable by others, ship a small **synthetic sample
dataset** (empty tables with the right structure and a handful of fake rows) instead of production
files.

```bash
git init
git add .gitignore README.md *.PRG
git commit -m "Marina Trading IMS: FoxPro source archive"
```

---

## What the program does

It is the back office for a trading/distribution business. In one integrated system it handles:

- **Stock control** — item master, multi-tier pricing, lot numbers and expiry dates, reorder levels,
  inventory adjustments, per-supplier sourcing
- **Sales** — sales orders, invoicing, printed invoices, sales returns
- **Purchasing** — purchase invoices, supplier balances, purchased-items history
- **Receivables & collections** — aging (30/60/90/over-90), payments, checks, bad accounts
- **Expenses & vouchers** — expense monitoring, voucher file, debit/credit memos
- **Reporting** — dozens of printed reports by customer, supplier, division, category, salesman and period
- **Archiving & housekeeping** — purge, archive, reindex, and a rotating 6-day backup

All of it is **multi-user over a shared network drive**, with explicit record locking and retry
prompts when two clerks touch the same record.

---

## Functions

### Transactions
| Menu item | Program | What it does |
| --- | --- | --- |
| Stock File | `MNUSTK` → `STKFYL`, `PRYSADJ`, `INVADJ` | Item master, price adjustment, inventory adjustment |
| Customer File | `CUSTFYL` | Customer master, credit terms, price category, monthly sales history |
| Supplier File | `SPLYRFYL` | Supplier master, terms, credit limit, running balance |
| Invoice Maintenance | `SIFYL2` / `SIFYL` | Create and edit sales invoices, line items priced from the stock master |
| Purchase Invoice | `PURFYL` | Record supplier invoices, receive stock |
| Sales Return | `SRFYL` | Return-to-stock and credit against the original invoice |
| Collections | `COLCFYL` | Post customer payments, apply to open invoices |
| Sales Order | `MNUSO`, `PROSO1`–`PROSO4` | Order entry and order processing (5 order sets: `SOFYL0`–`SOFYL4`) |
| Archived Records | `MNUOLDTR` | Read-only access to purged/archived history (`O_*` tables) |

### Reports
Price Inquiry · Stock Inquiry · Inventory · Customer List · Supplier List · Sales Summary ·
Purchase Summary · Purchased Items · Sales Return Summary · Accounts Receivable · Collection
Summary · Inactive Customers · Expiration Inquiry · Depleted Stocks · Archive Inquiry

Implemented by the ~90 `LST*.PRG` (list/report) and `REP_*.PRG` (report by dimension) programs, plus
`SI1PRN`–`SI13PRN` for the invoice print layouts.

### Maintenance
Purging of records (`MNUPURGE`) · Code revisions (`MNU_CREV`) · Reindex all files (`RBILDALL`) ·
Back-up files (`BACKDATA`, Monday–Saturday rotation) · Set printer mode (`SETPRINT`) · Password file
(`PASSFYL`)

---

## How it works

### Startup chain

```
MAIN.FOX  (compiled entry point)
   ├── DO INITENV      set the FoxPro environment, colors, PUBLIC vars, ON ERROR handler
   ├── DO PASSWORD     login screen; looks up PASSFYL, reads that user's ACCESMNU
   └── DO &mACCESMNU   macro-expands to the menu program that user is allowed to run
```

`INITENV.PRG` is the whole configuration file: `SET EXCLUSIVE OFF` (multi-user), `SET DELETED ON`,
`SET PROC TO MODULEM` (the shared procedure library), an `ON ERROR DO ERR_FIX` trap, and nine
colour macros (`c_head`, `c_body`, `c_option`, `c_message`, …) that every screen expands with `&`.
The company name shown in every header is a variable here: `company = 'MARINA TRADING'`.

### Role-based access

The login record's `ACCESMNU` field decides which top-level menu the user gets — the whole
authorization model in one field:

| Code | Role | Menu program |
| --- | --- | --- |
| A | Sales Order | `MNUSO` |
| B | Sales Monitoring | `MNUSIM` |
| C | Invoicing System | `MNUNVCS` |
| D | Inventory Monitoring | `MNUINVM` |
| E | Inventory System (full admin) | `MNUINVS` |
| F | Expense Monitoring | `MNUXPENS` |
| G | Accounts Receivable | `MNUAR` |
| H | Main Menu (passwords + reindex) | `MNUMAIN` |
| I | Invoicing / AR | `MNUSO2` |
| J | Inventory System 2 | `MNUINV2` |

### The screen engine

There is no forms designer. Every screen is drawn with `@ row, col SAY/GET` on an 80×25 character
grid, and all shared UI behaviour lives in **`modulem.prg`** (~1,200 lines), the procedure library
loaded once at startup:

| Procedure | Role |
| --- | --- |
| `BRDR1` / `BRDR2` | Standard page frame, title bar, user name, hint line |
| `MENU3C` | The three-column menu driver — arrow keys + letter/number hotkeys |
| `MENUOPT`, `OPTION1`…`OPTION14` | The action bar (`Save Edit Delete preV Next Abort Print`) and its state machine |
| `MODE` | Decides add-vs-edit: seeks the key, sets `new` and `action` (`GET` = editable, `SAY` = display) |
| `VALID1` / `VALID2` | Lookup-and-validate a foreign key while typing |
| `KEYS` / `PAGEKEY` | Scrolling and paging inside 10-row line-item grids |
| `RECLOCK1` | `RLOCK()` loop with a "record is being used by another user, retry?" prompt |
| `ERR_FIX` | Global `ON ERROR` handler; on lock errors 109/130 it retries up to 2,500 times, then asks |

Because the same procedures back every screen, all 250+ programs look and behave identically — the
same keys do the same thing everywhere.

### Data model

Classic xBase: one `.DBF` table per entity, one `.IDX` per access path, opened per work area with
`USE … INDEX …` and navigated with `SEEK`. Headers and details are separate files:

| Table | Rows | Purpose |
| --- | --- | --- |
| `STKFYL` | 2,137 | Stock master — code, description, division, category, lot, expiry, 3 reorder levels, cost, and five price tiers (`PRYS_A`–`PRYS_E`) with markups |
| `STKREC` | 2,575,645 | Every stock movement — the transaction ledger (`TRANS_C` tags sale/purchase/return) |
| `SIFYL` | 84,912 | Sales invoice headers — customer, terms, discounts, net, payment and balance |
| `CUSTFYL` | 1,735 | Customer master with 12-month sales and sales-return history columns |
| `SPLYRFYL` | 66 | Supplier master |
| `PURFYL` | 8,217 | Purchase invoice headers |
| `SRFYL` | 1,932 | Sales return headers |
| `COLECFYL` | 365,842 | Collections / payments |
| `SOFYL0`–`SOFYL4`, `SOREC*` | — | Sales order headers and lines (one set per terminal/series) |
| `VOUCHFYL`, `CMFYL`, `DMFYL`, `ACCTFYL` | — | Vouchers, credit memos, debit memos, chart of accounts |
| `O_*` | — | Archived (purged) copies of the above |
| `PASSFYL` | — | Users, passwords, access code |

### Naming conventions

| Prefix / suffix | Meaning |
| --- | --- |
| `MNU*` | Menu screen |
| `*FYL` | Master/header file maintenance screen (and its table) |
| `*REC` | Detail/line-item table |
| `LST*`, `REP_*` | Report programs |
| `SI#PRN` | Sales-invoice print layouts (13 variants) |
| `O_*` | Archive ("old") version of a file or program |
| `VALIDAT*` | Field validation routines |
| `TMP*`, `T*FYL` | Scratch tables used while building reports |

### Printing

Output goes straight to a parallel-port dot-matrix printer with Epson ESC/P control codes
(`CHR(27)+CHR(69)` = bold on). `SETPRINT.PRG` toggles between the real printer and a `TEMP` file, so
you can preview a run without paper.

---

## Running it

### Requirements

| Piece | Status | Notes |
| --- | --- | --- |
| **DOS environment** | free, install below | DOSBox-X (recommended), vDosPlus, or real DOS/Windows 9x |
| **FoxPro 2.x for DOS** (or FoxBASE+) | **you must supply this** | Microsoft proprietary; not redistributable, so it is not in this repo. Any of `FOXPROX.EXE`, `FOXPRO.EXE`, `FOXR.EXE` works. |
| **Data files** | `*.DBF` + `*.IDX` | must sit in the same directory as the programs |

Install the emulator:

```bash
winget install joncampbell123.DOSBox-X
```

### Start it

1. Put your licensed FoxPro DOS installation in `C:\FoxPro` (or edit `FOXPRO_DIR` at the top of
   `run\Run-IMS.bat`).
2. Double-click **`run\Run-IMS.bat`**.

The launcher locates DOSBox-X, verifies the FoxPro runtime, generates `run\ims.conf`, mounts FoxPro
as `C:` and this project as `D:`, and runs `MAIN`. It uses DOSBox-X's TTF text renderer, so the
80×25 screens come up crisp in a resizable Windows window rather than as scaled bitmap pixels.

Doing it by hand instead — from the DOS prompt in the program directory:

```bash
FOXPROX MAIN
```

or from the FoxPro dot prompt:

```bash
DO MAIN
```

Then log in. `PASSWORD.PRG` allows **four attempts** and quits to DOS after that; leaving the user
name blank also quits.

> `MAINSRC.PRG` is a reconstruction of the lost `MAIN.PRG` source, kept under a different name so it
> never shadows the original `MAIN.FOX`. Run it with `DO MAINSRC` if you ever need a source-level
> entry point.

### Multi-user setup

Put the whole directory on a shared drive and run the same `MAIN.FOX` from each workstation.
`SET EXCLUSIVE OFF` plus `RLOCK()` handles concurrency. Two operational rules:

1. **Reindex (`RBILDALL`) requires exclusive use** — everyone must be out; it `PACK`s tables, which
   permanently removes deleted records.
2. **Run the daily backup** (Maintenance → Back-up Files) — it rotates Monday through Saturday.

---

## Reading the data without FoxPro

If you don't have a FoxPro licence, the application can't run — but **the data is not locked up with
it**. The tables are plain dBase-format `.DBF` files, readable on any modern machine.
`tools/ims.py` does exactly that:

```bash
python -m pip install dbfread

python tools/ims.py tables                 # every table, record count, size
python tools/ims.py schema STKFYL          # field definitions
python tools/ims.py head CUSTFYL -n 5 -f CUST_N,CUST_M,CUST_BAL
python tools/ims.py find STKFYL STK_M ALVEDON
python tools/ims.py csv SPLYRFYL           # one table to CSV
python tools/ims.py sqlite --skip-big      # everything into one SQLite database
```

Once exported, the whole 25-year history is queryable with ordinary SQL:

```sql
SELECT CUST_M, CUST_BAL FROM CUSTFYL ORDER BY CUST_BAL DESC LIMIT 10;
SELECT STK_M, QTY_R, EXPIRY_D FROM STKFYL WHERE EXPIRY_D < '2026-01-01';
```

Notes:

- Text is decoded as **code page 437** (DOS), and records flagged deleted are skipped, matching the
  app's `SET DELETED ON`.
- The parser is deliberately tolerant: a handful of numeric fields contain debris like a bare `.`
  that FoxPro accepted. Those cells become `NULL` rather than aborting the export.
- Two scratch tables (`O_SITMP`, `SRT_STC`) have corrupt headers and are reported as unreadable.
  Both are temporary report workspaces, not business data.
- `--skip-big` omits the four tables over 100 MB (`STKREC`, `O_TRN2`, `O_SIFYL`, `COLECREC`). Export
  those individually with `--only STKREC` when you need them.

This is also the natural first step toward options 3 and 4 below.

---

## Making it window-based

Four realistic paths, cheapest first.

### 1. Run it in a proper Windows window — *hours, zero code change*

**vDosPlus** or **DOSBox-X** run DOS FoxPro inside a resizable, scalable Windows window with
selectable fonts, clipboard support, mapped network drives, and — importantly — **printing to modern
Windows printers or PDF**, which real DOS emulation can't do. This is the standard rescue path for
DOS business applications and preserves behaviour exactly.

> Best first move: it makes the system usable on current hardware immediately, with no risk to the
> data, and buys time for anything below.

### 2. Recompile under FoxPro 2.6 for Windows / Visual FoxPro — *weeks, moderate risk*

The `@ … SAY/GET` screens still run in the FoxPro *desktop window* on Windows, so most of the code
compiles and runs with a native title bar, resizing and Windows printing. Expect to fix:

- `INKEY()`/`READKEY()` scan codes and the hand-rolled password field
- `SET COLOR TO` macros → Windows colour pairs or plain themes
- Direct `LPT1` / ESC/P printing → Windows print jobs or a report writer
- `RUN` shell-outs and 8.3 path assumptions

Result: a windowed app that is still character-grid inside. A halfway house, not a modern UI.

### 3. New GUI front end on the existing DBF files — *months, low risk to data*

Keep the `.DBF` files as the database and write a new UI against them. The tables are readable today
by:

- **Python** — `dbf` / `simpledbf` + PySide6 or Tkinter for the desktop, or FastAPI + a web front end
- **C# / .NET** — the Visual FoxPro OLE DB provider, or a DBF library, with WinForms/WPF/Blazor
- **Web** — a small service that reads DBFs and serves a browser UI on the LAN

This lets you modernize screen by screen (start with Stock Inquiry and Price Inquiry — read-only,
high value) while the DOS app keeps running for everything else. Watch out: writing to DBFs from two
different runtimes at once needs matching lock semantics, so **read-only first**.

### 4. Full migration — *the real answer long-term*

Move the data into **SQLite / PostgreSQL / SQL Server** (a one-off ETL from the DBFs is
straightforward — the schemas are flat and fully documented above), then rebuild the app as a
desktop or web application. The 25 years of `.PRG` files become the specification: they encode the
actual pricing tiers, discount rules, aging buckets and invoice numbering the business runs on.

Suggested order: **1 → 3 (read-only reports) → 4**, skipping 2 unless you have a FoxPro licence and
want a quick visual win.

---

## Known constraints

- **`MAIN.PRG` source is missing** — only the compiled `MAIN.FOX` survives. Its logic is short and
  recoverable from the strings inside it: `DO INITENV`, `DO PASSWORD`, `DO &mACCESMNU`. Rewriting it
  as a plain `MAIN.PRG` is a good first contribution.
- **Passwords are stored in plaintext** and compared with a `LOCATE FOR`; there is no lockout beyond
  four tries per session.
- **8.3 filenames, uppercase, no subdirectories** — all 403 files sit in one folder.
- **Two-digit years** — `SET CENTURY` is toggled on and off per program; date handling is
  inconsistent across the codebase.
- Some programs reference companions (`modulem2`, `modulem3`) that are variants of the main library;
  behaviour depends on which one a program loads.

---

## Repository layout

```
*.PRG          256 source programs (menus, screens, reports, utilities)
MAIN.FOX       compiled entry point
MAINSRC.PRG    reconstruction of the lost MAIN.PRG source
run/
  Run-IMS.bat  DOSBox-X launcher (generates ims.conf, mounts and starts MAIN)
tools/
  ims.py       read/export the DBF tables without FoxPro
*.DBF          67 data tables      ← gitignored
*.IDX          77 index files      ← gitignored
readme.txt     original one-page note from the author
```

---

## Credits

Written and maintained by the original author from 1999 through 2024 for Marina Trading. This
repository preserves the source, documents the architecture, and lays out a migration path.
