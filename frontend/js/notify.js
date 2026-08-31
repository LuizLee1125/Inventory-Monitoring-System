// The bell in the top bar: the unread badge, the panel behind it, and the poll
// that keeps both honest.
//
// The server raises the alerts (`backend/app/notifications.py`); this only ever
// reads them and marks them read. Anything that decides *when* an alert starts
// or stops belongs there, not here.

import { api } from './api.js';
import { $, clear, el, toast } from './ui.js';

// A minute. These are conditions that change on a fifteen-minute sweep, so
// asking more often than this would only produce the same answer faster.
const POLL_MS = 60000;

// The panel is a summary. Anything past this is what "View all" is for.
const PANEL_LIMIT = 6;

let timer = null;
let unread = 0;
let wired = false;

// Ids already announced as a toast, so a rising count never re-announces
// something the user has been shown. Reset on sign-out with everything else.
const announced = new Set();

/* --------------------------------------------------------------- helpers -- */

// A workstation is routinely a version ahead of the server: this application is
// left open for days, and the office updates the PC in the corner rather than
// the counter machines. The 404 that produces is not "something went wrong", it
// is "that server has not been restarted yet" — and saying which is the
// difference between somebody restarting it and somebody reporting a bug.
//
// Same reasoning as the retention picker on the maintenance screen, which is
// drawn disabled with its reason on it rather than hidden.
export function describeError(error) {
  if (error?.status === 404) {
    return 'This server does not have notifications yet — it needs restarting '
      + 'to pick up the update.';
  }
  return error?.message || 'Could not load notifications.';
}

export function sinceText(value) {
  if (!value) return '';
  const then = new Date(value);
  if (Number.isNaN(then.getTime())) return '';
  const seconds = Math.max(0, (Date.now() - then.getTime()) / 1000);
  if (seconds < 90) return 'just now';
  const minutes = Math.round(seconds / 60);
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours} ${hours === 1 ? 'hour' : 'hours'} ago`;
  const days = Math.round(hours / 24);
  if (days < 30) return `${days} ${days === 1 ? 'day' : 'days'} ago`;
  return then.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: '2-digit' });
}

// Where a notification points. The server says what it is about rather than
// naming a route, so the two halves are not coupled: `report` carries a path
// because the report list is the answer to a rolled-up alert, and `stock`
// carries a code.
export function targetOf(item) {
  if (item.entity === 'report' && item.entity_id) return `#${item.entity_id}`;
  if (item.entity === 'stock' && item.entity_id) return `#/stock/${item.entity_id}`;
  return '';
}

export function notificationRow(item, { onNavigate } = {}) {
  const href = targetOf(item);
  const classes = ['notif-item', `sev-${item.severity || 'info'}`];
  if (item.is_read) classes.push('read');
  if (item.resolved_at) classes.push('resolved');

  const children = [
    el('span', { class: 'notif-dot', 'aria-hidden': 'true' }),
    el('div', { class: 'notif-text' }, [
      el('strong', { text: item.title }),
      item.body ? el('span', { class: 'notif-body', text: item.body }) : null,
      el('span', { class: 'notif-when', text: sinceText(item.raised_at) }),
    ]),
  ];

  // A row with nowhere to go is a div, not a dead link.
  if (!href) return el('div', { class: classes.join(' ') }, children);
  return el('a', {
    class: classes.join(' '),
    href,
    onClick: () => { markRead([item.id]); onNavigate?.(); },
  }, children);
}

/* ------------------------------------------------------------- the badge -- */

function paintBadge() {
  const badge = $('#bell-badge');
  if (!badge) return;
  badge.hidden = unread === 0;
  // Past ninety-nine the exact number stops being information and starts being
  // a wide badge over the top of the bell.
  badge.textContent = unread > 99 ? '99+' : String(unread);
  const bell = $('#btn-bell');
  if (bell) {
    bell.title = unread
      ? `Notifications — ${unread} unread`
      : 'Notifications';
  }
}

export function setUnread(count) {
  unread = Math.max(0, Number(count) || 0);
  paintBadge();
}

/* -------------------------------------------------------------- the poll -- */

