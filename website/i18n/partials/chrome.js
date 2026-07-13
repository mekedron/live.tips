  /* ================= i18n (injected per locale by scripts/build_site.py) ================= */
  var I18N = {{i18n_js}};
  var LOCALES = {{locales_js}};
  var CUR = "{{code}}";
  /* Where the banner should send a reader who switches language from THIS page.
     Empty on the landing (the locale home is right); on a blog page it maps each
     locale to that post's translation, or to the locale's blog index. */
  var ALT = {{alt_urls_js}};

  /* ================= language switcher (header <select>) ================= */
  [].forEach.call(document.querySelectorAll('.lang-select'), function (sel) {
    sel.addEventListener('change', function () {
      if (this.value) location.assign(this.value);
    });
  });

  /* ================= cross-language banner =================
     Show "this site is also available in <your language>" when the visitor's
     browser language maps to a locale we publish that isn't the current one.
     Text + link render in the TARGET language from the embedded LOCALES table. */
  (function () {
    var bar = document.getElementById('lt-langbar');
    if (!bar) return;
    try { if (localStorage.getItem('lt-langbar-dismissed') === '1') return; } catch (e) { /* private mode */ }
    var navs = (navigator.languages && navigator.languages.length) ? navigator.languages : [navigator.language || ''];
    var want = null;
    for (var i = 0; i < navs.length && !want; i++) {
      var base = String(navs[i] || '').toLowerCase().split('-')[0];
      for (var j = 0; j < LOCALES.length; j++) {
        if (LOCALES[j].c === base) { want = LOCALES[j]; break; }
      }
    }
    if (!want || want.c === CUR) return;
    document.getElementById('lt-langbar-text').textContent = want.b;
    var link = document.getElementById('lt-langbar-link');
    link.href = ALT[want.c] || (want.c === 'en' ? '/' : '/' + want.c + '/');
    link.textContent = (want.f ? want.f + ' ' : '') + want.n + ' →';
    bar.hidden = false;
    document.getElementById('lt-langbar-x').addEventListener('click', function () {
      bar.hidden = true;
      try { localStorage.setItem('lt-langbar-dismissed', '1'); } catch (e) { /* private mode */ }
    });
  })();

  /* ================= theme: auto → light → dark ================= */
  var THEME_KEY = 'lt-landing-theme';
  var themeBtn = document.getElementById('theme-btn');
  var themeIco = document.getElementById('theme-ico');
  var order = ['auto', 'light', 'dark'];
  /* Material Symbols Rounded path data (fill 1, 24px) — brightness_auto,
     light_mode, dark_mode. The button's SVG swaps its <path d> directly. */
  var icons = {
    auto: 'M480-80q-83 0-156-31.5T197-197q-54-54-85.5-127T80-480q0-83 31.5-156T197-763q54-54 127-85.5T480-880q83 0 156 31.5T763-763q54 54 85.5 127T880-480q0 83-31.5 156T763-197q-54 54-127 85.5T480-80Zm40-83q119-15 199.5-104.5T800-480q0-123-80.5-212.5T520-797v634Z',
    light: 'M338.5-338.5Q280-397 280-480t58.5-141.5Q397-680 480-680t141.5 58.5Q680-563 680-480t-58.5 141.5Q563-280 480-280t-141.5-58.5ZM80-440q-17 0-28.5-11.5T40-480q0-17 11.5-28.5T80-520h80q17 0 28.5 11.5T200-480q0 17-11.5 28.5T160-440H80Zm720 0q-17 0-28.5-11.5T760-480q0-17 11.5-28.5T800-520h80q17 0 28.5 11.5T920-480q0 17-11.5 28.5T880-440h-80ZM451.5-771.5Q440-783 440-800v-80q0-17 11.5-28.5T480-920q17 0 28.5 11.5T520-880v80q0 17-11.5 28.5T480-760q-17 0-28.5-11.5Zm0 720Q440-63 440-80v-80q0-17 11.5-28.5T480-200q17 0 28.5 11.5T520-160v80q0 17-11.5 28.5T480-40q-17 0-28.5-11.5ZM226-678l-43-42q-12-11-11.5-28t11.5-29q12-12 29-12t28 12l42 43q11 12 11 28t-11 28q-11 12-27.5 11.5T226-678Zm494 495-42-43q-11-12-11-28.5t11-27.5q11-12 27.5-11.5T734-282l43 42q12 11 11.5 28T777-183q-12 12-29 12t-28-12Zm-42-495q-12-11-11.5-27.5T678-734l42-43q11-12 28-11.5t29 11.5q12 12 12 29t-12 28l-43 42q-12 11-28 11t-28-11ZM183-183q-12-12-12-29t12-28l43-42q12-11 28.5-11t27.5 11q12 11 11.5 27.5T282-226l-42 43q-11 12-28 11.5T183-183Z',
    dark: 'M480-120q-151 0-255.5-104.5T120-480q0-138 90-239.5T440-838q13-2 23 3.5t16 14.5q6 9 6.5 21t-7.5 23q-17 26-25.5 55t-8.5 61q0 90 63 153t153 63q31 0 61.5-9t54.5-25q11-7 22.5-6.5T819-479q10 5 15.5 15t3.5 24q-14 138-117.5 229T480-120Z'
  };

  function applyTheme(t) {
    if (t === 'auto') document.documentElement.removeAttribute('data-theme');
    else document.documentElement.setAttribute('data-theme', t);
    themeIco.setAttribute('d', icons[t]);
    themeBtn.title = I18N.theme + ': ' + t;
  }
  var theme = localStorage.getItem(THEME_KEY);
  if (order.indexOf(theme) === -1) theme = 'auto';
  applyTheme(theme);
  themeBtn.addEventListener('click', function () {
    theme = order[(order.indexOf(theme) + 1) % order.length];
    localStorage.setItem(THEME_KEY, theme);
    applyTheme(theme);
  });
