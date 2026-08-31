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

## The sales chart (`views/dashboard.js`)

Hand-drawn SVG, because the application ships **no JavaScript dependencies at
all** and one bar chart is not the reason to start. It reads the same theme
tokens as everything else, so it follows light and dark with no JS.

**What is on hover is the point of the chart.** Bars alone answer only "was this
month bigger than that one". The tooltip carries what a reader wants next and
what the bars cannot show: the amount, the invoice count, the **average
invoice** and the **change on the previous month** — derived figures, not a
restatement of the bar's height. Printing all of that on the chart would be six
numbers per bar and no chart.

Four things that are easy to get wrong:

- **The hit area is a transparent full-height column, not the bar.** A lean
  month is six pixels tall, and hovering it should not mean hitting six pixels.
- **The highlight is a band behind the column, not a lighter bar.** A short bar
  has almost no area to light up; the band says which column is being read even
  when its value is nearly zero.
- **The tooltip anchors to the bar's top, not the column's**, or a month that
  barely registers gets its tooltip parked at the top of the chart. When there
  is no room above the bar it flips to just below that edge.
- **`:has()`, not `~`.** The hit rect is the last child of the group, so a
  sibling combinator can never reach the band drawn before it. And focus is a
  `stroke`, not an `outline`: `outline` on an SVG shape is not dependable.

The rise/fall marker is a **drawn arrow**, `--icon-arrow-up` masked by
`.trend-arrow`, for the same reason the magnifier stopped being a `⌕`: `▲` and
`▼` are solid triangles rather than arrows, and they render at a different
weight and size in every font that might be installed. There is one icon — the
fall is the same mark turned 180° by the row's class — so the two directions
cannot drift apart, and `background: currentColor` means the arrow is green or
red with the figure beside it without being told which.

Every bar is `tabindex="0"` with an `aria-label` carrying the same figures, and
the tooltip opens on focus as well as hover — so the chart is readable without a
mouse, which the previous `<title>` tooltip never was.

## Loading placeholders

Every screen fetches before it can draw. There are two moments to cover and they
are covered differently.

**The page-level placeholder is the router's job, not the view's.** `mount()` in
`app.js` appends `pageSkeleton()` and removes it again the instant the view
appends anything of its own — a `MutationObserver` on the container watches for
a child that is not the placeholder. That means a view needs no code at all to
get one, including views added later, and there is no way to forget.

Two details keep it honest:

- **The render promise's `finally` is the safety net.** A view that throws, or
  that legitimately renders nothing, would otherwise leave a placeholder up for
  something that is never coming.
- **`skeleton` may be a function of the route parameters.** One module serves
  both `/stock` and `/stock/:code`, which are different shapes, so `stock.js`
  exports `(params) => params.code ? 'detail' : 'list'`. A plain string is fine
  for a module with one screen.

Shapes are `list` (toolbar + table), `stats` (figures, then cards), `detail` and
`form`. They exist to stop the layout jumping when the data lands, so the right
shape matters more than the right number of rows.

**The in-list placeholder is separate.** A list screen renders its toolbar
immediately and refetches into a card below it on every filter, search and page
change — so the page-level placeholder is long gone by the second fetch.
`skeletonTable(columns, rows)` fills that card. It replaced
`<div class="empty">Loading…</div>`, which collapsed the card to one line of
text and made the whole page jump twice per keystroke.

Bar widths vary per row and are **stable for a given row index** — a column of
identical grey rectangles reads as a broken image rather than as text. Under
`prefers-reduced-motion` the sweep is dropped and the flat tint remains, which
still says "a table is coming".

## Backups

Retention is by **age with a floor**, not by count. It used to keep the newest
14 files whatever their dates, which answers the wrong question: what an office
needs to know is "how far back can I go", and a count only answers that if you
also know how often backups were taken.

- `BACKUP_KEEP_DAYS` (7) — how long an **automatic** backup lives. Fixed: the
  daily rotation is the machine's own housekeeping.
