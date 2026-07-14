import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/cloud_migrator.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/band_settings.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/tip_jar.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const _uid = 'uid_1';

const _tipJar = TipJar(
  productId: 'prod_1',
  priceId: 'price_1',
  paymentLinkId: 'plink_1',
  url: 'https://buy.stripe.com/x',
  currency: 'eur',
  displayName: 'Alpha',
  livemode: true,
);

const _relayJar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'Beta',
  currency: 'eur',
  revolutUsername: 'beta',
  createdAtMs: 1751500000000,
);

LiveSession _session() => LiveSession(
      id: 'sess_1',
      startedAt: DateTime.fromMillisecondsSinceEpoch(1751500000000),
      endedAt: DateTime.fromMillisecondsSinceEpoch(1751500003600),
      currency: 'eur',
      goalMinor: 10000,
      tips: [
        Tip(
          id: 'cs_live_1',
          amountMinor: 500,
          currency: 'eur',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1751500001000),
        ),
      ],
    );

Tip _relayTip() => Tip.relayTip(
      amountMinor: 700,
      currency: 'eur',
      method: TipMethod.revolut,
      ts: 1751500002000,
      serial: 0,
      relayId: 'r1',
    );

/// The classic pre-sign-in device: two local bands, one Stripe-flavored,
/// one relay-flavored, each with a secret in the keychain.
Future<(LocalStore, FakeSecureStore)> _seedTwoBands() async {
  SharedPreferences.setMockInitialValues({});
  final local = LocalStore(await SharedPreferences.getInstance());
  await local.saveAccountsRegistry(const AccountsRegistry(
    accounts: [
      BandAccount(id: 'acc_a', name: 'Alpha', createdAtMs: 1),
      BandAccount(id: 'acc_b', name: 'Beta', createdAtMs: 2),
    ],
    activeId: 'acc_a',
  ));
  await local.saveTipJar('acc_a', _tipJar);
  await local.saveBandSettings('acc_a', const BandSettings(lastGoalMinor: 7500));
  await local.appendSessionToHistory('acc_a', _session());
  await local.saveRelayJar('acc_b', _relayJar);
  await local.appendRelayHistory('acc_b', [_relayTip()]);
  final secure = FakeSecureStore();
  await secure.writeApiKey('acc_a', 'rk_live_1');
  await secure.writeRelaySecret('acc_b', 'jar_secret_1');
  return (local, secure);
}

/// The gap that let #30 through: [FakeFirebaseFirestore] accepts every write,
/// so no test had ever seen the migrator FAIL. These two make it fail the two
/// ways it can — the only two the artist has to be told apart.
///
/// A Firestore that rejects the writes of anybody but the owning uid — the
/// real rules, in miniature. Signed in as somebody else, every write into
/// users/{uid}/… is denied, permanently, exactly as it would be on the server.
FakeFirebaseFirestore _rejectingDb() => FakeFirebaseFirestore(
      authObject: Stream.value(const {'uid': 'somebody_else'}),
      securityRules: '''
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
''',
    );

