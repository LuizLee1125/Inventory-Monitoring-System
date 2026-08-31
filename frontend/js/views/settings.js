// Settings: the account, its password, and how the application looks.
//
// Reached from the initials in the top right. Everything here is about *this*
// signed-in person — changing somebody else's account is Users & Audit, which
// is where the permission for it lives.
//
// Two columns of grouped rows: the group's name sits outside its card, so the
// card holds nothing but controls. Left is the account and its password, right
// is appearance and what this installation is.

import { api } from '../api.js';
import { dateTime, el, field, input, reportError, toast } from '../ui.js';
import { page, session, setTitle } from '../app.js';
import { THEMES, currentTheme, effectiveTheme, setTheme } from '../theme.js';

/* --------------------------------------------------------------- pieces -- */

/** A titled group: label outside, card of rows inside, optional footer. */
function group(label, rows, foot = null) {
  return el('section', { class: 'set-group' }, [
    el('h3', { text: label }),
    el('div', { class: 'set-card' }, [
      ...rows.filter(Boolean),
      foot ? el('div', { class: 'set-foot' }, [foot]) : null,
    ]),
  ]);
}

/** One label/control pair. `stacked` puts the control on its own line. */
function row(label, hint, control, { stacked = false } = {}) {
  return el('div', { class: `set-row${stacked ? ' stacked' : ''}` }, [
    el('div', { class: 'set-label' }, [
      el('strong', { text: label }),
      hint ? el('span', { text: hint }) : null,
    ]),
    el('div', { class: 'set-control' }, [control]),
  ]);
}

/* A read-only value reads as data, not as a disabled input: an input box the
   user cannot type into invites clicking at it until they give up. */
const value = (text, extra = '') =>
  el('div', { class: `set-value ${extra}`.trim(), text: text || '—' });

/** Initials, the same rule the top-bar avatar uses. */
function initials(name) {
  const parts = String(name || '').trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return '··';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

/* ------------------------------------------------------------- account -- */

function accountGroup(me) {
  const role = session.meta?.roles?.[me.role];
  const who = me.full_name || me.username;

  // No photographs anywhere in this system, and no plan for any: the initials
  // block is the avatar rather than a placeholder waiting to be replaced.
  const profile = el('div', { class: 'set-profile' }, [
    el('div', { class: 'set-avatar', 'aria-hidden': 'true', text: initials(who) }),
    el('div', { class: 'set-who' }, [
      el('div', { class: 'name' }, [
        el('h4', { text: who }),
        el('span', { class: 'tag info', text: role?.label || me.role }),
      ]),
      el('p', { class: 'mono', text: me.username }),
    ]),
  ]);

  return group('Account', [
    profile,
    row('Full name', 'Shown on the documents you raise.', value(me.full_name)),
    row('Role', role?.legacy && role.legacy !== '-'
      ? `Replaces the DOS menu ${role.legacy}.`
      : 'What this account may do.',
    value(`${(me.permissions || []).length} permissions`, 'dim')),
    me.legacy_access_code
      ? row('Legacy access code', 'Carried over from the DOS PASSFYL record.',
        value(me.legacy_access_code, 'mono dim'))
      : null,
    row('Account opened', '', value(dateTime(me.created_at), 'dim')),
    row('This sign-in', 'When the session you are using began.',
      value(dateTime(me.last_login), 'dim')),
  ]);
}

/* ------------------------------------------------------------ password -- */

function passwordGroup() {
  const current = input('current_password',
    { type: 'password', autocomplete: 'current-password' });
  const next = input('new_password',
    { type: 'password', minlength: 8, autocomplete: 'new-password' });
  const again = input('confirm', { type: 'password', autocomplete: 'new-password' });

  const save = el('button', { class: 'btn primary', type: 'submit', text: 'Change password' });

  const form = el('form', { class: 'set-group' }, [
    el('h3', { text: 'Security' }),
    el('div', { class: 'set-card' }, [
      el('div', { class: 'set-stack' }, [
        el('p', { class: 'hint', style: 'margin:0' },
          ['Eight characters or more. You stay signed in on this device; other '
           + 'devices keep their sessions until they expire.']),
        field('Current password', current),
        field('New password', next),
        field('Repeat new password', again),
      ]),
      el('div', { class: 'set-foot' }, [save]),
    ]),
  ]);

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (next.value !== again.value) {
      toast('The two new passwords do not match.', 'error');
      again.focus();
      return;
    }
    save.disabled = true;
    try {
      await api.post('/change-password', {
        current_password: current.value, new_password: next.value,
      });
      session.user.must_change_password = false;
      form.reset();
      toast('Password changed.', 'success');
    } catch (error) {
      reportError(error);
    } finally {
      save.disabled = false;
    }
  });

  return form;
}