- **The manual window is the office's choice, 7 days or 14**, and it lives in
  the `settings` table rather than in the environment. An environment variable
  is the right home for "where is the database"; this answer belongs to the
  business and should follow it onto a new PC. A stored value that is no longer
  one of the offered choices falls back rather than being honoured — the choices
  are what the screen can show, and an unshowable setting is one nobody can
  correct.
- `BACKUP_KEEP_MIN` (3) — **the floor, and the important half.** Age alone would
  mean an office that closed for a fortnight came back to a folder that had
  tidied itself empty. That is the one state a backup system must never reach,
  and it is the state a pure age rule reaches on its own.
- `BACKUP_EVERY_HOURS` (24) — `0` disables the schedule and leaves the button.

A retention window only means something if the window is full, so backups are
now **taken on a schedule** rather than only when somebody presses the button.
Two decisions there:

- **A timer, not a fixed hour.** "Every night at 2am" means never on a PC that
  is switched off overnight. `backup_is_due()` asks whether the newest backup is
  older than the interval, the schedule asks that every 15 minutes, and the
  lifespan asks it once at startup — so a machine switched on at nine gets its
  backup shortly after nine.
- **On a worker thread.** `asyncio.to_thread`, because copying 1.2 GB takes
  several seconds and doing it on the event loop would stop the office working
  for exactly as long as the backup exists to avoid. `db.get_connection()` is
  thread-local, so the worker opens its own connection and nothing is shared.

A scheduled backup that fails is logged and skipped; the next tick tries again.
It must never take the server down, and the maintenance screen goes on showing
the real last-backup time rather than a comforting one.

### The administrator is not at the server

This is the fact the whole design turns on. The server is a PC in the corner of
the office; the person who presses "Back up now" is at a counter machine on the
LAN. A file written to the server's disk is one they cannot put on a memory
stick, cannot take home, and cannot reach at all if that PC is the thing that
has gone wrong.

So a backup is a **zip**, and there is a **download** for every one of them —
`GET /maintenance/backups/{name}/download`, a plain `<a download>` in the table
so the browser handles progress and where the file lands. Pressing "Back up now"
downloads the new one automatically: the click should end with the file on the
machine that made it.

**And "another machine" includes a phone.** The backups are a `<ul>`, not a
`dataTable`, and that is the whole reason: as a table the three actions sat in a
seventh column 959px into a 341px handset window — present, and reachable only
by scrolling a table sideways inside a page, which in practice means nobody
finds them. As a list the name and its details stack, and below 560px the
buttons go full width. This is the one screen that has to work on a handset,
because backing up is what somebody does from wherever they happen to be.

Three consequences worth keeping:

- **The server keeps its copy either way.** The download is a convenience on top
  of a backup that already exists, so a dropped connection or a power cut
  mid-transfer costs nothing but the click.
- **The zip is written to `.part` and renamed at the end.** The rename is the
  only atomic step, so a power cut leaves a file nobody will mistake for a
  backup rather than a truncated `.zip` that looks like one. `tidy_backup_dir()`
  sweeps them at startup.
- **Level 1 deflate, not the default 6.** Measured on this office's own 1,186 MB
  database: level 1 gives 387 MB in 6 seconds, level 6 gives 298 MB in 19. The
  extra 89 MB is not worth thirteen seconds of somebody watching a button.

`BACKUP_DIR` moved to `backups/` at the top of the project, out of `database/`.
It is the one folder somebody has to find in a hurry, possibly over the phone,
and `backups` next to `start.bat` is a folder you can talk a person to.
`tidy_backup_dir()` moves anything left in the old location on startup — with
`rename`, which within one drive moves no bytes and needs no free space.

**Both formats are listed.** New backups are zips; an office upgrading to this
version has a folder of plain `.sqlite` copies that are perfectly good backups
of its real business. `open_backup()` yields the database inside either — a temp
extraction for a zip, the file itself for a `.sqlite`, which must not then be
deleted on the way out. Hiding somebody's existing backups because the format
changed would be the worst possible way to introduce a new one.

### The name reads as a date, so the order comes from the clock

