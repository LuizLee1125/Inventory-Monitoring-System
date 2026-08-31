// Sales returns: goods coming back, credited against the original invoice.

import { api } from '../api.js';
import {
  attachLookup, card, clear, dataTable, date, debounce, el, field, input, money,
  pager, qty, reportError, skeletonTable, statusTag, toast, today, toolbar,
} from '../ui.js';
import { can, setTitle } from '../app.js';
import { lineEditor } from './lineEditor.js';

const state = { q: '', date_from: '', date_to: '', page: 1 };

export const skeleton = (params) => (params.id ? 'detail' : 'list');

export async function render(container, params = {}) {
  const hash = window.location.hash.slice(1);
  if (hash.startsWith('/returns/new')) return editor(container, hash);
  if (params.id) return detail(container, params.id);
  return list(container);
}

async function list(container) {
  setTitle('Sales returns');

  const search = el('input', { placeholder: 'Return number, customer or invoice…', value: state.q });
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
  container.append(toolbar([
    el('div', { class: 'search' }, [search]), from, to,
    el('span', { class: 'spacer' }),
    can('return:write')
      ? el('button', { class: 'btn primary', text: '+ New return',
                       onClick: () => { window.location.hash = '#/returns/new'; } })
      : null,
  ]), host);

  async function refresh() {
    clear(host);
    host.append(skeletonTable(7, 10));
    try {
      const result = await api.get('/returns', {
        q: state.q, date_from: state.date_from, date_to: state.date_to,
        page: state.page, page_size: 50,
      });
      clear(host);
      host.append(
        dataTable([
          { key: 'sr_no', label: 'Number', class: 'mono' },
          { key: 'sr_date', label: 'Date', render: (r) => date(r.sr_date) },
          { key: 'customer_name', label: 'Customer', class: 'wrap' },
          { key: 'ref_invoice', label: 'Against invoice', class: 'mono' },
          { key: 'net_amount', label: 'Amount', align: 'right', render: (r) => money(r.net_amount) },
          { key: 'status', label: 'Status', render: (r) => statusTag(r.status) },
        ], result.items, {
          onRowClick: (row) => { window.location.hash = `#/returns/${encodeURIComponent(row.sr_no)}`; },
          footer: { customer_name: 'Total', net_amount: money(result.summary.net) },
          emptyText: 'No sales returns match these filters.',
        }),
        pager(result, (p) => { state.page = p; refresh(); }),
      );
    } catch (error) {
      clear(host);
      host.append(el('div', { class: 'empty', text: error.detail || 'Could not load returns.' }));
    }
  }

  await refresh();
}

async function detail(container, srNo) {
  setTitle(`Return ${srNo}`);
  const sr = await api.get(`/returns/${encodeURIComponent(srNo)}`);

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Back to returns', onClick: () => { window.location.hash = '#/returns'; } }),
      el('span', { class: 'spacer' }),
      el('button', { class: 'btn', text: 'Print', onClick: () => window.print() }),
    ]),

    card(`${sr.customer_code} — ${sr.customer_name}`, el('div', { class: 'form-grid' }, [
      ['Return number', sr.sr_no], ['Date', date(sr.sr_date)],
      ['Against invoice', sr.ref_invoice || 'None'],
      ['Amount', money(sr.net_amount)],
      ['Applied to the invoice', money(sr.applied_amt)],
      ['Status', sr.status],
      ['Remarks', sr.remarks],
      ['Recorded by', `${sr.created_by} · ${date(sr.created_at)}`],
    ].map(([label, value]) => el('div', { class: 'field' }, [
      el('span', { text: label }), el('div', { text: value || '—' }),
    ]))), [
      sr.ref_invoice
        ? el('a', { class: 'btn sm', href: `#/invoices/${encodeURIComponent(sr.ref_invoice)}` },
            ['Open invoice'])
        : null,
      el('a', { class: 'btn sm', href: `#/customers/${encodeURIComponent(sr.customer_code)}` },
        ['Open customer']),
    ].filter(Boolean)),

    card('Lines', dataTable([
      { key: 'line_no', label: '#' },
      { key: 'stock_code', label: 'Code', class: 'mono' },
      { key: 'description', label: 'Description', class: 'wrap' },
      { key: 'qty', label: 'Qty', align: 'right', render: (r) => qty(r.qty) },
      { key: 'unit', label: 'Unit' },
      { key: 'unit_price', label: 'Price', align: 'right', render: (r) => money(r.unit_price) },
      { key: 'line_total', label: 'Total', align: 'right', render: (r) => money(r.line_total) },
    ], sr.lines, {
      emptyText: 'This return has no stored line detail.',
      footer: { description: 'Total', line_total: money(sr.net_amount) },
    }), [], { flush: true }),
  );
}

async function editor(container, hash) {
  setTitle('New sales return');
  const query = new URLSearchParams(hash.split('?')[1] || '');

  const customerCode = input('customer_code', {
    placeholder: 'Customer code', style: 'text-transform:uppercase',
    value: query.get('customer') || '',
  });
  const customerName = el('div', { class: 'hint', text: 'No customer selected.' });
  const refInvoice = input('ref_invoice', {
    placeholder: 'Original invoice (optional)', style: 'text-transform:uppercase',
    value: query.get('invoice') || '',
  });
  const srDate = input('sr_date', { type: 'date', value: today() });
  const remarks = input('remarks', { placeholder: 'Reason for the return' });

  const totalCell = el('div', { class: 'amount', text: money(0) });
  const lines = lineEditor({
    priceField: 'price_a',
    showDiscounts: false,
    onChange: (subtotal) => { totalCell.textContent = money(subtotal); },
  });

  attachLookup(customerCode, '/customers/lookup', {
    format: (row) => row.name,
    meta: (row) => (row.balance ? money(row.balance) : ''),
    onPick: (row) => { customerName.textContent = `${row.name} — ${row.city || ''}`.trim(); },
  });

  const saveButton = el('button', { class: 'btn primary', text: 'Save return' });

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Cancel', onClick: () => { window.location.hash = '#/returns'; } }),
      el('span', { class: 'spacer' }),
      saveButton,
    ]),

    card('Customer', el('div', {}, [
      el('div', { class: 'form-grid' }, [
        field('Customer code', customerCode),
        field('Original invoice', refInvoice),
        field('Return date', srDate),
        field('Remarks', remarks),
      ]),
      customerName,
      el('p', { class: 'hint' },
        ['If an invoice is named, prices default to that invoice and the credit is '
         + 'applied to it before the customer balance.']),
    ])),

    card('Lines returned', el('div', {}, [
      lines.node,
      el('div', { class: 'totals' }, [
        el('div', {}, [el('div', { class: 'label', text: 'Credit total' }), totalCell]),
      ]),
    ])),
  );

  saveButton.addEventListener('click', async () => {
    const payload = {
      customer_code: customerCode.value.trim().toUpperCase(),
      ref_invoice: refInvoice.value.trim().toUpperCase(),
      sr_date: srDate.value,
      remarks: remarks.value.trim(),
      lines: lines.getLines(),
    };
    if (!payload.customer_code) return toast('Choose a customer first.', 'error');
    if (!payload.lines.length) return toast('Add at least one line with a quantity.', 'error');

    saveButton.disabled = true;
    try {
      const sr = await api.post('/returns', payload);
      toast(`Return ${sr.sr_no} saved.`, 'success');
      window.location.hash = `#/returns/${encodeURIComponent(sr.sr_no)}`;
    } catch (error) {
      reportError(error);
    } finally {
      saveButton.disabled = false;
    }
  });
}
