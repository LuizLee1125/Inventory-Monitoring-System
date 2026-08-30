// Home — one screen, no scrolling.
//
// The DOS main menu was a list of twenty-nine places to go. A screen that can
// show live data should not spend itself on a second copy of the sidebar, so
// this shows the state of the business instead: what happened today, who owes
// the most, and whether the system itself is healthy — one panel for each of
// the three columns the office knows.
//
// The letter keys survive. They are bound to every destination the old menu
// reached, whether or not it is drawn here, because pressing G for Collections
// is muscle memory. Each panel shows a few of them so they stay discoverable.

import { api } from '../api.js';
import { count, el, money, toast } from '../ui.js';
import { can, changePassword, session, setTitle, signOut } from '../app.js';

const ACTIONS = {
  password: () => changePassword(false),
  signout: () => signOut(),
};

// Every destination the DOS menu had, on the key it had. Not all are drawn.
const SHORTCUTS = [
  { key: 'A', label: 'Stock File', path: '/stock', permission: 'stock:read' },
  { key: 'B', label: 'Customer File', path: '/customers', permission: 'customer:read' },
  { key: 'C', label: 'Supplier File', path: '/suppliers', permission: 'supplier:read' },
  { key: 'D', label: 'Invoices', path: '/invoices', permission: 'invoice:read' },
  { key: 'E', label: 'Purchases', path: '/purchases', permission: 'purchase:read' },
  { key: 'F', label: 'Sales Returns', path: '/returns', permission: 'return:read' },
  { key: 'G', label: 'Collections', path: '/collections', permission: 'collection:read' },
  { key: 'H', label: 'Archived Records', path: '/archive', permission: 'report:read' },
  { key: 'N', label: 'Price Inquiry', path: '/reports/price-inquiry', permission: 'report:read' },
  { key: 'O', label: 'Stock Inquiry', path: '/stock', permission: 'stock:read' },
  { key: 'P', label: 'Inventory', path: '/reports/inventory', permission: 'report:read' },
  { key: 'Q', label: 'Customer List', path: '/customers', permission: 'customer:read' },
  { key: 'R', label: 'Supplier List', path: '/suppliers', permission: 'supplier:read' },
  { key: 'S', label: 'Sales Summary', path: '/reports/sales', permission: 'report:read' },
  { key: 'T', label: 'Purchase Summary', path: '/reports/purchases', permission: 'report:read' },
  { key: 'U', label: 'Purchased Items', path: '/reports/purchased-items', permission: 'report:read' },
  { key: 'V', label: 'Return Summary', path: '/reports/returns-summary', permission: 'return:read' },
  { key: 'W', label: 'Receivables', path: '/reports/aging', permission: 'report:read' },
  { key: 'X', label: 'Collection Summary', path: '/reports/collections', permission: 'report:read' },
  { key: 'Y', label: 'Inactive Customers', path: '/reports/inactive-customers', permission: 'report:read' },
  { key: 'Z', label: 'Overview', path: '/overview', permission: 'report:read' },
  { key: '1', label: 'Exit', action: 'signout', permission: 'report:read' },
  { key: '2', label: 'Purging of Records', path: '/maintenance/purge', permission: 'maintenance:run' },
  { key: '3', label: 'Users & Audit', path: '/admin', permission: 'admin:users' },
  { key: '4', label: 'ReIndex Files', path: '/maintenance', permission: 'maintenance:run' },
  { key: '5', label: 'Back-up Files', path: '/maintenance', permission: 'maintenance:run' },
  { key: '6', label: 'Expiration Inquiry', path: '/reports/expiring', permission: 'report:read' },
  { key: '7', label: 'Depleted Stocks', path: '/reports/depleted', permission: 'report:read' },
  { key: '8', label: 'Archive Inquiry', path: '/archive/summary', permission: 'report:read' },
  { key: '9', label: 'Change Password', action: 'password', permission: 'report:read' },
];

const ROLE_LEAD = {
  admin: 'Everything is here.',
  manager: 'The whole system, minus user administration.',
  invoicing: 'Invoicing and the customer file.',
  ar: 'Collections and what is still owed.',
  sales: 'Prices, stock on hand and your customers.',
  inventory: 'Stock, purchasing and the supplier file.',
  viewer: 'Read-only access.',
};

const PRIMARY = {
  manager: { label: 'Open receivables', path: '/reports/aging', permission: 'report:read' },
  invoicing: { label: 'Raise an invoice', path: '/invoices/new', permission: 'invoice:write' },
  ar: { label: 'Record a payment', path: '/collections/new', permission: 'collection:write' },
  sales: { label: 'Look up an item', path: '/stock', permission: 'stock:read' },
  inventory: { label: 'Receive a delivery', path: '/purchases/new', permission: 'purchase:write' },
};

/* --------------------------------------------------------------- render -- */

