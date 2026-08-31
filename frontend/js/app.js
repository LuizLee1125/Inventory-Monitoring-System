// Bootstrap: session, shell, navigation, routing.

import { api, onUnauthorized } from './api.js';
import {
  $, clear, el, field, input, modal, pageSkeleton, reportError, toast,
} from './ui.js';
import { currentPath, resolve, route, setNotFound, start } from './router.js';
import { setupSearch } from './omni.js';
import { initTheme } from './theme.js';
import {
  closeNotifications, startNotifications, stopNotifications, wireNotifications,
} from './notify.js';

import * as home from './views/home.js';
import * as dashboard from './views/dashboard.js';
import * as maintenance from './views/maintenance.js';
import * as purge from './views/purge.js';
import * as archive from './views/archive.js';
import * as stock from './views/stock.js';
import * as customers from './views/customers.js';
import * as suppliers from './views/suppliers.js';
import * as invoices from './views/invoices.js';
import * as printInvoice from './views/printInvoice.js';
import * as purchases from './views/purchases.js';
import * as returns from './views/returns.js';
import * as collections from './views/collections.js';
import * as reports from './views/reports.js';
import * as admin from './views/admin.js';
import * as settings from './views/settings.js';
import * as notifications from './views/notifications.js';

export const session = { user: null, meta: null };

export const can = (permission) => Boolean(session.user?.permissions?.includes(permission));

/* --------------------------------------------------------- desktop app -- */

/**
 * Whether this page is being shown by the desktop shell rather than a browser.
 *
 * The shell opens its window on `/?desktop=1&boot=…`; a query string survives
 * the hash routing that is all this application does, so the answer is the same
 * on every screen. Nothing below this line runs in a browser.
 */
export const inDesktopApp = () =>
  new URLSearchParams(window.location.search).has('desktop');

const DESKTOP_BOOT_KEY = 'ims.desktop.boot';

/**
 * The desktop app starts signed out, every time.
 *
 * A browser tab is somebody's own; an installed application on a shared counter
 * PC is not, and leaving the last person still signed in when the next one
 * opens it is how the wrong name ends up on an invoice. So closing the app ends
 * the session — implemented here, at the next open, because a process that is
 * killed or loses power never gets to run a tidy-up.
 *
 * "Was the app just opened?" is answered by `boot`, which the shell regenerates
 * once per launch, held against `sessionStorage`, which the webview drops when
 * it closes. Either signal alone would do; together they still give the right
 * answer if one of them behaves differently on some future WebView2. A reload
 * inside a run matches on both and is left alone — nobody expects F5 to sign
 * them out.
 */
async function endDesktopSession() {
  if (!inDesktopApp()) return;

  const boot = new URLSearchParams(window.location.search).get('boot') || '';
  try {
    if (sessionStorage.getItem(DESKTOP_BOOT_KEY) === boot) return;
    sessionStorage.setItem(DESKTOP_BOOT_KEY, boot);
  } catch {
    // Storage unavailable: sign out rather than risk carrying a session over.
  }

  // Deliberately not api.post: a 401 here is the ordinary answer when nobody
  // was signed in, and it must not reach the unauthorized listeners, whose job
  // is to announce a session that ended in the middle of somebody's work.
  try {
    await fetch('/api/logout', { method: 'POST', credentials: 'same-origin' });
  } catch {
    // Offline, or the session was already gone. The sign-in screen is next
    // either way.
  }
}

/* ----------------------------------------------------------- navigation -- */

