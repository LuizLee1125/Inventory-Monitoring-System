// Users, roles, live sessions and the audit trail.

import { api } from '../api.js';
import {
  card, clear, count, dataTable, dateTime, el, field, input, modal, promptDialog,
  readForm, reportError, select, stat, statusTag, toast,
} from '../ui.js';
import { page, session, setTitle } from '../app.js';

/** A heading between groups of cards, so five stacked tables read as two ideas. */
function section(title, hint) {
  return el('div', { class: 'section-head' }, [
    el('h3', { text: title }),
    hint ? el('span', { text: hint }) : null,
  ]);
}

/* Seventeen permissions rendered as one comma-separated line is a wall of text
   that nobody reads, and every role holds the same reads — the writes are the
   whole difference between them. So: what it may change, as chips, and the
   reads reduced to a count. */
function rolePowers(role) {
  const writes = role.permissions
    .filter((p) => !p.endsWith(':read'))
    .map((p) => p.replace(/:write$/, '').replace(':', ' '));
  const reads = role.permissions.length - writes.length;

  return el('div', { class: 'chips' }, [
    ...(writes.length
      ? writes.map((name) => el('span', { class: 'tag info', text: name }))
      : [el('span', { class: 'tag neutral', text: 'read only' })]),
    el('span', { class: 'chips-note', text: `+ ${reads} read` }),
  ]);
}

export const skeleton = 'stats';

export async function render(container) {
  setTitle('Users and audit');

  const [users, roles, sessions, stats, audit] = await Promise.all([
    api.get('/admin/users'),
    api.get('/admin/roles'),
    api.get('/admin/sessions'),
    api.get('/admin/stats'),
    api.get('/admin/audit', { page_size: 60 }),
  ]);

  const roleOptions = roles.map((role) => [role.name, role.label]);
  const active = users.filter((u) => u.is_active).length;
  const mustChange = users.filter((u) => u.must_change_password).length;

  container.append(
    // The screen used to open on a bare "4 accounts" heading above a table.
    // These are the four questions an administrator actually arrives with.
    el('div', { class: 'stat-grid four' }, [
      stat('Accounts', count(users.length),
        active === users.length ? 'all active' : `${count(users.length - active)} disabled`),
      stat('Signed in now', count(sessions.length),
        sessions.length === 1 ? 'one session' : 'live sessions', sessions.length ? 'ok' : ''),
      stat('Roles', count(roles.length), 'from the DOS menus'),
      stat('Password changes due', count(mustChange),
        mustChange ? 'at next sign-in' : 'none outstanding', mustChange ? 'warn' : ''),
    ]),

    section('People', 'Who may sign in, and what they may do'),

    card('Users', dataTable([
      { key: 'username', label: 'User name', class: 'mono' },
      { key: 'full_name', label: 'Name' },
      { key: 'role', label: 'Role',
        render: (r) => roles.find((role) => role.name === r.role)?.label || r.role },
      { key: 'legacy_access_code', label: 'Legacy code',
        render: (r) => (r.legacy_access_code
          ? el('span', { class: 'tag neutral', text: r.legacy_access_code }) : '') },
      { key: 'is_active', label: 'Status',
        render: (r) => el('span', { class: `tag ${r.is_active ? 'paid' : 'cancelled'}`,
                                    text: r.is_active ? 'Active' : 'Disabled' }) },
      { key: 'must_change_password', label: 'Password',
        render: (r) => (r.must_change_password
          ? el('span', { class: 'tag open', text: 'Change required' }) : '') },
      { key: 'last_login', label: 'Last sign-in', render: (r) => dateTime(r.last_login) },
      { key: 'actions', label: '',
        render: (r) => el('span', {}, [
          el('button', { class: 'btn ghost sm', text: 'Edit',
                         onClick: (e) => { e.stopPropagation(); editUser(r, roleOptions); } }),
          el('button', { class: 'btn ghost sm', text: 'Reset password',
                         onClick: (e) => { e.stopPropagation(); resetPassword(r); } }),
        ]) },
    ], users, { emptyText: 'No accounts.' }),
      [el('button', { class: 'btn primary sm', text: '+ New user',
                      onClick: () => editUser(null, roleOptions) })],
      { flush: true }),

    card('Roles', dataTable([
      { key: 'label', label: 'Role' },
      { key: 'legacy', label: 'Legacy menu', class: 'mono' },
      { key: 'permissions', label: 'May change', class: 'wrap',
        render: rolePowers },
      { key: 'holders', label: 'Accounts', align: 'right',
        render: (r) => count(users.filter((u) => u.role === r.name).length) },
    ], roles, {}), [], { flush: true }),

    section('System', 'Sessions, storage and the record of what happened'),

    card('Signed in now', dataTable([
      { key: 'username', label: 'User name', class: 'mono' },
      { key: 'full_name', label: 'Name' },
      { key: 'role', label: 'Role' },
      { key: 'ip', label: 'Address' },
      { key: 'created_at', label: 'Since', render: (r) => dateTime(r.created_at) },
      { key: 'expires_at', label: 'Expires', render: (r) => dateTime(r.expires_at) },
    ], sessions, {
      emptyText: 'Nobody else is signed in.',
    }), [], { flush: true }),

    card('Database', dataTable([
      { key: 'table', label: 'Table' },
      { key: 'rows', label: 'Rows', align: 'right', render: (r) => count(r.rows) },
    ], Object.entries(stats.rows).map(([table, rows]) => ({ table, rows })), {}),
      [], { flush: true }),

    card('Audit trail', dataTable([
      { key: 'at', label: 'When', render: (r) => dateTime(r.at) },
      { key: 'username', label: 'User', class: 'mono' },
      { key: 'action', label: 'Action', render: (r) => statusTag(r.action) },
      { key: 'entity', label: 'Entity' },
      { key: 'entity_id', label: 'Reference', class: 'mono' },
      { key: 'detail', label: 'Detail', class: 'wrap' },
    ], audit.items, { emptyText: 'Nothing recorded yet.' }), [], { flush: true }),
  );
}

