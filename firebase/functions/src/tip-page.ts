/// Server-rendered tip page. Two invariants keep it XSS-proof:
/// 1. markup is built with the html`` tagged template, which escapes every
///    ${value} by construction — the only unescaped holes are raw() (static
///    CSS/JS, never fan input);
/// 2. the single inline <script> is a static constant — no template holes —
///    so its CSP hash is stable. Page data reaches the script only via the
///    escaped data-* attributes on <main>.
///
/// The fan-facing flow is a linear stepper (no modals): a progress bar under
/// the tabs drives Back. Tip = [amount+method] → [details]; Song requests =
/// [pick a song] → [votes+method] → [details]. Card/Stripe skips straight out.

import { createHash } from "node:crypto";
import { bareMethodUrl } from "./deeplinks";
import { html, raw, SafeHtml } from "./html";
import { methodCurrency, TIP_METHODS } from "./methods";
import { amountBounds, escapeHtml, ZERO_DECIMAL } from "./validate";
import type { JarProfile, RequestsConfig, RequestsLive } from "./types";

/** Static — never interpolate into this string (it is hashed for CSP). */
const INLINE_SCRIPT = `(function () {
  var main = document.querySelector('main');
  function id(x) { return document.getElementById(x); }
  function show(el) { if (el) el.removeAttribute('hidden'); }
  function hide(el) { if (el) el.setAttribute('hidden', ''); }
  function isDesktop() { return window.matchMedia('(min-width: 768px)').matches; }
  function money(minor, p) {
    var v = minor / p.factor;
    var num = p.factor === 1 || v === Math.round(v) ? String(v) : v.toFixed(2);
    return p.symLeads ? p.sym + num : num + ' ' + p.sym;
  }

  var methods = JSON.parse(main.getAttribute('data-methods'));
  var reqAttr = main.getAttribute('data-requests');
  var req = reqAttr ? JSON.parse(reqAttr) : null;

  var card = main.querySelector('.card');
  var tabsEl = main.querySelector('.tabs');
  var tabTip = id('tab-tip');
  var tabReq = id('tab-requests');
  var progressEl = id('progress');
  var progSegs = id('prog-segs');
  var progBack = id('prog-back');

  var detailsEl = id('s-details');
  var form = detailsEl;
  var amountEl = id('f-amount');
  var chipsEl = id('f-chips');
  var symPre = id('f-sym-pre');
  var symPost = id('f-sym-post');
  var ctaEl = id('tip-cta');
  var tipErrEl = id('tip-error');
  var methodListEl = id('method-list');
  var methodInput = id('f-method');
  var titleEl = id('f-title');
  var submitEl = id('f-submit');
  var errEl = id('f-error');
  var fallbackEl = id('f-fallback');
  var successEl = id('success');

  // Every step section, and the ordered flows over them. The details step only
  // exists when a relay method does (card/Stripe never collects a name here).
  var ALL = ['s-tip', 's-songs', 's-votes', 's-details'];
  var hasDetails = !!detailsEl;
  var STEPS = {
    tip: hasDetails ? ['s-tip', 's-details'] : ['s-tip'],
    request: hasDetails ? ['s-songs', 's-votes', 's-details'] : ['s-songs', 's-votes']
  };
  var flow = 'tip';
  var stepIdx = 0;

  var current = null;    // pricing of the selected tip method
  var currentKey = null; // 'card' | 'revolut' | 'mobilepay' | 'monzo'
  var currentLabel = '';
  var isCard = false;
  var cardHref = '';
  var mode = 'tip';      // 'tip' | 'request'
  var reqSong = null;
  var votes = 1;
  var redirected = false;
  var paintSuccessQueue = function () {};

  function updateProgress() {
    var steps = STEPS[flow];
    if (!progressEl || steps.length <= 1) { hide(progressEl); return; }
    show(progressEl);
    progSegs.textContent = '';
    for (var i = 0; i < steps.length; i++) {
      var seg = document.createElement('span');
      seg.className = 'seg' + (i <= stepIdx ? ' on' : '');
      progSegs.appendChild(seg);
    }
    // visibility (not display) so the left arrow keeps its slot on step 1 —
    // the transparent right mirror then balances it and the segments stay centred.
    progBack.style.visibility = stepIdx > 0 ? '' : 'hidden';
  }
  function renderStep() {
    ALL.forEach(function (x) { hide(id(x)); });
    hide(successEl);
    show(id(STEPS[flow][stepIdx]));
    updateProgress();
    window.scrollTo(0, 0);
  }
  function goStep(name) {
    var i = STEPS[flow].indexOf(name);
    if (i >= 0) { stepIdx = i; renderStep(); }
  }
  function setFlow(f) {
    if (!STEPS[f]) return;
    flow = f;
    stepIdx = 0;
    if (tabTip && tabReq) {
      var t = f === 'tip';
      tabTip.classList.toggle('active', t); tabTip.setAttribute('aria-selected', String(t));
      tabReq.classList.toggle('active', !t); tabReq.setAttribute('aria-selected', String(!t));
    }
    renderStep();
  }
  if (progBack) progBack.addEventListener('click', function () { if (stepIdx > 0) { stepIdx -= 1; renderStep(); } });
  if (tabTip) tabTip.addEventListener('click', function () { setFlow('tip'); });
  if (tabReq) tabReq.addEventListener('click', function () { setFlow('request'); });

  // -------------------------------------------------------------- tip step
  function parseAmount() {
    if (!current) return null;
    var a = Math.round(parseFloat((amountEl.value || '').replace(',', '.')) * current.factor);
    if (!isFinite(a) || a < current.min || a > current.max) return null;
    return a;
  }
  function sizeAmount() {
    var len = amountEl.value.length || String(amountEl.placeholder).length || 1;
    amountEl.style.width = (len + 0.5) + 'ch';
  }
  function updateCta() {
    if (!current) return;
    if (isCard) { ctaEl.textContent = 'Pay with card →'; return; }
    var a = parseAmount();
    ctaEl.textContent = a !== null
      ? 'Tip ' + money(a, current) + ' with ' + currentLabel + ' →'
      : 'Tip with ' + currentLabel + ' →';
  }
  function applySymbol(p) {
    if (p.symLeads) { symPre.textContent = p.sym; show(symPre); hide(symPost); }
    else { symPost.textContent = p.sym; show(symPost); hide(symPre); }
  }
  function buildChips(p) {
    chipsEl.textContent = '';
    p.chips.forEach(function (c) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'chip';
      b.textContent = money(c * p.factor, p);
      b.addEventListener('click', function () { amountEl.value = String(c); sizeAmount(); updateCta(); });
      chipsEl.appendChild(b);
    });
    var other = document.createElement('button');
    other.type = 'button';
    other.className = 'chip other';
    other.textContent = 'Other';
    other.addEventListener('click', function () { amountEl.value = ''; sizeAmount(); amountEl.focus(); updateCta(); });
    chipsEl.appendChild(other);
  }
  function selectMethod(btn) {
    currentKey = btn.getAttribute('data-method');
    current = methods[currentKey];
    isCard = currentKey === 'card';
    cardHref = btn.getAttribute('data-href') || '';
    currentLabel = btn.getAttribute('data-label') || '';
    Array.prototype.forEach.call(methodListEl.querySelectorAll('.method'), function (m) { m.classList.remove('selected'); });
    btn.classList.add('selected');
    applySymbol(current);
    buildChips(current);
    // Pre-fill the middle preset so the amount is a real value from the start.
    amountEl.value = String(current.chips[1]);
    sizeAmount();
    updateCta();
  }
  function openStripe(href) {
    if (!href) return;
    if (isDesktop()) window.open(href, '_blank', 'noopener');
    else location.href = href;
  }
  function openDetails(title) {
    hide(errEl);
    hide(fallbackEl);
    titleEl.textContent = title;
    submitEl.textContent = 'Open ' + currentLabel + ' →';
    submitEl.disabled = false;
    goStep('s-details');
  }

  if (methodListEl) {
    Array.prototype.forEach.call(methodListEl.querySelectorAll('.method'), function (btn) {
      btn.addEventListener('click', function () { selectMethod(btn); });
    });
    var firstMethod = methodListEl.querySelector('.method');
    if (firstMethod) selectMethod(firstMethod);
    amountEl.addEventListener('input', function () { sizeAmount(); updateCta(); });
    ctaEl.addEventListener('click', function () {
      hide(tipErrEl);
      if (isCard) { openStripe(cardHref); return; }
      if (parseAmount() === null) {
        tipErrEl.textContent = 'Please enter a valid amount first.';
        show(tipErrEl);
        amountEl.focus();
        return;
      }
      mode = 'tip';
      methodInput.value = currentKey;
      openDetails('Tip ' + money(parseAmount(), current) + ' with ' + currentLabel);
    });
  }

  // ------------------------------------------------------------ details step
  if (form) {
    document.addEventListener('visibilitychange', function () {
      if (redirected && document.visibilityState === 'visible') showSuccess();
    });
    form.addEventListener('submit', function (ev) {
      ev.preventDefault();
      hide(errEl);
      var name = id('f-name').value.trim();
      if (name.indexOf(':') !== -1) {
        errEl.textContent = 'Please leave the ":" character out of your name.';
        show(errEl);
        return;
      }
      var body = { method: methodInput.value, name: name, message: id('f-message').value };
      if (mode === 'request') {
        body.songId = reqSong.id;
        body.votes = votes;
      } else {
        var a = parseAmount();
        if (a === null) { errEl.textContent = 'Please enter a valid amount.'; show(errEl); return; }
        body.amountMinor = a;
      }
      var tokenEl = form.querySelector('[name="cf-turnstile-response"]');
      var token = tokenEl ? tokenEl.value : '';
      if (!token) { errEl.textContent = 'Please complete the verification above.'; show(errEl); return; }
      body.turnstileToken = token;
      submitEl.disabled = true;
      fetch(location.pathname.replace(/\\/+$/, '') + '/tips', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(body)
      }).then(function (res) {
        if (!res.ok) { var e = new Error('http ' + res.status); e.status = res.status; throw e; }
        return res.json();
      }).then(function (data) {
        redirected = true;
        location.href = data.redirectUrl;
      }).catch(function (e) {
        submitEl.disabled = false;
        if (mode === 'request' && e && e.status === 409) {
          // The window closed under a stale page: drop the requests side and
          // land the fan back on the tip flow with the message showing there.
          if (tabReq) hide(tabReq);
          setFlow('tip');
          tipErrEl.textContent = 'Song requests just closed. You can still send a regular tip.';
          show(tipErrEl);
        } else {
          errEl.textContent = 'Something went wrong sending your message. You can still pay directly:';
          show(errEl);
          if (mode !== 'request') show(fallbackEl);
        }
        if (window.turnstile && window.turnstile.reset) window.turnstile.reset();
      });
    });
  }

  function showSuccess() {
    if (!successEl) return;
    var isReq = mode === 'request';
    id('success-app').textContent = currentLabel || 'the app';
    id('success-title').textContent = isReq ? 'Request sent!' : 'You tipped!';
    id('success-icon').textContent = isReq ? '♪' : '✓';
    var q = id('success-queue');
    if (q) { if (isReq && req) { paintSuccessQueue(q); show(q); } else hide(q); }
    ALL.forEach(function (x) { hide(id(x)); });
    hide(progressEl);
    if (tabsEl) hide(tabsEl);
    show(successEl);
    successEl.classList.add('confetti-play');
    setTimeout(function () { successEl.classList.remove('confetti-play'); }, 2600);
    window.scrollTo(0, 0);
  }
  var doneBtn = successEl && successEl.querySelector('[data-done]');
  if (doneBtn) {
    doneBtn.addEventListener('click', function () {
      hide(successEl);
      if (tabsEl) show(tabsEl);
      stepIdx = 0;
      renderStep();
    });
  }

  // ------------------------------------------------------------ song requests
  var reqSection = id('requests');
  if (req && reqSection) {
    req.songs.forEach(function (s, i) { s.idx = i; });
    var byId = {};
    Object.keys(req.queue || {}).forEach(function (k) {
      var e = req.queue[k];
      byId[k] = { t: e.t, c: e.c, s: e.s };
    });

    var votesEl = id('r-votes');
    var totalEl = id('r-total');
    var songEl = id('r-song');
    var standingEl = id('r-standing');
    var rankEl = id('r-rank');
    var reqMethodListEl = id('req-method-list');
    var reqContinueEl = id('req-continue');
    var searchEl = id('req-search');
    var groupUp = id('grp-up');
    var groupRest = id('grp-rest');
    var groupDone = id('grp-done');
    var groupUpTitle = id('grp-up-title');
    var groupRestTitle = id('grp-rest-title');
    var reqChoice = null;

    function songPrice(s) { return s.priceMinor !== undefined ? s.priceMinor : req.defaultPriceMinor; }
    function isDone(e) { return !!(e && (e.s === 'p' || e.s === 'k')); }
    // Where THIS song would land if the fan added v votes: 1 + everyone whose
    // live total still beats the projected one (ties fall to the earlier song).
    function projectedRank(song, v) {
      var e0 = byId[song.id];
      var mine = (e0 ? e0.t : 0) + v * songPrice(song);
      var rank = 1;
      req.songs.forEach(function (s) {
        if (s.id === song.id) return;
        var e = byId[s.id];
        if (!e || e.c <= 0 || isDone(e)) return;
        if (e.t > mine || (e.t === mine && s.idx < song.idx)) rank += 1;
      });
      return rank;
    }
    function updateRank() {
      if (!reqSong || !rankEl) return;
      var proj = projectedRank(reqSong, votes);
      var top = proj === 1;
      rankEl.classList.toggle('top', top);
      rankEl.textContent = '';
      var lead = document.createElement('span');
      var num = document.createElement('span');
      num.className = 'rank-num';
      num.textContent = '#' + proj;
      if (top) {
        lead.textContent = 'Next to play —';
        rankEl.appendChild(lead);
        rankEl.appendChild(num);
      } else {
        lead.textContent = "You'd be";
        var tail = document.createElement('span');
        tail.textContent = 'in the queue';
        rankEl.appendChild(lead);
        rankEl.appendChild(num);
        rankEl.appendChild(tail);
      }
    }
    function rankedUp() {
      var up = req.songs.filter(function (s) {
        var e = byId[s.id];
        return e && e.c > 0 && !isDone(e);
      });
      up.sort(function (a, b) { return (byId[b.id].t - byId[a.id].t) || (a.idx - b.idx); });
      return up;
    }
    function songSort(a, b) {
      var ea = byId[a.id] || { t: 0, c: 0, s: 'q' };
      var eb = byId[b.id] || { t: 0, c: 0, s: 'q' };
      var da = isDone(ea), db = isDone(eb);
      if (da !== db) return da ? 1 : -1;
      var ha = ea.c > 0, hb = eb.c > 0;
      if (ha !== hb) return ha ? -1 : 1;
      if (ea.t !== eb.t) return eb.t - ea.t;
      return a.idx - b.idx;
    }
    function renderSongs() {
      var q = (searchEl && searchEl.value || '').trim().toLowerCase();
      var up = rankedUp();
      var anyUp = false, anyRest = false;
      req.songs.slice().sort(songSort).forEach(function (s) {
        var cardEl = reqSection.querySelector('button.song[data-song="' + s.id + '"]');
        if (!cardEl) return;
        var e = byId[s.id];
        var matches = !q || (s.title + ' ' + (s.artist || '')).toLowerCase().indexOf(q) !== -1;
        if (!matches) { hide(cardEl); return; }
        show(cardEl);
        var done = isDone(e);
        var hasVotes = !!(e && e.c > 0);
        var standing = cardEl.querySelector('.song-standing');
        var badge = cardEl.querySelector('.song-badge');
        var action = cardEl.querySelector('.song-action');
        var rankNode = cardEl.querySelector('.song-rank');
        // A played/skipped song can't be donated to — no clicks, no action.
        cardEl.classList.toggle('done', done);
        cardEl.disabled = done;
        if (hasVotes && !done) {
          standing.textContent = money(e.t, req) + ' · ' + e.c + (e.c === 1 ? ' fan' : ' fans');
          show(standing);
        } else { standing.textContent = ''; hide(standing); }
        if (done) { badge.textContent = e.s === 'p' ? 'Played' : 'Skipped'; show(badge); } else hide(badge);
        if (rankNode) {
          var rank = hasVotes && !done ? up.indexOf(s) + 1 : 0;
          rankNode.textContent = rank > 0 ? String(rank) : '';
        }
        if (action) {
          if (done) hide(action);
          else {
            show(action);
            action.textContent = hasVotes ? 'Boost' : 'Request · ' + money(songPrice(s), req);
            action.classList.toggle('boost', hasVotes);
          }
        }
        var target = done ? groupDone : (hasVotes ? groupUp : groupRest);
        if (target) target.appendChild(cardEl);
        if (target === groupUp) anyUp = true;
        if (target === groupRest) anyRest = true;
      });
      if (groupUpTitle) (anyUp ? show : hide)(groupUpTitle);
      if (groupRestTitle) (anyRest ? show : hide)(groupRestTitle);
    }
    renderSongs();
    if (searchEl) searchEl.addEventListener('input', renderSongs);

    function refreshTotal() {
      votesEl.textContent = votes + (votes === 1 ? ' vote' : ' votes');
      totalEl.textContent = votes + ' × ' + money(songPrice(reqSong), req) + ' = ' + money(songPrice(reqSong) * votes, req);
      updateRank();
    }
    function updateReqContinue() {
      if (!reqChoice) { reqContinueEl.textContent = 'Continue'; return; }
      reqContinueEl.textContent = reqChoice.getAttribute('data-reqmethod') === 'stripe'
        ? 'Pay ' + money(songPrice(reqSong) * votes, req) + ' with card →'
        : 'Continue with ' + (reqChoice.getAttribute('data-label') || '') + ' →';
    }
    id('r-minus').addEventListener('click', function () { if (reqSong && votes > 1) { votes -= 1; refreshTotal(); updateReqContinue(); } });
    id('r-plus').addEventListener('click', function () { if (reqSong && votes < 50) { votes += 1; refreshTotal(); updateReqContinue(); } });

    Array.prototype.forEach.call(reqSection.querySelectorAll('button.song'), function (cardEl) {
      cardEl.addEventListener('click', function () {
        if (cardEl.disabled) return;
        var sid = cardEl.getAttribute('data-song');
        reqSong = null;
        req.songs.forEach(function (s) { if (s.id === sid) reqSong = s; });
        if (!reqSong) return;
        var e = byId[reqSong.id];
        if (isDone(e)) return; // played/skipped — not donatable
        votes = 1;
        songEl.textContent = (e && e.c > 0 ? 'Boost ' : 'Request ') + reqSong.title;
        standingEl.textContent = e && e.c > 0
          ? 'Currently #' + (rankedUp().indexOf(reqSong) + 1) + ' · ' + money(e.t, req) + ' from ' + e.c + (e.c === 1 ? ' fan' : ' fans')
          : 'Be the first to request this song';
        var stripeRadio = reqMethodListEl.querySelector('[data-reqmethod="stripe"]');
        if (stripeRadio) (reqSong.stripeUrl ? show : hide)(stripeRadio);
        Array.prototype.forEach.call(reqMethodListEl.querySelectorAll('.method'), function (m) { m.classList.remove('selected'); });
        reqChoice = reqMethodListEl.querySelector('.method:not([hidden])');
        if (reqChoice) reqChoice.classList.add('selected');
        refreshTotal();
        updateReqContinue();
        goStep('s-votes');
      });
    });
    Array.prototype.forEach.call(reqMethodListEl.querySelectorAll('.method'), function (btn) {
      btn.addEventListener('click', function () {
        Array.prototype.forEach.call(reqMethodListEl.querySelectorAll('.method'), function (m) { m.classList.remove('selected'); });
        btn.classList.add('selected');
        reqChoice = btn;
        updateReqContinue();
      });
    });
    reqContinueEl.addEventListener('click', function () {
      if (!reqSong || !reqChoice) return;
      var m = reqChoice.getAttribute('data-reqmethod');
      if (m === 'stripe') { openStripe(reqSong.stripeUrl); return; }
      mode = 'request';
      currentKey = m;
      currentLabel = reqChoice.getAttribute('data-label') || '';
      methodInput.value = m;
      openDetails(reqSong.title + ' · ' + votes + (votes === 1 ? ' vote' : ' votes') + ' · ' + money(songPrice(reqSong) * votes, req));
    });

    paintSuccessQueue = function (el) {
      el.textContent = '';
      rankedUp().slice(0, 3).forEach(function (s, i) {
        var e = byId[s.id];
        var row = document.createElement('div');
        row.className = 'sq-row' + (s === reqSong ? ' mine' : '');
        var rank = document.createElement('span');
        rank.className = 'sq-rank';
        rank.textContent = String(i + 1);
        var name = document.createElement('span');
        name.className = 'sq-name';
        name.textContent = s.title + (s.artist ? ' — ' + s.artist : '');
        var amt = document.createElement('span');
        amt.className = 'sq-amt';
        amt.textContent = money(e.t, req) + ' · ' + e.c + (e.c === 1 ? ' fan' : ' fans');
        row.appendChild(rank); row.appendChild(name); row.appendChild(amt);
        el.appendChild(row);
      });
    };

    var applyQueue = function (data) {
      if (!data.open) {
        if (tabReq) hide(tabReq);
        if (flow === 'request') setFlow('tip');
        return;
      }
      byId = {};
      data.songs.forEach(function (s) { byId[s.id] = { t: s.totalMinor, c: s.count, s: s.status }; });
      renderSongs();
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

  renderStep();
})();`;

