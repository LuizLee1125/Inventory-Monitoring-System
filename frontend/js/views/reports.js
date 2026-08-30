// The Reports column, carried over: price inquiry, inventory, sales, purchases,
// purchased items, returns, receivables, collections and the stock alerts.

import { api } from '../api.js';
import {
  attachLookup, card, clear, count, dataTable, date, debounce, el, money,
  monthsAgo, qty, select, statusTag, today, toolbar,
} from '../ui.js';
import { session, setTitle } from '../app.js';

// Named as they were on the DOS Reports column, so the office recognises them.
const REPORTS = {
  'price-inquiry': 'Price Inquiry',
  inventory: 'Inventory',
  sales: 'Sales Summary',
  purchases: 'Purchase Summary',
  'purchased-items': 'Purchased Items',
  'stock-purchases': 'View Purchases',
  'returns-summary': 'Sales Return Summary',
  aging: 'Accounts Receivable',
  collections: 'Collection Summary',
  'inactive-customers': 'Inactive Customers',
  expiring: 'Expiration Inquiry',
  depleted: 'Depleted Stocks',
  movers: 'Fast and slow movers',
};

// A role that is given a smaller system than its permissions allow gets a
// smaller picker too, so the dropdown cannot offer a report its sidebar has
// withheld. Roles absent from this table see the full list.
const ROLE_REPORTS = {
  sales: ['price-inquiry', 'stock-purchases'],
};

function reportsFor() {
  const only = ROLE_REPORTS[session.user?.role];
  const entries = Object.entries(REPORTS);
  return only ? entries.filter(([name]) => only.includes(name)) : entries;
}

export async function render(container, params = {}) {
  const available = reportsFor();
  const fallback = available.some(([key]) => key === 'aging') ? 'aging' : available[0][0];
  const name = params.name || fallback;
  setTitle(REPORTS[name] || 'Report');

  const picker = select('report', available, name);
  picker.addEventListener('change', () => { window.location.hash = `#/reports/${picker.value}`; });

  const bar = toolbar([
    el('strong', { text: 'Report' }), picker,
    el('span', { class: 'spacer' }),
    el('button', { class: 'btn', text: 'Print', onClick: () => window.print() }),
  ]);
  const host = el('div');
  container.append(bar, host);

  const renderers = {
    'price-inquiry': priceInquiry,
    aging: agingReport,
    sales: salesReport,
    purchases: purchasesReport,
    'purchased-items': purchasedItems,
    'stock-purchases': stockPurchases,
    'returns-summary': returnsSummary,
    inventory: inventoryReport,
    expiring: expiringReport,
    depleted: depletedReport,
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

/** Price Inquiry — the counter lookup: five tiers side by side, and the one
    this customer is actually on. */
async function priceInquiry(host) {
  const search = el('input', { placeholder: 'Item code or description…', style: 'min-width:240px' });
  const customer = el('input', {
    placeholder: 'Customer code (optional)', style: 'text-transform:uppercase;width:200px',
  });
  const note = el('div', { class: 'hint' });
  const table = el('div');

  host.append(
    el('div', { class: 'toolbar' }, [
      el('div', { class: 'search' }, [search]),
      customer,
      el('span', { class: 'spacer' }),
    ]),
    note,
    el('div', { class: 'card', style: 'margin-top:14px' }, [table]),
  );

  attachLookup(customer, '/customers/lookup', {
    format: (row) => row.name,
    meta: (row) => `tier ${row.price_cat || 'A'}`,
    onPick: () => draw(),
  });
  search.addEventListener('input', debounce(() => draw(), 250));
  customer.addEventListener('change', () => draw());

  async function draw() {
    loading(table);
    const data = await api.get('/reports/price-inquiry', {
      q: search.value.trim(), customer: customer.value.trim(), limit: 60,
    });

    note.textContent = data.customer
      ? `${data.customer.name} buys on tier ${data.tier}`
        + `${data.customer.terms_days ? ` · ${data.customer.terms_days} day terms` : ''}`
        + `${data.customer.balance ? ` · owes ${money(data.customer.balance)}` : ''}`
      : 'No customer chosen — showing tier A as the selling price.';

    clear(table);
    table.append(dataTable([
      { key: 'code', label: 'Code', class: 'mono' },
      { key: 'name', label: 'Description', class: 'wrap' },
      { key: 'unit', label: 'Unit' },
      { key: 'qty_on_hand', label: 'On hand', align: 'right', render: (r) => qty(r.qty_on_hand) },
      { key: 'cost', label: 'Cost', align: 'right', render: (r) => money(r.cost) },
      { key: 'their_price', label: `Tier ${data.tier}`, align: 'right',
        render: (r) => el('strong', { text: money(r.their_price) }) },
      { key: 'margin', label: 'Margin', align: 'right',
        render: (r) => el('span', { class: r.margin < 0 ? 'danger-text' : '', text: money(r.margin) }) },
      { key: 'markup_pct', label: 'Mark-up', align: 'right',
        render: (r) => (r.markup_pct === null ? '' : `${r.markup_pct}%`) },
      { key: 'price_a', label: 'A', align: 'right', render: (r) => money(r.price_a) },
      { key: 'price_b', label: 'B', align: 'right', render: (r) => money(r.price_b) },
      { key: 'price_c', label: 'C', align: 'right', render: (r) => money(r.price_c) },
      { key: 'price_d', label: 'D', align: 'right', render: (r) => money(r.price_d) },
      { key: 'price_e', label: 'E', align: 'right', render: (r) => money(r.price_e) },
    ], data.rows, {
      onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.code)}`; },
      emptyText: 'Type part of a code or description to look up a price.',
    }));
  }

  await draw();
}

async function purchasedItems(host) {
  const range = dateRange(() => draw());
  const table = el('div');
  host.append(range.node, el('div', { class: 'card' }, [table]));

  async function draw() {
    loading(table);
    const data = await api.get('/reports/purchased-items', {
      date_from: range.from.value, date_to: range.to.value,
    });
    clear(table);
    table.append(dataTable([
      { key: 'stock_code', label: 'Code', class: 'mono' },
      { key: 'description', label: 'Description', class: 'wrap' },
      { key: 'quantity', label: 'Bought', align: 'right', render: (r) => qty(r.quantity) },
      { key: 'unit', label: 'Unit' },
      { key: 'avg_cost', label: 'Average cost', align: 'right', render: (r) => money(r.avg_cost) },
      { key: 'value', label: 'Value', align: 'right', render: (r) => money(r.value) },
      { key: 'documents', label: 'Docs', align: 'right', render: (r) => count(r.documents) },
      { key: 'last_bought', label: 'Last bought', render: (r) => date(r.last_bought) },
      { key: 'qty_on_hand', label: 'On hand', align: 'right', render: (r) => qty(r.qty_on_hand) },
    ], data.rows, {
      onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.stock_code)}`; },
      footer: { description: `${count(data.totals.items)} items`, value: money(data.totals.value) },
      emptyText: 'Nothing was purchased in this period.',
    }));
  }

  await draw();
}

