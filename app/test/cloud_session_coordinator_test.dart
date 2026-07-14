import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/cloud_session_coordinator.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Two "devices" — two ProviderContainers with distinct device ids — over
/// ONE FakeFirebaseFirestore: the multi-device session protocol end to end,
/// through the real controller and the real CloudSessionCoordinator.
///
/// SharedPreferences is a process singleton, so both devices share the same
/// prefs (crash snapshots collide harmlessly — same band, same session);
/// what must differ per device, the device id, is a provider override.

const _uid = 'uid_cloud';
const _bandId = 'band_1';

/// Hands out pre-scripted batches, one per pollNew() call (same scaffold as
/// live_session_controller_test.dart).
class ScriptedSource extends TipSource {
  ScriptedSource(this.batches);
  final List<List<Tip>> batches;
  var _i = 0;

  @override
  Future<void> prime(DateTime startedAt,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Tip>> pollNew() async =>
      _i < batches.length ? batches[_i++] : const [];

  @override
  String? get cursor => null;
}

Tip d(String id, int amountMinor) => Tip(
      id: id,
      amountMinor: amountMinor,
      currency: 'usd',
      createdAt: DateTime.utc(2026, 7, 12),
      livemode: false,
    );

Future<void> settle([int rounds = 40]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Disables the repo-revision fan-out. These tests read the repository and
/// the coordination docs directly, so nothing here needs the mirror-refresh
/// machinery — and AppStateNotifier._onRemoteChange reading the notifiers
/// of providers that watch appState trips riverpod's debug-mode circular-
/// dependency check the moment those providers are mounted (a pre-existing
/// wrinkle this harness has no business exercising).
class _NoopRevision extends RepoRevisionNotifier {
  @override
  void bump() {}
}

/// A [FirebaseFirestore] veneer over the shared fake that reproduces the ONE
/// piece of real-SDK behaviour fake_cloud_firestore lacks — the cache-first
/// listener: a `snapshots()` listener attached to [stalePath] FIRST emits the
/// doc as the local cache last saw it (`metadata.isFromCache: true`), and only
/// then hands over to the live stream. Real Firestore transactions never write
/// to the local cache, so right after a claim transaction the cache still
/// holds the PREVIOUS session's stopped doc — which is exactly what this
/// serves every fresh listener first. That first stale emission is what shot
/// down every production "Go live" after an account's first session.
class StaleCacheFirestore extends Fake implements FirebaseFirestore {
  StaleCacheFirestore(this.inner, this.stalePath, this.staleData,
      {this.staleFromCache = false});

  final FakeFirebaseFirestore inner;
  final String stalePath;

  /// Whether the stale first emission claims to come from the local cache.
  /// PRODUCTION SAYS FALSE: the doc already has a listener (the Join banner's),
  /// so the SDK replays that target's current — pre-transaction — data
  /// server-synced. A fix that keyed on `isFromCache` therefore shipped still
  /// broken. The cached variant is kept because it is also real (a cold
  /// listener on a warm cache), and both must be survived.
  final bool staleFromCache;

  /// What the cache "remembers" for [stalePath] — fixed at construction,
  /// mirroring a cache the claim transaction cannot refresh.
  final Map<String, dynamic> staleData;

  @override
  DocumentReference<Map<String, dynamic>> doc(String documentPath) {
    final real = inner.doc(documentPath);
    if (documentPath == stalePath || real.path == stalePath) {
      return _StaleCacheDocRef(real, staleData, staleFromCache);
    }
    return real;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(
          String collectionPath) =>
      inner.collection(collectionPath);

  @override
  WriteBatch batch() => inner.batch();

  @override
  Future<T> runTransaction<T>(TransactionHandler<T> transactionHandler,
          {Duration timeout = const Duration(seconds: 30),
          int maxAttempts = 5}) =>
      inner.runTransaction(transactionHandler,
          timeout: timeout, maxAttempts: maxAttempts);

  @override
  Future<void> waitForPendingWrites() => inner.waitForPendingWrites();
}

// Deliberate, like fake_cloud_firestore's own snapshot fakes.
// ignore: subtype_of_sealed_class
class _StaleCacheDocRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _StaleCacheDocRef(this.inner, this.staleData, this.fromCache);

  final DocumentReference<Map<String, dynamic>> inner;
  final Map<String, dynamic> staleData;
  final bool fromCache;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) async* {
    yield _CachedSnap(inner, staleData, fromCache);
    yield* inner.snapshots(includeMetadataChanges: includeMetadataChanges);
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) =>
      inner.get(options);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) =>
      inner.set(data, options);

