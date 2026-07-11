/// Server-rendered donor page. Two invariants keep it XSS-proof:
/// 1. every interpolated value passes through escapeHtml() (or is a number),
/// 2. the single inline <script> is a static constant — no template holes —
///    so its CSP hash is stable by construction. Page data reaches the
///    script only via escaped data-* attributes.

import { bareMethodUrl } from "./deeplinks";
import { methodCurrency, TIP_METHODS } from "./methods";
import { amountBounds, escapeHtml, ZERO_DECIMAL } from "./validate";
import type { JarProfile } from "./types";

/** Static — never interpolate into this string (it is hashed for CSP). */
const INLINE_SCRIPT = `(function () {
  var form = document.getElementById('tipform');
  if (!form) return;
  // Per-method pricing: a Box always collects EUR and Monzo always GBP, so the
  // amount the donor types is denominated by the METHOD they picked, not by the
  // jar. Picking a method reprices the whole field.
  var methods = JSON.parse(document.querySelector('main').getAttribute('data-methods'));
  var current = null;
  var methodInput = document.getElementById('f-method');
  var amountEl = document.getElementById('f-amount');
  var labelEl = document.getElementById('f-amount-label');
  var chipsEl = document.getElementById('f-chips');
  var errEl = document.getElementById('f-error');
  var successEl = document.getElementById('f-success');
  var redirected = false;
  function show(el) { el.removeAttribute('hidden'); }
  function hide(el) { el.setAttribute('hidden', ''); }
  function showSuccess() {
    var names = { mobilepay: 'MobilePay', monzo: 'Monzo', revolut: 'Revolut' };
    document.getElementById('f-success-app').textContent = names[methodInput.value] || 'the app';
    hide(form);
    show(successEl);
    successEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
  function reprice(method) {
    current = methods[method];
    labelEl.textContent = 'Amount (' + current.code + ')';
    amountEl.value = '';
    amountEl.placeholder = String(current.chips[1]);
    chipsEl.textContent = '';
    current.chips.forEach(function (c) {
      var b = document.createElement('button');
      b.type = 'button';
      b.textContent = String(c);
      b.addEventListener('click', function () { amountEl.value = String(c); });
      chipsEl.appendChild(b);
    });
  }
  document.addEventListener('visibilitychange', function () {
    if (redirected && document.visibilityState === 'visible') showSuccess();
  });
  Array.prototype.forEach.call(document.querySelectorAll('button[data-method]'), function (btn) {
    btn.addEventListener('click', function () {
      methodInput.value = btn.getAttribute('data-method');
      document.getElementById('f-title').textContent = btn.getAttribute('data-label');
      reprice(btn.getAttribute('data-method'));
      show(form);
      form.scrollIntoView({ behavior: 'smooth', block: 'start' });
      amountEl.focus();
    });
  });
  form.addEventListener('submit', function (ev) {
    ev.preventDefault();
    hide(errEl);
    if (!current) return;
    var name = document.getElementById('f-name').value.trim();
    if (name.indexOf(':') !== -1) {
      errEl.textContent = 'Please leave the ":" character out of your name.';
      show(errEl);
      return;
    }
    var amount = Math.round(parseFloat(amountEl.value.replace(',', '.')) * current.factor);
    if (!isFinite(amount) || amount < current.min || amount > current.max) {
      errEl.textContent = 'Please enter a valid amount.';
      show(errEl);
      return;
    }
    var tokenEl = form.querySelector('[name="cf-turnstile-response"]');
    var token = tokenEl ? tokenEl.value : '';
    if (!token) {
      errEl.textContent = 'Please complete the verification above.';
      show(errEl);
      return;
    }
    var btn = document.getElementById('f-submit');
    btn.disabled = true;
    fetch(location.pathname.replace(/\\/+$/, '') + '/tips', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        method: methodInput.value,
        amountMinor: amount,
        name: name,
        message: document.getElementById('f-message').value,
        turnstileToken: token
      })
    }).then(function (res) {
      if (!res.ok) throw new Error('http ' + res.status);
      return res.json();
    }).then(function (data) {
      redirected = true;
      location.href = data.redirectUrl;
    }).catch(function () {
      btn.disabled = false;
      errEl.textContent = 'Something went wrong sending your message. You can still pay directly:';
      show(errEl);
      show(document.getElementById('f-fallback'));
      if (window.turnstile && window.turnstile.reset) window.turnstile.reset();
    });
  });
})();`;

