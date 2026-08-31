// The live channel: one EventSource for the whole page, and the subscriptions
// hanging off it.
//
// The server pushes; nothing here ever sends. `backend/app/events.py` decides
// what each account is allowed to hear, so a handler registered for an event
// this user cannot receive simply never fires — there is no client-side filter
// to keep in step with the server's.
//
// Reference is NTC-TMS-Tauri's `useRealtime`, which holds one socket.io
// connection for the application and ref-counts the listeners on it. Same shape,
// no dependency: `EventSource` is in the browser, `socket.io-client` is 40 KB
// and a build step this application does not have.
//
// ----------------------------------------------------------------------------
// The rule that matters here is that a workstation must cost nothing while
// nobody is using it. Three things enforce it, and none of them is optional:
//
//   * the connection is closed on `visibilitychange` and reopened from where it
//     left off. A counter PC left on overnight holds nothing open;
//   * a handler runs only while the screen that registered it is mounted —
//     `mount()` in app.js calls the view's `leave`, which unsubscribes;
//   * `onChange()` debounces, so a save that touches forty stock codes causes
//     one refetch on each open screen rather than forty.
//
// This replaces a 60-second poll, so it is a reduction in work: ten counter PCs
// were making 14,400 requests a day between them to be told nothing had changed.

import { toast } from './ui.js';

// Long enough to swallow a burst — a purchase receipt publishing one event per
// document plus one coalesced stock event — short enough that a screen never
// looks stale to somebody watching it.
const REFRESH_MS = 400;

// The server's own `retry:` is 3 s and the browser honours it. Past a few
// consecutive failures the server is not coming straight back — it is being
// restarted, or the office switch is down — and hammering it every three
// seconds helps nobody. From there the delay doubles to a half-minute ceiling.
const BACKOFF_FROM = 3;
const BACKOFF_BASE_MS = 3000;
const BACKOFF_MAX_MS = 30000;

let source = null;
let lastId = '';
let failures = 0;
let retryTimer = null;
let everConnected = false;
let wanted = false;              // whether a signed-in session wants a stream

const handlers = new Map();      // event name -> Set of functions
const stateListeners = new Set();
let state = 'idle';              // idle | connecting | live | reconnecting

/* -------------------------------------------------------------- plumbing -- */

function setState(next) {
  if (state === next) return;
  state = next;
  for (const fn of stateListeners) {
    try { fn(state); } catch { /* an indicator must never break the stream */ }
  }
}

export function liveState() { return state; }

export function onLiveState(fn) {
  stateListeners.add(fn);
  fn(state);
  return () => stateListeners.delete(fn);
}

function emit(name, data) {
  const set = handlers.get(name);
  if (!set) return;
  for (const fn of [...set]) {
    try {
      fn(data);
    } catch (error) {
      // One screen's handler throwing must not stop the others being told, and
      // must not take the connection down with it.
      console.error(`live handler for ${name} failed`, error);
    }
  }
}

// Every event the server can send has to be named here: EventSource dispatches
// by name, so an unlisted one arrives at no listener at all. Adding a
// `batch.add("thing:done", …)` on the server without adding it here is the one
// way to make an event that is delivered and never seen.
const EVENTS = [
  'connection:ack',
  'sync:required',
  'notification:changed',
  'notification:read',
  'invoice:created',
  'invoice:updated',
  'invoice:cancelled',
  'purchase:created',
  'return:created',
  'collection:created',
  'collection:reversed',
  'stock:changed',
  'stock:short',
];

function attach(stream) {
  for (const name of EVENTS) {
    stream.addEventListener(name, (event) => {
      if (event.lastEventId) lastId = event.lastEventId;

      let data = null;
      try { data = event.data ? JSON.parse(event.data) : null; } catch { data = null; }

      if (name === 'connection:ack') {
        failures = 0;
        setState('live');
        // A reconnection the ring could not fill means this page has been out
        // of touch for longer than the server remembers. Whatever is on screen
        // may be stale in ways no event will now describe, so every subscriber
        // is told to fetch again. Not on the first connect: nothing has been
        // missed by a page that has only just loaded.
        if (everConnected && !data?.recovered) emit('live:resync', { reason: 'gap' });
        everConnected = true;
        return;
      }

      if (name === 'sync:required') {
        emit('live:resync', { reason: data?.reason || 'backlog' });
        return;
      }

      emit(name, data);
    });
  }
}

