// The home screen: the successor to the DOS main menu.
//
// The three columns are kept — Transactions, Reports, Maintenance — because
// after twenty-five years that grouping is how the office thinks about the
// work. So are the letter keys: pressing G for Collections is muscle memory
// for people who have done it every working day since 1999, and it still
// works here. Everything else is new: live counts on the tiles that have
// something to say, so the menu can tell you what needs attention before you
// open anything.

import { api } from '../api.js';
import { count, el, money, toast } from '../ui.js';
import { can, changePassword, session, setTitle } from '../app.js';

// Tiles that run something instead of going somewhere.
const ACTIONS = {
  password: () => changePassword(false),
};

/* --------------------------------------------------------------- tiles --- */
// `key` is the accelerator from the DOS menu, kept wherever the destination is
// genuinely the same screen. `badge` names the counter this tile shows.

const COLUMNS = [
  {
    title: 'Transactions',
    hint: 'The day-to-day work',
    items: [
      { key: 'A', label: 'Stock File', path: '/stock', permission: 'stock:read',
        desc: 'Items, prices, lots and expiry', badge: 'stock_alerts' },
      { key: 'B', label: 'Customer File', path: '/customers', permission: 'customer:read',
        desc: 'Accounts, terms and credit limits' },
      { key: 'C', label: 'Supplier File', path: '/suppliers', permission: 'supplier:read',
        desc: 'Suppliers and what is owed to them' },
      { key: 'D', label: 'Invoices', path: '/invoices', permission: 'invoice:read',
        desc: 'Raise and look up sales invoices', badge: 'open_invoices' },
      { key: 'E', label: 'Purchases', path: '/purchases', permission: 'purchase:read',
        desc: 'Receive deliveries from suppliers' },
      { key: 'F', label: 'Sales Returns', path: '/returns', permission: 'return:read',
        desc: 'Goods back, credit against the invoice' },
      { key: 'G', label: 'Collections', path: '/collections', permission: 'collection:read',
        desc: 'Payments applied to open invoices' },
    ],
  },
  {
    title: 'Reports',
    hint: 'What the numbers say',
    items: [
      { key: 'W', label: 'Accounts Receivable', path: '/reports/aging', permission: 'report:read',
        desc: 'Aging by customer and salesman', badge: 'overdue' },
      { key: 'S', label: 'Sales Summary', path: '/reports/sales', permission: 'report:read',
        desc: 'By month, customer, salesman or line' },
      { key: 'P', label: 'Inventory', path: '/reports/inventory', permission: 'report:read',
        desc: 'Valuation at cost, item by item' },
      { key: 'T', label: 'Purchase Summary', path: '/reports/purchases', permission: 'report:read',
        desc: 'What was bought, and from whom' },
      { key: 'X', label: 'Collection Summary', path: '/reports/collections', permission: 'report:read',
        desc: 'Cash and cheques by month' },
      { key: 'V', label: 'Expiry & Stock Alerts', path: '/reports/expiring', permission: 'report:read',
        desc: 'Expiring, expired and depleted', badge: 'expiring' },
      { key: 'Y', label: 'Inactive Customers', path: '/reports/inactive-customers',
        permission: 'report:read', desc: 'No trade in twelve months' },
      { key: 'O', label: 'Overview', path: '/overview', permission: 'report:read',
        desc: 'Charts and recent activity' },
    ],
  },
  {
    title: 'Maintenance',
    hint: 'Housekeeping',
    items: [
      { key: '1', label: 'Users & Audit', path: '/admin', permission: 'admin:users',
        desc: 'Accounts, roles, who did what', badge: 'users' },
      { key: '2', label: 'Backup & Database', path: '/maintenance', permission: 'maintenance:run',
        desc: 'Take a backup, check the database', badge: 'backup_age' },
      { key: '3', label: 'Change Password', action: 'password', permission: 'report:read',
        desc: 'Choose a new one for this account' },
    ],
  },
];

/* ----------------------------------------------------------- role focus -- */
// Filtering the same menu by permission would give the invoicing clerk and the
// AR officer near-identical screens, because both can read everything. The DOS
// system did not work that way - MNUNVCS and MNUAR were different menus - so
// each role gets the one action it performs all day put up front, and its own
// tiles floated to the top of the column.

