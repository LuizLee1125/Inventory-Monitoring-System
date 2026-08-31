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
- **Screens that keep themselves current.** Raise an invoice at one counter and the stock figures,
  the invoice list and the bell move on every other machine, with no refresh — including the
  quantities under the cursor of somebody mid-way through writing an invoice. One held-open
  connection per browser, no polling: ten workstations cost 0.000 s of server CPU over 40 s.
- **An oversold item is a note to the buyer, not a lost sale.** If two clerks sell the same stock at
  once the second invoice still goes through; the difference is recorded, the clerk is told, and it
  appears on **Needs Refilling** until a delivery covers it. Switchable off per item.
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

### Restarting

**Stop the old server before starting a new one.** Two copies cannot share a port: the second one
fails to start while the first carries on serving, so the screen keeps showing the old version and a
restart appears to do nothing. `start.bat` now checks first and says so rather than letting that
happen silently:

```
 ALREADY RUNNING - nothing was started
 Something is already serving port 8080 (process 9160).
 ...
     taskkill /PID 9160 /F
```

Closing the server's console window is the normal way to stop it. If that window is gone but the
process is not:

```bash
netstat -ano -p TCP | findstr :8080
taskkill /PID <the number from the last column> /F
```

A sign you are looking at a server that never restarted: the maintenance screen says *"The server is
running an older version than this page."*

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

Because user names are upper-case, staff hold Caps Lock down to type one — and then type their
password with it still on. The sign-in screen says so, under the password box, rather than leaving
the rejection that follows unexplained. The eye at the end of the box shows what was typed.

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

## Desktop edition

Everything above still holds: the system is a server and a browser, and that is
how most of the office will keep using it. The desktop edition adds an installed
application — an icon on the desktop, an entry in the tray, no console window —
for the people who want one. It is in `desktop/`, built with Tauri v2, the same
toolkit as `NTC-TMS-Tauri`.

**It is not a second copy of the application.** The window is pointed at the
running server over HTTP, so what it shows is the same `frontend/` a browser
gets, from the same process, on the same session cookie. Desktop and browser
cannot show different versions of a screen, because there is only one of each
screen. Nothing under `backend/` or `frontend/` changes for it to work.

Two modes, chosen on the first run and remembered:

| Mode | What it does | Where it belongs |
| --- | --- | --- |
| **This PC runs the server** | Starts the server itself and waits for it, then opens the window on it. Quitting the app stops the server. | The office PC — it replaces double-clicking `start.bat` |
| **Connect to the office server** | Opens the window on an address somebody else is hosting. | Counter machines, replacing a browser bookmark |

**The web edition is unaffected either way.** Host mode binds `0.0.0.0` exactly
as `start.bat` does, so while the desktop app is running the server, every other
PC, phone and tablet still opens `http://<server>:8080` and works normally. The
desktop app is one more way in, not a replacement for the others — there is an
*Open in a browser instead* on its first screen and in its tray menu saying so.

