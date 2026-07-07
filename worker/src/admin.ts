/// Maintainer-only view: list every jar with counters, delete abusive ones.
/// Auth = long random ADMIN_TOKEN (wrangler secret) as a Bearer header; the
/// page asks for it once and keeps it in sessionStorage. All registry data
/// is rendered client-side via textContent — no HTML from stored values.

import { timingSafeStringEqual } from "./auth";
import type { Env } from "./types";

export async function isAdmin(request: Request, env: Env): Promise<boolean> {
  const header = request.headers.get("Authorization") ?? "";
  if (!header.startsWith("Bearer ") || !env.ADMIN_TOKEN) return false;
  return timingSafeStringEqual(header.slice(7), env.ADMIN_TOKEN);
}

const ADMIN_SCRIPT = `(function () {
  var token = sessionStorage.getItem('lt-admin-token');
  if (!token) {
    token = prompt('Admin token');
    if (!token) return;
    sessionStorage.setItem('lt-admin-token', token);
  }
  function load() {
    fetch('/admin/jars', { headers: { Authorization: 'Bearer ' + token } })
      .then(function (res) {
        if (res.status === 401) { sessionStorage.removeItem('lt-admin-token'); throw new Error('unauthorized'); }
        if (!res.ok) throw new Error('http ' + res.status);
        return res.json();
      })
      .then(render)
      .catch(function (e) { document.getElementById('status').textContent = String(e); });
  }
  function td(text) { var el = document.createElement('td'); el.textContent = text; return el; }
  function render(rows) {
    document.getElementById('status').textContent = rows.length + ' jars';
    var body = document.getElementById('rows');
    body.textContent = '';
    rows.forEach(function (r) {
      var tr = document.createElement('tr');
      tr.appendChild(td(r.jarId));
      tr.appendChild(td(r.artistName));
      tr.appendChild(td(r.methods));
      tr.appendChild(td(new Date(r.createdAt).toISOString().slice(0, 10)));
      tr.appendChild(td(new Date(r.lastSeenDay * 86400000).toISOString().slice(0, 10)));
      tr.appendChild(td(String(r.tipsToday)));
      tr.appendChild(td(String(r.tipsTotal)));
      var actions = document.createElement('td');
      var link = document.createElement('a');
      link.href = 'https://live.tips/t/' + encodeURIComponent(r.jarId);
      link.textContent = 'page';
      link.target = '_blank';
      link.rel = 'noopener';
      actions.appendChild(link);
      var del = document.createElement('button');
      del.textContent = 'delete';
      del.addEventListener('click', function () {
        if (!confirm('Delete jar ' + r.jarId + ' (' + r.artistName + ')?')) return;
        fetch('/admin/jars/' + encodeURIComponent(r.jarId), {
          method: 'DELETE',
          headers: { Authorization: 'Bearer ' + token }
        }).then(load);
      });
      actions.appendChild(del);
      tr.appendChild(actions);
      body.appendChild(tr);
    });
  }
  load();
})();`;

export function renderAdminPage(): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>live.tips relay admin</title>
<style>
body { font: 14px/1.5 system-ui, sans-serif; margin: 24px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc; padding: 6px 10px; text-align: left; font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
th { background: #f2f2f2; }
button { cursor: pointer; margin-left: 8px; }
</style>
</head>
<body>
<h1>live.tips relay — jars</h1>
<p id="status">Loading…</p>
<table>
<thead><tr><th>jarId</th><th>artist</th><th>methods</th><th>created</th><th>last seen</th><th>tips today</th><th>tips total</th><th></th></tr></thead>
<tbody id="rows"></tbody>
</table>
<script>${ADMIN_SCRIPT}</script>
</body>
</html>`;
}

let cspCache: string | null = null;

export async function adminPageCsp(): Promise<string> {
  if (cspCache === null) {
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(ADMIN_SCRIPT));
    const hash = btoa(String.fromCharCode(...new Uint8Array(digest)));
    cspCache = [
      "default-src 'none'",
      `script-src 'sha256-${hash}'`,
      "style-src 'unsafe-inline'",
      "connect-src 'self'",
      "base-uri 'none'",
      "frame-ancestors 'none'",
    ].join("; ");
  }
  return cspCache;
}
