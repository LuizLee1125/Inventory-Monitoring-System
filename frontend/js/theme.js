// Light / dark / follow-system, stored per browser.
//
// The stylesheet has carried a complete dark palette for a long time, keyed on
// `:root[data-theme="dark"]`, but nothing ever set that attribute — so the
// theme was whatever the operating system said and could not be changed from
// inside the application. This is the missing half.
//
// Three modes, and "system" is deliberately not the same as writing out the
// current system value:
//
//   system  no attribute at all, so the `prefers-color-scheme` block in
//           app.css wins and the theme follows the OS as it changes
//   light   data-theme="light", which that block explicitly excludes
//   dark    data-theme="dark"
//
// The first paint is handled by a small inline copy of `apply()` in the head of
// index.html. Without it a dark-mode user gets a white flash on every load
// while this module is fetched and parsed. If the modes ever change, that copy
// has to change with them.

const KEY = 'ims.theme';
const DARK = '(prefers-color-scheme: dark)';

export const THEMES = [
  { value: 'light', label: 'Light', hint: 'Always the light palette' },
  { value: 'dark', label: 'Dark', hint: 'Always the dark palette' },
  { value: 'system', label: 'System', hint: 'Follow this device' },
];

const listeners = new Set();

export function currentTheme() {
  const stored = localStorage.getItem(KEY);
  return stored === 'light' || stored === 'dark' ? stored : 'system';
}

/** What the user actually sees: 'light' or 'dark', never 'system'. */
export function effectiveTheme() {
  const mode = currentTheme();
  if (mode !== 'system') return mode;
  return window.matchMedia(DARK).matches ? 'dark' : 'light';
}

function apply(mode) {
  const root = document.documentElement;
  if (mode === 'system') root.removeAttribute('data-theme');
  else root.dataset.theme = mode;
}

export function setTheme(mode) {
  const next = THEMES.some((t) => t.value === mode) ? mode : 'system';
  if (next === 'system') localStorage.removeItem(KEY);
  else localStorage.setItem(KEY, next);
  apply(next);
  for (const fn of listeners) fn(next, effectiveTheme());
}

export function onThemeChange(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

export function initTheme() {
  apply(currentTheme());
  // Only meaningful in system mode, but harmless otherwise: the attribute
  // already pins the theme, so nothing visible changes.
  window.matchMedia(DARK).addEventListener('change', () => {
    if (currentTheme() === 'system') {
      for (const fn of listeners) fn('system', effectiveTheme());
    }
  });
}