/* ---------------------------------------------------------- appearance -- */

const THEME_ICON = { light: '☀', dark: '☾', system: '🖥' };

function appearanceGroup() {
  const buttons = new Map();
  const describe = () => (currentTheme() === 'system'
    ? `Following this device, which is currently ${effectiveTheme()}.`
    : `Always ${currentTheme()}, whatever this device is set to.`);
  const resolved = el('span', { text: describe() });
  const label = el('div', { class: 'set-label' }, [
    el('strong', { text: 'Theme' }),
    el('span', {}, [resolved]),
  ]);

  const pick = (mode) => {
    setTheme(mode);
    for (const [name, button] of buttons) {
      button.setAttribute('aria-pressed', String(name === mode));
    }
    resolved.textContent = describe();
  };

  const segmented = el('div', {
    class: 'segmented', role: 'group', 'aria-label': 'Appearance',
  }, THEMES.map((theme) => {
    const button = el('button', {
      class: 'segment',
      type: 'button',
      title: theme.hint,
      'aria-pressed': String(theme.value === currentTheme()),
      onClick: () => pick(theme.value),
    }, [
      el('span', { class: 'ico', text: THEME_ICON[theme.value] }),
      theme.label,
    ]);
    buttons.set(theme.value, button);
    return button;
  }));

  // The swatch strip that used to sit under this is gone: the application
  // behind the card is the preview, and it repaints the moment a segment is
  // pressed. Three chips saying SURFACE / RAISED / ACCENT showed the same
  // colours a second time and cost the card most of its height.
  return el('section', { class: 'set-group' }, [
    el('h3', { text: 'Appearance' }),
    el('div', { class: 'set-card' }, [
      el('div', { class: 'set-row' }, [
        label,
        el('div', { class: 'set-control' }, [segmented]),
      ]),
    ]),
  ]);
}

/* -------------------------------------------------------------- system -- */

function systemGroup() {
  const meta = session.meta || {};
  return group('System', [
    row('Company', 'Set with IMS_COMPANY on the server.', value(meta.company)),
    row('Application', '', value(meta.app)),
    row('Version', '', value(meta.version ? `v${meta.version}` : '', 'mono dim')),
    row('Roles defined', 'Carried over from the DOS access menus.',
      value(`${Object.keys(meta.roles || {}).length}`, 'dim')),
  ]);
}

/* ---------------------------------------------------------------------- */

export async function render(container) {
  setTitle('Settings');

  // Read the account fresh rather than trusting the copy taken at sign-in:
  // an administrator may have changed the role in the meantime.
  const me = await api.get('/me');
  session.user = { ...session.user, ...me };

  // No standing header: the top bar already says Settings, and the group
  // labels say what each card is. A sentence above them restated both.
  container.classList.add('settings-page');
  container.append(
    el('div', { class: 'settings-grid' }, [
      el('div', { class: 'set-col' }, [accountGroup(me), passwordGroup()]),
      el('div', { class: 'set-col' }, [appearanceGroup(), systemGroup()]),
    ]),
  );
}

/** The router clears the page between screens but not its classes. */
export function leave() {
  page().classList.remove('settings-page');
}
