import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/repository/firestore_repository.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// A cloud repository's band mirror is EMPTY until its first snapshot lands.
/// Read as "this account has no profiles", that silence made every cold start
/// mint a fresh empty profile, activate it, and sync it to Firestore — the
/// switcher filled up with "Unnamed profile" rows, one per reload.
const _uid = 'uid_guest';
const _bandId = 'acc_cloud';

const _guest = AuthUser(uid: _uid, kind: AccountKind.anonymous);

/// A directory whose active profile is the guest cloud account.
Future<LocalStore> _guestStore() async {
  final local = await seededStore(bandName: 'Local Band');
  await local.saveAccountsDirectory(
    AccountsDirectory.initial()
        .withAccount(const AppAccount(
          id: _uid,
          name: 'Guest',
          kind: AccountKind.anonymous,
        ))
        .withActive(_uid),
  );
  return local;
}

ProviderContainer _container(
  LocalStore local,
  FakeFirebaseFirestore db, {
  AuthUser? user = _guest,
  AuthService? auth,
}) {
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    initialRelaySecretProvider.overrideWithValue(null),
    firestoreProvider.overrideWithValue(db),
    authServiceProvider
        .overrideWithValue(auth ?? FakeAuthService(user: user)),
    tipSourceFactoryProvider.overrideWithValue(
        ({required demo, required apiKey, required jar}) => NullTipSource()),
    relayChannelFactoryProvider.overrideWithValue(
        ({required demo, required jar, required secret}) => null),
  ]);
  addTearDown(container.dispose);
  return container;
}