export async function render(container) {
  setTitle('Home');
  detachShortcuts?.();
  container.classList.add('home-fit');

  const [dash, aging, maint, admin] = await Promise.all([
    api.get('/reports/dashboard'),
    can('report:read') ? api.get('/reports/aging', { page_size: 10 }).catch(() => null) : null,
    can('maintenance:run') ? api.get('/maintenance/status').catch(() => null) : null,
    can('admin:users') ? api.get('/admin/stats').catch(() => null) : null,
  ]);

  container.append(
    greeting(dash),
    kpis(dash),
    el('div', { class: 'home-panels' }, [
      transactionsPanel(dash),
      reportsPanel(dash, aging),
      maintenancePanel(dash, maint, admin),
    ].filter(Boolean)),
  );

  bindShortcuts();
}

/* -------------------------------------------------------------- heading -- */

function greeting(dash) {
  const hour = new Date().getHours();
  const part = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
  const name = (session.user.full_name || session.user.username).split(' ')[0];
  const role = session.meta?.roles?.[session.user.role]?.label || session.user.role;
  const t = dash.today || {};
  const primary = PRIMARY[session.user.role];

  return el('header', { class: 'home-head' }, [
    el('div', {}, [
      el('p', { class: 'home-eyebrow', text: new Date().toLocaleDateString(undefined,
        { weekday: 'long', month: 'long', day: 'numeric' }) }),
      el('h2', { class: 'home-title', text: `${part}, ${name}.` }),
      el('p', { class: 'home-sub' }, [
        `${role}. ${ROLE_LEAD[session.user.role] || ''} `,
        t.invoices
          ? `${count(t.invoices)} invoices and ${money(t.collected)} collected so far today.`
          : 'Nothing has been raised yet today.',
      ]),
    ]),
    el('div', { class: 'home-right' }, [
      can('invoice:write')
        ? el('a', { class: 'btn', href: '#/invoices/new', text: 'New invoice' })
        : null,
      primary && can(primary.permission)
        ? el('a', { class: 'btn primary', href: `#${primary.path}`, text: primary.label })
        : can('collection:write')
          ? el('a', { class: 'btn primary', href: '#/collections/new', text: 'Record a payment' })
          : null,
    ].filter(Boolean)),
  ]);
}

function kpis(dash) {
  const ar = dash.receivable || {};
  const stock = dash.stock || {};
  const overdue = ar.over_90 || 0;
  const shortages = stock.needs_attention || 0;

  const tiles = [
    ['Receivables', money(ar.total), `${count(ar.open_invoices)} open invoices`, '',
      '/reports/aging'],
    ['Over 90 days', money(overdue), overdue > 0 ? 'Needs chasing' : 'Nothing badly overdue',
      overdue > 0 ? 'danger' : 'ok', '/reports/aging'],
    ['Sales this month', money(dash.month?.sales), `${count(dash.month?.invoices)} invoices`, '',
      '/reports/sales'],
    ['Stock needing attention', count(shortages), `${count(stock.expiring)} expiring soon`,
      shortages > 0 ? 'warn' : 'ok', '/reports/depleted'],
  ];

  return el('div', { class: 'home-kpis' }, tiles.map(([label, value, sub, tone, path]) =>
    el('a', { class: `home-kpi ${tone}`, href: `#${path}` }, [
      el('span', { class: 'value', text: value }),
      el('span', { class: 'label', text: label }),
      el('span', { class: 'sub', text: sub }),
    ])));
}

/* --------------------------------------------------------------- panels -- */

function panel(title, hint, body) {
  return el('section', { class: 'home-panel' }, [
    el('div', { class: 'home-panel-head' }, [
      el('h3', { text: title }),
      el('span', { class: 'home-panel-hint', text: hint }),
    ]),
    el('div', { class: 'home-panel-body' }, [body]),
  ]);
}

function rows(items, empty) {
  if (!items.length) return el('div', { class: 'home-empty', text: empty });
  return el('ul', { class: 'home-list' }, items);
}

function row(href, left, middle, right, tone = '') {
  return el('li', {}, [el('a', { class: 'home-row', href }, [
    el('span', { class: 'r-code', text: left }),
    el('span', { class: 'r-name', text: middle }),
    el('span', { class: `r-value ${tone}`, text: right }),
  ])]);
}

// Lists are rendered longer than a short screen can show and the panel clips
// them. A 1080p monitor fills its panels; a 768-high laptop simply sees fewer
// rows. Neither ends up scrolling, and neither leaves a hole.
function transactionsPanel(dash) {
  const t = dash.today || {};
  const invoices = dash.recent_invoices || [];

  return panel('Transactions', 'Latest activity', el('div', {}, [
    el('div', { class: 'home-mini' }, [
      mini('Invoiced today', money(t.sales), `${count(t.invoices)} documents`),
      mini('Collected today', money(t.collected), `${count(t.payments)} payments`),
    ]),
    rows(invoices.map((r) => row(
      `#/invoices/${encodeURIComponent(r.inv_no)}`,
      r.inv_no, r.customer_name, money(r.net_amount),
      r.balance > 0 ? 'warn-text' : '')),
      'No invoices on file yet.'),
  ]));
}

