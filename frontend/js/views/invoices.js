// Sales invoices: browse, view, create, cancel, print.

import { api } from '../api.js';
import {
  attachLookup, card, clear, confirmDialog, count, dataTable, date, debounce, el,
  field, input, modal, money, pager, promptDialog, qty, reportError, select,
  statusTag, toast, today, toolbar,
} from '../ui.js';
import { can, page, setTitle } from '../app.js';
import { lineEditor } from './lineEditor.js';

const state = {
  q: '', status: '', date_from: '', date_to: '', unpaid_only: false,
  sort: 'date', direction: 'desc', page: 1,
};

export async function render(container, params = {}) {
  const hash = window.location.hash.slice(1);
  if (hash.startsWith('/invoices/new')) return editor(container, hash);
  if (params.id) return detail(container, params.id);
  return list(container);
}

/* ----------------------------------------------------------------- list -- */

async function list(container) {
  setTitle('Invoices');

  const search = el('input', { placeholder: 'Invoice number or customer…', value: state.q });
  search.addEventListener('input', debounce(() => {
    state.q = search.value.trim(); state.page = 1; refresh();
  }));

  const statusSelect = select('status', [
    ['', 'All statuses'], ['OPEN', 'Open'], ['PAID', 'Paid'], ['CANCELLED', 'Cancelled'],
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

  const unpaid = el('label', { class: 'hint', style: 'display:flex;gap:6px;align-items:center' }, [
    el('input', {
      type: 'checkbox', checked: state.unpaid_only,
      onChange: (event) => { state.unpaid_only = event.target.checked; state.page = 1; refresh(); },
    }),
    'Unpaid only',
  ]);

  const host = el('div', { class: 'card' });
  container.append(toolbar([
    el('div', { class: 'search' }, [search]),
    statusSelect, from, to, unpaid,
    el('span', { class: 'spacer' }),
    can('invoice:write')
      ? el('button', { class: 'btn primary', text: '+ New invoice',
                       onClick: () => { window.location.hash = '#/invoices/new'; } })
      : null,
  ]), host);

  async function refresh() {
    clear(host);
    host.append(el('div', { class: 'empty', text: 'Loading…' }));
    try {
      const result = await api.get('/invoices', {
        q: state.q, status: state.status, date_from: state.date_from,
        date_to: state.date_to, unpaid_only: state.unpaid_only,
        sort: state.sort, direction: state.direction,
        page: state.page, page_size: 50,
      });
      clear(host);
      host.append(
        dataTable([
          { key: 'inv_no', label: 'Number', class: 'mono', sort: 'number' },
          { key: 'inv_date', label: 'Date', sort: 'date', render: (r) => date(r.inv_date) },
          { key: 'customer_name', label: 'Customer', class: 'wrap', sort: 'customer' },
          { key: 'salesman', label: 'Salesman' },
          { key: 'due_date', label: 'Due', render: (r) => date(r.due_date) },
          { key: 'net_amount', label: 'Amount', align: 'right', sort: 'amount',
            render: (r) => money(r.net_amount) },
          { key: 'paid_amount', label: 'Paid', align: 'right', render: (r) => money(r.paid_amount) },
          { key: 'balance', label: 'Balance', align: 'right', sort: 'balance',
            render: (r) => el('span', { class: r.balance > 0 ? 'warn-text' : '', text: money(r.balance) }) },
          { key: 'status', label: 'Status', render: (r) => statusTag(r.status) },
        ], result.items, {
          sort: state.sort,
          direction: state.direction,
          onSort: (sort, direction) => { Object.assign(state, { sort, direction, page: 1 }); refresh(); },
          onRowClick: (row) => { window.location.hash = `#/invoices/${encodeURIComponent(row.inv_no)}`; },
          footer: {
            inv_no: `${count(result.total)} invoices`,
            net_amount: money(result.summary.net),
            balance: money(result.summary.balance),
          },
          emptyText: 'No invoices match these filters.',
        }),
        pager(result, (p) => { state.page = p; refresh(); }),
      );
    } catch (error) {
      clear(host);
      host.append(el('div', { class: 'empty', text: error.detail || 'Could not load invoices.' }));
    }
  }

  await refresh();
}

/* --------------------------------------------------------------- detail -- */

async function detail(container, invNo) {
  setTitle(`Invoice ${invNo}`);
  const invoice = await api.get(`/invoices/${encodeURIComponent(invNo)}`);

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Back to invoices', onClick: () => { window.location.hash = '#/invoices'; } }),
      el('span', { class: 'spacer' }),
      // Printing this screen would send the stat boxes and the payments card to
      // the printer. The document lives on its own page.
      el('a', { class: 'btn', text: 'Print',
                href: `#/invoices/print/${encodeURIComponent(invoice.inv_no)}` }),
      can('invoice:write') && invoice.status !== 'CANCELLED'
        ? el('button', { class: 'btn', text: 'Edit header', onClick: () => editHeader(invoice) })
        : null,
      can('invoice:write') && invoice.status !== 'CANCELLED'
        ? el('button', { class: 'btn danger', text: 'Cancel invoice', onClick: () => cancel(invoice) })
        : null,
    ]),

    el('div', { class: 'stat-grid' }, [
      statBox('Net amount', money(invoice.net_amount),
        invoice.gross !== invoice.net_amount ? `Gross ${money(invoice.gross)}` : ''),
      statBox('Paid', money(invoice.paid_amount), `${invoice.payments.length} payment(s)`),
      statBox('Balance', money(invoice.balance),
        invoice.balance > 0 ? 'Outstanding' : 'Settled',
        invoice.balance > 0 ? 'warn' : 'ok'),
      statBox('Status', invoice.status, `${date(invoice.inv_date)} · due ${date(invoice.due_date)}`),
    ]),

    card(`${invoice.customer_code} — ${invoice.customer_name}`,
      el('div', { class: 'form-grid' }, [
        ['Invoice number', invoice.inv_no], ['Date', date(invoice.inv_date)],
        ['Address', `${invoice.address} ${invoice.city}`.trim()],
        ['Terms', invoice.terms_days ? `${invoice.terms_days} days` : invoice.terms_text],
        ['Price tier', invoice.price_cat], ['Salesman', invoice.salesman],
        ['Remarks', invoice.remarks],
        ['Prepared by', `${invoice.created_by} · ${date(invoice.created_at)}`],
      ].map(([label, value]) => el('div', { class: 'field' }, [
        el('span', { text: label }),
        el('div', { text: value || '—' }),
      ]))),
      [el('a', { class: 'btn sm', href: `#/customers/${encodeURIComponent(invoice.customer_code)}` },
        ['Open customer'])]),

    card('Lines', dataTable([
      { key: 'line_no', label: '#' },
      { key: 'stock_code', label: 'Code', class: 'mono' },
      { key: 'description', label: 'Description', class: 'wrap' },
      { key: 'qty', label: 'Qty', align: 'right', render: (r) => qty(r.qty) },
      { key: 'unit', label: 'Unit' },
      { key: 'unit_price', label: 'Price', align: 'right', render: (r) => money(r.unit_price) },
      { key: 'disc1', label: 'Disc %', align: 'right',
        render: (r) => [r.disc1, r.disc2, r.disc3].filter(Boolean).join(' / ') },
      { key: 'line_total', label: 'Total', align: 'right', render: (r) => money(r.line_total) },
    ], invoice.lines, {
      emptyText: 'This invoice has no stored line detail.',
      footer: { description: 'Net of discounts', line_total: money(invoice.net_amount) },
    }), [], { flush: true }),

    invoice.payments.length ? card('Payments applied', dataTable([
      { key: 'col_no', label: 'Payment', class: 'mono' },
      { key: 'col_date', label: 'Date', render: (r) => date(r.col_date) },
      { key: 'method', label: 'Method' },
      { key: 'check_no', label: 'Reference' },
      { key: 'amount', label: 'Amount', align: 'right', render: (r) => money(r.amount) },
    ], invoice.payments, {
      onRowClick: (row) => { window.location.hash = `#/collections/${encodeURIComponent(row.col_no)}`; },
    }), [], { flush: true }) : null,
  );
}

