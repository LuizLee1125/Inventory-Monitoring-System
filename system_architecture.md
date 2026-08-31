# System architecture notes

Design decisions that are not obvious from the code, kept so a later change
does not have to rediscover them.

## The schema is a folder, not a file (v0.3)

`backend/app/schema.sql` was one 490-line document covering security, masters,
sales, purchasing, the ledger and the archive. It is now
`backend/app/schema/*.sql`, run in **filename order** by `db.init_db()`.

Rules for changing it:

- **Add a numbered part, do not revive the single file.** The numbers are
  three-wide with gaps (000, 010, 020, …) so a new part slots in without
  renumbering; fixed width keeps the plain sort correct once there are ten.
- **A foreign key never crosses a part.** The parent table is declared in the
  same file as the child. SQLite does not enforce FK targets at `CREATE` time,
  so a cross-file reference would work and then break the day someone reorders
  the folder — the invariant is what makes the order safe to change.
- **Everything stays `IF NOT EXISTS`.** `init_db()` runs on every startup, on a
  live database.
- `init_db()` raises on an empty schema folder rather than building an empty
  database, and names the failing file on a SQL error. Both exist because a
  seven-file schema fails less legibly than a one-file schema did.

### Adding a column to an existing table

`CREATE TABLE IF NOT EXISTS` builds a missing table and does **nothing at all**
to a table that already exists. So a column added to a schema part would reach a
new database and never reach the office's, and the failure would arrive one
query at a time, months later, as `no such column`.

`init_db()` closes that gap. After running the parts it builds the same schema
into an in-memory database — the *reference* — and compares `PRAGMA table_info`
table by table:

- a column the parts declare and the database lacks is added with
  `ALTER TABLE ... ADD COLUMN`, carrying its type and `DEFAULT` across, so
  existing rows get the default rather than NULL;
- a column the database has and the parts no longer declare is **reported and
  kept**. It may hold the only copy of something, and nothing is broken by its
  being there;
- `init_db()` returns what it added; `main.py` and `migrate.py` print it.

Comparing against a real in-memory database beats parsing the `.sql` files —
SQLite has already done the parsing, and `PRAGMA table_info` answers in exactly
the shape the comparison needs.

The one thing this cannot do is add a `NOT NULL` column with no `DEFAULT`;
SQLite refuses, correctly, because there is no value for the existing rows.
`init_db()` raises with that explanation rather than letting SQLite's own
message stand. **Give every new column a default.**

It is still not a full migration framework: no versioned up/down steps, no
`schema_version` table, and renaming, retyping or dropping a column is a manual
job. Adding one — which is what actually happens — is handled.

## Reading the data (`backend/dump_db.py`)

Nothing in `database/` can be opened in an editor — the database, the backups
and the journal files are all binary — which makes "just look at what is
actually in there" harder than it should be. `dump_db.py` projects each
database into `database/plaintext/<name>/` as `.sql` files plus
`000_schema.sql`, and describes the journal files in `_journal.txt`.

### Text is not the same as readable

The first version wrote one `INSERT` per line with the full column list on every
one. That is text, and it is unreadable: 1.1 MB files, 2,000 lines, individual
lines 650 characters wide, most of every line being the same 27 column names
again. Four rules make the difference, and a change to the format should keep
all four:

- **200 rows per file** (`--rows-per-file`). Over that, a table becomes a folder
  of numbered chunks — `invoices/0001-0200.sql` — and no file exceeds ~70 KB.
