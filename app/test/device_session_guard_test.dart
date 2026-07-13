import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/features/account/device_session_guard.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// A silent tip source that remembers being disposed — how the revocation
/// test observes "the poll timer is dead".
class _RecordingSource extends TipSource {
  bool disposed = false;

  @override
  Future<void> prime(DateTime startedAt,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Tip>> pollNew() async => const [];

  @override
  String? get cursor => null;

  @override
  void dispose() => disposed = true;
}

/// The mutable Firestore handle the harness flips mid-test — riverpod 3 has
/// no StateProvider, so this is the two-line equivalent.
class _DbSwitch extends Notifier<FirebaseFirestore?> {
  _DbSwitch(this.initial);

  final FirebaseFirestore? initial;

  @override
  FirebaseFirestore? build() => initial;

  void set(FirebaseFirestore? db) => state = db;
}

/// The device-doc lifecycle the Security screen depends on: registration
/// must land once an AUTHENTICATED Firestore handle exists (not just once at
/// boot, when the account slot may not have restored yet), and `lastSeenAtMs`
/// must be a heartbeat, not a page-load timestamp — an always-visible web
/// tab never emits `AppLifecycleState.resumed`.
void main() {
  const uid = 'uid_1';
  const deviceId = 'dev_self';

  /// The swappable Firestore handle: null models the boot window where the
  /// account's session hasn't restored and registration can only fail.
  final dbSwitch = NotifierProvider<_DbSwitch, FirebaseFirestore?>(
      () => _DbSwitch(null));

  Future<ProviderContainer> pumpGuard(
    WidgetTester tester, {
    FirebaseFirestore? initialDb,
    TipSource? tipSource,
  }) async {
    final local = await seededStore();
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(local),
      secureStoreProvider.overrideWithValue(FakeSecureStore()),
      initialApiKeyProvider.overrideWithValue(null),
      authServiceProvider.overrideWithValue(FakeAuthService(
          user: const AuthUser(uid: uid, kind: AccountKind.google))),
      deviceIdProvider.overrideWithValue(deviceId),
      describeDeviceProvider.overrideWithValue(() async =>
          const DeviceDescription(name: 'Test phone', platform: 'ios')),
      dbSwitch.overrideWith(() => _DbSwitch(initialDb)),
      firestoreProvider.overrideWith((ref) => ref.watch(dbSwitch)),
      if (tipSource != null)
        tipSourceFactoryProvider.overrideWithValue(
            ({required demo, required apiKey, required jar}) => tipSource),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        // A Scaffold under the guard: _onRevoked's "signed out" snackbar
        // needs one registered with the messenger.
        home: const DeviceSessionGuard(child: Scaffold(body: SizedBox())),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  /// Unmounts the guard so its heartbeat timer dies before the test's
  /// end-of-run pending-timer check.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets(
      'a registration that failed at boot retries when the authenticated '
      'handle appears — one failure must not be memoized for the whole run',
      (tester) async {
    // Boot: no authenticated handle yet. Registration runs and fails
    // (in production: permission-denied through the default app).
    final container = await pumpGuard(tester, initialDb: null);

    // The account slot's session restores: the Firestore handle resolves.
    final db = FakeFirebaseFirestore();
    container.read(dbSwitch.notifier).set(db);
    await tester.pumpAndSettle();

    final doc = await db.doc('users/$uid/devices/$deviceId').get();
    expect(doc.exists, isTrue,
        reason: 'the device doc must land once registration CAN succeed — '
            'without it the Security list has an orphan row and the '
            '"This device" pill matches nothing');
    expect(doc.data()!['revoked'], isFalse);
    await unmount(tester);
  });

  testWidgets(
      'lastSeenAt is a heartbeat, and a missing doc is re-registered rather '
      'than update()-ing into the void forever', (tester) async {
    final db = FakeFirebaseFirestore();
    await pumpGuard(tester, initialDb: db);
    await tester.pumpAndSettle();

    final ref = db.doc('users/$uid/devices/$deviceId');
    expect((await ref.get()).exists, isTrue);

    // The doc disappears server-side (a cleanup, a rules rewrite, a rotated
    // id's orphan sweep). The old touch() ran update() on nothing and
    // failed silently forever.
    await ref.delete();
    expect((await ref.get()).exists, isFalse);

    // One heartbeat later the doc is back — no app restart, no `resumed`
    // lifecycle event (a pinned web tab never sends one).
    await tester.pump(const Duration(minutes: 5, seconds: 1));
    await tester.pumpAndSettle();

    final revived = await ref.get();
    expect(revived.exists, isTrue,
        reason: 'touch() must upsert (via re-register) when the doc is gone');
    expect(revived.data()!['revoked'], isFalse);
    expect(revived.data()!['lastSeenAtMs'], greaterThan(0));
    await unmount(tester);
  });

  testWidgets(
      'revocation stops the live session — the coordinator must not keep '
      'polling with the in-memory key behind the sign-out', (tester) async {
    final db = FakeFirebaseFirestore();
    final source = _RecordingSource();
    final container =
        await pumpGuard(tester, initialDb: db, tipSource: source);

    // A REAL set, on a real key — not demo. This test is about an artist's
    // night being archived as their device is revoked out from under them,
    // and a demo set is now archived where demo's data lives, not the band's
    // (#52). Demo was only ever standing in here for "connected".
    await container.read(appStateProvider.notifier).connect('rk_test_key');
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    await tester.pumpAndSettle();
    expect(container.read(liveSessionProvider), isNotNull);

    // The owner revokes THIS device (a function-owned flag in production).
    await db.doc('users/$uid/devices/$deviceId').update({'revoked': true});
    await tester.pumpAndSettle();

    expect(container.read(liveSessionProvider), isNull,
        reason: 'revocation that leaves the session running is not '
            'revocation — this is precisely the local state it exists '
            'to clear');
    expect(source.disposed, isTrue,
        reason: 'the poll timer dies with the coordinator');
    expect(container.read(authControllerProvider).user, isNull);
    expect(
        container
            .read(localStoreProvider)
            .readSessionHistory(kTestAccountId),
        hasLength(1),
        reason: 'the set is archived on the way out, not dropped');
    await unmount(tester);
  });
}
