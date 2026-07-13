import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/repository/firestore_repository.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/settings/settings_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// "Remove this profile from this device" DELETED a cloud profile from the
/// whole account, on every device, for good — the copy promised the opposite of
/// what the code did, and the operation it promised did not exist at all (#27).
///
/// Two operations now, each named for what it does:
///   * Delete this profile — account-wide, irreversible, and the copy says so.
///   * Remove from this device — the local copy and the keychain secrets go,
///     the band stays in the account, and no byte of the network is needed.
///
/// The old tests asserted exactly what the code did (the registry, the wipe),
/// so nothing noticed that the artist was told the opposite. These assert the
/// STRINGS the artist is shown as well as the effect.
const _uid = 'uid_artist';
const _bandA = 'band_a';
const _bandB = 'band_b';

const _artist = AuthUser(
  uid: _uid,
  kind: AccountKind.google,
  displayName: 'Ana',
  email: 'ana@example.com',
);

/// A device signed into the cloud account, with a local profile beside it (as
/// every install has) — the directory's active profile is the account.
Future<LocalStore> _cloudStore() async {
  final local = await seededStore(bandName: 'Local Band');
  await local.saveAccountsDirectory(
    AccountsDirectory.initial()
        .withAccount(const AppAccount(
          id: _uid,
          name: 'Ana',
          kind: AccountKind.google,
          email: 'ana@example.com',
        ))
        .withActive(_uid),
  );
  await local.saveActiveCloudBand(_uid, _bandA);
  return local;
}

CollectionReference<Map<String, dynamic>> _bands(FakeFirebaseFirestore db) =>
    db.collection('users').doc(_uid).collection('bands');

/// The account's two profiles in the cloud: A is the one every test removes —
/// it has a jar, a session, a relay tip and a secrets doc, so "the account's
/// copy survived" is a claim with something to survive.
Future<FakeFirebaseFirestore> _cloudAccount() async {
  final db = FakeFirebaseFirestore();
  await _bands(db).doc(_bandA).set({
    'name': 'The Foxes',
    'createdAtMs': 1,
    'relayJar': {
      'jarId': 'jar_a',
      'tipUrl': 'https://live.tips/t/jar_a',
      'artistName': 'The Foxes',
      'currency': 'eur',
      'revolutUsername': 'foxy',
      'createdAtMs': 1,
    },
  });
  await _bands(db)
      .doc(_bandA)
      .collection('sessions')
      .doc('sess_1')
      .set({'id': 'sess_1', 'startedAt': 1, 'endedAt': 2, 'tips': <dynamic>[]});
  await _bands(db)
      .doc(_bandA)
      .collection('relayTips')
      .doc('tip_1')
      .set({'id': 'tip_1', 'createdAt': 1, 'amountMinor': 500});
  await _bands(db)
      .doc(_bandA)
      .collection('secrets')
      .doc('v1')
      .set({'relaySecret': 'sec_a'});
  await _bands(db).doc(_bandB).set({'name': 'Duo', 'createdAtMs': 2});
  return db;
}

/// The keychain of a device that has both cloud profiles cached.
FakeSecureStore _keychain() => FakeSecureStore({
      '${SecureStore.kApiKeyBase}_$_bandA': 'rk_live_a',
      '${SecureStore.kRelaySecretBase}_$_bandA': 'sec_a',
      '${SecureStore.kApiKeyBase}_$_bandB': 'rk_live_b',
    });

