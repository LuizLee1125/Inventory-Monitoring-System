// Settings: the account, its password, and how the application looks.
//
// Reached from the avatar in the top right. Everything here is about *this*
// signed-in person — changing somebody else's account is Users & Audit, which
// is where the permission for it lives.

import { api } from '../api.js';
import { card, dateTime, el, field, input, reportError, toast } from '../ui.js';
import { page, session, setTitle } from '../app.js';
import { THEMES, currentTheme, effectiveTheme, setTheme } from '../theme.js';

/** One labelled row: what it is on the left, the control on the right. */
function row(label, hint, control, { grow = false } = {}) {
  return el('div', { class: 'set-row' }, [
    el('div', { class: 'set-label' }, [
      el('strong', { text: label }),
      hint ? el('span', { text: hint }) : null,
    ]),
    el('div', { class: `set-control${grow ? ' grow' : ''}` }, [control]),
  ]);
}

const value = (text, extra = '') =>
  el('div', { class: `set-value ${extra}`.trim(), text: text || '—' });

/* ------------------------------------------------------------- account -- */

function accountCard(me) {
  const roleLabel = session.meta?.roles?.[me.role]?.label || me.role;
  const legacy = session.meta?.roles?.[me.role]?.legacy;

  return card('Account', el('div', {}, [
    row('User name', 'How you sign in. It cannot be changed here.',
      value(me.username, 'mono')),
    row('Full name', 'Shown on the documents you raise.', value(me.full_name)),
    row('Role', legacy ? `Replaces the DOS menu ${legacy}.` : 'What this account may do.',
      el('span', { class: 'tag info', text: roleLabel })),
    row('Permissions', 'Granted by the role, not set per account.',
      value(`${(me.permissions || []).length} granted`, 'dim')),
    me.legacy_access_code
      ? row('Legacy access code', 'Carried over from the DOS PASSFYL record.',
        value(me.legacy_access_code, 'mono dim'))
      : null,
    row('Account opened', '', value(dateTime(me.created_at), 'dim')),
    row('This sign-in', 'When the session you are using began.',
      value(dateTime(me.last_login), 'dim')),
  ]), [], { flush: true });
}

/* ------------------------------------------------------------ password -- */

function passwordCard() {
  const current = input('current_password', { type: 'password', autocomplete: 'current-password' });
  const next = input('new_password', { type: 'password', minlength: 8, autocomplete: 'new-password' });
  const again = input('confirm', { type: 'password', autocomplete: 'new-password' });

  const save = el('button', { class: 'btn primary', text: 'Change password' });

  const form = el('form', { class: 'card-body' }, [
    el('p', { class: 'hint', style: 'margin-top:0' },
      ['Eight characters or more. You stay signed in on this device; other '
       + 'devices keep their sessions until they expire.']),
    el('div', { class: 'form-grid' }, [
      field('Current password', current),
      field('New password', next),
      field('Repeat new password', again),
    ]),
    el('div', { class: 'toolbar', style: 'margin:0' }, [el('span', { class: 'spacer' }), save]),
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

  const node = el('div', { class: 'card' }, [
    el('div', { class: 'card-head' }, [el('h3', { text: 'Password' })]),
    form,
  ]);
  return node;
}

/* ---------------------------------------------------------- appearance -- */

const THEME_ICON = { light: '☀', dark: '☾', system: '🖥' };

function appearanceCard() {
  const buttons = new Map();

  const pick = (mode) => {
    setTheme(mode);
    for (const [value_, button] of buttons) {
      button.setAttribute('aria-pressed', String(value_ === mode));
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

  const describe = () => (currentTheme() === 'system'
    ? `Following this device, which is currently ${effectiveTheme()}.`
    : `Always ${currentTheme()}, whatever this device is set to.`);

  const resolved = el('span', { text: describe() });

  // Painted from the same tokens the rest of the application uses, so it can
  // never claim a colour the interface is not actually showing.
  const preview = el('div', { class: 'theme-preview' }, [
    el('div', { class: 'theme-chip' }, [
      'Surface',
      el('span', { class: 'bar' }),
      el('span', { class: 'bar dim' }),
    ]),
    el('div', { class: 'theme-chip', style: 'background:var(--surface-2)' }, [
      'Raised',
      el('span', { class: 'bar' }),
      el('span', { class: 'bar dim' }),
    ]),
    el('div', { class: 'theme-chip', style: 'background:var(--primary-soft);color:var(--on-primary-soft)' }, [
      'Accent',
      el('span', { class: 'bar' }),
      el('span', { class: 'bar dim' }),
    ]),
  ]);

  return card('Appearance', el('div', {}, [
    el('div', { class: 'set-row' }, [
      el('div', { class: 'set-label' }, [
        el('strong', { text: 'Theme' }),
        el('span', {}, [resolved]),
      ]),
      el('div', { class: 'set-control' }, [segmented]),
    ]),
    el('div', { class: 'card-body', style: 'padding-top:0' }, [preview]),
  ]), [], { flush: true });
}

/* ---------------------------------------------------------------------- */

export async function render(container) {
  setTitle('Settings');

  // Read the account fresh rather than trusting the copy taken at sign-in:
  // an administrator may have changed the role in the meantime.
  const me = await api.get('/me');
  session.user = { ...session.user, ...me };

  container.classList.add('settings');
  container.append(
    el('p', { class: 'lede' },
      ['Your account, and how this application looks on this device. '
       + 'The appearance setting is remembered in this browser only — signing '
       + 'in elsewhere starts from the system setting again.']),
    accountCard(me),
    passwordCard(),
    appearanceCard(),
  );
}

/** The router clears the page between screens but not its classes. */
export function leave() {
  page().classList.remove('settings');
}
