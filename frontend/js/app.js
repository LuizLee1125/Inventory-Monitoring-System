// Bootstrap: session, shell, navigation, routing.

import { api, onUnauthorized } from './api.js';
import { $, clear, el, field, input, modal, reportError, toast } from './ui.js';
import { resolve, route, setNotFound, start } from './router.js';

import * as dashboard from './views/dashboard.js';
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

const NAV = [
  { group: 'Transactions', items: [
    { path: '/', label: 'Dashboard', icon: '▤', permission: 'report:read' },
    { path: '/invoices', label: 'Invoices', icon: '▦', permission: 'invoice:read' },
    { path: '/collections', label: 'Collections', icon: '₱', permission: 'collection:read' },
    { path: '/returns', label: 'Sales Returns', icon: '↩', permission: 'return:read' },
    { path: '/purchases', label: 'Purchases', icon: '⇩', permission: 'purchase:read' },
  ] },
  { group: 'Master files', items: [
    { path: '/stock', label: 'Stock', icon: '▣', permission: 'stock:read' },
    { path: '/customers', label: 'Customers', icon: '☺', permission: 'customer:read' },
    { path: '/suppliers', label: 'Suppliers', icon: '⌂', permission: 'supplier:read' },
  ] },
  { group: 'Reports', items: [
    { path: '/reports/aging', label: 'AR Aging', icon: '⏱', permission: 'report:read' },
    { path: '/reports/sales', label: 'Sales', icon: '↗', permission: 'report:read' },
    { path: '/reports/inventory', label: 'Inventory', icon: '≡', permission: 'report:read' },
    { path: '/reports/expiring', label: 'Expiry & Stock Alerts', icon: '⚑', permission: 'report:read' },
  ] },
  { group: 'System', items: [
    { path: '/admin', label: 'Users & Audit', icon: '⚙', permission: 'admin:users' },
  ] },
];

function buildNav() {
  const nav = $('#nav');
  clear(nav);
  for (const section of NAV) {
    const items = section.items.filter((item) => can(item.permission));
    if (!items.length) continue;
    nav.append(el('div', { class: 'nav-group', text: section.group }));
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
  route('/', guard('report:read', dashboard));
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
  $('#user-chip').innerHTML =
    `<b>${session.user.full_name || session.user.username}</b> · ${roleLabel()}`;

  buildNav();
  if (started) resolve();

  if (session.user.must_change_password) {
    changePassword(true);
  }
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

function changePassword(forced = false) {
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

  $('#btn-logout').addEventListener('click', async () => {
    try { await api.post('/logout'); } catch { /* signing out anyway */ }
    session.user = null;
    showLogin();
  });

  $('#btn-password').addEventListener('click', () => changePassword(false));
  $('#menu-toggle').addEventListener('click', () => $('#sidebar').classList.toggle('open'));

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
