# Marina Trading IMS — how it fits together, and what to do next

Written 1 September 2026, for picking up in about a week.

This is the plain-language companion to `README.md`. That file explains the
system; this one explains **the plan** — how the pieces relate, what was decided
and why, and the exact steps to finish setting it up.

---

## 1. The goal

One computer at work runs the system and holds all the records. Everyone else
looks at it from wherever they are — the counter in the office, home, or another
country entirely.

Nothing is copied to the cloud. The records live in one place and stay there.

```
  Someone away from             The work computer                Google Drive
  the office                    (the only one with
                                 the real records)
  ┌──────────────┐              ┌──────────────────┐            ┌───────────┐
  │  laptop or   │◄────────────►│  the system      │───────────►│  backups  │
  │  phone       │  Tailscale   │  the database    │  nightly   │  (copies) │
  └──────────────┘  encrypted   └──────────────────┘            └───────────┘
                                         ▲
                                         │  office WiFi
                                         │  (no Tailscale needed)
                                  ┌──────┴───────┐
                                  │ counter PCs  │
                                  └──────────────┘
```

---

## 2. The three layers

This is the thing that was confusing, so it is worth keeping straight. There are
three separate layers, and **only one of them decides what a person can do.**

| Layer | What it decides | Does it limit what you can do? |
| --- | --- | --- |
| **How you connect** — office WiFi, or Tailscale | Whether you can reach the computer at all | **No** |
| **What you look through** — browser, or the desktop app | What the window looks like | **No** |
| **Your login account's role** | What you are allowed to change | **Yes — only this** |

So an Administrator connecting over Tailscale from another country has exactly
the same powers as an Administrator standing at the counter. A Sales account has
the same limits in both places.

**Tailscale is the road. The browser and the app are two cars on that road.**
Choosing one car over the other changes nothing about the road.

### What the roles actually allow

From `backend/app/security.py`. Worth checking before handing accounts out.

| Role | Can change |
| --- | --- |
| **Administrator** | Everything, including creating user accounts |
| **Manager** | Everything except creating user accounts |
| **Inventory / Purchasing** | Stock, suppliers, purchases |
| **Invoicing** | Invoices, customers, returns |
| **Accounts Receivable** | Collections (payments) |
| **Sales** | *Nothing* — read only |
| **Read only** | Nothing |

> **Careful with "Sales".** It is read-only — it matches the old DOS
> *Sales Order / Monitoring* menu, which was a viewing screen. If somebody needs
> to write up invoices, give them **Invoicing**, not **Sales**.

---

## 3. Who connects how

Two groups, different needs, and **both work at the same time** on the same
server and the same database.

| Who | Where they are | Address they use | Tailscale? |
| --- | --- | --- | --- |
| Office staff | Same building, office WiFi | `http://192.168.x.x:8080` | **No** |
| Anyone away | Anywhere in the world | The Tailscale address | **Yes** |

Office staff need nothing new — that already works today, and is what
`start.bat` was built for. Only people outside the building need Tailscale, and
adding it does not disturb the office setup at all.

### They do not need the same internet

Each computer needs **its own** internet connection. They do **not** need the
same one. Work computer in Manila on the office WiFi, somebody else on their
home WiFi in another country — both running Tailscale — works fine. That is the
entire reason to use it.

- Without Tailscale the address is `192.168.1.5`, which only means something
  inside the office.
- With Tailscale the address is `100.x.y.z`, which means the same thing
  everywhere.

---

## 4. Where things stand right now

| | |
| --- | --- |
| Database | Created at `database\ims.sqlite`, empty except for one account |
| Legacy data | **Not loaded yet** — no `legacy\*.DBF` migrated |
| Account | `ADMIN` / `admin123` — **change this before anyone connects** |
| Installer | Built and published: `releases\Marina IMS_0.4.0_x64-setup.exe` |
| Settings screen | Now shows the app with a Download button (it used to say none was published) |
| Remote access | **Not set up.** This is the work below. |

---

## 5. What to do, in order

### Step 0 — Change the admin password

Do this first. It is the one thing standing in front of the data.

