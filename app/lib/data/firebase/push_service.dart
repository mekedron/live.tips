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

  /// This device's current registration token — null when anything along the
  /// way (support, permission, the push service itself) says no.
  Future<String?> getToken() async {
    final m = _messaging;
    if (m == null) return null;
    try {
      return await m.getToken(vapidKey: kVapidKey.isEmpty ? null : kVapidKey);
    } catch (e) {
      debugPrint('push token fetch failed: $e');
      return null;
    }
  }

  /// FCM rotated the token under us; whoever stored it must re-store.
  Stream<String> get onTokenRefresh =>
      _messaging?.onTokenRefresh ?? const Stream.empty();

  PushPermission _map(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional =>
          PushPermission.granted,
        AuthorizationStatus.denied => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };
}
