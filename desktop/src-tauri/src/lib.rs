//! Desktop shell for the Inventory Monitoring System.
//!
//! The shell deliberately does **not** bundle `frontend/`. The browser
//! application calls `fetch('/api/...')` with relative URLs, so served from
//! `tauri://localhost` every request would resolve to the webview itself. Rather
//! than introduce an API base URL and ship a second copy of the frontend that
//! can drift from the one the office's browsers get, the window is pointed at
//! the running FastAPI server over HTTP. Desktop and browser are then literally
//! the same application.
//!
//! Two modes, chosen once and remembered:
//!
//! * **host**   - this PC runs the server. The shell spawns uvicorn as a child
//!                process, waits for `/api/meta` to answer, and opens the window
//!                on `http://127.0.0.1:PORT`. The server still binds `0.0.0.0`,
//!                so every other PC on the LAN keeps reaching it in a browser.
//! * **client** - somebody else is hosting; the window opens on their address
//!                and no child process is started.

use std::collections::VecDeque;
use std::io::{BufRead, BufReader, Read, Write as _};
use std::net::{TcpStream, ToSocketAddrs};
use std::path::{Path, PathBuf};
use std::process::{Child, Command, Stdio};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use serde::{Deserialize, Serialize};
use tauri::menu::{Menu, MenuItem};
use tauri::tray::TrayIconBuilder;
use tauri::{AppHandle, Manager, State, WebviewUrl, WebviewWindowBuilder};

/// Lines of server output kept for the setup page. Enough to hold a Python
/// traceback, which is the thing anybody actually needs to read.
const LOG_LINES: usize = 240;

/// The one path the application window may ask for and never reach: the
/// settings screen's "Install now" navigates here, and the shell answers it
/// instead of the server. Two underscores and a name nothing else could want,
/// so it cannot collide with a real screen.
const UPDATE_PATH: &str = "/__ims-update";

/// How long to wait for a freshly spawned server to answer. Cold starts run the
/// schema comparison and can take a backup before serving, and a 1.2 GB backup
/// is about six seconds on this office's machine.
const START_TIMEOUT: Duration = Duration::from_secs(90);

// ---------------------------------------------------------------- configuration

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AppConfig {
    /// `"host"` or `"client"`.
    pub mode: String,
    /// Only meaningful in client mode; host mode always talks to loopback.
    pub host: String,
    pub port: u16,
    /// Project folder holding `backend/app/main.py`. `None` means "detect".
    pub project_dir: Option<String>,
    /// False until the user has been through the setup page once.
    pub configured: bool,
    /// Put the chooser on the login screen every time the app opens. The
    /// office moves between "this PC hosts" and "the other one does" more often
    /// than a settings screen buried three clicks away would suggest, so asking
    /// is the default; the checkbox on the chooser turns it off for people who
    /// only ever answer the same way.
    #[serde(default = "yes")]
    pub ask_on_open: bool,
}

fn yes() -> bool {
    true
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            mode: "host".into(),
            host: "127.0.0.1".into(),
            port: 8080,
            project_dir: None,
            configured: false,
            ask_on_open: true,
        }
    }
}

fn config_path(app: &AppHandle) -> Option<PathBuf> {
    app.path().app_config_dir().ok().map(|d| d.join("config.json"))
}

fn load_config(app: &AppHandle) -> AppConfig {
    config_path(app)
        .and_then(|p| std::fs::read_to_string(p).ok())
        .and_then(|text| serde_json::from_str(&text).ok())
        .unwrap_or_default()
}

fn store_config(app: &AppHandle, config: &AppConfig) -> Result<(), String> {
    let path = config_path(app).ok_or("No configuration folder for this user")?;
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    let text = serde_json::to_string_pretty(config).map_err(|e| e.to_string())?;
    std::fs::write(&path, text).map_err(|e| e.to_string())
}

// ------------------------------------------------------------------- the server