const ROLE_FOCUS = {
  admin: {
    lead: 'Everything is here. The keys are the ones you already know.',
  },
  manager: {
    lead: 'The whole system, minus user administration.',
    action: { label: 'Open accounts receivable', path: '/reports/aging',
              permission: 'report:read' },
    first: ['W', 'A', 'D'],
  },
  invoicing: {
    lead: 'Invoicing and the customer file.',
    action: { label: 'Raise an invoice', path: '/invoices/new',
              permission: 'invoice:write' },
    first: ['D', 'B', 'F'],
  },
  ar: {
    lead: 'Collections and what is still owed.',
    action: { label: 'Record a payment', path: '/collections/new',
              permission: 'collection:write' },
    first: ['G', 'B', 'D'],
  },
  sales: {
    lead: 'Prices, stock on hand and your customers.',
    action: { label: 'Look up an item', path: '/stock', permission: 'stock:read' },
    first: ['A', 'B', 'D'],
  },
  inventory: {
    lead: 'Stock, purchasing and the supplier file.',
    action: { label: 'Receive a delivery', path: '/purchases/new',
              permission: 'purchase:write' },
    first: ['A', 'E', 'C'],
  },
  viewer: { lead: 'Read-only access.' },
};

function focusFor() {
  return ROLE_FOCUS[session.user.role] || {};
}

/** Float the role's daily tiles to the top of their column, order preserved. */
function ordered(items, first) {
  if (!first?.length) return items;
  const rank = (item) => {
    const i = first.indexOf(item.key);
    return i === -1 ? first.length : i;
  };
  return [...items].sort((a, b) => rank(a) - rank(b));
}

/* --------------------------------------------------------------- render -- */

export async function render(container) {
  setTitle('Home');
  detachShortcuts?.();

  const [dash, admin] = await Promise.all([
    api.get('/reports/dashboard'),
    can('admin:users') ? api.get('/admin/stats').catch(() => null) : Promise.resolve(null),
  ]);
  const maint = can('maintenance:run')
    ? await api.get('/maintenance/status').catch(() => null)
    : null;

  const badges = buildBadges(dash, admin, maint);
  const focus = focusFor();
  const columns = COLUMNS
    .map((column) => ({
      ...column,
      items: ordered(column.items.filter((i) => can(i.permission)), focus.first),
    }))
    .filter((column) => column.items.length);

  // Accelerators are only bound to tiles this person can actually reach.
  const shortcuts = new Map();
  for (const column of columns) {
    for (const item of column.items) shortcuts.set(item.key, item);
  }

  container.append(
    greeting(dash, focus),
    attention(dash),
    el('div', { class: 'menu-grid' }, columns.map((column) => panel(column, badges))),
    el('p', { class: 'menu-foot' }, [
      'Press a letter or number to open a screen — the same keys as the old system. ',
      el('kbd', { text: '?' }), ' lists them.',
    ]),
  );

  bindShortcuts(container, shortcuts);
}

function greeting(dash, focus) {
  const hour = new Date().getHours();
  const part = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
  const name = (session.user.full_name || session.user.username).split(' ')[0];
  const role = session.meta?.roles?.[session.user.role]?.label || session.user.role;
  const action = focus.action && can(focus.action.permission) ? focus.action : null;

  return el('header', { class: 'home-head' }, [
    el('div', {}, [
      el('p', { class: 'home-eyebrow', text: new Date().toLocaleDateString(undefined,
        { weekday: 'long', month: 'long', day: 'numeric' }) }),
      el('h2', { class: 'home-title', text: `${part}, ${name}.` }),
      el('p', { class: 'home-sub' },
        [`${role}. ${focus.lead || ''} `,
         `${count(dash.receivable?.open_invoices || 0)} invoices are still open.`]),
    ]),
    el('div', { class: 'home-right' }, [
      action
        ? el('a', { class: 'btn primary', href: `#${action.path}`, text: action.label })
        : null,
    ]),
  ]);
}

function attention(dash) {
  const ar = dash.receivable || {};
  const stock = dash.stock || {};
  const overdue = ar.over_90 || 0;
  const shortages = stock.needs_attention || 0;

  const items = [
    { label: 'Receivables', value: money(ar.total), note: `${count(ar.customers)} customers`,
      tone: '', path: '/reports/aging' },
    { label: 'Over 90 days', value: money(overdue),
      note: overdue > 0 ? 'Needs chasing' : 'Nothing badly overdue',
      tone: overdue > 0 ? 'bad' : 'good', path: '/reports/aging' },
    { label: 'Sales this month', value: money(dash.month?.sales),
      note: `${count(dash.month?.invoices)} invoices`, tone: '', path: '/reports/sales' },
    { label: 'Stock needing attention', value: count(shortages),
      note: `${count(stock.expiring)} expiring soon`,
      tone: shortages > 0 ? 'warn' : 'good', path: '/reports/expiring' },
  ];

  return el('div', { class: 'attention' }, items.map((item) =>
    el('a', { class: `attention-item ${item.tone}`, href: `#${item.path}` }, [
      el('span', { class: 'attention-label', text: item.label }),
      el('strong', { class: 'attention-value', text: item.value }),
      el('span', { class: 'attention-note', text: item.note }),
    ])));
}