If the port is already serving this system — `start.bat` is open, or the app was
launched twice — it **attaches to what is already there** rather than starting a
second copy. That is the failure the [Restarting](#restarting) section is about,
answered rather than merely refused.

### Every time it opens

Two things happen in the desktop app that do not happen in a browser.

**It asks where the system is.** The app connects with the setting it used last,
so the sign-in screen comes up straight away, and then the chooser appears
resting on top of it: *Running on this PC, port 8080* — carry on, or point this
PC somewhere else. A machine that gets switched between hosting and connecting
is worth asking, and asking it over the sign-in screen costs nobody a step: the
answer is already on screen behind the question.

For people who only ever answer the same way, a bar across the bottom of that
window turns it off: **Ask every time the app opens**. Untick it and later opens
go straight to sign-in. It is saved the moment it is ticked, so closing that
window with its own close button keeps the choice. To get the chooser back
afterwards, use **Change server…** in the tray menu.

**It starts signed out.** Closing the app ends the session, so the next person
to open it gets the sign-in screen rather than the last person's account. A
browser tab belongs to somebody; an installed application on a shared counter PC
does not, and that is how the wrong name ends up on an invoice. Reloading inside
a run does *not* sign you out — only closing and reopening the app does.

Neither applies to the browser. Open `http://<server>:8080` and it behaves
exactly as it always has, session and all.

### Getting it onto a PC

**Settings → Desktop app → Download installer.** Every role reaches Settings, so
anybody can install it on the machine they are sitting at; nothing about it is
privileged, and installing the client grants nothing that signing in does not.

Beside it is the **link itself** — `http://<this server>:8080/api/desktop/download`
— shown in full and copyable with one button, so it can be sent to somebody at
another counter rather than walked over to. It is an address on this server, not
on the internet, so it works with the office line down; whoever opens it needs to
be signed in here first.

The installer comes off this server rather than off the internet. `NTC-TMS-Tauri`
fetches its releases from cloud storage because its users are spread across the
country; these users are all on one network with the server in the corner of the
room, and a release channel that needed the line to be up would be one that
fails on exactly the days it is not.

What Settings offers is the newest installer in `releases\`, and failing that
whatever `npm run build` last wrote into `desktop\src-tauri\target\release\bundle`
— so a fresh build is downloadable without anybody having to copy it anywhere.
To publish one deliberately, put it in `releases\`; that folder wins over the
build output even when the build is newer, because publishing should be a
decision rather than a side effect of compiling.

If Settings says *None on this server*, nobody has built one yet.

### Launching it

There are three ways to open this system, and they are not the same thing.

| What you want | What to open | What you get |
| --- | --- | --- |
| **The web edition** | A browser, at `http://localhost:8080` or `http://<server>:8080` | A tab. The server must already be running — `start.bat`, or the desktop app in host mode |
| **The desktop app, installed** | **Start menu → Marina IMS**, or the desktop shortcut the installer makes | The application. It starts the server itself if it is set to host |
| **The desktop app, from source** | `start-desktop.bat` | The same application, compiled fresh — for changing it, not for using it |

`start.bat` does **not** open the desktop app; it starts the server and nothing
else. `start-desktop.bat` is the *development* launcher: it needs
[Node.js](https://nodejs.org) and the [Rust toolchain](https://rustup.rs),
compiles the Rust shell on the first run, and takes several minutes to do it.
Neither tool is needed by the web edition and neither belongs on a workstation
— the installer is what goes there.

The two can be open at once. They are the same server and the same data, so an
invoice raised in the app is on the browser's screen when it refreshes.

If the installed app is set to host and `start.bat` is already running, the app
**attaches** to that server rather than starting a second one. That is why
closing the app does not always stop the server: it only stops the one it
started itself.

### Updates

**Settings → Version & updates.** It shows the version running and, under it,
one of five answers: checking, you are on the latest, a version is available,
nothing published on this server yet, or the check failed and why.

In the desktop app an available version comes with **Install now** — it
downloads the installer, closes the app, and runs it. Open the app again
afterwards and it is the new one. The app also checks on every open and puts the
same offer on the chooser, so somebody who never visits Settings still finds out;
that notice appears even for people who turned the chooser off, because turning
off a question you always answer the same way is not the same as asking not to
be told the app is out of date.

In a browser the card shows the **server's** version instead, and offers the
installer as a download. A browser has nothing of its own to update — it is
served by the server, so refreshing is the whole of it.

The check asks **this server**, not the internet: `GET /api/desktop` reports
what installer is published in `releases\`, and the app compares that against
its own version. It therefore works with the office line down, which is when a
LAN system most needs to.

There is no signed auto-update feed. `NTC-TMS-Tauri` has one because its users
are spread across the country and its release endpoint is fixed; here the
release channel is whichever office PC is hosting, which is not known until the
app connects, and a signing key would put a permanent secret in the way of
anybody rebuilding. The reasoning is in
[system_architecture.md](system_architecture.md).

### Releasing a new version

Two numbers, and both have to move:

| File | Versions |
| --- | --- |
| `backend/app/__init__.py` | the server |
| `desktop/src-tauri/Cargo.toml` | the desktop application and its installer |

`tauri.conf.json` has no `version` of its own on purpose — it takes Cargo's, so
the shell and its bundle can never disagree. Then:

```bash
cd desktop && npm run build
```

Copy the resulting `-setup.exe` into `releases\`, commit, and tag the **full
three-part version**:

```bash
git tag -a v0.4.0 -m "Release version 0.4.0" && git push origin refs/heads/v0.4 v0.4.0
```

Three parts even when the branch is the two-part series: a tag and a branch
sharing a name make `git push origin <name>` ambiguous and it refuses.

### Building an installer

To produce one for the office:

```bash
cd desktop
npm run build
```

The `.exe` and `.msi` land in `desktop\src-tauri\target\release\bundle`.

Build notes, the permissions model and the reasoning behind the design are in
[desktop/README.md](desktop/README.md).

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

**Needs Refilling** is new, and it is worth telling apart from Depleted Stocks, which it sits beside.
Depleted answers *what has run low*. Needs Refilling answers *what has already been promised to a
customer and is not on the shelf* — see [Selling below zero](#selling-below-zero). It lists the
buying side (one row per item, because a purchase order is raised per item) and the sales side (which
customers are waiting, on which invoice, since when). Rows clear themselves when stock comes back;
there is nothing to tick off.

Every report prints from the browser with a dedicated print stylesheet.

### Maintenance

**Users & Audit** — accounts and roles, live sessions ("who is signed in right now", something the
DOS system could never show), the audit trail, and row counts per table.

**Backup & Database** — the successor to the DOS Maintenance column, where "Back-up Files" meant a
Monday-to-Saturday rotation of floppies and "ReIndex Files" required everyone out of the system.
Neither restriction survives:

| Action | What it does |
| --- | --- |
| Back up now | Copies the live database using SQLite's own backup API, so the office keeps working. On top of the automatic daily one — see [Backups](#backups) for what is kept. A 1.2 GB database takes about 7 seconds. |
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
**Settings**. Four groups, in two columns:

| Group | What is there |
| --- | --- |
| Account | The account's initials as its picture, name and role, then user name, full name, the DOS menu the role replaces, how many permissions it grants, when the account was opened and when this sign-in began. Read-only — changing somebody's account is Users & Audit, which is where the permission for it lives. |
| Security | Change your own password. Eight characters or more. You stay signed in on this device. **This is the only place it can be done** — it used to be in the account menu as well, which meant two ways in. The DOS key `9` still works and lands here. |
| Appearance | **Light**, **Dark**, or **System**, which follows whatever the PC is set to and keeps following it. The choice is remembered in that browser on that PC, not on the account. |
| Desktop app | Install the [desktop edition](#desktop-edition) on this PC: the file name, the version, its size, the address it comes from, and **Download installer** / **Copy link**. Every account has it, whatever the role. Opened from inside the app itself it says *Installed* and keeps only the link — offering somebody a download of what they are already running is not a useful thing to do. |
| Version & updates | The version running — the *application's* in the desktop app, the *server's* in a browser — and under it whether anything newer is published, with **Check for updates**. In the app an available version comes with **Install now**, which downloads it, closes the app and runs the installer. See [Updates](#updates). |
| System | Company, application, version, and how many roles are defined. |

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

### Selling below zero

Two clerks, one shelf. An item shows 100. One invoices 80 and saves; the second, whose screen was
fetched before that save, invoices 50.

**The second invoice goes through.** For anything the office can reorder, a sale is worth more than a
tidy stock figure, and the clerk was reading a number that was correct when it was drawn. Refusing it
would turn a delivery delay into a lost customer.

What it does *not* do is go through silently:

- the 30 that were promised and are not there become a row in `stock_shortfalls`, and the invoice
  line is marked short;
- the clerk gets a warning naming what was on hand and what was taken, and the invoice carries a
  banner from then on;
- whoever buys gets a **Needs Refilling** alert on the bell, and the item appears on that report;
- the shortfall closes **by itself** when stock comes back to zero or above — through a purchase, a
  sales return, or an inventory adjustment. There is no "mark as handled" button, deliberately: the
  obligation is discharged by the delivery, not by somebody saying it was.

Cancelling the invoice withdraws the obligation, because the goods go back on the shelf. A purge
never removes an invoice that still owes stock — that is unfinished business exactly as an unpaid one
is, even when it has been paid for.

**Turning it off per item.** Stock items have a *Selling below zero* switch, on the edit form.
It is **on for every item**, which is what the system always did — nothing ever checked stock before
writing an invoice. Switch it off for the few things that genuinely cannot be promised (a controlled
drug, a single-source import) and an invoice line that would go below zero is refused instead, naming
the quantity actually available.

While an invoice is being written, the line editor shows what is on hand under each quantity and
**updates it live as other people sell**, so the warning arrives while there is still time to do
something about it. It is advisory: the server decides, against the quantities as they are at the
moment of the save.

### Live updates

Screens update themselves. Raise an invoice at one counter and the invoice list, the stock figures,
the home screen and the bell move on every other machine, with no refresh.

It is one long-lived HTTP connection per signed-in browser (`GET /api/events`, Server-Sent Events) —
no polling, no new dependency on either side. **Idle cost measured on this hardware: ten connected
workstations, 0.000 seconds of server CPU over 40 seconds.** It replaces a 60-second poll that made
about 14,400 requests a day across ten machines to be told nothing had changed, so it is a reduction
in load rather than an addition.

A small dot beside the bell shows the state. It is green and silent while connected, and turns amber
and pulses if the connection drops — which is the moment worth knowing about, because the screen has
stopped updating itself. Reconnection is automatic and replays what was missed.

What each account is told is filtered by **permission**, per event: a sales clerk sees the invoice and
the stock movement, and is never told to go buying.

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
| `notifications`, `notification_reads` | Alerts the server raises, and who has read them |
| `stock_shortfalls` | Stock sold that was not on the shelf, until a delivery covers it |
| `sequences`, `settings` | Document numbering and configuration |

Full definitions with indexes are in [backend/app/schema/](backend/app/schema), split
into numbered parts that the server runs in filename order on startup:
[security](backend/app/schema/010_security.sql),
[master files](backend/app/schema/020_master_files.sql),
[sales](backend/app/schema/030_sales.sql),
[purchasing](backend/app/schema/040_purchasing.sql),
[ledger](backend/app/schema/050_stock_ledger.sql),
[archive](backend/app/schema/060_archive.sql),
[notifications](backend/app/schema/070_notifications.sql),
[replenishment](backend/app/schema/080_replenishment.sql).

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
| Reports | `/api/reports/dashboard`, `aging`, `sales`, `purchases`, `inventory`, `expiring`, `depleted`, `refill`, `movers`, `collections`, `inactive-customers` |
| Notifications | `GET /api/notifications`, `/unread-count`; `POST /api/notifications/read`, `read-all` |
| Live | `GET /api/events` — one long-lived Server-Sent Events stream per signed-in browser |
| Admin | `/api/admin/users`, `roles`, `sessions`, `audit`, `stats` |
| Maintenance | `GET /api/maintenance/status`, `purge-preview`, `restore-preview`, `backups/{name}/download`; `POST /api/maintenance/backup`, `backups/import`, `restore`, `retention`, `check`, `compact`, `purge`; `DELETE /api/maintenance/backups/{name}` |
| Archive | `GET /api/archive/summary`, `/api/archive/{kind}`, `/api/archive/{kind}/{number}`, `/api/archive/moves/by-item/{code}` |
| Desktop | `GET /api/desktop`, `/api/desktop/download` |

---

## Project layout

```
start.bat               one-click start (creates the venv on first run)
start-desktop.bat       runs the desktop edition from source
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
    events.py           the live channel: in-process bus, fanned out over SSE
    notifications.py    the alerts the server raises for itself, and the sweep
    replenishment.py    stock sold that was not there: recording and closing it
    schema/             the relational schema, in numbered parts run in order
                        000 conventions, 010 security, 020 master files,
                        030 sales, 040 purchasing, 050 ledger, 060 archive,
                        070 notifications, 080 replenishment
    routers/            auth, stock, customers, suppliers, invoices, purchases,
                        returns, collections, reports, admin, notifications,
                        events

frontend/               browser application, no build step
  index.html            the shell
  css/app.css           the whole stylesheet, light and dark
  js/
    api.js              fetch wrapper, 401 and 409 handling
    live.js             the one EventSource, and the subscriptions on it
    notify.js           the bell: badge, panel, and the alerts feed
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

desktop/                the desktop edition (Tauri v2) - see desktop/README.md
  package.json          the Tauri CLI, dev-only
  app-icon.svg          source for the generated icon set
  ui/                   the launcher, and the only page the shell bundles
  src-tauri/
    tauri.conf.json     product name, identifier, bundle targets, CSP
    capabilities/       IPC permissions - the launcher window only
    src/lib.rs          config, health probe, server process, tray

releases/               the published desktop installer, handed out by Settings
                        (gitignored - built output, tens of megabytes)

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
| `IMS_BACKUP_DIR` | `backups/` | Where backups are written |
| `IMS_DESKTOP_DIR` | `releases/` | Where the desktop installer is published for Settings to hand out |
| `IMS_BACKUP_ZIP_LEVEL` | `1` | Deflate level; `6` is ~25% smaller and ~3× slower |
| `IMS_BACKUP_DAYS` | `7` | How long an automatic backup is kept |
| `IMS_BACKUP_MANUAL_DAYS` | `14` | Manual window, until the office chooses one on the screen |
| `IMS_BACKUP_KEEP_MIN` | `3` | Newest backups kept regardless of age |
| `IMS_BACKUP_HOURS` | `24` | Hours between automatic backups; `0` turns them off |
| `IMS_HOST` / `IMS_PORT` | `0.0.0.0` / `8080` | Bind address and port |
| `IMS_COMPANY` | `Marina Trading` | Name shown in the header and page titles |
| `IMS_SESSION_HOURS` | `12` | How long a sign-in lasts |
| `IMS_PBKDF2_ROUNDS` | `260000` | Password hashing work factor |

---

## Backups

**The server backs itself up.** While it is running it takes a copy every 24 hours, and it takes one
at startup if the newest is already older than that — so a PC switched on for an hour a day still
gets its daily backup. The button on **Backup & Database** takes one on top of that.

Backups go in **`backups\`, at the top of the project**, next to `start.bat`. Each is a **zip**
holding the whole database, named with the date it was taken:

```
ims-8-31-2026.zip                the one you took
ims-8-31-2026-auto.zip           the daily one
ims-8-31-2026-prerestore.zip     saved just before a restore
ims-8-31-2026-2.zip              a second one taken by hand the same day
```

Just the date, because that is what the file is: the database as it stood that day. The list on
screen shows the exact minute.

On this office's 1,186 MB database a backup comes out at **387 MB in about 6 seconds**.

They are taken with SQLite's own online backup API, which copies a live database safely — nobody has
to be out of the system, which is the one thing the DOS Monday-to-Saturday floppy rotation always
demanded.

### Getting a backup off the server

**You are probably not sitting at the server.** It is a PC in the corner of the office; you are at a
counter machine reaching it over the network. A file on its disk is not one you can put on a memory
stick or take home.

So every backup in the list has a **Download** button, and pressing **Back up now** downloads the
new one to whatever machine you pressed it from. It arrives as an ordinary browser download — one
zip, about a third of the size of the database.

**This works on a phone**, and the screen is built for it: the backups show as a list rather than a
table, so Download, Restore and Delete are under your thumb instead of off the side of a table you
would have to scroll sideways. The file lands wherever that phone puts downloads — the Files app on
an iPhone, the Downloads folder on Android — and can be shared on from there. Mind the size on mobile
data: a backup of a 1.2 GB database is around 387 MB.

The server keeps its own copy regardless. If the download fails halfway, the power goes off, or the
network drops, nothing is lost: press Download again. And a backup interrupted while it was being
written is left as a `.part` file and cleared away at the next startup, so a half-written file is
never mistaken for a backup you could restore from.

> **A backup that only exists on the server does not survive that PC failing.** Download one now and
> then and put it somewhere else — a memory stick, another machine, the `\\server` share.

### Upgrading from an earlier version

Backups used to be plain `.sqlite` files in `database\backups`. On the first start after this change
they are **moved into `backups\` automatically**, and they keep working: they are still listed, still
downloadable, and still restorable. Only new backups are zipped.

### What is kept

There are **two windows**, because the two kinds of backup mean different things. The daily rotation
is the machine's own housekeeping; a backup somebody took by hand was taken for a reason, usually
just before something risky, and should outlive it.

| Rule | Value | Set where |
| --- | --- | --- |
| Automatic backups are deleted after | 7 days | `IMS_BACKUP_DAYS` |
| Backups taken by hand are deleted after | **7 or 14 days, your choice** | Backup & Database screen |
| ...but never fewer than this many survive | 3 | `IMS_BACKUP_KEEP_MIN` |
| Hours between automatic backups (`0` turns them off) | 24 | `IMS_BACKUP_HOURS` |

The manual window is a choice, not a setting file: pick **7 days** or **14 days** on the maintenance
screen and it is remembered in the database. Shortening it applies immediately rather than at the
next backup. `IMS_BACKUP_MANUAL_DAYS` is only the answer until somebody chooses.

The floor is the important half. Age alone would mean an office that closed for a fortnight came back
to a backup folder that had tidied itself empty — so the three most recent always survive, however
old they are, whichever kind they are.

### Bringing one back from a device

**Import backup**, next to *Back up now*, is the other half of Download. Pick a backup file off this
PC, a memory stick, or a phone, and it goes onto the server and into the list — ready to restore
from. Use it after rebuilding the office PC, or when the only copy left is the one you downloaded.

Both shapes are accepted, because both are shapes this system has handed out: the **zip** it writes
now, and a bare **`.sqlite`** from an older version. It decides which by looking inside the file
rather than at its name, so a file somebody renamed still works.

Nothing is trusted. The upload is checked before it becomes a backup — a real database, passing its
integrity check, with the tables this version needs — and anything else is refused with the reason,
leaving nothing behind. A file already named like one of ours keeps its name, so a backup downloaded
last week and imported today is the same file it was; anything else is filed under today's date and
marked `-imported`.

### Deleting one

Every backup has a **Delete** next to Restore, for the times retention does not fit — a copy taken
before something that turned out fine, a `-prerestore` nobody needs, a folder filling a small disk.
It asks first, says how much space it frees, and if it is the last backup on the server it says that
too. A copy you have already downloaded is not affected.

### Putting a backup back

**Backup & Database → the backups list → Restore.** It shows what the backup holds against what is in
the database now, row counts side by side, so the only question that matters — what changes — is
answered before anything is touched. Confirm by typing `RESTORE`.

Three things stand between a mistaken click and a bad day:

1. the confirmation has to be typed, as it does for a purge;
2. the file is opened and verified first — a damaged or truncated backup is refused, and one missing
   tables this version needs is refused as too old;
3. **a copy of the current database is taken first**, tagged `-prerestore`, so the restore itself can
   be undone by restoring that copy. It appears in the list as *before a restore*.

Everyone is signed out, including whoever pressed the button: the accounts and sessions come from the
backup as well. Sign in again afterwards. Note that a restore also rolls back the manual-retention
choice, since that lives in the database too.

**Budget the disk.** Seven daily copies of a 1.2 GB database is roughly 8.5 GB. The maintenance
screen shows the running total and the free space beside it; if that is tight, lower `IMS_BACKUP_DAYS`
rather than switching the schedule off.

### Copying them off automatically

Downloading by hand covers the day you think of it. For the days you do not, a scheduled task:

```bash
robocopy backups "\\server\ims-backups" /MIR
```

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
