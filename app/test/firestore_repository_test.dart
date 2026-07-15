import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/repository/firestore_repository.dart';
import 'package:live_tips/domain/app_settings.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/tip_jar.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const _uid = 'uid_1';
const _bandId = 'acc_cloud';

TipJar _tipJar({String url = 'https://buy.stripe.com/x'}) => TipJar(
      productId: 'prod_1',
      priceId: 'price_1',
      paymentLinkId: 'plink_1',
      url: url,
      currency: 'eur',
      displayName: 'The Sondheims',
      livemode: true,
    );

RelayJar _relayJar({String? message, String? revolut = 'sondheims'}) =>
    RelayJar(
      jarId: 'jar_1',
      tipUrl: 'https://live.tips/t/jar_1',
      artistName: 'The Sondheims',
      currency: 'eur',
      message: message,
      revolutUsername: revolut,
      createdAtMs: 1751500000000,
    );

Tip _relayTip(int serial, {int ts = 1751500000000}) => Tip.relayTip(
      amountMinor: 500 + serial,
      currency: 'eur',
      method: TipMethod.mobilepay,
      name: 'Maya',
      ts: ts + serial,
      serial: serial,
    );

Tip _stripeTip(String id, {required bool livemode}) => Tip(
      id: id,
      amountMinor: 500,
      currency: 'eur',
      createdAt: DateTime.utc(2026, 7, 3),
      livemode: livemode,
    );

