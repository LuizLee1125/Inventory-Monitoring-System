// Thin fetch wrapper. Every call goes through here so authentication failures
// and edit conflicts are handled in exactly one place.

const listeners = { unauthorized: [] };

export function onUnauthorized(fn) { listeners.unauthorized.push(fn); }

export class ApiError extends Error {
  constructor(status, detail) {
    super(detail || `Request failed (${status})`);
    this.status = status;
    this.detail = detail;
    // 409 means another user saved first - the web equivalent of the DOS
    // "record is being used by another user" message.
    this.isConflict = status === 409;
  }
}

function queryString(params) {
  if (!params) return '';
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === '' || value === false) continue;
    search.set(key, value);
  }
  const text = search.toString();
  return text ? `?${text}` : '';
}

async function request(method, path, { body, params } = {}) {
  const response = await fetch(`/api${path}${queryString(params)}`, {
    method,
    headers: body ? { 'Content-Type': 'application/json' } : undefined,
    body: body ? JSON.stringify(body) : undefined,
    credentials: 'same-origin',
  });

  if (response.status === 204) return null;

  let payload = null;
  const type = response.headers.get('content-type') || '';
  if (type.includes('application/json')) {
    payload = await response.json().catch(() => null);
  }

  if (!response.ok) {
    if (response.status === 401) listeners.unauthorized.forEach((fn) => fn());
    let detail = payload?.detail;
    if (Array.isArray(detail)) detail = detail.map((d) => d.msg || d).join('; ');
    throw new ApiError(response.status, detail);
  }
  return payload;
}

export const api = {
  get: (path, params) => request('GET', path, { params }),
  post: (path, body) => request('POST', path, { body }),
  put: (path, body) => request('PUT', path, { body }),
  del: (path) => request('DELETE', path),
};