pub struct Server {
    child: Mutex<Option<Child>>,
    log: Arc<Mutex<VecDeque<String>>>,
    /// Where the application window is currently pointed, so switching servers
    /// from the chooser knows it has to close and reopen rather than raise what
    /// is already there.
    url: Mutex<Option<String>>,
    /// Set when something went wrong somewhere with no screen to say so on -
    /// an update started from the settings page, which has no way to be told.
    /// The launcher reads and clears it when it next opens.
    error: Mutex<Option<String>>,
    /// New for every launch of the app, and carried on the window's URL. The
    /// page uses it to tell "the app was just opened" from "somebody reloaded",
    /// which is what makes signing out on close possible without the shell
    /// having to reach into the webview's cookie jar. See `end_desktop_session`
    /// in `frontend/js/app.js`.
    boot_id: String,
}

impl Default for Server {
    fn default() -> Self {
        let boot_id = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos().to_string())
            .unwrap_or_else(|_| "0".into());
        Self {
            child: Mutex::new(None),
            log: Arc::new(Mutex::new(VecDeque::new())),
            url: Mutex::new(None),
            error: Mutex::new(None),
            boot_id,
        }
    }
}

impl Server {
    fn note(&self, line: impl Into<String>) {
        push(&self.log, line.into());
    }

    fn kill(&self) {
        if let Ok(mut slot) = self.child.lock() {
            if let Some(mut child) = slot.take() {
                let _ = child.kill();
                let _ = child.wait();
            }
        }
    }
}

fn push(log: &Arc<Mutex<VecDeque<String>>>, line: String) {
    if let Ok(mut lines) = log.lock() {
        if lines.len() >= LOG_LINES {
            lines.pop_front();
        }
        lines.push_back(line);
    }
}

// --------------------------------------------------------------- health probing

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ProbeResult {
    /// Something answered on that port.
    pub reachable: bool,
    /// ...and it was this system rather than some other server.
    pub is_ims: bool,
    pub detail: String,
}

/// `0.0.0.0` is a bind address, not somewhere to connect to; an address pasted
/// out of the server's own console, or off a bookmark, may carry a scheme and a
/// path. Both are the same mistake to the person typing, so both are corrected.
fn normalize_host(raw: &str) -> String {
    let mut host = raw.trim().to_string();
    for prefix in ["http://", "https://"] {
        if let Some(rest) = host.strip_prefix(prefix) {
            host = rest.to_string();
        }
    }
    if let Some(slash) = host.find('/') {
        host.truncate(slash);
    }
    if let Some(colon) = host.rfind(':') {
        // Only a port, never the middle of an IPv6 literal.
        if host[colon + 1..].chars().all(|c| c.is_ascii_digit()) && !host.contains('[') {
            host.truncate(colon);
        }
    }
    let host = host.trim().to_string();
    if host.is_empty() || host == "0.0.0.0" {
        "127.0.0.1".into()
    } else {
        host
    }
}