// View Purchases — STKPURCH.PRG. It asked for a start and a stop date and then
// listed every receipt between them, one line per delivery rather than a total
// per item, which is the question a salesman is actually being asked: did that
// come in, when, and how much of it is left. Purchased Items above answers the
// other one. Three months back is the default because the DOS screen opened on
// the earliest recorded date and nobody wanted the whole file.
async function stockPurchases(host) {
  const range = dateRange(() => draw(), monthsAgo(3));
  const table = el('div');
  host.append(
    el('div', { class: 'toolbar' }, [
      el('span', { class: 'hint', text: 'Start at issued date' }), range.from,
      el('span', { class: 'hint', text: 'stop at' }), range.to,
    ]),
    el('div', { class: 'card' }, [table]));

  async function draw() {
    loading(table);
    const data = await api.get('/reports/stock-purchases', {
      date_from: range.from.value, date_to: range.to.value,
    });
    clear(table);
    table.append(dataTable([
      { key: 'doc_date', label: 'Pur. date', render: (r) => date(r.doc_date) },
      { key: 'doc_no', label: 'Document', class: 'mono' },
      { key: 'stock_code', label: 'Stock code', class: 'mono' },
      { key: 'description', label: 'Description', class: 'wrap' },
      { key: 'quantity', label: 'Qty bought', align: 'right', render: (r) => qty(r.quantity) },
      { key: 'unit', label: 'Unit' },
      { key: 'unit_cost', label: 'Price', align: 'right', render: (r) => money(r.unit_cost) },
      { key: 'line_total', label: 'Value', align: 'right', render: (r) => money(r.line_total) },
      { key: 'qty_on_hand', label: 'On hand', align: 'right', render: (r) => qty(r.qty_on_hand) },
    ], data.rows, {
      onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.stock_code)}`; },
      footer: {
        description: `${count(data.totals.lines)} deliveries · ${count(data.totals.items)} items`,
        line_total: money(data.totals.value),
      },
      emptyText: 'Nothing was received between these dates.',
    }));
  }

  await draw();
}

async function returnsSummary(host) {
  const groupBy = select('group_by', [
    ['item', 'By item'], ['customer', 'By customer'], ['month', 'By month'],
  ], 'item');
  const range = dateRange(() => draw());
  groupBy.addEventListener('change', () => draw());

  const table = el('div');
  host.append(el('div', { class: 'toolbar' }, [groupBy, range.node]),
    el('div', { class: 'card' }, [table]));

  async function draw() {
    loading(table);
    const data = await api.get('/reports/returns-summary', {
      group_by: groupBy.value, date_from: range.from.value, date_to: range.to.value,
    });
    clear(table);
    table.append(dataTable([
      { key: 'label', label: groupBy.value === 'month' ? 'Month' : 'Code', class: 'mono' },
      { key: 'detail', label: 'Description', class: 'wrap' },
      { key: 'quantity', label: 'Quantity', align: 'right',
        render: (r) => (r.quantity === null ? '' : qty(r.quantity)) },
      { key: 'documents', label: 'Returns', align: 'right', render: (r) => count(r.documents) },
      { key: 'value', label: 'Value', align: 'right', render: (r) => money(r.value) },
    ], data.rows, {
      footer: { detail: 'Total', documents: count(data.totals.documents),
                value: money(data.totals.value) },
      emptyText: 'No sales returns in this period.',
    }));
  }

  await draw();
}

async function depletedReport(host) {
  loading(host);
  const rows = await api.get('/reports/depleted');
  clear(host);
  host.append(card('Depleted and below reorder point', dataTable([
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
  ], rows, {
    onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.code)}`; },
    emptyText: 'Every item is above its reorder point.',
  }), [], { flush: true }));
}

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
      customer_name: `${count(data.totals.customers)} customers`,
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
