// Bootstrap: session, shell, navigation, routing.

import { api, onUnauthorized } from './api.js';
import { $, clear, el, field, input, modal, reportError, toast } from './ui.js';
import { resolve, route, setNotFound, start } from './router.js';
import { setupSearch } from './omni.js';

import * as home from './views/home.js';
import * as dashboard from './views/dashboard.js';
import * as maintenance from './views/maintenance.js';
import * as purge from './views/purge.js';
import * as archive from './views/archive.js';
import * as stock from './views/stock.js';
import * as customers from './views/customers.js';
import * as suppliers from './views/suppliers.js';
import * as invoices from './views/invoices.js';
import * as purchases from './views/purchases.js';
import * as returns from './views/returns.js';
import * as collections from './views/collections.js';
import * as reports from './views/reports.js';
import * as admin from './views/admin.js';

export const session = { user: null, meta: null };

export const can = (permission) => Boolean(session.user?.permissions?.includes(permission));

/* ----------------------------------------------------------- navigation -- */

// The sidebar keeps the DOS menu's three groupings, because that is the
// taxonomy the office already knows. Master files sat inside Transactions
// there too — Stock File, Customer File and Supplier File were items A, B
// and C — so they stay grouped that way rather than being split out.
const NAV = [
  { group: '', items: [
    { path: '/', label: 'Home', icon: '⌂', permission: 'report:read' },
  ] },
  { group: 'Transactions', items: [
    { path: '/stock', label: 'Stock File', icon: '▣', permission: 'stock:read' },
    { path: '/customers', label: 'Customer File', icon: '☺', permission: 'customer:read' },
    { path: '/suppliers', label: 'Supplier File', icon: '⌂', permission: 'supplier:read' },
    { path: '/invoices', label: 'Invoices', icon: '▦', permission: 'invoice:read' },
    { path: '/purchases', label: 'Purchases', icon: '⇩', permission: 'purchase:read' },
    { path: '/returns', label: 'Sales Returns', icon: '↩', permission: 'return:read' },
    { path: '/collections', label: 'Collections', icon: '₱', permission: 'collection:read' },
    { path: '/archive', label: 'Archived Records', icon: '⛃', permission: 'report:read' },
  ] },
  { group: 'Reports', items: [
    { path: '/reports/price-inquiry', label: 'Price Inquiry', icon: '₱', permission: 'report:read' },
    { path: '/reports/inventory', label: 'Inventory', icon: '≡', permission: 'report:read' },
    { path: '/reports/sales', label: 'Sales Summary', icon: '↗', permission: 'report:read' },
    { path: '/reports/purchases', label: 'Purchase Summary', icon: '⇩', permission: 'report:read' },
    { path: '/reports/aging', label: 'Accounts Receivable', icon: '⏱', permission: 'report:read' },
    { path: '/reports/expiring', label: 'Expiration Inquiry', icon: '⚑', permission: 'report:read' },
    { path: '/overview', label: 'Overview', icon: '▤', permission: 'report:read' },
  ] },
  { group: 'Maintenance', items: [
    { path: '/maintenance', label: 'Backup & Database', icon: '⛁', permission: 'maintenance:run' },
    { path: '/maintenance/purge', label: 'Purging of Records', icon: '⌫', permission: 'maintenance:run' },
    { path: '/archive/summary', label: 'Archive Inquiry', icon: '⛃', permission: 'report:read' },
    { path: '/reports/depleted', label: 'Depleted Stocks', icon: '↓', permission: 'report:read' },
    { path: '/admin', label: 'Users & Audit', icon: '⚙', permission: 'admin:users' },
  ] },
];

function buildNav() {
  const nav = $('#nav');
  clear(nav);
  for (const section of NAV) {
    const items = section.items.filter((item) => can(item.permission));
    if (!items.length) continue;
    if (section.group) nav.append(el('div', { class: 'nav-group', text: section.group }));
    for (const item of items) {
      nav.append(el('a', { href: `#${item.path}`, dataset: { path: item.path } }, [
        el('span', { class: 'ico', text: item.icon }),
        item.label,
      ]));
    }
  }
}

function highlightNav() {
  const path = window.location.hash.slice(1) || '/';
  $('#nav').querySelectorAll('a').forEach((link) => {
    const target = link.dataset.path;
    const active = target === '/' ? path === '/' : path.startsWith(target);
    link.classList.toggle('active', active);
  });
  $('#sidebar').classList.remove('open');
}

export function setTitle(text) {
  $('#page-title').textContent = text;
  document.title = `${text} · ${session.meta?.company || 'IMS'}`;
}

export function page() { return $('#page'); }

/* --------------------------------------------------------------- routes -- */

function mount(view, params) {
  const container = page();
  clear(container);
  // Only the home screen pins itself to the viewport; every other screen
  // scrolls normally.
  container.classList.remove('home-fit');
  highlightNav();
  Promise.resolve(view.render(container, params)).catch(reportError);
}

function guard(permission, view) {
  return (params) => {
    // Nothing renders while signed out; the login screen owns the window.
    if (!session.user) return;
    if (!can(permission)) {
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

  setNotFound(() => {
    setTitle('Not found');
    clear(page());
    page().append(el('div', { class: 'empty' }, ['That screen does not exist.']));
  });
}

/* ------------------------------------------------------------- sign in --- */

function showLogin(message = '') {
  $('#boot').hidden = true;
  $('#shell').hidden = true;
  $('#login').hidden = false;
  const error = $('#login-error');
  error.hidden = !message;
  error.textContent = message;
  $('#login-form').username.focus();
}

async function showShell() {
  $('#boot').hidden = true;
  $('#login').hidden = true;
  $('#shell').hidden = false;

  $('#brand-company').textContent = session.meta.company;
  $('#version-tag').textContent = `v${session.meta.version}`;

  const who = session.user.full_name || session.user.username;
  $('#avatar-initials').textContent = initials(who);
  $('#btn-account').title = who;
  $('#account-name').textContent = who;
  $('#account-role').textContent = roleLabel();

  buildNav();
  setupSearch();
  if (started) resolve();

  if (session.user.must_change_password) {
    changePassword(true);
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
  try {
    session.user = await api.get('/me');
    return true;
  } catch {
    session.user = null;
    return false;
  }
}

export function changePassword(forced = false) {
  const current = input('current_password', { type: 'password', required: true });
  const next = input('new_password', { type: 'password', required: true, minlength: 8 });
  const again = input('confirm', { type: 'password', required: true });

  modal({
    title: forced ? 'Choose a new password' : 'Change password',
    body: el('div', {}, [
      forced ? el('p', { class: 'hint' },
        ['This account was carried over from the DOS system, where passwords were '
         + 'stored in plain text. Set a new one to continue.']) : null,
      field('Current password', current),
      field('New password (8 characters or more)', next),
      field('Repeat new password', again),
    ]),
    actions: [
      forced ? null : { label: 'Cancel' },
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
    ].filter(Boolean),
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

function wireChrome() {
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

  $('#btn-password').addEventListener('click', () => {
    closeAccountMenu();
    changePassword(false);
  });
  $('#menu-toggle').addEventListener('click', () => $('#sidebar').classList.toggle('open'));

  const account = $('#btn-account');
  account.addEventListener('click', (event) => {
    event.stopPropagation();
    const menu = $('#account-menu');
    const opening = menu.hidden;
    menu.hidden = !opening;
    account.setAttribute('aria-expanded', String(opening));
  });
  document.addEventListener('click', closeAccountMenu);
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') closeAccountMenu();
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
  wireChrome();
  registerRoutes();
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
