import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase/device_registry.dart';
import '../data/firebase/notifications_service.dart';
import '../data/firebase/push_service.dart';
import '../domain/app_account.dart';
import '../domain/device_kind.dart';
import '../domain/notification_item.dart';
import 'auth_providers.dart';
import 'device_providers.dart';
import 'providers.dart';
import 'venue_providers.dart';

/// The bell and its feed (issue: push notifications for cloud accounts).
/// Everything hangs off the ACTIVE account, exactly like device_providers:
/// signed out / local profile means an empty feed, default prefs, no badge —
/// the widgets need no platform or account branches.

final notificationsServiceProvider = Provider<NotificationsService>(
  (ref) => NotificationsService(db: ref.watch(firestoreProvider)),
);

/// How much of the feed the page currently shows. Starts at one screenful
/// and [grow]s as the artist scrolls — some accounts will have the full
/// server cap sitting there, and opening the page must not fetch it all.
/// autoDispose: only the page listens, so closing it resets the window and
/// the next visit starts small again.
class NotificationsFeedLimit extends Notifier<int> {
  @override
  int build() {
    ref.watch(authControllerProvider.select((s) => s.user?.uid));
    return NotificationsService.pageSize;
  }

  void grow() {
    if (state >= NotificationsService.serverCap) return;
    state = (state + NotificationsService.pageSize)
        .clamp(0, NotificationsService.serverCap);
  }
}

final notificationsFeedLimitProvider =
    NotifierProvider.autoDispose<NotificationsFeedLimit, int>(
        NotificationsFeedLimit.new);

/// The newest feed entries for the active account, newest first, windowed by
/// [notificationsFeedLimitProvider]. Empty in local mode / signed out.
/// autoDispose with the page: the bell has its own unread stream below, so
/// nothing should keep feed docs flowing once the page is closed.
final notificationsFeedProvider =
    StreamProvider.autoDispose<List<NotificationItem>>((ref) {
  final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (uid == null) return Stream.value(const <NotificationItem>[]);
  final limit = ref.watch(notificationsFeedLimitProvider);
  return ref.watch(notificationsServiceProvider).watchFeed(uid, limit: limit);
});

/// The account's notification settings; defaults while loading and in local
/// mode, so readers can treat it as always-present.
final notificationPrefsProvider = StreamProvider<NotificationPrefs>((ref) {
  final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (uid == null) return Stream.value(const NotificationPrefs());
  return ref.watch(notificationsServiceProvider).watchPrefs(uid);
});

/// The unread docs themselves, straight from a watermark-filtered query —
/// NOT derived from the feed page: the bell lives on Home and must not keep
/// the whole feed streaming just to wear a number. Usually this query
/// matches nothing at all.
final _unreadCountStreamProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (uid == null) return Stream.value(0);
  final prefs = ref.watch(notificationPrefsProvider).value;
  if (prefs == null) return Stream.value(0);
  return ref
      .watch(notificationsServiceProvider)
      .watchUnreadCount(uid, prefs.lastSeenAtMs);
});

/// What the bell wears. Zero while the streams are still warming up — a
/// badge that flashes a number and takes it back reads as a bug.
final unreadNotificationsProvider = Provider<int>(
  (ref) => ref.watch(_unreadCountStreamProvider).value ?? 0,
);

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

/// THIS device's own row in the account's registry (null while loading, in
/// local mode, or before registration lands).
final thisDeviceInfoProvider = Provider<DeviceInfo?>((ref) {
  final devices = ref.watch(devicesProvider).value;
  if (devices == null) return null;
  for (final d in devices) {
    if (d.isCurrent) return d;
  }
  return null;
});

/// Push on THIS device for the ACTIVE account = its own device doc carries a
/// token. The doc is the source of truth on purpose: it is what the send
/// trigger reads, and it survives reinstalls of nothing (a cleared browser
/// loses the token server-side via pruning, and this reads false again).
final thisDevicePushEnabledProvider = Provider<bool>(
  (ref) => ref.watch(thisDeviceInfoProvider)?.fcmToken != null,
);

/// A guest (anonymous) account's jar is never claimed as owned
/// (RelayAuth.ownsJars), so its tips never take the server-direct path — and
/// a notification service that will never be handed a tip has nothing to
/// offer. The nudge stands down; the settings page says why.
final pushAccountIsGuestProvider = Provider<bool>((ref) =>
    ref.watch(authControllerProvider.select((s) => s.user?.kind)) ==
    AccountKind.anonymous);

/// "Not now" on the home nudge, remembered per device+account (LocalStore).
/// A Notifier so the card disappears the moment it is dismissed, without a
/// prefs round-trip on every home build.
class PushNudgeDismissed extends Notifier<bool> {
  @override
  bool build() {
    final uid =
        ref.watch(authControllerProvider.select((s) => s.user?.uid));
    if (uid == null) return true; // nobody to nudge
    return ref.read(localStoreProvider).pushNudgeDismissed(uid);
  }