const STYLE = `
:root { color-scheme: light dark; --accent: #e8542f; --accent-soft: #fdeee8; --bg: #faf6f1; --fg: #2b2018; --card: #ffffff; --muted: #8a7a6d; --line: #e7ddd3; --live: #7ab77a; --faint: #d8cabb; --field: #f1e9df; }
@media (prefers-color-scheme: dark) { :root { --bg: #1c1713; --fg: #f3ece4; --card: #292219; --muted: #a2917f; --line: #3d332a; --accent-soft: #3a231b; --faint: #4a3d31; --field: #241d16; } }
* { box-sizing: border-box; margin: 0; }
[hidden] { display: none !important; }
body { min-height: 100dvh; background: var(--bg); color: var(--fg); font: 16px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif; display: flex; flex-direction: column; align-items: center; padding: 20px 16px 32px; }
@media (min-width: 768px) {
  body { justify-content: center; background: radial-gradient(90% 120% at 50% -20%, #f6ede3 0%, #efe4d6 55%, #e9dccb 100%); padding: 40px 20px; }
}
@media (min-width: 768px) and (prefers-color-scheme: dark) {
  body { background: radial-gradient(90% 120% at 50% -20%, #26201a 0%, #1f1a14 55%, #17130f 100%); }
}
main { width: 100%; max-width: 460px; }
.card { position: relative; background: var(--bg); border-radius: 24px; padding: 0; }
@media (min-width: 768px) { .card { border: 1px solid var(--line); box-shadow: 0 24px 70px rgba(43,32,24,.18); padding: 28px 28px 26px; } }
@media (min-width: 768px) and (prefers-color-scheme: dark) { .card { box-shadow: 0 24px 70px rgba(0,0,0,.5); } }
.hdr { display: flex; align-items: center; gap: 13px; }
.avatar { width: 48px; height: 48px; flex: 0 0 auto; border-radius: 50%; background: var(--accent-soft); color: var(--accent); display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 18px; }
.hdr-info { min-width: 0; }
h1 { font-size: 18px; font-weight: 800; margin: 0; overflow-wrap: anywhere; }
.hdr-msg { font-size: 12.5px; color: var(--muted); overflow-wrap: anywhere; white-space: pre-wrap; }
.live { display: flex; align-items: center; gap: 6px; font-size: 12px; color: var(--muted); margin-top: 1px; }
.live-dot { width: 7px; height: 7px; border-radius: 50%; background: var(--live); display: inline-block; }
.tabs { display: flex; gap: 4px; background: var(--line); border-radius: 13px; padding: 4px; margin: 18px 0 0; }
.tab { flex: 1; text-align: center; padding: 10px 0; border-radius: 10px; border: 0; background: transparent; color: var(--muted); font: inherit; font-weight: 600; font-size: 14px; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 7px; }
.tab.active { background: var(--card); color: var(--fg); font-weight: 700; box-shadow: 0 1px 3px rgba(0,0,0,.08); }
.tab-dot { width: 7px; height: 7px; border-radius: 50%; background: var(--accent); display: inline-block; }
/* Progress bar — a left chevron, the segments (flex:1), and a transparent
   mirror of the same chevron on the right. Two equal-width arrows keep the
   segments centred by pure symmetry — no absolute positioning, fully fluid. */
.progress { display: flex; align-items: center; gap: 12px; margin: 8px 0 2px; }
.prog-arrow { flex: 0 0 auto; display: inline-flex; align-items: center; justify-content: center; width: 16px; height: 22px; padding: 0; color: var(--muted); }
.prog-back { position: relative; border: 0; background: none; cursor: pointer; }
/* A ~40x40 square tap target, larger than the SVG, that doesn't grow the flex
   slot — so the segments' symmetry is untouched. */
.prog-back::before { content: ""; position: absolute; inset: -9px -12px; }
.prog-spacer { visibility: hidden; }
.prog-segs { display: flex; gap: 6px; flex: 1; min-width: 0; }
.seg { flex: 1; height: 4px; border-radius: 2px; background: var(--line); transition: background 0.2s; }
.seg.on { background: var(--accent); }
.step { margin-top: 18px; }
.step-title { font-size: 18px; font-weight: 800; overflow-wrap: anywhere; }
.step-sub { font-size: 13px; color: var(--muted); margin: 2px 0 14px; }
/* Amount */
.amt-row { display: flex; align-items: baseline; justify-content: center; gap: 3px; }
.amt-sym { font-size: 34px; font-weight: 800; color: var(--faint); }
.amt-input { width: 2ch; text-align: center; border: 0; background: transparent; color: var(--fg); font: inherit; font-size: 54px; font-weight: 800; letter-spacing: -0.02em; padding: 0; }
.amt-input::placeholder { color: var(--faint); }
.amt-input:focus { outline: none; }
.chips { display: flex; gap: 8px; justify-content: center; flex-wrap: wrap; margin: 12px 0 20px; }
.chip { padding: 9px 18px; border-radius: 999px; border: 1px solid var(--line); background: var(--card); color: var(--fg); cursor: pointer; font-weight: 700; font-size: 14px; }
.chip.other { border-style: dashed; border-color: var(--faint); background: transparent; color: var(--muted); font-weight: 600; }
/* Method radios */
.methods { display: flex; flex-direction: column; gap: 9px; }
.method { display: flex; align-items: center; gap: 12px; width: 100%; text-align: left; padding: 14px 16px; border-radius: 14px; border: 1px solid var(--line); background: var(--card); color: var(--fg); font: inherit; text-decoration: none; cursor: pointer; }
.method.selected { border: 2px solid var(--accent); padding: 13px 15px; }
.radio-dot { width: 20px; height: 20px; flex: 0 0 auto; border-radius: 50%; border: 2px solid var(--faint); box-sizing: border-box; }
.method.selected .radio-dot { border: 6px solid var(--accent); }
.method-copy { flex: 1; min-width: 0; }
.method-label { display: block; font-weight: 700; font-size: 15px; overflow-wrap: anywhere; }
.method-sub { display: block; font-size: 12px; color: var(--muted); margin-top: 1px; }
.cta { width: 100%; margin-top: 14px; padding: 16px; border: 0; border-radius: 16px; background: var(--accent); color: #fff; font-size: 17px; font-weight: 700; cursor: pointer; }
.cta:disabled { opacity: 0.6; }
.tip-error, .field-error { color: #c0392b; margin-top: 10px; font-size: 13px; }
.fallback a { display: block; margin-top: 8px; color: var(--accent); }
/* Details step */
label { display: block; font-size: 12px; color: var(--muted); margin: 12px 0 5px; }
input, textarea { width: 100%; padding: 12px 14px; border: 1px solid var(--line); border-radius: 12px; background: var(--field); color: var(--fg); font: inherit; font-size: 16px; }
.amt-input { background: transparent; }
textarea { resize: vertical; min-height: 60px; }
.turnstile-slot { margin-top: 14px; min-height: 66px; }
#f-submit { width: 100%; margin-top: 16px; padding: 15px; border: 0; border-radius: 14px; background: var(--accent); color: #fff; font-size: 16px; font-weight: 700; cursor: pointer; }
#f-submit:disabled { opacity: 0.6; }
/* Song list */
.search-wrap { display: flex; align-items: center; gap: 9px; padding: 11px 14px; border: 1px solid var(--line); border-radius: 12px; background: var(--card); color: var(--muted); margin-bottom: 6px; }
.search-wrap .glass { font-size: 15px; flex: 0 0 auto; }
#req-search { border: 0; background: none; padding: 0; flex: 1; color: var(--fg); font: inherit; font-size: 16px; }
#req-search::placeholder { color: var(--muted); }
.req-hint { color: var(--muted); font-size: 12.5px; margin: 6px 2px 4px; }
.song-group-title { font-size: 11.5px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; color: var(--muted); margin: 14px 2px 8px; }
button.song { display: flex; align-items: center; gap: 11px; width: 100%; text-align: left; padding: 12px 14px; margin: 8px 0; border-radius: 13px; border: 1px solid var(--line); background: var(--card); color: var(--fg); font: inherit; cursor: pointer; }
button.song.done { opacity: 0.5; cursor: default; }
.song-rank { width: 18px; flex: 0 0 auto; font-weight: 800; color: var(--accent); font-size: 15px; text-align: center; }
.song-copy { flex: 1; min-width: 0; }
.song-title { display: block; font-weight: 700; font-size: 14.5px; overflow-wrap: anywhere; }
.song-artist { display: block; color: var(--muted); font-size: 12px; overflow-wrap: anywhere; }
.song-standing { color: var(--accent); font-size: 13px; font-weight: 800; white-space: nowrap; text-align: right; }
.song-badge { font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; color: var(--muted); border: 1px solid var(--line); border-radius: 8px; padding: 2px 7px; white-space: nowrap; }
.song-action { flex: 0 0 auto; padding: 9px 15px; border-radius: 11px; border: 0; background: var(--accent); color: #fff; font-size: 13px; font-weight: 700; white-space: nowrap; }
.song-action.boost { background: var(--accent-soft); color: var(--accent); border: 1px solid var(--accent); }
/* Votes step */
.req-standing { display: block; font-size: 13px; color: var(--muted); margin: 2px 0 14px; }
.stepper { display: flex; align-items: center; gap: 14px; margin: 6px 0 6px; }
.stepper button { width: 46px; height: 46px; border-radius: 13px; border: 1px solid var(--line); background: var(--card); color: var(--fg); font-size: 22px; cursor: pointer; box-shadow: 0 1px 2px rgba(0,0,0,.05); }
.stepper button:active { background: var(--bg); }
#r-votes { flex: 1; text-align: center; font-size: 20px; font-weight: 800; }
#r-total { text-align: center; color: var(--muted); font-size: 13px; margin-bottom: 10px; }
.rank-pill { display: flex; align-items: center; justify-content: center; gap: 7px; text-align: center; margin-bottom: 16px; padding: 11px 12px; border-radius: 12px; border: 1px solid var(--accent); background: var(--accent-soft); color: var(--accent); font-size: 14px; font-weight: 800; transition: background 0.15s, color 0.15s; }
.rank-pill.top { background: var(--accent); color: #fff; }
.rank-pill .rank-num { font-size: 16px; }
/* Success */
#success { text-align: center; padding-top: 8px; }
.success-icon { width: 76px; height: 76px; border-radius: 50%; background: var(--accent); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 34px; margin: 8px auto 0; box-shadow: 0 10px 30px rgba(232,84,47,.35); }
.success-title { font-size: 24px; font-weight: 800; margin: 16px 0 4px; }
.success-msg { font-size: 14px; color: var(--muted); overflow-wrap: anywhere; }
#success-queue { margin-top: 18px; display: flex; flex-direction: column; gap: 7px; text-align: left; }
.sq-row { display: flex; align-items: center; gap: 11px; padding: 12px 14px; border-radius: 13px; background: var(--card); border: 1px solid var(--line); }
.sq-row.mine { border: 2px solid var(--accent); box-shadow: 0 4px 14px rgba(232,84,47,.15); }
.sq-rank { width: 18px; flex: 0 0 auto; font-weight: 800; font-size: 15px; color: var(--muted); }
.sq-row.mine .sq-rank { color: var(--accent); }
.sq-name { flex: 1; min-width: 0; font-weight: 700; font-size: 14px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sq-amt { flex: 0 0 auto; font-size: 12.5px; font-weight: 800; color: var(--muted); }
.sq-row.mine .sq-amt { color: var(--accent); }
.success-again { width: 100%; margin-top: 18px; padding: 14px; border: 1px solid var(--line); border-radius: 14px; background: var(--card); color: var(--fg); font: inherit; font-weight: 600; cursor: pointer; }
/* Confetti */
.confetti-piece { position: absolute; pointer-events: none; opacity: 0; border-radius: 2px; }
.confetti-play .confetti-piece { animation: confetti-fall 1.8s ease-out forwards; }
@keyframes confetti-fall { 0% { opacity: 1; transform: translateY(0) rotate(0deg); } 100% { opacity: 0; transform: translateY(150px) rotate(150deg); } }
/* Footer */
footer { margin: 22px 4px 0; font-size: 11.5px; line-height: 1.5; color: var(--muted); text-align: center; }
footer a { color: inherit; }
`;