const STYLE = `
:root { color-scheme: light dark; --accent: #e8542f; --bg: #faf6f1; --fg: #2b2018; --card: #ffffff; --muted: #8a7a6d; --line: #e7ddd3; }
@media (prefers-color-scheme: dark) { :root { --bg: #1c1713; --fg: #f3ece4; --card: #292219; --muted: #a2917f; --line: #3d332a; } }
* { box-sizing: border-box; margin: 0; }
body { background: var(--bg); color: var(--fg); font: 16px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif; display: flex; justify-content: center; padding: 24px 16px 40px; }
main { width: 100%; max-width: 420px; }
h1 { font-size: 1.6rem; margin: 8px 0 4px; overflow-wrap: anywhere; }
.msg { color: var(--muted); margin-bottom: 20px; overflow-wrap: anywhere; white-space: pre-wrap; }
.paybtn, button[data-method] { display: block; width: 100%; text-align: center; padding: 14px 16px; margin: 10px 0; border-radius: 14px; border: 1px solid var(--line); background: var(--card); color: var(--fg); font-size: 1.05rem; font-weight: 600; text-decoration: none; cursor: pointer; }
.paybtn.primary { background: var(--accent); border-color: var(--accent); color: #fff; }
form { margin-top: 20px; padding: 16px; border: 1px solid var(--line); border-radius: 14px; background: var(--card); }
form h2 { font-size: 1.1rem; margin-bottom: 12px; }
label { display: block; font-size: 0.85rem; color: var(--muted); margin: 10px 0 4px; }
input, textarea { width: 100%; padding: 10px 12px; border: 1px solid var(--line); border-radius: 10px; background: var(--bg); color: var(--fg); font: inherit; }
textarea { resize: vertical; min-height: 60px; }
.chips { display: flex; gap: 8px; margin-top: 6px; }
.chips button { flex: 1; padding: 8px 0; border-radius: 10px; border: 1px solid var(--line); background: var(--bg); color: var(--fg); cursor: pointer; font-weight: 600; }
#f-submit { width: 100%; margin-top: 14px; padding: 13px; border: 0; border-radius: 12px; background: var(--accent); color: #fff; font-size: 1.05rem; font-weight: 700; cursor: pointer; }
#f-submit:disabled { opacity: 0.6; }
#f-error { color: #c0392b; margin-top: 10px; font-size: 0.9rem; }
#f-fallback a { display: block; margin-top: 8px; color: var(--accent); }
#f-success { margin-top: 20px; padding: 20px 16px; border: 1px solid var(--accent); border-radius: 14px; background: var(--card); }
#f-success h2 { font-size: 1.2rem; margin-bottom: 8px; }
#f-success p { color: var(--muted); overflow-wrap: anywhere; }
.turnstile-slot { margin-top: 14px; min-height: 66px; }
footer { margin-top: 28px; font-size: 0.75rem; color: var(--muted); }
footer a { color: inherit; }
`;

/** How one method prices a tip: its currency, minor-unit factor, and bounds. */
function pricing(currency: string) {
  const zeroDecimal = ZERO_DECIMAL.has(currency);
  return {
    code: currency.toUpperCase(),
    factor: zeroDecimal ? 1 : 100,
    chips: zeroDecimal ? [500, 1000, 2000] : [2, 5, 10],
    ...amountBounds(currency),
  };
}

