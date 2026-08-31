// Stock master: search, detail, edit, inventory adjustment, movement ledger.

import { api } from '../api.js';
import {
  card, clear, dataTable, date, debounce, el, field, input, modal, money,
  pager, qty, reportError, select, readForm, skeletonTable, statusTag, toast,
  toolbar,
} from '../ui.js';
import { can, page, setTitle } from '../app.js';

const state = { q: '', division: '', flag: '', sort: 'code', direction: 'asc', page: 1 };

// One module, two screens: a searchable list and one item's detail page.
export const skeleton = (params) => (params.code ? 'detail' : 'list');

export async function render(container, params = {}) {
  if (params.code) return detail(container, params.code);
  return list(container);
}

/* ----------------------------------------------------------------- list -- */

async function list(container) {
  setTitle('Stock file');

  const search = el('input', { placeholder: 'Search code or description…', value: state.q });
  search.addEventListener('input', debounce(() => {
    state.q = search.value.trim();
    state.page = 1;
    refresh();
  }));

  const divisionSelect = select('division', [['', 'All divisions']], state.division);
  divisionSelect.addEventListener('change', () => {
    state.division = divisionSelect.value; state.page = 1; refresh();
  });

  const flagSelect = select('flag', [
    ['', 'All items'],
    ['low', 'At or below reorder point'],
    ['zero', 'Depleted'],
    ['expiring', 'Expiring within 90 days'],
    ['expired', 'Expired'],
  ], state.flag);
  flagSelect.addEventListener('change', () => {
    state.flag = flagSelect.value; state.page = 1; refresh();
  });

  const bar = toolbar([
    el('div', { class: 'search' }, [search]),
    divisionSelect,
    flagSelect,
    el('span', { class: 'spacer' }),
    can('stock:write')
      ? el('button', { class: 'btn primary', text: '+ New item', onClick: () => editItem(null) })
      : null,
  ]);

  const host = el('div', { class: 'card' });
  container.append(bar, host);

  api.get('/stock/divisions')
    .then((rows) => rows.forEach((row) =>
      divisionSelect.append(el('option', { value: row.code }, [`${row.code} (${row.items})`]))))
    .catch(() => {});

  async function refresh() {
    clear(host);
    host.append(skeletonTable(8, 10));
    try {
      const result = await api.get('/stock', {
        q: state.q, division: state.division, flag: state.flag,
        sort: state.sort, direction: state.direction,
        page: state.page, page_size: 50,
      });
      clear(host);
      host.append(
        dataTable([
          { key: 'code', label: 'Code', class: 'mono', sort: 'code' },
          { key: 'name', label: 'Description', class: 'wrap', sort: 'name' },
          { key: 'division', label: 'Div', sort: 'division' },
          { key: 'qty_on_hand', label: 'On hand', align: 'right', sort: 'qty',
            render: (r) => {
              const node = el('span', { text: qty(r.qty_on_hand) });
              if (r.qty_on_hand <= 0) node.className = 'danger-text';
              else if (r.reorder_point > 0 && r.qty_on_hand <= r.reorder_point) node.className = 'warn-text';
              return node;
            } },
          { key: 'unit', label: 'Unit' },
          { key: 'cost', label: 'Cost', align: 'right', sort: 'cost', render: (r) => money(r.cost) },
          { key: 'price_a', label: 'Price A', align: 'right', sort: 'price', render: (r) => money(r.price_a) },
          { key: 'expiry_date', label: 'Expiry', sort: 'expiry', render: (r) => date(r.expiry_date) },
        ], result.items, {
          sort: state.sort,
          direction: state.direction,
          onSort: (sort, direction) => {
            Object.assign(state, { sort, direction, page: 1 });
            refresh();
          },
          onRowClick: (row) => { window.location.hash = `#/stock/${encodeURIComponent(row.code)}`; },
          emptyText: 'No stock items match this search.',
        }),
        pager(result, (p) => { state.page = p; refresh(); }),
      );
    } catch (error) {
      clear(host);
      host.append(el('div', { class: 'empty', text: error.detail || 'Could not load stock.' }));
    }
  }

  await refresh();
}

