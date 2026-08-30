// DOM helpers, formatting, tables, modals, toasts and the type-ahead used by
// the document editors.

import { api } from './api.js';

/* ------------------------------------------------------------- elements -- */

export function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (value === null || value === undefined || value === false) continue;
    if (key === 'class') node.className = value;
    else if (key === 'html') node.innerHTML = value;
    else if (key === 'text') node.textContent = value;
    else if (key === 'dataset') Object.assign(node.dataset, value);
    else if (key.startsWith('on')) node.addEventListener(key.slice(2).toLowerCase(), value);
    else if (value === true) node.setAttribute(key, '');
    else node.setAttribute(key, value);
  }
  for (const child of [].concat(children)) {
    if (child === null || child === undefined || child === false) continue;
    node.append(child.nodeType ? child : document.createTextNode(String(child)));
  }
  return node;
}

export const $ = (selector, scope = document) => scope.querySelector(selector);
export const clear = (node) => { while (node.firstChild) node.firstChild.remove(); };

/* ----------------------------------------------------------- formatting -- */

const moneyFormat = new Intl.NumberFormat('en-PH', {
  minimumFractionDigits: 2, maximumFractionDigits: 2,
});
const intFormat = new Intl.NumberFormat('en-PH');

export const money = (value) => moneyFormat.format(Number(value || 0));
export const count = (value) => intFormat.format(Number(value || 0));

export function qty(value) {
  const n = Number(value || 0);
  return Number.isInteger(n) ? intFormat.format(n) : moneyFormat.format(n);
}