const CURRENCY_SYMBOLS: Record<string, { sym: string; leads: boolean }> = {
  eur: { sym: "€", leads: false },
  gbp: { sym: "£", leads: true },
  usd: { sym: "$", leads: true },
  aud: { sym: "$", leads: true },
  cad: { sym: "$", leads: true },
  nzd: { sym: "$", leads: true },
  jpy: { sym: "¥", leads: true },
  cny: { sym: "¥", leads: true },
  chf: { sym: "CHF", leads: false },
  sek: { sym: "kr", leads: false },
  nok: { sym: "kr", leads: false },
  dkk: { sym: "kr", leads: false },
  isk: { sym: "kr", leads: false },
  pln: { sym: "zł", leads: false },
  czk: { sym: "Kč", leads: false },
  huf: { sym: "Ft", leads: false },
  ron: { sym: "lei", leads: false },
  bgn: { sym: "лв", leads: false },
  inr: { sym: "₹", leads: true },
  brl: { sym: "R$", leads: true },
  mxn: { sym: "$", leads: true },
  zar: { sym: "R", leads: true },
  try: { sym: "₺", leads: true },
  ils: { sym: "₪", leads: true },
  krw: { sym: "₩", leads: true },
};

function symbolFor(currency: string): { sym: string; leads: boolean } {
  return CURRENCY_SYMBOLS[currency] ?? { sym: currency.toUpperCase(), leads: false };
}