async function announceNew() {
  // Only ever called when the count went UP, so this is one extra request on a
  // change rather than a second request on every tick.
  let items = [];
  try {
    const result = await api.get('/notifications', { unread_only: true, limit: 5 });
    items = result.items || [];
  } catch { return; }

  for (const item of items.reverse()) {
    if (announced.has(item.id)) continue;
    announced.add(item.id);
    toast(item.body || '', item.severity === 'error' ? 'error' : 'warn', item.title);
  }
}

async function poll({ announce = true } = {}) {
  let count;
  try {
    ({ unread: count } = await api.get('/notifications/unread-count'));
  } catch {
    // A failed poll is not worth telling anybody about; the next one is a
    // minute away and the badge keeps its last honest value.
    return;
  }
  const rose = count > unread;
  setUnread(count);
  if (rose && announce) await announceNew();
}

export function startNotifications() {
  stopNotifications();
  // First answer immediately: the interesting case is signing in to find that
  // something happened overnight, and waiting a minute for it is a poor way to
  // learn that. Nothing is toasted on this pass — everything is new to a page
  // that has just loaded, and a stack of six toasts on arrival is not a
  // welcome.
  poll({ announce: false });
  timer = setInterval(poll, POLL_MS);
}

export function stopNotifications() {
  if (timer) clearInterval(timer);
  timer = null;
  setUnread(0);
  announced.clear();
  closeNotifications();
}

// A hidden tab runs no useful poll and a machine left on overnight would
// otherwise make several hundred pointless requests before anybody came back.
document.addEventListener('visibilitychange', () => {
  if (!timer && !document.hidden) return;
  if (document.hidden) {
    clearInterval(timer);
    timer = null;
  } else {
    poll();
    timer = setInterval(poll, POLL_MS);
  }
});

/* ------------------------------------------------------------- the panel -- */

export function closeNotifications() {
  const menu = $('#notif-menu');
  if (menu && !menu.hidden) {
    menu.hidden = true;
    $('#btn-bell')?.setAttribute('aria-expanded', 'false');
  }
}

async function markRead(ids) {
  if (!ids.length) return;
  try {
    const result = await api.post('/notifications/read', { ids });
    setUnread(result.unread);
  } catch { /* the badge corrects itself on the next poll */ }
}

async function markAllRead() {
  const button = $('#btn-read-all');
  if (button) button.disabled = true;
  try {
    const result = await api.post('/notifications/read-all', {});
    setUnread(result.unread);
    await fillPanel();
  } catch (error) {
    toast(error.message || 'Could not mark them read', 'error');
    if (button) button.disabled = false;
  }
}

async function fillPanel() {
  const list = $('#notif-list');
  if (!list) return;
  let result;
  try {
    result = await api.get('/notifications', { limit: PANEL_LIMIT });
  } catch (error) {
    clear(list);
    list.append(el('div', { class: 'notif-empty', text: describeError(error) }));
    const stale = $('#btn-read-all');
    if (stale) stale.disabled = true;
    return;
  }

  setUnread(result.unread);
  clear(list);

  const items = result.items || [];
  if (!items.length) {
    list.append(el('div', { class: 'notif-empty', text: 'Nothing needs attention.' }));
  } else {
    for (const item of items) {
      list.append(notificationRow(item, { onNavigate: closeNotifications }));
    }
  }

  const readAll = $('#btn-read-all');
  if (readAll) readAll.disabled = !items.some((item) => !item.is_read);
}

export function wireNotifications() {
  if (wired) return;
  wired = true;

  const bell = $('#btn-bell');
  const menu = $('#notif-menu');
  if (!bell || !menu) return;

  bell.addEventListener('click', (event) => {
    event.stopPropagation();
    const opening = menu.hidden;
    menu.hidden = !opening;
    bell.setAttribute('aria-expanded', String(opening));
    // Fetched on open rather than kept warm: the panel is only ever looked at
    // deliberately, and the badge already answers the question that is asked
    // without opening it.
    if (opening) fillPanel();
  });

  // Clicks inside must not reach the document handler that closes it.
  menu.addEventListener('click', (event) => event.stopPropagation());
  $('#btn-read-all')?.addEventListener('click', markAllRead);
  $('#btn-view-all')?.addEventListener('click', closeNotifications);
}
