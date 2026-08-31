// Customer master: search, detail with aging and ledger, edit.

import { api } from '../api.js';
import {
  card, clear, count, dataTable, date, debounce, el, field, input, modal, money,
  pager, readForm, reportError, select, skeletonTable, statusTag, toast, toolbar,
} from '../ui.js';
import { can, page, setTitle } from '../app.js';

const state = { q: '', flag: '', sort: 'name', direction: 'asc', page: 1 };

export const skeleton = (params) => (params.code ? 'detail' : 'list');

export async function render(container, params = {}) {
  if (params.code) return detail(container, params.code);
  return list(container);
}

async function list(container) {
  setTitle('Customer file');

  const search = el('input', { placeholder: 'Search code, name or city…', value: state.q });
  search.addEventListener('input', debounce(() => {
    state.q = search.value.trim(); state.page = 1; refresh();
  }));

  const flagSelect = select('flag', [
    ['', 'All customers'],
    ['owing', 'With an outstanding balance'],
    ['overlimit', 'Over credit limit'],
    ['inactive12m', 'No activity in 12 months'],
  ], state.flag);
  flagSelect.addEventListener('change', () => {
    state.flag = flagSelect.value; state.page = 1; refresh();
  });

  const host = el('div', { class: 'card' });
  container.append(toolbar([
    el('div', { class: 'search' }, [search]),
    flagSelect,
    el('span', { class: 'spacer' }),
    can('customer:write')
      ? el('button', { class: 'btn primary', text: '+ New customer', onClick: () => editCustomer(null) })
      : null,
  ]), host);

  async function refresh() {
    clear(host);
    host.append(skeletonTable(7, 10));
    try {
      const result = await api.get('/customers', {
        q: state.q, flag: state.flag, sort: state.sort,
        direction: state.direction, page: state.page, page_size: 50,
      });
      clear(host);
      host.append(
        dataTable([
          { key: 'code', label: 'Code', class: 'mono', sort: 'code' },
          { key: 'name', label: 'Name', class: 'wrap', sort: 'name' },
          { key: 'city', label: 'City', sort: 'city' },
          { key: 'salesman', label: 'Salesman', sort: 'salesman' },
          { key: 'price_cat', label: 'Tier' },
          { key: 'terms_days', label: 'Terms', render: (r) => (r.terms_days ? `${r.terms_days} days` : r.terms_text || '') },
          { key: 'credit_limit', label: 'Limit', align: 'right', render: (r) => money(r.credit_limit) },
          { key: 'balance', label: 'Balance', align: 'right', sort: 'balance',
            render: (r) => el('span', {
              class: r.credit_limit > 0 && r.balance > r.credit_limit ? 'danger-text' : '',
              text: money(r.balance),
            }) },
        ], result.items, {
          sort: state.sort,
          direction: state.direction,
          onSort: (sort, direction) => { Object.assign(state, { sort, direction, page: 1 }); refresh(); },
          onRowClick: (row) => { window.location.hash = `#/customers/${encodeURIComponent(row.code)}`; },
          emptyText: 'No customers match this search.',
        }),
        pager(result, (p) => { state.page = p; refresh(); }),
      );
    } catch (error) {
      clear(host);
      host.append(el('div', { class: 'empty', text: error.detail || 'Could not load customers.' }));
    }
  }

  await refresh();
}