`ims-8-31-2026.zip` — the date the way the office writes it and nothing else,
because the file's job is to still mean something in somebody's Downloads folder
a week later, and a time of day was noise there. `-auto` and `-prerestore` mark
the kind; a second backup on the same day becomes `ims-8-31-2026-2.zip`. Built
by hand rather than with `strftime`: dropping the leading zero is `%-m` on Linux
and `%#m` on Windows, and neither is portable.

**That name does not sort**, and the list used to be ordered by sorting it.
`10-1-2026` comes before `8-31-2026` as text, so October would have been filed
as the oldest backup in the folder. `_backup_files()` now orders by modified
time, which is what retention and "last backup" already read — so the whole
feature agrees with itself, and files from both naming schemes interleave
correctly.

### `HEAD` has to be registered, not assumed

The download button asks for the headers before pointing the browser at the
file, so a backup that is no longer there is reported in the page instead of
failing as "Failed - No file" in the downloads tray, which says nothing and
looks like a bug in the application.

That probe only works because the route is registered `methods=["GET", "HEAD"]`.
Starlette did **not** add HEAD for the plain `@router.get`, so the probe fell
through to the `/api/{rest:path}` catch-all and answered 404 for every backup —
turning a safety check into an outage. It was caught by testing the probe
against a file that definitely existed, which is the test worth remembering:
check the success path of an error handler, not just the error path.

### A screen newer than its server must still say so

Workstations hold this page open for days, so it is routinely a version ahead of
the server. The first cut of the retention picker was **hidden** when the server
reported no policy, which is the worst of both: the documentation says the
setting exists, the screen shows nothing, and the reason sits in the middle of a
paragraph of body text where it reads as prose.

It is now always drawn, disabled, with the reason on the control itself and a
warning banner above the card. **A control that is present and explained beats a
control that has vanished** — the second one sends somebody hunting.

The kind tag falls back to reading the filename when the server sends no `kind`,
and reads it as a **suffix on the stem** (`/-auto$/`) rather than as a substring.
`ims-8-31-2026-auto.zip` and the older `ims-20260831-092119-auto.sqlite` both
resolve, and a name that merely contains the word cannot be mislabelled.

The kind is carried in the filename — `-auto`, `-prerestore`, or neither for one
taken by hand. That suffix is the whole mechanism behind the "By" column and
behind which window a file is pruned by: there is no database table of backups,
and the filesystem already knows. `dump_db.py` globs `ims-*.sqlite`, so it still
finds all of them.

**Names must be unique, and the second stamp is not enough.** Two backups can
land inside one second — taking a pre-restore copy immediately before a restore
does exactly that — and the second write silently overwrote the first. In the
restore path that meant the safety copy landing on top of the file it was about
to restore from, so the restore put back the database it was supposed to be
replacing. `take_backup()` now appends `-2`, `-3` on collision, **before** the
kind, so `-auto` and `-prerestore` stay at the end of the stem where everything
looks for them.

### Restoring

The one action here that can lose work, so most of it is the safety.

**The copy goes through SQLite's backup API, not through the filesystem.**
`source.backup(live_connection)` writes the backup's pages into the database the
server already has open. Swapping the file on disk would leave every other
thread's connection pointing at something that no longer exists; this way there
is nothing to reopen and nothing to coordinate.

The order matters and each step is there for a reason:

1. **Typed confirmation** — `RESTORE`, as a purge needs `PURGE`.
2. **Verify before overwriting.** `inspect_backup()` opens the file read-only
   and immutable, runs `integrity_check`, and compares its tables against
   `db.reference_schema()`. A truncated file or one from an older system is
   refused while the database is still untouched.
3. **Safety copy first**, tagged `-prerestore`, so the restore is itself
   undoable. Plus an explicit guard that it did not collide with the source —
   unreachable now, but the failure it catches is silent.
4. **`db.init_db()` afterwards.** A backup can predate a schema change, so the
   restored database is brought up to what the running code expects before
   anything reads it.
5. **Sessions cleared, then the audit entry.** In that order, and after the
   restore: an entry written beforehand would have been overwritten by the very
   next step, and every session in the database now belongs to whenever the
   backup was taken, so nobody is meaningfully signed in.