```
backend\.venv\Scripts\python.exe backend\reset_password.py ADMIN
```

It asks for the new password twice and does not show it on screen. At least 8
characters.

To see every account and its role:

```
backend\.venv\Scripts\python.exe backend\reset_password.py
```

### Step 1 — Load the real data (if not done)

Put the legacy `.DBF` files in `legacy\`, then:

```
backend\.venv\Scripts\python.exe backend\migrate.py
```

This takes a while — the movement ledger is 2.5 million rows. `--skip-moves`
does the fast version if you only want to see it working first.

Migrated staff accounts keep the password they used in the DOS system and are
made to change it at first sign-in.

### Step 2 — The office network (already works)

```
start.bat
```

It prints the addresses. Office PCs use the **Network** one —
`http://192.168.x.x:8080` — in any browser. Allow the port through the firewall
once, as administrator:

```
netsh advfirewall firewall add rule name="Marina IMS" dir=in action=allow protocol=TCP localport=8080
```

Give the work computer a **reserved IP** on the router so the address stops
changing.

### Step 3 — Tailscale, for people outside the office

This is the new piece. Free, permanent address, nothing to configure on any
router.

**On the work computer:**

1. Install from <https://tailscale.com/download>
2. Sign in — a Google account is fine
3. Note the address it shows, something like `100.94.12.7`
4. Set the computer **not to sleep**. Control Panel → Power Options. On a
   laptop, also set "closing the lid" to do nothing.

**On each person's laptop or phone:**

1. Install Tailscale (there are iPhone and Android apps too)
2. Sign into the **same account**
3. Open `http://100.94.12.7:8080` in a browser, or type that address into the
   desktop app

That is all. After the first day nobody thinks about Tailscale again — it runs
quietly in the background like antivirus.

> **Protect the Tailscale account.** It is now a key to the records. Use a strong
> password and turn on two-factor authentication.

To remove somebody's access later, delete their device in the Tailscale admin
console. Their login account can be disabled separately in the system's own
Settings screen.

### Step 4 — Backups off the machine

Backups are written to `backups\` automatically, once a day. They are only
useful if they are not on the same computer as the original.

**The numbers:**

| | |
| --- | --- |
| Database (25 years) | 1,186 MB |
| One backup zip | 387 MB (about 6 seconds to make) |
| Seven days of backups | **~2.7 GB** |
| Google Drive free | 15 GB — plenty |

Install [rclone](https://rclone.org/downloads/), connect it to Drive once with
`rclone config`, then:

```
rclone sync backups remote:ims-backups
```

Put that in Task Scheduler to run nightly. It replaces the `robocopy` line in
`README.md`, which only copies to another machine on the same network.

> **Never put the live database in Google Drive.** Drive copies files while the
> system is still writing to them, which produces a corrupt database you will not
> discover until the day you need it. Backups are sealed files and are safe;
> the live database is not.

### Step 5 — The desktop app, for whoever wants it

Anyone signed in can get it: **Settings → Desktop app → Download**.

On their machine, after installing:

1. Choose **"Another PC is running it"**
2. Type the address — the office `192.168.x.x` or the Tailscale `100.x.y.z`
3. Port 8080

It asks for that address **once**. On the second run, a box appears at the
bottom: *"Ask every time the app opens."* Untick it and from then on the app
opens straight to the sign-in screen.

A machine using the app needs **nothing else** — no copy of the project, no
Python, no database. The app is only a window; the server does all the work.

---

## 6. Decisions already made

Recorded so they do not have to be argued again.

| Idea | Verdict | Why |
| --- | --- | --- |
| **Supabase (free) for the database** | No | Free plan caps the database at 500 MB; this one is 1,186 MB. Free has no automated backups at all — those start at $25/month. And Supabase is PostgreSQL while this system is SQLite throughout, so it would mean rewriting the entire data layer, not changing a setting. |
| **Supabase for backup storage** | No | 1 GB free, and a week of backups is 2.7 GB. |
| **Google Drive for backups** | **Yes** | 15 GB free, needs 2.7 GB. |
| **Google Drive as the database** | Never | Sync corrupts a database that is being written to. |
| **Cloudflare tunnel** | Shelved | Works, and needs nothing installed at the other end — but the free address changes on every restart, and a permanent one needs a paid domain. Also, Cloudflare can see the traffic in the clear. |
| **Port forwarding on the router** | No | Needs router admin, breaks behind CGNAT, and would expose the office over plain HTTP. |
| **Tailscale** | **Yes** | Free, permanent address, nothing public, encrypted between the two computers, and Tailscale itself cannot read the traffic. Costs one app install per person. |
| **Trimming history to 5 years** | Not needed | That was only to squeeze under Supabase's 500 MB. On your own disk, 1.2 GB is nothing. Keep all 25 years. (`migrate.py --since 2021-01-01` if you ever want it smaller.) |

**Total cost of the chosen plan: nothing.** No domain, no hosting, no
subscriptions.

---

## 7. Work that was shelved, not deleted

An earlier attempt built remote access around a Cloudflare tunnel. It worked and
was tested, but the plan changed to Tailscale, so it was put aside rather than
thrown away.

It is in a git stash:

```
git stash list                 see it
git stash show -p stash@{0}    read what is in it
git stash pop                  bring it all back
git stash drop stash@{0}       discard it permanently
```

**What is in there,** in case any of it is wanted later:

- `share.bat` / `share.ps1` — start the server and publish it through a
  Cloudflare tunnel in one step
- **Login rate limiting** (`backend/app/throttle.py`) — five wrong passwords per
  account and per address, then a fifteen-minute wait. This one is worth having
  even on the office network; it closes a **High** finding in
  `SECURITY-AUDIT.md`.
- **Security response headers** — closes a Low finding in the same audit
- **HTTPS support in the desktop app** — the connection test was a hand-written
  plain-HTTP request that cannot speak to an `https://` address, and `ureq` was
  compiled without TLS
