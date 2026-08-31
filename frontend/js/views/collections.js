// Collections: record a customer payment and apply it to open invoices.

import { api } from '../api.js';
import {
  attachLookup, card, clear, confirmDialog, count, dataTable, date, debounce, el,
  field, input, money, pager, promptDialog, reportError, select, skeletonTable,
  statusTag, toast, today, toolbar,
} from '../ui.js';
import { can, page, setTitle } from '../app.js';

const state = { q: '', method: '', date_from: '', date_to: '', page: 1 };

export const skeleton = (params) => (params.id ? 'detail' : 'list');

export async function render(container, params = {}) {
  const hash = window.location.hash.slice(1);
  if (hash.startsWith('/collections/new')) return editor(container, hash);
  if (params.id) return detail(container, params.id);
  return list(container);
}

async function list(container) {
  setTitle('Collections');

  const search = el('input', { placeholder: 'Payment number, customer or reference…', value: state.q });
  search.addEventListener('input', debounce(() => {
    state.q = search.value.trim(); state.page = 1; refresh();
  }));

  const methodSelect = select('method', [
    ['', 'All methods'], ['CASH', 'Cash'], ['CHECK', 'Check'], ['TRANSFER', 'Transfer'],
  ], state.method);
  methodSelect.addEventListener('change', () => {
    state.method = methodSelect.value; state.page = 1; refresh();
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
    methodSelect, from, to,
    el('span', { class: 'spacer' }),
    can('collection:write')
      ? el('button', { class: 'btn primary', text: '+ Record payment',
                       onClick: () => { window.location.hash = '#/collections/new'; } })
      : null,
  ]), host);

  async function refresh() {
    clear(host);
    host.append(skeletonTable(8, 10));
    try {
      const result = await api.get('/collections', {
        q: state.q, method: state.method, date_from: state.date_from,
        date_to: state.date_to, page: state.page, page_size: 50,
      });
      clear(host);
      host.append(
        dataTable([
          { key: 'col_no', label: 'Number', class: 'mono' },
          { key: 'col_date', label: 'Date', render: (r) => date(r.col_date) },
          { key: 'customer_name', label: 'Customer', class: 'wrap' },
          { key: 'method', label: 'Method' },
          { key: 'reference', label: 'Reference' },
          { key: 'net_amount', label: 'Amount', align: 'right', render: (r) => money(r.net_amount) },
          { key: 'applied_amt', label: 'Applied', align: 'right', render: (r) => money(r.applied_amt) },
          { key: 'status', label: 'Status', render: (r) => statusTag(r.status) },
        ], result.items, {
          onRowClick: (row) => { window.location.hash = `#/collections/${encodeURIComponent(row.col_no)}`; },
          footer: {
            customer_name: `${count(result.total)} payments`,
            net_amount: money(result.summary.net),
          },
          emptyText: 'No payments match these filters.',
        }),
        pager(result, (p) => { state.page = p; refresh(); }),
      );
    } catch (error) {
      clear(host);
      host.append(el('div', { class: 'empty', text: error.detail || 'Could not load payments.' }));
    }
  }

  await refresh();
}

