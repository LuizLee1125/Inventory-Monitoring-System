// Reports: aging, sales, inventory, expiry and stock alerts.

import { api } from '../api.js';
import {
  card, clear, count, dataTable, date, el, money, monthsAgo, qty,
  select, statusTag, today, toolbar,
} from '../ui.js';
import { setTitle } from '../app.js';

const REPORTS = {
  aging: 'AR Aging',
  sales: 'Sales',
  purchases: 'Purchases',
  inventory: 'Inventory',
  expiring: 'Expiry and stock alerts',
  movers: 'Fast and slow movers',
  collections: 'Collections',
  'inactive-customers': 'Inactive customers',
};

export async function render(container, params = {}) {
  const name = params.name || 'aging';
  setTitle(REPORTS[name] || 'Report');

  const picker = select('report', Object.entries(REPORTS), name);
  picker.addEventListener('change', () => { window.location.hash = `#/reports/${picker.value}`; });

  const bar = toolbar([
    el('strong', { text: 'Report' }), picker,
    el('span', { class: 'spacer' }),
    el('button', { class: 'btn', text: 'Print', onClick: () => window.print() }),
  ]);
  const host = el('div');
  container.append(bar, host);

  const renderers = {
    aging: agingReport,
    sales: salesReport,
    purchases: purchasesReport,
    inventory: inventoryReport,
    expiring: expiringReport,
    movers: moversReport,
    collections: collectionsReport,
    'inactive-customers': inactiveReport,
  };
  await (renderers[name] || agingReport)(host);
}

/* -------------------------------------------------------------- helpers -- */

function loading(host) {
  clear(host);
  host.append(el('div', { class: 'empty', text: 'Loading…' }));
}

function dateRange(onChange, fromDefault = monthsAgo(12)) {
  const from = el('input', { type: 'date', value: fromDefault });
  const to = el('input', { type: 'date', value: today() });
  for (const node of [from, to]) node.addEventListener('change', () => onChange(from.value, to.value));
  return {
    node: el('div', { class: 'toolbar' }, [
      el('span', { class: 'hint', text: 'From' }), from,
      el('span', { class: 'hint', text: 'to' }), to,
    ]),
    from, to,
  };
}

/* -------------------------------------------------------------- reports -- */

async function agingReport(host) {
  loading(host);
  const data = await api.get('/reports/aging');
  clear(host);
  host.append(card('Accounts receivable aging', dataTable([
    { key: 'customer_code', label: 'Code', class: 'mono' },
    { key: 'customer_name', label: 'Customer', class: 'wrap' },
    { key: 'salesman', label: 'Salesman' },
    { key: 'invoices', label: 'Inv', align: 'right' },
    { key: 'current', label: data.buckets[0], align: 'right', render: (r) => money(r.current) },
    { key: 'bucket1', label: data.buckets[1], align: 'right', render: (r) => money(r.bucket1) },
    { key: 'bucket2', label: data.buckets[2], align: 'right', render: (r) => money(r.bucket2) },
    { key: 'bucket3', label: data.buckets[3], align: 'right',
      render: (r) => el('span', { class: r.bucket3 > 0 ? 'danger-text' : '', text: money(r.bucket3) }) },
    { key: 'total', label: 'Total', align: 'right', render: (r) => money(r.total) },
  ], data.rows, {
    onRowClick: (row) => { window.location.hash = `#/customers/${encodeURIComponent(row.customer_code)}`; },
    footer: {
      customer_name: `${count(data.rows.length)} customers`,
      current: money(data.totals.current),
      bucket1: money(data.totals.bucket1),
      bucket2: money(data.totals.bucket2),
      bucket3: money(data.totals.bucket3),
      total: money(data.totals.total),
    },
    emptyText: 'Nothing outstanding.',
  }), [], { flush: true }));
}

