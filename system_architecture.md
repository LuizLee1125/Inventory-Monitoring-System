# System architecture notes

Design decisions that are not obvious from the code, kept so a later change
does not have to rediscover them.

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