/// A raw `GET /api/meta`. An HTTP client crate would be a heavier dependency
/// than the question deserves: what is being asked is "is our server listening
/// there", and the answer is in the first few hundred bytes.
fn probe(host: &str, port: u16, timeout: Duration) -> ProbeResult {
    let host = normalize_host(host);
    let target = match format!("{host}:{port}").to_socket_addrs() {
        Ok(mut addrs) => match addrs.next() {
            Some(addr) => addr,
            None => {
                return ProbeResult {
                    reachable: false,
                    is_ims: false,
                    detail: format!("{host} does not resolve to an address"),
                }
            }
        },
        Err(err) => {
            return ProbeResult {
                reachable: false,
                is_ims: false,
                detail: format!("{host} could not be looked up: {err}"),
            }
        }
    };

    let mut stream = match TcpStream::connect_timeout(&target, timeout) {
        Ok(stream) => stream,
        Err(err) => {
            return ProbeResult {
                reachable: false,
                is_ims: false,
                detail: format!("Nothing is answering on {host}:{port} ({err})"),
            }
        }
    };
    let _ = stream.set_read_timeout(Some(timeout));
    let _ = stream.set_write_timeout(Some(timeout));

    let request = format!(
        "GET /api/meta HTTP/1.1\r\nHost: {host}:{port}\r\nUser-Agent: ims-desktop\r\n\
         Accept: application/json\r\nConnection: close\r\n\r\n"
    );
    if let Err(err) = stream.write_all(request.as_bytes()) {
        return ProbeResult {
            reachable: true,
            is_ims: false,
            detail: format!("{host}:{port} accepted the connection then failed: {err}"),
        };
    }

    let mut body = Vec::new();
    let mut chunk = [0u8; 2048];
    while body.len() < 8192 {
        match stream.read(&mut chunk) {
            Ok(0) => break,
            Ok(n) => body.extend_from_slice(&chunk[..n]),
            Err(_) => break,
        }
    }
    let text = String::from_utf8_lossy(&body);

    if text.contains("\"app\"") && text.contains("\"version\"") {
        ProbeResult {
            reachable: true,
            is_ims: true,
            detail: format!("Connected to {host}:{port}"),
        }
    } else {
        ProbeResult {
            reachable: true,
            is_ims: false,
            detail: format!(
                "Something is listening on {host}:{port}, but it is not the \
                 Inventory Monitoring System."
            ),
        }
    }
}

// ------------------------------------------------------------ finding the server

/// The marker that identifies a project folder. Checked rather than assumed, so
/// pointing the app at the wrong folder fails with a sentence instead of a
/// Python import error thirty lines deep.
fn is_project_root(dir: &Path) -> bool {
    dir.join("backend").join("app").join("main.py").is_file()
}

fn climb(start: &Path) -> Option<PathBuf> {
    let mut here = Some(start);
    while let Some(dir) = here {
        if is_project_root(dir) {
            return Some(dir.to_path_buf());
        }
        here = dir.parent();
    }
    None
}

/// Walks up from both the executable and the working directory. In development
/// the binary sits in `desktop/src-tauri/target/debug`; installed, the working
/// directory is the more likely of the two to be inside the project.
fn find_project_root() -> Option<PathBuf> {
    let mut candidates: Vec<PathBuf> = Vec::new();
    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            candidates.push(dir.to_path_buf());
        }
    }
    if let Ok(cwd) = std::env::current_dir() {
        candidates.push(cwd);
    }
    candidates.iter().find_map(|dir| climb(dir))
}

/// The virtual environment `start.bat` builds, then whatever is on PATH.
fn python_for(root: &Path) -> Option<PathBuf> {
    let venv = if cfg!(windows) {
        root.join("backend/.venv/Scripts/python.exe")
    } else {
        root.join("backend/.venv/bin/python")
    };
    if venv.is_file() {
        return Some(venv);
    }
    for name in ["python", "python3", "py"] {
        if Command::new(name)
            .arg("--version")
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
        {
            return Some(PathBuf::from(name));
        }
    }
    None
}

fn spawn_server(root: &Path, port: u16, log: &Arc<Mutex<VecDeque<String>>>) -> Result<Child, String> {
    let python = python_for(root).ok_or_else(|| {
        format!(
            "No Python found. Expected {}, and nothing on PATH either. Run \
             start.bat once to build the virtual environment.",
            root.join("backend/.venv").display()
        )
    })?;

    let mut command = Command::new(&python);
    command
        .current_dir(root.join("backend"))
        .args([
            "-m",
            "uvicorn",
            "app.main:app",
            "--host",
            "0.0.0.0",
            "--port",
            &port.to_string(),
        ])
        // The server reads these itself (backend/app/config.py), so the banner
        // it prints and the address it binds agree with what was asked for.
        .env("IMS_HOST", "0.0.0.0")
        .env("IMS_PORT", port.to_string())
        .env("PYTHONUNBUFFERED", "1")
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());

    // Without this Windows opens a console window beside the app for the
    // lifetime of the server, which is exactly what the desktop edition exists
    // to get rid of.
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        const CREATE_NO_WINDOW: u32 = 0x0800_0000;
        command.creation_flags(CREATE_NO_WINDOW);
    }

    push(log, format!("$ {} -m uvicorn app.main:app --port {port}", python.display()));
    let mut child = command
        .spawn()
        .map_err(|e| format!("Could not start the server: {e}"))?;

    for stream in [
        child.stdout.take().map(|s| Box::new(s) as Box<dyn Read + Send>),
        child.stderr.take().map(|s| Box::new(s) as Box<dyn Read + Send>),
    ]
    .into_iter()
    .flatten()
    {
        let log = Arc::clone(log);
        std::thread::spawn(move || {
            for line in BufReader::new(stream).lines().map_while(Result::ok) {
                push(&log, line);
            }
        });
    }

    Ok(child)
}

