import 'package:web/web.dart' as web;

/// Open [url] in the browser from the web build.
///
/// By default this synthesises a real, user-clicked `<a target="_blank">`,
/// which an iOS Home-Screen PWA routes to the in-app Safari view. That view
/// keeps its own cookie jar — separate from the real Safari app — so a sign-in
/// begun there can't be finished by a verification link the user opens from
/// their email, which lands in the real Safari app. Stripe onboarding hits
/// exactly this wall: sign in, get a device-verification email, tap its link in
/// Safari, and the session never matches the sign-in.
///
/// Pass [safari] `true` for links that must survive that round-trip (the Stripe
/// key-setup links). On an installed iOS PWA we then rewrite the URL with the
/// `x-safari-https://` scheme, which asks iOS to hand it to the *real* Safari
/// app, so the sign-in and the email link share one session. Where the trap
/// doesn't exist — desktop, Android, a normal browser tab — [safari] is a no-op
/// and the link opens normally, so an unsupported scheme can never break it.
///
/// The click must fire synchronously inside the tap gesture — no `await` before
/// `.click()`, or iOS drops the user activation and traps the link in the PWA.
Future<void> openExternal(String url, {bool safari = false}) async {
  final href = (safari && _isInstalledIOS) ? _toSafariScheme(url) : url;
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
/// Safari view — the one place the `x-safari-https` escape is both needed and
/// safe. In a normal browser tab the link already opens in the real browser.
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
