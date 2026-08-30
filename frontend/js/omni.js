// Top-bar search: one box across stock, customers and invoices.
//
// The DOS system had a lookup field on every screen and you had to be on the
// right screen first. This asks all three files at once and takes you to the
// record, so finding "that Glyden invoice" no longer starts with choosing a
// menu.

import { api } from './api.js';
import { $, count, debounce, el, money } from './ui.js';
import { can } from './app.js';

const MIN_CHARS = 2;

let hits = [];
let cursor = -1;
let wired = false;

export function setupSearch() {
  // showShell() runs again after every sign-in; the listeners are bound once.
  if (wired) return;
  wired = true;

  const input = $('#omni-input');
  const panel = $('#omni-results');

  const close = () => {
    panel.hidden = true;
    panel.replaceChildren();
    hits = [];
    cursor = -1;
  };

  const open = (rows, term) => {
    hits = rows;
    cursor = -1;
    panel.replaceChildren();

    if (!rows.length) {
      panel.append(el('div', { class: 'omni-empty', text: `Nothing matches “${term}”.` }));
      panel.hidden = false;
      return;
    }

    let group = null;
    rows.forEach((hit, index) => {
      if (hit.group !== group) {
        group = hit.group;
        panel.append(el('div', { class: 'omni-group', text: group }));
      }
      panel.append(el('button', {
        class: 'omni-hit',
        type: 'button',
        dataset: { index },
        onMouseDown: (event) => { event.preventDefault(); go(index); },
      }, [
        el('span', { class: 'code', text: hit.code }),
        el('span', { class: 'name', text: hit.name }),
        el('span', { class: 'meta', text: hit.meta || '' }),
      ]));
    });
    panel.hidden = false;
  };

  const go = (index) => {
    const hit = hits[index];
    if (!hit) return;
    input.value = '';
    input.blur();
    close();
    window.location.hash = `#${hit.path}`;
  };

  const highlight = () => {
    panel.querySelectorAll('.omni-hit').forEach((node, i) => {
      node.classList.toggle('on', i === cursor);
      if (i === cursor) node.scrollIntoView({ block: 'nearest' });
    });
  };

  const search = debounce(async () => {
    const term = input.value.trim();
    if (term.length < MIN_CHARS) return close();
    try {
      open(await lookup(term), term);
    } catch {
      close();
    }
  }, 200);

  input.addEventListener('input', search);
  input.addEventListener('focus', () => { if (input.value.trim().length >= MIN_CHARS) search(); });
  input.addEventListener('blur', () => setTimeout(close, 120));

  input.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') { input.value = ''; close(); input.blur(); return; }
    if (panel.hidden || !hits.length) return;
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      cursor = Math.min(cursor + 1, hits.length - 1);
      highlight();
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      cursor = Math.max(cursor - 1, 0);
      highlight();
    } else if (event.key === 'Enter') {
      event.preventDefault();
      go(cursor === -1 ? 0 : cursor);
    }
  });

  // Ctrl+K from anywhere, the shortcut people already expect.
  document.addEventListener('keydown', (event) => {
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
      event.preventDefault();
      input.focus();
      input.select();
    }
  });
}

/** Ask the three files in parallel and flatten the answers. */
async function lookup(term) {
  const jobs = [];

  if (can('stock:read')) {
    jobs.push(api.get('/stock/lookup', { q: term, limit: 5 }).then((rows) => rows.map((r) => ({
      group: 'Stock', code: r.code, name: r.name,
      meta: `${count(r.qty_on_hand)} ${r.unit || ''}`.trim(),
      path: `/stock/${encodeURIComponent(r.code)}`,
    }))));
  }
  if (can('customer:read')) {
    jobs.push(api.get('/customers/lookup', { q: term, limit: 5 }).then((rows) => rows.map((r) => ({
      group: 'Customers', code: r.code, name: r.name,
      meta: r.balance ? money(r.balance) : '',
      path: `/customers/${encodeURIComponent(r.code)}`,
    }))));
  }
  if (can('invoice:read')) {
    jobs.push(api.get('/invoices', { q: term, page_size: 5 }).then((res) => res.items.map((r) => ({
      group: 'Invoices', code: r.inv_no, name: r.customer_name,
      meta: money(r.net_amount),
      path: `/invoices/${encodeURIComponent(r.inv_no)}`,
    }))));
  }

  const groups = await Promise.all(jobs.map((job) => job.catch(() => [])));
  return groups.flat();
}