  @override
  Future<void> update(Map<Object, Object?> data) => inner.update(data);

  @override
  Future<void> delete() => inner.delete();

  @override
  CollectionReference<Map<String, dynamic>> collection(
          String collectionPath) =>
      inner.collection(collectionPath);

  @override
  String get id => inner.id;

  @override
  String get path => inner.path;
}

// The synthesized "from the local cache" emission. Implementing the sealed
// class is deliberate, like fake_cloud_firestore's own snapshot fakes.
// ignore: subtype_of_sealed_class
class _CachedSnap extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _CachedSnap(this._ref, this._data, this._fromCache);

  final DocumentReference<Map<String, dynamic>> _ref;
  final Map<String, dynamic> _data;
  final bool _fromCache;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic>? data() => Map<String, dynamic>.of(_data);

  @override
  SnapshotMetadata get metadata => _CacheMeta(_fromCache);

  @override
  DocumentReference<Map<String, dynamic>> get reference => _ref;

  @override
  String get id => _ref.id;
}

class _CacheMeta extends Fake implements SnapshotMetadata {
  _CacheMeta(this._fromCache);

  final bool _fromCache;

  @override
  bool get isFromCache => _fromCache;

  @override
  bool get hasPendingWrites => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late LocalStore store;

  DocumentReference<Map<String, dynamic>> liveDoc() =>
      db.doc('users/$_uid/live/current');
  CollectionReference<Map<String, dynamic>> sessionsCol() =>
      db.collection('users/$_uid/bands/$_bandId/sessions');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = FakeFirebaseFirestore();
    store = LocalStore(await SharedPreferences.getInstance());
    // The device knows the cloud profile and which of its bands is active.
    await store.saveAccountsDirectory(AccountsDirectory(
      accounts: [
        AppAccount.localProfile(),
        const AppAccount(id: _uid, name: 'Casey', kind: AccountKind.google),
      ],
      activeAccountId: _uid,
    ));
    await store.saveActiveCloudBand(_uid, _bandId);
    // The band already exists in the account's subtree.
    await db
        .doc('users/$_uid/bands/$_bandId')
        .set({'name': 'The Sondheims', 'createdAtMs': 1});
  });

  /// One "device": its own container, device id, and scripted Stripe feed,
  /// over the shared Firestore + prefs. Waits until the cloud band mirror
  /// is warm so app state lands on the real band, not a placeholder.
  /// [dbOverride] swaps in a wrapped Firestore (see [StaleCacheFirestore])
  /// while the rest of the harness keeps writing to the shared fake.
  Future<ProviderContainer> device(String deviceId,
      {List<List<Tip>> batches = const [],
      FirebaseFirestore? dbOverride}) async {
    final container = ProviderContainer(overrides: [
      repoRevisionProvider.overrideWith(_NoopRevision.new),
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(FakeSecureStore(
          {'${SecureStore.kApiKeyBase}_$_bandId': 'sk_test_key'})),
      firestoreProvider.overrideWithValue(dbOverride ?? db),
      authServiceProvider.overrideWithValue(FakeAuthService(
          user: const AuthUser(uid: _uid, kind: AccountKind.google))),
      deviceIdProvider.overrideWithValue(deviceId),
      initialApiKeyProvider.overrideWithValue('sk_test_key'),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              ScriptedSource(batches)),
      relayChannelFactoryProvider.overrideWithValue(
          ({required demo, required jar, required secret}) => null),
    ]);
    var disposed = false;
    addTearDown(() {
      if (!disposed) container.dispose();
      disposed = true;
    });
    // Warm the band mirror before app state first reads it, so the device
    // boots straight onto the seeded band (no revision fan-out here — see
    // [_NoopRevision]).
    final repo = container.read(accountDataRepositoryProvider);
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(Duration.zero);
      if (repo.listBands().any((b) => b.id == _bandId)) break;
    }
    expect(container.read(appStateProvider).accountId, _bandId,
        reason: 'the device must land on the seeded cloud band');
    await settle();
    return container;
  }

  Future<ActiveSessionInfo> readInfo() async =>
      ActiveSessionInfo.fromData((await liveDoc().get()).data())!;

  test('transactional single-start: two devices race, exactly one wins',
      () async {
    final a = await device('dev_a');
    final b = await device('dev_b');

    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await settle();
    expect(a.read(liveSessionProvider), isNotNull);
    final doc = (await liveDoc().get()).data()!;
    expect(doc['active'], isTrue);
    expect(doc['leaderDeviceId'], 'dev_a');
    final sessionId = doc['sessionId'] as String;

    await expectLater(
      b.read(liveSessionProvider.notifier).start(goalMinor: 5000),
      throwsA(isA<SessionAlreadyActiveException>()),
    );
    expect(b.read(liveSessionProvider), isNull,
        reason: 'the loser must not be left in a half-started state');
    final after = (await liveDoc().get()).data()!;
    expect(after['sessionId'], sessionId,
        reason: 'the winner\'s doc stands untouched');
    expect(after['leaderDeviceId'], 'dev_a');
    // Let the loser's fire-and-forget writes land while its container lives.
    await settle();
  });

  test(
      'leader polls → tips land in the subcollection → the follower\'s '
      'listener ingests them: identical totals on both sides', () async {
    final a = await device('dev_a', batches: [
      [d('cs_1', 500), d('cs_2', 700)],
    ]);
    final b = await device('dev_b');

    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await settle();

    // The leader itself ingests through the listener echo — same path.
    final stateA = a.read(liveSessionProvider)!;
    expect(stateA.session.totalMinor, 1200);
    expect(stateA.confettiTick, 2);

    final joined =
        await b.read(liveSessionProvider.notifier).join(await readInfo());
    await settle();
    expect(joined, isTrue);

    final stateB = b.read(liveSessionProvider)!;
    expect(stateB.session.id, stateA.session.id);
    expect(stateB.session.totalMinor, 1200,
        reason: 'the backlog reaches a late joiner in full');
    expect(stateB.session.tips.map((t) => t.id),
        stateA.session.tips.map((t) => t.id));
    expect(stateB.health, PollHealth.ok,
        reason: 'a flowing listener is the follower\'s feed health');

    final tipDocs = await sessionsCol()
        .doc(stateA.session.id)
        .collection('tips')
        .get();
    expect(tipDocs.docs.length, 2, reason: 'doc id = tip id, idempotent');
  });

  test('a goal edit on the follower reaches the leader (and vice versa)',
      () async {
    final a = await device('dev_a');
    final b = await device('dev_b');

    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await settle();
    await b.read(liveSessionProvider.notifier).join(await readInfo());
    await settle();

    b.read(liveSessionProvider.notifier).editGoal(20000);
    await settle();
    expect(a.read(liveSessionProvider)!.session.goalMinor, 20000,
        reason: 'the doc is the goal\'s source of truth — LWW');
    expect((await liveDoc().get()).data()!['goalMinor'], 20000);

    a.read(liveSessionProvider.notifier).editGoal(15000);
    await settle();
    expect(b.read(liveSessionProvider)!.session.goalMinor, 15000);
  });

  group('song requests across devices (#64)', () {
    Tip requestTip(String id, int amountMinor, {bool verified = true}) => Tip(
          id: id,
          amountMinor: amountMinor,
          currency: 'usd',
          createdAt: DateTime.utc(2026, 7, 12),
          livemode: false,
          verified: verified,
          songId: 'sng_1',
          songTitle: 'Wonderwall',
        );

    test(
        'requests state round-trips live/current both ways: the leader\'s '
        'toggle reaches the follower, the follower\'s status reaches the '
        'leader — and echoes never loop', () async {
      final a = await device('dev_a', batches: [
        [requestTip('cs_1', 500)],
      ]);
      final b = await device('dev_b');

      await a
          .read(liveSessionProvider.notifier)
          .start(goalMinor: 10000, requestsOpen: true);
      await settle();
      await b.read(liveSessionProvider.notifier).join(await readInfo());
      await settle();
      expect(b.read(liveSessionProvider)!.session.requestsOpen, isTrue,
          reason: 'the claim wrote the initial requests state to the doc');

      // Leader pauses → the follower's copy follows through the doc.
      a.read(liveSessionProvider.notifier).toggleRequestsOpen();
      await settle();
      expect((await liveDoc().get()).data()!['requests'],
          containsPair('open', false));
      expect(b.read(liveSessionProvider)!.session.requestsOpen, isFalse);

      // Follower marks the song played → the leader's copy follows.
      b
          .read(liveSessionProvider.notifier)
          .setSongStatus('sng_1', LiveSession.statusPlayed);
      await settle();
      expect(a.read(liveSessionProvider)!.session.songStatuses,
          {'sng_1': LiveSession.statusPlayed});

      // …and clearing it must not be resurrected by a deep merge (the
      // update-vs-merge distinction this feature's writes hinge on).
      b.read(liveSessionProvider.notifier).setSongStatus('sng_1', null);
      await settle();
      expect(a.read(liveSessionProvider)!.session.songStatuses, isEmpty);
      final docRequests =
          (await liveDoc().get()).data()!['requests'] as Map;
      expect(docRequests['statuses'], isEmpty,
          reason: 'the statuses map is REPLACED wholesale, never merged');
    });

    test(
        'a request tip that arrives while the session says requests-off is '
        'never dropped: song fields intact on every device, and a mid-set '
        'setRequestsOpen reaches the follower', () async {
      // The server's 12h window can be armed while the leader's session says
      // closed (a re-opened window, a lost close) — a request can therefore
      // arrive "impossibly". It must land as money with its song fields, on
      // the leader AND on a follower, whatever the open flag says.
      final a = await device('dev_a', batches: [
        [requestTip('cs_offreq', 700)],
      ]);
      final b = await device('dev_b');

      await a
          .read(liveSessionProvider.notifier)
          .start(goalMinor: 10000, requestsOpen: false);
      await settle();
      await b.read(liveSessionProvider.notifier).join(await readInfo());
      await settle();

      for (final device in [a, b]) {
        final tip = device.read(liveSessionProvider)!.session.tips.single;
        expect(tip.songId, 'sng_1',
            reason: 'the round trip through toJson/fromJson keeps the song');
        expect(tip.songTitle, 'Wonderwall');
        expect(tip.amountMinor, 700);
      }

      // The mid-session settings-enable path: the leader opens explicitly
      // and the follower's copy follows through live/current.
      a.read(liveSessionProvider.notifier).setRequestsOpen(true);
      await settle();
      expect((await liveDoc().get()).data()!['requests'],
          containsPair('open', true));
      expect(b.read(liveSessionProvider)!.session.requestsOpen, isTrue);
    });

    test(
        'a verified flip on one device reaches the other as a MODIFIED doc — '
        'replaced in place, no re-ingest, no leftover verified field',
        () async {
      final a = await device('dev_a', batches: [
        [requestTip('relay_1', 700, verified: false)],
      ]);
      final b = await device('dev_b');

      await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();
      await b.read(liveSessionProvider.notifier).join(await readInfo());
      await settle();
      final ticksBefore = a.read(liveSessionProvider)!.confettiTick;
      expect(b.read(liveSessionProvider)!.session.tips.single.verified,
          isFalse);

      // The FOLLOWER vouches for the tip; its write is the plain doc set.
      b.read(liveSessionProvider.notifier).markVerified('relay_1');
      await settle();

      final stateA = a.read(liveSessionProvider)!;
      expect(stateA.session.tips.single.verified, isTrue,
          reason: 'the modified doc reached the leader via onTipsUpdated');
      expect(stateA.session.count, 1, reason: 'replaced, not re-ingested');
      expect(stateA.confettiTick, ticksBefore,
          reason: 'an update is not new money — no celebration');

      // The raw doc: toJson omits `verified` when true, so a merge would
      // have left the stale `verified: false` behind. Assert the plain set
      // really removed it.
      final raw = (await sessionsCol()
              .doc(stateA.session.id)
              .collection('tips')
              .doc('relay_1')
              .get())
          .data()!;
      expect(raw.containsKey('verified'), isFalse,
          reason: 'a lingering verified:false would unverify the tip on '
              'every device that reads it back');
      expect(raw['songId'], 'sng_1');
    });
  });

  test(
      'stop finalizes the archive doc with the embedded tips — exactly one '
      'entry, no repository double-write — and the follower tears down '
      'without a summary', () async {
    final a = await device('dev_a', batches: [
      [d('cs_1', 500), d('cs_2', 700)],
    ]);
    final b = await device('dev_b');

    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await settle();
    await b.read(liveSessionProvider.notifier).join(await readInfo());
    await settle();
    expect(b.read(liveSessionProvider), isNotNull);

    final summary = await a.read(liveSessionProvider.notifier).stop();
    await settle();

    // Only the stopping device gets the summary.
    expect(summary, isNotNull);
    expect(summary!.endedAt, isNotNull);
    expect(summary.totalMinor, 1200);

    // The follower observed active:false and went to "no session" quietly.
    expect(b.read(liveSessionProvider), isNull);
    expect(store.readActiveSession(_bandId), isNull,
        reason: 'no stale crash snapshot survives a clean stop');

    // The finalized session doc IS the archive: one doc, full set inside.
    final sessions = await sessionsCol().get();
    expect(sessions.docs.length, 1,
        reason: 'a second entry would mean the night was archived twice');
    final data = sessions.docs.single.data();
    expect(data['endedAt'], isNotNull);
    expect((data['tips'] as List).length, 2);

    // And the history mirror serves it back on any device.
    final repo = b.read(accountDataRepositoryProvider);
    repo.readSessionHistory(_bandId); // kick the lazy listener
    await settle();
    final history = repo.readSessionHistory(_bandId);
    expect(history.map((s) => s.id), [summary.id]);
    expect(history.single.tips.length, 2);
  });

  test(
      'lease takeover: a follower claims a session whose leader went silent '
      'past the staleness window, then polls with its Stripe key (the '
      'key-less takeover is pinned in cloud_relay_leadership_test.dart)',
      () async {
    final a = await device('dev_a', batches: [
      [d('cs_1', 500)],
    ]);
    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await settle();
    final info = await readInfo();

    // The leader dies without stopping: its container goes away, the doc
    // keeps saying dev_a — and then two minutes of silence pass.
    a.dispose();
    await liveDoc().set({
      'leaderLeaseUntilMs': DateTime.now().millisecondsSinceEpoch -
          CloudSessionCoordinator.staleMs -
          60000,
    }, SetOptions(merge: true));

    final b = await device('dev_b', batches: [
      [d('cs_9', 900)],
    ]);
    final joined =
        await b.read(liveSessionProvider.notifier).join(info);
    expect(joined, isTrue);
    await settle();

    final doc = (await liveDoc().get()).data()!;
    expect(doc['leaderDeviceId'], 'dev_b', reason: 'leadership moved');
    expect(doc['active'], isTrue);

    final state = b.read(liveSessionProvider)!;
    expect(state.session.tips.map((t) => t.id),
        containsAll(['cs_1', 'cs_9']),
        reason: 'the old backlog plus the new leader\'s own polling');
    expect(state.session.totalMinor, 1400);
  });

  group('resume reconcile', () {
    test('live/current still names our session → re-attach as leader',
        () async {
      final a = await device('dev_a', batches: [
        [d('cs_1', 500), d('cs_2', 700)],
      ]);
      await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();
      final sessionId = a.read(liveSessionProvider)!.session.id;
      a.dispose(); // crash: the snapshot stays, the doc stays active

      final a2 = await device('dev_a');
      expect(store.readActiveSession(_bandId), isNotNull);
      final resumed =
          await a2.read(liveSessionProvider.notifier).resumeStored();
      await settle();

      expect(resumed, isTrue);
      final state = a2.read(liveSessionProvider)!;
      expect(state.session.id, sessionId);
      expect(state.session.totalMinor, 1200,
          reason: 'snapshot tips + listener echo, deduped by id');
      expect((await liveDoc().get()).data()!['leaderDeviceId'], 'dev_a',
          reason: 'the lease was ours — leadership reclaimed');
    });

    test(
        'session ended elsewhere meanwhile → resume archives the snapshot '
        'and comes up with no session', () async {
      final a = await device('dev_a', batches: [
        [d('cs_1', 500)],
      ]);
      await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();
      final sessionId = a.read(liveSessionProvider)!.session.id;
      a.dispose();

      // Another device stopped the session while we were dead.
      await liveDoc().set({
        'active': false,
        'endedAtMs': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      final a2 = await device('dev_a');
      final resumed =
          await a2.read(liveSessionProvider.notifier).resumeStored();
      await settle();

      expect(resumed, isFalse);
      expect(a2.read(liveSessionProvider), isNull);
      expect(store.readActiveSession(_bandId), isNull,
          reason: 'the snapshot is spent — no resume banner next boot');
      // Nobody finalized the skeleton (the "stop" above was doc-only), so
      // the snapshot was salvaged into the archive.
      final archived =
          (await sessionsCol().doc(sessionId).get()).data()!;
      expect(archived['endedAt'], isNotNull);
      expect((archived['tips'] as List).length, 1);
    });
  });

  group('cache-first listener (the real SDK behaviour the fake lacks)', () {
    /// The production shape: the account already ran (and stopped) a session,
    /// so the local cache remembers `live/current` as `active: false` with
    /// the OLD session id. The claim transaction commits server-side without
    /// touching the cache, and the coordinator's fresh listener gets that
    /// stale cached doc FIRST.
    Map<String, dynamic> lastNightsDoc() => {
          'active': false,
          'bandId': _bandId,
          'sessionId': 'ses_last_night',
          'startedAtMs': DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
          'currency': 'usd',
          'goalMinor': 5000,
          'leaderDeviceId': 'dev_a',
          'leaderLeaseUntilMs': DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
          'endedAtMs': DateTime.now()
              .subtract(const Duration(hours: 20))
              .millisecondsSinceEpoch,
        };

    test(
        'a stale PRE-TRANSACTION echo of the previous session must not shoot '
        'down the session this device just claimed', () async {
      // Last night's stopped session, echoed back to the fresh listener
      // SERVER-SYNCED (isFromCache: false) — production's actual shape.
      final stale = lastNightsDoc();
      await liveDoc().set(stale);
      final a = await device('dev_a',
          batches: [
            [d('cs_1', 500)],
          ],
          dbOverride:
              StaleCacheFirestore(db, 'users/$_uid/live/current', stale));

      await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();

      // The coordinator read the echoed active:false doc as "stopped on
      // another device", nulled the state, and the very session this device
      // leads came back as a foreign Join banner. Guarding on isFromCache did
      // NOT fix it — the echo is server-synced, because the doc already has a
      // listener (the Join banner's) whose current data the SDK replays.
      final state = a.read(liveSessionProvider);
      expect(state, isNotNull,
          reason: 'a device that just won the claim transaction must not be '
              'told by a pre-transaction echo that its own session is over');
      final doc = (await liveDoc().get()).data()!;
      expect(doc['active'], isTrue);
      expect(doc['sessionId'], state!.session.id);
      expect(doc['leaderDeviceId'], 'dev_a');
      expect(state.session.totalMinor, 500,
          reason: 'the session keeps running: polls flow, tips land');
      expect(store.readActiveSession(_bandId), isNotNull,
          reason: 'the crash snapshot survives — nothing tore down');
    });

    test(
        'a genuine remote stop still tears the session down, stale echo or '
        'not', () async {
      final stale = lastNightsDoc();
      await liveDoc().set(stale);
      final a = await device('dev_a',
          dbOverride:
              StaleCacheFirestore(db, 'users/$_uid/live/current', stale));

      await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();
      expect(a.read(liveSessionProvider), isNotNull);

      // Another device stops the session: this names OUR sessionId, so it is
      // news, not an echo, and must still be obeyed.
      await liveDoc().set({
        'active': false,
        'endedAtMs': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      await settle();

      expect(a.read(liveSessionProvider), isNull,
          reason: 'the echo guard must not deafen the coordinator to '
              'real remote stops');
    });

    test(
        'a device superseded by a STRICTLY NEWER session tears down even '
        'before it ever saw its own', () async {
      final stale = lastNightsDoc();
      await liveDoc().set(stale);
      final a = await device('dev_a',
          dbOverride:
              StaleCacheFirestore(db, 'users/$_uid/live/current', stale));

      await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();
      expect(a.read(liveSessionProvider), isNotNull);

      // Another device took the doc with a session started AFTER ours. That
      // is not an echo of the past — it is the present, and it is not us.
      // Waving it through would trade the dead-session bug for a phantom one:
      // a device happily leading a night that belongs to someone else.
      await liveDoc().set({
        'active': true,
        'bandId': _bandId,
        'sessionId': 'ses_newer',
        'startedAtMs': DateTime.now()
            .add(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
        'leaderDeviceId': 'dev_b',
        'leaderLeaseUntilMs':
            DateTime.now().add(const Duration(minutes: 2)).millisecondsSinceEpoch,
      });
      await settle();

      expect(a.read(liveSessionProvider), isNull,
          reason: 'a newer session on the doc supersedes ours, seen or not');
    });
  });

  test('LocalStore.deviceId is minted once and stays put', () async {
    final id = store.deviceId();
    expect(id, startsWith('dev_'));
    expect(store.deviceId(), id);
    final reopened = LocalStore(await SharedPreferences.getInstance());
    expect(reopened.deviceId(), id);
  });
}