export function date(value) {
  if (!value) return '';
  const text = String(value).slice(0, 10);
  const parsed = new Date(`${text}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) return text;
  return parsed.toLocaleDateString(undefined,
    { year: 'numeric', month: 'short', day: '2-digit' });
}

export function dateTime(value) {
  if (!value) return '';
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? value : parsed.toLocaleString();
}

export const today = () => new Date().toISOString().slice(0, 10);

export function monthsAgo(n) {
  const d = new Date();
  d.setMonth(d.getMonth() - n);
  return d.toISOString().slice(0, 10);
}

export function statusTag(status) {
  const key = String(status || '').toLowerCase();
  return el('span', { class: `tag ${key || 'neutral'}`, text: status || '-' });
}

/* --------------------------------------------------------------- toasts -- */

export function toast(message, kind = 'info', title = '') {
  const node = el('div', { class: `toast ${kind}` }, [
    title ? el('b', { text: title }) : null,
    message,
  ]);
  $('#toasts').append(node);
  setTimeout(() => {
    node.style.transition = 'opacity .25s';
    node.style.opacity = '0';
    setTimeout(() => node.remove(), 250);
  }, kind === 'error' ? 7000 : 3800);
}

export function reportError(error) {
  if (error?.isConflict) {
    toast(error.detail, 'warn', 'Saved by someone else');
  } else {
    toast(error?.detail || error?.message || 'Something went wrong.', 'error');
  }
  console.error(error);
}

/* --------------------------------------------------------------- modals -- */

export function modal({ title, body, actions = [], wide = false, onClose }) {
  const back = el('div', { class: 'modal-back' });
  const box = el('div', { class: `modal${wide ? ' wide' : ''}` });

  const close = () => { back.remove(); document.removeEventListener('keydown', onKey); onClose?.(); };
  const onKey = (event) => { if (event.key === 'Escape') close(); };

  box.append(
    el('div', { class: 'modal-head' }, [
      el('h3', { text: title }),
      el('button', { class: 'btn ghost sm', text: '✕', onClick: close }),
    ]),
    el('div', { class: 'modal-body' }, [body]),
  );

  if (actions.length) {
    box.append(el('div', { class: 'modal-foot' }, actions.map((action) =>
      el('button', {
        class: `btn ${action.kind || ''}`,
        text: action.label,
        onClick: async (event) => {
          const button = event.currentTarget;
          button.disabled = true;
          try {
            const keep = await action.onClick?.(close);
            if (keep !== 'keep') close();
          } catch (error) {
            reportError(error);
          } finally {
            button.disabled = false;
          }
        },
      }))));
  }

  back.append(box);
  back.addEventListener('mousedown', (event) => { if (event.target === back) close(); });
  document.addEventListener('keydown', onKey);
  $('#modal-root').append(back);
  setTimeout(() => box.querySelector('input, select, textarea')?.focus(), 40);
  return { close, box };
}

export function confirmDialog(title, message, confirmLabel = 'Confirm') {
  return new Promise((resolve) => {
    modal({
      title,
      body: el('p', { class: 'hint', text: message }),
      actions: [
        { label: 'Cancel', onClick: () => resolve(false) },
        { label: confirmLabel, kind: 'primary', onClick: () => resolve(true) },
      ],
      onClose: () => resolve(false),
    });
  });
}

export function promptDialog(title, label, { value = '', placeholder = '' } = {}) {
  return new Promise((resolve) => {
    const input = el('input', { value, placeholder });
    modal({
      title,
      body: el('label', { class: 'field' }, [el('span', { text: label }), input]),
      actions: [
        { label: 'Cancel', onClick: () => resolve(null) },
        { label: 'OK', kind: 'primary', onClick: () => resolve(input.value.trim()) },
      ],
      onClose: () => resolve(null),
    });
  });
}

/* --------------------------------------------------------------- fields -- */

export function field(label, input, { span = false } = {}) {
  return el('label', { class: `field${span ? ' span2' : ''}` },
    [el('span', { text: label }), input]);
}

export function input(name, attrs = {}) {
  return el('input', { name, ...attrs });
}

export function select(name, options, value) {
  const node = el('select', { name });
  for (const option of options) {
    const [key, text] = Array.isArray(option) ? option : [option, option];
    node.append(el('option', { value: key, selected: String(key) === String(value) },
      [text]));
  }
  return node;
}

export function readForm(scope) {
  const data = {};
  scope.querySelectorAll('[name]').forEach((node) => {
    if (node.type === 'checkbox') data[node.name] = node.checked;
    else if (node.type === 'number') data[node.name] = node.value === '' ? 0 : Number(node.value);
    else data[node.name] = node.value;
  });
  return data;
}

/* --------------------------------------------------------------- tables -- */

/**
 * columns: [{ key, label, class, align, render, sort }]
 */
export function dataTable(columns, rows, options = {}) {
  const { onRowClick, footer, sort, direction, onSort, emptyText = 'Nothing to show.' } = options;

  if (!rows.length) return el('div', { class: 'empty', text: emptyText });

  const head = el('tr', {}, columns.map((column) => {
    const sortable = Boolean(column.sort && onSort);
    const active = sortable && sort === column.sort;
    return el('th', {
      class: [column.align === 'right' ? 'num' : '', sortable ? 'sortable' : ''].join(' ').trim(),
      onClick: sortable ? () => onSort(column.sort,
        active && direction === 'asc' ? 'desc' : 'asc') : null,
    }, [column.label + (active ? (direction === 'asc' ? ' ↑' : ' ↓') : '')]);
  }));

  const body = el('tbody', {}, rows.map((row) => {
    const tr = el('tr', { class: onRowClick ? 'clickable' : '' }, columns.map((column) => {
      const content = column.render ? column.render(row) : row[column.key];
      const classes = [column.align === 'right' ? 'num' : '', column.class || ''].join(' ').trim();
      return el('td', { class: classes },
        [content === null || content === undefined ? '' : content]);
    }));
    if (onRowClick) tr.addEventListener('click', () => onRowClick(row));
    return tr;
  }));

  const table = el('table', { class: 'grid' }, [el('thead', {}, [head]), body]);
  if (footer) {
    table.append(el('tfoot', {}, [el('tr', {}, columns.map((column) => {
      const value = footer[column.key];
      return el('td', { class: column.align === 'right' ? 'num' : '' },
        [value === undefined ? '' : value]);
    }))]));
  }
  return el('div', { class: 'table-wrap' }, [table]);
}

export function pager(result, onPage) {
  const { page, pages, total, page_size: size } = result;
  const from = total === 0 ? 0 : (page - 1) * size + 1;
  const to = Math.min(page * size, total);
  return el('div', { class: 'pager' }, [
    el('span', { text: `${count(from)}–${count(to)} of ${count(total)}` }),
    el('span', { class: 'spacer' }),
    el('button', {
      class: 'btn sm', text: '‹ Previous', disabled: page <= 1,
      onClick: () => onPage(page - 1),
    }),
    el('span', { text: `Page ${page} of ${pages}` }),
    el('button', {
      class: 'btn sm', text: 'Next ›', disabled: page >= pages,
      onClick: () => onPage(page + 1),
    }),
  ]);
}

/* ----------------------------------------------------------- type-ahead -- */

export function debounce(fn, wait = 220) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), wait);
  };
}

/**
 * Attach a lookup dropdown to a text input. `endpoint` must accept ?q= and
 * return a list of records. Replaces the DOS habit of pressing Enter on a
 * blank field to browse the master file.
 */
export function attachLookup(inputNode, endpoint, {
  format = (row) => row.name,
  meta = () => '',
  onPick,
} = {}) {
  let box = null;
  let items = [];
  let index = -1;

  const close = () => { box?.remove(); box = null; items = []; index = -1; };

  const open = (rows) => {
    close();
    if (!rows.length) return;
    items = rows;
    box = el('div', { class: 'suggest' }, rows.map((row, i) =>
      el('div', {
        onMouseDown: (event) => { event.preventDefault(); pick(i); },
      }, [
        el('span', { class: 'code', text: row.code }),
        el('span', { text: format(row) }),
        el('span', { class: 'meta', text: meta(row) }),
      ])));
    const rect = inputNode.getBoundingClientRect();
    Object.assign(box.style, {
      position: 'fixed',
      left: `${rect.left}px`,
      top: `${rect.bottom + 2}px`,
      minWidth: `${Math.max(rect.width, 320)}px`,
    });
    document.body.append(box);
  };

  const pick = (i) => {
    const row = items[i];
    if (!row) return;
    inputNode.value = row.code;
    close();
    onPick?.(row);
  };

  const search = debounce(async (term) => {
    try {
      open(await api.get(endpoint, { q: term, limit: 15 }));
    } catch { close(); }
  });

  inputNode.addEventListener('input', () => search(inputNode.value.trim()));
  inputNode.addEventListener('focus', () => search(inputNode.value.trim()));
  inputNode.addEventListener('blur', () => setTimeout(close, 150));
  inputNode.addEventListener('keydown', (event) => {
    if (!box) return;
    const options = [...box.children];
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      options[index]?.classList.remove('on');
      index = event.key === 'ArrowDown'
        ? Math.min(index + 1, options.length - 1)
        : Math.max(index - 1, 0);
      options[index]?.classList.add('on');
      options[index]?.scrollIntoView({ block: 'nearest' });
    } else if (event.key === 'Enter') {
      if (index >= 0) { event.preventDefault(); pick(index); }
    } else if (event.key === 'Escape') {
      close();
    }
  });

  return { close };
}

/* --------------------------------------------------------------- layout -- */

export function card(title, bodyNode, actions = [], { flush = false } = {}) {
  const node = el('div', { class: 'card' });
  if (title || actions.length) {
    node.append(el('div', { class: 'card-head' },
      [el('h3', { text: title || '' }), ...actions]));
  }
  node.append(el('div', { class: `card-body${flush ? ' flush' : ''}` }, [bodyNode]));
  return node;
}

export function stat(label, value, sub = '', kind = '') {
  return el('div', { class: `stat ${kind}` }, [
    el('div', { class: 'label', text: label }),
    el('div', { class: 'value', text: value }),
    sub ? el('div', { class: 'sub', text: sub }) : null,
  ]);
}

export function toolbar(children) {
  return el('div', { class: 'toolbar' }, children);
}