function panel(column, badges) {
  return el('section', { class: 'menu-panel' }, [
    el('div', { class: 'menu-panel-head' }, [
      el('h3', { text: column.title }),
      el('span', { class: 'menu-panel-hint', text: column.hint }),
    ]),
    el('div', { class: 'menu-items' }, column.items.map((item) => {
      const badge = item.badge ? badges[item.badge] : null;
      const attrs = { class: 'menu-item', dataset: { key: item.key } };
      if (item.path) {
        attrs.href = `#${item.path}`;
      } else {
        attrs.href = '#';
        attrs.onClick = (event) => { event.preventDefault(); ACTIONS[item.action]?.(); };
      }
      return el('a', attrs, [
        el('kbd', { class: 'menu-key', text: item.key }),
        el('span', { class: 'menu-text' }, [
          el('span', { class: 'menu-label', text: item.label }),
          el('span', { class: 'menu-desc', text: item.desc }),
        ]),
        badge ? el('span', { class: `menu-badge ${badge.tone || ''}`, text: badge.text }) : null,
      ]);
    })),
  ]);
}

function buildBadges(dash, admin, maint) {
  const stock = dash.stock || {};
  const ar = dash.receivable || {};
  const shortages = stock.needs_attention || 0;
  const badges = {};

  if (shortages) {
    badges.stock_alerts = {
      text: `${count(shortages)} of ${count(stock.items)}`,
      tone: 'warn',
    };
  }
  if (ar.open_invoices) badges.open_invoices = { text: `${count(ar.open_invoices)} open`, tone: '' };
  if (ar.over_90 > 0) badges.overdue = { text: 'overdue', tone: 'bad' };
  if (stock.expiring) badges.expiring = { text: `${count(stock.expiring)} expiring`, tone: 'warn' };
  if (admin?.rows?.users) badges.users = { text: `${count(admin.rows.users)} users`, tone: '' };

  if (maint) {
    const last = maint.last_backup;
    if (!last) {
      badges.backup_age = { text: 'no backup', tone: 'bad' };
    } else {
      const days = Math.floor((Date.now() - new Date(last.created_at)) / 86400000);
      badges.backup_age = days >= 1
        ? { text: days === 1 ? 'backed up yesterday' : `${days} days since backup`,
            tone: days > 6 ? 'bad' : 'warn' }
        : { text: 'backed up today', tone: 'good' };
    }
  }
  return badges;
}

/* ------------------------------------------------------------ shortcuts -- */

// The accelerators belong to the home screen only. `#page` is reused between
// routes rather than replaced, so "is my container still in the DOM?" is not a
// usable signal - leaving them bound meant pressing S while reading the invoice
// list jumped to Sales Summary. They are torn down on the way out instead.
let detachShortcuts = null;

function bindShortcuts(container, shortcuts) {
  detachShortcuts?.();

  const onKey = (event) => {
    if (event.metaKey || event.ctrlKey || event.altKey) return;
    const tag = document.activeElement?.tagName;
    if (tag === 'INPUT' || tag === 'SELECT' || tag === 'TEXTAREA') return;
    if (document.querySelector('.modal-back')) return;
    if (event.key === '?') {
      event.preventDefault();
      toast('Every tile shows its key. They are the same letters the DOS menu used.',
        'info', 'Keyboard shortcuts');
      return;
    }
    const key = event.key.toUpperCase();
    const item = shortcuts.get(key);
    if (!item) return;
    event.preventDefault();

    const go = () => {
      if (item.path) window.location.hash = `#${item.path}`;
      else ACTIONS[item.action]?.();
    };

    const tile = container.querySelector(`[data-key="${key}"]`);
    if (tile) {
      tile.classList.add('firing');
      setTimeout(go, 90);
    } else {
      go();
    }
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

export { COLUMNS };