function reportsPanel(dash, aging) {
  const owing = aging?.rows || [];
  const totals = aging?.totals || {};

  return panel('Reports', 'Who owes the most', el('div', {}, [
    el('div', { class: 'home-mini' }, [
      mini('Current', money(totals.current), 'Within terms'),
      mini('Over 90 days', money(totals.bucket3), 'Chase these', 'danger'),
    ]),
    rows(owing.map((r) => row(
      `#/customers/${encodeURIComponent(r.customer_code)}`,
      r.customer_code, r.customer_name, money(r.total),
      r.bucket3 > 0 ? 'danger-text' : '')),
      'Nothing outstanding.'),
  ]));
}

function maintenancePanel(dash, maint, admin) {
  if (!maint && !admin) return null;

  const backup = maint?.last_backup;
  const days = backup
    ? Math.floor((Date.now() - new Date(backup.created_at)) / 86400000)
    : null;
  const backupText = !backup ? 'Never'
    : days === 0 ? 'Today' : days === 1 ? 'Yesterday' : `${days} days ago`;
  const stock = dash.stock || {};

  const facts = [
    ['Last backup', backupText, backup ? `${count(backup.size_mb)} MB` : 'Take one now',
      !backup || days > 6 ? 'danger' : days >= 1 ? 'warn' : 'ok'],
    ['Signed in now', count(maint?.sessions_open ?? 0),
      `${count(admin?.rows?.users ?? 0)} accounts`, ''],
  ];

  return panel('Maintenance', 'System health', el('div', {}, [
    el('div', { class: 'home-mini' }, facts.map(([l, v, s, tone]) => mini(l, v, s, tone))),
    rows([
      row('#/maintenance', 'Database', `${count(maint?.database?.size_mb ?? 0)} MB`,
        maint?.database?.journal_mode?.toUpperCase() || ''),
      row('#/maintenance', 'Disk free', `${count(maint?.disk_free_mb ?? 0)} MB`,
        (maint?.disk_free_mb ?? 0) < (maint?.database?.size_mb ?? 0) ? 'tight' : 'ample',
        (maint?.disk_free_mb ?? 0) < (maint?.database?.size_mb ?? 0) ? 'warn-text' : ''),
      row('#/maintenance', 'Backups kept', `${count(maint?.backups?.length ?? 0)} files`,
        'on this disk'),
      row('#/reports/depleted', 'Depleted', `${count(stock.depleted)} items`, 'at zero',
        stock.depleted ? 'danger-text' : ''),
      row('#/reports/expiring', 'Expiring', `${count(stock.expiring)} lots`, 'within 90 days',
        stock.expiring ? 'warn-text' : ''),
      row('#/reports/inventory', 'Stock value', money(stock.value), 'at cost'),
      row('#/archive/summary', 'Archive', 'Purged history', 'read only'),
      row('#/admin', 'Audit trail', `${count(admin?.rows?.audit_log ?? 0)} entries`, 'recorded'),
    ], ''),
  ]));
}

function mini(label, value, sub, tone = '') {
  return el('div', { class: `home-mini-item ${tone}` }, [
    el('span', { class: 'label', text: label }),
    el('strong', { class: 'value', text: value }),
    el('span', { class: 'sub', text: sub }),
  ]);
}

/* ------------------------------------------------------------ shortcuts -- */

let detachShortcuts = null;

function bindShortcuts() {
  detachShortcuts?.();

  const map = new Map(
    SHORTCUTS.filter((s) => can(s.permission)).map((s) => [s.key, s]));

  const onKey = (event) => {
    if (event.metaKey || event.ctrlKey || event.altKey) return;
    const tag = document.activeElement?.tagName;
    if (tag === 'INPUT' || tag === 'SELECT' || tag === 'TEXTAREA') return;
    if (document.querySelector('.modal-back')) return;

    if (event.key === '?') {
      event.preventDefault();
      toast([...map.values()].map((s) => `${s.key} ${s.label}`).join(' · '),
        'info', 'The keys from the old menu');
      return;
    }
    const item = map.get(event.key.toUpperCase());
    if (!item) return;
    event.preventDefault();
    if (item.path) window.location.hash = `#${item.path}`;
    else ACTIONS[item.action]?.();
  };

  const onHash = () => {
    const path = (window.location.hash.slice(1) || '/').split('?')[0];
    if (path !== '/') detachShortcuts?.();
  };

  document.addEventListener('keydown', onKey);
  window.addEventListener('hashchange', onHash);

  detachShortcuts = () => {
    document.removeEventListener('keydown', onKey);
    window.removeEventListener('hashchange', onHash);
    detachShortcuts = null;
  };
}
