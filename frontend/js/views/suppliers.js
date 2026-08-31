// Supplier master: search, detail with supplied items and purchase history.

import { api } from '../api.js';
import {
  card, clear, count, dataTable, date, debounce, el, field, input, modal, money,
  pager, readForm, reportError, skeletonTable, statusTag, toast, toolbar,
} from '../ui.js';
import { can, page, setTitle } from '../app.js';

const state = { q: '', sort: 'name', direction: 'asc', page: 1 };

export const skeleton = (params) => (params.code ? 'detail' : 'list');

export async function render(container, params = {}) {
  if (params.code) return detail(container, params.code);
  return list(container);
}

async function list(container) {
  setTitle('Supplier file');

  const search = el('input', { placeholder: 'Search code, name or city…', value: state.q });
  search.addEventListener('input', debounce(() => {
    state.q = search.value.trim(); state.page = 1; refresh();
  }));

  const host = el('div', { class: 'card' });
  container.append(toolbar([
    el('div', { class: 'search' }, [search]),
    el('span', { class: 'spacer' }),
    can('supplier:write')
      ? el('button', { class: 'btn primary', text: '+ New supplier', onClick: () => editSupplier(null) })
      : null,
  ]), host);

  async function refresh() {
    clear(host);
    host.append(skeletonTable(6, 10));
    try {
      const result = await api.get('/suppliers', {
        q: state.q, sort: state.sort, direction: state.direction,
        page: state.page, page_size: 50,
      });
      clear(host);
      host.append(
        dataTable([
          { key: 'code', label: 'Code', class: 'mono', sort: 'code' },
          { key: 'name', label: 'Name', class: 'wrap', sort: 'name' },
          { key: 'city', label: 'City', sort: 'city' },
          { key: 'contact', label: 'Contact' },
          { key: 'phone', label: 'Phone' },
          { key: 'terms_days', label: 'Terms', render: (r) => (r.terms_days ? `${r.terms_days} days` : r.terms_text || '') },
          { key: 'balance', label: 'Payable', align: 'right', sort: 'balance', render: (r) => money(r.balance) },
        ], result.items, {
          sort: state.sort,
          direction: state.direction,
          onSort: (sort, direction) => { Object.assign(state, { sort, direction, page: 1 }); refresh(); },
          onRowClick: (row) => { window.location.hash = `#/suppliers/${encodeURIComponent(row.code)}`; },
          emptyText: 'No suppliers match this search.',
        }),
        pager(result, (p) => { state.page = p; refresh(); }),
      );
    } catch (error) {
      clear(host);
      host.append(el('div', { class: 'empty', text: error.detail || 'Could not load suppliers.' }));
    }
  }

  await refresh();
}

