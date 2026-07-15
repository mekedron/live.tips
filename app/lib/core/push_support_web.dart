import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// True in an iOS/iPadOS *browser tab*: Safari there has no Push API at all —
/// web push exists only inside an installed Home Screen app (iOS 16.4+). The
/// permission widget turns this into "install first" steps instead of a dead
/// "not supported". Same sniffing as install_prompt_web.dart, including the
/// iPadOS-reports-as-Mac workaround.
bool get pushNeedsPwaInstall => _isIOS && !_isStandalone;

/// The last-ditch repair for a wedged registration: FCM can refuse even to
/// DELETE a token whose installation is gone (HTTP 403,
/// `messaging/token-unsubscribe-failed`) — and the SDK throws before
/// clearing its own cache, so every getToken() after that resurrects the
/// same dead token. Unsubscribing the browser's push subscription needs no
/// FCM authorization at all, and with the subscription gone the next
/// getToken() has no choice but to mint a genuinely new registration.
/// The messaging SDK's token store is dropped alongside (fire-and-forget:
/// deleteDatabase waits for open connections, and the unsubscribe alone
/// already forces the fresh mint).
Future<bool> pushBrowserUnsubscribe() async {
  var cleared = false;
  try {
    final regs = (await web.window.navigator.serviceWorker
            .getRegistrations()
            .toDart)
        .toDart;
    for (final reg in regs) {
      final sub = await reg.pushManager.getSubscription().toDart;
      if (sub != null) {
        cleared = (await sub.unsubscribe().toDart).toDart || cleared;
      }
    }
  } catch (_) {
    // No service worker / permission oddity: nothing to clear is fine.
  }
  try {
    web.window.self.indexedDB.deleteDatabase('firebase-messaging-database');
  } catch (_) {}
  return cleared;
}

String get _ua => web.window.navigator.userAgent;

bool get _isIPad =>
    _ua.contains('iPad') ||
    (_ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);

bool get _isIOS => _ua.contains('iPhone') || _ua.contains('iPod') || _isIPad;

bool get _isStandalone =>
    web.window.matchMedia('(display-mode: standalone)').matches;
