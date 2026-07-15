import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override (the overrides-list element type) lives in misc, not the core barrel.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/data/firebase/push_service.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/notifications/notifications_bell.dart';
import 'package:live_tips/features/notifications/push_nudge_card.dart';
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
    bool venueDevice = false,
    Widget home = const Scaffold(
      body: Align(alignment: Alignment.topRight, child: NotificationsBell()),
    ),
    List<Override> extra = const [],
  }) async {
    final local = await seededStore();
    if (venueDevice) await local.saveDeviceKind(DeviceKind.venue);
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
    // The server stamps createdAtMs with ITS clock — model one running ahead
    // of this device. Marking read at plain device-"now" left this entry
    // forever unread: a badge that survives the very page that shows it.
    final aheadMs = DateTime.now().millisecondsSinceEpoch + 60_000;
    await seedNote(db, 'n1', createdAtMs: 1000);
    await seedNote(db, 'n2',
        createdAtMs: aheadMs, kind: 'songRequest', songTitle: 'Hallelujah');
    await pump(tester, db: db);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    // The rows say who and how much, newest first (whole euros — the app's
    // formatAmount drops the decimals a round amount doesn't need).
    expect(find.text('Ada requested a song · €5'), findsOneWidget);
    expect(find.text('Ada tipped €5'), findsOneWidget);

    // Both are newer than the watermark the page OPENED with (none set →
    // 0), so both wear the unread dot — and keep it for the whole visit,
    // even though the mark-read write below has already landed.
    expect(find.byKey(const ValueKey('unread-dot-n1')), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-dot-n2')), findsOneWidget);

    // The watermark covers the newest entry SHOWN, clock skew included: the
    // badge is cleared for every device.
    final prefs = await db.doc(prefsPath).get();
    final seenAt = prefs.data()?['lastSeenAtMs'] as int?;
    expect(seenAt, isNotNull);
    expect(seenAt, greaterThanOrEqualTo(aheadMs));

    // Back on home the bell is quiet.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNothing);
  });

  testWidgets(
      'the feed groups by day, and only entries newer than the opening '
      'watermark wear the dot', (tester) async {
    final db = FakeFirebaseFirestore();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final earlier = today.subtract(const Duration(days: 3));
    await seedNote(db, 'old',
        createdAtMs: earlier.millisecondsSinceEpoch, name: 'Old Ada');
    await seedNote(db, 'new',
        createdAtMs: today.millisecondsSinceEpoch, name: 'New Ada');
    // The old entry was read on a previous visit; only the new one is news.
    await db
        .doc(prefsPath)
        .set({'lastSeenAtMs': earlier.millisecondsSinceEpoch + 1});
    await pump(tester, db: db);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    // LtRowGroup headers render uppercased (LtSectionLabel).
    expect(find.text('TODAY'), findsOneWidget);
    expect(
      find.text(DateFormat('EEEE, MMM d').format(earlier).toUpperCase()),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('unread-dot-new')), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-dot-old')), findsNothing);
  });

  testWidgets('the trash deletes one entry; Clear all (confirmed) empties the feed',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await seedNote(db, 'n1', createdAtMs: 1000);
    await seedNote(db, 'n2', createdAtMs: 2000, name: 'Beda');
    await pump(tester, db: db);
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    // One trash per row; the top row is the newest (Beda).
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Beda tipped €5'), findsNothing);
    expect(find.text('Ada tipped €5'), findsOneWidget);
    expect((await db.doc('$notes/n2').get()).exists, isFalse);
    expect((await db.doc('$notes/n1').get()).exists, isTrue);

    // Clear all asks first — Cancel leaves everything standing.
    await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await db.doc('$notes/n1').get()).exists, isTrue);

    // Confirmed, the whole feed goes and the empty state returns. (The
    // page's own Clear all also says the words — scope to the dialog.)
    await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Clear all'),
    ));
    await tester.pumpAndSettle();
    expect((await db.doc('$notes/n1').get()).exists, isFalse);
    expect(find.text('Nothing yet'), findsOneWidget);
  });

  testWidgets('the feed pages in on scroll instead of loading everything',
      (tester) async {
    final db = FakeFirebaseFirestore();
    for (var i = 1; i <= 30; i++) {
      await seedNote(db, 'n$i', createdAtMs: 1000 + i, name: 'Fan $i');
    }
    await pump(tester, db: db);
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    // One window, not the whole feed: the 26th-newest entry (Fan 5) is not
    // built yet — and not for lack of scrolling, it is not in the stream.
    expect(find.text('Fan 5 tipped €5', skipOffstage: false), findsNothing);
    expect(find.text('Fan 30 tipped €5', skipOffstage: false), findsOneWidget);

    // Nearing the bottom grows the window; the stream re-emits with more.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Fan 5 tipped €5', skipOffstage: false), findsOneWidget);
    expect(find.text('Fan 1 tipped €5', skipOffstage: false), findsOneWidget);
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
      'the home nudge enables push in one tap and hides itself', (tester) async {
    final db = FakeFirebaseFirestore();
    final push = _FakePushService();
    await pump(
      tester,
      db: db,
      home: const Scaffold(body: PushNudgeCard()),
      extra: [pushServiceProvider.overrideWithValue(push)],
    );

    expect(find.text("Don't miss a tip"), findsOneWidget);

    await tester.tap(find.text('Enable notifications'));
    await tester.pumpAndSettle();

    // Permission asked and granted inside the tap; the token landed; the
    // card has nothing left to offer.
    final doc = (await db.doc('users/$uid/devices/$deviceId').get()).data()!;
    expect(doc['fcmToken'], 'tok_test');
    expect(find.text("Don't miss a tip"), findsNothing);
  });

  testWidgets('"Not now" hides the nudge and is remembered on this device',
      (tester) async {
    final db = FakeFirebaseFirestore();
    final push = _FakePushService();
    final container = await pump(
      tester,
      db: db,
      home: const Scaffold(body: PushNudgeCard()),
      extra: [pushServiceProvider.overrideWithValue(push)],
    );

    expect(find.text("Don't miss a tip"), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text("Don't miss a tip"), findsNothing);
    // The memory outlives this widget tree: the next launch reads prefs.
    expect(
      container.read(localStoreProvider).pushNudgeDismissed(uid),
      isTrue,
    );
    // And no token was minted — "Not now" means no.
    final doc = (await db.doc('users/$uid/devices/$deviceId').get()).data();
    expect(doc?['fcmToken'], isNull);
  });

  testWidgets(
      'a venue device is never nudged, and its settings toggle is dead, off '
      'and honest about why', (tester) async {
    final db = FakeFirebaseFirestore();
    final push = _FakePushService();

    // The nudge, on a venue tablet: nothing, whatever the permission state.
    await pump(
      tester,
      db: db,
      venueDevice: true,
      home: const Scaffold(body: PushNudgeCard()),
      extra: [pushServiceProvider.overrideWithValue(push)],
    );
    expect(find.text("Don't miss a tip"), findsNothing);

    // The settings page: the switch is there, permanently off and disabled,
    // with the venue explanation underneath.
    await pump(
      tester,
      db: db,
      venueDevice: true,
      home: const NotificationSettingsScreen(),
      extra: [
        pushServiceProvider.overrideWithValue(push),
        pushStatusProvider.overrideWith((ref) async => PushStatus.canRequest),
      ],
    );
    expect(find.text('Not on a venue device'), findsOneWidget);
    expect(find.text('Enable notifications'), findsNothing);
    final deviceSwitch = tester.widgetList<Switch>(find.byType(Switch)).first;
    expect(deviceSwitch.value, isFalse);
    expect(deviceSwitch.onChanged, isNull);
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
