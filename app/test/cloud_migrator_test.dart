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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('happy path: everything lands in the cloud, local becomes one fresh '
      'empty band, keychain untouched', () async {
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

    // The local side: bands wiped, one fresh empty band, flag cleared.
    expect(local.accountHasData('acc_a'), isFalse);
    expect(local.accountHasData('acc_b'), isFalse);
    final registry = local.readAccountsRegistry()!;
    expect(registry.accounts, hasLength(1));
    expect(registry.accounts.single.id, isNot(anyOf('acc_a', 'acc_b')));
    expect(registry.accounts.single.name, isEmpty);
    expect(registry.activeId, registry.accounts.single.id);
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
    expect(local.readAccountsRegistry()!.accounts, hasLength(1));
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
    expect(registry.accounts.single.id, isNot(anyOf('acc_a', 'acc_b')),
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
    expect(local.readAccountsRegistry()!.accounts, hasLength(1));
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
    // The crashed run finished everything except clearing the flag: the
    // registry already holds the fresh post-upload band.
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
}