/** How one method prices a tip: currency, symbol/placement, factor, bounds. */
function pricing(currency: string) {
  const zeroDecimal = ZERO_DECIMAL.has(currency);
  const { sym, leads } = symbolFor(currency);
  return {
    code: currency.toUpperCase(),
    sym,
    symLeads: leads,
    factor: zeroDecimal ? 1 : 100,
    chips: zeroDecimal ? [500, 1000, 2000] : [2, 5, 10],
    ...amountBounds(currency),
  };
}

type Pricing = ReturnType<typeof pricing>;

/**
 * Minor units → human string ("3", "5.50", or "500" on a zero-decimal
 * currency). The inline script carries the same logic so a queue poll repaints
 * a standing into exactly the server-rendered string.
 */
function formatMinor(minor: number, factor: number): string {
  const v = minor / factor;
  return factor === 1 || Number.isInteger(v) ? String(v) : v.toFixed(2);
}

/** Minor units → a currency-marked string ("5 €", "£5", "500 ¥"). */
function moneyMinor(minor: number, p: Pricing): string {
  const num = formatMinor(minor, p.factor);
  return p.symLeads ? `${p.sym}${num}` : `${num} ${p.sym}`;
}

/** Up to two initials for the header avatar — cosmetic, escaped like anything. */
function initials(name: string): string {
  const stripped = name.replace(/^(the|a|an)\s+/i, "").trim() || name.trim();
  const words = stripped.split(/\s+/).filter(Boolean);
  if (words.length >= 2) {
    return (([...words[0]!][0] ?? "") + ([...words[1]!][0] ?? "")).toUpperCase();
  }
  return [...(words[0] ?? name)].slice(0, 2).join("").toUpperCase();
}