The name from the browser is matched against the directory listing rather than
joined onto a path, so `../../etc/passwd` never becomes a path at all.

A restore also rolls back the manual-retention choice, because that lives in the
`settings` table. That is consistent rather than surprising once you know where
the setting lives, and it is in the README.

## The sign-in screen

Two panels: the name of the place on the left, the way in on the right. It was a
single 380px card centred on a gradient, which said nothing about what the
system is — and this is the first screen anyone sees.

- **The brand panel keeps its own deep-blue palette in both themes.** It is a
  printed cover, not a surface of the application; a dark-mode version of it
  would only make it agree with less. It drops out entirely below 1000px, where
  there is no room for it and the form should have the window.
- **The ruling in the panel is a mask, not a picture.** The reference puts a
  photograph of its building there. This business has no such photograph, so the
  panel carries faint ledger ruling instead, faded out with a radial mask — the
  same idea as the DOS system's character grid, at the size of a page. It keeps
  the panel from being a flat rectangle without inventing an asset.
- **The headline is sized to the panel, not to the type scale.** `clamp()` on
  viewport width: it is display lettering on a cover with a whole column to
  fill, which is the one place the scale in `app.css` does not apply.

### The rejected-sign-in banner

`showLoginError()` in `app.js` drives three states, and they are three because
arriving and being told the same thing again are different events:

| State | When | What plays |
| --- | --- | --- |
| `arriving` | the banner was hidden | `error-in` — fades and drops into place |
| `again` | it was already on screen | `shake` — it cannot announce itself by fading in, because it never faded out |
| `leaving` | ten seconds later | `error-out`, at 480ms |

Three things that are easy to get wrong here:

- **Adding a class does not replay an animation.** The browser coalesces the
  removal and the addition into one style recalculation and sees no change.
  Reading `offsetWidth` between them forces the flush that makes it a change.
- **`animationend` is the signal, a timer is the guarantee.** A backgrounded tab
  runs no animation frames, so the event may never arrive — and a banner that
  fails to leave sits there until the page is reloaded. Same fallback as the
  dropdown's exit animation.
- **A fresh error can land mid-fade**, and clears `leaving` on its way in. The
  dismissal handler checks for that class before hiding, or the shake it plays
  would end on the pending listener and hide a banner just raised again.

`error-out` is the one animation slower than `--dur-slow`. Everything else in
the application answers something the user just did, where a long duration is
only a wait; this one starts on its own after ten seconds, and at 240ms the
banner did not fade so much as vanish.

The banner has **no rule down its leading edge**. It had the 3px one every
framework's alert component ships with, and next to a form of soft-cornered
wells it read as pasted in from elsewhere. The badge already says what kind of
message it is.

Two things on the form side exist for reasons specific to this office:

- **The Caps Lock warning.** Every user name here is upper-case, carried over
  from the DOS access file, so people hold Caps Lock to type one and then type
  their password with it still down. Without the warning the rejection that
  follows is a mystery and becomes a phone call.
- **`showLogin()` re-masks the password and clears the warning.** A password
  left revealed must not still be on screen for whoever signs in next, and the
  warning belongs to the attempt that raised it.

## Form controls

Fields are **filled wells**, not outlined boxes: `--field-bg` with a hairline
`--field-border` at `--radius-field` (12px), and a ring on focus. Before this
they were `--surface` inside a 1px `--border-strong` at 6px, which drew a grid
of hard rectangles across every form and was most of what made these screens
look unrelated to the rest of the family. Buttons share `--radius-field` so a
button and an input in one toolbar agree with each other.

**The global search is a pill; in-page filters are wells.** They do different
jobs and the shape says which before the placeholder is read. Both take the same
fill and hairline, so they still belong to one set.

### Never the `background` shorthand on anything with a background-image

`background: var(--surface)` resets `background-repeat`, `-position` and `-size`
along with the colour. The focus rule used to say exactly that, which wiped
`no-repeat` off the select chevron and **tiled it across the control** the
moment it was focused. Use `background-color`.