/// A Firestore whose writes land locally but never reach the server: the
/// commit point is where an offline device stops, and it stops with the
/// SDK's own 'unavailable'.
class _OfflineDb extends FakeFirebaseFirestore {
  @override
  Future<void> waitForPendingWrites() async => throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Failed to reach the backend.',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('happy path: everything lands in the cloud, the local registry is left '
      'EMPTY, keychain untouched', () async {
    final (local, secure) = await _seedTwoBands();
    final db = FakeFirebaseFirestore();
    final migrator = CloudMigrator(local: local, secure: secure, db: db);
    final progress = <(String, int, int)>[];

    await migrator.uploadLocalBands(_uid,
        onProgress: (name, done, total) => progress.add((name, done, total)));

    final bands = db.collection('users').doc(_uid).collection('bands');
    final bandA = (await bands.doc('acc_a').get()).data()!;
    expect(bandA['name'], 'Alpha');
    expect(bandA['createdAtMs'], 1);
    expect((bandA['tipJar'] as Map)['url'], 'https://buy.stripe.com/x');
    expect((bandA['bandSettings'] as Map)['lastGoalMinor'], 7500);
    final bandB = (await bands.doc('acc_b').get()).data()!;
    expect((bandB['relayJar'] as Map)['jarId'], 'jar_1');

    final sessionDoc =
        await bands.doc('acc_a').collection('sessions').doc('sess_1').get();
    expect((sessionDoc.data()!['tips'] as List), hasLength(1));
    final tipDoc =
        await bands.doc('acc_b').collection('relayTips').doc('relay_r1').get();
    expect(tipDoc.data()!['amountMinor'], 700);

    final secretsA =
        await bands.doc('acc_a').collection('secrets').doc('v1').get();
    expect(secretsA.data()!['stripeKey'], 'rk_live_1');
    final secretsB =
        await bands.doc('acc_b').collection('secrets').doc('v1').get();
    expect(secretsB.data()!['relaySecret'], 'jar_secret_1');

    // The local side: bands wiped, registry EMPTY, flag cleared. The move used
    // to leave one fresh unnamed band behind — a deliberate placeholder, so
    // that switching back to the local profile landed on a ready band. An empty
    // local profile is routable (it lands on the create step, #38/#40), and the
    // placeholder was a profile the artist never made: unnamed, dataless, and
    // exactly the phantom of #50 by another route.
    expect(local.accountHasData('acc_a'), isFalse);
    expect(local.accountHasData('acc_b'), isFalse);
    final registry = local.readAccountsRegistry()!;
    expect(registry.accounts, isEmpty);
    expect(registry.activeId, '');
    expect(migrator.hasPendingUpload, isFalse);

    // Keychain entries stay: they are now the cloud profile's cache under
    // the same band ids.
    expect(await secure.readApiKey('acc_a'), 'rk_live_1');
    expect(await secure.readRelaySecret('acc_b'), 'jar_secret_1');

    expect(progress.first, ('Alpha', 0, 2));
    expect(progress.last, ('Beta', 2, 2));
  });

  test('resume after a crash mid-upload: identical end state, no duplicates',
      () async {
    final (local, secure) = await _seedTwoBands();
    final db = FakeFirebaseFirestore();
    // The crashed run got as far as band A's doc and its session before
    // dying: flag set, some docs written, nothing wiped.
    await local.saveCloudUploadPending(_uid, ['acc_a', 'acc_b']);
    final bands = db.collection('users').doc(_uid).collection('bands');
    await bands.doc('acc_a').set({
      'name': 'Alpha',
      'createdAtMs': 1,
      'tipJar': _tipJar.toJson(),
      'bandSettings': const BandSettings(lastGoalMinor: 7500).toJson(),
      'updatedAtMs': 1,
    });
    await bands
        .doc('acc_a')
        .collection('sessions')
        .doc('sess_1')
        .set(_session().toJson());

    final migrator = CloudMigrator(local: local, secure: secure, db: db);
    expect(migrator.hasPendingUpload, isTrue);
    await migrator.uploadLocalBands(_uid);

    expect((await bands.get()).docs.map((d) => d.id), ['acc_a', 'acc_b']);
    expect((await bands.doc('acc_a').collection('sessions').get()).docs,
        hasLength(1),
        reason: 'doc ids are the stable local ids — a resume overwrites, '
            'never duplicates');
    expect((await bands.doc('acc_b').collection('relayTips').get()).docs,
        hasLength(1));
    expect(local.accountHasData('acc_a'), isFalse);
    expect(local.readAccountsRegistry()!.accounts, isEmpty);
    expect(migrator.hasPendingUpload, isFalse);
  });

  test('resume after a crash inside the local wipe does not re-upload the '
      'wiped bands — cloud bandSettings survive', () async {
    final (local, secure) = await _seedTwoBands();
    final db = FakeFirebaseFirestore();
    // The crashed run got past the commit point AND the wipe loop, but died
    // before the registry reset: everything is safely in the cloud, the
    // local blobs are gone, and both bands are still claimed by the flag.
    await local.saveCloudUploadPending(_uid, ['acc_a', 'acc_b']);
    final bands = db.collection('users').doc(_uid).collection('bands');
    await bands.doc('acc_a').set({
      'name': 'Alpha',
      'createdAtMs': 1,
      'tipJar': _tipJar.toJson(),
      'bandSettings': const BandSettings(lastGoalMinor: 7500).toJson(),
      'updatedAtMs': 1,
    });
    await bands.doc('acc_b').set({
      'name': 'Beta',
      'createdAtMs': 2,
      'relayJar': _relayJar.toJson(),
      'updatedAtMs': 1,
    });
    await local.wipeAccount('acc_a');
    await local.wipeAccount('acc_b');

    final migrator = CloudMigrator(local: local, secure: secure, db: db);
    await migrator.uploadLocalBands(_uid);

    final bandA = (await bands.doc('acc_a').get()).data()!;
    expect((bandA['bandSettings'] as Map)['lastGoalMinor'], 7500,
        reason: 'a wiped band re-read answers default settings — the upload '
            'must omit the absent blob, not merge defaults over the cloud');
    expect((bandA['tipJar'] as Map)['url'], 'https://buy.stripe.com/x');
    // The resume still finishes the crashed run's cleanup.
    final registry = local.readAccountsRegistry()!;
    expect(registry.accounts, isEmpty,
        reason: 'the registry reset the crash interrupted still happens');
    expect(migrator.hasPendingUpload, isFalse);
    expect(local.readActiveCloudBand(_uid), 'acc_a',
        reason: 'the cloud profile still opens on the migrated band');
  });

  test('resume still uploads a band that was only ever named — "no local data" '
      'is not proof it was already in the cloud', () async {
    final (local, secure) = await _seedTwoBands();
    // A third band the artist named and never configured: no jar, no settings,
    // no history. It holds no local data — and it has NOT been uploaded.
    final registry = local.readAccountsRegistry()!;
    await local.saveAccountsRegistry(AccountsRegistry(
      accounts: [
        ...registry.accounts,
        const BandAccount(id: 'acc_c', name: 'Gamma', createdAtMs: 3),
      ],
      activeId: registry.activeId,
    ));
    // The crashed run died inside the upload loop: the flag claims all three,
    // nothing is wiped yet, and Gamma never made it to the cloud.
    await local.saveCloudUploadPending(_uid, ['acc_a', 'acc_b', 'acc_c']);

    final db = FakeFirebaseFirestore();
    final migrator = CloudMigrator(local: local, secure: secure, db: db);
    await migrator.uploadLocalBands(_uid);

    expect(local.accountHasData('acc_c'), isFalse,
        reason: 'the band this test is about holds no local data at all');
    final gamma = await db
        .collection('users')
        .doc(_uid)
        .collection('bands')
        .doc('acc_c')
        .get();
    expect(gamma.exists, isTrue,
        reason: 'skipping empty-looking bands on a resume would strand a band '
            'the artist named but had not configured yet');
    expect(gamma.data()!['name'], 'Gamma');
  });

  test('a locked keychain skips secrets but never the migration', () async {
    final (local, secure) = await _seedTwoBands();
    secure.failing = true;
    final db = FakeFirebaseFirestore();
    final migrator = CloudMigrator(local: local, secure: secure, db: db);

    await migrator.uploadLocalBands(_uid);

    final bands = db.collection('users').doc(_uid).collection('bands');
    expect((await bands.doc('acc_a').get()).exists, isTrue);
    expect((await bands.doc('acc_a').collection('secrets').doc('v1').get())
        .exists, isFalse,
        reason: 'the secret stays local-only; the band still works here');
    expect((await bands.doc('acc_b').collection('secrets').doc('v1').get())
        .exists, isFalse);
    expect(local.readAccountsRegistry()!.accounts, isEmpty);
    expect(migrator.hasPendingUpload, isFalse);
  });

  test('a stale flag for a different uid is discarded and the upload starts '
      'fresh for the new one', () async {
    final (local, secure) = await _seedTwoBands();
    await local.saveCloudUploadPending('uid_old', ['acc_a']);
    final db = FakeFirebaseFirestore();
    final migrator = CloudMigrator(local: local, secure: secure, db: db);

    await migrator.uploadLocalBands(_uid);

    final bands = db.collection('users').doc(_uid).collection('bands');
    expect((await bands.get()).docs.map((d) => d.id), ['acc_a', 'acc_b'],
        reason: 'BOTH bands go up — the old flag\'s band list must not '
            'constrain a fresh run for a new uid');
    expect(
        (await db.collection('users').doc('uid_old').collection('bands').get())
            .docs,
        isEmpty);
    expect(migrator.hasPendingUpload, isFalse);
  });

  test('a stale flag with nothing local left is simply cleared', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalStore(await SharedPreferences.getInstance());
    await local.saveCloudUploadPending('uid_old', ['acc_a']);
    final db = FakeFirebaseFirestore();
    final migrator =
        CloudMigrator(local: local, secure: FakeSecureStore(), db: db);

    await migrator.uploadLocalBands(_uid);

    expect(migrator.hasPendingUpload, isFalse);
    expect(
        (await db.collection('users').doc(_uid).collection('bands').get()).docs,
        isEmpty);
  });

  test('resume after a crash between the local reset and the flag clear does '
      'not re-upload the fresh band', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalStore(await SharedPreferences.getInstance());
    // An upload crashed under a build that still left the placeholder band
    // behind, and this build resumes it: whatever the registry holds now, only
    // the bands the crashed run CLAIMED are pre-sign-in data. (The boot sweep
    // takes the placeholder itself — it is a phantom like any other, #50.)
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [BandAccount(id: 'acc_fresh', name: '', createdAtMs: 9)],
      activeId: 'acc_fresh',
    ));
    await local.saveCloudUploadPending(_uid, ['acc_a', 'acc_b']);
    final db = FakeFirebaseFirestore();
    final migrator =
        CloudMigrator(local: local, secure: FakeSecureStore(), db: db);

    await migrator.uploadLocalBands(_uid);

    expect(migrator.hasPendingUpload, isFalse);
    expect(
        (await db.collection('users').doc(_uid).collection('bands').get()).docs,
        isEmpty,
        reason: 'the fresh band was never claimed by the crashed run — it is '
            'not pre-sign-in data to move');
    expect(local.readAccountsRegistry()!.accounts.single.id, 'acc_fresh',
        reason: 'the registry is left exactly as the finished run set it');
  });

  test('a REJECTED write is permanent: it throws with the reason, keeps the '
      'profiles, and does not promise a resume', () async {
    // #30: the migrator threw, the caller swallowed it, and the pending flag
    // stayed set — so every launch re-ran the identical doomed upload and
    // told the artist the same reassuring lie about it.
    final (local, secure) = await _seedTwoBands();
    final migrator =
        CloudMigrator(local: local, secure: secure, db: _rejectingDb());

    final failure = await migrator
        .uploadLocalBands(_uid)
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(failure, isA<CloudUploadException>());
    final e = failure! as CloudUploadException;
    expect(e.transient, isFalse);
    expect(e.message, isNotEmpty, reason: 'the artist gets to be told WHY');
    // The flag is gone: a permanent failure re-armed forever is the bug.
    expect(migrator.hasPendingUpload, isFalse);
    // And nothing local was destroyed on the way out — the wipe lives past
    // the commit point, so the profiles are still here to try again with.
    expect(local.accountHasData('acc_a'), isTrue);
    expect(local.readRelayJar('acc_b'), isNotNull);
    expect(local.readAccountsRegistry()!.accounts, hasLength(2));
  });

  test('an OFFLINE failure is transient: it throws, and the pending flag '
      'survives so the next boot really does resume', () async {
    final (local, secure) = await _seedTwoBands();
    final migrator =
        CloudMigrator(local: local, secure: secure, db: _OfflineDb());

    final failure = await migrator
        .uploadLocalBands(_uid)
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(failure, isA<CloudUploadException>());
    expect((failure! as CloudUploadException).transient, isTrue);
    // The one case where "it will resume" is true — so the flag stays, and
    // the local bands stay with it.
    expect(migrator.hasPendingUpload, isTrue);
    expect(local.readCloudUploadPending()!.bandIds, ['acc_a', 'acc_b']);
    expect(local.accountHasData('acc_a'), isTrue);
  });

  test('a fresh run with a selection moves only the ticked bands and leaves '
      'the rest local, untouched', () async {
    // The per-profile move: the artist ticked one of two local bands. The
    // ticked one goes up and is wiped locally; the unticked one is not
    // uploaded, not wiped, and stays in the registry exactly as it was. Before
    // the fix there was no way to say "just this one" — uploadLocalBands moved
    // the whole registry, all or nothing.
    final (local, secure) = await _seedTwoBands();
    final db = FakeFirebaseFirestore();
    final migrator = CloudMigrator(local: local, secure: secure, db: db);

    final active =
        await migrator.uploadLocalBands(_uid, selectedBandIds: {'acc_a'});

    final bands = db.collection('users').doc(_uid).collection('bands');
    expect((await bands.get()).docs.map((d) => d.id), ['acc_a'],
        reason: 'only the ticked band reaches the cloud');
    expect(active, 'acc_a', reason: 'the app lands on a band that moved');
    // acc_a moved: local data wiped, out of the registry.
    expect(local.accountHasData('acc_a'), isFalse);
    // acc_b is the whole point — it was left behind, and it must be exactly
    // where it was: not in the cloud, still in the registry, data intact.
    expect((await bands.doc('acc_b').get()).exists, isFalse);
    final registry = local.readAccountsRegistry()!;
    expect(registry.accounts.map((b) => b.id), ['acc_b'],
        reason: 'an unticked profile stays local — nothing is deleted');
    expect(registry.activeId, 'acc_b',
        reason: 'the emptied slot re-points at a band that still exists');
    expect(local.readRelayJar('acc_b'), isNotNull);
    expect(local.readRelayHistory('acc_b'), hasLength(1),
        reason: 'the relay-tip archive — the only record of those tips '
            'anywhere — is untouched');
    expect(migrator.hasPendingUpload, isFalse);
  });

  test('a fresh run with an EMPTY selection moves nothing and loses nothing',
      () async {
    final (local, secure) = await _seedTwoBands();
    final db = FakeFirebaseFirestore();
    final migrator = CloudMigrator(local: local, secure: secure, db: db);

    final active =
        await migrator.uploadLocalBands(_uid, selectedBandIds: <String>{});

    expect(active, isNull);
    expect(
        (await db.collection('users').doc(_uid).collection('bands').get()).docs,
        isEmpty);
    // Both bands are precisely where they started.
    expect(local.readAccountsRegistry()!.accounts.map((b) => b.id),
        ['acc_a', 'acc_b']);
    expect(local.accountHasData('acc_a'), isTrue);
    expect(local.readRelayJar('acc_b'), isNotNull);
    expect(migrator.hasPendingUpload, isFalse);
  });

  test('a resume ignores a later selection — the crashed run\'s flag governs',
      () async {
    // Selection is a FRESH-run affordance. Once a pending flag exists, the set
    // it recorded is the truth; a new pick must not narrow (or widen) a move
    // already half-committed, or a crash-resume could strand a band the first
    // run had claimed.
    final (local, secure) = await _seedTwoBands();
    await local.saveCloudUploadPending(_uid, ['acc_a', 'acc_b']);
    final db = FakeFirebaseFirestore();
    final migrator = CloudMigrator(local: local, secure: secure, db: db);

    await migrator.uploadLocalBands(_uid, selectedBandIds: {'acc_a'});

    expect(
        (await db.collection('users').doc(_uid).collection('bands').get())
            .docs
            .map((d) => d.id),
        ['acc_a', 'acc_b'],
        reason: 'the resume moves what the flag claims, not what a new pick '
            'says');
    expect(local.readAccountsRegistry()!.accounts, isEmpty);
    expect(migrator.hasPendingUpload, isFalse);
  });
}