// The sidebar keeps the DOS menu's three groupings, because that is the
// taxonomy the office already knows. Master files sat inside Transactions
// there too — Stock File, Customer File and Supplier File were items A, B
// and C — so they stay grouped that way rather than being split out.
// `icon` names a drawn mark — `--nav-<name>` and `--nav-<name>-on` in app.css,
// which is where the drawings and the reasoning live. It used to be a Unicode
// character per row, and half of them had no glyph in the interface font.
// Every name here is distinct; four of the characters were not.
const NAV = [
  { group: '', items: [
    { path: '/', label: 'Home', icon: 'home', permission: 'report:read' },
  ] },
  { group: 'Transactions', items: [
    { path: '/stock', label: 'Stock File', icon: 'box', permission: 'stock:read' },
    { path: '/customers', label: 'Customer File', icon: 'users', permission: 'customer:read' },
    { path: '/suppliers', label: 'Supplier File', icon: 'truck', permission: 'supplier:read' },
    { path: '/invoices', label: 'Invoices', icon: 'invoice', permission: 'invoice:read' },
    // The sales account reaches invoices to print them, not to browse them, so
    // its sidebar names the errand. Other roles get there from the invoice.
    { path: '/invoices/print', label: 'Print Invoice', icon: 'printer',
      permission: 'invoice:read', roles: ['sales'] },
    { path: '/purchases', label: 'Purchases', icon: 'inbound', permission: 'purchase:read' },
    { path: '/returns', label: 'Sales Returns', icon: 'return', permission: 'return:read' },
    { path: '/collections', label: 'Collections', icon: 'cash', permission: 'collection:read' },
    { path: '/archive', label: 'Archived Records', icon: 'archive', permission: 'report:read' },
  ] },
  { group: 'Reports', items: [
    { path: '/reports/price-inquiry', label: 'Price Inquiry', icon: 'tag', permission: 'report:read' },
    { path: '/reports/inventory', label: 'Inventory', icon: 'clipboard', permission: 'report:read' },
    { path: '/reports/sales', label: 'Sales Summary', icon: 'trend-up', permission: 'report:read' },
    { path: '/reports/purchases', label: 'Purchase Summary', icon: 'trend-down', permission: 'report:read' },
    { path: '/reports/purchased-items', label: 'Purchased Items', icon: 'checklist', permission: 'report:read' },
    { path: '/reports/stock-purchases', label: 'View Purchases', icon: 'lookup', permission: 'report:read' },
    { path: '/reports/aging', label: 'Accounts Receivable', icon: 'clock', permission: 'report:read' },
    { path: '/reports/expiring', label: 'Expiration Inquiry', icon: 'hourglass', permission: 'report:read' },
    { path: '/overview', label: 'Overview', icon: 'grid', permission: 'report:read' },
  ] },
  { group: 'Maintenance', items: [
    { path: '/maintenance', label: 'Backup & Database', icon: 'database', permission: 'maintenance:run' },
    { path: '/maintenance/purge', label: 'Purging of Records', icon: 'trash', permission: 'maintenance:run' },
    { path: '/archive/summary', label: 'Archive Inquiry', icon: 'archive-find', permission: 'report:read' },
    { path: '/reports/depleted', label: 'Depleted Stocks', icon: 'box-down', permission: 'report:read' },
    { path: '/admin', label: 'Users & Audit', icon: 'shield', permission: 'admin:users' },
  ] },
];

// Some roles are given a smaller system than their permissions would allow.
// The DOS build did the same thing with ACCESMNU: a sales clerk could read the
// same files as everyone else, but was only ever shown the Sales Order menu —
// two destinations and an exit. A role listed here sees those screens and
// nothing else; a role that is absent sees everything it has rights to.
//
// This shapes the UI, not the API. Permissions remain the real boundary.
const ROLE_SCREENS = {
  sales: [
    '/', '/invoices', '/stock', '/customers',
    '/reports/price-inquiry', '/reports/stock-purchases',
  ],
};

// Screens that belong to the account rather than to the business. Every signed-in
// user reaches these whatever their role shows them, which is why they sit
// outside ROLE_SCREENS instead of being repeated in each role's list.
//
// `/notifications` qualifies for the same reason `/settings` does: the list is
// this person's, and what it may contain is already filtered by permission on
// the server. It has no sidebar entry — the bell is the only way in — so it
// appears here and nowhere in NAV.
const ACCOUNT_SCREENS = ['/settings', '/notifications'];

function allowed(path) {
  const target = path.split('?')[0];
  if (ACCOUNT_SCREENS.includes(target)) return true;
  const screens = ROLE_SCREENS[session.user?.role];
  if (!screens) return true;
  return screens.some((screen) => (screen === '/'
    ? target === '/'
    : target === screen || target.startsWith(`${screen}/`)));
}

// The arrival stagger stops being a stagger and starts being a wait somewhere
// around here; a role that sees every screen has twenty-four rows.
const NAV_STAGGER_CAP = 12;

