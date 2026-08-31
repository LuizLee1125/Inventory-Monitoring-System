// Launcher for the desktop edition.
//
// The only page the shell itself serves, and the only one with IPC access. Its
// whole job is to decide an address, get a server answering on it, and then
// hand over to the real application - which is the same frontend/ the office's
// browsers get, served over HTTP by the same FastAPI process.
//
// No modules and no build step, matching the browser application: this is a
// plain script with `withGlobalTauri`, so `window.__TAURI__` is the whole API.

const invoke = window.__TAURI__.core.invoke;

const el = (id) => document.getElementById(id);

const view = { working: el('state-working'), form: el('state-form') };
const workingLine = el('working-line');
const workingNote = el('working-note');
const connected = el('connected');
const lede = el('lede');
const askBar = el('ask-bar');
const askAgain = el('ask-again');
const updateBox = el('update');
const updateLine = el('update-line');
const updateNote = el('update-note');
const btnUpdate = el('btn-update');
const modeHost = el('mode-host');
const modeClient = el('mode-client');
const fieldAddress = el('field-address');
const fieldFolder = el('field-folder');
const inputHost = el('input-host');
const inputFolder = el('input-folder');
const inputPort = el('input-port');
const alertBox = el('alert');
const btnTest = el('btn-test');
const btnGo = el('btn-go');
const btnBrowser = el('btn-browser');
const btnCancel = el('btn-cancel');
const logBox = el('log');
const logBody = el('log-body');

let mode = 'host';
let logTimer = null;

// The launcher wears two faces. On a first run, and whenever something is
// wrong, it is the setup form and nothing is behind it. On every later open it
// connects first and then comes back as the *chooser*, on top of the sign-in
// screen: the same question, asked of somebody who can already see the answer
// it used last time.
let chooser = false;
let connectedTo = null;

// ------------------------------------------------------------------- plumbing

function show(name) {
  view.working.hidden = name !== 'working';
  view.form.hidden = name !== 'form';
}

function say(message, kind) {
  if (!message) {
    alertBox.hidden = true;
    return;
  }
  alertBox.textContent = message;
  alertBox.classList.toggle('ok', kind === 'ok');
  alertBox.hidden = false;
}

function busy(on) {
  btnTest.disabled = on;
  btnGo.disabled = on;
}

function setMode(next) {
  mode = next;
  modeHost.setAttribute('aria-checked', String(next === 'host'));
  modeClient.setAttribute('aria-checked', String(next === 'client'));
  fieldAddress.hidden = next !== 'client';
  fieldFolder.hidden = next !== 'host';
  say('');
}

/** What the form currently describes, in the shape the Rust side expects. */
function readForm() {
  const port = Number.parseInt(inputPort.value, 10);
  return {
    mode,
    host: mode === 'client' ? inputHost.value.trim() : '127.0.0.1',
    port: Number.isFinite(port) && port > 0 && port < 65536 ? port : 8080,
    projectDir: inputFolder.value.trim() || null,
    configured: true,
    askOnOpen: askAgain.checked,
  };
}

/** Whether pressing Continue would actually change anything. */
const sameAsConnected = (config) => Boolean(connectedTo)
  && config.mode === connectedTo.mode
  && config.port === connectedTo.port
  && (config.mode !== 'client' || config.host === connectedTo.host);

/**
 * Come back as the chooser, over the sign-in screen.
 *
 * The application window is already open behind this one and already showing
 * the login form, so the wording drops "where does this PC get the system
 * from" - it has that answer on screen - and asks whether to keep it.
 */
async function showChooser(config) {
  chooser = true;
  connectedTo = config;

  connected.textContent = config.mode === 'host'
    ? `Running on this PC, port ${config.port}`
    : `Connected to ${config.host}:${config.port}`;
  connected.hidden = false;
  lede.textContent = 'Carry on, or point this PC somewhere else.';
  btnGo.textContent = 'Continue';
  askAgain.checked = config.askOnOpen !== false;
  askBar.hidden = false;

  show('form');
  await invoke('present_chooser').catch(() => {});
}

/** The server's own output, so a failed start explains itself here rather than
 *  sending somebody to a console window this edition exists to remove. */
async function refreshLog() {
  const lines = await invoke('server_log');
  if (!lines.length) return;
  logBox.hidden = false;
  logBody.textContent = lines.join('\n');
  logBody.scrollTop = logBody.scrollHeight;
}

function watchLog(on) {
  clearInterval(logTimer);
  logTimer = on ? setInterval(() => { refreshLog().catch(() => {}); }, 700) : null;
}

// ------------------------------------------------------------------- actions

/** Start or connect, and say whether it worked. */
async function start(config) {
  show('working');
  workingLine.textContent = config.mode === 'host'
    ? 'Starting the server…'
    : `Connecting to ${config.host}…`;
  workingNote.textContent = config.mode === 'host'
    ? 'The first start of the day also takes a backup. That can take a few seconds on a large database.'
    : 'Make sure the other PC is switched on and running the system.';
  watchLog(config.mode === 'host');

  try {
    await invoke('launch', { config });
    watchLog(false);
    return true;
  } catch (error) {
    watchLog(false);
    await refreshLog().catch(() => {});
    show('form');
    say(String(error));
    return false;
  }
}

