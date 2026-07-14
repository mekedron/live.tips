import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/relay/firestore_tip_channel.dart';
import 'package:live_tips/data/tip_channel.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/cloud_session_coordinator.dart';
import 'package:live_tips/state/jar_requests_publisher.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Who attaches the relay tip feed in a cloud session, proven end to end
/// through the real controller, the real [CloudSessionCoordinator] and the
/// real [FirestoreTipChannel] — with devices that have NO Stripe API key,
/// which is exactly the desktop a cloud account signs into fresh (the key
/// lives on the phone's keychain, or in cloud custody; it never travels).
///
/// The ground truth these tests pin: leading is about SERVING THE JAR — the
/// relay channel, the `jars/{jarId}/pendingTips` drain, the lease — and the
/// Stripe key gates only the poller (a key-less leader polls
/// [NullTipSource]). So the device that STARTS a session leads
/// unconditionally, and a key-less follower may RESCUE a session whose
/// leader died (#70): the leader is the queue's only reader, and the old
/// key-gated takeover left fans' tips waiting out the 1-hour hold unseen
/// while every surviving device showed a running set. Every other
/// coordinator test seeds a leader-capable device, which is how both halves
/// went unasked for so long.

const _uid = 'uid_cloud';
const _bandId = 'band_1';
const _jarId = 'jar_live';
const _pendingPath = 'jars/$_jarId/pendingTips';