function editUser(user, roleOptions) {
  const isNew = !user;
  const form = el('div', { class: 'form-grid' }, [
    field('User name', input('username', {
      value: user?.username || '', readonly: !isNew, required: true,
      style: 'text-transform:uppercase',
    })),
    field('Full name', input('full_name', { value: user?.full_name || '' })),
    field('Role', select('role', roleOptions, user?.role || 'viewer')),
    isNew ? field('Password (8 characters or more)',
      input('password', { type: 'password', required: true, minlength: 8 })) : null,
    // A checkbox is not a field with a value under a label — it is a statement
    // you agree or disagree with, so it reads as one line.
    el('label', { class: 'field span2 check' }, [
      el('input', {
        type: 'checkbox', name: 'is_active', checked: user ? Boolean(user.is_active) : true,
      }),
      el('span', { text: 'Active — may sign in' }),
    ]),
  ]);

  modal({
    title: isNew ? 'New user' : `Edit ${user.username}`,
    body: form,
    actions: [
      { label: 'Cancel' },
      {
        label: 'Save',
        kind: 'primary',
        onClick: async () => {
          const payload = readForm(form);
          payload.username = (payload.username || '').toUpperCase();
          if (isNew) {
            await api.post('/admin/users', payload);
            toast(`${payload.username} created. They must change the password at first sign-in.`,
              'success');
          } else {
            payload.version = user.version;
            await api.put(`/admin/users/${user.id}`, payload);
            toast('Saved.', 'success');
          }
          reload();
        },
      },
    ],
  });
}

async function resetPassword(user) {
  const password = await promptDialog(`Reset password for ${user.username}`,
    'New password (8 characters or more)');
  if (!password) return;
  if (password.length < 8) return toast('Too short — use at least 8 characters.', 'error');
  try {
    await api.post(`/admin/users/${user.id}/reset-password`, { password });
    toast(`Password reset. ${user.username} must change it at next sign-in.`, 'success');
    if (user.username === session.user.username) {
      toast('Your own sessions were signed out.', 'warn');
    }
    reload();
  } catch (error) {
    reportError(error);
  }
}

function reload() {
  const container = page();
  clear(container);
  render(container).catch(reportError);
}
