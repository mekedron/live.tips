import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase/callables.dart';
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

/// Push on THIS device for the ACTIVE account = the INTENT its own device
/// doc records (`pushEnabled`), which only the artist's own taps move. The
/// token beside it is mere CAPABILITY — the server prunes it when FCM
/// rejects it, [PushRegistration.maintain] re-mints it silently — and it
/// must never be read as the toggle: when it was, every pruned token
/// flipped the switch off with no way to tell "you turned this off" from
/// "the registration died", and no self-heal was possible because the
/// intent was gone with it. Docs from before the flag (a token and nothing
/// else) count as ON — the token was the old world's whole record of the
/// choice.
final thisDevicePushEnabledProvider = Provider<bool>((ref) {
  final info = ref.watch(thisDeviceInfoProvider);
  if (info == null) return false;
  return info.pushEnabled ?? (info.fcmToken != null);
});

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

/// While the STAGE SCREEN is visibly open here, this device's doc carries a
/// fresh `liveOpenAtMs` heartbeat — the send trigger reads it and skips THIS
/// device only: the stage already shows every tip landing, confetti and all,
/// so a default OS banner on top of it is noise. Every other device keeps
/// getting pushed even mid-set — the artist's phone in a pocket is exactly
/// where a tip should knock. The mark is cleared the moment the stage is
/// left or backgrounded; a crashed tab ages out server-side (150s).
class StagePresence {
  StagePresence(this.ref);

  final Ref ref;
  Timer? _beat;

  /// Two beats fit inside the server's 150s staleness window with slack.
  static const period = Duration(seconds: 60);

  DocumentReference<Map<String, dynamic>>? _ownDoc() {
    final uid = ref.read(authControllerProvider).user?.uid;
    if (uid == null) return null;
    return ref
        .read(firestoreProvider)
        ?.doc('users/$uid/devices/${ref.read(deviceIdProvider)}');
  }

  /// The stage screen became visible: mark now, then keep beating.
  void enter() {
    _beat?.cancel();
    _write();
    _beat = Timer.periodic(period, (_) => _write());
  }

  /// Left the stage or backgrounded: stop beating and clear the mark, so
  /// pushes resume immediately instead of after the staleness window.
  void leave() {
    _beat?.cancel();
    _beat = null;
    final doc = _ownDoc();
    if (doc == null) return;
    unawaited(
      doc.update({'liveOpenAtMs': FieldValue.delete()}).catchError(
          (Object e) => debugPrint('stage mark clear failed: $e')),
    );
  }

  void _write() {
    final doc = _ownDoc();
    if (doc == null) return;
    unawaited(
      doc.update({
        'liveOpenAtMs': DateTime.now().millisecondsSinceEpoch,
      }).catchError((Object e) => debugPrint('stage mark failed: $e')),
    );
  }
}

final stagePresenceProvider =
    Provider<StagePresence>((ref) => StagePresence(ref));

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