/// Polls until the server answers, the child dies, or the deadline passes.
fn wait_for_server(port: u16, child: &mut Child, log: &Arc<Mutex<VecDeque<String>>>) -> Result<(), String> {
    let deadline = Instant::now() + START_TIMEOUT;
    while Instant::now() < deadline {
        if let Ok(Some(status)) = child.try_wait() {
            let tail = log
                .lock()
                .map(|lines| lines.iter().rev().take(6).cloned().collect::<Vec<_>>())
                .unwrap_or_default()
                .into_iter()
                .rev()
                .collect::<Vec<_>>()
                .join("\n");
            return Err(format!(
                "The server stopped before it began serving ({status}).\n\n{tail}"
            ));
        }
        if probe("127.0.0.1", port, Duration::from_millis(400)).is_ims {
            return Ok(());
        }
        std::thread::sleep(Duration::from_millis(300));
    }
    Err(format!(
        "The server did not answer on port {port} within {} seconds.",
        START_TIMEOUT.as_secs()
    ))
}

// --------------------------------------------------------------------- updating

/// What the server is offering against what is running.
#[derive(Clone, Debug, Default, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateInfo {
    /// The version of this application, from Cargo.toml by way of the bundle.
    pub installed: String,
    /// The version of the installer published on the server, if there is one.
    pub latest: Option<String>,
    pub filename: Option<String>,
    pub size: Option<u64>,
    /// True only when `latest` is a strictly higher version than `installed`.
    pub available: bool,
    /// Empty when the check succeeded; the reason when it did not.
    pub error: Option<String>,
}

/// `0.4.0` against `0.10.0` is the whole reason this is not a string compare:
/// `"0.10.0" < "0.4.0"` alphabetically, and an office that never sees a
/// two-digit minor would find that out on the day it does. Missing or
/// non-numeric parts count as zero, so `0.4` and `0.4.0` are the same version.
fn version_parts(text: &str) -> Vec<u64> {
    text.trim()
        .trim_start_matches('v')
        .split(['.', '-', '+'])
        .map(|part| part.parse::<u64>().unwrap_or(0))
        .collect()
}

fn is_newer(candidate: &str, current: &str) -> bool {
    let (a, b) = (version_parts(candidate), version_parts(current));
    for index in 0..a.len().max(b.len()) {
        let (left, right) = (a.get(index).copied().unwrap_or(0),
                             b.get(index).copied().unwrap_or(0));
        if left != right {
            return left > right;
        }
    }
    false
}

