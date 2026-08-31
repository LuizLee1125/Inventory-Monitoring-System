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

/**
 * A dropdown.
 *
 * Returns a wrapper element, not the `<select>` — but one that behaves like the
 * select for everything this application does with it: `.value` reads and
 * writes through, and `change` bubbles out of the real control inside, so
 * `node.addEventListener('change', …)` still works and `readForm()` still finds
 * it by name. Callers did not have to change.
 *
 * The real `<select>` is still in there and still holds the value. What is
 * replaced is only the *popup*: a native one is drawn by the operating system,
 * which means square corners, its own font, and no animation — nothing about it
 * can be made to match the rest of the interface. This draws the list instead.
 */
export function select(name, options, value) {
  const native = el('select', {
    name,
    class: 'cselect-native',
    // The button below carries the interaction and the accessible name; the
    // select is here to hold the value, and must not be a second tab stop.
    tabindex: -1,
    'aria-hidden': 'true',
  });
  for (const option of options) {
    const [key, text] = Array.isArray(option) ? option : [option, option];
    native.append(el('option', { value: key, selected: String(key) === String(value) },
      [text]));
  }
  return dropdown(native);
}

function dropdown(native) {
  const label = el('span', { class: 'cselect-label' });
  const button = el('button', {
    type: 'button',
    class: 'cselect-btn',
    'aria-haspopup': 'listbox',
    'aria-expanded': 'false',
  }, [label, el('span', { class: 'cselect-caret', 'aria-hidden': 'true' })]);

  const wrap = el('div', { class: 'cselect' }, [native, button]);

  let menu = null;
  let active = -1;
  let typed = '';
  let typedAt = 0;

  const items = () => [...native.options];
  const paint = () => { label.textContent = native.selectedOptions[0]?.textContent ?? ''; };

  function highlight(index) {
    if (!menu) return;
    active = Math.max(0, Math.min(index, items().length - 1));
    [...menu.children].forEach((node, i) => {
      node.classList.toggle('on', i === active);
      if (i === active) node.scrollIntoView({ block: 'nearest' });
    });
  }

  function close({ focus = false } = {}) {
    if (!menu) return;
    const dying = menu;
    menu = null;
    button.setAttribute('aria-expanded', 'false');
    // Kept in the document until the exit animation finishes; `animationend`
    // may never fire under prefers-reduced-motion's 1ms, so a timer backs it up.
    dying.classList.add('closing');
    const remove = () => dying.remove();
    dying.addEventListener('animationend', remove, { once: true });
    setTimeout(remove, 300);
    window.removeEventListener('scroll', place, true);
    window.removeEventListener('resize', place);
    window.removeEventListener('hashchange', onNavigate);
    document.removeEventListener('mousedown', onOutside, true);
    if (focus) button.focus();
  }

  /**
   * Put the panel under its trigger — or above it, when there is no room
   * below. Called again on scroll and resize rather than closing on either:
   * a scroll still settling from before the menu opened would otherwise shut
   * it the instant it appeared.
   */
  function place() {
    if (!menu) return;

    // The panel lives on <body> so nothing can clip it, which means it does not
    // go away when the router clears the screen underneath it. Without this it
    // is left floating over the next screen, anchored to a trigger that no
    // longer exists.
    if (!button.isConnected) { close(); return; }

    const rect = button.getBoundingClientRect();

    // Only when the trigger itself has left the window is closing right.
    if (rect.bottom < 0 || rect.top > window.innerHeight) { close(); return; }

    const height = menu.offsetHeight;
    const above = rect.bottom + 6 + height > window.innerHeight - 8
      && rect.top - height - 6 > 8;
    menu.classList.toggle('above', above);
    Object.assign(menu.style, {
      left: `${rect.left}px`,
      top: above ? `${rect.top - height - 6}px` : `${rect.bottom + 6}px`,
      minWidth: `${rect.width}px`,
    });
  }

  const onOutside = (event) => {
    if (!menu?.contains(event.target) && !wrap.contains(event.target)) close();
  };

  // Leaving the screen closes the menu. `place()` catches the disconnected
  // trigger too, but only when something scrolls or resizes — this is the
  // signal that the screen changed.
  const onNavigate = () => close();

  function choose(index) {
    const option = items()[index];
    if (!option || option.disabled) return;
    native.selectedIndex = index;
    paint();
    native.dispatchEvent(new Event('change', { bubbles: true }));
    close({ focus: true });
  }

  function open() {
    if (menu) return;
    menu = el('div', { class: 'cselect-menu', role: 'listbox' },
      items().map((option, index) => el('button', {
        type: 'button',
        class: 'cselect-option',
        role: 'option',
        'aria-selected': String(index === native.selectedIndex),
        // mousedown, not click: the button would otherwise take focus first and
        // the outside-click handler would close the menu under the pointer.
        onMouseDown: (event) => { event.preventDefault(); choose(index); },
        onMouseEnter: () => highlight(index),
      }, [option.textContent])));

    // Fixed, and placed from the trigger's rectangle, so the panel is never
    // clipped by a scrolling modal body or a table's overflow container.
    menu.style.position = 'fixed';
    // Off-screen for the first frame: place() needs the rendered height to
    // decide whether the panel goes below or above, and measuring it in view
    // would show one frame in the wrong place.
    menu.style.top = '-9999px';
    document.body.append(menu);

    // Everything that marks the menu open happens before place(), because
    // place() may decide the trigger has scrolled out of view and close again.
    // Setting aria-expanded afterwards left the button claiming to be open
    // with nothing under it.
    button.setAttribute('aria-expanded', 'true');
    window.addEventListener('scroll', place, true);
    window.addEventListener('resize', place);
    window.addEventListener('hashchange', onNavigate);
    document.addEventListener('mousedown', onOutside, true);

    place();
    if (menu) highlight(native.selectedIndex);
  }

  button.addEventListener('click', () => (menu ? close() : open()));

  button.addEventListener('keydown', (event) => {
    const { key } = event;
    if (key === 'Escape') { close({ focus: true }); return; }
    if (key === 'Tab') { close(); return; }

    if (!menu) {
      if (key === 'ArrowDown' || key === 'ArrowUp' || key === 'Enter' || key === ' ') {
        event.preventDefault();
        open();
      }
      return;
    }

    if (key === 'ArrowDown') { event.preventDefault(); highlight(active + 1); }
    else if (key === 'ArrowUp') { event.preventDefault(); highlight(active - 1); }
    else if (key === 'Home') { event.preventDefault(); highlight(0); }
    else if (key === 'End') { event.preventDefault(); highlight(items().length - 1); }
    else if (key === 'Enter' || key === ' ') { event.preventDefault(); choose(active); }
    else if (key.length === 1) {
      // Type-ahead, the one thing a native select does that is easy to miss.
      const now = Date.now();
      typed = now - typedAt > 800 ? key : typed + key;
      typedAt = now;
      const found = items().findIndex((option) =>
        option.textContent.toLowerCase().startsWith(typed.toLowerCase()));
      if (found >= 0) highlight(found);
    }
  });

  // Options added after construction go to the real <select>, not to the
  // wrapper. `stock.js` fills its division list from a fetch that resolves
  // later, and appending an <option> to a <div> renders its text as loose
  // prose beside the control — which is exactly what happened.
  //
  // The menu is built from `native.options` each time it opens, so an option
  // added at any point simply appears in the list.
  const isOption = (node) => node instanceof HTMLOptionElement
    || node instanceof HTMLOptGroupElement;

  wrap.append = (...nodes) => {
    const [forNative, forWrap] = nodes.reduce(
      ([a, b], node) => (isOption(node) ? [[...a, node], b] : [a, [...b, node]]),
      [[], []]);
    if (forNative.length) { native.append(...forNative); paint(); }
    if (forWrap.length) Element.prototype.append.call(wrap, ...forWrap);
  };
  wrap.appendChild = (node) => {
    if (isOption(node)) { native.appendChild(node); paint(); return node; }
    return Element.prototype.appendChild.call(wrap, node);
  };
  /** HTMLSelectElement.add(), for anything that reaches for it. */
  wrap.add = (option, before) => { native.add(option, before); paint(); };

  // Forwarding is the whole reason callers can stay as they were — including
  // the ones that assign to `.value` from outside without dispatching an event,
  // and `salesReport()`, which reads the chosen option's text through
  // `.options[.selectedIndex]`. Anything a caller reaches for on a <select>
  // belongs here; the alternative is discovering it as a TypeError, or as
  // option labels printed across the toolbar.
  Object.defineProperties(wrap, {
    value: {
      get: () => native.value,
      set: (next) => { native.value = next; paint(); },
    },
    options: { get: () => native.options },
    selectedOptions: { get: () => native.selectedOptions },
    selectedIndex: {
      get: () => native.selectedIndex,
      set: (next) => { native.selectedIndex = next; paint(); },
    },
    disabled: {
      get: () => native.disabled,
      set: (next) => { native.disabled = next; button.disabled = next; },
    },
  });

  paint();
  return wrap;
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
