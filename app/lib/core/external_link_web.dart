import 'package:web/web.dart' as web;

const _safariEscapeKey = 'lt_open_links_in_safari';

/// Whether the "open links in Safari" workaround is even relevant. Only an
/// installed iOS Home-Screen PWA traps outbound links in the in-app Safari
/// view; on desktop or in a normal mobile browser there is nothing to escape,
/// so the Settings toggle stays hidden there.
bool get safariEscapeApplicable => _isIOS && _isStandalone;

/// Whether the visitor has opted to route outbound links through the real
/// Safari app. Persisted per-device in localStorage. See [openExternal].
bool get preferSafariEscape =>
    web.window.localStorage.getItem(_safariEscapeKey) == '1';

set preferSafariEscape(bool value) {
  if (value) {
    web.window.localStorage.setItem(_safariEscapeKey, '1');
  } else {
    web.window.localStorage.removeItem(_safariEscapeKey);
  }
}

/// Open [url] in the browser from the web build.
///
/// By default this synthesises a real, user-clicked `<a target="_blank">`,
/// which an iOS Home-Screen PWA routes to the in-app Safari view. That view
/// keeps its own cookie jar — separate from the real Safari app — so a sign-in
/// begun there can't be finished by a verification link the user opens from
/// their email, which lands in the real Safari app. Stripe onboarding hits
/// exactly this wall: sign in, get a device-verification email, tap its link
/// in Safari, and the session never matches.
///
/// With [preferSafariEscape] on we rewrite the URL with the `x-safari-https://`
/// scheme, which asks iOS to hand the link to the real Safari app so the
/// sign-in and the email link share one session. That scheme is
/// version-dependent (it may prompt, or fail outright on older iOS), so it's
/// opt-in rather than the default.
///
/// The click must fire synchronously inside the tap gesture — no `await` before
/// `.click()`, or iOS drops the user activation and falls back to trapping the
/// link inside the PWA.
Future<void> openExternal(String url) async {
  final href = preferSafariEscape ? _toSafariScheme(url) : url;
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

String get _ua => web.window.navigator.userAgent;

// iPadOS 13+ Safari reports a desktop Mac user-agent, so a "Macintosh" that
// also reports touch points is really an iPad (a real Mac has no touchscreen).
bool get _isIPad =>
    _ua.contains('iPad') ||
    (_ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);

bool get _isIOS => _ua.contains('iPhone') || _ua.contains('iPod') || _isIPad;

bool get _isStandalone =>
    web.window.matchMedia('(display-mode: standalone)').matches;