/// Ask the connected server what it is publishing.
///
/// `/api/desktop` takes no session (see `backend/app/routers/desktop.py`), which
/// is what lets this run before anybody has signed in - the sign-in screen is
/// exactly the thing that might be out of date.
fn check_for_update(app: &AppHandle) -> UpdateInfo {
    let installed = app.package_info().version.to_string();
    let base = app
        .state::<Server>()
        .url
        .lock()
        .ok()
        .and_then(|held| held.clone());

    let mut info = UpdateInfo { installed: installed.clone(), ..Default::default() };

    let Some(base) = base else {
        info.error = Some("Not connected to a server yet.".into());
        return info;
    };

    let body = match ureq::get(&format!("{base}/api/desktop"))
        .timeout(Duration::from_secs(8))
        .call()
    {
        Ok(response) => response.into_string().unwrap_or_default(),
        Err(err) => {
            info.error = Some(format!("Could not ask the server: {err}"));
            return info;
        }
    };

    let parsed: serde_json::Value = match serde_json::from_str(&body) {
        Ok(value) => value,
        Err(err) => {
            info.error = Some(format!("The server's answer was not readable: {err}"));
            return info;
        }
    };

    if !parsed.get("available").and_then(|v| v.as_bool()).unwrap_or(false) {
        // Not an error: a server with no installer published is an ordinary
        // state, and the screen says so in its own words.
        return info;
    }

    let latest = parsed.get("version").and_then(|v| v.as_str()).map(String::from);
    info.available = latest.as_deref().map(|v| is_newer(v, &installed)).unwrap_or(false);
    info.filename = parsed.get("filename").and_then(|v| v.as_str()).map(String::from);
    info.size = parsed.get("size").and_then(serde_json::Value::as_u64);
    info.latest = latest;
    info
}

/// Fetch the installer and hand over to it.
///
/// There is no silent in-place update and no signing key. `tauri-plugin-updater`
/// wants a signed manifest on an endpoint fixed at build time; this system's
/// release channel is whichever office PC happens to be hosting, which is not
/// known until the app connects, and a minisign keypair would put a permanent
/// build-time secret in the way of anybody rebuilding the app. The threat model
/// does not ask for one either: the file comes from the same server that is
/// already serving every screen in the application, so a server that could hand
/// over a bad installer could hand over a bad application first.
fn run_installer(app: &AppHandle) -> Result<(), String> {
    let info = check_for_update(app);
    if let Some(error) = info.error {
        return Err(error);
    }
    if !info.available {
        return Err("There is nothing newer on the server.".into());
    }
    let base = app
        .state::<Server>()
        .url
        .lock()
        .ok()
        .and_then(|held| held.clone())
        .ok_or("Not connected to a server.")?;

    let name = info.filename.unwrap_or_else(|| "marina-ims-setup.exe".into());
    let target = std::env::temp_dir().join(&name);

    let response = ureq::get(&format!("{base}/api/desktop/download"))
        .timeout(Duration::from_secs(600))
        .call()
        .map_err(|e| format!("Could not download the update: {e}"))?;

    // Written beside its final name and renamed at the end, for the reason the
    // backups are: a download the power cut off halfway through must not be
    // left looking like an installer somebody can run.
    let part = target.with_extension("part");
    {
        let mut file = std::fs::File::create(&part)
            .map_err(|e| format!("Could not write to the temporary folder: {e}"))?;
        std::io::copy(&mut response.into_reader(), &mut file)
            .map_err(|e| format!("The download did not finish: {e}"))?;
    }
    let _ = std::fs::remove_file(&target);
    std::fs::rename(&part, &target)
        .map_err(|e| format!("Could not finish the download: {e}"))?;

    Command::new(&target)
        .spawn()
        .map_err(|e| format!("Could not start the installer: {e}"))?;

    // The installer cannot replace a running executable, so this has to go.
    // Killing the server first: it is this process's child, and leaving it
    // holding the port through an upgrade is the failure start.bat warns about.
    app.state::<Server>().kill();
    app.exit(0);
    Ok(())
}

// ---------------------------------------------------------------------- windows

