import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/push_support.dart';

/// The Web Push certificate's PUBLIC key (Firebase console → Cloud Messaging
/// → Web Push certificates, generated 2026-07-15). Public value, safe in git.
const kVapidKey =
    'BC3-v0flWq7UCkaqrk5PyCGLoskCJ2KRgDHx8Nfr7LhPlaqMZ7UhwLlHBmNaIVAQ-TSqlzhSbyEnEE3x9OU_HY8';

/// What this device can do about push at all — decided before permission
/// even comes up.
enum PushSupport {
  /// No push here, and installing wouldn't change it (old browser, no SW).
  unsupported,

  /// iOS/iPadOS browser tab: Safari pushes only to installed Home Screen
  /// apps (16.4+), so the fix is the install, not a permission prompt.
  needsPwaInstall,

  supported,
}

enum PushPermission { notDetermined, granted, denied }

/// The FCM edge, [DeviceRegistry]-mold: built with a null [FirebaseMessaging]
/// wherever Firebase isn't, and then every answer is the safe one — no
/// support, no permission, no token — so callers need no platform branches.
///
/// Deliberately NOT here: writing the token anywhere. Where a token lives
/// (which account's device doc) is an account question, and it belongs to
/// PushRegistration (notifications_providers.dart); this class only ever
/// talks to the messaging SDK.
class PushService {
  PushService({FirebaseMessaging? messaging}) : _messaging = messaging;

  final FirebaseMessaging? _messaging;

  Future<PushSupport> support() async {
    final m = _messaging;
    if (m == null) return PushSupport.unsupported;
    try {
      if (await m.isSupported()) return PushSupport.supported;
    } catch (e) {
      debugPrint('push support check failed: $e');
    }
    return pushNeedsPwaInstall
        ? PushSupport.needsPwaInstall
        : PushSupport.unsupported;
  }

  Future<PushPermission> permission() async {
    final m = _messaging;
    if (m == null) return PushPermission.notDetermined;
    try {
      return _map(await m.getNotificationSettings());
    } catch (e) {
      debugPrint('push permission read failed: $e');
      return PushPermission.notDetermined;
    }
  }

  /// Must run inside the user's tap: Safari (and Firefox) only honour
  /// permission prompts born from a gesture.
  Future<PushPermission> requestPermission() async {
    final m = _messaging;
    if (m == null) return PushPermission.notDetermined;
    try {
      return _map(await m.requestPermission());
    } catch (e) {
      debugPrint('push permission request failed: $e');
      return PushPermission.notDetermined;
    }
  }

  /// True when the last [getToken] wasn't refused but IGNORED — the whole
  /// 20s leash spent in silence. That is the shape of a browser with no push
  /// backend behind the Push API at all (Ungoogled Chromium strips GCM), as
  /// opposed to a quick refusal (the iOS Simulator's webpushd rejecting the
  /// subscribe) or a flaky moment. Overriding [getToken] may set it too.
  @protected
  bool lastTokenAskTimedOut = false;

  /// This device's current registration token — null when anything along the
  /// way (support, permission, the push service itself) says no.
  ///
  /// Bounded: browsers without a push backend behind the Push API (Ungoogled
  /// Chromium strips GCM entirely) let `subscribe()` hang forever — the
  /// enable toggle froze mid-air on one of Nikita's browsers. Twenty seconds
  /// is beyond any honest network; after that the answer is an honest no.
  Future<String?> getToken() async {
    final m = _messaging;
    if (m == null) return null;
    lastTokenAskTimedOut = false;
    try {
      return await m
          .getToken(vapidKey: kVapidKey.isEmpty ? null : kVapidKey)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      lastTokenAskTimedOut = true;
      debugPrint('push token fetch timed out: no push service answering');
      return null;
    } catch (e) {
      debugPrint('push token fetch failed: $e');
      return null;
    }
  }

  /// The enable flow's ask: [getToken] with one retry for a flaky moment —
  /// but not after a timeout, where the push service never answered at all
  /// and a second helping of the same silence would only keep the switch
  /// lying ON another 20s before its rollback.
  Future<String?> mintToken() async =>
      await getToken() ?? (lastTokenAskTimedOut ? null : await getToken());

  /// Throw the registration away so the next [getToken] mints a genuinely
  /// NEW one instead of handing back the cached corpse. Repair-only: call
  /// this when FCM has already rejected the current token as dead — at that
  /// point no other account signed in here still rides it either.
  ///
  /// The SDK's own deleteToken can itself be refused (403 for a token whose
  /// installation is gone) AND it throws before clearing its cache — seen
  /// live 2026-07-15. The fallback cuts the push subscription loose at the
  /// browser level, which needs no FCM authorization and forces the fresh
  /// mint just the same.
  Future<void> deleteToken() async {
    final m = _messaging;
    if (m == null) return;
    try {
      await m.deleteToken();
    } catch (e) {
      debugPrint('push token delete failed: $e');
      await pushBrowserUnsubscribe();
    }
  }

  /// FCM rotated the token under us; whoever stored it must re-store.
  Stream<String> get onTokenRefresh =>
      _messaging?.onTokenRefresh ?? const Stream.empty();

  /// Messages arriving while the app is in the FOREGROUND — where the OS
  /// banner rightly stays away. The bell handles real tips through
  /// Firestore; the one listener here is the settings page's test button,
  /// which turns "did it arrive?" into "received ✓" on the spot.
  Stream<RemoteMessage> get onMessage =>
      _messaging == null ? const Stream.empty() : FirebaseMessaging.onMessage;

  PushPermission _map(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional =>
          PushPermission.granted,
        AuthorizationStatus.denied => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };
}
