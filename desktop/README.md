# Desktop edition

A Tauri v2 shell around the Inventory Monitoring System, in the same family as
`NTC-TMS-Tauri`. It gives the office an installed application with an icon,
a tray entry and no console window — **without taking the browser away from
anyone**.

---

## What it is, and what it is not

It is **not** a second copy of the application. The window is pointed at the
running FastAPI server over HTTP, so what it shows is the same `frontend/` the
office's browsers get, served by the same process, on the same session cookie.

```
Tauri window ──► http://127.0.0.1:8080   this PC hosts
                 http://192.168.x.x:8080  another PC hosts
                        │
                        ▼
                 backend/ + frontend/, unchanged
```

That is a deliberate choice rather than a shortcut. `frontend/js/api.js` calls
`fetch('/api/...')` with relative URLs; bundled into the webview those resolve
against `tauri://localhost`, where there is no API. Making the frontend work
inside the bundle would mean introducing an API base URL, threading it through
every call, and shipping a copy of the frontend inside the installer that can
drift from the served one — two versions of the same screen, differing on the
day somebody updates one of them. Pointing at HTTP costs nothing and cannot
drift.

**Nothing under `backend/` or `frontend/` is modified by this half of the
project.**

## The two modes

Chosen on first run, remembered afterwards in `config.json` under the user's
app-config folder.

| Mode | What happens | Where it belongs |
| --- | --- | --- |
| **This PC runs the server** | Spawns `backend\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8080`, waits for `/api/meta`, opens the window on loopback. Quitting the app stops the server. | The office PC — it replaces double-clicking `start.bat` |
| **Connect to the office server** | Opens the window on somebody else's address. No child process. | Counter machines, replacing a browser bookmark |

Host mode still binds `0.0.0.0`, so **the web edition is unaffected**: phones,
tablets and every other PC keep opening `http://<server>:8080` exactly as
before, while the desktop app is what happens to be running the server.

If the port is already serving this system — because `start.bat` is open, or a
second copy of the app was launched — it **attaches to what is there** instead
of starting a rival. `start.bat` refuses in that situation, for the good reason
in the main README; attaching is the better answer where it is available.

## What happens on every open

1. The launcher window appears and connects with the stored setting — spinner,
   server output on failure.
2. The application window opens on the sign-in screen.
3. Unless `ask_on_open` is off, the launcher **stays**, goes always-on-top and
   re-centres as the *chooser*, resting on that sign-in screen. Continue with
   what is connected, or point the PC somewhere else.
4. The page signs out whatever account the last run left behind, so the sign-in
   screen is always a real one.
5. The shell asks the server whether it publishes anything newer than the
   running version. If it does, the chooser carries the offer — and appears even
   for somebody who turned it off, because that switch was about a question, not
   about being told the app is out of date.

The chooser is the same window as the launcher, not a second one — a dialog
should not add a taskbar entry, and re-parenting after build is not something a
window can do. It is not rendered *inside* the login page either: that page is
remote and has no IPC by design, and choosing a server is a shell operation.

## How it reaches a PC

**Settings → Desktop app → Download**, in the browser, from the server the user
is already signed in to. Every role reaches Settings, and installing the client
grants nothing that signing in does not — the permission checks that matter are
on the endpoints the app then calls.

The card is shaped after the "Get the software" panel in `NTC-TMS-Tauri`: the
file, its name, a version pill, the **address in full**, then Download installer
and Copy link. The address is built from `location.origin`, so on a counter PC it
is already the network address the rest of the office uses and pastes usefully
into a message.

`copyLink()` falls back to a hidden field and `execCommand('copy')` rather than
only using `navigator.clipboard`. That is not legacy code: the clipboard API
needs a secure context, and this server is deliberately plain HTTP on a LAN, so
it is present on `localhost` and **missing on every machine that most needs to
pass the link on**. The fallback is the path most people here take.

`GET /api/desktop` reports what there is; `GET /api/desktop/download` sends it
(`backend/app/routers/desktop.py`). What it offers is the newest installer in
`releases/`, and failing that whatever `npm run build` last wrote into
`src-tauri/target/release/bundle` — so a fresh build is downloadable without
anybody copying it anywhere, while `releases/` stays the deliberate publish and
wins even when the build is newer.

