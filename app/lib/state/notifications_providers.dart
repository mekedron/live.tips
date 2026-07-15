import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase/notifications_service.dart';
import '../data/firebase/push_service.dart';
import '../domain/notification_item.dart';
import 'auth_providers.dart';
import 'device_providers.dart';
import 'providers.dart';

/// The bell and its feed (issue: push notifications for cloud accounts).
/// Everything hangs off the ACTIVE account, exactly like device_providers:
/// signed out / local profile means an empty feed, default prefs, no badge —
/// the widgets need no platform or account branches.

final notificationsServiceProvider = Provider<NotificationsService>(
  (ref) => NotificationsService(db: ref.watch(firestoreProvider)),
);

/// The newest feed entries for the active account, server-capped, newest
/// first. Empty in local mode / signed out.
final notificationsFeedProvider = StreamProvider<List<NotificationItem>>((ref) {
  final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (uid == null) return Stream.value(const <NotificationItem>[]);
  return ref.watch(notificationsServiceProvider).watchFeed(uid);
});

/// The account's notification settings; defaults while loading and in local
/// mode, so readers can treat it as always-present.
final notificationPrefsProvider = StreamProvider<NotificationPrefs>((ref) {
  final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (uid == null) return Stream.value(const NotificationPrefs());
  return ref.watch(notificationsServiceProvider).watchPrefs(uid);
});

/// What the bell wears: feed entries newer than the mark-all-read watermark.
/// Zero while either stream is still warming up — a badge that flashes a
/// number and takes it back reads as a bug.
final unreadNotificationsProvider = Provider<int>((ref) {
  final feed = ref.watch(notificationsFeedProvider).value;
  final prefs = ref.watch(notificationPrefsProvider).value;
  if (feed == null || prefs == null) return 0;
  return feed.where((n) => n.createdAtMs > prefs.lastSeenAtMs).length;
});

// ---------------------------------------------------------------------------
// Push registration — where OS permission meets the device doc.

final pushServiceProvider = Provider<PushService>((ref) {
  // firebaseAuthProvider is the "did Firebase boot?" signal here exactly as
  // in functionsProvider: without it, FirebaseMessaging.instance would
  // throw on the platforms that never initialize an app.
  final available = ref.watch(firebaseAuthProvider) != null;
  return PushService(messaging: available ? FirebaseMessaging.instance : null);
});

/// The permission widget's whole state, one field. Recomputed when the
/// settings screen asks (ref.invalidate on resume): the user may have flipped
/// the browser/OS permission while the app was in the background.
enum PushStatus { unsupported, needsPwaInstall, canRequest, blocked, granted }

final pushStatusProvider = FutureProvider<PushStatus>((ref) async {
  final service = ref.watch(pushServiceProvider);
  return switch (await service.support()) {
    PushSupport.needsPwaInstall => PushStatus.needsPwaInstall,
    PushSupport.unsupported => PushStatus.unsupported,
    PushSupport.supported => switch (await service.permission()) {
        PushPermission.granted => PushStatus.granted,
        PushPermission.denied => PushStatus.blocked,
        PushPermission.notDetermined => PushStatus.canRequest,
      },
  };
});

/// Push on THIS device for the ACTIVE account = its own device doc carries a
/// token. The doc is the source of truth on purpose: it is what the send
/// trigger reads, and it survives reinstalls of nothing (a cleared browser
/// loses the token server-side via pruning, and this reads false again).
final thisDevicePushEnabledProvider = Provider<bool>((ref) {
  final devices = ref.watch(devicesProvider).value;
  if (devices == null) return false;
  for (final d in devices) {
    if (d.isCurrent) return d.fcmToken != null;
  }
  return false;
});

enum PushEnableOutcome { enabled, denied, failed }

final pushRegistrationProvider =
    Provider<PushRegistration>((ref) => PushRegistration(ref));