/** A handful of hardcoded confetti pieces, matching the design's burst. */
const CONFETTI = [
  { l: "18%", t: "6%", w: 9, h: 15, c: "var(--accent)", r: 24 },
  { l: "30%", t: "2%", w: 8, h: 8, c: "#f2b04c", r: 0 },
  { l: "46%", t: "8%", w: 9, h: 15, c: "var(--live)", r: -32 },
  { l: "60%", t: "2%", w: 9, h: 9, c: "#5a9bd4", r: 0 },
  { l: "74%", t: "7%", w: 9, h: 15, c: "#d46a9e", r: 50 },
  { l: "10%", t: "14%", w: 8, h: 8, c: "#5a9bd4", r: 0 },
  { l: "56%", t: "14%", w: 9, h: 14, c: "var(--accent)", r: 66 },
  { l: "86%", t: "12%", w: 8, h: 8, c: "#f2b04c", r: 0 },
];

function confetti(): SafeHtml {
  return html`${CONFETTI.map((p) =>
    raw(
      `<span class="confetti-piece" style="left:${p.l};top:${p.t};width:${p.w}px;height:${p.h}px;background:${p.c};transform:rotate(${p.r}deg)"></span>`,
    ),
  )}`;
}

/** Left chevron for the progress Back arrow — and its transparent mirror. */
const CHEVRON = raw(
  '<svg viewBox="0 0 8 14" width="8" height="14" fill="none" aria-hidden="true"><path d="M6.5 1 1.5 7l5 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>',
);