async function detail(container, colNo) {
  setTitle(`Payment ${colNo}`);
  const collection = await api.get(`/collections/${encodeURIComponent(colNo)}`);

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Back to collections', onClick: () => { window.location.hash = '#/collections'; } }),
      el('span', { class: 'spacer' }),
      el('button', { class: 'btn', text: 'Print', onClick: () => window.print() }),
      can('collection:write') && collection.status !== 'REVERSED'
        ? el('button', { class: 'btn danger', text: 'Reverse', onClick: () => reverse(collection) })
        : null,
    ]),

    card(`${collection.customer_code} — ${collection.customer_name}`,
      el('div', { class: 'form-grid' }, [
        ['Payment number', collection.col_no], ['Date', date(collection.col_date)],
        ['Method', collection.method], ['Reference', collection.reference],
        ['Amount', money(collection.amount)], ['Adjustment', money(collection.adjustment)],
        ['Net', money(collection.net_amount)], ['Applied', money(collection.applied_amt)],
        ['Status', collection.status], ['Remarks', collection.remarks],
        ['Recorded by', `${collection.created_by} · ${date(collection.created_at)}`],
      ].map(([label, value]) => el('div', { class: 'field' }, [
        el('span', { text: label }), el('div', { text: value || '—' }),
      ]))),
      [el('a', { class: 'btn sm', href: `#/customers/${encodeURIComponent(collection.customer_code)}` },
        ['Open customer'])]),

    card('Applied to', dataTable([
      { key: 'inv_no', label: 'Invoice', class: 'mono' },
      { key: 'inv_date', label: 'Invoice date', render: (r) => date(r.inv_date) },
      { key: 'invoice_amount', label: 'Invoice total', align: 'right', render: (r) => money(r.invoice_amount) },
      { key: 'amount', label: 'Applied', align: 'right', render: (r) => money(r.amount) },
      { key: 'balance', label: 'Still open', align: 'right', render: (r) => money(r.balance) },
      { key: 'check_no', label: 'Check' },
    ], collection.applications, {
      emptyText: 'This payment was not applied to any invoice.',
      onRowClick: (row) => { window.location.hash = `#/invoices/${encodeURIComponent(row.inv_no)}`; },
    }), [], { flush: true }),
  );
}

/* --------------------------------------------------------------- editor -- */