/// The token's lifecycle against `users/{uid}/devices/{deviceId}`:
/// enable/disable from the settings toggle, and [maintain] — the self-heal
/// that keeps a stored token current across FCM rotations, app restarts,
/// account switches, locale changes, and the device doc's own full-`set()`
/// recreate path (which drops fcmToken; see DeviceRegistry.registerThisDevice).
///
/// One browser/app token, written under EACH account that enabled push here:
/// the token is project-scoped, the accounts share the project, and the
/// server fans out per account — so two accounts on one phone both knock.
class PushRegistration {
  PushRegistration(this.ref);

  final Ref ref;

  DocumentReference<Map<String, dynamic>>? _ownDoc(String uid) => ref
      .read(firestoreProvider)
      ?.doc('users/$uid/devices/${ref.read(deviceIdProvider)}');

  /// The language this device's pushes should speak: the chosen app language
  /// when one is set, the OS language otherwise — resolved HERE because the
  /// server can't (AppSettings.localeCode is null for "follow the device").
  String _localeCode() =>
      ref.read(appStateProvider).settings.localeCode ??
      PlatformDispatcher.instance.locale.languageCode;

  /// The settings toggle's ON: permission (inside the user's tap), token,
  /// then the doc write that makes the server see this device.
  Future<PushEnableOutcome> enableThisDevice() async {
    final uid = ref.read(authControllerProvider).user?.uid;
    final doc = _ownDoc(uid ?? '');
    if (uid == null || doc == null) return PushEnableOutcome.failed;
    final service = ref.read(pushServiceProvider);
    final permission = await service.requestPermission();
    if (permission == PushPermission.denied) return PushEnableOutcome.denied;
    if (permission != PushPermission.granted) return PushEnableOutcome.failed;
    final token = await service.getToken();
    if (token == null) return PushEnableOutcome.failed;
    try {
      await _writeToken(uid, doc, token);
      return PushEnableOutcome.enabled;
    } catch (e) {
      debugPrint('push enable failed: $e');
      return PushEnableOutcome.failed;
    }
  }

  /// The toggle's OFF — for the active account only. Never deleteToken():
  /// the browser token may be serving another account signed in here.
  Future<void> disableThisDevice() async {
    final uid = ref.read(authControllerProvider).user?.uid;
    final doc = _ownDoc(uid ?? '');
    if (uid == null || doc == null) return;
    try {
      await doc.update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenAtMs': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('push disable failed: $e');
    }
  }

  /// The self-heal, cheap enough to run on every wake: if this account
  /// enabled push here (the doc says so), make sure the stored token and
  /// locale are today's. A device doc without a token is left alone — that
  /// is the OFF state, not a bug to fix.
  Future<void> maintain() async {
    final uid = ref.read(authControllerProvider).user?.uid;
    final doc = uid == null ? null : _ownDoc(uid);
    if (uid == null || doc == null) return;
    try {
      final snap = await doc.get();
      final data = snap.data();
      final stored = data?['fcmToken'] as String?;
      if (stored == null) return;
      final service = ref.read(pushServiceProvider);
      if (await service.permission() != PushPermission.granted) return;
      final token = await service.getToken();
      if (token == null) return;
      if (stored == token && data?['locale'] == _localeCode()) return;
      await _writeToken(uid, doc, token);
    } catch (e) {
      debugPrint('push token maintenance failed: $e');
    }
  }

  Future<void> _writeToken(
    String uid,
    DocumentReference<Map<String, dynamic>> doc,
    String token,
  ) async {
    final patch = {
      'fcmToken': token,
      'fcmTokenAtMs': DateTime.now().millisecondsSinceEpoch,
      'locale': _localeCode(),
    };
    try {
      await doc.update(patch);
    } on FirebaseException {
      // No doc to update — registration hasn't landed yet (fresh sign-in,
      // boot race). Register through the ONE writer that knows the create
      // shape, then try once more; DeviceSessionGuard's touch() fallback,
      // same reasoning.
      final ok =
          await ref.read(deviceRegistryProvider).registerThisDevice(uid);
      if (ok) await doc.update(patch);
    }
  }
}

