// Archived Records (Transactions H) and Archive Inquiry (Maintenance 8).
//
// The legacy O_* files: documents the DOS system purged out of the working set
// over twenty-five years. Read-only, and reached the same two ways the old menu
// reached them — browse the documents, or take the overview.

import { api } from '../api.js';
import {
  card, clear, count, dataTable, date, debounce, el, money, pager, qty,
  reportError, select, statusTag, toolbar,
} from '../ui.js';
import { page, setTitle } from '../app.js';

const state = { kind: 'invoices', q: '', date_from: '', date_to: '', page: 1 };

const COLUMNS = {
  invoices: [
    { key: 'inv_no', label: 'Number', class: 'mono' },
    { key: 'inv_date', label: 'Date', render: (r) => date(r.inv_date) },
    { key: 'customer_name', label: 'Customer', class: 'wrap' },
    { key: 'salesman', label: 'Salesman' },
    { key: 'net_amount', label: 'Amount', align: 'right', render: (r) => money(r.net_amount) },
    { key: 'paid_amount', label: 'Paid', align: 'right', render: (r) => money(r.paid_amount) },
    { key: 'balance', label: 'Balance', align: 'right', render: (r) => money(r.balance) },
    { key: 'status', label: 'Status', render: (r) => statusTag(r.status) },
  ],
  purchases: [
    { key: 'pur_no', label: 'Number', class: 'mono' },
    { key: 'pur_date', label: 'Date', render: (r) => date(r.pur_date) },
    { key: 'supplier_name', label: 'Supplier', class: 'wrap' },
    { key: 'terms_text', label: 'Terms' },
    { key: 'gross', label: 'Gross', align: 'right', render: (r) => money(r.gross) },
    { key: 'net_amount', label: 'Net', align: 'right', render: (r) => money(r.net_amount) },
  ],
  returns: [
    { key: 'sr_no', label: 'Number', class: 'mono' },
    { key: 'sr_date', label: 'Date', render: (r) => date(r.sr_date) },
    { key: 'customer_name', label: 'Customer', class: 'wrap' },
    { key: 'ref_invoice', label: 'Against invoice', class: 'mono' },
    { key: 'net_amount', label: 'Amount', align: 'right', render: (r) => money(r.net_amount) },
    { key: 'status', label: 'Status', render: (r) => statusTag(r.status) },
  ],
  collections: [
    { key: 'col_no', label: 'Number', class: 'mono' },
    { key: 'col_date', label: 'Date', render: (r) => date(r.col_date) },
    { key: 'customer_name', label: 'Customer', class: 'wrap' },
    { key: 'remarks', label: 'Remarks', class: 'wrap' },
    { key: 'amount', label: 'Amount', align: 'right', render: (r) => money(r.amount) },
    { key: 'net_amount', label: 'Net', align: 'right', render: (r) => money(r.net_amount) },
  ],
};

const KEY = { invoices: 'inv_no', purchases: 'pur_no', returns: 'sr_no', collections: 'col_no' };

export async function render(container, params = {}) {
  const hash = window.location.hash.slice(1);
  if (hash.startsWith('/archive/summary')) return inquiry(container);
  if (params.kind && params.number) return document_(container, params.kind, params.number);
  return browse(container);
}

/* --------------------------------------------------------------- browse -- */

async function browse(container) {
  setTitle('Archived records');

  const kind = select('kind', [
    ['invoices', 'Invoices'], ['purchases', 'Purchases'],
    ['returns', 'Sales returns'], ['collections', 'Collections'],
  ], state.kind);
  kind.addEventListener('change', () => {
    state.kind = kind.value; state.page = 1; refresh();
  });

  const search = el('input', { placeholder: 'Number, customer or code…', value: state.q });
  search.addEventListener('input', debounce(() => {
    state.q = search.value.trim(); state.page = 1; refresh();
  }));

  const from = el('input', { type: 'date', value: state.date_from, title: 'From date' });
  const to = el('input', { type: 'date', value: state.date_to, title: 'To date' });
  for (const node of [from, to]) {
    node.addEventListener('change', () => {
      state.date_from = from.value; state.date_to = to.value; state.page = 1; refresh();
    });
  }

  const host = el('div', { class: 'card' });
  container.append(
    el('p', { class: 'lede' },
      ['Documents the old system purged out of the working files. They are kept exactly as '
       + 'they were archived and cannot be edited — this is the record of what happened.']),
    toolbar([kind, el('div', { class: 'search' }, [search]), from, to]),
    host,
  );

  async function refresh() {
    clear(host);
    host.append(el('div', { class: 'empty', text: 'Loading…' }));
    try {
      const result = await api.get(`/archive/${state.kind}`, {
        q: state.q, date_from: state.date_from, date_to: state.date_to,
        page: state.page, page_size: 50,
      });
      clear(host);
      host.append(
        dataTable(COLUMNS[state.kind], result.items, {
          onRowClick: (row) => {
            const number = row[KEY[state.kind]];
            window.location.hash = `#/archive/${state.kind}/${encodeURIComponent(number)}`;
          },
          footer: {
            [COLUMNS[state.kind][0].key]: `${count(result.total)} archived`,
            net_amount: money(result.summary.value),
          },
          emptyText: 'Nothing archived matches these filters.',
        }),
        pager(result, (p) => { state.page = p; refresh(); }),
      );
    } catch (error) {
      clear(host);
      host.append(el('div', { class: 'empty', text: error.detail || 'Could not load the archive.' }));
    }
  }

  await refresh();
}

