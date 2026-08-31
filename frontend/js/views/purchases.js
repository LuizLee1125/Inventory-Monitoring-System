// Purchase invoices: browse, view, receive stock, record payments.

import { api } from '../api.js';
import {
  attachLookup, card, clear, count, dataTable, date, debounce, el, field, input,
  modal, money, pager, qty, reportError, select, skeletonTable, statusTag, toast,
  today, toolbar,
} from '../ui.js';
import { can, page, setTitle } from '../app.js';
import { lineEditor } from './lineEditor.js';

const state = { q: '', status: '', date_from: '', date_to: '', page: 1 };

export const skeleton = (params) => (params.id ? 'detail' : 'list');

export async function render(container, params = {}) {
  const hash = window.location.hash.slice(1);
  if (hash.startsWith('/purchases/new')) return editor(container, hash);
  if (params.id) return detail(container, params.id);
  return list(container);
}

async function list(container) {
  setTitle('Purchases');

  const search = el('input', { placeholder: 'Purchase number or supplier…', value: state.q });
  search.addEventListener('input', debounce(() => {
    state.q = search.value.trim(); state.page = 1; refresh();
  }));

  const statusSelect = select('status', [
    ['', 'All statuses'], ['OPEN', 'Open'], ['PAID', 'Paid'],
  ], state.status);
  statusSelect.addEventListener('change', () => {
    state.status = statusSelect.value; state.page = 1; refresh();
  });

  const from = el('input', { type: 'date', value: state.date_from, title: 'From date' });
  const to = el('input', { type: 'date', value: state.date_to, title: 'To date' });
  for (const node of [from, to]) {
    node.addEventListener('change', () => {
      state.date_from = from.value; state.date_to = to.value; state.page = 1; refresh();
    });
  }

  const host = el('div', { class: 'card' });
  container.append(toolbar([
    el('div', { class: 'search' }, [search]),
    statusSelect, from, to,
    el('span', { class: 'spacer' }),
    can('purchase:write')
      ? el('button', { class: 'btn primary', text: '+ New purchase',
                       onClick: () => { window.location.hash = '#/purchases/new'; } })
      : null,
  ]), host);

  async function refresh() {
    clear(host);
    host.append(skeletonTable(8, 10));
    try {
      const result = await api.get('/purchases', {
        q: state.q, status: state.status, date_from: state.date_from,
        date_to: state.date_to, page: state.page, page_size: 50,
      });
      clear(host);
      host.append(
        dataTable([
          { key: 'pur_no', label: 'Number', class: 'mono' },
          { key: 'pur_date', label: 'Date', render: (r) => date(r.pur_date) },
          { key: 'supplier_name', label: 'Supplier', class: 'wrap' },
          { key: 'due_date', label: 'Due', render: (r) => date(r.due_date) },
          { key: 'net_amount', label: 'Amount', align: 'right', render: (r) => money(r.net_amount) },
          { key: 'paid_amount', label: 'Paid', align: 'right', render: (r) => money(r.paid_amount) },
          { key: 'balance', label: 'Balance', align: 'right', render: (r) => money(r.balance) },
          { key: 'status', label: 'Status', render: (r) => statusTag(r.status) },
        ], result.items, {
          onRowClick: (row) => { window.location.hash = `#/purchases/${encodeURIComponent(row.pur_no)}`; },
          footer: {
            pur_no: `${count(result.total)} purchases`,
            net_amount: money(result.summary.net),
            balance: money(result.summary.balance),
          },
          emptyText: 'No purchases match these filters.',
        }),
        pager(result, (p) => { state.page = p; refresh(); }),
      );
    } catch (error) {
      clear(host);
      host.append(el('div', { class: 'empty', text: error.detail || 'Could not load purchases.' }));
    }
  }

  await refresh();
}

async function detail(container, purNo) {
  setTitle(`Purchase ${purNo}`);
  const purchase = await api.get(`/purchases/${encodeURIComponent(purNo)}`);

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Back to purchases', onClick: () => { window.location.hash = '#/purchases'; } }),
      el('span', { class: 'spacer' }),
      el('button', { class: 'btn', text: 'Print', onClick: () => window.print() }),
      can('purchase:write') && purchase.balance > 0
        ? el('button', { class: 'btn primary', text: 'Record payment', onClick: () => pay(purchase) })
        : null,
    ]),

    el('div', { class: 'stat-grid' }, [
      statBox('Net amount', money(purchase.net_amount), `Gross ${money(purchase.gross)}`),
      statBox('Paid', money(purchase.paid_amount), ''),
      statBox('Balance', money(purchase.balance),
        purchase.balance > 0 ? 'Payable' : 'Settled', purchase.balance > 0 ? 'warn' : 'ok'),
      statBox('Status', purchase.status, `${date(purchase.pur_date)} · due ${date(purchase.due_date)}`),
    ]),

    card(`${purchase.supplier_code} — ${purchase.supplier_name}`,
      el('div', { class: 'form-grid' }, [
        ['Purchase number', purchase.pur_no], ['Date', date(purchase.pur_date)],
        ['Terms', purchase.terms_days ? `${purchase.terms_days} days` : purchase.terms_text],
        ['Remarks', purchase.remarks],
        ['Recorded by', `${purchase.created_by} · ${date(purchase.created_at)}`],
      ].map(([label, value]) => el('div', { class: 'field' }, [
        el('span', { text: label }), el('div', { text: value || '—' }),
      ]))),
      [el('a', { class: 'btn sm', href: `#/suppliers/${encodeURIComponent(purchase.supplier_code)}` },
        ['Open supplier'])]),

    card('Lines', dataTable([
      { key: 'line_no', label: '#' },
      { key: 'stock_code', label: 'Code', class: 'mono' },
      { key: 'description', label: 'Description', class: 'wrap' },
      { key: 'qty', label: 'Qty', align: 'right', render: (r) => qty(r.qty) },
      { key: 'unit', label: 'Unit' },
      { key: 'unit_cost', label: 'Cost', align: 'right', render: (r) => money(r.unit_cost) },
      { key: 'lot_no', label: 'Lot' },
      { key: 'expiry_date', label: 'Expiry', render: (r) => date(r.expiry_date) },
      { key: 'line_total', label: 'Total', align: 'right', render: (r) => money(r.line_total) },
    ], purchase.lines, {
      emptyText: 'This purchase has no stored line detail.',
      footer: { description: 'Net', line_total: money(purchase.net_amount) },
    }), [], { flush: true }),
  );
}