async function editor(container, hash) {
  setTitle('Record payment');
  const preset = new URLSearchParams(hash.split('?')[1] || '').get('customer') || '';

  const customerCode = input('customer_code', {
    placeholder: 'Customer code', style: 'text-transform:uppercase', value: preset,
  });
  const customerName = el('div', { class: 'hint', text: 'No customer selected.' });
  const colDate = input('col_date', { type: 'date', value: today() });
  const method = select('method', [['CASH', 'Cash'], ['CHECK', 'Check'], ['TRANSFER', 'Transfer']], 'CASH');
  const reference = input('reference', { placeholder: 'Check or transfer number' });
  const amount = input('amount', { type: 'number', step: '0.01', value: '', class: 'num' });
  const adjustment = input('adjustment', { type: 'number', step: '0.01', value: 0, class: 'num' });
  const remarks = input('remarks', { placeholder: 'Optional note' });

  const invoiceHost = el('div', { class: 'card-body flush' },
    [el('div', { class: 'empty', text: 'Choose a customer to see open invoices.' })]);
  const unappliedNote = el('div', { class: 'hint' });

  let openInvoices = [];
  const applications = new Map();     // inv_no -> input element

  function totalApplied() {
    let sum = 0;
    for (const node of applications.values()) sum += Number(node.value || 0);
    return Math.round(sum * 100) / 100;
  }

  function refreshNote() {
    const net = Math.round((Number(amount.value || 0) + Number(adjustment.value || 0)) * 100) / 100;
    const applied = totalApplied();
    const left = Math.round((net - applied) * 100) / 100;
    unappliedNote.textContent =
      `Payment ${money(net)} · applied ${money(applied)} · unapplied ${money(left)}`;
    unappliedNote.className = left < -0.005 ? 'danger-text' : 'hint';
  }

  function autoAllocate() {
    let left = Math.round((Number(amount.value || 0) + Number(adjustment.value || 0)) * 100) / 100;
    for (const invoice of openInvoices) {
      const node = applications.get(invoice.inv_no);
      if (!node) continue;
      const take = Math.min(left, invoice.balance);
      node.value = take > 0 ? take.toFixed(2) : '';
      left = Math.round((left - Math.max(take, 0)) * 100) / 100;
    }
    refreshNote();
  }

  async function loadInvoices(code) {
    applications.clear();
    clear(invoiceHost);
    invoiceHost.append(el('div', { class: 'empty', text: 'Loading open invoices…' }));
    try {
      openInvoices = await api.get(`/collections/open-invoices/${encodeURIComponent(code)}`);
    } catch {
      openInvoices = [];
    }
    clear(invoiceHost);
    if (!openInvoices.length) {
      invoiceHost.append(el('div', { class: 'empty', text: 'This customer has no open invoices.' }));
      refreshNote();
      return;
    }
    invoiceHost.append(dataTable([
      { key: 'inv_no', label: 'Invoice', class: 'mono' },
      { key: 'inv_date', label: 'Date', render: (r) => date(r.inv_date) },
      { key: 'age_days', label: 'Age', align: 'right',
        render: (r) => el('span', { class: r.age_days > 90 ? 'danger-text' : '', text: `${r.age_days} d` }) },
      { key: 'net_amount', label: 'Invoice', align: 'right', render: (r) => money(r.net_amount) },
      { key: 'balance', label: 'Open', align: 'right', render: (r) => money(r.balance) },
      { key: 'apply', label: 'Apply', align: 'right',
        render: (r) => {
          const node = el('input', {
            type: 'number', step: '0.01', class: 'num', style: 'width:120px',
            max: r.balance,
          });
          node.addEventListener('input', refreshNote);
          applications.set(r.inv_no, node);
          return node;
        } },
    ], openInvoices, { emptyText: '' }));
    refreshNote();
  }

  attachLookup(customerCode, '/customers/lookup', {
    format: (row) => row.name,
    meta: (row) => (row.balance ? money(row.balance) : ''),
    onPick: (row) => {
      customerName.textContent = `${row.name} — outstanding ${money(row.balance)}`;
      loadInvoices(row.code);
    },
  });
  if (preset) {
    api.get(`/customers/${encodeURIComponent(preset)}`).then((row) => {
      customerName.textContent = `${row.name} — outstanding ${money(row.balance)}`;
      loadInvoices(row.code);
    }).catch(() => {});
  }

  for (const node of [amount, adjustment]) node.addEventListener('input', refreshNote);

  const saveButton = el('button', { class: 'btn primary', text: 'Post payment' });

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Cancel', onClick: () => { window.location.hash = '#/collections'; } }),
      el('span', { class: 'spacer' }),
      saveButton,
    ]),

    card('Payment', el('div', {}, [
      el('div', { class: 'form-grid' }, [
        field('Customer code', customerCode),
        field('Date', colDate),
        field('Method', method),
        field('Reference', reference),
        field('Amount', amount),
        field('Adjustment (discount, write-off)', adjustment),
        field('Remarks', remarks),
      ]),
      customerName,
    ])),

    el('div', { class: 'card' }, [
      el('div', { class: 'card-head' }, [
        el('h3', { text: 'Apply to open invoices' }),
        el('button', { class: 'btn sm', text: 'Auto-allocate oldest first', onClick: autoAllocate }),
      ]),
      invoiceHost,
      el('div', { style: 'padding:12px 15px;border-top:1px solid var(--border)' }, [unappliedNote]),
    ]),
  );

  saveButton.addEventListener('click', async () => {
    const applied = [];
    for (const [invNo, node] of applications) {
      const value = Number(node.value || 0);
      if (value > 0) applied.push({ inv_no: invNo, amount: value });
    }
    const payload = {
      customer_code: customerCode.value.trim().toUpperCase(),
      col_date: colDate.value,
      method: method.value,
      reference: reference.value.trim(),
      amount: Number(amount.value || 0),
      adjustment: Number(adjustment.value || 0),
      remarks: remarks.value.trim(),
      applications: applied,
    };
    if (!payload.customer_code) return toast('Choose a customer first.', 'error');
    if (payload.amount <= 0) return toast('Enter the amount received.', 'error');

    saveButton.disabled = true;
    try {
      const collection = await api.post('/collections', payload);
      toast(`Payment ${collection.col_no} posted.`, 'success');
      window.location.hash = `#/collections/${encodeURIComponent(collection.col_no)}`;
    } catch (error) {
      reportError(error);
    } finally {
      saveButton.disabled = false;
    }
  });
}

async function reverse(collection) {
  const reason = await promptDialog(`Reverse ${collection.col_no}`, 'Reason',
    { placeholder: 'Bounced check, posted twice…' });
  if (reason === null) return;
  const sure = await confirmDialog('Reverse this payment?',
    'The invoices it settled go back to open and the customer balance rises again.',
    'Reverse payment');
  if (!sure) return;
  try {
    await api.post(`/collections/${encodeURIComponent(collection.col_no)}/reverse`, { reason });
    toast(`${collection.col_no} reversed.`, 'success');
    const container = page();
    clear(container);
    await detail(container, collection.col_no);
  } catch (error) {
    reportError(error);
  }
}