/// The push state's lifecycle against `users/{uid}/devices/{deviceId}` —
/// two fields with two owners. `pushEnabled` is INTENT and belongs to the
/// artist: enable/disable write it, nothing else moves it. `fcmToken` is
/// CAPABILITY and belongs to whoever last verified it: the server prunes it
/// dead, [maintain] re-mints it — across FCM rotations, app restarts,
/// account switches, locale changes, the device doc's own full-`set()`
/// recreate path (which drops fcmToken; see DeviceRegistry.registerThisDevice),
/// and a fan-out prune, all without the toggle moving.
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

  /// The settings toggle's ON — intent first, then capability. Permission
  /// (inside the user's tap) and the `pushEnabled: true` write land before
  /// the token mint, so the switch answers the finger instead of hanging in
  /// mid-air for the seconds a mint can take on a phone. The mint itself is
  /// bounded (PushService.getToken's 20s leash) and gets ONE retry; if both
  /// come back empty the intent is rolled back and the page told — an ON
  /// toggle that will never buzz is a lie, and leaving intent behind would
  /// set [maintain] chasing a registration this browser refuses to grant.
  Future<PushEnableOutcome> enableThisDevice() async {
    final uid = ref.read(authControllerProvider).user?.uid;
    final doc = _ownDoc(uid ?? '');
    if (uid == null || doc == null) return PushEnableOutcome.failed;
    final service = ref.read(pushServiceProvider);
    final permission = await service.requestPermission();
    if (permission == PushPermission.denied) return PushEnableOutcome.denied;
    if (permission != PushPermission.granted) return PushEnableOutcome.failed;
    try {
      await _patch(uid, doc, {'pushEnabled': true});
    } catch (e) {
      debugPrint('push enable failed: $e');
      return PushEnableOutcome.failed;
    }
    final token = await service.getToken() ?? await service.getToken();
    if (token == null) {
      try {
        await doc.update({'pushEnabled': false});
      } catch (e) {
        debugPrint('push enable rollback failed: $e');
      }
      return PushEnableOutcome.failed;
    }
    try {
      // No pushEnabled here: a disable racing this mint must win — the
      // token it leaves behind is inert (intent is what the server obeys).
      await _patch(uid, doc, _tokenPatch(token));
      return PushEnableOutcome.enabled;
    } catch (e) {
      debugPrint('push enable failed: $e');
      return PushEnableOutcome.failed;
    }
  }

  /// The toggle's OFF — for the active account only. Never deleteToken():
  /// the browser token may be serving another account signed in here. The
  /// intent is written false, not deleted — an absent flag means "before
  /// the flag existed" and would read the next stray token as consent.
  Future<void> disableThisDevice() async {
    final uid = ref.read(authControllerProvider).user?.uid;
    final doc = _ownDoc(uid ?? '');
    if (uid == null || doc == null) return;
    try {
      await doc.update({
        'pushEnabled': false,
        'fcmToken': FieldValue.delete(),
        'fcmTokenAtMs': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('push disable failed: $e');
    }
  }

  /// The self-heal, cheap enough to run on every wake: while this account's
  /// intent here is ON, make sure the doc carries a live token in today's
  /// language — including a token the send trigger PRUNED as dead, which is
  /// re-minted silently while the toggle (rendering intent) never moves.
  /// `pushEnabled: false`, and a doc with neither flag nor token, are the
  /// OFF state — not a bug to fix. A doc from before the flag (token, no
  /// flag) counts as ON and gets the explicit flag stamped on this first
  /// touch.
  ///
  /// Launch, resume, a uid flip and onTokenRefresh can all ask in the same
  /// breath: one pass at a time, and a burst that arrived mid-pass (an
  /// account switch under a slow mint) earns exactly one fresh pass against
  /// the new state. getToken answering null is a quiet give-up until the
  /// next wake — re-asking a browser that just said no is how loops start.
  Future<void> maintain() async {
    if (_maintaining) {
      _maintainAgain = true;
      return;
    }
    _maintaining = true;
    try {
      do {
        _maintainAgain = false;
        await _maintainOnce();
      } while (_maintainAgain);
    } finally {
      _maintaining = false;
    }
  }

  bool _maintaining = false;
  bool _maintainAgain = false;

  Future<void> _maintainOnce() async {
    final uid = ref.read(authControllerProvider).user?.uid;
    final doc = uid == null ? null : _ownDoc(uid);
    if (uid == null || doc == null) return;
    try {
      final snap = await doc.get();
      final data = snap.data();
      final stored = data?['fcmToken'] as String?;
      final intent = data?['pushEnabled'] as bool?;
      if (!(intent ?? stored != null)) return;
      final service = ref.read(pushServiceProvider);
      if (await service.permission() != PushPermission.granted) return;
      final token = await service.getToken();
      if (token == null) return;
      if (stored == token &&
          data?['locale'] == _localeCode() &&
          intent != null) {
        return;
      }
      await _patch(uid, doc, {
        ..._tokenPatch(token),
        // Stamped only where it was MISSING: intent already read true above
        // (by inference), and re-asserting an existing true could resurrect
        // a disable that raced this pass.
        if (intent == null) 'pushEnabled': true,
      });
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

  /// One sendTestPush call, through [callCallable] like every callable in
  /// the app (the functions SDK's call() minted a second FCM installation
  /// per invocation on web and murdered the very token under test — the
  /// invoker's doc has the full story; this button is where it was caught).
  Future<_TestCallResult> _callTest() async {
    final functions = ref.read(functionsProvider);
    if (functions == null) return _TestCallResult.failed;
    try {
      final map = await callCallable(functions, 'sendTestPush', {
        'deviceId': ref.read(deviceIdProvider),
      });
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

  Map<String, dynamic> _tokenPatch(String token) => {
        'fcmToken': token,
        'fcmTokenAtMs': DateTime.now().millisecondsSinceEpoch,
        'locale': _localeCode(),
      };

  Future<void> _patch(
    String uid,
    DocumentReference<Map<String, dynamic>> doc,
    Map<String, dynamic> patch,
  ) async {
    try {
      await doc.update(patch);
    } on FirebaseException {
      // No doc to update — registration hasn't landed yet (fresh sign-in,
      // boot race). Register through the ONE writer that knows the create
      // shape, then try once more; DeviceSessionGuard's touch() fallback,
      // same reasoning. A registration that refuses rethrows: the callers
      // owe the artist "failed", not a toggle that claims what never landed.
      if (!await ref.read(deviceRegistryProvider).registerThisDevice(uid)) {
        rethrow;
      }
      await doc.update(patch);
    }
  }
}