fn open_main_window(app: &AppHandle, url: &str) -> Result<(), String> {
    let server = app.state::<Server>();
    let same = server
        .url
        .lock()
        .map(|held| held.as_deref() == Some(url))
        .unwrap_or(false);

    if let Some(existing) = app.get_webview_window("main") {
        if same {
            let _ = existing.show();
            let _ = existing.set_focus();
            return Ok(());
        }
        // A different server is a different application: the window has to be
        // rebuilt rather than raised, or the chooser would report a switch that
        // never happened.
        let _ = existing.close();
    }

    // `?desktop=1` is how the page knows which of the two it is being viewed in.
    // It survives hash navigation, which is the whole of the frontend's routing,
    // and it costs nothing - the alternative was overriding the user agent,
    // which means hardcoding a browser version that goes stale. `boot` rides
    // along so the page can tell this launch from a reload.
    // `v` is the running application's own version. The settings screen shows
    // it and compares it against what the server publishes, and it has to get
    // there without IPC: this window is a remote page and is given none.
    let parsed = format!(
        "{url}/?desktop=1&boot={}&v={}",
        server.boot_id,
        app.package_info().version
    )
    .parse()
    .map_err(|_| format!("{url} is not an address the app can open"))?;

    // How the settings screen starts an update without being given IPC.
    //
    // That window loads a remote page over plain HTTP and has no Tauri commands
    // available to it, deliberately - see capabilities/default.json. But it can
    // *navigate*, and navigation is something the shell already sees. So the
    // page asks for an update by trying to go to one fixed, unparameterised
    // path; the shell recognises it, refuses the navigation so nothing actually
    // moves, and does the work. One-way, no arguments, nothing else reachable.
    let nav = app.clone();
    WebviewWindowBuilder::new(app, "main", WebviewUrl::External(parsed))
        .on_navigation(move |url| {
            if url.path() != UPDATE_PATH {
                return true;
            }
            let handle = nav.clone();
            std::thread::spawn(move || {
                if let Err(message) = run_installer(&handle) {
                    if let Ok(mut slot) = handle.state::<Server>().error.lock() {
                        *slot = Some(message);
                    }
                    // Nothing on the settings screen can be told, so the
                    // launcher is opened to carry the message instead.
                    let _ = open_setup_window(&handle);
                }
            });
            false
        })
        .title("Marina Trading - Inventory Monitoring System")
        .inner_size(1440.0, 900.0)
        .min_inner_size(900.0, 600.0)
        .maximized(true)
        .build()
        .map_err(|e| format!("Could not open the application window: {e}"))?;

    if let Ok(mut held) = server.url.lock() {
        *held = Some(url.to_string());
    }
    Ok(())
}

fn open_setup_window(app: &AppHandle) -> Result<(), String> {
    if let Some(existing) = app.get_webview_window("setup") {
        let _ = existing.show();
        let _ = existing.set_focus();
        return Ok(());
    }
    WebviewWindowBuilder::new(app, "setup", WebviewUrl::App("index.html".into()))
        .title("Inventory Monitoring System")
        .inner_size(560.0, 700.0)
        .min_inner_size(460.0, 560.0)
        .resizable(true)
        .center()
        .build()
        .map_err(|e| format!("Could not open the setup window: {e}"))?;
    Ok(())
}

fn browse(url: &str) -> Result<(), String> {
    #[cfg(windows)]
    let mut command = {
        let mut c = Command::new("cmd");
        c.args(["/C", "start", "", url]);
        c
    };
    #[cfg(target_os = "macos")]
    let mut command = {
        let mut c = Command::new("open");
        c.arg(url);
        c
    };
    #[cfg(all(unix, not(target_os = "macos")))]
    let mut command = {
        let mut c = Command::new("xdg-open");
        c.arg(url);
        c
    };

    command
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .map(|_| ())
        .map_err(|e| format!("Could not open a browser: {e}"))
}

// --------------------------------------------------------------------- commands

#[tauri::command]
fn get_config(app: AppHandle) -> AppConfig {
    load_config(&app)
}

#[tauri::command]
fn detect_project() -> Option<String> {
    find_project_root().map(|p| p.display().to_string())
}

#[tauri::command]
fn test_connection(host: String, port: u16) -> ProbeResult {
    probe(&host, port, Duration::from_millis(1500))
}