  Future<void> dismiss() async {
    final uid = ref.read(authControllerProvider).user?.uid;
    if (uid == null) return;
    state = true;
    await ref.read(localStoreProvider).setPushNudgeDismissed(uid);
  }
}

final pushNudgeDismissedProvider =
    NotifierProvider<PushNudgeDismissed, bool>(PushNudgeDismissed.new);

/// A shared bar tablet is nobody's phone: it must never carry a push token
/// (whose tips would it announce, and to whom at the counter?), so the nudge
/// and the settings toggle both stand down on it.
final pushDeviceIsVenueProvider = Provider<bool>(
  (ref) => ref.watch(deviceKindProvider) == DeviceKind.venue,
);

/// Whether Home should offer to turn notifications on. Only when the offer's
/// button can actually deliver in one tap: a cloud account is signed in, the
/// OS permission is still unasked (canRequest — blocked/unsupported/install-
/// first cases stay in Settings where the full ladder lives), push isn't
/// already on here, this isn't a venue tablet, and the artist never said
/// "Not now".
final pushNudgeVisibleProvider = Provider<bool>((ref) {
  final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (uid == null) return false;
  if (ref.watch(pushDeviceIsVenueProvider)) return false;
  if (ref.watch(pushAccountIsGuestProvider)) return false;
  if (ref.watch(pushNudgeDismissedProvider)) return false;
  if (ref.watch(thisDevicePushEnabledProvider)) return false;
  return ref.watch(pushStatusProvider).value == PushStatus.canRequest;
});

enum PushEnableOutcome { enabled, denied, failed }

/// What the settings page's "Send test notification" learned — AFTER the
/// repair loop had its chance (see [PushRegistration.testThisDevice]).
enum TestPushOutcome {
  /// FCM accepted it for this device's token — it is on its way.
  sent,

  /// Even a freshly minted registration was rejected: this browser/OS is
  /// refusing push right now. The device has been switched off deliberately
  /// — the page owes the artist the why.
  unreachable,

  failed,
}

/// The callable's raw verdict, pre-repair.
enum _TestCallResult { sent, noToken, deadToken, failed }

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

  /// The settings page's "Send test notification": one REAL push through the
  /// whole pipeline (callable → FCM → this very device) — with the repair
  /// loop that keeps the toggle honest. FCM rejecting the stored token does
  /// NOT flip anything off under the artist: the stale registration is
  /// thrown away, a fresh one minted and stored ([onRepair] fires so the
  /// page can narrate it), and the send retried once. Only when the FRESH
  /// token is rejected too does this device get switched off — deliberately,
  /// with [TestPushOutcome.unreachable] carrying the why.
  Future<TestPushOutcome> testThisDevice({void Function()? onRepair}) async {
    final first = await _callTest();
    if (first == _TestCallResult.sent) return TestPushOutcome.sent;
    if (first == _TestCallResult.failed) return TestPushOutcome.failed;

    // no-token / dead-token: the registration this account holds is unusable.
    onRepair?.call();
    if (first == _TestCallResult.deadToken) {
      // getToken() would hand the cached corpse straight back — only a
      // delete makes the SDK mint a new registration.
      await ref.read(pushServiceProvider).deleteToken();
    }
    if (await enableThisDevice() != PushEnableOutcome.enabled) {
      return TestPushOutcome.failed;
    }
    return switch (await _callTest()) {
      _TestCallResult.sent => TestPushOutcome.sent,
      _TestCallResult.failed => TestPushOutcome.failed,
      // A brand-new registration rejected as well: push is broken at the
      // browser/OS level. Read the toggle off honestly instead of looping.
      _TestCallResult.noToken || _TestCallResult.deadToken => await _giveUp(),
    };
  }

  Future<TestPushOutcome> _giveUp() async {
    await disableThisDevice();
    return TestPushOutcome.unreachable;
  }

  Future<_TestCallResult> _callTest() async {
    final functions = ref.read(functionsProvider);
    if (functions == null) return _TestCallResult.failed;
    try {
      final result = await functions
          .httpsCallable('sendTestPush')
          .call<dynamic>({'deviceId': ref.read(deviceIdProvider)});
      final data = result.data;
      final map = data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
      if (map['sent'] == true) return _TestCallResult.sent;
      return switch (map['reason']) {
        'no-token' => _TestCallResult.noToken,
        'dead-token' => _TestCallResult.deadToken,
        _ => _TestCallResult.failed,
      };
    } catch (e) {
      debugPrint('test push failed: $e');
      return _TestCallResult.failed;
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