- **The column list once per statement**, not once per row. Rows are grouped 50
  to an `INSERT ... VALUES` (SQLite's own limit is 500).
- **Every row wrapped at 88 columns.** Nothing runs off the side. A single value
  longer than that overflows on its own line rather than being split, because
  splitting it would corrupt it.
- **A numbered column legend at the head of every file**, so a value can be
  placed by counting instead of scrolling back to the `INSERT`.

The output stays valid SQL and replays into an empty database, which is worth
keeping as a correctness check on the quoting. It is not why the files exist.

It is **not** a backup — `POST /api/maintenance/backup` is, and it uses
SQLite's own copy API. Consequences of being a viewer rather than a backup: it
caps at 2,000 rows per table by default (`stock_moves` holds 2.5 million),
skips `sessions`, and redacts `users.password_hash` unless `--include-secrets`
is passed. The output folder is git-ignored with the rest of `database/`; it
holds real customer records.

### Reading a database must not modify it

This is the one genuinely sharp edge, and the first version of the script got
it wrong: it left a `-wal` and a `-shm` beside a backup that had neither.
`mode=ro` is not sufficient. Reading a WAL database needs the `-shm` index, and
SQLite creates one when it is missing — read-only applies to the *content*, not
to the files around it.

Two rules keep it honest, and both matter for backups, which are supposed to be
inert:

- open with `immutable=1` when there is no outstanding log, which makes SQLite
  skip the WAL machinery entirely. A database that *does* have an
  un-checkpointed log cannot be opened read-only at all by the first connection
  to reach it — recovering the log is a write — so that case opens normally;
- record which journal files existed before opening and delete exactly the ones
  this run created, never any that were already there.

`_journal.txt` is also written *before* the database is opened. Written after,
it would describe files the reader had just made.

### What `_journal.txt` can and cannot say

A `-wal` holds raw 4 KB database pages and a `-shm` holds a platform-specific
shared-memory index. Neither has a text form, and no amount of work will give
them one. What the report does give is the WAL header (page size, checkpoint
sequence, salt), the number of live frames — those whose salt still matches the
header, later ones belong to an already-checkpointed generation — and how many
of them are commit records. That answers the only question worth asking of a
`-wal`: how much committed work is sitting in the log rather than in the
database file. The `-shm` gets a description and nothing more, because there is
nothing in it that is not derived from the `-wal`.

## Role-shaped UI (added with the sales account, v0.3)

There are now **two independent filters** on what a signed-in user can see, and
they answer different questions:

| Filter | Lives in | Question it answers |
| --- | --- | --- |
| `permissions` | `backend/app/security.py` → `ROLES` | *May this account do it?* Enforced on every API call by `Depends(require(...))`. |
| `ROLE_SCREENS` | `frontend/js/app.js` | *Is this account shown it?* Enforced in `buildNav()` and `guard()` only. |

`ROLE_SCREENS` exists because the DOS system worked this way: `ACCESMNU` chose
which menu program opened, and a sales clerk who could read the same files as
everyone else still only ever saw `MNUSO.PRG` — two options and an exit. A role
listed in `ROLE_SCREENS` sees exactly those path prefixes; a role that is
absent sees everything its permissions allow, which is how every other role
still behaves.

**It is not a security boundary.** Anything added there must already be denied
by permissions if the denial matters. When adding a screen for such a role,
three places have to agree or the UI contradicts itself:

1. `ROLE_SCREENS` in `frontend/js/app.js` — the nav entry and the route guard.
2. `ROLE_REPORTS` in `frontend/js/views/reports.js` — the report picker, if the
   screen is a report. A report in the picker but not in `ROLE_SCREENS` gives a
   dropdown entry that lands on "Not allowed".
3. `ROLE_MENU` in `frontend/js/views/home.js`, if the role has its own menu.

`ACCOUNT_SCREENS` (also `app.js`) is the exception to all of that: screens that
belong to the person rather than to the business — `/settings` today. They are
allowed for every signed-in user whatever their role shows them, which is why
they sit in their own list instead of being repeated in each role's. A screen
belongs there only if it would be right for *every* role, present and future;
anything about the business goes through `ROLE_SCREENS`.

## Role menus on the home screen

`ROLE_MENU` (`frontend/js/views/home.js`) gives a role the DOS menu it used to
open, in place of the main menu's three panels. When a role has one:

- `render()` draws `menuKpis()` and one panel **per option**, in a two-column
  `.home-panels.two` grid, and skips the aging fetch — the role has no
  receivables screen to click into.
- `bindShortcuts()` binds **only** that menu's letters. The main menu's A/B/C
  (Stock, Customer, Supplier File) do not apply: on the sales screen A is Print
  Sales Invoice, because that is what `MNUSO.PRG` printed on line 9.

`ROLE_MENU.options` is a **key binding table, not a drawing**. The first cut
rendered it as a boxed list of links, which sat beside a sidebar containing the
same links and filled half the screen doing nothing. Each option now gets a
panel that does its work — recent invoices straight to the print document,
recent deliveries straight to the item — with the DOS letter on the panel
heading and a footer link to the full screen. If a third option is ever added,
give it a panel, not a row.

Two panels cannot fill a wide screen the way three can, so `.home-panels.two`
sizes its panels to their content (`align-items: start`) with `max-height:100%`
as the cap. Without that, four rows stretch down the whole viewport.

The legacy programs behind the current sales menu are `SIFYL`/`SIFYLP` (A) and
`STKPURCH` (B).

## The design scale (v0.3)

`app.css` opens with a block of tokens, and **every rule below it uses them**.
That is the whole discipline, and it is worth stating plainly because the
stylesheet spent a long time not doing it: it had accumulated nineteen font
sizes (10.5 … 29px), eight weights (including 550, 650, 660 and 750, which Inter
does not have and the browser silently rounded), and spacing at 7, 9, 11, 13,
15, 18, 22 and 26px. Each value was reasonable on the screen it was written for.
Together they were the reason two screens never quite lined up.

| Tokens | Steps |
| --- | --- |
| `--fs-2xs … --fs-3xl` | 11, 12, 13, 14, 16, 20, 26, 32 |
| `--fw-normal … --fw-bold` | 400, 500, 600, 700 |
| `--lh-tight / snug / normal` | 1.2, 1.35, 1.5 |
| `--sp-1 … --sp-10` | 4, 8, 12, 16, 20, 24, 32, 40 |
| `--radius-sm / --radius / --radius-lg / --radius-full` | 6, 10, 14, 999 |

When something needs a size that is not on the scale, the answer is almost
always the nearest step, not a new token. The two deliberate exemptions are
documented where they live: `.print-doc` and the `.doc-*` rules, which are
measured against a sheet of paper and the boxes on a pre-printed form rather
than against the screen, and icon glyph sizes, which are not text.

## Motion

Three durations and two curves (`--dur-fast` 110ms, `--dur` 170ms, `--dur-slow`
240ms; `--ease`, `--ease-out`), and one rule for choosing: **anything that
responds to a pointer uses `--dur-fast`; anything that appears uses `--dur`.**

There are seven keyframes for the whole application and they share a vocabulary
on purpose — things that appear next to their trigger scale out of it
(`pop-in`, with `transform-origin` set at the call site so a dropdown grows from
the control that opened it), things arriving from elsewhere travel a short
distance (`slide-in`, `page-in`, `rise-in`, `modal-in`), and only an error
shakes. A new animation should be one of these before it is an eighth.

Two things that are easy to get wrong here:

- **Theme changes are transitioned, layout never is.** A named list of surfaces
  cross-fades `background-color`, `border-color` and `color` over `--dur-slow`,
  so switching theme is a wash rather than a flash. Adding `all` to that
  transition would animate every layout property with it and make the whole
  interface wobble.
- **`prefers-reduced-motion` is one block at the end of the file**, and it sets
  durations to `1ms` rather than `none` so `animationend` and `transitionend`
  still fire — nothing waiting on one is left hanging. Hover *displacements*
  (`translateY`, `translateX`, `padding-left`) are separately set back to their
  resting value, because an instant jump under the pointer is exactly what that
  setting is asking to avoid.

The page-enter animation is driven by an `.entering` class that `mount()` adds
in `app.js`. It is added once and left on: `clear()` has already removed every
child, so whatever `render()` appends is a new element and animates on
insertion — including parts that arrive late, after their fetch resolves.

## Theming

The stylesheet carried a complete `:root[data-theme="dark"]` palette for a long
time and **nothing ever set that attribute**, so the theme followed the OS and
could not be changed. `frontend/js/theme.js` is the missing half.

Three modes, and `system` is deliberately not "write out the current OS value":

| Mode | What it does |
| --- | --- |
| `system` | removes `data-theme` entirely, so the `prefers-color-scheme` block wins and the theme keeps following the OS as it changes |
| `light` | `data-theme="light"`, which that block explicitly excludes |
| `dark` | `data-theme="dark"` |

This is why the dark rules are written as
`:root:not([data-theme="light"])` inside the media query. Any new themed
property needs a value in all three places — bare `:root`, the media query, and
`:root[data-theme="dark"]` — or it will be right in two themes and wrong in the
third.

**There is a duplicated copy of `apply()` inlined in the head of
`index.html`.** It has to be there: a module cannot run before the first paint,
and without it a dark-mode user gets a white flash on every load. If the modes
change, that copy changes with them.

The setting is `localStorage`, so it is per-browser and per-device, not per
account. That is a choice, not an oversight — it is a property of the screen
someone is sitting at, and the same clerk on the warehouse terminal and the
office PC will want different answers.

## Printing

`window.print()` on a normal screen prints that screen; `@media print` in
`app.css` only strips the chrome. Anything that is meant to be a **document**
gets its own route and a `.print-doc` block, and the print rule
`.page:has(.print-doc) > :not(.print-doc)` hides everything else on the page.

The sales invoice is the first of these (`views/printInvoice.js`, route
`/invoices/print/:id`). `.print-doc` is deliberately outside the theme — white
sheet, black text, in dark mode too — because it is a preview of the paper that
gets signed. If a second document is added (a purchase order, a statement of
account), follow the same shape rather than adding print rules per screen.

Note that `GET /invoices/{no}/print` existed unused for a long time; check for
an endpoint like it before adding one.
