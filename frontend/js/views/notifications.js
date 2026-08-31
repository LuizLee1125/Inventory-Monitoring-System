// Notifications — the whole list, behind "View all notifications" on the bell.
//
// There is deliberately no sidebar entry. The bell is the way in: it is where
// the count lives and where somebody looks when they want to know what
// happened, and a rail entry would be a second front door to a screen nobody
// navigates to on purpose.
//
// The rows are drawn by `notify.js`, the same function the panel uses, so the
// summary and the full list can never drift apart.

import { api } from '../api.js';
import { card, clear, el, reportError, toast, toolbar } from '../ui.js';
import { describeError, notificationRow, setUnread } from '../notify.js';
import { setTitle } from '../app.js';

export const skeleton = 'list';

const PAGE_SIZE = 50;

// Open / unread / everything. "Everything" includes conditions that have since
// cleared, which is the only place they can be seen — the badge does not count
// them and the panel does not list them.
const FILTERS = [
  { id: 'open', label: 'Needs attention', params: { open_only: true } },
  { id: 'unread', label: 'Unread', params: { open_only: true, unread_only: true } },
  { id: 'all', label: 'Everything', params: { open_only: false } },
];

export async function render(container) {
  setTitle('Notifications');

  let filter = FILTERS[0];
  let offset = 0;

  const tabs = el('div', {
    class: 'segmented', role: 'group', 'aria-label': 'Which notifications',
  });
  const readAll = el('button', { class: 'btn', text: 'Mark all read' });
  const body = el('div', { class: 'notif-page' });
  const foot = el('div');

  function paintTabs() {
    clear(tabs);
    for (const option of FILTERS) {
      tabs.append(el('button', {
        class: 'segment',
        type: 'button',
        'aria-pressed': String(option.id === filter.id),
        text: option.label,
        onClick: () => {
          if (option.id === filter.id) return;
          filter = option;
          offset = 0;
          paintTabs();
          load();
        },
      }));
    }
  }

  async function load() {
    clear(body);
    clear(foot);
    body.append(el('div', { class: 'notif-empty', text: 'Loading…' }));

    let result;
    try {
      result = await api.get('/notifications',
        { ...filter.params, limit: PAGE_SIZE, offset });
    } catch (error) {
      clear(body);
      // A server without the endpoint is explained on the page rather than
      // thrown as a toast — the toast leaves after four seconds and the screen
      // is then blank with no reason on it.
      if (error?.status !== 404) reportError(error);
      body.append(el('div', { class: 'empty', text: describeError(error) }));
      readAll.disabled = true;
      return;
    }

    // The badge is corrected from this response rather than from a poll: the
    // screen has just read the same figure the bell is showing.
    setUnread(result.unread);
    readAll.disabled = result.unread === 0;

    clear(body);
    const items = result.items || [];
    if (!items.length) {
      body.append(el('div', { class: 'notif-empty' }, [
        filter.id === 'unread'
          ? 'Nothing unread.'
          : 'Nothing to report. Stock levels, expiry dates and the backup are '
            + 'all where they should be.',
      ]));
      return;
    }

    const list = el('div', { class: 'notif-list' });
    for (const item of items) list.append(notificationRow(item));
    body.append(list);

    // Offset paging rather than the shared `pager()`: this list is ordered by
    // time and grows from the top, so page numbers would mean something
    // different from one minute to the next.
    const shown = offset + items.length;
    if (shown < result.total || offset > 0) {
      foot.append(el('div', { class: 'notif-foot' }, [
        el('span', { text: `${shown} of ${result.total}` }),
        offset > 0 ? el('button', {
          class: 'btn', text: 'Newer',
          onClick: () => { offset = Math.max(0, offset - PAGE_SIZE); load(); },
        }) : null,
        shown < result.total ? el('button', {
          class: 'btn', text: 'Older',
          onClick: () => { offset += PAGE_SIZE; load(); },
        }) : null,
      ]));
    }
  }

  readAll.addEventListener('click', async () => {
    readAll.disabled = true;
    try {
      const result = await api.post('/notifications/read-all', {});
      setUnread(result.unread);
      toast(result.marked ? `${result.marked} marked read` : 'Nothing to mark',
            'success');
      await load();
    } catch (error) {
      reportError(error);
      readAll.disabled = false;
    }
  });

  paintTabs();
  container.append(
    toolbar([tabs, el('span', { class: 'spacer' }), readAll]),
    card('', el('div', {}, [body, foot]), [], { flush: true }),
  );
  await load();
}