LiveSession _session(String id, List<Tip> tips, {int startedAtMs = 0}) =>
    LiveSession(
      id: id,
      startedAt:
          DateTime.fromMillisecondsSinceEpoch(1751500000000 + startedAtMs),
      endedAt:
          DateTime.fromMillisecondsSinceEpoch(1751500000000 + startedAtMs + 1),
      currency: 'eur',
      goalMinor: 10000,
      tips: tips,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late LocalStore local;
  late FakeSecureStore secure;
  FirestoreRepository? repo;
  late int changes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = FakeFirebaseFirestore();
    local = LocalStore(await SharedPreferences.getInstance());
    secure = FakeSecureStore();
    changes = 0;
    repo = null;
  });

  tearDown(() => repo?.dispose());

  FirestoreRepository makeRepo() => repo = FirestoreRepository(
        uid: _uid,
        db: db,
        local: local,
        resolveSecure: () => secure,
        onChanged: () => changes++,
      );

  DocumentReference<Map<String, dynamic>> bandDoc([String id = _bandId]) =>
      db.collection('users').doc(_uid).collection('bands').doc(id);

  test('listBands mirrors the collection in creation order, skips malformed '
      'docs, and follows remote edits', () async {
    await bandDoc('acc_b').set({'name': 'Second', 'createdAtMs': 2});
    await bandDoc('acc_a').set({'name': 'First', 'createdAtMs': 1});
    await bandDoc('acc_c').set({'name': 'Third', 'createdAtMs': 3});
    await bandDoc('acc_bad').set({'name': 42, 'createdAtMs': 4});

    final repo = makeRepo();
    await pumpEventQueue();

    expect(repo.listBands().map((b) => b.id), ['acc_a', 'acc_b', 'acc_c'],
        reason: 'creation order, like the registry; the malformed doc is '
            'skipped rather than crashing the boot');
    expect(repo.listBands().first.name, 'First');

    // Another device renames a band — the mirror follows and says so.
    final before = changes;
    await bandDoc('acc_a')
        .set({'name': 'Renamed'}, SetOptions(merge: true));
    await pumpEventQueue();
    expect(repo.listBands().first.name, 'Renamed');
    expect(changes, greaterThan(before));
  });

  test('an empty from-cache snapshot leaves the repository cold — offline '
      'silence is not "no bands"', () async {
    final repo = makeRepo();
    // fake_cloud_firestore never raises a from-cache snapshot, so feed the
    // handler the one an offline boot starts with (a cold or — venue mode —
    // disabled cache).
    repo.applyBandsSnapshot(const {}, fromCache: true);

    expect(repo.isWarm, isFalse,
        reason: 'warming on it read as "this account has no bands", and a '
            'junk band got minted over the real ones and synced everywhere');
    expect(repo.listBands(), isEmpty);

    // Connectivity returns; the fake's snapshot stands in for the server's.
    await pumpEventQueue();
    expect(repo.isWarm, isTrue,
        reason: 'a server snapshot — even an empty one — is an answer');
  });

  test('a from-cache snapshot WITH bands warms the mirror — an offline '
      'restart still shows the cached bands', () async {
    final repo = makeRepo();
    repo.applyBandsSnapshot({
      _bandId: {'name': 'Cached Band', 'createdAtMs': 1},
    }, fromCache: true);

    expect(repo.isWarm, isTrue,
        reason: 'the cache vouches for what exists; only emptiness needs '
            'the server\'s word');
    expect(repo.listBands().single.name, 'Cached Band');
  });

  test('accountHasData answers null, not "empty", until every mirror has '
      'heard from the server', () async {
    await bandDoc()
        .collection('sessions')
        .doc('s1')
        .set(_session('s1', [_stripeTip('cs_1', livemode: true)]).toJson());

    final repo = makeRepo();
    expect(repo.accountHasData(_bandId), isNull,
        reason: 'history that exists only in Firestore must not read as '
            '"holds no data" — every caller of this method deletes on that '
            'answer');

    await pumpEventQueue();
    expect(repo.accountHasData(_bandId), isTrue);
  });

  test('from-cache empties never confirm "no data"; server snapshots do',
      () async {
    final repo = makeRepo();
    expect(repo.accountHasData(_bandId), isNull,
        reason: 'nothing has answered at all yet');

    // The offline boot: every mirror answers from an empty cache.
    repo.applyBandsSnapshot(const {}, fromCache: true);
    repo.applySessionsSnapshot(_bandId, const [], fromCache: true);
    repo.applyRelayTipsSnapshot(_bandId, const [], fromCache: true);
    expect(repo.accountHasData(_bandId), isNull,
        reason: 'a cache vouches for what exists, never for what does not');

    // Connectivity returns; the fake's snapshots stand in for the server's.
    await pumpEventQueue();
    expect(repo.accountHasData(_bandId), isFalse,
        reason: 'every mirror now has the server\'s word — empty is an '
            'answer');
  });

  test('a from-cache history snapshot still proves what exists', () async {
    final repo = makeRepo();
    repo.applySessionsSnapshot(
        _bandId,
        [
          _session('s1', [_stripeTip('cs_1', livemode: true)]).toJson(),
        ],
        fromCache: true);

    expect(repo.accountHasData(_bandId), isTrue,
        reason: 'presence needs no server confirmation — the cached session '
            'is real');
  });

  test('jar writes read back synchronously — before any ack — and land in '
      'the band doc', () async {
    final repo = makeRepo();
    await pumpEventQueue();
    await repo.upsertBandEntry(
        const BandAccount(id: _bandId, name: 'Band', createdAtMs: 5));

    final pending = repo.saveTipJar(_bandId, _tipJar());
    expect(repo.readTipJar(_bandId)?.url, 'https://buy.stripe.com/x',
        reason: 'the mirror is updated before the network ack');
    await pending;
    await pumpEventQueue();

    expect(repo.readTipJar(_bandId)?.url, 'https://buy.stripe.com/x',
        reason: 'the listener echo must not undo the write');
    final data = (await bandDoc().get()).data()!;
    expect(data['name'], 'Band');
    expect((data['tipJar'] as Map)['url'], 'https://buy.stripe.com/x');
  });

  test('saveRelayJar replaces the field wholesale — cleared optionals do not '
      'resurrect under merge', () async {
    final repo = makeRepo();
    await repo.saveRelayJar(_bandId, _relayJar(message: 'Hi from the stage'));
    await pumpEventQueue();

    await repo.saveRelayJar(_bandId, _relayJar(message: null));
    await pumpEventQueue();

    expect(repo.readRelayJar(_bandId)?.message, isNull);
    final stored = (await bandDoc().get()).data()!['relayJar'] as Map;
    expect(stored.containsKey('message'), isFalse,
        reason: 'the omitted optional must be deleted from the doc, or the '
            'next snapshot would bring the old message back');
    expect(stored['revolutUsername'], 'sondheims');
  });

  test('clearTipJar deletes the field but keeps the band doc', () async {
    final repo = makeRepo();
    await repo.upsertBandEntry(
        const BandAccount(id: _bandId, name: 'Band', createdAtMs: 5));
    await repo.saveTipJar(_bandId, _tipJar());

    await repo.clearTipJar(_bandId);
    expect(repo.readTipJar(_bandId), isNull,
        reason: 'optimistic mirror update, like LocalStore');
    await pumpEventQueue();

    final data = (await bandDoc().get()).data()!;
    expect(data.containsKey('tipJar'), isFalse);
    expect(data['name'], 'Band', reason: 'the band entry itself survives');
  });

  test('relay history: appends write docs keyed by tip id, dedupe, newest '
      'first', () async {
    final repo = makeRepo();
    await repo.appendRelayHistory(_bandId, [_relayTip(0), _relayTip(1)]);
    // Relay redelivery / resumed-session replay: same tip, same id.
    await repo.appendRelayHistory(_bandId, [_relayTip(0), _relayTip(2)]);
    await pumpEventQueue();

    expect(repo.readRelayHistory(_bandId).map((t) => t.id), [
      'relay_1751500000002_2',
      'relay_1751500000001_1',
      'relay_1751500000000_0',
    ]);
    final docs = await bandDoc().collection('relayTips').get();
    expect(docs.docs, hasLength(3), reason: 'no duplicate docs');
  });

  test('relay history mirror is capped at ${LocalStore.relayHistoryCap}',
      () async {
    final col = bandDoc().collection('relayTips');
    for (var i = 0; i < LocalStore.relayHistoryCap + 5; i++) {
      await col.doc('t$i').set(_relayTip(i).toJson());
    }

    final repo = makeRepo();
    expect(repo.readRelayHistory(_bandId), isEmpty,
        reason: 'first read starts the lazy listener');
    await pumpEventQueue();

    final history = repo.readRelayHistory(_bandId);
    expect(history, hasLength(LocalStore.relayHistoryCap));
    expect(history.first.id,
        'relay_${1751500000000 + LocalStore.relayHistoryCap + 4}_'
        '${LocalStore.relayHistoryCap + 4}',
        reason: 'the newest survives; the oldest fall off the window');
  });

  test(
      'an OFF-SESSION server-written tip (#71) surfaces through the '
      'existing relayTips listener — no new plumbing, fields intact',
      () async {
    // No set is running, every device of the artist may be off: the server
    // routes the fan tip into the band\'s relayTips archive, in exactly the
    // appendRelayHistory doc shape (Tip.toJson, doc id = tip id).
    final tip = Tip.relayTip(
      amountMinor: 700,
      currency: 'eur',
      method: TipMethod.revolut,
      name: 'Sam',
      message: 'From the 03:00 crowd',
      ts: 1751500009999,
      serial: 0,
      relayId: 'srv_night',
      songId: 'sng_1',
      songTitle: 'Wonderwall',
    );
    await bandDoc()
        .collection('relayTips')
        .doc(tip.id)
        .set({...tip.toJson(), 'updatedAtMs': 1});

    // The next launch: the repository's lazy listener — the one History and
    // the home Recent-tips card already read through — delivers it.
    final repo = makeRepo();
    repo.readRelayHistory(_bandId); // first read starts the listener
    await pumpEventQueue();

    final surfaced = repo.readRelayHistory(_bandId).single;
    expect(surfaced.id, 'relay_srv_night');
    expect(surfaced.amountMinor, 700);
    expect(surfaced.method, TipMethod.revolut);
    expect(surfaced.verified, isFalse,
        reason: 'a fan-declared tip stays unverified until the artist says');
    expect(surfaced.name, 'Sam');
    expect(surfaced.message, 'From the 03:00 crowd');
    expect(surfaced.songId, 'sng_1');
    expect(surfaced.songTitle, 'Wonderwall');
    expect(surfaced.livemode, isTrue,
        reason: 'not swept at 04:00 — the tip is real, durable money now');
  });

  test('session history appends and purgeSimulatedData drops demo/test '
      'sessions', () async {
    final repo = makeRepo();
    await repo.appendSessionToHistory(_bandId,
        _session('demo', [_stripeTip('demo_1', livemode: false)]));
    await repo.appendSessionToHistory(
        _bandId,
        _session('live', [_stripeTip('cs_live_1', livemode: true)],
            startedAtMs: 1));
    await repo.appendSessionToHistory(
        _bandId,
        _session('test', [_stripeTip('cs_test_1', livemode: false)],
            startedAtMs: 2));
    await pumpEventQueue();
    expect(repo.readSessionHistory(_bandId).map((s) => s.id),
        ['demo', 'live', 'test']);

    await repo.purgeSimulatedData(_bandId);
    await pumpEventQueue();

    expect(repo.readSessionHistory(_bandId).map((s) => s.id), ['live']);
    final docs = await bandDoc().collection('sessions').get();
    expect(docs.docs.map((d) => d.id), ['live']);
  });

  test('purgeSimulatedData works without a prior history read and clears a '
      'simulated local crash snapshot', () async {
    await bandDoc().collection('sessions').doc('demo').set(
        _session('demo', [_stripeTip('demo_1', livemode: false)]).toJson());
    await local.saveActiveSession(_bandId,
        _session('demo2', [_stripeTip('demo_2', livemode: false)]), 'cur_1');

    final repo = makeRepo();
    await repo.purgeSimulatedData(_bandId);

    final docs = await bandDoc().collection('sessions').get();
    expect(docs.docs, isEmpty,
        reason: 'the purge queries the collection, not the (unstarted) '
            'mirror');
    expect(local.readActiveSession(_bandId), isNull);
    expect(local.readActiveCursor(_bandId), isNull);
  });

  test('writeApiKey goes keychain-first, then to the secrets doc', () async {
    final repo = makeRepo();
    await repo.writeApiKey(_bandId, ' rk_live_1 ');
    await pumpEventQueue();

    expect(await secure.readApiKey(_bandId), 'rk_live_1');
    final doc = await bandDoc().collection('secrets').doc('v1').get();
    expect(doc.data()!['stripeKey'], 'rk_live_1');
    expect(await repo.readApiKey(_bandId), 'rk_live_1');
  });

  test('a locked keychain fails writeApiKey before anything reaches the doc',
      () async {
    final repo = makeRepo();
    secure.failing = true;

    await expectLater(repo.writeApiKey(_bandId, 'rk_live_1'), throwsException,
        reason: 'same contract as the local profile — callers catch');
    final doc = await bandDoc().collection('secrets').doc('v1').get();
    expect(doc.exists, isFalse,
        reason: 'a key the fast path cannot produce must not exist in the '
            'cloud either');
  });

  test('reads are keychain-first: the mirror only answers when the keychain '
      'cannot', () async {
    await bandDoc().set({'name': 'Band', 'createdAtMs': 1});
    await bandDoc()
        .collection('secrets')
        .doc('v1')
        .set({'stripeKey': 'rk_cloud'});

    final repo = makeRepo();
    await pumpEventQueue();
    expect(await secure.readApiKey(_bandId), 'rk_cloud',
        reason: 'the remote snapshot was written through to the keychain');

    // A value only the keychain holds (a fresher local write the doc has
    // not echoed) wins over the mirror, because the keychain is read first.
    await secure.writeApiKey(_bandId, 'rk_newer');
    expect(await repo.readApiKey(_bandId), 'rk_newer');
  });

  test('the mirror serves reads while the keychain is locked, then backfills '
      'it', () async {
    await bandDoc().set({'name': 'Band', 'createdAtMs': 1});
    secure.failing = true; // locked from the start: no write-through either

    final repo = makeRepo();
    await pumpEventQueue();
    await bandDoc()
        .collection('secrets')
        .doc('v1')
        .set({'relaySecret': 'sec_cloud'});
    await pumpEventQueue();

    expect(await repo.readRelaySecret(_bandId), 'sec_cloud',
        reason: 'the mirror is exactly for the moments the keychain is not '
            'available');

    secure.failing = false;
    expect(await repo.readRelaySecret(_bandId), 'sec_cloud');
    await pumpEventQueue();
    expect(await secure.readRelaySecret(_bandId), 'sec_cloud',
        reason: 'a mirror hit backfills the keychain for the fast path');
  });

  test('a secrets doc written by another device is written through to the '
      'keychain and announced', () async {
    await bandDoc().set({'name': 'Band', 'createdAtMs': 1});
    final repo = makeRepo();
    await pumpEventQueue();
    expect(repo.listBands(), hasLength(1));

    final before = changes;
    await bandDoc().collection('secrets').doc('v1').set({
      'stripeKey': 'rk_other_device',
      'updatedAtMs': 1,
    });
    await pumpEventQueue();

    expect(await secure.readApiKey(_bandId), 'rk_other_device',
        reason: 'the keychain doubles as the cloud profile\'s cache');
    expect(changes, greaterThan(before));
  });

  // A second "device": its own keychain over the same account's Firestore.
  (FirestoreRepository, FakeSecureStore) makeDeviceB() {
    final secureB = FakeSecureStore();
    final repoB = FirestoreRepository(
      uid: _uid,
      db: db,
      local: local,
      resolveSecure: () => secureB,
    );
    addTearDown(repoB.dispose);
    return (repoB, secureB);
  }

  test('disconnecting Stripe on one device clears the other device\'s '
      'keychain — the tombstone travels', () async {
    await bandDoc().set({'name': 'Band', 'createdAtMs': 1});
    final repoA = makeRepo();
    final (repoB, secureB) = makeDeviceB();
    await repoA.writeApiKey(_bandId, 'rk_live_1');
    await pumpEventQueue();
    expect(await secureB.readApiKey(_bandId), 'rk_live_1',
        reason: 'the connect synced to device B first');

    await repoA.deleteApiKey(_bandId);
    await pumpEventQueue();

    expect(await secureB.readApiKey(_bandId), isNull,
        reason: 'a revocation must revoke everywhere, not just on the '
            'device that tapped Disconnect');
    expect(await repoB.readApiKey(_bandId), isNull,
        reason: 'neither the keychain nor the mirror may keep serving it');
  });

  test('a device that slept through the disconnect still revokes on its '
      'first snapshot', () async {
    await bandDoc().set({'name': 'Band', 'createdAtMs': 1});
    await bandDoc().collection('secrets').doc('v1').set({
      'stripeKeyDeletedAtMs': 5,
      'updatedAtMs': 5,
    });
    await secure.writeApiKey(_bandId, 'rk_stale');

    final repo = makeRepo();
    await pumpEventQueue();

    expect(await secure.readApiKey(_bandId), isNull,
        reason: 'a fresh mirror starts untombstoned, so the very first '
            'snapshot is edge enough to clear the keychain');
    expect(await repo.readApiKey(_bandId), isNull);
  });

  test('a secret the doc never held is NOT deleted — bare absence stays '
      'additions-only', () async {
    await bandDoc().set({'name': 'Band', 'createdAtMs': 1});
    // The doc knows the relay secret but never saw the Stripe key: exactly
    // what a migration over a locked keychain leaves behind.
    await bandDoc().collection('secrets').doc('v1').set({
      'relaySecret': 'sec_cloud',
      'updatedAtMs': 1,
    });
    await secure.writeApiKey(_bandId, 'rk_local_only');

    final repo = makeRepo();
    await pumpEventQueue();

    expect(await repo.readApiKey(_bandId), 'rk_local_only',
        reason: 'no tombstone means the doc says nothing about the key — '
            'the migration-skipped secret must survive');
  });

  test('a reconnect after a disconnect wins: the fresh key clears the '
      'tombstone and syncs back out', () async {
    await bandDoc().set({'name': 'Band', 'createdAtMs': 1});
    final repoA = makeRepo();
    final (repoB, secureB) = makeDeviceB();
    await repoA.writeApiKey(_bandId, 'rk_first');
    await pumpEventQueue();
    await repoA.deleteApiKey(_bandId);
    await pumpEventQueue();
    expect(await secureB.readApiKey(_bandId), isNull);

    await repoA.writeApiKey(_bandId, 'rk_second');
    await pumpEventQueue();

    expect(await secureB.readApiKey(_bandId), 'rk_second',
        reason: 'a key written after the tombstone must win');
    expect(await repoB.readApiKey(_bandId), 'rk_second');
    final doc = await bandDoc().collection('secrets').doc('v1').get();
    expect(doc.data()!.containsKey('stripeKeyDeletedAtMs'), isFalse,
        reason: 'the write evicts the tombstone in the same doc write');
  });

  test('deleteRelaySecret rides the same tombstone mechanism', () async {
    await bandDoc().set({'name': 'Band', 'createdAtMs': 1});
    final repoA = makeRepo();
    final (repoB, secureB) = makeDeviceB();
    await repoA.writeRelaySecret(_bandId, 'sec_1');
    await pumpEventQueue();
    expect(await secureB.readRelaySecret(_bandId), 'sec_1');

    await repoA.deleteRelaySecret(_bandId);
    await pumpEventQueue();

    expect(await secureB.readRelaySecret(_bandId), isNull,
        reason: 'forgetting the relay jar must forget its secret on every '
            'device');
    expect(await repoB.readRelaySecret(_bandId), isNull);
  });

  test('wipeAccountData removes every doc and the local snapshot', () async {
    final repo = makeRepo();
    await repo.upsertBandEntry(
        const BandAccount(id: _bandId, name: 'Band', createdAtMs: 5));
    await repo.saveTipJar(_bandId, _tipJar());
    await repo.appendSessionToHistory(
        _bandId, _session('live', [_stripeTip('cs_1', livemode: true)]));
    await repo.appendRelayHistory(_bandId, [_relayTip(0)]);
    await repo.writeApiKey(_bandId, 'rk_live_1');
    await repo.saveActiveSession(_bandId, _session('active', const []), 'c1');
    await pumpEventQueue();
    expect(repo.accountHasData(_bandId), isTrue);

    await repo.wipeAccountData(_bandId);
    await pumpEventQueue();

    expect((await bandDoc().get()).exists, isFalse);
    expect((await bandDoc().collection('sessions').get()).docs, isEmpty);
    expect((await bandDoc().collection('relayTips').get()).docs, isEmpty);
    expect(
        (await bandDoc().collection('secrets').doc('v1').get()).exists, isFalse);
    expect(local.readActiveSession(_bandId), isNull,
        reason: 'the device-local crash snapshot goes with the band');
    expect(repo.accountHasData(_bandId), isFalse);
    expect(repo.listBands(), isEmpty);
  });

  test('wipeAccountData refuses a cache-backed listing: offline it throws '
      'and deletes NOTHING', () async {
    final repo = makeRepo();
    await repo.upsertBandEntry(
        const BandAccount(id: _bandId, name: 'Band', createdAtMs: 5));
    await repo.appendSessionToHistory(
        _bandId, _session('live', [_stripeTip('cs_1', livemode: true)]));
    await repo.appendRelayHistory(_bandId, [_relayTip(0)]);
    await pumpEventQueue();

    // Offline. The real client's server-sourced get throws `unavailable`
    // instead of quietly answering from a partial cache — the fake serves
    // the truth for every get, so the seam raises what the plugin would.
    // (A cache-backed listing here once let docs this device never synced
    // survive the batch, stranding an undeletable history under a deleted
    // band doc.)
    repo.serverGetOverride = (query) => throw FirebaseException(
        plugin: 'cloud_firestore', code: 'unavailable');

    await expectLater(repo.wipeAccountData(_bandId),
        throwsA(isA<FirebaseException>()),
        reason: 'a wipe that cannot enumerate authoritatively must fail '
            'loudly, never run over whatever happens to be cached');

    expect((await bandDoc().get()).exists, isTrue,
        reason: 'nothing may be deleted on a refusal — a deleted band doc '
            'over surviving history is exactly the orphan the server-sourced '
            'listing exists to prevent');
    expect((await bandDoc().collection('sessions').get()).docs, hasLength(1));
    expect((await bandDoc().collection('relayTips').get()).docs, hasLength(1));

    // Connectivity returns: the same wipe now completes.
    repo.serverGetOverride = null;
    await repo.wipeAccountData(_bandId);
    expect((await bandDoc().get()).exists, isFalse);
    expect((await bandDoc().collection('sessions').get()).docs, isEmpty);
  });

  test('the active-session crash snapshot lives in LocalStore, never in '
      'Firestore', () async {
    final repo = makeRepo();
    await repo.saveActiveSession(
        _bandId, _session('active', const []), 'cur_1');
    await pumpEventQueue();

    expect(repo.readActiveSession(_bandId)?.id, 'active');
    expect(repo.readActiveCursor(_bandId), 'cur_1');
    expect(local.readActiveSession(_bandId)?.id, 'active',
        reason: 'delegated to LocalStore verbatim');
    final bands = await db.collection('users').doc(_uid).collection('bands').get();
    expect(bands.docs, isEmpty, reason: 'nothing was synced');

    await repo.clearActiveSession(_bandId);
    expect(repo.readActiveSession(_bandId), isNull);
  });

  test('settings: local fallback before the first snapshot, mirror after, '
      'whole-doc save', () async {
    await local.saveSettings(
        const AppSettings(themeMode: AppThemeMode.dark));
    final repo = makeRepo();
    await pumpEventQueue();
    expect(repo.readSettings().themeMode, AppThemeMode.dark,
        reason: 'no cloud settings yet — the local copy keeps the theme '
            'from flashing');

    final settingsDoc =
        db.collection('users').doc(_uid).collection('settings').doc('app');
    await settingsDoc.set(const AppSettings(
            themeMode: AppThemeMode.light, localeCode: 'de')
        .toJson());
    await pumpEventQueue();
    expect(repo.readSettings().themeMode, AppThemeMode.light);
    expect(repo.readSettings().localeCode, 'de');

    // Back to the device language: the save must shed localeCode entirely.
    await repo.saveSettings(
        const AppSettings(themeMode: AppThemeMode.light));
    expect(repo.readSettings().localeCode, isNull);
    await pumpEventQueue();
    expect((await settingsDoc.get()).data()!.containsKey('localeCode'),
        isFalse);
  });

  test('the active band id is a device pref keyed by uid', () async {
    final repo = makeRepo();
    expect(repo.readActiveBandId(), isNull);

    await repo.saveActiveBandId(_bandId);

    expect(repo.readActiveBandId(), _bandId);
    expect(local.readActiveCloudBand(_uid), _bandId);
    expect(local.prefs.getString('active_band_v1_$_uid'), _bandId,
        reason: 'device-local, never in Firestore');
  });

  test('removeBandEntry deletes the band doc', () async {
    final repo = makeRepo();
    await repo.upsertBandEntry(
        const BandAccount(id: _bandId, name: 'Band', createdAtMs: 5));
    await pumpEventQueue();
    expect(repo.listBands(), hasLength(1));

    await repo.removeBandEntry(_bandId);
    await pumpEventQueue();

    expect(repo.listBands(), isEmpty);
    expect((await bandDoc().get()).exists, isFalse);
  });
}