async function salesReport(host) {
  const groupBy = select('group_by', [
    ['month', 'By month'], ['customer', 'By customer'], ['salesman', 'By salesman'],
    ['division', 'By division'], ['category', 'By category'],
  ], 'month');

  const range = dateRange(() => draw());
  groupBy.addEventListener('change', () => draw());

  const table = el('div');
  host.append(
    el('div', { class: 'toolbar' }, [groupBy, range.node]),
    el('div', { class: 'card' }, [table]),
  );

  async function draw() {
    loading(table);
    const data = await api.get('/reports/sales', {
      group_by: groupBy.value, date_from: range.from.value, date_to: range.to.value,
    });
    clear(table);
    const columns = [
      { key: 'label', label: groupBy.options[groupBy.selectedIndex].text.replace('By ', '') },
      { key: 'invoices', label: 'Documents', align: 'right', render: (r) => count(r.invoices) },
      { key: 'sales', label: 'Sales', align: 'right', render: (r) => money(r.sales) },
    ];
    if (data.rows.some((r) => r.quantity !== undefined)) {
      columns.splice(1, 0, { key: 'quantity', label: 'Quantity', align: 'right',
        render: (r) => qty(r.quantity) });
    }
    table.append(dataTable(columns, data.rows, {
      footer: { label: 'Total', sales: money(data.totals.sales), invoices: count(data.totals.invoices) },
      emptyText: 'No sales in this period.',
    }));
  }

  await draw();
}

async function purchasesReport(host) {
  const range = dateRange(() => draw());
  const table = el('div');
  host.append(range.node, el('div', { class: 'card' }, [table]));

  async function draw() {
    loading(table);
    const data = await api.get('/reports/purchases', {
      date_from: range.from.value, date_to: range.to.value,
    });
    clear(table);
    table.append(dataTable([
      { key: 'label', label: 'Code', class: 'mono' },
      { key: 'supplier_name', label: 'Supplier', class: 'wrap' },
      { key: 'documents', label: 'Documents', align: 'right', render: (r) => count(r.documents) },
      { key: 'purchases', label: 'Purchases', align: 'right', render: (r) => money(r.purchases) },
      { key: 'payable', label: 'Payable', align: 'right', render: (r) => money(r.payable) },
    ], data.rows, {
      onRowClick: (row) => { window.location.hash = `#/suppliers/${encodeURIComponent(row.label)}`; },
      footer: { supplier_name: 'Total', purchases: money(data.totals.purchases),
                payable: money(data.totals.payable) },
      emptyText: 'No purchases in this period.',
    }));
  }

  await draw();
}