const LABELS: Record<string, string> = { revolut: "Revolut", mobilepay: "MobilePay", monzo: "Monzo" };
const SUBTEXT: Record<string, string> = {
  revolut: "Opens the Revolut app to finish",
  mobilepay: "Opens the MobilePay app to finish",
  monzo: "Opens the Monzo app to finish",
};

/** One method radio row (shared by the tip step and the votes step). */
function methodRow(opts: {
  attr: "data-method" | "data-reqmethod";
  key: string;
  name: string;
  label: string;
  sub: string;
  href?: string;
  hidden?: boolean;
}): SafeHtml {
  return html`<button type="button" class="method"${raw(` ${opts.attr}="${escapeHtml(opts.key)}"`)} data-label="${opts.name}"${opts.href ? raw(` data-href="${escapeHtml(opts.href)}"`) : ""}${opts.hidden ? raw(" hidden") : ""}>
    <span class="radio-dot" aria-hidden="true"></span>
    <span class="method-copy"><span class="method-label">${opts.label}</span><span class="method-sub">${opts.sub}</span></span>
  </button>`;
}

export function renderTipPage(
  profile: JarProfile,
  siteKey: string,
  requestsConfig?: RequestsConfig,
  requestsLive?: RequestsLive,
): string {
  const currency = profile.currency; // validated ^[a-z]{3}$
  const initial = pricing(currency);

  const offered = TIP_METHODS.filter((m) => bareMethodUrl(profile, m) !== null);
  const priced = offered.map((m) => ({ method: m, price: pricing(methodCurrency(m, currency)) }));
  const methodPricing: Record<string, Pricing> = Object.fromEntries(priced.map((p) => [p.method, p.price]));
  if (profile.methods.stripeUrl) methodPricing["card"] = initial;

  const methodRows: SafeHtml[] = [];
  if (profile.methods.stripeUrl) {
    methodRows.push(
      methodRow({
        attr: "data-method",
        key: "card",
        name: "Card",
        label: "Card · Apple Pay · Google Pay",
        sub: "Opens the secure Stripe payment page",
        href: profile.methods.stripeUrl,
      }),
    );
  }
  for (const { method, price } of priced) {
    const suffix = price.code === initial.code ? "" : ` · ${price.code}`;
    methodRows.push(
      methodRow({ attr: "data-method", key: method, name: LABELS[method]!, label: `${LABELS[method]}${suffix}`, sub: SUBTEXT[method]! }),
    );
  }

  const fallbackLinks = offered.map((m) =>
    html`<a href="${bareMethodUrl(profile, m)!}" rel="noopener">Open ${LABELS[m]}</a>`,
  );

  const hasForm = offered.length > 0;

  // ------------------------------------------------------ song requests (#64)
  const requestsOpen =
    requestsConfig?.enabled === true && (requestsLive?.openUntilMs ?? 0) > Date.now();

  let requestsAttr: SafeHtml | "" = "";
  let songsStep: SafeHtml | "" = "";
  let votesStep: SafeHtml | "" = "";
  let tabsBar: SafeHtml | "" = "";
  let successQueueSlot: SafeHtml | "" = "";

  if (requestsOpen && requestsConfig && requestsLive) {
    const liveSongs = requestsLive.songs ?? {};
    const stripeRequests = requestsConfig.methods.includes("stripe");
    const relayMethods = priced
      .filter((p) => requestsConfig.methods.includes(p.method) && p.price.code === initial.code)
      .map((p) => p.method);

    const ordered = requestsConfig.songs
      .map((song, idx) => ({ song, idx, entry: liveSongs[song.id] }))
      .sort((a, b) => {
        const doneA = a.entry?.s === "p" || a.entry?.s === "k";
        const doneB = b.entry?.s === "p" || b.entry?.s === "k";
        if (doneA !== doneB) return doneA ? 1 : -1;
        const hasA = (a.entry?.c ?? 0) > 0;
        const hasB = (b.entry?.c ?? 0) > 0;
        if (hasA !== hasB) return hasA ? -1 : 1;
        if ((a.entry?.t ?? 0) !== (b.entry?.t ?? 0)) return (b.entry?.t ?? 0) - (a.entry?.t ?? 0);
        return a.idx - b.idx;
      });
    let rank = 0;

    const cards = ordered.map(({ song, entry }) => {
      const done = entry !== undefined && (entry.s === "p" || entry.s === "k");
      const hasVotes = entry !== undefined && entry.c > 0;
      const badge = entry?.s === "p" ? "Played" : entry?.s === "k" ? "Skipped" : "";
      const standing = hasVotes && !done ? `${moneyMinor(entry!.t, initial)} · ${entry!.c} ${entry!.c === 1 ? "fan" : "fans"}` : "";
      const price = moneyMinor(song.priceMinor ?? requestsConfig.defaultPriceMinor, initial);
      const action = done ? "" : hasVotes ? "Boost" : `Request · ${price}`;
      const actionClass = `song-action${hasVotes && !done ? " boost" : ""}`;
      const rankLabel = hasVotes && !done ? String(++rank) : "";
      // A played/skipped song is disabled at render time — never donatable.
      return html`<button type="button" class="song${done ? " done" : ""}" data-song="${song.id}"${done ? raw(" disabled") : ""}>
    <span class="song-rank" aria-hidden="true">${rankLabel}</span>
    <span class="song-copy"><span class="song-title">${song.title}</span>${song.artist ? html`<span class="song-artist">${song.artist}</span>` : ""}</span>
    <span class="song-standing"${standing ? "" : raw(" hidden")}>${standing}</span>
    <span class="song-badge"${badge ? "" : raw(" hidden")}>${badge}</span>
    <span class="${actionClass}"${action ? "" : raw(" hidden")}>${action}</span>
  </button>`;
    });

    const reqMethodRows: SafeHtml[] = relayMethods.map((m) =>
      methodRow({ attr: "data-reqmethod", key: m, name: LABELS[m]!, label: LABELS[m]!, sub: SUBTEXT[m]! }),
    );
    if (stripeRequests && requestsConfig.songs.some((s) => s.stripeUrl !== undefined)) {
      reqMethodRows.push(
        methodRow({
          attr: "data-reqmethod",
          key: "stripe",
          name: "Card",
          label: "Card · Apple Pay · Google Pay",
          sub: "On the payment page, set the quantity to your number of votes.",
          hidden: true,
        }),
      );
    }

    songsStep = html`
  <section id="s-songs" class="step" hidden>
    <div class="search-wrap"><span class="glass" aria-hidden="true">⌕</span><input type="text" id="req-search" placeholder="Search songs or artists…" autocomplete="off"></div>
    <p class="req-hint">Pick a song and chip in — every vote pushes it up the queue.</p>
    <div id="requests">
      <p class="song-group-title" id="grp-up-title" hidden>Up next</p>
      <div id="grp-up"></div>
      <p class="song-group-title" id="grp-rest-title" hidden>Not requested yet</p>
      <div id="grp-rest"></div>
      <div id="grp-done"></div>
      ${cards}
    </div>
  </section>`;

    votesStep = html`
  <section id="s-votes" class="step" hidden>
    <div class="step-title" id="r-song"></div>
    <div class="req-standing" id="r-standing"></div>
    <div class="stepper">
      <button type="button" id="r-minus" aria-label="Fewer votes">−</button>
      <span id="r-votes">1 vote</span>
      <button type="button" id="r-plus" aria-label="More votes">＋</button>
    </div>
    <p id="r-total" aria-live="polite"></p>
    <div id="r-rank" class="rank-pill" aria-live="polite"></div>
    <div class="methods" id="req-method-list" role="radiogroup" aria-label="Payment method">
      ${reqMethodRows}
    </div>
    <button type="button" class="cta" id="req-continue">Continue</button>
  </section>`;

    successQueueSlot = html`<div id="success-queue" hidden></div>`;

    const reqJson = {
      currency: initial.code,
      sym: initial.sym,
      symLeads: initial.symLeads,
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
    requestsAttr = html` data-requests="${JSON.stringify(reqJson)}"`;

    tabsBar = html`
  <div class="tabs" role="tablist">
    <button type="button" class="tab active" id="tab-tip" role="tab" aria-selected="true">Tip</button>
    <button type="button" class="tab" id="tab-requests" role="tab" aria-selected="false">Song requests<span class="tab-dot" aria-hidden="true"></span></button>
  </div>`;
  }

  // ---------------------------------------------------------------- tip step
  const tipStep = hasForm
    ? html`
  <section id="s-tip" class="step">
    <div class="amt-row">
      <span class="amt-sym" id="f-sym-pre" hidden></span>
      <input id="f-amount" class="amt-input" inputmode="decimal" autocomplete="off" placeholder="${initial.chips[1]!}" aria-label="Amount">
      <span class="amt-sym" id="f-sym-post"></span>
    </div>
    <div class="chips" id="f-chips"></div>
    <div class="methods" id="method-list" role="radiogroup" aria-label="Payment method">
      ${methodRows}
    </div>
    <button type="button" class="cta" id="tip-cta">Continue</button>
    <p class="tip-error" id="tip-error" role="alert" hidden></p>
  </section>`
    : "";

  const detailsStep = hasForm
    ? html`
  <form id="s-details" class="step" hidden>
    <input type="hidden" id="f-method" value="">
    <div class="step-title" id="f-title">Send a tip</div>
    <p class="step-sub">Add a shout-out — it shows on the performer's screen.</p>
    <label for="f-name">Your name (optional)</label>
    <input id="f-name" maxlength="40" autocomplete="off" placeholder="Anonymous">
    <label for="f-message">Message (optional)</label>
    <textarea id="f-message" maxlength="200" placeholder="You guys rock!"></textarea>
    <div class="turnstile-slot"><div class="cf-turnstile" data-sitekey="${siteKey}"></div></div>
    <button id="f-submit" type="submit">Open the app →</button>
    <p class="field-error" id="f-error" role="alert" aria-live="assertive" hidden></p>
    <div class="fallback" id="f-fallback" role="group" aria-live="polite" hidden>${fallbackLinks}</div>
  </form>`
    : "";

  const successStep = hasForm
    ? html`
  <div id="success" class="step" hidden role="status" aria-live="polite">
    ${confetti()}
    <div class="success-icon" id="success-icon" aria-hidden="true">✓</div>
    <div class="success-title" id="success-title">You tipped!</div>
    <p class="success-msg">Your message is on its way to the performer's screen. Finish the payment in <span id="success-app">the app</span> to complete it — you can close this page once you're done.</p>
    ${successQueueSlot}
    <button type="button" class="success-again" data-done>Done</button>
  </div>`
    : "";

  const turnstileScript = hasForm
    ? raw(`<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" defer></script>`)
    : "";

  const noscript = hasForm
    ? html`<noscript><p style="margin-top:16px">JavaScript is off — you can still pay directly:</p>${fallbackLinks}</noscript>`
    : "";

  const page = html`<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${profile.artistName} — tip jar</title>
<style>${raw(STYLE)}</style>
</head>
<body>
<main data-methods="${JSON.stringify(methodPricing)}"${requestsAttr}>
  <div class="card">
    <header class="hdr">
      <div class="avatar" aria-hidden="true">${initials(profile.artistName)}</div>
      <div class="hdr-info">
        <h1>${profile.artistName}</h1>
        ${profile.message ? html`<div class="hdr-msg">${profile.message}</div>` : html`<div class="live"><span class="live-dot"></span>Live now</div>`}
      </div>
    </header>
    ${tabsBar}
    <div class="progress" id="progress" hidden>
      <button type="button" class="prog-arrow prog-back" id="prog-back" aria-label="Back">${CHEVRON}</button>
      <div class="prog-segs" id="prog-segs"></div>
      <span class="prog-arrow prog-spacer" aria-hidden="true">${CHEVRON}</span>
    </div>
    ${tipStep}
    ${songsStep}
    ${votesStep}
    ${detailsStep}
    ${successStep}
  </div>
  <footer>
    Tips you send here go straight to the performer's screen. If their screen is
    away, your tip waits up to an hour for it and is then deleted unseen — live.tips
    keeps no tip history. Powered by <a href="https://live.tips" rel="noopener">live.tips</a>.
  </footer>
</main>
${noscript}
${turnstileScript}
<script>${raw(INLINE_SCRIPT)}</script>
</body>
</html>`;

  return page.value;
}

/** Uniform page for unknown, deleted, and expired jars alike (anti-enumeration). */
export function renderNotFoundPage(): string {
  return html`<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Tip jar not active — live.tips</title>
<style>${raw(STYLE)}</style>
</head>
<body>
<main>
  <div class="card">
    <h1>This tip jar isn't active</h1>
    <p class="hdr-msg" style="margin-top:8px">The link may have expired or been replaced. Ask the performer for their current QR code.</p>
  </div>
  <footer>Powered by <a href="https://live.tips" rel="noopener">live.tips</a>.</footer>
</main>
</body>
</html>`.value;
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