export function renderDonorPage(profile: JarProfile, siteKey: string): string {
  const name = escapeHtml(profile.artistName);
  const message = profile.message ? `<p class="msg">${escapeHtml(profile.message)}</p>` : "";
  const currency = profile.currency; // validated ^[a-z]{3}$

  // One pricing entry per offered method. MobilePay and Monzo bring their own
  // currency, so a single page can price a €-Box tip and a £-Monzo tip side by
  // side; the script swaps the field over when the donor picks one.
  const offered = TIP_METHODS.filter((m) => bareMethodUrl(profile, m) !== null);
  const priced = offered.map((m) => ({ method: m, price: pricing(methodCurrency(m, currency)) }));
  const methodPricing = Object.fromEntries(priced.map((p) => [p.method, p.price]));

  // The pre-selection default the label shows before any method is picked.
  const initial = pricing(currency);

  const LABELS: Record<string, string> = { revolut: "Revolut", mobilepay: "MobilePay", monzo: "Monzo" };

  const buttons: string[] = [];
  if (profile.methods.stripeUrl) {
    buttons.push(
      `<a class="paybtn primary" href="${escapeHtml(profile.methods.stripeUrl)}" rel="noopener">Card · Apple Pay · Google Pay</a>`,
    );
  }
  for (const { method, price } of priced) {
    const label = LABELS[method];
    // The currency rides on the button when it isn't the jar's own, so the
    // donor knows a Monzo tip is priced in pounds before they tap it.
    const suffix = price.code === initial.code ? "" : ` · ${price.code}`;
    buttons.push(
      `<button type="button" data-method="${method}" data-label="Tip with ${label}">${label}${suffix}</button>`,
    );
  }

  const fallbackLinks = offered.map(
    (m) => `<a href="${escapeHtml(bareMethodUrl(profile, m)!)}" rel="noopener">Open ${LABELS[m]}</a>`,
  );

  const hasForm = offered.length > 0;
  const form = hasForm
    ? `
<form id="tipform" hidden>
  <h2 id="f-title">Send a tip</h2>
  <input type="hidden" id="f-method" value="">
  <label id="f-amount-label" for="f-amount">Amount (${initial.code})</label>
  <input id="f-amount" inputmode="decimal" autocomplete="off" placeholder="${initial.chips[1]}" required>
  <div class="chips" id="f-chips"></div>
  <label for="f-name">Your name (optional)</label>
  <input id="f-name" maxlength="40" autocomplete="off" placeholder="Anonymous">
  <label for="f-message">Message (optional)</label>
  <textarea id="f-message" maxlength="200"></textarea>
  <div class="turnstile-slot"><div class="cf-turnstile" data-sitekey="${escapeHtml(siteKey)}"></div></div>
  <button id="f-submit" type="submit">Continue to payment</button>
  <p id="f-error" role="alert" aria-live="assertive" hidden></p>
  <div id="f-fallback" role="group" aria-live="polite" hidden>${fallbackLinks.join("")}</div>
</form>
<div id="f-success" role="status" aria-live="polite" hidden>
  <h2>Thanks! 🎉</h2>
  <p>Your message is on its way to the performer's screen. Finish the payment in <span id="f-success-app">the app</span> to complete your tip — you can close this page once you're done.</p>
</div>
<noscript><p>JavaScript is off — you can still pay directly:</p>${fallbackLinks.join("")}</noscript>`
    : "";

  const turnstileScript = hasForm
    ? `<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" defer></script>`
    : "";

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${name} — tip jar</title>
<style>${STYLE}</style>
</head>
<body>
<main data-methods="${escapeHtml(JSON.stringify(methodPricing))}">
  <h1>${name}</h1>
  ${message}
  ${buttons.join("\n  ")}
  ${form}
  <footer>
    Tips you send here go straight to the performer's screen. If their screen is
    away, your tip waits up to an hour for it and is then deleted unseen — live.tips
    keeps no donation history. The performer's name and payment methods are kept
    until they delete this page or after 90 days of inactivity.
    Powered by <a href="https://live.tips" rel="noopener">live.tips</a>.
  </footer>
</main>
${turnstileScript}
<script>${INLINE_SCRIPT}</script>
</body>
</html>`;
}

/** Uniform page for unknown, deleted, and expired jars alike (anti-enumeration). */
export function renderNotFoundPage(): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Tip jar not active — live.tips</title>
<style>${STYLE}</style>
</head>
<body>
<main>
  <h1>This tip jar isn't active</h1>
  <p class="msg">The link may have expired or been replaced. Ask the performer for their current QR code.</p>
  <footer>Powered by <a href="https://live.tips" rel="noopener">live.tips</a>.</footer>
</main>
</body>
</html>`;
}

let cspCache: string | null = null;

/** CSP for donor pages — inline-script hash computed from the real constant. */
export async function donorPageCsp(): Promise<string> {
  if (cspCache === null) {
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(INLINE_SCRIPT));
    const hash = btoa(String.fromCharCode(...new Uint8Array(digest)));
    cspCache = [
      "default-src 'none'",
      `script-src 'sha256-${hash}' https://challenges.cloudflare.com`,
      "frame-src https://challenges.cloudflare.com",
      "style-src 'unsafe-inline'",
      "connect-src 'self' https://challenges.cloudflare.com",
      "img-src 'self' data:",
      "base-uri 'none'",
      "form-action 'self'",
      "frame-ancestors 'none'",
    ].join("; ");
  }
  return cspCache;
}

/** Exported for the test that guards the "static script" invariant. */
export const _inlineScriptForTests = INLINE_SCRIPT;