### Dropdowns are drawn here, not by the operating system

`select()` in `ui.js` returns a wrapper, not the `<select>` — but one that
stands in for it completely: `.value` reads and writes through, `.options`,
`.selectedIndex`, `.selectedOptions` and `.disabled` forward, and `change`
bubbles out of the real control inside. So `readForm()` still finds it by name
and every caller stayed as it was. `append`, `appendChild` and `add` route
`<option>` children to the real select, because `stock.js` fills its division
list from a fetch that resolves after render.

**Anything a caller reaches for on a `<select>` belongs in that forwarding
block.** Two were missed on the first pass and both surfaced as bugs rather
than by reading the code: `salesReport()` reads `.options[.selectedIndex].text`
and threw; `stock.js` appended options to what had become a `<div>`, which
rendered their labels as loose prose across the toolbar. Adding a use of a
native select API without adding it here will fail the same way.

A native popup is drawn by the operating system: square corners, its own font,
no animation, nothing about it matching the interface. So only the popup is
replaced; the real `<select>` is still inside the wrapper holding the value.

Three things the panel gets right that are easy to lose:

- **It lives on `<body>`, positioned `fixed` from the trigger's rectangle**, so
  a scrolling modal body or a table's overflow container cannot clip it. The
  cost is that it does not disappear when the router clears the screen beneath
  it — hence `close()` on `hashchange`, and a `button.isConnected` check in
  `place()`.
- **Scrolling repositions it; it does not close.** Closing on any scroll meant a
  scroll still settling from before the menu opened shut it the instant it
  appeared. Only the trigger leaving the window closes it.
- **Everything that marks the menu open happens before `place()`**, because
  `place()` may close it again. Setting `aria-expanded` afterwards left the
  button claiming to be open with nothing under it.

The panel flips above its trigger when there is no room below, and swaps to the
`pop-in-up` / `pop-out-down` pair so it still travels *towards* the control.
Keyboard: arrows, Home/End, Enter, Escape, and type-ahead — the one thing a
native select does that is easy to forget to reimplement.

The magnifier in `.search` is a **mask**, not a background image, so `color`
drives it and the focus state is a one-property change. It replaced a `⌕`
character, which rendered at a different weight and size in every font that
might be installed.

## The settings screen

Two columns of grouped rows at ≥1200px, one below it. The split is at 1200 and
not 1024 because a label plus a 320px control needs about 34rem, and half of
1024 is 29rem — the width at which the rows look cramped rather than roomy.

The structure is `group()` and `row()` in `views/settings.js`, and the rule that
makes it compact is that **the group's name sits outside its card**. A header
bar inside every card costs a row of height per group and makes four groups read
as four pages. `row(..., { stacked: true })` is there for a control too wide to
sit opposite its label; nothing needs it today.

The page takes the **full width** — no `max-width`. There is no reading-measure
argument for one here: these are label/value rows, not prose, and a cap left a
third of a wide monitor empty beside a page that had run out of room.

Three things were tried and removed, and should not come back without a better
reason than the one they had:

- a sentence of introduction above the cards — the top bar already says
  Settings and the group labels say what each card is;
- a SURFACE / RAISED / ACCENT swatch strip under the theme picker — the
  application behind the card is the preview, and it repaints the instant a
  segment is pressed;
- a "Remembered where / This device" row — true, but it is a footnote about the
  setting above it, and it cost a row to say so. It is in the README instead.

The avatar is the account's **initials**, in the top bar and again at 64px on
this screen. There are no uploaded photographs in this system and none planned,
so it is the avatar rather than a placeholder waiting for one; `initials()` is
duplicated in `app.js` and `settings.js` because the two draw at different
sizes and neither owns the other.

**Changing a password happens here and nowhere else.** It used to be an item in
the account menu as well, which meant two ways in and two things to keep in
step. The DOS key `9` still works and now opens this screen. One modal survives:
`forcePasswordChange()` in `app.js`, for an account carried over from the DOS
system that cannot be used until it has a password of its own — it has no
Cancel, which is the whole reason it is a modal and not a screen.

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