function buildNav() {
  const nav = $('#nav');
  clear(nav);

  // First in the DOM so the links paint over it.
  // 'true' as a string, not a boolean: el() writes a bare `true` out as an
  // empty attribute, and `aria-hidden=""` is an invalid token that resolves
  // back to "not hidden".
  nav.append(el('span', { class: 'nav-pill', id: 'nav-pill', 'aria-hidden': 'true' }));

  let index = 0;
  for (const section of NAV) {
    const items = section.items.filter((item) => can(item.permission)
      && allowed(item.path)
      && (!item.roles || item.roles.includes(session.user?.role)));
    if (!items.length) continue;
    if (section.group) nav.append(el('div', { class: 'nav-group', text: section.group }));
    for (const item of items) {
      nav.append(el('a', {
        href: `#${item.path}`,
        dataset: { path: item.path },
        style: `--i:${Math.min(index += 1, NAV_STAGGER_CAP)};`
          + `--nav-icon:var(--nav-${item.icon});--nav-icon-on:var(--nav-${item.icon}-on)`,
      }, [
        el('span', { class: 'ico', 'aria-hidden': 'true' }),
        item.label,
      ]));
    }
  }
}

// The pill is one element sliding between rows rather than a background on each
// of them, so it is placed here — after the active row is known — instead of in
// CSS. `.nav` is `position: relative`, which makes it the offset parent: the
// link's own `offsetTop` is already the number wanted, and it scrolls with the
// content the way a `getBoundingClientRect` reading would not.
function placeNavPill(active) {
  const pill = $('#nav-pill');
  if (!pill) return;
  if (!active) { pill.classList.remove('on'); return; }

  pill.style.transform = `translate(${active.offsetLeft}px, ${active.offsetTop}px)`;
  pill.style.width = `${active.offsetWidth}px`;
  pill.style.height = `${active.offsetHeight}px`;
  pill.classList.add('on');

  // Animated only from the second placement onwards, or it flies down the rail
  // from the top on every sign-in. One frame is enough for the first to land.
  if (!pill.classList.contains('ready')) {
    requestAnimationFrame(() => pill.classList.add('ready'));
  }
}

function highlightNav() {
  const path = (window.location.hash.slice(1) || '/').split('?')[0];
  const links = [...$('#nav').querySelectorAll('a')];

  // Only the most specific entry lights up. Without this, /invoices/print
  // marks both Invoices and Print Invoice, because one path is a prefix of the
  // other.
  const matches = links.filter((link) => {
    const target = link.dataset.path;
    return target === '/' ? path === '/' : path === target || path.startsWith(`${target}/`);
  });
  const best = matches.reduce((longest, link) =>
    (!longest || link.dataset.path.length > longest.dataset.path.length ? link : longest), null);

  for (const link of links) link.classList.toggle('active', link === best);
  placeNavPill(best);
  $('#sidebar').classList.remove('open');
}

// The rail is a fixed width, but it becomes a full-height drawer below 900px
// and the rows change height with the font. Nothing else re-measures it.
window.addEventListener('resize', () => {
  placeNavPill($('#nav')?.querySelector('a.active'));
});

export function setTitle(text) {
  $('#page-title').textContent = text;
  document.title = `${text} · ${session.meta?.company || 'IMS'}`;
}

export function page() { return $('#page'); }

/* --------------------------------------------------------------- routes -- */

let leaving = null;

function mount(view, params) {
  const container = page();
  leaving?.();
  leaving = view.leave || null;
  clear(container);
  // Only the home screen pins itself to the viewport; every other screen
  // scrolls normally.
  container.classList.remove('home-fit');
  highlightNav();

  // The class stays on for the life of the screen. clear() has just removed
  // every child, so whatever render() appends is a new element and starts its
  // enter animation on insertion — including the parts that arrive late,
  // after their fetch resolves.
  container.classList.add('entering');

  // Every screen fetches before it can draw, and until it does the page is
  // empty. Rather than each view remembering to say so, the placeholder goes in
  // here and leaves the moment the view appends anything of its own — which is
  // its toolbar for a list screen, or the finished page for one that awaits
  // first. A view names the shape it wants by exporting `skeleton`.
  // A module serves both its list and its detail screens, which are different
  // shapes, so `skeleton` may be a function of the route parameters.
  const shape = typeof view.skeleton === 'function'
    ? view.skeleton(params) : view.skeleton;
  const placeholder = pageSkeleton(shape);
  container.append(placeholder);

  const watcher = new MutationObserver(() => {
    if ([...container.children].some((child) => child !== placeholder)) {
      placeholder.remove();
      watcher.disconnect();
    }
  });
  watcher.observe(container, { childList: true });

  Promise.resolve(view.render(container, params))
    .catch(reportError)
    // Also the safety net: a screen that renders nothing at all, or throws,
    // must not be left showing a placeholder for something that is not coming.
    .finally(() => { watcher.disconnect(); placeholder.remove(); });
}

