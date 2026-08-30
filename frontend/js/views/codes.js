// Code Revisions — item 3 on the old Maintenance menu.
//
// Changing a stock or customer code by hand meant editing it in the master file
// and then in every detail file that referenced it, and an interruption left
// orphaned rows behind. Here it is one transaction: every table moves together
// or nothing does.

import { api } from '../api.js';
import {
  card, clear, count, dataTable, el, field, input, reportError, select, toast,
} from '../ui.js';
import { page, setTitle } from '../app.js';

const KINDS = [
  ['stock', 'Stock item'],
  ['customer', 'Customer'],
  ['supplier', 'Supplier'],
];

export async function render(container) {
  setTitle('Code revisions');

  const kind = select('kind', KINDS, 'stock');
  const oldCode = input('old_code', {
    placeholder: 'Existing code', style: 'text-transform:uppercase',
  });
  const newCode = input('new_code', {
    placeholder: 'New code', style: 'text-transform:uppercase', maxlength: 10,
  });
  const preview = el('div');
  const applyButton = el('button', { class: 'btn primary', text: 'Rename everywhere', disabled: true });

  let usage = null;

  const check = async () => {
    usage = null;
    applyButton.disabled = true;
    clear(preview);
    const code = oldCode.value.trim().toUpperCase();
    if (!code) return;

    try {
      usage = await api.get('/maintenance/code-usage', { kind: kind.value, code });
    } catch (error) {
      preview.append(el('p', { class: 'danger-text', text: error.detail || 'Not found.' }));
      return;
    }

    applyButton.disabled = false;
    preview.append(
      el('p', { class: 'hint' },
        [`${usage.code} — `, el('strong', { text: usage.name || '(no name)' }),
         `. Renaming touches ${count(usage.total_rows)} detail row(s):`]),
      dataTable([
        { key: 'table', label: 'Table' },
        { key: 'rows', label: 'Rows', align: 'right', render: (r) => count(r.rows) },
      ], usage.usage.filter((u) => u.rows > 0), {
        emptyText: 'Nothing references this code yet — only the master record changes.',
      }),
    );
  };

  kind.addEventListener('change', check);
  oldCode.addEventListener('change', check);
  oldCode.addEventListener('blur', check);

  applyButton.addEventListener('click', async () => {
    const from = oldCode.value.trim().toUpperCase();
    const to = newCode.value.trim().toUpperCase();
    if (!from || !to) return toast('Enter both codes.', 'error');
    if (from === to) return toast('The two codes are the same.', 'error');

    applyButton.disabled = true;
    try {
      const result = await api.post('/maintenance/code-revision', {
        kind: kind.value, old_code: from, new_code: to,
      });
      toast(`${result.old_code} is now ${result.new_code} — `
            + `${count(result.total_rows)} row(s) updated.`, 'success', 'Renamed');
      oldCode.value = '';
      newCode.value = '';
      clear(preview);
    } catch (error) {
      reportError(error);
    } finally {
      applyButton.disabled = false;
    }
  });

  container.append(
    el('p', { class: 'lede' },
      ['A code appears in the master file and in every invoice, purchase, return and '
       + 'movement that ever used it. This changes all of them at once, so nothing is '
       + 'left pointing at a code that no longer exists.']),

    card('Rename a code', el('div', {}, [
      el('div', { class: 'form-grid' }, [
        field('What kind', kind),
        field('Existing code', oldCode),
        field('New code', newCode),
      ]),
      preview,
      el('div', { class: 'toolbar', style: 'margin:16px 0 0' }, [applyButton]),
    ])),

    card('Before you do this', el('ul', { class: 'plain-list' }, [
      el('li', { text: 'Take a backup first if the code is used widely.' }),
      el('li', { text: 'Anything already printed keeps the old code — this changes the '
                       + 'records, not the paper.' }),
      el('li', { text: 'The new code must not already belong to another record.' }),
    ])),
  );

  await check();
}

export function reload() {
  const container = page();
  clear(container);
  render(container).catch(reportError);
}