ProviderContainer _container(
  LocalStore local,
  FakeFirebaseFirestore db,
  FakeSecureStore secure, {
  FakeCallables? relay,
  AuthService? auth,
}) {
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(secure),
    initialApiKeyProvider.overrideWithValue(null),
    initialRelaySecretProvider.overrideWithValue(null),
    firestoreProvider.overrideWithValue(db),
    authServiceProvider
        .overrideWithValue(auth ?? FakeAuthService(user: _artist)),
    if (relay != null)
      relayClientProvider.overrideWithValue(fakeRelayClient(relay)),
    tipSourceFactoryProvider.overrideWithValue(
        ({required demo, required apiKey, required jar}) => NullTipSource()),
    relayChannelFactoryProvider.overrideWithValue(
        ({required demo, required jar, required secret}) => null),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// Mounts the app state and lets the account's first bands snapshot land — a
/// cloud mirror is silent until it does.
Future<void> _warm(ProviderContainer container) async {
  container.read(appStateProvider);
  await pumpEventQueue();
  expect(container.read(appStateProvider).accounts.map((b) => b.id),
      [_bandA, _bandB]);
  // An account with several profiles opens on NONE of them until the artist
  // answers the picker — so these tests, which are about removing the ACTIVE
  // profile, have to answer it first. Picking is the artist's move, and the
  // app no longer makes it for them.
  expect(container.read(appStateProvider).accountId, '',
      reason: 'two profiles, nobody asked yet');
  await container.read(appStateProvider.notifier).switchAccount(_bandA);
  expect(container.read(appStateProvider).accountId, _bandA);
}

Future<List<String>> _bandDocs(FakeFirebaseFirestore db) async =>
    [for (final d in (await _bands(db).get()).docs) d.id];

/// Settings over the same cloud account the notifier tests use — the profile
/// on screen is band A, of the signed-in account.
Future<void> _pumpSettings(
  WidgetTester tester,
  LocalStore local,
  FakeFirebaseFirestore db,
  FakeSecureStore secure,
) async {
  final container = _container(local, db, secure, relay: FakeCallables());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const Scaffold(body: SettingsScreen()),
      ),
    ),
  );
  // The first bands snapshot has to land before the profile has a name.
  await tester.pumpAndSettle();
  // An account with several profiles opens on none of them until the artist
  // says which — the picker's job (RootGate routes there), which Settings is
  // pumped past here. Answer it the way the artist would, or Settings has no
  // profile to show.
  await container.read(appStateProvider.notifier).switchAccount(_bandA);
  await tester.pumpAndSettle();
  expect(find.text('The Foxes'), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DELETE reaches the account: the band, its history and its secrets go '
      'from the cloud, and the tip page dies with them', () async {
    final local = await _cloudStore();
    final db = await _cloudAccount();
    final secure = _keychain();
    final relay = FakeCallables();
    final container = _container(local, db, secure, relay: relay);
    await _warm(container);

    expect(
      await container.read(appStateProvider.notifier).removeAccount(_bandA),
      isTrue,
    );

    expect(await _bandDocs(db), [_bandB],
        reason: 'a delete is account-wide — every device loses the band');
    expect((await _bands(db).doc(_bandA).collection('sessions').get()).docs,
        isEmpty);
    expect((await _bands(db).doc(_bandA).collection('relayTips').get()).docs,
        isEmpty);
    expect((await _bands(db).doc(_bandA).collection('secrets').get()).docs,
        isEmpty);
    // The public fan page goes too: nobody may tip a profile that no longer
    // exists.
    expect(relay.names, contains('deleteJar'));
    // And this device keeps nothing of it either.
    expect(secure.values.containsKey('${SecureStore.kApiKeyBase}_$_bandA'),
        isFalse);
    final app = container.read(appStateProvider);
    expect(app.accounts.map((b) => b.id), [_bandB]);
    expect(app.accountId, _bandB);
  });

  test('REMOVE FROM THIS DEVICE keeps the account whole: the cloud band, its '
      'history and its tip page all survive; the device keeps nothing',
      () async {
    final local = await _cloudStore();
    final db = await _cloudAccount();
    final secure = _keychain();
    final relay = FakeCallables();
    final container = _container(local, db, secure, relay: relay);
    // A device-local blob of the cloud band (the reprint notice) — device-local
    // by contract, and so exactly the kind of thing this removal exists to drop.
    await local.writeRelayLinkReplaced(_bandA, 'https://live.tips/t/old');
    expect(local.accountHasData(_bandA), isTrue);
    await _warm(container);

    expect(
      await container
          .read(appStateProvider.notifier)
          .removeAccountFromDevice(_bandA),
      isTrue,
    );

    // The account is untouched — this is the whole promise the dialog makes.
    expect(await _bandDocs(db), [_bandA, _bandB]);
    expect((await _bands(db).doc(_bandA).collection('sessions').get()).docs,
        hasLength(1));
    expect((await _bands(db).doc(_bandA).collection('relayTips').get()).docs,
        hasLength(1));
    expect((await _bands(db).doc(_bandA).collection('secrets').get()).docs,
        hasLength(1),
        reason: "the account's own copy of the secret stays in the account");
    expect(relay.names, isEmpty,
        reason: 'the tip page belongs to a band that still exists');

    // This device, on the other hand, keeps nothing of it: no keychain entry,
    // no local blob, no row in the switcher.
    expect(secure.values.containsKey('${SecureStore.kApiKeyBase}_$_bandA'),
        isFalse);
    expect(secure.values.containsKey('${SecureStore.kRelaySecretBase}_$_bandA'),
        isFalse);
    expect(local.accountHasData(_bandA), isFalse);
    expect(secure.values.containsKey('${SecureStore.kApiKeyBase}_$_bandB'),
        isTrue,
        reason: 'the other profile of the same account is not collateral');
    final app = container.read(appStateProvider);
    expect(app.accounts.map((b) => b.id), [_bandB]);
    expect(app.accountId, _bandB);
    expect(app.switching, isFalse);
  });

  test('the device removal needs no network — exactly where the delete can '
      'only refuse', () async {
    final local = await _cloudStore();
    final db = await _cloudAccount();
    final secure = _keychain();
    final container = _container(local, db, secure);
    await _warm(container);
    // Offline: the cloud wipe enumerates on the SERVER and throws (#17), so
    // the delete refuses rather than half-deleting.
    (container.read(accountDataRepositoryProvider) as FirestoreRepository)
            .serverGetOverride =
        (_) => throw FirebaseException(
            plugin: 'cloud_firestore', code: 'unavailable');
    final notifier = container.read(appStateProvider.notifier);

    expect(await notifier.removeAccount(_bandA), isFalse);
    expect(await _bandDocs(db), [_bandA, _bandB], reason: 'nothing deleted');

    // The device-local removal touches no server at all — this is the one an
    // artist can run on a venue tablet with no bars.
    expect(await notifier.removeAccountFromDevice(_bandA), isTrue);
    expect(await _bandDocs(db), [_bandA, _bandB]);
    expect(container.read(appStateProvider).accounts.map((b) => b.id),
        [_bandB]);
  });

  test('sign out takes the account OFF this device — and signing back in '
      'brings all of it back (#31)', () async {
    final local = await _cloudStore();
    final db = await _cloudAccount();
    final secure = _keychain();
    final auth = FakeAuthService(user: _artist, nextUser: _artist);
    final container = _container(local, db, secure, auth: auth);
    await _warm(container);

    await container.read(signOutProvider)();

    // The switcher must not go on offering the account — nor its email — to
    // whoever picks the device up next.
    final directory = container.read(accountsDirectoryProvider);
    expect(directory.contains(_uid), isFalse);
    expect(directory.activeAccountId, kLocalAccountId);
    // Its profiles are off the device with it: keychain and local blobs.
    expect(secure.values, isEmpty);
    expect(local.readActiveCloudBand(_uid), isNull);
    expect(local.accountHasData(_bandA), isFalse);
    // Nothing was DELETED, though — the account's data is in the cloud, which
    // is precisely what the sign-out dialog promises.
    expect(await _bandDocs(db), [_bandA, _bandB]);

    // Signing back in re-adds the account and its profiles, from the cloud.
    final back = await container
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    expect(back?.uid, _uid);
    await pumpEventQueue();
    expect(container.read(accountsDirectoryProvider).contains(_uid), isTrue);
    expect(container.read(accountsDirectoryProvider).activeAccountId, _uid);
    expect(container.read(appStateProvider).accounts.map((b) => b.id),
        [_bandA, _bandB]);
  });

  // ------------------------------------------------------------------ copy ---
  //
  // The half no old test had: what the artist is TOLD. The delete said "from
  // this device" while deleting from the account — a test that only asserts the
  // effect passes just as happily on a lie.

  testWidgets('a cloud profile offers both removals, and each says what it does',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final local = await _cloudStore();
    final db = await _cloudAccount();
    await _pumpSettings(tester, local, db, _keychain());

    expect(find.text('Remove from this device'), findsOneWidget);
    expect(find.text('Keeps it in your account — this device stops holding a copy'),
        findsOneWidget);
    expect(find.text('Delete this profile'), findsOneWidget);
    expect(find.text('Deletes it from your account, on all your devices'),
        findsOneWidget);
    // The lie that was: no row anywhere may promise a device-local removal and
    // run an account-wide delete.
    expect(find.text('Remove this profile from this device'), findsNothing);
  });

  testWidgets('the delete dialog names the ACCOUNT, says every device, and '
      'makes the artist type the word', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final local = await _cloudStore();
    final db = await _cloudAccount();
    await _pumpSettings(tester, local, db, _keychain());

    await tester.tap(find.text('Delete this profile'));
    await tester.pumpAndSettle();

    expect(find.text('Delete The Foxes?'), findsOneWidget);
    expect(
      find.textContaining(
          'from your account (ana@example.com) — here and on every other '
          'device you sign in on'),
      findsOneWidget,
    );
    expect(find.textContaining('Your other profiles stay.'), findsOneWidget);
    expect(find.textContaining('use “Remove from this device”'), findsOneWidget);

    // Proportional to the act: the button stays dead until the word is typed.
    FilledButton deleteButton() => tester.widget<FilledButton>(find.ancestor(
        of: find.text('Delete'), matching: find.byType(FilledButton)));
    expect(deleteButton().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pumpAndSettle();
    expect(deleteButton().onPressed, isNotNull);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await _bandDocs(db), [_bandB],
        reason: 'the confirmed delete really is the account-wide one');
  });

  testWidgets('the device removal says the profile stays in the account — and '
      'it does', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final local = await _cloudStore();
    final db = await _cloudAccount();
    final secure = _keychain();
    await _pumpSettings(tester, local, db, secure);

    await tester.tap(find.text('Remove from this device'));
    await tester.pumpAndSettle();

    expect(find.text('Remove The Foxes from this device?'), findsOneWidget);
    expect(
      find.textContaining(
          'stays in your account (ana@example.com) — nothing is deleted'),
      findsOneWidget,
    );
    expect(find.textContaining('Needs no connection.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(await _bandDocs(db), [_bandA, _bandB],
        reason: 'the account keeps the profile it was promised to keep');
    expect(secure.values.containsKey('${SecureStore.kApiKeyBase}_$_bandA'),
        isFalse);
    expect(find.text("The Foxes is off this device. It's still in your account."),
        findsOneWidget);
  });
}
