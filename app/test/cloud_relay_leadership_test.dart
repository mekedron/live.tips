import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/relay/jar_claimer.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/cloud_session_coordinator.dart';
import 'package:live_tips/state/jar_requests_publisher.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// How a cloud session relates to the jar after #71, proven end to end
/// through the real controller, the real [CloudSessionCoordinator] and the
/// real [JarClaimer] — with devices that have NO Stripe API key, which is
/// exactly the desktop a cloud account signs into fresh.
///
/// The ground truth these tests pin: for a cloud account the SERVER writes
/// fan-page tips straight into the account's own collections (the session's
/// tips subcollection during a set), so NO device runs a relay channel, no
/// pendingTips queue is drained, and money no longer rides on leadership —
/// the #70 failure mode ("a dead leader orphans the relay feed") is
/// structurally impossible: there is no client feed to orphan. What is left
/// of the jar relationship is the CLAIM: every device claims at attach,
/// carrying `bandId` + `owned` (the route the server branches on), under
/// the pinned contract that bandId never travels without owned. Leadership
/// survives for what still needs one voice: the Stripe poll, the lease, the
/// finalize, and the fan page's request-queue publish (#70's takeover
/// semantics stay, re-pinned here).

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

  /// Writes a fan tip the way the SERVER now does (#71): straight into the
  /// live session's tips subcollection, doc id = tip id, in the exact
  /// `Tip.toJson` wire shape (the leader's `_publish` shape — the server
  /// half is built against precisely this serializer).
  Future<Tip> serverWritesSessionTip(
    String sessionId, {
    required String relayId,
    int amountMinor = 700,
    String? songId,
    String? songTitle,
  }) async {
    final tip = Tip.relayTip(
      amountMinor: amountMinor,
      currency: 'usd',
      method: TipMethod.revolut,
      name: 'Sam',
      message: 'Great set!',
      ts: DateTime.now().millisecondsSinceEpoch,
      serial: 0,
      relayId: relayId,
      songId: songId,
      songTitle: songTitle,
    );
    await db
        .doc('users/$_uid/bands/$_bandId/sessions/$sessionId/tips/${tip.id}')
        .set({
      ...tip.toJson(),
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    });
    return tip;
  }

  /// A cloud device WITHOUT a Stripe key (no secure-store seed, no initial
  /// key): `app.apiKey == null` — the fresh-desktop shape. Its jar claim is
  /// the real [JarClaimer] over a recorded backend whose [FakeRelayAuth]
  /// says `ownsJars` (a signed-in real account), so `backend.names` shows
  /// exactly which devices spoke to the fan page (claimJar = route install;
  /// setJarRequests = published the request state) — and the relay CHANNEL
  /// factory records every construction attempt, because for a cloud
  /// session the honest count is zero.
  Future<
      ({
        ProviderContainer container,
        FakeCallables backend,
        List<String> channelAsks,
      })> device(String deviceId) async {
    final backend = FakeCallables();
    final channelAsks = <String>[];
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
          ({required demo, required jar, required secret}) {
        channelAsks.add(deviceId);
        return null;
      }),
      jarClaimerFactoryProvider.overrideWithValue(
          ({required demo, required jar, required secret, required bandId}) =>
              JarClaimer(
                client: fakeRelayClient(backend,
                    auth: FakeRelayAuth(owned: true)),
                jarId: _jarId,
                secret: 'sec',
                bandId: bandId,
                backoff: (_) => null,
              )),
      jarRequestsPublisherFactoryProvider
          .overrideWithValue(({required serverComputesTotals}) =>
              JarRequestsPublisher(
                client: fakeRelayClient(backend),
                jar: const RelayJar(
                  jarId: _jarId,
                  tipUrl: 'https://tip.live.tips/$_jarId',
                  artistName: 'The Sondheims',
                  currency: 'usd',
                  createdAtMs: 1,
                ),
                secret: 'sec',
                serverComputesTotals: serverComputesTotals,
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
    return (
      container: container,
      backend: backend,
      channelAsks: channelAsks,
    );
  }

  test(
      'a cloud session runs NO relay channel at all: the claim installs the '
      'route (bandId + owned, per the pinned contract), pendingTips is left '
      'strictly alone, and a server-written session tip is what reaches the '
      'stage — celebrated, with song fields intact', () async {
    final (container: a, backend: backend, channelAsks: channelAsks) =
        await device('dev_a');
    expect(a.read(appStateProvider).apiKey, isNull,
        reason: 'this is the fresh-desktop shape: no Stripe key on device');

    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await _settle();

    // The starter leads unconditionally — no key check anywhere in _claim.
    final doc = (await liveDoc().get()).data()!;
    expect(doc['active'], isTrue);
    expect(doc['leaderDeviceId'], 'dev_a');

    // No channel was ever CONSTRUCTED, let alone attached — the factory
    // seam is the proof that cloud sessions cannot drain a queue even by
    // accident. And with no channel there is no second pill.
    expect(channelAsks, isEmpty,
        reason: 'a cloud session must never build a FirestoreTipChannel');
    expect(a.read(liveSessionProvider)!.relay, isNull,
        reason: 'the relay pill is retired for cloud sessions');

    // The claim still happened, and it carried the ROUTE — bandId together
    // with owned, exactly as the server half stores it (FakeCallables
    // enforces the perimeter: junk bandId or bandId-without-owned throws).
    expect(backend.names, contains('claimJar'));
    expect(backend.argsFor('claimJar'), {
      'jarId': _jarId,
      'secret': 'sec',
      'owned': true,
      'bandId': _bandId,
    });

    // A pendingTips doc (an unrouted jar's tip, or an old build's leftovers)
    // is NOT this session's business: nothing listens, nothing deletes.
    await db.collection(_pendingPath).add({
      'method': 'revolut',
      'amountMinor': 400,
      'currency': 'USD',
      'tsMs': DateTime.now().millisecondsSinceEpoch,
    });
    await _settle();
    expect((await db.collection(_pendingPath).get()).docs, hasLength(1),
        reason: 'no drain, no delete-ack — delivery-is-deletion is the '
            'LOCAL mode\'s contract, never the cloud one\'s');
    expect(a.read(liveSessionProvider)!.session.totalMinor, 0,
        reason: 'a cloud session must not ingest from the queue either — '
            'the switch keys on the session kind, not on what appears there');

    // What DOES reach the stage: the server-written subcollection doc.
    final sessionId = a.read(liveSessionProvider)!.session.id;
    final tip = await serverWritesSessionTip(sessionId,
        relayId: 'srv_1', songId: 'sng_1', songTitle: 'Wonderwall');
    await _settle();

    final state = a.read(liveSessionProvider)!;
    expect(state.session.totalMinor, 700);
    expect(state.confettiTick, 1,
        reason: 'a genuinely new tip celebrates exactly as before');
    expect(state.session.tips.single.id, tip.id);
    expect(state.session.tips.single.songId, 'sng_1');
    expect(state.session.tips.single.songTitle, 'Wonderwall');
  });

  test(
      'a JOINER claims too (any device may backfill an old jar\'s route — '
      'same uid, idempotent), still builds no channel, shows no second pill, '
      'and never bids while the lease is fresh', () async {
    final (container: a, backend: _, channelAsks: _) = await device('dev_a');
    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await _settle();

    final (container: b, backend: backendB, channelAsks: channelAsksB) =
        await device('dev_b');
    final info = ActiveSessionInfo.fromData((await liveDoc().get()).data())!;
    final joined = await b.read(liveSessionProvider.notifier).join(info);
    await _settle();

    expect(joined, isTrue);
    expect((await liveDoc().get()).data()!['leaderDeviceId'], 'dev_a',
        reason: 'a live lease is a live leader — nothing to rescue');
    expect(channelAsksB, isEmpty);
    expect(b.read(liveSessionProvider)!.relay, isNull);
    expect(backendB.names, contains('claimJar'),
        reason: 'the claim is attach-time route maintenance now, not a '
            'leader\'s prelude to draining a queue');
    expect(backendB.argsFor('claimJar')['bandId'], _bandId);
  });

  test(
      'money flows with NOBODY leading, and a key-less follower still '
      'RESCUES the dead leader\'s remaining jobs (#70): republishes the '
      'request state after taking the stale lease over', () async {
    final (container: a, backend: _, channelAsks: _) = await device('dev_a');
    await a
        .read(liveSessionProvider.notifier)
        .start(goalMinor: 10000, requestsOpen: true);
    await _settle();
    final info = ActiveSessionInfo.fromData((await liveDoc().get()).data())!;
    final sessionId = info.sessionId;

    // The leader dies without stopping: its container goes away, the doc
    // keeps saying dev_a — and then two minutes of silence pass.
    a.dispose();
    await liveDoc().set({
      'leaderLeaseUntilMs': DateTime.now().millisecondsSinceEpoch -
          CloudSessionCoordinator.staleMs -
          60000,
    }, SetOptions(merge: true));

    // A fan tips INTO the leaderless window: the server needs no leader —
    // the tip lands in the subcollection while no device is even attached.
    await serverWritesSessionTip(sessionId, relayId: 'srv_gap');

    final (container: b, backend: backendB, channelAsks: channelAsksB) =
        await device('dev_b');
    expect(b.read(appStateProvider).apiKey, isNull,
        reason: 'the rescuer has no Stripe key — the shape under key '
            'custody, where NO device holds one');
    final joined = await b.read(liveSessionProvider.notifier).join(info);
    expect(joined, isTrue);
    await _settle();

    // The tip that arrived while nobody led is on the stage of the device
    // that came back — the whole stale-lease window costs no money.
    expect(b.read(liveSessionProvider)!.session.totalMinor, 700);

    final doc = (await liveDoc().get()).data()!;
    expect(doc['active'], isTrue);
    expect(doc['leaderDeviceId'], 'dev_b',
        reason: 'leading is serving the session — the poll, the lease, the '
            'fan page\'s one voice — and needs no Stripe key');

    // ...and the fan page heard its new voice: the request state was
    // republished on takeover (the joiner itself never published — the
    // old leader may have died with the last publish unsent).
    expect(backendB.names, contains('setJarRequests'));
    // Still no channel anywhere in the takeover path.
    expect(channelAsksB, isEmpty);

    // And tips keep landing under the new leader — same one road.
    await serverWritesSessionTip(sessionId,
        relayId: 'srv_2', amountMinor: 500);
    await _settle();
    expect(b.read(liveSessionProvider)!.session.totalMinor, 1200);
    expect((await db.collection(_pendingPath).get()).docs, isEmpty,
        reason: 'nothing ever flowed through the queue in this test');
  });

  test(
      'two key-less followers race a dead leader\'s lease: the transactional '
      'claim lets exactly one through — one fan-page voice', () async {
    final (container: a, backend: _, channelAsks: _) = await device('dev_a');
    await a
        .read(liveSessionProvider.notifier)
        .start(goalMinor: 10000, requestsOpen: true);
    await _settle();
    final info = ActiveSessionInfo.fromData((await liveDoc().get()).data())!;

    final (container: b, backend: backendB, channelAsks: _) =
        await device('dev_b');
    final (container: c, backend: backendC, channelAsks: _) =
        await device('dev_c');
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
    final winnerBackend = leader == 'dev_b' ? backendB : backendC;
    final loserBackend = leader == 'dev_b' ? backendC : backendB;

    // The republish is the takeover's one relay job now — exactly one
    // device performed it. (Both claimed at JOIN: the claim is attach-time
    // route maintenance, deliberately leadership-blind.)
    expect(winnerBackend.names, contains('setJarRequests'));
    expect(loserBackend.names, isNot(contains('setJarRequests')),
        reason: 'the loser saw the winner\'s fresh lease inside its own '
            'transaction and stayed a quiet follower');
  });
}