async function detail(container, code) {
  setTitle(`Customer · ${code}`);
  const [customer, aging, ledger, monthly] = await Promise.all([
    api.get(`/customers/${encodeURIComponent(code)}`),
    api.get(`/customers/${encodeURIComponent(code)}/aging`),
    api.get(`/customers/${encodeURIComponent(code)}/ledger`, { limit: 100 }),
    api.get(`/customers/${encodeURIComponent(code)}/monthly`, { years: 2 }),
  ]);

  const overLimit = customer.credit_limit > 0 && customer.balance > customer.credit_limit;

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Back to customers', onClick: () => { window.location.hash = '#/customers'; } }),
      el('span', { class: 'spacer' }),
      can('invoice:write') ? el('button', {
        class: 'btn', text: 'New invoice',
        onClick: () => { window.location.hash = `#/invoices/new?customer=${encodeURIComponent(code)}`; },
      }) : null,
      can('collection:write') ? el('button', {
        class: 'btn', text: 'Record payment',
        onClick: () => { window.location.hash = `#/collections/new?customer=${encodeURIComponent(code)}`; },
      }) : null,
      can('customer:write') ? el('button', {
        class: 'btn primary', text: 'Edit', onClick: () => editCustomer(customer),
      }) : null,
    ]),

    el('div', { class: 'stat-grid' }, [
      statBox('Outstanding balance', money(customer.balance),
        `${count(customer.open_invoices)} open invoices`, overLimit ? 'danger' : ''),
      statBox('Credit limit', money(customer.credit_limit),
        overLimit ? 'Over the limit' : 'Within the limit', overLimit ? 'danger' : 'ok'),
      statBox('Over 90 days', money(aging.d90 ?? 0),
        (aging.d90 ?? 0) > 0 ? 'Needs chasing' : 'Clear', (aging.d90 ?? 0) > 0 ? 'warn' : 'ok'),
      statBox('Last payment', customer.last_payment ? money(customer.last_payment.net_amount) : '—',
        customer.last_payment ? date(customer.last_payment.col_date) : 'No payments recorded'),
    ]),

    card('Aging', dataTable([
      { key: 'current', label: 'Current', align: 'right', render: (r) => money(r.current) },
      { key: 'd30', label: '31–60 days', align: 'right', render: (r) => money(r.d30) },
      { key: 'd60', label: '61–90 days', align: 'right', render: (r) => money(r.d60) },
      { key: 'd90', label: 'Over 90 days', align: 'right', render: (r) => money(r.d90) },
      { key: 'total', label: 'Total', align: 'right', render: (r) => money(r.total) },
    ], [aging], { emptyText: 'Nothing outstanding.' }), [], { flush: true }),

    card(customer.name, el('div', { class: 'form-grid' }, [
      ['Code', customer.code], ['Address', customer.address], ['City', customer.city],
      ['Contact', customer.contact_person], ['Phone', customer.phone],
      ['Terms', customer.terms_days ? `${customer.terms_days} days` : customer.terms_text],
      ['Price tier', customer.price_cat], ['Salesman', customer.salesman],
      ['TIN', customer.tin], ['Business style', customer.business_style],
      ['Customer since', date(customer.date_started)], ['Last transaction', date(customer.last_txn)],
      ['Lifetime purchases', money(customer.purchases)], ['Lifetime payments', money(customer.payments)],
      ['Remarks', customer.remarks],
    ].map(([label, value]) => el('div', { class: 'field' }, [
      el('span', { text: label }),
      el('div', { text: value === null || value === undefined || value === '' ? '—' : String(value) }),
    ])))),

    card('Monthly history', dataTable([
      { key: 'year', label: 'Year' },
      { key: 'month', label: 'Month', render: (r) => new Date(2000, r.month - 1, 1)
        .toLocaleString(undefined, { month: 'long' }) },
      { key: 'sales', label: 'Sales', align: 'right', render: (r) => money(r.sales) },
      { key: 'returns', label: 'Returns', align: 'right', render: (r) => money(r.returns) },
    ], monthly, { emptyText: 'No history recorded.' }), [], { flush: true }),

    card('Ledger', dataTable([
      { key: 'date', label: 'Date', render: (r) => date(r.date) },
      { key: 'kind', label: 'Type', render: (r) => statusTag(r.kind) },
      { key: 'document', label: 'Document', class: 'mono' },
      { key: 'remarks', label: 'Remarks', class: 'wrap' },
      { key: 'charge', label: 'Charge', align: 'right', render: (r) => (r.charge ? money(r.charge) : '') },
      { key: 'credit', label: 'Credit', align: 'right', render: (r) => (r.credit ? money(r.credit) : '') },
      { key: 'balance', label: 'Open', align: 'right', render: (r) => (r.balance ? money(r.balance) : '') },
    ], ledger, {
      emptyText: 'No transactions yet.',
      onRowClick: (row) => {
        const path = { INVOICE: 'invoices', RETURN: 'returns', PAYMENT: 'collections' }[row.kind];
        if (path) window.location.hash = `#/${path}/${encodeURIComponent(row.document)}`;
      },
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

function editCustomer(customer) {
  const isNew = !customer;
  const form = el('div', { class: 'form-grid' }, [
    field('Code', input('code', {
      value: customer?.code || '', readonly: !isNew, required: true, maxlength: 10,
      style: 'text-transform:uppercase',
    })),
    field('Name', input('name', { value: customer?.name || '', required: true }), { span: true }),
    field('Address', input('address', { value: customer?.address || '' }), { span: true }),
    field('City', input('city', { value: customer?.city || '' })),
    field('Contact person', input('contact_person', { value: customer?.contact_person || '' })),
    field('Phone', input('phone', { value: customer?.phone || '' })),
    field('Terms (text)', input('terms_text', { value: customer?.terms_text || '' })),
    field('Terms (days)', input('terms_days', { type: 'number', value: customer?.terms_days ?? 0, class: 'num' })),
    field('Price tier', select('price_cat', ['A', 'B', 'C', 'D', 'E'], customer?.price_cat || 'A')),
    field('Credit limit', input('credit_limit', { type: 'number', step: '0.01', value: customer?.credit_limit ?? 0, class: 'num' })),
    field('Salesman', input('salesman', { value: customer?.salesman || '' })),
    field('TIN', input('tin', { value: customer?.tin || '' })),
    field('Business style', input('business_style', { value: customer?.business_style || '' })),
    field('Remarks', input('remarks', { value: customer?.remarks || '' }), { span: true }),
  ]);

  modal({
    title: isNew ? 'New customer' : `Edit ${customer.code}`,
    wide: true,
    body: form,
    actions: [
      { label: 'Cancel' },
      {
        label: 'Save',
        kind: 'primary',
        onClick: async () => {
          const payload = readForm(form);
          payload.code = (payload.code || '').toUpperCase();
          if (isNew) {
            await api.post('/customers', payload);
            toast(`Customer ${payload.code} created.`, 'success');
            window.location.hash = `#/customers/${encodeURIComponent(payload.code)}`;
          } else {
            payload.version = customer.version;
            await api.put(`/customers/${encodeURIComponent(customer.code)}`, payload);
            toast('Saved.', 'success');
          }
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
  const code = hash.startsWith('/customers/') ? decodeURIComponent(hash.slice(11)) : null;
  (code ? detail(container, code) : list(container)).catch(reportError);
}