/* ------------------------------------------------------------- document -- */

async function document_(container, kind, number) {
  setTitle(`Archived ${number}`);
  const doc = await api.get(`/archive/${kind}/${encodeURIComponent(number)}`);
  const key = KEY[kind];

  const facts = Object.entries(doc)
    .filter(([k, v]) => !['lines', 'party'].includes(k) && v !== null && v !== '')
    .map(([k, v]) => el('div', { class: 'field' }, [
      el('span', { text: k.replace(/_/g, ' ') }),
      el('div', { text: typeof v === 'number' ? money(v) : String(v) }),
    ]));

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Back to the archive',
                     onClick: () => { window.location.hash = '#/archive'; } }),
      el('span', { class: 'spacer' }),
      el('span', { class: 'tag neutral', text: 'Archived — read only' }),
      el('button', { class: 'btn', text: 'Print', onClick: () => window.print() }),
    ]),

    card(`${doc[key]} — ${doc.customer_name || doc.supplier_name || ''}`,
      el('div', { class: 'form-grid' }, facts)),

    card('Lines', dataTable([
      { key: 'stock_code', label: 'Code', class: 'mono' },
      { key: 'description', label: 'Description', class: 'wrap' },
      { key: 'qty', label: 'Qty', align: 'right', render: (r) => qty(Math.abs(r.qty)) },
      { key: 'unit', label: 'Unit' },
      { key: 'unit_price', label: 'Price', align: 'right', render: (r) => money(r.unit_price) },
      { key: 'line_total', label: 'Total', align: 'right', render: (r) => money(r.line_total) },
      { key: 'lot_no', label: 'Lot' },
      { key: 'expiry_date', label: 'Expiry', render: (r) => date(r.expiry_date) },
    ], doc.lines, {
      emptyText: 'The archive holds this document’s header but not its line detail.',
      footer: { description: 'Total',
                line_total: money(doc.lines.reduce((s, l) => s + (l.line_total || 0), 0)) },
    }), [], { flush: true }),
  );
}

/* -------------------------------------------------------------- inquiry -- */

async function inquiry(container) {
  setTitle('Archive inquiry');
  const data = await api.get('/archive/summary');

  container.append(
    el('p', { class: 'lede' },
      ['What the archive holds, and the years it covers. Everything here came out of the '
       + 'legacy O_ files when the DOS system purged its working files.']),

    el('div', { class: 'stat-grid' }, data.documents.map((d) =>
      el('div', { class: 'stat' }, [
        el('div', { class: 'value', text: count(d.rows) }),
        el('div', { class: 'label', text: d.label }),
        el('div', { class: 'sub',
          text: d.rows ? `${date(d.first)} to ${date(d.last)}` : 'None archived' }),
      ]))),

    card('Movement detail', el('div', {}, [
      el('div', { class: 'form-grid' }, [
        ['Archived movements', count(data.movements.rows)],
        ['Documents covered', count(data.movements.documents)],
        ['Distinct items', count(data.movements.items)],
        ['Earliest', date(data.movements.first)],
        ['Latest', date(data.movements.last)],
      ].map(([label, value]) => el('div', { class: 'field' }, [
        el('span', { text: label }), el('div', { text: String(value) }),
      ]))),
      el('p', { class: 'hint' }, [
        `${count(data.line_detail.invoices_with_lines)} of `,
        `${count(data.line_detail.invoices_total)} archived invoices `,
        `(${data.line_detail.percent}%) still have their line detail. `,
        'The old system archived headers and movements on different schedules, so for the '
        + 'rest only the header survived the purge — the amounts are intact, the item '
        + 'breakdown is not.',
      ]),
    ])),

    card('Master records that were purged', el('div', { class: 'form-grid' }, [
      ['Customers', count(data.masters.customers)],
      ['Stock items', count(data.masters.stock)],
      ['Suppliers', count(data.masters.suppliers)],
    ].map(([label, value]) => el('div', { class: 'field' }, [
      el('span', { text: label }), el('div', { text: String(value) }),
    ])))),

    card('Archived invoices by year', dataTable([
      { key: 'year', label: 'Year' },
      { key: 'invoices', label: 'Invoices', align: 'right', render: (r) => count(r.invoices) },
      { key: 'value', label: 'Value', align: 'right', render: (r) => money(r.value) },
    ], data.by_year, { emptyText: 'Nothing archived.' }), [
      el('a', { class: 'btn sm', href: '#/archive' }, ['Browse the documents']),
    ], { flush: true }),
  );
}

export function reload() {
  const container = page();
  clear(container);
  render(container).catch(reportError);
}