#[tauri::command]
fn server_log(server: State<'_, Server>) -> Vec<String> {
    server
        .log
        .lock()
        .map(|lines| lines.iter().cloned().collect())
        .unwrap_or_default()
}

#[tauri::command]
fn open_in_browser(host: String, port: u16) -> Result<(), String> {
    browse(&format!("http://{}:{}", normalize_host(&host), port))
}

/// Everything that has to happen before there is something to show: start the
/// server if this PC is the one hosting, wait for it, then open the window on
/// it. The blocking half runs off the UI thread; the window is built back on
/// the main one.
///
/// The launcher window is deliberately **not** closed here. Whether it closes
/// or stays on top of the login screen as the chooser is the page's decision,
/// and it depends on `ask_on_open` and on whether the user got here by hand.
#[tauri::command]
async fn launch(app: AppHandle, config: AppConfig) -> Result<String, String> {
    let mut config = config;
    config.host = normalize_host(&config.host);
    config.configured = true;
    store_config(&app, &config)?;

    let handle = app.clone();
    let target = tauri::async_runtime::spawn_blocking(move || prepare(&handle, &config))
        .await
        .map_err(|e| format!("The launch task failed: {e}"))??;

    open_main_window(&app, &target)?;
    Ok(target)
}

#[tauri::command]
fn close_launcher(app: AppHandle) {
    if let Some(setup) = app.get_webview_window("setup") {
        let _ = setup.close();
    }
}

/// Put the launcher on top of the application window, over the login screen.
///
/// It is the same window that has just been showing the spinner rather than a
/// new one: re-parenting is not a thing a window can do after it is built, and
/// a second window would flash a second taskbar entry for a dialog. Always on
/// top and re-centred over a maximized application window is what makes it read
/// as resting on the page behind it.
#[tauri::command]
fn present_chooser(app: AppHandle) -> Result<(), String> {
    let setup = app
        .get_webview_window("setup")
        .ok_or("The launcher window has already closed")?;
    let _ = setup.set_always_on_top(true);
    let _ = setup.center();
    let _ = setup.show();
    setup.set_focus().map_err(|e| e.to_string())
}

/// Anything that failed with no screen to report it on. Read once, then gone.
#[tauri::command]
fn pending_error(server: State<'_, Server>) -> Option<String> {
    server.error.lock().ok().and_then(|mut slot| slot.take())
}

#[tauri::command]
async fn update_status(app: AppHandle) -> UpdateInfo {
    tauri::async_runtime::spawn_blocking(move || check_for_update(&app))
        .await
        .unwrap_or_else(|e| UpdateInfo {
            error: Some(format!("The update check failed: {e}")),
            ..Default::default()
        })
}

#[tauri::command]
async fn install_update(app: AppHandle) -> Result<(), String> {
    let handle = app.clone();
    tauri::async_runtime::spawn_blocking(move || run_installer(&handle))
        .await
        .map_err(|e| format!("The update task failed: {e}"))?
}

/// The "don't ask again" box, saved the moment it is ticked.
///
/// Not on the way out through the Continue button: the window has a close
/// button of its own, and a preference that only persists down one of the two
/// ways out is a preference that looks broken half the time.
#[tauri::command]
fn save_preferences(app: AppHandle, ask_on_open: bool) -> Result<(), String> {
    let mut config = load_config(&app);
    config.ask_on_open = ask_on_open;
    store_config(&app, &config)
}