/**
 * Ask the server whether it is publishing anything newer than this app.
 *
 * Runs after connecting, because the answer comes from the server that was just
 * connected to. Silent when there is nothing to say: an update notice is worth
 * a panel, "you are up to date" is not — the settings screen is where somebody
 * goes to ask that question, and it answers it there.
 */
const megabytes = (bytes) => `${(bytes / 1_048_576).toFixed(1)} MB`;

async function checkUpdate() {
  const info = await invoke('update_status').catch(() => null);
  if (!info || !info.available) return false;

  updateLine.textContent = `Version ${info.latest} is available`;
  updateNote.textContent = `You are on ${info.installed}.`
    + (info.size ? ` The download is ${megabytes(info.size)}.` : '');
  updateBox.hidden = false;
  return true;
}

async function installUpdate() {
  btnUpdate.disabled = true;
  show('working');
  workingLine.textContent = 'Downloading the update…';
  workingNote.textContent = 'The app closes when the download finishes so the '
    + 'installer can replace it. Open it again afterwards.';
  try {
    // On success this never returns anything the page will see: the shell
    // starts the installer and exits, taking this window with it.
    await invoke('install_update');
  } catch (error) {
    show('form');
    say(String(error));
    btnUpdate.disabled = false;
  }
}

/** The primary button: open it the first time, continue or move it after. */
async function go() {
  const config = readForm();

  // Continue with what is already on screen behind this window. Nothing to
  // start, nothing to reconnect - just get out of the way.
  if (chooser && sameAsConnected(config)) {
    await invoke('close_launcher');
    return;
  }

  if (await start(config)) await invoke('close_launcher');
}

async function test() {
  const config = readForm();
  busy(true);
  say('Checking…');
  try {
    const result = await invoke('test_connection', {
      host: config.host,
      port: config.port,
    });
    say(result.detail, result.isIms ? 'ok' : undefined);
  } catch (error) {
    say(String(error));
  } finally {
    busy(false);
  }
}

// ---------------------------------------------------------------------- wiring

modeHost.addEventListener('click', () => setMode('host'));
modeClient.addEventListener('click', () => setMode('client'));
btnTest.addEventListener('click', () => { test(); });
btnGo.addEventListener('click', () => { go(); });

// Saved as it is ticked, not on the way out: this window can also be closed
// with its own close button, and a preference that survives only one of the two
// exits is one that looks broken half the time.
askAgain.addEventListener('change', () => {
  invoke('save_preferences', { askOnOpen: askAgain.checked }).catch(() => {});
});

btnUpdate.addEventListener('click', () => { installUpdate(); });

btnCancel.addEventListener('click', () => {
  // The server it is waiting on may still come up; this only stops watching, so
  // the address can be corrected while it does.
  watchLog(false);
  show('form');
  say('');
});

btnBrowser.addEventListener('click', async () => {
  const config = readForm();
  try {
    await invoke('open_in_browser', { host: config.host, port: config.port });
  } catch (error) {
    say(String(error));
  }
});

for (const input of [inputHost, inputFolder, inputPort]) {
  input.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') go();
  });
}

// ------------------------------------------------------------------- start-up

(async function boot() {
  const config = await invoke('get_config');

  // An update started from the settings screen has no way to be told it failed,
  // so the shell parks the reason and opens this window to carry it.
  const parked = await invoke('pending_error').catch(() => null);

  setMode(config.mode === 'client' ? 'client' : 'host');
  // Set before anything can submit. `readForm()` carries this value, so leaving
  // it at the markup's unchecked default would let a *failed* connection — the
  // one path that reaches the form without going through the chooser — quietly
  // turn "ask every time" off on the retry.
  askAgain.checked = config.askOnOpen !== false;
  inputPort.value = String(config.port || 8080);
  if (config.host && config.host !== '127.0.0.1') inputHost.value = config.host;

  const detected = await invoke('detect_project');
  inputFolder.value = config.projectDir || detected || '';
  if (!config.projectDir && detected) {
    el('folder-hint').textContent = 'Found automatically. Change it if this is wrong.';
  }

  // A first run has nothing to connect to yet, so the form comes up cold.
  //
  // Every later open connects first - the office should not have to answer a
  // question before it can even see the sign-in screen - and then, unless the
  // box at the bottom was ticked to stop it, comes back as the chooser resting
  // on that screen. Same question, asked where the answer is already visible.
  if (parked) {
    // Already connected and running behind this window; the only thing missing
    // was somewhere to put the message.
    await showChooser(config);
    say(parked);
    return;
  }

  if (!config.configured) {
    show('form');
    return;
  }

  if (!await start(config)) return;

  // An update outranks the preference. Somebody who turned the chooser off did
  // so to stop being asked a question they always answer the same way, not to
  // stop being told the app is out of date.
  const updating = await checkUpdate();

  if (config.askOnOpen === false && !updating) {
    await invoke('close_launcher');
  } else {
    await showChooser(config);
  }
}()).catch((error) => {
  show('form');
  say(String(error));
});
