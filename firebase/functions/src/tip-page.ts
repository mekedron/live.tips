/// Server-rendered tip page. Two invariants keep it XSS-proof:
/// 1. every interpolated value passes through escapeHtml() (or is a number),
/// 2. the single inline <script> is a static constant — no template holes —
///    so its CSP hash is stable by construction. Page data reaches the
///    script only via escaped data-* attributes.

import { createHash } from "node:crypto";
import { bareMethodUrl } from "./deeplinks";
import { methodCurrency, TIP_METHODS } from "./methods";
import { amountBounds, escapeHtml, ZERO_DECIMAL } from "./validate";
import type { JarProfile, RequestsConfig, RequestsLive } from "./types";

/** Static — never interpolate into this string (it is hashed for CSP). */
const INLINE_SCRIPT = `(function () {
  var main = document.querySelector('main');
  var form = document.getElementById('tipform');
  // Per-method pricing: a Box always collects EUR and Monzo always GBP, so the
  // amount the fan types is denominated by the METHOD they picked, not by the
  // jar. Picking a method reprices the whole field.
  var methods = JSON.parse(main.getAttribute('data-methods'));
  // Song requests (#64): everything the section needs rides one escaped
  // attribute. No attribute = no section = nothing to wire up.
  var reqAttr = main.getAttribute('data-requests');
  var req = reqAttr ? JSON.parse(reqAttr) : null;
  var reqSection = document.getElementById('requests');
  var current = null;
  var reqMode = false;
  var reqSong = null;
  var votes = 1;
  var methodInput = document.getElementById('f-method');
  var amountEl = document.getElementById('f-amount');
  var labelEl = document.getElementById('f-amount-label');
  var chipsEl = document.getElementById('f-chips');
  var errEl = document.getElementById('f-error');
  var successEl = document.getElementById('f-success');
  var reqInfoEl = document.getElementById('f-reqinfo');
  var redirected = false;
  function show(el) { el.removeAttribute('hidden'); }
  function hide(el) { el.setAttribute('hidden', ''); }
  // Mirrors the server's formatMinor — the poll must repaint a standing into
  // exactly the string the server rendered, or every refresh flickers.
  function fmt(minor) {
    var v = minor / req.factor;
    return req.factor === 1 || v === Math.round(v) ? String(v) : v.toFixed(2);
  }
  function songPrice(song) {
    return song.priceMinor !== undefined ? song.priceMinor : req.defaultPriceMinor;
  }
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
  if (form) {
    document.addEventListener('visibilitychange', function () {
      if (redirected && document.visibilityState === 'visible') showSuccess();
    });
    Array.prototype.forEach.call(document.querySelectorAll('button[data-method]'), function (btn) {
      btn.addEventListener('click', function () {
        reqMode = false;
        methodInput.value = btn.getAttribute('data-method');
        document.getElementById('f-title').textContent = btn.getAttribute('data-label');
        show(labelEl);
        show(amountEl);
        show(chipsEl);
        amountEl.required = true;
        if (reqInfoEl) hide(reqInfoEl);
        reprice(btn.getAttribute('data-method'));
        show(form);
        form.scrollIntoView({ behavior: 'smooth', block: 'start' });
        amountEl.focus();
      });
    });
    form.addEventListener('submit', function (ev) {
      ev.preventDefault();
      hide(errEl);
      if (reqMode ? !reqSong : !current) return;
      var name = document.getElementById('f-name').value.trim();
      if (name.indexOf(':') !== -1) {
        errEl.textContent = 'Please leave the ":" character out of your name.';
        show(errEl);
        return;
      }
      var body = {
        method: methodInput.value,
        name: name,
        message: document.getElementById('f-message').value
      };
      if (reqMode) {
        // Request mode: songId + votes in, NO amount — the server prices the
        // request from its own config and refuses a fan-sent amount.
        body.songId = reqSong.id;
        body.votes = votes;
      } else {
        var amount = Math.round(parseFloat(amountEl.value.replace(',', '.')) * current.factor);
        if (!isFinite(amount) || amount < current.min || amount > current.max) {
          errEl.textContent = 'Please enter a valid amount.';
          show(errEl);
          return;
        }
        body.amountMinor = amount;
      }
      var tokenEl = form.querySelector('[name="cf-turnstile-response"]');
      var token = tokenEl ? tokenEl.value : '';
      if (!token) {
        errEl.textContent = 'Please complete the verification above.';
        show(errEl);
        return;
      }
      body.turnstileToken = token;
      var btn = document.getElementById('f-submit');
      btn.disabled = true;
      fetch(location.pathname.replace(/\\/+$/, '') + '/tips', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(body)
      }).then(function (res) {
        if (!res.ok) {
          var e = new Error('http ' + res.status);
          e.status = res.status;
          throw e;
        }
        return res.json();
      }).then(function (data) {
        redirected = true;
        location.href = data.redirectUrl;
      }).catch(function (e) {
        btn.disabled = false;
        if (reqMode && e && e.status === 409) {
          // The window closed under a stale page: nothing to retry — drop the
          // section and leave the plain tip flow standing.
          errEl.textContent = 'Song requests just closed. You can still send a regular tip.';
          show(errEl);
          if (reqSection) hide(reqSection);
        } else {
          errEl.textContent = 'Something went wrong sending your message. You can still pay directly:';
          show(errEl);
          if (!reqMode) show(document.getElementById('f-fallback'));
        }
        if (window.turnstile && window.turnstile.reset) window.turnstile.reset();
      });
    });
  }
  if (req && reqSection) {
    var panel = document.getElementById('req-panel');
    var votesEl = document.getElementById('r-votes');
    var totalEl = document.getElementById('r-total');
    var songEl = document.getElementById('r-song');
    var stripeEl = document.getElementById('r-stripe');
    var stripeHintEl = document.getElementById('r-stripe-hint');
    var refreshTotal = function () {
      votesEl.textContent = String(votes);
      var line = votes + ' × ' + fmt(songPrice(reqSong)) + ' ' + req.currency +
        ' = ' + fmt(songPrice(reqSong) * votes) + ' ' + req.currency;
      totalEl.textContent = line;
      if (reqInfoEl) reqInfoEl.textContent = reqSong.title + ' · ' + line;
    };
    // 50 mirrors the server's MAX_REQUEST_VOTES (this script is static — no holes).
    document.getElementById('r-minus').addEventListener('click', function () {
      if (reqSong && votes > 1) { votes -= 1; refreshTotal(); }
    });
    document.getElementById('r-plus').addEventListener('click', function () {
      if (reqSong && votes < 50) { votes += 1; refreshTotal(); }
    });
    Array.prototype.forEach.call(reqSection.querySelectorAll('button.song'), function (card) {
      card.addEventListener('click', function () {
        var id = card.getAttribute('data-song');
        reqSong = null;
        req.songs.forEach(function (s) { if (s.id === id) reqSong = s; });
        if (!reqSong) return;
        votes = 1;
        songEl.textContent = reqSong.title + (reqSong.artist ? ' — ' + reqSong.artist : '');
        if (stripeEl) {
          if (reqSong.stripeUrl) {
            stripeEl.href = reqSong.stripeUrl;
            show(stripeEl);
            show(stripeHintEl);
          } else {
            hide(stripeEl);
            hide(stripeHintEl);
          }
        }
        refreshTotal();
        show(panel);
        panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
      });
    });
    Array.prototype.forEach.call(document.querySelectorAll('button[data-reqmethod]'), function (btn) {
      btn.addEventListener('click', function () {
        if (!form || !reqSong) return;
        reqMode = true;
        current = null;
        methodInput.value = btn.getAttribute('data-reqmethod');
        document.getElementById('f-title').textContent = 'Request: ' + reqSong.title;
        // The computed votes × price readout replaces the amount input.
        hide(labelEl);
        hide(amountEl);
        hide(chipsEl);
        amountEl.required = false;
        if (reqInfoEl) show(reqInfoEl);
        refreshTotal();
        show(form);
        form.scrollIntoView({ behavior: 'smooth', block: 'start' });
      });
    });
    var applyQueue = function (data) {
      if (!data.open) { hide(reqSection); return; }
      show(reqSection);
      var byId = {};
      data.songs.forEach(function (s) { byId[s.id] = s; });
      Array.prototype.forEach.call(reqSection.querySelectorAll('button.song'), function (card) {
        var e = byId[card.getAttribute('data-song')];
        var standing = card.querySelector('.song-standing');
        var badge = card.querySelector('.song-badge');
        if (e && e.count > 0) {
          standing.textContent = fmt(e.totalMinor) + ' ' + req.currency + ' · ' +
            e.count + (e.count === 1 ? ' fan' : ' fans');
          show(standing);
        } else {
          standing.textContent = '';
          hide(standing);
        }
        if (e && (e.status === 'p' || e.status === 'k')) {
          badge.textContent = e.status === 'p' ? 'Played' : 'Skipped';
          show(badge);
          card.classList.add('done');
        } else {
          hide(badge);
          card.classList.remove('done');
        }
      });
    };
    var poll = function () {
      if (document.visibilityState !== 'visible') return;
      fetch(location.pathname.replace(/\\/+$/, '') + '/queue').then(function (res) {
        if (!res.ok) throw new Error('http ' + res.status);
        return res.json();
      }).then(applyQueue).catch(function () {});
    };
    setInterval(poll, 15000);
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') poll();
    });
  }
})();`;