/* --------------------------------------------------------------- detail -- */

async function detail(container, code) {
  setTitle(`Stock · ${code}`);
  const item = await api.get(`/stock/${encodeURIComponent(code)}`);
  const moves = await api.get(`/stock/${encodeURIComponent(code)}/moves`, { limit: 60 });

  const facts = (rows) => el('div', { class: 'form-grid' }, rows.map(([label, value]) =>
    el('div', { class: 'field' }, [
      el('span', { text: label }),
      el('div', { text: value === null || value === undefined || value === '' ? '—' : String(value) }),
    ])));

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Back to stock', onClick: () => { window.location.hash = '#/stock'; } }),
      el('span', { class: 'spacer' }),
      can('stock:write') ? el('button', { class: 'btn', text: 'Adjust quantity', onClick: () => adjust(item) }) : null,
      can('stock:write') ? el('button', { class: 'btn primary', text: 'Edit', onClick: () => editItem(item) }) : null,
    ]),

    el('div', { class: 'stat-grid' }, [
      stat2('On hand', qty(item.qty_on_hand), `${item.unit || ''} · reorder at ${qty(item.reorder_point)}`,
        item.qty_on_hand <= 0 ? 'danger'
          : (item.reorder_point > 0 && item.qty_on_hand <= item.reorder_point) ? 'warn' : ''),
      stat2('Cost', money(item.cost), `Stock value ${money(item.qty_on_hand * item.cost)}`),
      stat2('Price A', money(item.price_a),
        `B ${money(item.price_b)} · C ${money(item.price_c)}`),
      stat2('Sold, last 12 months', qty(item.sold_12m || 0), item.unit || ''),
    ]),

    card(item.name, facts([
      ['Code', item.code],
      ['Division', item.division],
      ['Category', item.category],
      ['Pack', item.pack_qty ? `${item.pack_qty} ${item.pack_unit}` : ''],
      ['Lot number', item.lot_no],
      ['Expiry', date(item.expiry_date)],
      ['Supplier', item.supplier_name ? `${item.supplier_code} — ${item.supplier_name}` : item.supplier_code],
      ['Prices D / E', `${money(item.price_d)} / ${money(item.price_e)}`],
      ['Last transaction', date(item.last_txn)],
      ['Price updated', date(item.price_updated)],
      ['Remarks', item.remarks],
      ['Last edited', item.updated_by ? `${item.updated_by} · ${date(item.updated_at)}` : ''],
    ])),

    card('Movement ledger', dataTable([
      { key: 'doc_date', label: 'Date', render: (r) => date(r.doc_date) },
      { key: 'move_type', label: 'Type', render: (r) => statusTag(r.move_type) },
      { key: 'doc_no', label: 'Document', class: 'mono' },
      { key: 'customer_code', label: 'Party', render: (r) => r.customer_code || r.supplier_code || '' },
      { key: 'qty', label: 'Qty', align: 'right',
        render: (r) => el('span', { class: r.qty < 0 ? 'danger-text' : 'ok-text', text: qty(r.qty) }) },
      { key: 'unit_price', label: 'Price', align: 'right', render: (r) => money(r.unit_price) },
      { key: 'line_total', label: 'Total', align: 'right', render: (r) => money(r.line_total) },
      { key: 'balance_after', label: 'Balance', align: 'right',
        render: (r) => (r.balance_after === null ? '' : qty(r.balance_after)) },
      { key: 'remarks', label: 'Remarks', class: 'wrap' },
    ], moves, { emptyText: 'No movements recorded for this item yet.' }), [], { flush: true }),
  );
}

function stat2(label, value, sub, kind = '') {
  return el('div', { class: `stat ${kind}` }, [
    el('div', { class: 'label', text: label }),
    el('div', { class: 'value', text: value }),
    sub ? el('div', { class: 'sub', text: sub }) : null,
  ]);
}

/* ---------------------------------------------------------------- forms -- */