function statBox(label, value, sub, kind = '') {
  return el('div', { class: `stat ${kind}` }, [
    el('div', { class: 'label', text: label }),
    el('div', { class: 'value', text: value }),
    sub ? el('div', { class: 'sub', text: sub }) : null,
  ]);
}

/* --------------------------------------------------------------- editor -- */

async function editor(container, hash) {
  setTitle('New invoice');
  const preset = new URLSearchParams(hash.split('?')[1] || '').get('customer') || '';

  const customerCode = input('customer_code', {
    placeholder: 'Customer code', style: 'text-transform:uppercase', value: preset,
  });
  const customerName = el('div', { class: 'hint', text: 'No customer selected.' });
  const invDate = input('inv_date', { type: 'date', value: today() });
  const terms = input('terms_days', { type: 'number', value: 0, class: 'num' });
  const priceCat = select('price_cat', ['A', 'B', 'C', 'D', 'E'], 'A');
  const salesman = input('salesman', { style: 'text-transform:uppercase' });
  const remarks = input('remarks', { placeholder: 'Optional note printed on the invoice' });
  const disc1 = input('disc1', { type: 'number', step: '0.01', value: 0, class: 'num' });
  const disc2 = input('disc2', { type: 'number', step: '0.01', value: 0, class: 'num' });

  const netCell = el('div', { class: 'amount', text: money(0) });
  const subtotalCell = el('div', { class: 'amount', text: money(0) });

  let priceField = 'price_a';
  const lines = lineEditor({
    priceField,
    onChange: (subtotal) => {
      subtotalCell.textContent = money(subtotal);
      let net = subtotal;
      for (const node of [disc1, disc2]) {
        const pct = Number(node.value || 0);
        if (pct) net *= (1 - pct / 100);
      }
      netCell.textContent = money(net);
    },
  });

  for (const node of [disc1, disc2]) node.addEventListener('input', () => lines.recalc());
  priceCat.addEventListener('change', () => {
    priceField = `price_${priceCat.value.toLowerCase()}`;
  });

  function applyCustomer(row) {
    customerName.textContent = `${row.name} — ${row.city || ''}`.trim();
    priceCat.value = row.price_cat || 'A';
    priceField = `price_${(row.price_cat || 'a').toLowerCase()}`;
    terms.value = row.terms_days || 0;
    salesman.value = row.salesman || '';
    if (row.balance > 0) {
      customerName.textContent += ` · outstanding ${money(row.balance)}`;
    }
    if (row.credit_limit > 0 && row.balance > row.credit_limit) {
      customerName.className = 'danger-text';
      customerName.textContent += ' · OVER CREDIT LIMIT';
    } else {
      customerName.className = 'hint';
    }
  }

  attachLookup(customerCode, '/customers/lookup', {
    format: (row) => row.name,
    meta: (row) => (row.balance ? money(row.balance) : ''),
    onPick: applyCustomer,
  });
  if (preset) {
    api.get(`/customers/${encodeURIComponent(preset)}`).then(applyCustomer).catch(() => {});
  }

  const saveButton = el('button', { class: 'btn primary', text: 'Save invoice' });

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Cancel', onClick: () => { window.location.hash = '#/invoices'; } }),
      el('span', { class: 'spacer' }),
      saveButton,
    ]),

    card('Customer and terms', el('div', {}, [
      el('div', { class: 'form-grid' }, [
        field('Customer code', customerCode),
        field('Invoice date', invDate),
        field('Terms (days)', terms),
        field('Price tier', priceCat),
        field('Salesman', salesman),
        field('Remarks', remarks),
      ]),
      customerName,
    ])),

    card('Lines', el('div', {}, [
      lines.node,
      el('div', { class: 'form-grid', style: 'margin-top:14px;max-width:420px' }, [
        field('Invoice discount 1 (%)', disc1),
        field('Invoice discount 2 (%)', disc2),
      ]),
      el('div', { class: 'totals' }, [
        el('div', {}, [el('div', { class: 'label', text: 'Subtotal' }), subtotalCell]),
        el('div', {}, [el('div', { class: 'label', text: 'Net amount' }), netCell]),
      ]),
    ])),
  );

  saveButton.addEventListener('click', async () => {
    const payload = {
      customer_code: customerCode.value.trim().toUpperCase(),
      inv_date: invDate.value,
      terms_days: Number(terms.value || 0),
      price_cat: priceCat.value,
      salesman: salesman.value.trim().toUpperCase(),
      remarks: remarks.value.trim(),
      disc1: Number(disc1.value || 0),
      disc2: Number(disc2.value || 0),
      lines: lines.getLines(),
    };
    if (!payload.customer_code) return toast('Choose a customer first.', 'error');
    if (!payload.lines.length) return toast('Add at least one line with a quantity.', 'error');

    saveButton.disabled = true;
    try {
      const invoice = await api.post('/invoices', payload);
      toast(`Invoice ${invoice.inv_no} saved.`, 'success');
      window.location.hash = `#/invoices/${encodeURIComponent(invoice.inv_no)}`;
    } catch (error) {
      reportError(error);
    } finally {
      saveButton.disabled = false;
    }
  });
}