Within a folder, **format beats date**: a Tauri build writes the NSIS `.exe` and
the MSI a second apart, and the `.exe` is the one this office wants — it is what
staff expect a program to arrive as, and it installs without an administrator.

`NTC-TMS-Tauri` fetches its releases from Supabase storage because its users are
spread across the country. These users are all on one network with the server in
the corner of the room, so a channel that needed the internet would fail on
exactly the days the line is down.

To publish a build:

```bash
copy "desktop\src-tauri\target\release\bundle\nsis\Marina IMS_1.0.0_x64-setup.exe" releases\
```

## Building

Needs [Node.js](https://nodejs.org) and the [Rust toolchain](https://rustup.rs),
plus the Microsoft C++ Build Tools and WebView2 on Windows (Windows 11 ships
WebView2 already).

```bash
cd desktop
npm install
npm run icon      # once, generates src-tauri/icons from app-icon.svg
npm run dev       # run from source
npm run build     # installers, into src-tauri/target/release/bundle
```

`start-desktop.bat` at the top of the project does the first three for you.

The first Rust build compiles several hundred crates and takes minutes. Later
ones are quick.

## Layout

```
desktop/
  package.json          the Tauri CLI, dev-only
  app-icon.svg          the M mark, source for `npm run icon`
  ui/                   the launcher - the ONLY bundled page
    index.html
    setup.css           palette lifted from frontend/css/app.css
    setup.js            plain script, withGlobalTauri, no build step
  src-tauri/
    tauri.conf.json     product name, identifier, bundle targets, CSP
    capabilities/       IPC permissions, granted to the launcher window only
    src/lib.rs          config, health probe, server child process, tray
    src/main.rs
```

## Notes for a later change

- **The application window gets no IPC.** `capabilities/default.json` lists
  `"windows": ["setup"]`, so the remote page cannot reach a Tauri command even
  if something on it tried. Keep it that way; the window loads a page over
  plain HTTP from a LAN address.
- **The launcher has no build step**, matching the browser application. It is a
  plain `<script>` using `window.__TAURI__`, which is why
  `withGlobalTauri: true` is set.
- **The server is a `std::process::Child`, not `tauri-plugin-shell`.** Killing
  it on exit has to be unambiguous: a port held by an invisible process is the
  exact failure the main README's "Restarting" section is about.
- **The health probe is a raw `TcpStream`**, not an HTTP client crate. The
  question is only "is our server listening there", and the answer is in the
  first few hundred bytes of `GET /api/meta`.
- **`CREATE_NO_WINDOW`** on the spawn is load-bearing on Windows. Without it a
  console window sits beside the app for as long as the server runs, which is
  most of what this edition exists to remove.
- **`?desktop=1&boot=…` is the whole contract with the page.** `desktop` gates
  the two desktop-only behaviours; `boot` is regenerated once per launch and is
  what lets the page tell "the app was opened" from "somebody pressed F5". Keep
  `boot` stable across a reconnect — it is held in `Server`, not generated at
  the call site — or switching servers would read as a new launch.
- **Do not reach for `clear_all_browsing_data()`** to do the signing out. It
  takes `localStorage` with it, and `ims.theme` lives there: the app would
  forget light or dark on every launch.
- **The settings page starts an update by navigating, not by invoking.** It has
  no IPC, and widening the capability would expose *every* app command to a
  remote page — app commands are not ACL-gated the way plugin commands are, and
  `launch` spawns a Python interpreter from a path in its argument. Instead the
  page navigates to `/__ims-update`; `on_navigation` recognises that one fixed
  path, returns `false` so the page does not move, and does the work. Keep it
  unparameterised: the moment the shell reads anything *out* of that URL it
  becomes an IPC channel with no permission model.
- **There is no `version` in `tauri.conf.json`.** Tauri takes Cargo's, so the
  shell and its bundle cannot disagree. Bump `Cargo.toml`, not the JSON.
- **The updater is not `tauri-plugin-updater`.** Its endpoint is fixed at build
  time and this one is not known until the app connects, and
  `createUpdaterArtifacts` makes every future build depend on a signing key that
  cannot be committed. The reasoning is in `system_architecture.md`.