function guard(permission, view) {
  return (params, full) => {
    // Nothing renders while signed out; the login screen owns the window.
    if (!session.user) return;
    if (!can(permission) || !allowed(full ?? currentPath())) {
      setTitle('Not allowed');
      clear(page());
      page().append(el('div', { class: 'empty' },
        ['Your role does not have access to this screen.']));
      return;
    }
    mount(view, params);
  };
}

function registerRoutes() {
  route('/', guard('report:read', home));
  route('/overview', guard('report:read', dashboard));
  route('/maintenance', guard('maintenance:run', maintenance));
  route('/maintenance/purge', guard('maintenance:run', purge));
  route('/archive', guard('report:read', archive));
  route('/archive/summary', guard('report:read', archive));
  route('/archive/:kind/:number', guard('report:read', archive));
  route('/stock', guard('stock:read', stock));
  route('/stock/:code', guard('stock:read', stock));
  route('/customers', guard('customer:read', customers));
  route('/customers/:code', guard('customer:read', customers));
  route('/suppliers', guard('supplier:read', suppliers));
  route('/suppliers/:code', guard('supplier:read', suppliers));
  route('/invoices', guard('invoice:read', invoices));
  route('/invoices/new', guard('invoice:write', invoices));
  // Both of these must be registered before '/invoices/:id', which would
  // otherwise swallow 'print' as an invoice number.
  route('/invoices/print', guard('invoice:read', printInvoice));
  route('/invoices/print/:id', guard('invoice:read', printInvoice));
  route('/invoices/:id', guard('invoice:read', invoices));
  route('/purchases', guard('purchase:read', purchases));
  route('/purchases/new', guard('purchase:write', purchases));
  route('/purchases/:id', guard('purchase:read', purchases));
  route('/returns', guard('return:read', returns));
  route('/returns/new', guard('return:write', returns));
  route('/returns/:id', guard('return:read', returns));
  route('/collections', guard('collection:read', collections));
  route('/collections/new', guard('collection:write', collections));
  route('/collections/:id', guard('collection:read', collections));
  route('/reports/:name', guard('report:read', reports));
  route('/admin', guard('admin:users', admin));
  // Settings needs no permission beyond being signed in: it is this person's
  // own account, and every role has one.
  route('/settings', (params) => {
    if (session.user) mount(settings, params);
  });
  // Same reasoning: everybody has notifications, and which ones they are is
  // decided per row on the server rather than by a permission on the route.
  route('/notifications', (params) => {
    if (session.user) mount(notifications, params);
  });

  setNotFound(() => {
    setTitle('Not found');
    clear(page());
    page().append(el('div', { class: 'empty' }, ['That screen does not exist.']));
  });
}

/* ------------------------------------------------------------- sign in --- */

// How long a rejected sign-in stays on screen. Long enough to read twice and
// look back at what was typed; short enough that it is gone before the next
// person walks up to the terminal.
const LOGIN_ERROR_MS = 10000;
let loginErrorTimer = null;

/**
 * Show — or re-show — the sign-in error.
 *
 * Arriving and being told the same thing again are different events and get
 * different animations: a banner that is already on screen cannot announce
 * itself by fading in, because it never faded out. It shakes instead.
 *
 * Both need the animation *restarted*, which setting a class does not do on
 * its own: the browser coalesces the removal and the addition into one style
 * recalculation and sees no change. Reading `offsetWidth` between them forces
 * the flush that makes it a change.
 */