async function inventoryReport(host) {
  loading(host);
  const data = await api.get('/reports/inventory', { limit: 1000 });
  clear(host);
  host.append(
    el('div', { class: 'stat-grid' }, [
      el('div', { class: 'stat' }, [
        el('div', { class: 'label', text: 'Items' }),
        el('div', { class: 'value', text: count(data.totals.items) }),
      ]),
      el('div', { class: 'stat' }, [
        el('div', { class: 'label', text: 'Stock value at cost' }),
        el('div', { class: 'value', text: money(data.totals.value) }),
      ]),
    ]),
    card('Inventory valuation', dataTable([
      { key: 'code', label: 'Code', class: 'mono' },
      { key: 'name', label: 'Description', class: 'wrap' },
      { key: 'division', label: 'Div' },
      { key: 'qty_on_hand', label: 'On hand', align: 'right', render: (r) => qty(r.qty_on_hand) },
      { key: 'unit', label: 'Unit' },
      { key: 'cost', label: 'Cost', align: 'right', render: (r) => money(r.cost) },
      { key: 'value', label: 'Value', align: 'right', render: (r) => money(r.value) },
      { key: 'expiry_date', label: 'Expiry', render: (r) => date(r.expiry_date) },
    ], data.rows, {
      onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.code)}`; },
      emptyText: 'No stock on file.',
    }), [], { flush: true }),
  );
}

async function expiringReport(host) {
  loading(host);
  const [expiring, low] = await Promise.all([
    api.get('/reports/expiring', { days: 180 }),
    api.get('/reports/depleted'),
  ]);
  clear(host);
  host.append(
    card('Expiring or expired stock', dataTable([
      { key: 'code', label: 'Code', class: 'mono' },
      { key: 'name', label: 'Description', class: 'wrap' },
      { key: 'lot_no', label: 'Lot' },
      { key: 'expiry_date', label: 'Expiry', render: (r) => date(r.expiry_date) },
      { key: 'days_left', label: 'Days', align: 'right',
        render: (r) => el('span', { class: r.days_left < 0 ? 'danger-text' : 'warn-text',
                                    text: r.days_left < 0 ? `${-r.days_left} overdue` : String(r.days_left) }) },
      { key: 'qty_on_hand', label: 'On hand', align: 'right', render: (r) => qty(r.qty_on_hand) },
      { key: 'value', label: 'Value at risk', align: 'right', render: (r) => money(r.value) },
    ], expiring, {
      onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.code)}`; },
      footer: { name: 'Total at risk',
                value: money(expiring.reduce((sum, r) => sum + (r.value || 0), 0)) },
      emptyText: 'Nothing expiring in the next six months.',
    }), [], { flush: true }),

    card('Depleted and below reorder point', dataTable([
      { key: 'code', label: 'Code', class: 'mono' },
      { key: 'name', label: 'Description', class: 'wrap' },
      { key: 'division', label: 'Div' },
      { key: 'qty_on_hand', label: 'On hand', align: 'right',
        render: (r) => el('span', { class: r.qty_on_hand <= 0 ? 'danger-text' : 'warn-text',
                                    text: qty(r.qty_on_hand) }) },
      { key: 'reorder_point', label: 'Reorder at', align: 'right', render: (r) => qty(r.reorder_point) },
      { key: 'reorder_qty', label: 'Order qty', align: 'right', render: (r) => qty(r.reorder_qty) },
      { key: 'supplier_code', label: 'Supplier' },
      { key: 'cost', label: 'Cost', align: 'right', render: (r) => money(r.cost) },
    ], low, {
      onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.code)}`; },
      emptyText: 'Every item is above its reorder point.',
    }), [], { flush: true }),
  );
}

async function moversReport(host) {
  const direction = select('direction', [['top', 'Fastest moving'], ['bottom', 'Slowest moving']], 'top');
  const days = select('days', [[30, 'Last 30 days'], [90, 'Last 90 days'], [365, 'Last 12 months']], 90);
  for (const node of [direction, days]) node.addEventListener('change', () => draw());

  const table = el('div');
  host.append(el('div', { class: 'toolbar' }, [direction, days]),
    el('div', { class: 'card' }, [table]));

  async function draw() {
    loading(table);
    const rows = await api.get('/reports/movers', {
      direction: direction.value, days: days.value, limit: 60,
    });
    clear(table);
    table.append(dataTable([
      { key: 'code', label: 'Code', class: 'mono' },
      { key: 'name', label: 'Description', class: 'wrap' },
      { key: 'quantity', label: 'Sold', align: 'right', render: (r) => qty(r.quantity) },
      { key: 'sales', label: 'Sales value', align: 'right', render: (r) => money(r.sales) },
      { key: 'qty_on_hand', label: 'On hand', align: 'right', render: (r) => qty(r.qty_on_hand) },
    ], rows, {
      onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.code)}`; },
      emptyText: 'No movement data. Run the migration including the movement ledger.',
    }));
  }

  await draw();
}

async function collectionsReport(host) {
  const range = dateRange(() => draw());
  const table = el('div');
  host.append(range.node, el('div', { class: 'card' }, [table]));

  async function draw() {
    loading(table);
    const data = await api.get('/reports/collections', {
      date_from: range.from.value, date_to: range.to.value,
    });
    clear(table);
    table.append(dataTable([
      { key: 'label', label: 'Month' },
      { key: 'method', label: 'Method', render: (r) => statusTag(r.method) },
      { key: 'payments', label: 'Payments', align: 'right', render: (r) => count(r.payments) },
      { key: 'collected', label: 'Collected', align: 'right', render: (r) => money(r.collected) },
    ], data.rows, {
      footer: { method: 'Total', collected: money(data.totals.collected) },
      emptyText: 'No payments in this period.',
    }));
  }

  await draw();
}

async function inactiveReport(host) {
  loading(host);
  const rows = await api.get('/reports/inactive-customers', { months: 12 });
  clear(host);
  host.append(card('Customers with no activity in 12 months', dataTable([
    { key: 'code', label: 'Code', class: 'mono' },
    { key: 'name', label: 'Customer', class: 'wrap' },
    { key: 'city', label: 'City' },
    { key: 'salesman', label: 'Salesman' },
    { key: 'last_txn', label: 'Last transaction', render: (r) => date(r.last_txn) },
    { key: 'balance', label: 'Balance', align: 'right', render: (r) => money(r.balance) },
  ], rows, {
    onRowClick: (row) => { window.location.hash = `#/customers/${encodeURIComponent(row.code)}`; },
    emptyText: 'Every customer has traded in the last year.',
  }), [], { flush: true }));
}
