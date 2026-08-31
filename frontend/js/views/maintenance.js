// Backup and database housekeeping — the Maintenance column, brought forward.

import { api } from '../api.js';
import {
  card, clear, confirmDialog, count, dataTable, dateTime, el, field, input, modal,
  reportError, toast,
} from '../ui.js';
import { page, setTitle } from '../app.js';

// Four figures across the top, then cards — the router draws that shape while
// the status call is in flight.
export const skeleton = 'stats';

export async function render(container) {
  setTitle('Backup & database');
  const status = await api.get('/maintenance/status');
  const db = status.database;

  const lastBackup = status.last_backup;
  const days = lastBackup
    ? Math.floor((Date.now() - new Date(lastBackup.created_at)) / 86400000)
    : null;

  // A workstation can hold this page open for days, so it is routinely a
  // version ahead of or behind the server it is talking to — and a server that
  // predates the backup schedule sends no `backup_policy` at all. This is the
  // screen you open when something is wrong with the system, so a missing field
  // has to degrade into saying less, never into an error where the page was.
  const policy = status.backup_policy ?? null;
  const totalMb = policy?.total_mb
    ?? status.backups.reduce((sum, row) => sum + row.size_mb, 0);

  container.append(
    el('p', { class: 'lede' },
      ['The old system backed up onto a Monday-to-Saturday rotation of floppies and needed '
       + 'everyone out of the files to rebuild indexes. Neither is true any more: the database '
       + 'is one file, it is copied safely while the office keeps working, and the rotation '
       + 'happens on its own.']),

    el('div', { class: 'stat-grid' }, [
      stat('Database size', `${count(db.size_mb)} MB`,
        `${count(db.page_count)} pages, ${count(db.freelist_pages)} free`),
      stat('Disk free', `${count(status.disk_free_mb)} MB`,
        status.disk_free_mb < db.size_mb ? 'Too little to compact' : 'Room to back up',
        status.disk_free_mb < db.size_mb ? 'warn' : 'ok'),
      // With a schedule running, anything older than a couple of days means the
      // schedule itself has stopped — which is worth shouting about sooner than
      // it would be on a system where every backup is taken by hand.
      stat('Last backup', lastBackup ? `${count(lastBackup.size_mb)} MB` : 'None',
        lastBackup ? dateTime(lastBackup.created_at) : 'Take one now',
        backupTone(days, policy)),
      stat('Signed in now', count(status.sessions_open), 'People using the system'),
    ]),

    card('Back up the database', el('div', {}, [
      // Out of the paragraph and into a banner: it is the reason half this card
      // is inert, and a sentence in the middle of body text was read as prose
      // rather than as an instruction.
      policy ? null : el('p', { class: 'notice warn' }, [
        el('span', { class: 'ico', 'aria-hidden': 'true' }),
        el('span', {}, [
          el('strong', { text: 'The server is running an older version than this page.' }),
          ' It has not reported its backup policy, so the retention choice below '
          + 'is switched off and backups are still being written in the old format. '
          + 'Restart the server, then reload this page.',
        ]),
      ]),

      el('p', { class: 'hint' }, [
        policy && policy.every_hours
          ? `Taken automatically every ${policy.every_hours === 24 ? 'day' : `${policy.every_hours} hours`} `
            + `while the server is running, and kept for ${policy.keep_days} days. `
          : policy
            ? 'Automatic backups are switched off, so the only backups are the ones taken here. '
            : '',
        'Each one is a zip holding the whole database. ',
        policy
          ? `The ${policy.keep_min} most recent are always kept whatever their age, `
            + 'so a spell away from the office cannot empty the folder.'
          : '',
      ]),

      // The person reading this is usually not sitting at the server, so the
      // folder is only half the answer — Download is the other half.
      policy?.folder
        ? el('p', { class: 'hint backup-where' }, [
          el('span', { class: 'ico', 'aria-hidden': 'true' }),
          el('span', {}, ['On the server, in ', el('code', { text: policy.folder }),
            '. Not at that PC? ', el('strong', { text: 'Download' }),
            ' any backup below and it comes to this one.']),
        ])
        : null,
      el('p', { class: 'hint', style: 'margin-top:8px' },
        [el('strong', { text: 'Keep a copy somewhere else as well.' }),
         ' A backup that only exists on the server does not survive that PC failing —'
         + ' download one now and then, and put it on a memory stick or another machine.']),
      el('div', { class: 'toolbar', style: 'margin:14px 0 0' }, [
        el('button', { class: 'btn primary', text: 'Back up now', onClick: runBackup }),
        el('span', { class: 'spacer' }),
        policy?.next_due
          ? el('span', { class: 'hint', text: `Next automatic backup ${dateTime(policy.next_due)}` })
          : null,
      ]),

      // A backup taken by hand was taken for a reason — usually just before
      // something risky — so it gets its own window rather than being swept up
      // by the daily rotation. Always drawn, even against a server too old to
      // answer: a control that vanishes leaves somebody hunting for a setting
      // the documentation says exists.
      el('div', { class: 'set-row', style: 'padding-bottom:0' }, [
        el('div', { class: 'set-label' }, [
          el('strong', { text: 'Keep backups taken by hand for' }),
          el('span', { text: policy
            ? `The daily automatic ones keep to their own ${policy.keep_days}-day rotation.`
            : 'Restart the server to change this.' }),
        ]),
        el('div', { class: 'set-control' }, [retentionPicker(policy)]),
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

    card(`Backups (${status.backups.length}, ${count(totalMb)} MB)`,
      backupList(status.backups), [], { flush: true }),

    card('Rows on file', dataTable([
      { key: 'table', label: 'Table' },
      { key: 'rows', label: 'Rows', align: 'right', render: (r) => count(r.rows) },
    ], Object.entries(status.rows).map(([table, rows]) => ({ table, rows })), {}),
      [], { flush: true }),
  );
}

// What the screen offers when the server has not said. The server is still the
// authority — it validates the choice — but the control can be drawn without it.
const MANUAL_CHOICES = [7, 14];

/** 7 days or 14, as a segmented control matching the appearance picker. */
function retentionPicker(policy) {
  const choices = policy?.manual_choices ?? MANUAL_CHOICES;
  const current = policy?.manual_keep_days ?? null;
  const buttons = new Map();

  const choose = async (days) => {
    if (days === policy?.manual_keep_days) return;
    for (const node of buttons.values()) node.disabled = true;
    try {
      const result = await api.post('/maintenance/retention', { manual_keep_days: days });
      policy.manual_keep_days = result.manual_keep_days;
      for (const [value, node] of buttons) {
        node.setAttribute('aria-pressed', String(value === result.manual_keep_days));
      }
      const swept = result.removed.length
        ? ` ${result.removed.length} older ${result.removed.length === 1 ? 'copy' : 'copies'} removed.`
        : '';
      toast(`Backups taken by hand are kept ${days} days.${swept}`, 'success');
      if (result.removed.length) reload();
    } catch (error) {
      reportError(error);
    } finally {
      for (const node of buttons.values()) node.disabled = false;
    }
  };

  return el('div', {
    class: 'segmented', role: 'group', 'aria-label': 'Manual backup retention',
  }, choices.map((days) => {
    const button = el('button', {
      class: 'segment',
      type: 'button',
      'aria-pressed': String(days === current),
      // Visible but inert against a server that cannot store the answer, with
      // the reason on the control itself rather than only in the paragraph.
      disabled: !policy,
      title: policy ? '' : 'The server is running an older version — restart it to change this.',
      onClick: () => choose(days),
    }, [`${days} days`]);
    buttons.set(days, button);
    return button;
  }));
}

/* -------------------------------------------------------------- restore -- */

async function askRestore(row) {
  let preview;
  try {
    preview = await api.get('/maintenance/restore-preview', { name: row.name });
  } catch (error) {
    return reportError(error);
  }

  const confirm = input('confirm', { placeholder: 'RESTORE', autocomplete: 'off',
                                     style: 'text-transform:uppercase' });

  // What is in the backup against what is in the database now, side by side:
  // the only question that matters is what changes if this goes ahead.
  const comparison = dataTable([
    { key: 'table', label: '' },
    { key: 'now', label: 'In the database now', align: 'right',
      render: (r) => count(r.now) },
    { key: 'after', label: 'After restoring', align: 'right',
      render: (r) => el('strong', { text: count(r.after) }) },
  ], Object.keys(preview.backup.rows).map((table) => ({
    table, now: preview.current[table], after: preview.backup.rows[table],
  })), {});

  modal({
    title: `Restore ${row.name}?`,
    wide: true,
    body: el('div', {}, [
      el('p', { class: 'hint' }, [
        'This replaces ', el('strong', { text: 'everything' }),
        ` in the database with the contents of this backup, taken `,
        el('strong', { text: dateTime(preview.backup.taken_at) }), '. ',
        'Anything entered since then is gone.',
      ]),
      comparison,
      el('p', { class: 'hint', style: 'margin-top:14px' }, [
        el('strong', { text: 'A copy of the current database is saved first' }),
        ', so this can itself be undone by restoring that copy.',
      ]),
      el('p', { class: 'hint' },
        ['Everyone is signed out, including you — the accounts and sessions come '
         + 'from the backup too. Sign in again afterwards.']),
      field('Type RESTORE to confirm', confirm),
    ]),
    actions: [
      { label: 'Cancel' },
      {
        label: 'Restore now',
        kind: 'danger',
        onClick: async () => {
          const result = await api.post('/maintenance/restore', {
            name: row.name, confirm: confirm.value,
          });
          toast(`Restored from ${row.name}. The previous database was saved as `
                + `${result.safety_copy}. Signing you out…`, 'success', 'Restored');
          // The session came from the backup, so this one no longer exists.
          // Reloading lands on the sign-in screen rather than on a screen whose
          // every request would 401.
          setTimeout(() => window.location.reload(), 2500);
        },
      },
    ],
  });
}

const downloadUrl = (name) =>
  `/api/maintenance/backups/${encodeURIComponent(name)}/download`;

/**
 * Fetch a backup to this PC.
 *
 * The browser is left to do the transfer — a 400 MB file should not be pulled
 * through memory to hand back to the browser — but the URL is checked first.
 * A plain `<a download>` pointed at a 404 fails as "Failed - No file" in the
 * downloads tray and says nothing at all inside the application, which is how
 * a server running older code than this page looks from the user's chair.
 */
async function downloadBackup(name) {
  const url = downloadUrl(name);
  try {
    const probe = await fetch(url, { method: 'HEAD' });
    if (!probe.ok) {
      toast(probe.status === 404
        ? `${name} is no longer on the server. It may have been removed by the `
          + 'retention window, or this server is running an older version than '
          + 'this page — restart it and reload.'
        : `The server refused the download (${probe.status}).`,
      'error', 'Could not download');
      return false;
    }
  } catch (error) {
    reportError(error);
    return false;
  }

  const link = el('a', { href: url, download: name });
  document.body.append(link);
  link.click();
  link.remove();
  return true;
}

const KIND_TAGS = {
  automatic: ['neutral', 'automatic'],
  manual: ['info', 'by hand'],
  prerestore: ['open', 'before a restore'],
};

/**
 * Automatic, taken by hand, or saved before a restore.
 *
 * The server says which in `kind`. When it does not — an older one — the
 * filename is read instead, and it is read as a *suffix on the stem* rather
 * than as a substring: `-auto` has to be the last thing before the extension,
 * so it works for `ims-8-31-2026-auto.zip` and the older
 * `ims-20260831-092119-auto.sqlite` alike, and cannot be fooled by a name that
 * merely contains the word.
 */
function kindOf(row) {
  if (row.kind) return row.kind;
  const stem = row.name.replace(/\.(zip|sqlite)$/i, '');
  if (/-auto$/i.test(stem)) return 'automatic';
  if (/-prerestore$/i.test(stem)) return 'prerestore';
  return 'manual';
}

function kindTag(row) {
  const [tone, label] = KIND_TAGS[kindOf(row)] ?? KIND_TAGS.manual;
  return el('span', { class: `tag ${tone}`, text: label });
}

/**
 * The backups, as a list rather than a table.
 *
 * A table put the three actions in a seventh column, 959px into a 341px phone
 * window: reachable only by scrolling a table sideways inside a page, which on
 * a phone means most people never find them at all. Backing up is exactly the
 * thing somebody does from wherever they happen to be, so this is the one
 * screen that has to work on a handset. Here the name and its details stack,
 * and the buttons drop underneath at full width.
 */
function backupList(rows) {
  if (!rows.length) {
    return el('div', { class: 'empty', text: 'No backups yet. Take one now.' });
  }

  return el('ul', { class: 'backup-list' }, rows.map((row) => el('li', {
    class: 'backup-item',
  }, [
    el('div', { class: 'b-main' }, [
      el('span', { class: 'b-name', text: row.name }),
      el('span', { class: 'b-meta' }, [
        kindTag(row),
        el('span', { text: dateTime(row.created_at) }),
        el('span', { class: 'dot', 'aria-hidden': 'true' }),
        el('span', { text: ageOf(row) }),
        el('span', { class: 'dot', 'aria-hidden': 'true' }),
        el('span', { text: `${count(row.size_mb)} MB` }),
      ]),
    ]),
    el('div', { class: 'b-actions' }, [
      // A real link, so a phone browser treats it as a download like any
      // other — its own progress, its own Files/Downloads destination.
      el('a', {
        class: 'btn sm', href: downloadUrl(row.name), download: row.name,
        title: `Download ${row.name} to this device`,
        // Checked before the browser is sent at it, so a file that is no
        // longer there says so here instead of in the downloads tray.
        onClick: (event) => { event.preventDefault(); downloadBackup(row.name); },
      }, [el('span', { class: 'ico-download', 'aria-hidden': 'true' }), 'Download']),
      el('button', {
        class: 'btn ghost sm', text: 'Restore',
        onClick: () => askRestore(row),
      }),
      el('button', {
        class: 'btn ghost sm danger', text: 'Delete',
        title: `Delete ${row.name} from the server`,
        onClick: () => askDelete(row),
      }),
    ]),
  ])));
}

async function askDelete(row) {
  const last = document.querySelectorAll('.backup-item').length <= 1;

  const sure = await confirmDialog(
    `Delete ${row.name}?`,
    (last
      ? 'This is the only backup on the server. Deleting it leaves none to '
        + 'restore from. '
      : '')
    + `It is removed from the server for good — ${count(row.size_mb)} MB freed. `
    + 'If you have already downloaded a copy, that copy is not affected.',
    last ? 'Delete the only backup' : 'Delete');
  if (!sure) return;

  try {
    const result = await api.del(`/maintenance/backups/${encodeURIComponent(row.name)}`);
    toast(`${result.deleted} deleted — ${count(result.size_mb)} MB freed. `
          + `${count(result.remaining)} backup${result.remaining === 1 ? '' : 's'} left.`,
    'success');
    reload();
  } catch (error) {
    reportError(error);
  }
}

function ageOf(row) {
  const days = row.age_days
    ?? (Date.now() - new Date(row.created_at)) / 86400000;
  return days < 1 ? 'today' : `${Math.floor(days)} d`;
}

function backupTone(days, policy) {
  if (days === null) return 'danger';
  // A schedule that is running makes anything older than a couple of days a
  // sign the schedule itself has stopped. Without one, a week is the old mark.
  const stale = policy?.every_hours ? 2 : 7;
  if (days >= stale) return 'danger';
  return days >= 1 ? 'warn' : 'ok';
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
    const swept = result.removed.length
      ? ` ${result.removed.length} older ${result.removed.length === 1 ? 'copy' : 'copies'} removed.`
      : '';
    // Saved on the server first, then handed to whoever asked for it: pressing
    // the button from a counter PC should end with the file on that PC, not
    // with a file on a machine in another room. The backup itself has already
    // succeeded, so the message says so whether or not the transfer starts.
    const sent = await downloadBackup(result.name);
    toast(`${result.name} — ${count(result.size_mb)} MB zipped from `
          + `${count(result.database_mb)} MB.${swept}`
          + (sent ? ' Downloading to this PC.' : ' It is saved on the server.'),
    'success', 'Backed up');
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