/* -------------------------------------------------------------- actions -- */

function editHeader(invoice) {
  const form = el('div', { class: 'form-grid' }, [
    field('Salesman', input('salesman', { value: invoice.salesman })),
    field('Terms (days)', input('terms_days', { type: 'number', value: invoice.terms_days, class: 'num' })),
    field('Terms (text)', input('terms_text', { value: invoice.terms_text })),
    field('Remarks', input('remarks', { value: invoice.remarks }), { span: true }),
  ]);
  modal({
    title: `Edit ${invoice.inv_no}`,
    body: el('div', {}, [
      el('p', { class: 'hint' }, ['Lines cannot be changed once an invoice is posted. '
        + 'Use a sales return to correct quantities, or cancel and reissue.']),
      form,
    ]),
    actions: [
      { label: 'Cancel' },
      {
        label: 'Save',
        kind: 'primary',
        onClick: async () => {
          const values = {};
          form.querySelectorAll('[name]').forEach((n) => { values[n.name] = n.value; });
          values.version = invoice.version;
          await api.put(`/invoices/${encodeURIComponent(invoice.inv_no)}`, values);
          toast('Saved.', 'success');
          reload();
        },
      },
    ],
  });
}

async function cancel(invoice) {
  const reason = await promptDialog(`Cancel ${invoice.inv_no}`, 'Reason',
    { placeholder: 'Wrong customer, duplicate, returned in full…' });
  if (reason === null) return;
  const sure = await confirmDialog('Cancel this invoice?',
    'Stock goes back on the shelf and the customer balance is reduced. '
    + 'The invoice stays on file, marked cancelled.', 'Cancel invoice');
  if (!sure) return;
  try {
    await api.post(`/invoices/${encodeURIComponent(invoice.inv_no)}/cancel`,
      { reason, version: invoice.version });
    toast(`${invoice.inv_no} cancelled.`, 'success');
    reload();
  } catch (error) {
    reportError(error);
  }
}

function reload() {
  const container = page();
  clear(container);
  const hash = window.location.hash.slice(1);
  const id = hash.startsWith('/invoices/') ? decodeURIComponent(hash.slice(10)) : null;
  (id ? detail(container, id) : list(container)).catch(reportError);
}
