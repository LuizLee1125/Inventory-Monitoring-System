// Print Sales Invoice — item A of the Sales Order menu.
//
// The DOS original (SIFYLP) opened on a blank Invoice No. field: you typed a
// number, the record came up, and it went to the dot-matrix. The finder here
// is the same idea with the file browsable instead of guessed at, and what
// prints is an invoice document rather than a screenshot of a screen — the
// detail page's Print button used to send its stat boxes and its "Open
// customer" link to the printer.

import { api } from '../api.js';
import { clear, date, debounce, el, money, qty, toolbar } from '../ui.js';
import { session, setTitle } from '../app.js';

export async function render(container, params = {}) {
  return params.id ? document_(container, params.id) : finder(container);
}

/* --------------------------------------------------------------- finder -- */

async function finder(container) {
  setTitle('Print Sales Invoice');

  // One box, because the API's `q` already matches a number or a customer, and
  // the DOS habit of pressing Enter on the field to browse is preserved: the
  // list below is the file, filtered as you type.
  const search = el('input', {
    placeholder: 'Invoice number or customer…', autofocus: true,
  });
  let top = null;

  const open = (invNo) => {
    if (invNo) window.location.hash = `#/invoices/print/${encodeURIComponent(invNo)}`;
  };
  search.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') { event.preventDefault(); open(top); }
  });

  const host = el('div', { class: 'card' });

  container.append(
    toolbar([
      el('div', { class: 'search' }, [search]),
      el('button', { class: 'btn primary', text: 'Open', onClick: () => open(top) }),
    ]),
    el('p', { class: 'hint',
              text: 'Pick an invoice to see it as it will print. Enter opens the first one.' }),
    host,
  );

  const refresh = async () => {
    clear(host);
    host.append(el('div', { class: 'empty', text: 'Loading…' }));
    try {
      const result = await api.get('/invoices', {
        q: search.value.trim(), sort: 'date', direction: 'desc', page_size: 25,
      });
      clear(host);
      top = result.items[0]?.inv_no || null;
      if (!result.items.length) {
        host.append(el('div', { class: 'empty', text: 'No invoices match that.' }));
        return;
      }
      host.append(el('ul', { class: 'home-list' }, result.items.map((row) =>
        el('li', {}, [el('a', {
          class: 'home-row',
          href: `#/invoices/print/${encodeURIComponent(row.inv_no)}`,
        }, [
          el('span', { class: 'r-code', text: row.inv_no }),
          el('span', { class: 'r-name', text: `${date(row.inv_date)} · ${row.customer_name}` }),
          el('span', { class: 'r-value', text: money(row.net_amount) }),
        ])]))));
    } catch (error) {
      clear(host);
      host.append(el('div', { class: 'empty', text: error.detail || 'Could not load invoices.' }));
    }
  };

  search.addEventListener('input', debounce(refresh));
  await refresh();
  search.focus();
}

/* ------------------------------------------------------------- document -- */

