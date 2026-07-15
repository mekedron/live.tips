import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/notifications/notifications_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Opening the app from a push notification must open the INTERFACE the
/// notification belongs to. The push's link names whose feed fired and which
/// band (functions/src/notifications.ts, `notificationsLink`); the boot URL
/// carries both into the app, which seats that account+profile before the
/// feed page opens — and says so, once, in a self-dismissing caption. A
/// phone holding three accounts used to open account A's banner over the tip
/// account B had just received.
const _uid = 'uid_test'; // FakeAuthService's default user
const _foxes = 'acc_foxes';
const _duo = 'acc_duo';

const _casey = AuthUser(
  uid: _uid,
  kind: AccountKind.google,
  displayName: 'Casey',
  email: 'casey@example.com',
);

Future<FakeFirebaseFirestore> _account() async {
  final db = FakeFirebaseFirestore();
  final bands = db.collection('users').doc(_uid).collection('bands');
  await bands.doc(_foxes).set({'name': 'The Foxes', 'createdAtMs': 1});
  await bands.doc(_duo).set({'name': 'Duo Sundays', 'createdAtMs': 2});
  return db;
}

Future<ProviderContainer> _boot(
  WidgetTester tester, {
  required LocalStore store,
  required FakeFirebaseFirestore db,
  required String bootUrl,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        initialRelaySecretProvider.overrideWithValue(null),
        firestoreProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(FakeAuthService(user: _casey)),
        bootLinkUrlProvider.overrideWithValue(bootUrl),
      ],
      child: const LiveTipsApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
      tester.element(find.byType(LiveTipsApp)),
      listen: false);
}

void main() {
  testWidgets(
      'a push for ANOTHER account activates it — account and band — then '
      'opens the feed, with a caption naming where the artist landed',
      (tester) async {
    // The device sits on the LOCAL mode; the account the notification
    // belongs to is signed in beside it, not active.
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    await store.saveAccountsDirectory(
      AccountsDirectory.initial().withAccount(const AppAccount(
        id: _uid,
        name: 'Casey',
        kind: AccountKind.google,
        email: 'casey@example.com',
      )),
    );

    final container = await _boot(
      tester,
      store: store,
      db: await _account(),
      bootUrl:
          'https://live.tips/app/?open=notifications&account=$_uid&band=$_duo',
    );

    expect(container.read(accountsDirectoryProvider).activeAccountId, _uid,
        reason: 'the notification\'s account is the one the app opens');
    expect(container.read(appStateProvider).accountId, _duo,
        reason: 'and its band — never whichever profile happened to be open');
    expect(find.byType(NotificationsScreen), findsOneWidget);
    // The caption: the artist must know which interface they are looking at.
    expect(find.text('Showing Duo Sundays — Casey'), findsOneWidget);
    expect(store.readActiveCloudBand(_uid), _duo,
        reason: 'the landing is remembered like any other');
  });

  testWidgets(
      'same account, other band: the push switches the band and says so',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    await store.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(const AppAccount(
            id: _uid,
            name: 'Casey',
            kind: AccountKind.google,
          ))
          .withActive(_uid),
    );
    // The device would open The Foxes on its own — the tip landed in Duo.
    await store.saveActiveCloudBand(_uid, _foxes);

    final container = await _boot(
      tester,
      store: store,
      db: await _account(),
      bootUrl:
          'https://live.tips/app/?open=notifications&account=$_uid&band=$_duo',
    );

    expect(container.read(appStateProvider).accountId, _duo);
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('Showing Duo Sundays — Casey'), findsOneWidget);
  });

  testWidgets(
      'an account this device does not hold falls back gracefully: the feed '
      'still opens, on the current profile, with no caption', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    await store.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(const AppAccount(
            id: _uid,
            name: 'Casey',
            kind: AccountKind.google,
          ))
          .withActive(_uid),
    );
    await store.saveActiveCloudBand(_uid, _foxes);

    final container = await _boot(
      tester,
      store: store,
      db: await _account(),
      bootUrl: 'https://live.tips/app/'
          '?open=notifications&account=uid_stranger&band=acc_theirs',
    );

    expect(container.read(accountsDirectoryProvider).activeAccountId, _uid,
        reason: 'nothing to seat — the device stays where it was');
    expect(container.read(appStateProvider).accountId, _foxes);
    expect(find.byType(NotificationsScreen), findsOneWidget,
        reason: 'the page itself still opens — the tap asked for the feed');
    expect(find.byType(SnackBar), findsNothing,
        reason: 'nothing was activated, so there is nothing to announce');
  });

  testWidgets(
      'a link with no target at all keeps today\'s behavior: the feed over '
      'whatever is open', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    await store.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(const AppAccount(
            id: _uid,
            name: 'Casey',
            kind: AccountKind.google,
          ))
          .withActive(_uid),
    );
    await store.saveActiveCloudBand(_uid, _foxes);

    final container = await _boot(
      tester,
      store: store,
      db: await _account(),
      bootUrl: 'https://live.tips/app/?open=notifications',
    );

    expect(container.read(appStateProvider).accountId, _foxes);
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