CollectionReference<Map<String, dynamic>> _bands(FakeFirebaseFirestore db) =>
    db.collection('users').doc(_uid).collection('bands');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await _bands(db).doc(_bandId).set({'name': 'The Foxes', 'createdAtMs': 1});
  });

  test('a cold cloud mirror creates no profile — the real one lands instead',
      () async {
    final local = await _guestStore();
    await local.saveActiveCloudBand(_uid, _bandId);
    final container = _container(local, db);

    // The very first read happens before any snapshot: nothing is known yet,
    // and nothing may be invented.
    final cold = container.read(appStateProvider);
    expect(cold.accounts, isEmpty,
        reason: 'a silent mirror says nothing about the profiles');
    expect(cold.accountId, isEmpty,
        reason: 'no fabricated profile is ever the active one');

    await pumpEventQueue();

    final warm = container.read(appStateProvider);
    expect(warm.accounts.map((a) => a.id), [_bandId]);
    expect(warm.accountId, _bandId,
        reason: 'the account\'s real profile is adopted when it arrives');
    expect(warm.displayName, 'The Foxes');

    // The proof that nothing was written while cold: an upsertBandEntry would
    // have left a second band doc behind.
    final docs = (await _bands(db).get()).docs;
    expect(docs.map((d) => d.id), [_bandId],
        reason: 'no band doc may be created on a cold boot');
  });

  test('an offline boot — an empty FROM-CACHE snapshot — still seeds nothing',
      () async {
    final local = await _guestStore();
    await local.saveActiveCloudBand(_uid, _bandId);
    final container = _container(local, db);
    final repo =
        container.read(accountDataRepositoryProvider) as FirestoreRepository;

    // Firestore raises an empty from-cache snapshot when the device boots
    // offline with a cold cache (or venue mode's disabled one).
    // fake_cloud_firestore can never raise it — feed the handler directly,
    // before the fake's own snapshot lands.
    repo.applyBandsSnapshot(const {}, fromCache: true);

    final offline = container.read(appStateProvider);
    expect(offline.accounts, isEmpty,
        reason: 'an offline empty cache is silence, not "no bands"');
    expect(offline.accountId, isEmpty);
    expect((await _bands(db).get()).docs.map((d) => d.id), [_bandId],
        reason: 'no junk band doc may be minted, let alone synced');

    // Connectivity returns; the fake's snapshot stands in for the server's.
    await pumpEventQueue();
    final online = container.read(appStateProvider);
    expect(online.accounts.map((a) => a.id), [_bandId],
        reason: 'the artist\'s real band, not a fabricated empty one');
    expect(online.accountId, _bandId);
    expect((await _bands(db).get()).docs, hasLength(1));
  });

  test('an unnamed band whose history lives only in Firestore is NOT '
      'collected on switch-away', () async {
    // Synced from another device, never opened on this one.
    await _bands(db).doc('acc_new').set({'name': '', 'createdAtMs': 2});
    await _bands(db).doc('acc_new').collection('sessions').doc('s1').set(
        LiveSession(
          id: 's1',
          startedAt: DateTime.fromMillisecondsSinceEpoch(1751500000000),
          endedAt: DateTime.fromMillisecondsSinceEpoch(1751500000001),
          currency: 'eur',
          goalMinor: 10000,
          tips: const [],
        ).toJson());
    final local = await _guestStore();
    await local.saveActiveCloudBand(_uid, 'acc_new');
    final container = _container(local, db);
    container.read(appStateProvider);
    await pumpEventQueue();
    // Two profiles, but this device HAS an answer on file: the band it last
    // had open auto-opens — the question was answered here already.
    expect(container.read(appStateProvider).accountId, 'acc_new');

    final ok = await container
        .read(appStateProvider.notifier)
        .switchAccount(_bandId);
    expect(ok, isTrue);
    await pumpEventQueue();

    // The sessions mirror had not heard from the server when the collector
    // asked: "nobody can say yet" must keep the band — and its history.
    expect((await _bands(db).get()).docs.map((d) => d.id),
        containsAll(['acc_new', _bandId]));
    expect(
        (await _bands(db).doc('acc_new').collection('sessions').get()).docs,
        hasLength(1),
        reason: 'deleting on a maybe is how synced history vanished');
  });

  test('a stored active band id that names nothing falls through to a REAL '
      'profile, never to a placeholder', () async {
    final local = await _guestStore();
    await local.saveActiveCloudBand(_uid, 'acc_deleted_elsewhere');
    final container = _container(local, db);
    container.read(appStateProvider);
    await pumpEventQueue();

    expect(container.read(appStateProvider).accountId, _bandId);
    expect((await _bands(db).get()).docs, hasLength(1));
  });

  test('a cloud account that genuinely has no profiles gets NONE — and the '
      'account is not written to', () async {
    final empty = FakeFirebaseFirestore();
    final local = await _guestStore();
    final container = _container(local, empty);

    expect(container.read(appStateProvider).accounts, isEmpty);
    await pumpEventQueue();

    // A warm, truly empty account is not a fresh one to be filled in for the
    // artist: it is an account with no profile, which RootGate renders as the
    // create-a-profile step. The app's job here is to write NOTHING.
    final app = container.read(appStateProvider);
    expect(app.accounts, isEmpty,
        reason: 'no profile may be minted behind the artist\'s back');
    expect(app.accountId, isEmpty);
    expect(app.connected, isFalse);
    expect(container.read(activeProfileRenderProvider), ProfileRender.create);
    final docs = (await empty
            .collection('users')
            .doc(_uid)
            .collection('bands')
            .get())
        .docs;
    expect(docs, isEmpty,
        reason: 'a warm, empty account writes nothing to Firestore');
  });

  test('a band deleted on one device is NOT resurrected by a second device '
      'whose mirror goes warm-empty', () async {
    // Two devices, one account, one Firestore. The phone removes the last
    // band; the tablet's mirror goes empty — and used to conclude "fresh
    // account", mint a replacement and sync it, so the deletion could never
    // stick while a second device was online.
    final phoneStore = await _guestStore();
    await phoneStore.saveActiveCloudBand(_uid, _bandId);
    final phone = _container(phoneStore, db);
    final tabletStore = await _guestStore();
    await tabletStore.saveActiveCloudBand(_uid, _bandId);
    final tablet = _container(tabletStore, db);
    phone.read(appStateProvider);
    tablet.read(appStateProvider);
    await pumpEventQueue();
    expect(phone.read(appStateProvider).accountId, _bandId);
    expect(tablet.read(appStateProvider).accountId, _bandId);

    expect(await phone.read(appStateProvider.notifier).removeAccount(_bandId),
        isTrue);
    await pumpEventQueue();

    // The tablet saw the deletion and left it deleted.
    expect(tablet.read(appStateProvider).accounts, isEmpty,
        reason: 'the tablet must not conjure a band back');
    expect(tablet.read(appStateProvider).accountId, isEmpty);
    expect(tablet.read(activeProfileRenderProvider), ProfileRender.create);
    expect((await _bands(db).get()).docs, isEmpty,
        reason: 'the removal must stay removed in the cloud');
    // …and the phone, which is still listening too.
    expect(phone.read(appStateProvider).accounts, isEmpty);
  });

  // ------------------------------------------------------------ #37 ---
  //
  // The invariant the app is built on now: a cloud account's profile set is
  // IDENTICAL on every device, and the only device-local fact is which profile
  // is currently open. There used to be an operation that broke it on purpose
  // ("remove from this device"); it is gone, and these two tests are what stand
  // in its place — the invariant, asserted, and the one honest exception, which
  // is a rendering state and not a second profile set.

  test('a cloud account shows the SAME profile set on a second device: a fresh '
      'sign-in adopts every profile, and no device holds a subset', () async {
    await _bands(db).doc('acc_duo').set({'name': 'Duo', 'createdAtMs': 2});

    // The first device: signed in, warm, holding both profiles.
    final phoneStore = await _guestStore();
    final phone = _container(phoneStore, db);
    phone.read(appStateProvider);
    await pumpEventQueue();
    expect(phone.read(appStateProvider).accounts.map((a) => a.id),
        [_bandId, 'acc_duo']);

    // The second device has never seen this account. It signs in — same uid,
    // same Firestore — and the account it gets is the WHOLE account.
    final tabletStore = await seededStore(bandName: 'Tablet Local');
    final tablet = _container(
      tabletStore,
      db,
      auth: FakeAuthService(nextUser: _guest),
    );
    tablet.read(appStateProvider);
    await pumpEventQueue();
    final signedIn =
        await tablet.read(authControllerProvider.notifier).signInAnonymously();
    expect(signedIn?.uid, _uid);
    await pumpEventQueue();

    expect(tablet.read(accountsDirectoryProvider).activeAccountId, _uid);
    expect(
      tablet.read(appStateProvider).accounts.map((a) => a.id),
      phone.read(appStateProvider).accounts.map((a) => a.id),
      reason: "a cloud account's profile set is identical on every device",
    );
    // The one device-local fact, and the only one: which profile is open. The
    // tablet has been asked nothing yet, so it opens on none of them (#28) —
    // that is a device-local ANSWER, not a device-local profile set.
    expect(tablet.read(appStateProvider).accountId, isEmpty);
    expect(tablet.read(activeProfileRenderProvider), ProfileRender.pick);

    // The phone answers the question on its own, and that answer stays on the
    // phone: it changes which profile is OPEN there, and nothing about which
    // profiles either device has.
    expect(await phone.read(appStateProvider.notifier).switchAccount(_bandId),
        isTrue);
    await pumpEventQueue();
    expect(phone.read(appStateProvider).accountId, _bandId);
    expect(tablet.read(appStateProvider).accountId, isEmpty,
        reason: 'which profile is open is the one device-local fact');
    expect(tablet.read(appStateProvider).accounts.map((a) => a.id),
        [_bandId, 'acc_duo']);
  });

  test('a mirror that has not spoken renders SILENCE, not an empty account',
      () async {
    // The honest exception: a device that has never synced cannot show profiles
    // it has not seen. That is a rendering state of one profile set that has not
    // arrived — never "you have no profiles", never the create step, and nothing
    // may be written to the account on the strength of it.
    final local = await _guestStore();
    await local.saveActiveCloudBand(_uid, _bandId);
    final container = _container(local, db);
    final repo =
        container.read(accountDataRepositoryProvider) as FirestoreRepository;
    container.read(appStateProvider);
    // The empty from-cache snapshot an offline boot raises — a cache proves what
    // exists, never what is absent.
    repo.applyBandsSnapshot(const {}, fromCache: true);

    expect(repo.isWarm, isFalse);
    expect(container.read(appStateProvider).accounts, isEmpty);
    expect(container.read(activeProfileRenderProvider), ProfileRender.band,
        reason: 'the shell with no claim about the profile set — not create');

    // And when the server does speak, the account is whole, on this device too.
    await pumpEventQueue();
    expect(repo.isWarm, isTrue);
    expect(container.read(appStateProvider).accounts.map((a) => a.id),
        [_bandId]);
    expect((await _bands(db).get()).docs, hasLength(1),
        reason: 'silence writes nothing');
  });

  test('guest → local → guest round-trips: the session survives and the '
      'cloud profiles come back', () async {
    final local = await _guestStore();
    await local.saveActiveCloudBand(_uid, _bandId);
    final container = _container(local, db);
    final directory = container.read(accountsDirectoryProvider.notifier);
    container.read(appStateProvider);
    await pumpEventQueue();
    expect(container.read(appStateProvider).accountId, _bandId);

    // Switch the ACTIVE profile to the device-local one.
    await directory.setActive(kLocalAccountId);
    await pumpEventQueue();
    expect(container.read(appStateProvider).displayName, 'Local Band');
    expect(container.read(authControllerProvider).user?.uid, _uid,
        reason: 'a profile switch is a directory flip — it ends no session');

    // …and back, with no re-auth: the guest's band is exactly where it was.
    await directory.setActive(_uid);
    await pumpEventQueue();
    final app = container.read(appStateProvider);
    expect(app.accountId, _bandId);
    expect(app.displayName, 'The Foxes');
    expect((await _bands(db).get()).docs, hasLength(1),
        reason: 'round-tripping must not mint profiles either');
  });
}