async function document_(container, invNo) {
  setTitle(`Print ${invNo}`);
  const invoice = await api.get(`/invoices/${encodeURIComponent(invNo)}/print`);
  const customer = invoice.customer || {};
  const discounts = [invoice.disc1, invoice.disc2, invoice.disc3].filter(Boolean);

  container.append(
    toolbar([
      el('button', { class: 'btn', text: '‹ Another invoice',
                     onClick: () => { window.location.hash = '#/invoices/print'; } }),
      el('a', { class: 'btn', href: `#/invoices/${encodeURIComponent(invoice.inv_no)}`,
                text: 'Invoice detail' }),
      el('span', { class: 'spacer' }),
      el('button', { class: 'btn primary', text: 'Print', onClick: () => window.print() }),
    ]),

    el('div', { class: `print-doc${invoice.status === 'CANCELLED' ? ' cancelled' : ''}` }, [
      el('header', { class: 'doc-head' }, [
        el('div', {}, [
          el('h1', { text: session.meta?.company || 'Marina Trading' }),
          el('p', { text: 'Sales Invoice' }),
        ]),
        el('table', { class: 'doc-meta' }, [el('tbody', {}, [
          metaRow('Invoice no.', invoice.inv_no),
          metaRow('Date', date(invoice.inv_date)),
          metaRow('Terms', invoice.terms_days
            ? `${invoice.terms_days} days` : invoice.terms_text || 'Cash'),
          metaRow('Due', date(invoice.due_date)),
        ])]),
      ]),

      el('div', { class: 'doc-parties' }, [
        party('Sold to', [
          customer.name || invoice.customer_name,
          customer.address || invoice.address,
          customer.city || invoice.city,
          customer.tin ? `TIN ${customer.tin}` : '',
          customer.business_style,
        ]),
        party('Reference', [
          `Customer code ${invoice.customer_code}`,
          invoice.salesman ? `Salesman ${invoice.salesman}` : '',
          invoice.price_cat ? `Price tier ${invoice.price_cat}` : '',
          invoice.remarks,
        ]),
      ]),

      el('table', { class: 'doc-lines' }, [
        el('thead', {}, [el('tr', {}, [
          el('th', { class: 'c-qty', text: 'Qty' }),
          el('th', { text: 'Unit' }),
          el('th', { text: 'Code' }),
          el('th', { text: 'Description' }),
          el('th', { class: 'c-num', text: 'Price' }),
          el('th', { class: 'c-num', text: 'Amount' }),
        ])]),
        el('tbody', {}, invoice.lines.length
          ? invoice.lines.map((line) => el('tr', {}, [
            el('td', { class: 'c-qty', text: qty(line.qty) }),
            el('td', { text: line.unit || '' }),
            el('td', { class: 'mono', text: line.stock_code }),
            el('td', { text: line.description || '' }),
            el('td', { class: 'c-num', text: money(line.unit_price) }),
            el('td', { class: 'c-num', text: money(line.line_total) }),
          ]))
          : [el('tr', {}, [el('td', { colspan: '6', class: 'doc-empty',
                                      text: 'No stored line detail for this invoice.' })])]),
      ]),

      el('div', { class: 'doc-foot' }, [
        el('div', { class: 'doc-words' }, [
          el('span', { class: 'label', text: 'Amount in words' }),
          el('strong', { text: pesosInWords(invoice.net_amount) }),
        ]),
        el('table', { class: 'doc-totals' }, [el('tbody', {}, [
          totalRow('Gross', money(invoice.gross)),
          discounts.length
            ? totalRow(`Less discount ${discounts.join('/')}%`, money(invoice.discount_amt))
            : null,
          invoice.adjustment ? totalRow('Adjustment', money(invoice.adjustment)) : null,
          totalRow('Net amount', money(invoice.net_amount), 'net'),
          invoice.paid_amount ? totalRow('Paid', money(invoice.paid_amount)) : null,
          invoice.paid_amount ? totalRow('Balance', money(invoice.balance)) : null,
        ].filter(Boolean))]),
      ]),

      el('div', { class: 'doc-signs' }, [
        sign('Prepared by', invoice.created_by),
        sign('Checked by', ''),
        sign('Received the goods in good order', ''),
      ]),

      el('p', { class: 'doc-note' }, [
        invoice.status === 'CANCELLED'
          ? 'This invoice has been cancelled and is not a demand for payment.'
          : 'Please examine the goods before signing. Claims are not honoured afterwards.',
      ]),
    ]),
  );
}

function metaRow(label, value) {
  return el('tr', {}, [el('th', { text: label }), el('td', { text: value || '—' })]);
}

function totalRow(label, value, kind = '') {
  return el('tr', { class: kind }, [el('th', { text: label }), el('td', { text: value })]);
}

function party(title, lines) {
  return el('div', { class: 'doc-party' }, [
    el('span', { class: 'label', text: title }),
    ...lines.filter(Boolean).map((line, index) => el(index ? 'span' : 'strong', { text: line })),
  ]);
}

function sign(label, name) {
  return el('div', { class: 'doc-sign' }, [
    el('span', { class: 'rule', text: name || '' }),
    el('span', { class: 'label', text: label }),
  ]);
}

/* ------------------------------------------------------- amount in words -- */

const ONES = ['', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
  'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen',
  'eighteen', 'nineteen'];
const TENS = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty',
  'ninety'];
const SCALES = [[1e9, 'billion'], [1e6, 'million'], [1e3, 'thousand'], [100, 'hundred']];

function words(n) {
  if (n < 20) return ONES[n];
  if (n < 100) return (TENS[Math.floor(n / 10)] + (n % 10 ? `-${ONES[n % 10]}` : ''));
  for (const [size, name] of SCALES) {
    if (n >= size) {
      const rest = n % size;
      return `${words(Math.floor(n / size))} ${name}${rest ? ` ${words(rest)}` : ''}`;
    }
  }
  return '';
}

// Invoices are signed for, so the total is spelled out as well as figured —
// the same line the DOS forms carried above the signature.
export function pesosInWords(amount) {
  const value = Math.round(Number(amount || 0) * 100) / 100;
  const pesos = Math.floor(value);
  const centavos = Math.round((value - pesos) * 100);
  const main = pesos ? words(pesos) : 'zero';
  const tail = centavos ? ` and ${words(centavos)} centavos` : '';
  return `${main}${tail} pesos only`.replace(/^./, (c) => c.toUpperCase());
}