const STYLE = `
:root { color-scheme: light dark; --accent: #e8542f; --bg: #faf6f1; --fg: #2b2018; --card: #ffffff; --muted: #8a7a6d; --line: #e7ddd3; }
@media (prefers-color-scheme: dark) { :root { --bg: #1c1713; --fg: #f3ece4; --card: #292219; --muted: #a2917f; --line: #3d332a; } }
* { box-sizing: border-box; margin: 0; }
[hidden] { display: none !important; }
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
#f-reqinfo { font-weight: 600; margin-top: 10px; }
#f-success { margin-top: 20px; padding: 20px 16px; border: 1px solid var(--accent); border-radius: 14px; background: var(--card); }
#f-success h2 { font-size: 1.2rem; margin-bottom: 8px; }
#f-success p { color: var(--muted); overflow-wrap: anywhere; }
.turnstile-slot { margin-top: 14px; min-height: 66px; }
#requests { margin-top: 28px; }
#requests h2 { font-size: 1.2rem; margin-bottom: 2px; }
.req-hint { color: var(--muted); font-size: 0.85rem; margin-bottom: 6px; }
button.song { display: block; width: 100%; text-align: left; padding: 12px 14px; margin: 8px 0; border-radius: 14px; border: 1px solid var(--line); background: var(--card); color: var(--fg); font: inherit; cursor: pointer; }
button.song.done { opacity: 0.55; }
.song-title { font-weight: 600; overflow-wrap: anywhere; }
.song-artist { color: var(--muted); overflow-wrap: anywhere; }
.song-artist::before { content: " — "; }
.song-price { display: block; color: var(--muted); font-size: 0.85rem; }
.song-standing { color: var(--accent); font-size: 0.85rem; font-weight: 600; margin-right: 8px; }
.song-badge { font-size: 0.7rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); border: 1px solid var(--line); border-radius: 8px; padding: 1px 6px; }
#req-panel { margin-top: 12px; padding: 16px; border: 1px solid var(--line); border-radius: 14px; background: var(--card); }
#r-song { font-weight: 600; overflow-wrap: anywhere; }
.stepper { display: flex; align-items: center; gap: 14px; margin: 10px 0; }
.stepper button { width: 44px; height: 44px; border-radius: 12px; border: 1px solid var(--line); background: var(--bg); color: var(--fg); font-size: 1.3rem; cursor: pointer; }
#r-votes { font-size: 1.2rem; font-weight: 700; min-width: 2ch; text-align: center; }
#r-total { color: var(--muted); margin-bottom: 4px; }
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

/**
 * Minor units → the human string the page shows ("3", "5.50", or "500" on a
 * zero-decimal currency). The inline script carries the same logic (fmt) so a
 * queue poll repaints a standing into exactly the server-rendered string.
 */
function formatMinor(minor: number, factor: number): string {
  const v = minor / factor;
  return factor === 1 || Number.isInteger(v) ? String(v) : v.toFixed(2);
}

export function renderTipPage(
  profile: JarProfile,
  siteKey: string,
  requestsConfig?: RequestsConfig,
  requestsLive?: RequestsLive,
): string {
  const name = escapeHtml(profile.artistName);
  const message = profile.message ? `<p class="msg">${escapeHtml(profile.message)}</p>` : "";
  const currency = profile.currency; // validated ^[a-z]{3}$

  // One pricing entry per offered method. MobilePay and Monzo bring their own
  // currency, so a single page can price a €-Box tip and a £-Monzo tip side by
  // side; the script swaps the field over when the fan picks one.
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
    // fan knows a Monzo tip is priced in pounds before they tap it.
    const suffix = price.code === initial.code ? "" : ` · ${price.code}`;
    buttons.push(
      `<button type="button" data-method="${method}" data-label="Tip with ${label}">${label}${suffix}</button>`,
    );
  }

  const fallbackLinks = offered.map(
    (m) => `<a href="${escapeHtml(bareMethodUrl(profile, m)!)}" rel="noopener">Open ${LABELS[m]}</a>`,
  );

  const hasForm = offered.length > 0;

  // ------------------------------------------------------ song requests (#64)
  // The section renders ONLY while the sale is actually on: enabled config AND
  // an unexpired window — the exact gate the POST enforces (409 otherwise).
  // When it doesn't render, the page is byte-for-byte the plain tip page.
  const requestsOpen =
    requestsConfig?.enabled === true && (requestsLive?.openUntilMs ?? 0) > Date.now();

  let requestsAttr = "";
  let requestsSection = "";
  let requestsFormInfo = "";
  if (requestsOpen && requestsConfig && requestsLive) {
    // `songs` can be missing on the stored doc: setJarRequests arms `open` at
    // go-live before the leader has published any queue. Never trust the shape.
    const liveSongs = requestsLive.songs ?? {};
    const stripeRequests = requestsConfig.methods.includes("stripe");
    // Relay methods a request may ride: offered on the jar, listed by the
    // artist, AND collecting the jar's own currency (requests are priced in
    // it — the POST refuses the rest, so the page never shows them).
    const relayMethods = priced
      .filter((p) => requestsConfig.methods.includes(p.method) && p.price.code === initial.code)
      .map((p) => p.method);
    const fmt = (minor: number) => formatMinor(minor, initial.factor);

    const cards = requestsConfig.songs.map((song) => {
      const entry = liveSongs[song.id];
      const done = entry !== undefined && (entry.s === "p" || entry.s === "k");
      const badge = entry?.s === "p" ? "Played" : entry?.s === "k" ? "Skipped" : "";
      const standing =
        entry !== undefined && entry.c > 0
          ? `${fmt(entry.t)} ${initial.code} · ${entry.c} ${entry.c === 1 ? "fan" : "fans"}`
          : "";
      const artist = song.artist ? `<span class="song-artist">${escapeHtml(song.artist)}</span>` : "";
      return `<button type="button" class="song${done ? " done" : ""}" data-song="${escapeHtml(song.id)}">
    <span class="song-title">${escapeHtml(song.title)}</span>${artist}
    <span class="song-price">${fmt(song.priceMinor ?? requestsConfig.defaultPriceMinor)} ${initial.code}</span>
    <span class="song-standing"${standing ? "" : " hidden"}>${standing}</span>
    <span class="song-badge"${badge ? "" : " hidden"}>${badge}</span>
  </button>`;
    });

    const methodButtons = relayMethods.map(
      (m) => `<button type="button" class="paybtn" data-reqmethod="${m}">Request with ${LABELS[m]}</button>`,
    );
    // One shared anchor; the script points it at the tapped song's own
    // payment link (validated buy|donate.stripe.com, riding the escaped JSON).
    const stripeSlot =
      stripeRequests && requestsConfig.songs.some((s) => s.stripeUrl !== undefined)
        ? `
    <a id="r-stripe" class="paybtn primary" rel="noopener" hidden>Card · Apple Pay · Google Pay</a>
    <p id="r-stripe-hint" class="req-hint" hidden>On the payment page, set the quantity to your number of votes.</p>`
        : "";

    requestsSection = `
  <section id="requests">
    <h2>Request a song</h2>
    <p class="req-hint">Pick a song and chip in — every vote pushes it up the queue.</p>
    ${cards.join("\n    ")}
    <div id="req-panel" hidden>
      <p id="r-song"></p>
      <div class="stepper">
        <button type="button" id="r-minus" aria-label="Fewer votes">−</button>
        <span id="r-votes">1</span>
        <button type="button" id="r-plus" aria-label="More votes">+</button>
      </div>
      <p id="r-total" aria-live="polite"></p>
      ${methodButtons.join("\n      ")}${stripeSlot}
    </div>
  </section>`;

    // Everything the inline script needs, on one escaped attribute (the same
    // channel data-methods uses). stripeUrl only travels when "stripe" is an
    // accepted request method — otherwise the script must not offer it.
    const reqJson = {
      currency: initial.code,
      factor: initial.factor,
      defaultPriceMinor: requestsConfig.defaultPriceMinor,
      methods: relayMethods,
      songs: requestsConfig.songs.map((s) => ({
        id: s.id,
        title: s.title,
        ...(s.artist !== undefined ? { artist: s.artist } : {}),
        ...(s.priceMinor !== undefined ? { priceMinor: s.priceMinor } : {}),
        ...(stripeRequests && s.stripeUrl !== undefined ? { stripeUrl: s.stripeUrl } : {}),
      })),
      queue: liveSongs,
    };
    requestsAttr = ` data-requests="${escapeHtml(JSON.stringify(reqJson))}"`;
    // The votes × price readout that stands in for the amount input.
    if (hasForm) requestsFormInfo = `\n  <p id="f-reqinfo" hidden></p>`;
  }

  const form = hasForm
    ? `
<form id="tipform" hidden>
  <h2 id="f-title">Send a tip</h2>
  <input type="hidden" id="f-method" value="">
  <label id="f-amount-label" for="f-amount">Amount (${initial.code})</label>
  <input id="f-amount" inputmode="decimal" autocomplete="off" placeholder="${initial.chips[1]}" required>
  <div class="chips" id="f-chips"></div>${requestsFormInfo}
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
<main data-methods="${escapeHtml(JSON.stringify(methodPricing))}"${requestsAttr}>
  <h1>${name}</h1>
  ${message}
  ${buttons.join("\n  ")}
  ${form}${requestsSection}
  <footer>
    Tips you send here go straight to the performer's screen. If their screen is
    away, your tip waits up to an hour for it and is then deleted unseen — live.tips
    keeps no tip history. The performer's name and payment methods are kept
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

/** CSP for tip pages — inline-script hash computed from the real constant. */
export function tipPageCsp(): string {
  if (cspCache === null) {
    const hash = createHash("sha256").update(INLINE_SCRIPT, "utf8").digest("base64");
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