function showLoginError(message) {
  const error = $('#login-error');
  clearTimeout(loginErrorTimer);

  if (!message) {
    error.hidden = true;
    error.className = 'login-error';
    return;
  }

  const returning = !error.hidden;
  error.textContent = message;
  error.hidden = false;
  error.className = 'login-error';
  void error.offsetWidth;
  error.classList.add(returning ? 'again' : 'arriving');

  loginErrorTimer = setTimeout(() => {
    error.classList.add('leaving');

    const finish = () => {
      // A fresh error can arrive mid-fade, and it clears `leaving` on its way
      // in. Without this check the shake it plays would end on this listener
      // and hide a banner that had just been raised again.
      if (!error.classList.contains('leaving')) return;
      error.hidden = true;
      error.className = 'login-error';
    };

    // The event is the signal; the timer is the guarantee. A tab in the
    // background does not run animation frames, so `animationend` may never
    // arrive — and a banner that fails to leave would sit there until the page
    // was reloaded.
    error.addEventListener('animationend', finish, { once: true });
    loginErrorTimer = setTimeout(finish, 700);
  }, LOGIN_ERROR_MS);
}

function showLogin(message = '') {
  $('#boot').hidden = true;
  $('#shell').hidden = true;
  $('#login').hidden = false;
  showLoginError(message);

  // Every way back to this screen comes through here — signing out, an expired
  // session, a rejected call — so it is the one place the poll has to be
  // stopped. Left running it would keep asking a server that has already said
  // 401, and the next person to sign in would inherit the last one's badge.
  stopNotifications();

  // A password left revealed must not still be on screen for whoever signs in
  // next, and the caps warning belongs to the attempt that raised it.
  const form = $('#login-form');
  form.password.type = 'password';
  const reveal = $('#login-reveal');
  reveal.setAttribute('aria-pressed', 'false');
  reveal.setAttribute('aria-label', 'Show password');
  reveal.hidden = !form.password.value;
  $('#login-caps').hidden = true;
  form.username.focus();
}

async function showShell() {
  $('#boot').hidden = true;
  $('#login').hidden = true;
  $('#shell').hidden = false;

  $('#brand-company').textContent = session.meta.company;
  $('#version-tag').textContent = `v${session.meta.version}`;

  const who = session.user.full_name || session.user.username;
  $('#avatar-initials').textContent = initials(who);
  $('#account-avatar').textContent = initials(who);
  $('#btn-account').title = who;
  $('#account-name').textContent = who;
  $('#account-role').textContent = roleLabel();

  buildNav();
  setupSearch();
  startNotifications();
  if (started) resolve();

  if (session.user.must_change_password) {
    forcePasswordChange();
  }
}