function open() {
  if (!wanted || source) return;
  clearTimeout(retryTimer);
  retryTimer = null;
  setState(everConnected ? 'reconnecting' : 'connecting');

  // `Last-Event-ID` is a header the browser sets on *its own* automatic retries
  // and there is no way to set it by hand. Reopening after a deliberate close —
  // which is what returning to a hidden tab is — therefore has to carry the
  // position in the query string instead, or every wake-up would be a full
  // resync.
  const query = lastId ? `?since=${encodeURIComponent(lastId)}` : '';
  const stream = new EventSource(`/api/events${query}`, { withCredentials: true });
  source = stream;
  attach(stream);

  stream.onerror = () => {
    // CONNECTING means the browser is retrying on its own and will succeed
    // quietly if the server comes back; there is nothing useful to do but say
    // so on the indicator.
    if (stream.readyState === EventSource.CONNECTING) {
      failures += 1;
      setState('reconnecting');
      if (failures >= BACKOFF_FROM) {
        // Take the retry over from the browser, whose interval is flat.
        stream.close();
        if (source === stream) source = null;
        const wait = Math.min(BACKOFF_MAX_MS,
          BACKOFF_BASE_MS * 2 ** (failures - BACKOFF_FROM + 1));
        retryTimer = setTimeout(open, wait);
      }
      return;
    }
    // CLOSED: the browser has given up. Ours to restart.
    if (source === stream) source = null;
    failures += 1;
    setState('reconnecting');
    retryTimer = setTimeout(open, Math.min(BACKOFF_MAX_MS,
      BACKOFF_BASE_MS * 2 ** Math.max(0, failures - BACKOFF_FROM)));
  };
}

function close() {
  clearTimeout(retryTimer);
  retryTimer = null;
  if (source) {
    source.close();
    source = null;
  }
}

/* ----------------------------------------------------------------- api --- */

/**
 * Open the stream. Called once, from `showShell()`, when a session exists.
 */
export function startLive() {
  wanted = true;
  if (!document.hidden) open();
}

/**
 * Close it and forget everything. Called from `showLogin()`, which is the one
 * place every route back to the sign-in screen passes through — the same
 * reasoning that puts `stopNotifications()` there. Left running it would keep a
 * stream open against a server that has already said 401, and the position
 * would carry over to whoever signed in next.
 */
export function stopLive() {
  wanted = false;
  close();
  lastId = '';
  failures = 0;
  everConnected = false;
  setState('idle');
}

/**
 * Listen for one or more server events.
 *
 * `names` may include `live:resync`, which fires when the connection came back
 * with a gap the server could not fill — the cue to refetch rather than to
 * apply a change.
 *
 * Returns an unsubscribe. A view that subscribes **must** call it from `leave`,
 * or its handler goes on refetching a screen nobody is looking at.
 */
export function subscribe(names, handler) {
  const list = Array.isArray(names) ? names : [names];
  for (const name of list) {
    if (!handlers.has(name)) handlers.set(name, new Set());
    handlers.get(name).add(handler);
  }
  return () => {
    for (const name of list) {
      const set = handlers.get(name);
      if (!set) continue;
      set.delete(handler);
      if (!set.size) handlers.delete(name);
    }
  };
}

/**
 * The shape almost every screen wants: "something I am showing has changed,
 * fetch it again" — debounced, and skipped while the tab is hidden.
 *
 * The debounce is the whole point. An invoice with forty lines publishes one
 * coalesced `stock:changed`, but a purchase receipt also publishes
 * `purchase:created` beside it, and a screen listening for both would otherwise
 * redraw twice for one save.
 */
export function onChange(names, fn, { wait = REFRESH_MS } = {}) {
  let timer = null;
  const run = () => {
    timer = null;
    if (document.hidden) return;
    Promise.resolve(fn()).catch(() => { /* the next event tries again */ });
  };
  const off = subscribe([...(Array.isArray(names) ? names : [names]), 'live:resync'],
    () => {
      clearTimeout(timer);
      timer = setTimeout(run, wait);
    });
  return () => { clearTimeout(timer); off(); };
}

/**
 * Announce something that happened elsewhere, once, as a toast — for the events
 * worth interrupting somebody over rather than quietly redrawing.
 *
 * Deliberately narrow. A toast for every invoice the office raises would be
 * noise within an hour; this exists for the few that are somebody else's
 * problem landing on your desk.
 */
export function announce(name, describe, { kind = 'info', title = '' } = {}) {
  return subscribe(name, (data) => {
    const message = describe(data);
    if (message) toast(message, kind, title);
  });
}

/* ------------------------------------------------------------ lifecycle -- */

// A hidden tab is told nothing and asks for nothing. Reopening resumes from
// `lastId`, so the gap is filled from the server's ring if it is still inside
// the window and reported as a resync if it is not.
document.addEventListener('visibilitychange', () => {
  if (!wanted) return;
  if (document.hidden) close();
  else open();
});

// A tab being closed should release the connection immediately rather than
// leaving the server to notice the socket has gone.
window.addEventListener('pagehide', close);
