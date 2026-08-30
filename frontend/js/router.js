// Hash router. Routes look like #/invoices or #/stock/ABSO1000.

const routes = [];
let notFound = null;
let current = null;

export function route(pattern, handler) {
  const names = [];
  const regex = new RegExp(`^${pattern.replace(/:([\w]+)/g, (_, name) => {
    names.push(name);
    return '([^/]+)';
  })}$`);
  routes.push({ regex, names, handler, pattern });
}

export function setNotFound(handler) { notFound = handler; }

export function navigate(path, { replace = false } = {}) {
  const target = `#${path}`;
  if (replace) window.history.replaceState(null, '', target);
  else window.location.hash = target;
  if (replace) resolve();
}

export function currentPath() {
  return window.location.hash.slice(1) || '/';
}

export function resolve() {
  const full = currentPath();
  // Query strings (#/invoices/new?customer=ABC) are matched on the path only;
  // views read the parameters from the hash themselves.
  const path = full.split('?')[0];
  for (const item of routes) {
    const match = item.regex.exec(path);
    if (!match) continue;
    const params = {};
    item.names.forEach((name, i) => { params[name] = decodeURIComponent(match[i + 1]); });
    current = item.pattern;
    item.handler(params, full);
    return;
  }
  current = null;
  notFound?.(path);
}

export function activePattern() { return current; }

export function start() {
  window.addEventListener('hashchange', resolve);
  resolve();
}
