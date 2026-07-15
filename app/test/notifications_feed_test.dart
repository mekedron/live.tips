import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override (the overrides-list element type) lives in misc, not the core barrel.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/data/firebase/push_service.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/notifications/notifications_bell.dart';
import 'package:live_tips/features/settings/notification_settings_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/notifications_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// The bell, its feed page and the notification settings — the client half
/// of the push feature. The server half (what gets written into
/// users/{uid}/notifications and when) is pinned by the functions tests;
/// these tests treat that collection as given and pin what the app DOES with
/// it: the unread badge against the watermark, opening-marks-read, the
/// account-level kind toggles, and the device-doc token lifecycle.
void main() {
  const uid = 'uid_test';
  const deviceId = 'dev_self';
  const notes = 'users/$uid/notifications';
  const prefsPath = 'users/$uid/settings/notifications';

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required FirebaseFirestore db,
    bool signedIn = true,
    Widget home = const Scaffold(
      body: Align(alignment: Alignment.topRight, child: NotificationsBell()),
    ),
    List<Override> extra = const [],
  }) async {
    final local = await seededStore();
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(local),
      secureStoreProvider.overrideWithValue(FakeSecureStore()),
      initialApiKeyProvider.overrideWithValue(null),
      authServiceProvider.overrideWithValue(FakeAuthService(
        user: signedIn
            ? const AuthUser(uid: uid, kind: AccountKind.google)
            : null,
      )),
      deviceIdProvider.overrideWithValue(deviceId),
      describeDeviceProvider.overrideWithValue(() async =>
          const DeviceDescription(name: 'Test phone', platform: 'ios')),
      firestoreProvider.overrideWithValue(db),
      ...extra,
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        home: home,
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> seedNote(
    FirebaseFirestore db,
    String id, {
    int createdAtMs = 1000,
    String kind = 'tip',
    String? name = 'Ada',
    String? songTitle,
  }) =>
      db.doc('$notes/$id').set({
        'kind': kind,
        'bandId': 'acc_band1',
        'tipId': id,
        'amountMinor': 500,
        'currency': 'eur',
        'name': ?name,
        'songTitle': ?songTitle,
        'createdAtMs': createdAtMs,
      });

  testWidgets('signed out there is no bell at all — cloud-only, absent not disabled',
      (tester) async {
    await pump(tester, db: FakeFirebaseFirestore(), signedIn: false);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
  });

  testWidgets('the badge counts only entries newer than the watermark',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await seedNote(db, 'n1', createdAtMs: 1000);
    await seedNote(db, 'n2', createdAtMs: 2000);
    await seedNote(db, 'n3', createdAtMs: 3000);
    await db.doc(prefsPath).set({'lastSeenAtMs': 1000});

    await pump(tester, db: db);

    // n1 sits AT the watermark — seen; n2/n3 are news.
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('opening the feed page marks everything read, everywhere',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await seedNote(db, 'n1', createdAtMs: 1000);
    await seedNote(db, 'n2',
        createdAtMs: 2000, kind: 'songRequest', songTitle: 'Hallelujah');
    await pump(tester, db: db);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    // The rows say who and how much, newest first (whole euros — the app's
    // formatAmount drops the decimals a round amount doesn't need).
    expect(find.text('Ada requested a song · €5'), findsOneWidget);
    expect(find.text('Ada tipped €5'), findsOneWidget);

    // The watermark landed at "now": the badge is cleared for every device.
    final prefs = await db.doc(prefsPath).get();
    final seenAt = prefs.data()?['lastSeenAtMs'] as int?;
    expect(seenAt, isNotNull);
    expect(seenAt, greaterThanOrEqualTo(2000));

    // Back on home the bell is quiet.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNothing);
  });

  testWidgets('the kind toggles merge-write the account settings doc',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await db.doc(prefsPath).set({'lastSeenAtMs': 42});
    await pump(
      tester,
      db: db,
      home: const NotificationSettingsScreen(),
      extra: [
        pushStatusProvider.overrideWith((ref) async => PushStatus.granted),
      ],
    );

    // Both kinds default ON without a doc saying otherwise; the device
    // toggle (first) is off — no token on the device doc yet.
    final switches =
        tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(3));
    expect(switches.first.value, isFalse);
    expect(switches[1].value && switches[2].value, isTrue);

    // Tips off: only that flag lands; the watermark it merged over survives.
    await tester.tap(find.byType(Switch).at(1)); // device toggle is first
    await tester.pumpAndSettle();
    final prefs = (await db.doc(prefsPath).get()).data()!;
    expect(prefs['tips'], isFalse);
    expect(prefs.containsKey('songRequests'), isFalse);
    expect(prefs['lastSeenAtMs'], 42);
  });

  testWidgets(
      'enable writes the token (registering the device doc if need be); '
      'disable deletes the field and nothing else', (tester) async {
    final db = FakeFirebaseFirestore();
    final push = _FakePushService();
    final container = await pump(
      tester,
      db: db,
      home: const NotificationSettingsScreen(),
      extra: [
        pushServiceProvider.overrideWithValue(push),
        pushStatusProvider.overrideWith((ref) async => PushStatus.granted),
      ],
    );

    // No device doc yet — enable must register it first (the boot race),
    // then land the token beside the registry's own fields.
    final outcome =
        await container.read(pushRegistrationProvider).enableThisDevice();
    expect(outcome, PushEnableOutcome.enabled);
    final doc = (await db.doc('users/$uid/devices/$deviceId').get()).data()!;
    expect(doc['fcmToken'], 'tok_test');
    expect(doc['locale'], isA<String>());
    expect(doc['revoked'], isFalse, reason: 'registered, not conjured');

    await container.read(pushRegistrationProvider).disableThisDevice();
    final after = (await db.doc('users/$uid/devices/$deviceId').get()).data()!;
    expect(after.containsKey('fcmToken'), isFalse);
    expect(after['name'], isNotNull, reason: 'the device doc itself stays');
  });
}

/// A PushService whose OS always says yes — the doc lifecycle is the thing
/// under test, not the messaging SDK.
class _FakePushService extends PushService {
  _FakePushService() : super(messaging: null);

  PushPermission _permission = PushPermission.notDetermined;

  @override
  Future<PushSupport> support() async => PushSupport.supported;

  @override
  Future<PushPermission> permission() async => _permission;

  @override
  Future<PushPermission> requestPermission() async =>
      _permission = PushPermission.granted;

  @override
  Future<String?> getToken() async => 'tok_test';

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
}