async function detail(container, code) {
  setTitle(`Supplier · ${code}`);
  const [supplier, items, purchases] = await Promise.all([
    api.get(`/suppliers/${encodeURIComponent(code)}`),
    api.get(`/suppliers/${encodeURIComponent(code)}/items`),
    api.get(`/suppliers/${encodeURIComponent(code)}/purchases`, { limit: 50 }).catch(() => []),
  ]);

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Back to suppliers', onClick: () => { window.location.hash = '#/suppliers'; } }),
      el('span', { class: 'spacer' }),
      can('purchase:write') ? el('button', {
        class: 'btn', text: 'New purchase',
        onClick: () => { window.location.hash = `#/purchases/new?supplier=${encodeURIComponent(code)}`; },
      }) : null,
      can('supplier:write') ? el('button', {
        class: 'btn primary', text: 'Edit', onClick: () => editSupplier(supplier),
      }) : null,
    ]),

    el('div', { class: 'stat-grid' }, [
      statBox('Payable', money(supplier.balance), 'Outstanding to this supplier'),
      statBox('Purchases, last 12 months', money(supplier.purchases_12m || 0), ''),
      statBox('Items supplied', count(supplier.items_supplied), 'Stock codes'),
      statBox('Credit limit', money(supplier.credit_limit),
        supplier.terms_days ? `${supplier.terms_days} day terms` : supplier.terms_text || ''),
    ]),

    card(supplier.name, el('div', { class: 'form-grid' }, [
      ['Code', supplier.code], ['Address', supplier.address], ['City', supplier.city],
      ['Contact', supplier.contact], ['Phone', supplier.phone],
      ['Terms', supplier.terms_days ? `${supplier.terms_days} days` : supplier.terms_text],
      ['Lifetime purchases', money(supplier.purchases)],
      ['Lifetime payments', money(supplier.payments)],
      ['Last transaction', date(supplier.last_txn)],
      ['Remarks', supplier.remarks],
    ].map(([label, value]) => el('div', { class: 'field' }, [
      el('span', { text: label }),
      el('div', { text: value === null || value === undefined || value === '' ? '—' : String(value) }),
    ])))),

    card('Purchase history', dataTable([
      { key: 'pur_no', label: 'Number', class: 'mono' },
      { key: 'pur_date', label: 'Date', render: (r) => date(r.pur_date) },
      { key: 'net_amount', label: 'Amount', align: 'right', render: (r) => money(r.net_amount) },
      { key: 'balance', label: 'Balance', align: 'right', render: (r) => money(r.balance) },
      { key: 'status', label: 'Status', render: (r) => statusTag(r.status) },
    ], purchases, {
      emptyText: 'No purchases recorded.',
      onRowClick: (row) => { window.location.hash = `#/purchases/${encodeURIComponent(row.pur_no)}`; },
    }), [], { flush: true }),

    card('Items supplied', dataTable([
      { key: 'code', label: 'Code', class: 'mono' },
      { key: 'name', label: 'Description', class: 'wrap' },
      { key: 'qty_on_hand', label: 'On hand', align: 'right' },
      { key: 'unit', label: 'Unit' },
      { key: 'cost', label: 'Cost', align: 'right', render: (r) => money(r.cost) },
      { key: 'price_a', label: 'Price A', align: 'right', render: (r) => money(r.price_a) },
    ], items, {
      emptyText: 'No stock items are linked to this supplier.',
      onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.code)}`; },
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

function editSupplier(supplier) {
  const isNew = !supplier;
  const form = el('div', { class: 'form-grid' }, [
    field('Code', input('code', {
      value: supplier?.code || '', readonly: !isNew, required: true, maxlength: 10,
      style: 'text-transform:uppercase',
    })),
    field('Name', input('name', { value: supplier?.name || '', required: true }), { span: true }),
    field('Address', input('address', { value: supplier?.address || '' }), { span: true }),
    field('City', input('city', { value: supplier?.city || '' })),
    field('Contact', input('contact', { value: supplier?.contact || '' })),
    field('Phone', input('phone', { value: supplier?.phone || '' })),
    field('Terms (text)', input('terms_text', { value: supplier?.terms_text || '' })),
    field('Terms (days)', input('terms_days', { type: 'number', value: supplier?.terms_days ?? 0, class: 'num' })),
    field('Credit limit', input('credit_limit', { type: 'number', step: '0.01', value: supplier?.credit_limit ?? 0, class: 'num' })),
    field('Remarks', input('remarks', { value: supplier?.remarks || '' }), { span: true }),
  ]);

  modal({
    title: isNew ? 'New supplier' : `Edit ${supplier.code}`,
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
            await api.post('/suppliers', payload);
            toast(`Supplier ${payload.code} created.`, 'success');
            window.location.hash = `#/suppliers/${encodeURIComponent(payload.code)}`;
          } else {
            payload.version = supplier.version;
            await api.put(`/suppliers/${encodeURIComponent(supplier.code)}`, payload);
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
  const code = hash.startsWith('/suppliers/') ? decodeURIComponent(hash.slice(11)) : null;
  (code ? detail(container, code) : list(container)).catch(reportError);
}