fn prepare(app: &AppHandle, config: &AppConfig) -> Result<String, String> {
    let server = app.state::<Server>();

    if config.mode == "client" {
        let result = probe(&config.host, config.port, Duration::from_millis(2500));
        if !result.is_ims {
            return Err(result.detail);
        }
        return Ok(format!("http://{}:{}", config.host, config.port));
    }

    let url = format!("http://127.0.0.1:{}", config.port);

    // start.bat refuses to start a second copy on a busy port, because the
    // second one dies while the first carries on serving and the restart
    // appears to do nothing. The same port here means the same server: attach
    // to it rather than starting a rival, so opening the app while start.bat is
    // already running simply works.
    let existing = probe("127.0.0.1", config.port, Duration::from_millis(800));
    if existing.is_ims {
        server.note(format!(
            "Port {} was already serving; attached to it instead of starting a \
             second copy.",
            config.port
        ));
        return Ok(url);
    }
    if existing.reachable {
        return Err(existing.detail);
    }

    let root = match config.project_dir.as_deref().filter(|s| !s.trim().is_empty()) {
        Some(dir) => PathBuf::from(dir),
        None => find_project_root().ok_or(
            "Could not find the Inventory Monitoring System folder. Choose the \
             folder holding start.bat.",
        )?,
    };
    if !is_project_root(&root) {
        return Err(format!(
            "{} does not look like the project folder - there is no \
             backend\\app\\main.py inside it.",
            root.display()
        ));
    }

    server.kill();
    let mut child = spawn_server(&root, config.port, &server.log)?;
    match wait_for_server(config.port, &mut child, &server.log) {
        Ok(()) => {
            if let Ok(mut slot) = server.child.lock() {
                *slot = Some(child);
            }
            Ok(url)
        }
        Err(err) => {
            let _ = child.kill();
            let _ = child.wait();
            Err(err)
        }
    }
}

// ------------------------------------------------------------------------- tray

fn build_tray(app: &AppHandle) -> tauri::Result<()> {
    let open = MenuItem::with_id(app, "open", "Open", true, None::<&str>)?;
    let browser = MenuItem::with_id(app, "browser", "Open in browser", true, None::<&str>)?;
    let change = MenuItem::with_id(app, "change", "Change server\u{2026}", true, None::<&str>)?;
    let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
    let menu = Menu::with_items(app, &[&open, &browser, &change, &quit])?;

    TrayIconBuilder::with_id("ims-tray")
        .icon(app.default_window_icon().cloned().expect("bundled icon"))
        .tooltip("Marina Trading - Inventory Monitoring System")
        .menu(&menu)
        .show_menu_on_left_click(false)
        .on_menu_event(|app, event| match event.id().as_ref() {
            "open" => {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.show();
                    let _ = window.set_focus();
                } else {
                    let _ = open_setup_window(app);
                }
            }
            "browser" => {
                let config = load_config(app);
                let host = if config.mode == "client" { config.host } else { "127.0.0.1".into() };
                let _ = browse(&format!("http://{host}:{}", config.port));
            }
            "change" => {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.close();
                }
                app.state::<Server>().kill();
                let _ = open_setup_window(app);
            }
            "quit" => {
                app.state::<Server>().kill();
                app.exit(0);
            }
            _ => {}
        })
        .build(app)?;
    Ok(())
}

// ------------------------------------------------------------------------- entry

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, _argv, _cwd| {
            // One office PC, one server. A second copy would fight the first for
            // the port; raise the window that is already there instead.
            let window = app
                .get_webview_window("main")
                .or_else(|| app.get_webview_window("setup"));
            if let Some(window) = window {
                let _ = window.show();
                let _ = window.unminimize();
                let _ = window.set_focus();
            }
        }))
        .manage(Server::default())
        .invoke_handler(tauri::generate_handler![
            get_config,
            detect_project,
            test_connection,
            server_log,
            open_in_browser,
            launch,
            close_launcher,
            present_chooser,
            save_preferences,
            update_status,
            install_update,
            pending_error
        ])
        .setup(|app| {
            let handle = app.handle().clone();
            build_tray(&handle)?;
            open_setup_window(&handle).map_err(std::io::Error::other)?;
            Ok(())
        })
        .build(tauri::generate_context!())
        .expect("error while building the application")
        .run(|app, event| {
            if let tauri::RunEvent::Exit = event {
                // The server is this app's child: closing the app has to stop
                // it, or the office is left with a port held by nothing
                // visible - the exact failure start.bat warns about.
                app.state::<Server>().kill();
            }
        });
}