function initials(name) {
  const parts = String(name).trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return '··';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function roleLabel() {
  return session.meta?.roles?.[session.user.role]?.label || session.user.role;
}

async function loadSession() {
  session.meta = await api.get('/meta');
  $('#login-company').textContent = session.meta.company;
  $('#login-org').textContent = session.meta.company;
  $('#login-version').textContent = `v${session.meta.version}`;
  try {
    session.user = await api.get('/me');
    return true;
  } catch {
    session.user = null;
    return false;
  }
}

/**
 * The one case that still needs a modal: an account carried over from the DOS
 * system, stopped at the door until it has a password of its own. Changing a
 * password by choice is a section of the settings screen.
 *
 * There is no Cancel. The account cannot be used until this is done.
 */
function forcePasswordChange() {
  const current = input('current_password', { type: 'password', required: true });
  const next = input('new_password', { type: 'password', required: true, minlength: 8 });
  const again = input('confirm', { type: 'password', required: true });

  modal({
    title: 'Choose a new password',
    body: el('div', {}, [
      el('p', { class: 'hint' },
        ['This account was carried over from the DOS system, where passwords were '
         + 'stored in plain text. Set a new one to continue.']),
      field('Current password', current),
      field('New password (8 characters or more)', next),
      field('Repeat new password', again),
    ]),
    actions: [
      {
        label: 'Save',
        kind: 'primary',
        onClick: async () => {
          if (next.value !== again.value) {
            toast('The two new passwords do not match.', 'error');
            return 'keep';
          }
          await api.post('/change-password', {
            current_password: current.value, new_password: next.value,
          });
          session.user.must_change_password = false;
          toast('Password changed.', 'success');
        },
      },
    ],
  });
}

/* ----------------------------------------------------------------- boot -- */

export async function signOut() {
  closeAccountMenu();
  try { await api.post('/logout'); } catch { /* signing out anyway */ }
  session.user = null;
  showLogin();
}

function closeAccountMenu() {
  const menu = $('#account-menu');
  if (menu && !menu.hidden) {
    menu.hidden = true;
    $('#btn-account').setAttribute('aria-expanded', 'false');
  }
}

function wireLogin() {
  const form = $('#login-form');
  const password = form.password;
  const reveal = $('#login-reveal');
  const caps = $('#login-caps');

  reveal.addEventListener('click', () => {
    const showing = password.type === 'text';
    password.type = showing ? 'password' : 'text';
    reveal.setAttribute('aria-pressed', String(!showing));
    reveal.setAttribute('aria-label', showing ? 'Show password' : 'Hide password');
    password.focus();
  });

  // Nothing typed, nothing to reveal — an eye over an empty box is a control
  // that does nothing, sitting where the cursor is about to go.
  password.addEventListener('input', () => {
    reveal.hidden = !password.value;
    if (!password.value && password.type === 'text') {
      password.type = 'password';
      reveal.setAttribute('aria-pressed', 'false');
      reveal.setAttribute('aria-label', 'Show password');
    }
  });

  // Every user name here is upper case, carried over from the DOS access file,
  // so people hold Caps Lock to type one and then type their password with it
  // still down. Saying so is the difference between one failed sign-in and a
  // call to whoever administers the system.
  const checkCaps = (event) => {
    caps.hidden = !event.getModifierState?.('CapsLock');
  };
  for (const node of [form.username, password]) {
    node.addEventListener('keyup', checkCaps);
    node.addEventListener('keydown', checkCaps);
  }
  password.addEventListener('blur', () => { caps.hidden = true; });
}

function wireChrome() {
  wireLogin();

  $('#login-form').addEventListener('submit', async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const button = form.querySelector('button');
    button.disabled = true;
    try {
      session.user = await api.post('/login', {
        username: form.username.value, password: form.password.value,
      });
      form.reset();
      await showShell();
    } catch (error) {
      showLogin(error.detail || 'Could not sign in.');
    } finally {
      button.disabled = false;
    }
  });

  $('#btn-logout').addEventListener('click', signOut);

  // An anchor, so the router handles it; the menu just has to get out of the way.
  $('#btn-settings').addEventListener('click', closeAccountMenu);
  $('#menu-toggle').addEventListener('click', () => $('#sidebar').classList.toggle('open'));

  wireNotifications();
  // The panel closes the account menu from this side, because notify.js cannot
  // import from app.js without a cycle. `stopPropagation` inside its own
  // handler stops the event bubbling, not the other listeners on this button.
  $('#btn-bell').addEventListener('click', closeAccountMenu);

  const account = $('#btn-account');
  account.addEventListener('click', (event) => {
    event.stopPropagation();
    const menu = $('#account-menu');
    const opening = menu.hidden;
    menu.hidden = !opening;
    account.setAttribute('aria-expanded', String(opening));
    // Two popovers in one corner: opening either closes the other, or they
    // overlap and both claim to be open.
    if (opening) closeNotifications();
  });
  document.addEventListener('click', () => {
    closeAccountMenu();
    closeNotifications();
  });
  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') return;
    closeAccountMenu();
    closeNotifications();
  });

  onUnauthorized(() => {
    if (session.user) {
      session.user = null;
      showLogin('Your session has ended. Sign in again.');
    }
  });

  window.addEventListener('hashchange', highlightNav);
}

let started = false;

async function boot() {
  // The inline script in index.html has already painted the right theme; this
  // takes over so the picker and the system-change listener work.
  initTheme();
  wireChrome();
  registerRoutes();
  // Before the session is read, not after: in the desktop app a session left
  // over from the last time it was open has to be ended, or the shell would
  // hand the next person the previous one's account.
  await endDesktopSession();
  // Routing only begins once the session is known, so a guarded screen is
  // never rendered before permissions have loaded.
  const signedIn = await loadSession();
  if (signedIn) await showShell();
  else showLogin();
  started = true;
  start();
}

boot().catch((error) => {
  $('#boot').textContent = `Could not start: ${error.message}`;
});
