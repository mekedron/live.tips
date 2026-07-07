import 'package:web/web.dart' as web;

/// Open [url] in the browser from the web build.
///
/// On an installed iOS Home-Screen PWA, outbound links otherwise open in the
/// in-app Safari view, whose cookie jar is walled off from the real Safari app.
/// That breaks any sign-in that continues through an emailed link: the link
/// lands in the real Safari app — a different session — so it never matches.
/// Stripe onboarding is the sharp edge (sign in, verify by email, fail), but
/// the real Safari app is the right destination for every link. So on an
/// installed iOS PWA we rewrite http(s) URLs with the `x-safari-https://`
/// scheme, which asks iOS to hand them to the real Safari app. Everywhere else
/// — desktop, Android, a normal browser tab — the link just opens via a
/// synthesised, user-clicked `<a target="_blank">`.
///
/// The click must fire synchronously inside the tap gesture — no `await` before
/// `.click()`, or iOS drops the user activation and traps the link in the PWA.
Future<void> openExternal(String url) async {
  final href = _isInstalledIOS ? _toSafariScheme(url) : url;
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = href
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

/// Prefix an http(s) URL with the `x-safari-` scheme so iOS opens it in the
/// real Safari app. Leaves other schemes (mailto:, tel:) untouched.
String _toSafariScheme(String url) =>
    (url.startsWith('https://') || url.startsWith('http://'))
        ? 'x-safari-$url'
        : url;

/// Only an installed iOS Home-Screen PWA traps outbound links in the in-app
/// Safari view; in a normal browser tab the link already opens in the real
/// browser, so the scheme rewrite would just add a redundant hop.
bool get _isInstalledIOS => _isIOS && _isStandalone;

String get _ua => web.window.navigator.userAgent;

// iPadOS 13+ Safari reports a desktop Mac user-agent, so a "Macintosh" that
// also reports touch points is really an iPad (a real Mac has no touchscreen).
bool get _isIPad =>
    _ua.contains('iPad') ||
    (_ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);

bool get _isIOS => _ua.contains('iPhone') || _ua.contains('iPod') || _isIPad;

bool get _isStandalone =>
    web.window.matchMedia('(display-mode: standalone)').matches;
