// Purging of Records — item 2 on the old Maintenance menu.
//
// The DOS system purged because .DBF files grew until the machine struggled,
// so it was a chore you did to keep working. SQLite has no such limit — 2.5
// million movements sit in one file without complaint — so purging here is a
// choice, not maintenance. The screen says so, shows exactly what would go,
// and refuses to run without a backup on disk.

import { api } from '../api.js';
import {
  card, clear, count, dataTable, dateTime, el, field, input, reportError, toast,
} from '../ui.js';
import { page, setTitle } from '../app.js';

export const skeleton = 'form';

export async function render(container) {
  setTitle('Purging of records');

  const cutoff = input('before', { type: 'date', value: defaultCutoff() });
  const confirm = input('confirm', { placeholder: 'Type PURGE to confirm' });
  const preview = el('div');
  const runButton = el('button', { class: 'btn danger', text: 'Purge records', disabled: true });

  async function look() {
    runButton.disabled = true;
    clear(preview);
    if (!cutoff.value) return;

    let data;
    try {
      data = await api.get('/maintenance/purge-preview', { before: cutoff.value });
    } catch (error) {
      preview.append(el('p', { class: 'danger-text', text: error.detail || 'Could not check.' }));
      return;
    }

    const rows = Object.entries(data.scope).map(([table, n]) => ({ table, rows: n }));
    const hasBackup = Boolean(data.last_backup);

    preview.append(
      dataTable([
        { key: 'table', label: 'Would be removed from' },
        { key: 'rows', label: 'Rows', align: 'right', render: (r) => count(r.rows) },
      ], rows, {
        footer: { table: 'Total', rows: count(data.total_rows) },
      }),

      el('div', { class: 'form-grid', style: 'margin-top:18px' }, [
        fact('Kept — still unpaid', count(data.kept.unpaid_invoices) + ' invoices'),
        fact('Kept — cancelled', count(data.kept.cancelled_invoices) + ' invoices'),
        // Paid for and not yet delivered. A server that predates this figure
        // sends no key, and the row is dropped rather than reading "0 invoices"
        // — which would be a claim, and a false one.
        data.kept.invoices_owing_stock === undefined ? null
          : fact('Kept — stock still owed',
                 count(data.kept.invoices_owing_stock) + ' invoices'),
        fact('Oldest invoice on file', data.oldest_invoice || '—'),
        fact('Database size now', `${count(data.database_mb)} MB`),
      ]),

      hasBackup
        ? el('p', { class: 'hint' },
            [`Last backup: ${data.last_backup.name} (${dateTime(data.last_backup.created_at)}).`])
        : el('p', { class: 'danger-text' },
            ['There is no backup on disk. Take one from Backup & Database first — '
             + 'purging cannot be undone.']),
    );

    runButton.disabled = !hasBackup || data.total_rows === 0;
  }

  cutoff.addEventListener('change', look);

  runButton.addEventListener('click', async () => {
    if (confirm.value.trim().toUpperCase() !== 'PURGE') {
      return toast('Type PURGE in the confirmation box.', 'error');
    }
    runButton.disabled = true;
    runButton.textContent = 'Purging…';
    try {
      const result = await api.post('/maintenance/purge', {
        before: cutoff.value, confirm: 'PURGE',
      });
      toast(`${count(result.total_rows)} rows removed. ${result.note}`, 'success', 'Purged');
      confirm.value = '';
      await look();
    } catch (error) {
      reportError(error);
    } finally {
      runButton.textContent = 'Purge records';
    }
  });

  container.append(
    el('p', { class: 'lede' },
      ['The old system purged because the data files grew until the machine struggled. '
       + 'This one does not have that problem — it holds 2.5 million movements in a single '
       + 'file without difficulty — so purging is now something you choose to do, not '
       + 'something you have to. Most offices never need it.']),

    card('What would be removed', el('div', {}, [
      el('div', { class: 'form-grid', style: 'max-width:320px' }, [
        field('Remove settled records before', cutoff),
      ]),
      preview,
    ])),

    card('Run the purge', el('div', {}, [
      el('p', { class: 'hint' },
        ['Only fully paid invoices, posted collections and their movements are removed. '
         + 'Anything still owed — money or stock — and anything cancelled is always kept: '
         + 'an invoice waiting on a delivery is unfinished business even when it has been '
         + 'paid for. There is no undo other than restoring the backup.']),
      el('div', { class: 'form-grid', style: 'max-width:320px;margin-top:12px' }, [
        field('Confirmation', confirm),
      ]),
      el('div', { class: 'toolbar', style: 'margin:6px 0 0' }, [runButton]),
    ])),
  );

  await look();
}

function fact(label, value) {
  return el('div', { class: 'field' }, [
    el('span', { text: label }),
    el('div', { text: String(value) }),
  ]);
}

/** Seven years back — long enough that nothing recent is ever in scope. */
function defaultCutoff() {
  const d = new Date();
  d.setFullYear(d.getFullYear() - 7);
  return d.toISOString().slice(0, 10);
}

export function reload() {
  const container = page();
  clear(container);
  render(container).catch(reportError);
}
