import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/account/device_session_guard.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

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
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        home: const DeviceSessionGuard(child: SizedBox()),
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
}
