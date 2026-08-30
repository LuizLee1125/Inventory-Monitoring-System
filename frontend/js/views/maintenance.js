// Backup and database housekeeping — the Maintenance column, brought forward.

import { api } from '../api.js';
import {
  card, clear, confirmDialog, count, dataTable, dateTime, el, reportError, toast,
} from '../ui.js';
import { page, setTitle } from '../app.js';

export async function render(container) {
  setTitle('Backup & database');
  const status = await api.get('/maintenance/status');
  const db = status.database;

  const lastBackup = status.last_backup;
  const days = lastBackup
    ? Math.floor((Date.now() - new Date(lastBackup.created_at)) / 86400000)
    : null;

  container.append(
    el('p', { class: 'lede' },
      ['The old system backed up onto a rotation of floppies and needed everyone out of the '
       + 'files to rebuild indexes. Neither is true any more: the database is one file, and it '
       + 'can be copied safely while the office keeps working.']),

    el('div', { class: 'stat-grid' }, [
      stat('Database size', `${count(db.size_mb)} MB`,
        `${count(db.page_count)} pages, ${count(db.freelist_pages)} free`),
      stat('Disk free', `${count(status.disk_free_mb)} MB`,
        status.disk_free_mb < db.size_mb ? 'Too little to compact' : 'Room to back up',
        status.disk_free_mb < db.size_mb ? 'warn' : 'ok'),
      stat('Last backup', lastBackup ? `${count(lastBackup.size_mb)} MB` : 'None',
        lastBackup ? dateTime(lastBackup.created_at) : 'Take one now',
        !lastBackup || days > 6 ? 'danger' : days >= 1 ? 'warn' : 'ok'),
      stat('Signed in now', count(status.sessions_open), 'People using the system'),
    ]),

    card('Back up the database', el('div', {}, [
      el('p', { class: 'hint' },
        ['Writes a consistent copy into ', el('code', { text: 'database\\backups' }),
         `. The newest 14 are kept and older ones are removed. Copy them off this PC as well `
         + `— a backup on the same disk does not survive that disk failing.`]),
      el('div', { class: 'toolbar', style: 'margin:14px 0 0' }, [
        el('button', { class: 'btn primary', text: 'Back up now', onClick: runBackup }),
      ]),
    ])),

    card('Check the database', el('div', {}, [
      el('p', { class: 'hint' },
        ['SQLite keeps its own indexes, so there is nothing to rebuild — the successor to '
         + '"ReIndex Files" is a verification pass and a refresh of the statistics the query '
         + 'planner uses. It reads every page, so on a database this size expect it to take a '
         + 'minute or two and to slow everyone else down while it runs. Nobody has to leave '
         + 'the system, which the old ReIndex did require.']),
      el('div', { class: 'toolbar', style: 'margin:14px 0 0' }, [
        el('button', { class: 'btn', text: 'Run check', onClick: runCheck }),
        el('button', { class: 'btn', text: 'Compact', onClick: runCompact }),
      ]),
      el('p', { class: 'hint', style: 'margin-top:10px' },
        ['Compacting rewrites the whole file to reclaim free pages. It needs as much spare disk '
         + 'as the database occupies and takes a few minutes — do it out of hours.']),
    ])),

    card(`Backups (${status.backups.length})`, dataTable([
      { key: 'name', label: 'File', class: 'mono' },
      { key: 'created_at', label: 'Taken', render: (r) => dateTime(r.created_at) },
      { key: 'size_mb', label: 'Size', align: 'right', render: (r) => `${count(r.size_mb)} MB` },
    ], status.backups, {
      emptyText: 'No backups yet. Take one now.',
    }), [], { flush: true }),

    card('Rows on file', dataTable([
      { key: 'table', label: 'Table' },
      { key: 'rows', label: 'Rows', align: 'right', render: (r) => count(r.rows) },
    ], Object.entries(status.rows).map(([table, rows]) => ({ table, rows })), {}),
      [], { flush: true }),
  );
}

function stat(label, value, sub, tone = '') {
  return el('div', { class: `stat ${tone}` }, [
    el('div', { class: 'label', text: label }),
    el('div', { class: 'value', text: value }),
    sub ? el('div', { class: 'sub', text: sub }) : null,
  ]);
}

async function runBackup(event) {
  const button = event.currentTarget;
  button.disabled = true;
  button.textContent = 'Backing up…';
  try {
    const result = await api.post('/maintenance/backup', {});
    toast(`${result.name} — ${count(result.size_mb)} MB.`, 'success', 'Backed up');
    reload();
  } catch (error) {
    reportError(error);
    button.disabled = false;
    button.textContent = 'Back up now';
  }
}

async function runCheck(event) {
  const button = event.currentTarget;
  button.disabled = true;
  button.textContent = 'Checking…';
  try {
    const result = await api.post('/maintenance/check', {});
    if (result.ok) {
      toast('The database is intact and statistics are up to date.', 'success', 'All good');
    } else {
      toast(`Integrity: ${result.integrity}. Foreign key problems: `
            + `${result.foreign_key_problems}. Restore from a backup.`, 'error', 'Problems found');
    }
  } catch (error) {
    reportError(error);
  } finally {
    button.disabled = false;
    button.textContent = 'Run check';
  }
}

async function runCompact(event) {
  const sure = await confirmDialog(
    'Compact the database?',
    'The whole file is rewritten. It can take several minutes and the system will be slow '
    + 'while it runs, so do it outside working hours.',
    'Compact now');
  if (!sure) return;

  const button = event.currentTarget;
  button.disabled = true;
  button.textContent = 'Compacting…';
  try {
    const result = await api.post('/maintenance/compact', {});
    toast(`${count(result.reclaimed_mb)} MB reclaimed — now ${count(result.after_mb)} MB.`,
      'success', 'Compacted');
    reload();
  } catch (error) {
    reportError(error);
  } finally {
    button.disabled = false;
    button.textContent = 'Compact';
  }
}

function reload() {
  const container = page();
  clear(container);
  render(container).catch(reportError);
}