class _EmptySource extends TipSource {
  @override
  Future<void> prime(DateTime startedAt,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Tip>> pollNew() async => const [];

  @override
  String? get cursor => null;
}

Future<void> _settle([int rounds = 40]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// See cloud_session_coordinator_test.dart — same reasoning.
class _NoopRevision extends RepoRevisionNotifier {
  @override
  void bump() {}
}

/// fake_cloud_firestore's runTransaction is a dummy: the handler runs with
/// no serialization, and its writes land a few microtasks AFTER the call —
/// so two racing takeover "transactions" can both read the same stale lease
/// and both win, which real Firestore makes impossible (transactions are
/// serialized under optimistic concurrency; a loser is retried and re-reads
/// the winner's write). This veneer restores the one guarantee the takeover
/// race leans on: transactions run one at a time, and the next one starts
/// only after the previous one's writes are visible. The mold is
/// cloud_session_coordinator_test.dart's StaleCacheFirestore — model the
/// real SDK behaviour the fake lacks, delegate everything else.
class _SerialTxFirestore extends Fake implements FirebaseFirestore {
  _SerialTxFirestore(this.inner);

  final FakeFirebaseFirestore inner;
  Future<void> _queue = Future.value();

  @override
  DocumentReference<Map<String, dynamic>> doc(String documentPath) =>
      inner.doc(documentPath);

  @override
  CollectionReference<Map<String, dynamic>> collection(
          String collectionPath) =>
      inner.collection(collectionPath);

  @override
  WriteBatch batch() => inner.batch();

  @override
  Future<T> runTransaction<T>(TransactionHandler<T> transactionHandler,
      {Duration timeout = const Duration(seconds: 30),
      int maxAttempts = 5}) {
    final result = _queue.then((_) async {
      final value = await inner.runTransaction(transactionHandler,
          timeout: timeout, maxAttempts: maxAttempts);
      // The dummy transaction's writes are fire-and-forget microtasks; a
      // timer-turn yield drains them so the next reader sees them.
      await Future<void>.delayed(Duration.zero);
      return value;
    });
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<void> waitForPendingWrites() => inner.waitForPendingWrites();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late _SerialTxFirestore txDb;
  late LocalStore store;

  DocumentReference<Map<String, dynamic>> liveDoc() =>
      db.doc('users/$_uid/live/current');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = FakeFirebaseFirestore();
    txDb = _SerialTxFirestore(db);
    store = LocalStore(await SharedPreferences.getInstance());
    await store.saveAccountsDirectory(AccountsDirectory(
      accounts: [
        AppAccount.localProfile(),
        const AppAccount(id: _uid, name: 'Casey', kind: AccountKind.google),
      ],
      activeAccountId: _uid,
    ));
    await store.saveActiveCloudBand(_uid, _bandId);
    // The band mirrors a relay jar — that (not a Stripe key) is what makes
    // the fresh desktop "connected" enough to go live at all.
    await db.doc('users/$_uid/bands/$_bandId').set({
      'name': 'The Sondheims',
      'createdAtMs': 1,
      'relayJar': {
        'jarId': _jarId,
        'tipUrl': 'https://tip.live.tips/$_jarId',
        'artistName': 'The Sondheims',
        'currency': 'usd',
        'createdAtMs': 1,
      },
    });
  });

  /// A cloud device WITHOUT a Stripe key (no secure-store seed, no initial
  /// key): `app.apiKey == null` — the fresh-desktop shape. Its relay is the
  /// real [FirestoreTipChannel] over the shared fake, and its request
  /// publisher is the real [JarRequestsPublisher] over the same recorded
  /// backend, so `backend.names` shows exactly which devices spoke to the
  /// fan page (claimJar = attached the feed; setJarRequests = published the
  /// request state).
  Future<({ProviderContainer container, FakeCallables backend})> device(
      String deviceId) async {
    final backend = FakeCallables();
    final container = ProviderContainer(overrides: [
      repoRevisionProvider.overrideWith(_NoopRevision.new),
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(FakeSecureStore()),
      firestoreProvider.overrideWithValue(txDb),
      authServiceProvider.overrideWithValue(FakeAuthService(
          user: const AuthUser(uid: _uid, kind: AccountKind.google))),
      deviceIdProvider.overrideWithValue(deviceId),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) => _EmptySource()),
      relayChannelFactoryProvider.overrideWithValue(
          ({required demo, required jar, required secret}) =>
              FirestoreTipChannel(
                db: db,
                auth: FakeRelayAuth(),
                client: fakeRelayClient(backend),
                jarId: _jarId,
                secret: 'sec',
                backoff: (_) => null,
              )),
      jarRequestsPublisherFactoryProvider
          .overrideWithValue(() => JarRequestsPublisher(
                client: fakeRelayClient(backend),
                jar: const RelayJar(
                  jarId: _jarId,
                  tipUrl: 'https://tip.live.tips/$_jarId',
                  artistName: 'The Sondheims',
                  currency: 'usd',
                  createdAtMs: 1,
                ),
                secret: 'sec',
              )),
    ]);
    var disposed = false;
    addTearDown(() {
      if (!disposed) container.dispose();
      disposed = true;
    });
    final repo = container.read(accountDataRepositoryProvider);
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(Duration.zero);
      if (repo.listBands().any((b) => b.id == _bandId)) break;
    }
    expect(container.read(appStateProvider).accountId, _bandId,
        reason: 'the device must land on the seeded cloud band');
    await _settle();
    return (container: container, backend: backend);
  }

  test(
      'a key-less device that STARTS the session leads anyway: the relay '
      'channel attaches (claimJar), health reaches ok, and pendingTips are '
      'drained into the session', () async {
    final (container: a, backend: backend) = await device('dev_a');
    expect(a.read(appStateProvider).apiKey, isNull,
        reason: 'this is the fresh-desktop shape: no Stripe key on device');

    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await _settle();

    // The starter leads unconditionally — no key check anywhere in _claim.
    final doc = (await liveDoc().get()).data()!;
    expect(doc['active'], isTrue);
    expect(doc['leaderDeviceId'], 'dev_a',
        reason: 'the session-starting device installs itself as leader '
            'regardless of the Stripe key');

    // Leading is what attaches the relay: the jar was claimed and the
    // pendingTips listener is up.
    expect(backend.names, contains('claimJar'));
    expect(a.read(liveSessionProvider)!.relay, RelayHealth.ok,
        reason: 'the fan-page feed must come up for a key-less leader');

    // A fan tip through the relay reaches the stage, and delivery deletes
    // the queue doc (the relay keeps no tip history).
    await db.collection(_pendingPath).add({
      'method': 'revolut',
      'amountMinor': 700,
      'currency': 'USD',
      'name': 'Sam',
      'message': 'Great set!',
      'tsMs': 1770000000000,
    });
    await _settle();

    final state = a.read(liveSessionProvider)!;
    expect(state.session.totalMinor, 700,
        reason: 'the pendingTips queue drains into the session');
    expect((await db.collection(_pendingPath).get()).docs, isEmpty,
        reason: 'delivery IS deletion');
  });

  test(
      'a key-less JOINER stays a follower while the lease is fresh — no '
      'takeover bid, no relay pill at all (LiveState.relay is null, so '
      '"Tip page connecting…" can only come from a device that leads)',
      () async {
    final (container: a, backend: _) = await device('dev_a');
    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await _settle();

    final (container: b, backend: backendB) = await device('dev_b');
    final info =
        ActiveSessionInfo.fromData((await liveDoc().get()).data())!;
    final joined = await b.read(liveSessionProvider.notifier).join(info);
    await _settle();

    expect(joined, isTrue);
    expect((await liveDoc().get()).data()!['leaderDeviceId'], 'dev_a',
        reason: 'a live lease is a live leader — nothing to rescue');
    expect(b.read(liveSessionProvider)!.relay, isNull,
        reason: 'a follower runs no relay channel and shows no second pill');
    expect(backendB.names, isNot(contains('claimJar')),
        reason: 'only the leader claims the jar');
  });

  test(
      'a key-less follower RESCUES a dead leader (#70): takes the stale '
      'lease over, attaches the relay, republishes the request state, and '
      'the pendingTips queue has a reader again', () async {
    final (container: a, backend: _) = await device('dev_a');
    await a
        .read(liveSessionProvider.notifier)
        .start(goalMinor: 10000, requestsOpen: true);
    await _settle();
    final info =
        ActiveSessionInfo.fromData((await liveDoc().get()).data())!;

    // The leader dies without stopping: its container goes away, the doc
    // keeps saying dev_a — and then two minutes of silence pass.
    a.dispose();
    await liveDoc().set({
      'leaderLeaseUntilMs': DateTime.now().millisecondsSinceEpoch -
          CloudSessionCoordinator.staleMs -
          60000,
    }, SetOptions(merge: true));

    final (container: b, backend: backendB) = await device('dev_b');
    expect(b.read(appStateProvider).apiKey, isNull,
        reason: 'the rescuer has no Stripe key — the shape under key '
            'custody, where NO device holds one');
    final joined = await b.read(liveSessionProvider.notifier).join(info);
    expect(joined, isTrue);
    await _settle();

    final doc = (await liveDoc().get()).data()!;
    expect(doc['active'], isTrue);
    expect(doc['leaderDeviceId'], 'dev_b',
        reason: 'leading is serving the jar, not polling Stripe — a '
            'key-less device may take a dead leader over');

    // The takeover attached the relay: jar claimed, feed up, pill showing.
    expect(backendB.names, contains('claimJar'));
    expect(b.read(liveSessionProvider)!.relay, RelayHealth.ok,
        reason: 'the fan-page feed must come back up under the new leader');

    // ...and the fan page heard its new voice: the request state was
    // republished on takeover (the joiner itself never published — the
    // old leader may have died with the last publish unsent).
    expect(backendB.names, contains('setJarRequests'));

    // The queue has a reader again: a fan tip drains into the session
    // instead of waiting out the 1-hour hold unseen.
    await db.collection(_pendingPath).add({
      'method': 'revolut',
      'amountMinor': 700,
      'currency': 'USD',
      'name': 'Sam',
      'message': 'Great set!',
      'tsMs': 1770000000000,
    });
    await _settle();
    expect(b.read(liveSessionProvider)!.session.totalMinor, 700);
    expect((await db.collection(_pendingPath).get()).docs, isEmpty,
        reason: 'delivery IS deletion');
  });

  test(
      'two key-less followers race a dead leader\'s lease: the transactional '
      'claim lets exactly one through — one relay, one fan-page voice',
      () async {
    final (container: a, backend: _) = await device('dev_a');
    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await _settle();
    final info =
        ActiveSessionInfo.fromData((await liveDoc().get()).data())!;

    final (container: b, backend: backendB) = await device('dev_b');
    final (container: c, backend: backendC) = await device('dev_c');
    expect(await b.read(liveSessionProvider.notifier).join(info), isTrue);
    expect(await c.read(liveSessionProvider.notifier).join(info), isTrue);
    await _settle();

    // The leader dies; ONE doc write stales the lease, reaching both
    // followers' listeners in the same breath — both bid, the claim
    // transaction arbitrates.
    a.dispose();
    await liveDoc().set({
      'leaderLeaseUntilMs': DateTime.now().millisecondsSinceEpoch -
          CloudSessionCoordinator.staleMs -
          60000,
    }, SetOptions(merge: true));
    await _settle();

    final leader =
        (await liveDoc().get()).data()!['leaderDeviceId'] as String;
    expect({'dev_b', 'dev_c'}, contains(leader));
    final winner = leader == 'dev_b' ? b : c;
    final loser = leader == 'dev_b' ? c : b;
    final winnerBackend = leader == 'dev_b' ? backendB : backendC;
    final loserBackend = leader == 'dev_b' ? backendC : backendB;

    expect(winnerBackend.names, contains('claimJar'));
    expect(winner.read(liveSessionProvider)!.relay, RelayHealth.ok);
    expect(loserBackend.names, isNot(contains('claimJar')),
        reason: 'the loser saw the winner\'s fresh lease inside its own '
            'transaction and stayed a quiet follower');
    expect(loser.read(liveSessionProvider)!.relay, isNull,
        reason: 'no second relay channel, no second pill');
  });
}