- **URL-based addresses in the app** — so it can take `https://name.example.com`
  and not just a host and a port
- Documentation updates across `README.md`, `desktop/README.md`,
  `system_architecture.md` and `SECURITY-AUDIT.md`

None of it is needed for Tailscale, which behaves like an ordinary local
network. The login rate limiting is the piece worth recovering on its own.

---

## 8. Things that will trip you up

- **The work computer must be awake.** If it sleeps or the lid closes, everyone
  is offline. This is the most common cause of "it stopped working".
- **Only one server at a time.** `start.bat` refuses to start if the port is
  busy, on purpose — a second copy would fail while the first kept serving, and
  restarting would appear to do nothing.
- **Hosting is not the same as being an admin.** The work computer runs the
  software; accounts decide who can do what. The host machine can sit with
  nobody logged into it.
- **`sales` is read-only.** See the roles table above.
- **Changing a password signs that person out everywhere.** Expected.
- **Restoring a backup signs *everyone* out**, including whoever pressed the
  button — accounts come from the backup too.

---

## 9. Worth doing when there is time

From `SECURITY-AUDIT.md`, and unrelated to how people connect:

1. **Findings #3, #4 and #6** — a Manager can reach Administrator two different
   ways, through backup download and backup restore. Worth closing before more
   people have accounts.
2. **Recover the login rate limiting** from the stash (section 7).
3. **Finding #1** — the desktop app installs updates without checking a
   signature.

---

## 10. Reference

| | |
| --- | --- |
| Start the server | `start.bat` |
| Change a password | `backend\.venv\Scripts\python.exe backend\reset_password.py ADMIN` |
| List accounts | `backend\.venv\Scripts\python.exe backend\reset_password.py` |
| Load legacy data | `backend\.venv\Scripts\python.exe backend\migrate.py` |
| Build the installer | `cd desktop` then `npm run build` |
| Publish an installer | copy it into `releases\` |
| Database | `database\ims.sqlite` |
| Backups | `backups\` |
| Full documentation | `README.md` |
| Design decisions | `system_architecture.md` |
| Known security issues | `SECURITY-AUDIT.md` |