function editItem(item) {
  const isNew = !item;
  const form = el('div', { class: 'form-grid' }, [
    field('Code', input('code', {
      value: item?.code || '', readonly: !isNew, required: true, maxlength: 10,
      style: 'text-transform:uppercase',
    })),
    field('Description', input('name', { value: item?.name || '', required: true }), { span: true }),
    field('Division', input('division', { value: item?.division || '', maxlength: 5 })),
    field('Category', input('category', { value: item?.category || '', maxlength: 5 })),
    field('Unit', input('unit', { value: item?.unit || '', maxlength: 4 })),
    field('Pack quantity', input('pack_qty', { type: 'number', value: item?.pack_qty ?? 0, class: 'num' })),
    field('Pack unit', input('pack_unit', { value: item?.pack_unit || '', maxlength: 4 })),
    field('Supplier code', input('supplier_code', { value: item?.supplier_code || '' })),
    field('Lot number', input('lot_no', { value: item?.lot_no || '' })),
    field('Expiry date', input('expiry_date', { type: 'date', value: item?.expiry_date || '' })),
    field('Reorder point', input('reorder_point', { type: 'number', step: '0.01', value: item?.reorder_point ?? 0, class: 'num' })),
    field('Reorder quantity', input('reorder_qty', { type: 'number', step: '0.01', value: item?.reorder_qty ?? 0, class: 'num' })),
    isNew ? field('Opening quantity', input('qty_on_hand', { type: 'number', step: '0.01', value: 0, class: 'num' })) : null,
    field('Cost', input('cost', { type: 'number', step: '0.01', value: item?.cost ?? 0, class: 'num' })),
    field('Price A', input('price_a', { type: 'number', step: '0.01', value: item?.price_a ?? 0, class: 'num' })),
    field('Price B', input('price_b', { type: 'number', step: '0.01', value: item?.price_b ?? 0, class: 'num' })),
    field('Price C', input('price_c', { type: 'number', step: '0.01', value: item?.price_c ?? 0, class: 'num' })),
    field('Price D', input('price_d', { type: 'number', step: '0.01', value: item?.price_d ?? 0, class: 'num' })),
    field('Price E', input('price_e', { type: 'number', step: '0.01', value: item?.price_e ?? 0, class: 'num' })),
    field('Remarks', input('remarks', { value: item?.remarks || '' }), { span: true }),
  ]);

  modal({
    title: isNew ? 'New stock item' : `Edit ${item.code}`,
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
            await api.post('/stock', payload);
            toast(`Stock item ${payload.code} created.`, 'success');
            window.location.hash = `#/stock/${encodeURIComponent(payload.code)}`;
          } else {
            payload.version = item.version;
            await api.put(`/stock/${encodeURIComponent(item.code)}`, payload);
            toast('Saved.', 'success');
          }
          reload();
        },
      },
    ],
  });
}

function adjust(item) {
  const amount = input('qty', { type: 'number', step: '0.01', value: 0, class: 'num' });
  const reason = input('reason', { placeholder: 'Physical count, damage, correction…' });

  modal({
    title: `Adjust ${item.code}`,
    body: el('div', {}, [
      el('p', { class: 'hint' },
        [`On hand now: ${qty(item.qty_on_hand)} ${item.unit || ''}. `
         + 'Enter the change, not the new total — positive adds, negative removes. '
         + 'Every adjustment is written to the movement ledger.']),
      field('Quantity change', amount),
      field('Reason', reason),
    ]),
    actions: [
      { label: 'Cancel' },
      {
        label: 'Post adjustment',
        kind: 'primary',
        onClick: async () => {
          const result = await api.post(`/stock/${encodeURIComponent(item.code)}/adjust`, {
            qty: Number(amount.value), reason: reason.value,
          });
          toast(`${item.code} is now ${qty(result.qty_on_hand)} (${result.document}).`, 'success');
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
  const code = hash.startsWith('/stock/') ? decodeURIComponent(hash.slice(7)) : null;
  (code ? detail(container, code) : list(container)).catch(reportError);
}