function statBox(label, value, sub, kind = '') {
  return el('div', { class: `stat ${kind}` }, [
    el('div', { class: 'label', text: label }),
    el('div', { class: 'value', text: value }),
    sub ? el('div', { class: 'sub', text: sub }) : null,
  ]);
}

async function editor(container, hash) {
  setTitle('New purchase');
  const preset = new URLSearchParams(hash.split('?')[1] || '').get('supplier') || '';

  const supplierCode = input('supplier_code', {
    placeholder: 'Supplier code', style: 'text-transform:uppercase', value: preset,
  });
  const supplierName = el('div', { class: 'hint', text: 'No supplier selected.' });
  const purDate = input('pur_date', { type: 'date', value: today() });
  const terms = input('terms_days', { type: 'number', value: 0, class: 'num' });
  const remarks = input('remarks', { placeholder: 'Supplier reference, delivery note…' });
  const disc1 = input('disc1', { type: 'number', step: '0.01', value: 0, class: 'num' });

  const netCell = el('div', { class: 'amount', text: money(0) });
  const subtotalCell = el('div', { class: 'amount', text: money(0) });

  const lines = lineEditor({
    priceField: 'cost',
    showDiscounts: false,
    onChange: (subtotal) => {
      subtotalCell.textContent = money(subtotal);
      const pct = Number(disc1.value || 0);
      netCell.textContent = money(pct ? subtotal * (1 - pct / 100) : subtotal);
    },
  });
  disc1.addEventListener('input', () => lines.recalc());

  attachLookup(supplierCode, '/suppliers/lookup', {
    format: (row) => row.name,
    meta: (row) => (row.balance ? money(row.balance) : ''),
    onPick: (row) => {
      supplierName.textContent = `${row.name} — ${row.city || ''}`.trim();
      terms.value = row.terms_days || 0;
    },
  });

  const saveButton = el('button', { class: 'btn primary', text: 'Save and receive stock' });

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Cancel', onClick: () => { window.location.hash = '#/purchases'; } }),
      el('span', { class: 'spacer' }),
      saveButton,
    ]),

    card('Supplier and terms', el('div', {}, [
      el('div', { class: 'form-grid' }, [
        field('Supplier code', supplierCode),
        field('Purchase date', purDate),
        field('Terms (days)', terms),
        field('Remarks', remarks),
        field('Discount (%)', disc1),
      ]),
      supplierName,
    ])),

    card('Lines received', el('div', {}, [
      el('p', { class: 'hint' },
        ['Saving receives the goods: quantities go up and each item\'s moving '
         + 'average cost is recalculated.']),
      lines.node,
      el('div', { class: 'totals' }, [
        el('div', {}, [el('div', { class: 'label', text: 'Subtotal' }), subtotalCell]),
        el('div', {}, [el('div', { class: 'label', text: 'Net amount' }), netCell]),
      ]),
    ])),
  );

  saveButton.addEventListener('click', async () => {
    const payload = {
      supplier_code: supplierCode.value.trim().toUpperCase(),
      pur_date: purDate.value,
      terms_days: Number(terms.value || 0),
      remarks: remarks.value.trim(),
      disc1: Number(disc1.value || 0),
      lines: lines.getLines(),
    };
    if (!payload.supplier_code) return toast('Choose a supplier first.', 'error');
    if (!payload.lines.length) return toast('Add at least one line with a quantity.', 'error');

    saveButton.disabled = true;
    try {
      const purchase = await api.post('/purchases', payload);
      toast(`Purchase ${purchase.pur_no} recorded.`, 'success');
      window.location.hash = `#/purchases/${encodeURIComponent(purchase.pur_no)}`;
    } catch (error) {
      reportError(error);
    } finally {
      saveButton.disabled = false;
    }
  });
}

function pay(purchase) {
  const amount = input('amount', {
    type: 'number', step: '0.01', value: purchase.balance.toFixed(2), class: 'num',
  });
  modal({
    title: `Pay ${purchase.pur_no}`,
    body: el('div', {}, [
      el('p', { class: 'hint', text: `Outstanding: ${money(purchase.balance)}` }),
      field('Amount', amount),
    ]),
    actions: [
      { label: 'Cancel' },
      {
        label: 'Record payment',
        kind: 'primary',
        onClick: async () => {
          await api.post(`/purchases/${encodeURIComponent(purchase.pur_no)}/pay`, {
            amount: Number(amount.value), version: purchase.version,
          });
          toast('Payment recorded.', 'success');
          reload();
        },
      },
    ],
  });
}

function reload() {
  const container = page();
  clear(container);
  const hash = window.location.hash.slice(1);
  const id = hash.startsWith('/purchases/') ? decodeURIComponent(hash.slice(11)) : null;
  (id ? detail(container, id) : list(container)).catch(reportError);
}
