import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/repository/firestore_repository.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/features/account/device_session_guard.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';
import 'package:live_tips/state/venue_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// The night's archive, and whether it actually LANDS.
///
/// Every test here composes two things the suite used to assert only in
/// isolation: a session that stops, and a device that is torn down right
/// after. The bug lived exactly in the composition — the archive write was
/// fire-and-forget on the belief that "Firestore queues it durably either
/// way", which is false in the two places the app itself destroys the queue
/// (a venue tablet has no on-disk queue at all, and both teardowns delete the
/// account's FirebaseApp). fake_cloud_firestore cannot show it: it accepts
/// every write instantly and has no queue to lose, so an `unawaited` write and
/// an awaited one are indistinguishable in it.
///
/// [QueuedFirestore] is the missing seam.

const _uid = 'uid_cloud';
const _bandId = 'band_1';
const _deviceId = 'dev_venue';

/// A [FirebaseFirestore] veneer with the one thing fake_cloud_firestore has
/// not got: a write queue that can be HELD (an offline device) and DESTROYED
/// (what `Firebase.app(name).delete()` does to a real client — every mutation
/// still in flight dies with the instance, and its future never answers).
///
/// Every doc write takes a turn of the event loop to reach the fake, which is
/// what makes "the write was issued" and "the write landed" two different
/// moments — the gap the whole bug lives in.
class QueuedFirestore extends Fake implements FirebaseFirestore {
  QueuedFirestore(this.inner);

  final FakeFirebaseFirestore inner;

  /// The network is down: writes pile up and land only on [release].
  bool holding = false;

  /// The handle is dead (rules deny it, the app instance is gone): writes
  /// fail instead of landing.
  bool failing = false;

  bool _destroyed = false;
  final _pending = <_QueuedWrite>[];

  /// How many writes are still in the queue — "issued, not landed".
  int get pendingWrites => _pending.length;

  void release() {
    holding = false;
    for (final write in [..._pending]) {
      unawaited(_land(write));
    }
  }

  /// The FirebaseApp goes: whatever was still queued is gone with it, and the
  /// futures of those writes never complete — nobody is left to answer them.
  void destroy() {
    _destroyed = true;
    _pending.clear();
  }

  Future<void> _enqueue(Future<void> Function() write) {
    if (_destroyed) return Completer<void>().future;
    final queued = _QueuedWrite(write, Completer<void>());
    _pending.add(queued);
    if (!holding) unawaited(_land(queued));
    return queued.done.future;
  }

  Future<void> _land(_QueuedWrite write) async {
    await Future<void>.delayed(Duration.zero); // the round trip
    if (_destroyed || !_pending.remove(write)) return; // died in the queue
    if (failing) {
      write.done.completeError(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
      return;
    }
    // The store's own rejection (not-found, permission) belongs to the
    // WRITER's future, exactly like the `failing` path above — leaking it
    // out of this unawaited landing turns a handled failure (the sign-out
    // hook's best-effort push-token delete) into an unhandled async error.
    try {
      await write.run();
      if (!write.done.isCompleted) write.done.complete();
    } catch (e, st) {
      if (!write.done.isCompleted) write.done.completeError(e, st);
    }
  }

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) =>
      _QueuedDocRef(inner.doc(path), this);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      inner.collection(path);

  @override
  WriteBatch batch() => inner.batch();

  @override
  Future<T> runTransaction<T>(TransactionHandler<T> handler,
          {Duration timeout = const Duration(seconds: 30),
          int maxAttempts = 5}) =>
      inner.runTransaction(handler, timeout: timeout, maxAttempts: maxAttempts);

  @override
  Future<void> waitForPendingWrites() async {
    while (_pending.isNotEmpty && !_destroyed) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

class _QueuedWrite {
  _QueuedWrite(this.run, this.done);

  final Future<void> Function() run;
  final Completer<void> done;
}

// Deliberate, like fake_cloud_firestore's own fakes.
// ignore: subtype_of_sealed_class
class _QueuedDocRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _QueuedDocRef(this.inner, this.queue);

  final DocumentReference<Map<String, dynamic>> inner;
  final QueuedFirestore queue;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) =>
      queue._enqueue(() => inner.set(data, options));

  @override
  Future<void> update(Map<Object, Object?> data) {
    final done = queue._enqueue(() => inner.update(data));
    // fake_cloud_firestore's transaction drops the future its `tx.update`
    // returns, so a failing write would surface as an unhandled async error
    // instead of the failed transaction the coordinator already handles.
    unawaited(done.catchError((Object _) {}));
    return done;
  }

  @override
  Future<void> delete() => queue._enqueue(inner.delete);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) =>
      inner.get(options);

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      inner.snapshots(includeMetadataChanges: includeMetadataChanges);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      inner.collection(path);

  @override
  String get id => inner.id;

  @override
  String get path => inner.path;
}

/// The sign-out that takes the account's Firebase app — and its write queue —
/// down with it. That is the production order: the session stops, the
/// sign-out runs, `Firebase.app(uid).delete()` follows, and anything the stop
/// merely QUEUED is gone.
class TearDownAuthService extends FakeAuthService {
  TearDownAuthService(this.queue, {required AuthUser user})
      : super(user: user);

  final QueuedFirestore queue;

  @override
  Future<void> signOut() async {
    queue.destroy();
    await super.signOut();
  }
}

/// A scripted Stripe feed (same scaffold as cloud_session_coordinator_test).
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

Tip _tip(String id, int amountMinor, {bool livemode = true}) => Tip(
      id: id,
      amountMinor: amountMinor,
      currency: 'usd',
      createdAt: DateTime.utc(2026, 7, 12),
      livemode: livemode,
    );

Future<void> settle([int rounds = 40]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// See cloud_session_coordinator_test: the repo-revision fan-out is not what
/// these tests are about, and mounting it trips riverpod's circular-dependency
/// check in this harness.
class _NoopRevision extends RepoRevisionNotifier {
  @override
  void bump() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore inner;
  late QueuedFirestore db;
  late LocalStore store;
  late TearDownAuthService auth;

  CollectionReference<Map<String, dynamic>> sessionsCol() =>
      inner.collection('users/$_uid/bands/$_bandId/sessions');

  Future<void> seed({bool venue = false}) async {
    SharedPreferences.setMockInitialValues(
        venue ? {LocalStore.kDeviceKind: 'venue'} : {});
    inner = FakeFirebaseFirestore();
    db = QueuedFirestore(inner);
    store = LocalStore(await SharedPreferences.getInstance());
    auth = TearDownAuthService(db,
        user: const AuthUser(uid: _uid, kind: AccountKind.google));
    await store.saveAccountsDirectory(AccountsDirectory(
      accounts: [
        AppAccount.localProfile(),
        const AppAccount(id: _uid, name: 'Casey', kind: AccountKind.google),
      ],
      activeAccountId: _uid,
    ));
    await store.saveActiveCloudBand(_uid, _bandId);
    await inner
        .doc('users/$_uid/bands/$_bandId')
        .set({'name': 'The Sondheims', 'createdAtMs': 1});
  }

  /// The signed-in cloud device, over the queued Firestore.
  ProviderContainer newContainer({List<List<Tip>> batches = const []}) =>
      ProviderContainer(overrides: [
        repoRevisionProvider.overrideWith(_NoopRevision.new),
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(FakeSecureStore(
            {'${SecureStore.kApiKeyBase}_$_bandId': 'sk_test_key'})),
        firestoreProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(auth),
        deviceIdProvider.overrideWithValue(_deviceId),
        describeDeviceProvider.overrideWithValue(
            () async => const DeviceDescription(name: 'Tablet', platform: 'web')),
        initialApiKeyProvider.overrideWithValue('sk_test_key'),
        tipSourceFactoryProvider.overrideWithValue(
            ({required demo, required apiKey, required jar}) =>
                ScriptedSource(batches)),
        relayChannelFactoryProvider.overrideWithValue(
            ({required demo, required jar, required secret}) => null),
      ]);

  /// A device that has landed on the account's cloud band — the coordinator it
  /// builds for a session is the cloud one.
  Future<ProviderContainer> device({List<List<Tip>> batches = const []}) async {
    final container = newContainer(batches: batches);
    addTearDown(container.dispose);
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

  /// The archive doc as it stands in Firestore — the thing every device's
  /// History reads.
  Future<Map<String, dynamic>?> archive(String sessionId) async =>
      (await sessionsCol().doc(sessionId).get()).data();

  group('the commit point', () {
    test(
        'a venue end-of-stint leaves a COMPLETE archive — the stop commits '
        'before the sign-out deletes the app and takes the queue with it',
        () async {
      await seed(venue: true);
      final container = await device(batches: [
        [_tip('cs_1', 500), _tip('cs_2', 700)],
      ]);
      await container.read(venueSessionProvider.notifier).start(_uid);
      await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();
      final session = container.read(liveSessionProvider)!.session;
      expect(session.totalMinor, 1200);

      // The gig ends: "End session" (or the 12-hour ceiling) scrubs the
      // tablet — stop, sign out, delete the app, wipe the device.
      await container.read(venueSessionProvider.notifier).endSession();
      await settle();

      final data = await archive(session.id);
      expect(data, isNotNull, reason: 'the archive doc must exist at all');
      expect(data!['endedAt'], isNotNull,
          reason: 'a night that reads as "still running" forever is the bug: '
              'the finalize was queued into a queue that was then deleted');
      expect((data['tips'] as List).length, 2,
          reason: 'the set is 0 tips, €0 without this — while its tips sit in '
              'the subcollection one level below');
      expect(store.readActiveSession(_bandId), isNull,
          reason: 'a committed archive spends the crash snapshot');
      // The tablet still went clean: the artist's account is off it.
      expect(auth.user, isNull);
      expect(store.readVenueSession(), isNull);
    });

    test(
        'a revoked device leaves a COMPLETE archive — the archive commits '
        'before the sign-out', (
    ) async {
      await seed();
      final container = await device(batches: [
        [_tip('cs_1', 900)],
      ]);
      await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();
      final session = container.read(liveSessionProvider)!.session;

      // The owner revokes THIS device from another one.
      await inner
          .doc('users/$_uid/devices/$_deviceId')
          .set({'revoked': true, 'lastSeenAtMs': 1});
      // The guard listens on ownDeviceRevokedProvider; drive it the same way
      // the widget does, without a widget tree.
      final revoked = Completer<void>();
      container.listen(ownDeviceRevokedProvider, (_, next) {
        if (next.value == true && !revoked.isCompleted) revoked.complete();
      });
      await revoked.future.timeout(const Duration(seconds: 5));
      // What DeviceSessionGuard._onRevoked does, in its order.
      try {
        await container.read(liveSessionProvider.notifier).stop(durable: true);
      } catch (_) {
        fail('a healthy device must be able to commit its archive');
      }
      await container.read(authControllerProvider.notifier).signOut();
      await settle();

      final data = await archive(session.id);
      expect(data!['endedAt'], isNotNull);
      expect((data['tips'] as List).length, 1,
          reason: 'the revoked device owed the account its night, and the '
              'sign-out was about to delete the queue holding it');
    });

    test(
        'a normal stop does not wait on the network — the stage stays instant '
        'even with the queue held, and the set lands when it drains', () async {
      await seed();
      final container = await device(batches: [
        [_tip('cs_1', 500)],
      ]);
      await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();
      final session = container.read(liveSessionProvider)!.session;

      // The network goes: nothing lands until release().
      db.holding = true;
      var stopped = false;
      final stopping = container
          .read(liveSessionProvider.notifier)
          .stop()
          .then((_) => stopped = true);
      await settle();

      expect(stopped, isTrue,
          reason: 'ending a set must never block on a round trip — the '
              'summary screen is the artist walking off stage');
      expect(container.read(liveSessionProvider), isNull);
      expect(db.pendingWrites, greaterThan(0),
          reason: 'the archive write is queued, not lost');

      // The queue drains (the app comes back online, or replays at the next
      // launch — a device with persistence keeps it on disk).
      db.release();
      await settle();
      await stopping;

      final data = await archive(session.id);
      expect(data!['endedAt'], isNotNull);
      expect((data['tips'] as List).length, 1,
          reason: 'a set stopped while offline must not vanish');
    });

    test(
        'a durable stop that CANNOT commit says so — it throws, keeps the '
        'crash snapshot, and leaves the tips it already wrote as the night\'s '
        'only copy', () async {
      await seed();
      final container = await device(batches: [
        [_tip('cs_1', 500), _tip('cs_2', 700)],
      ]);
      await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);
      await settle();
      final session = container.read(liveSessionProvider)!.session;

      // The handle dies (revoked rules, a network that answers with nothing).
      db.failing = true;

      await expectLater(
        container.read(liveSessionProvider.notifier).stop(durable: true),
        throwsA(isA<ArchiveNotCommittedException>()),
        reason: 'the catch blocks in the venue scrub and the revocation guard '
            'exist for exactly this, and could never fire while the write was '
            'unawaited',
      );
      expect(container.read(liveSessionProvider), isNull,
          reason: 'the set is over either way — the stage must not be left on '
              'a night that ended');
      expect(store.readActiveSession(_bandId), isNotNull,
          reason: 'an uncommitted set is not a finished one: the crash '
              'snapshot is the last copy on a device that still has one');

      // And the money is still in Firestore, where it landed as it arrived —
      // which is what the history rebuilds the set from.
      final tips =
          await sessionsCol().doc(session.id).collection('tips').get();
      expect(tips.docs.length, 2);
    });
  });

  group('the tips subcollection is read back', () {
    /// A night that ended without a finalize: the skeleton written at Go live,
    /// with every tip of the set in `sessions/{id}/tips` under it. This is
    /// what a venue stint and a revoked device used to leave behind — and what
    /// History rendered as "0 tips, €0, still running".
    Future<void> seedUnfinalizedNight() async {
      await inner.doc('users/$_uid/bands/$_bandId/sessions/ses_1').set({
        'id': 'ses_1',
        'startedAt': DateTime.utc(2026, 7, 12).millisecondsSinceEpoch,
        'currency': 'usd',
        'goalMinor': 10000,
        'bankedMinor': 0,
        'bankedJars': 0,
        'tips': <Map<String, dynamic>>[],
      });
      for (final tip in [_tip('cs_1', 500), _tip('cs_2', 700)]) {
        await inner
            .doc('users/$_uid/bands/$_bandId/sessions/ses_1/tips/${tip.id}')
            .set(tip.toJson());
      }
    }

    FirestoreRepository repo() => FirestoreRepository(
          uid: _uid,
          db: inner,
          local: store,
          resolveSecure: FakeSecureStore.new,
        );

    test('a session whose finalize never landed still shows its money',
        () async {
      await seed();
      await seedUnfinalizedNight();
      final repository = repo();
      addTearDown(repository.dispose);

      repository.readSessionHistory(_bandId); // kicks the lazy listeners
      await settle();

      final history = repository.readSessionHistory(_bandId);
      expect(history.single.id, 'ses_1');
      expect(history.single.tips.map((t) => t.id), ['cs_1', 'cs_2']);
      expect(history.single.totalMinor, 1200,
          reason: 'the tips were in Firestore the whole time — nothing read '
              'them back, so the artist\'s night showed €0');
    });

    test('an empty tips snapshot never subtracts a night — silence is not "€0"',
        () async {
      await seed();
      await seedUnfinalizedNight();
      final repository = repo();
      addTearDown(repository.dispose);
      repository.readSessionHistory(_bandId);
      await settle();
      expect(repository.readSessionHistory(_bandId).single.totalMinor, 1200);

      // The from-cache snapshot an offline device raises first: empty, and it
      // proves nothing. A cache proves what exists, never what is absent.
      repository.applySessionTipsSnapshot(_bandId, 'ses_1', const []);
      repository.applySessionsSnapshot(
        _bandId,
        [
          {
            'id': 'ses_1',
            'startedAt': DateTime.utc(2026, 7, 12).millisecondsSinceEpoch,
            'currency': 'usd',
            'goalMinor': 10000,
            'tips': <Map<String, dynamic>>[],
          }
        ],
        fromCache: true,
      );

      expect(repository.readSessionHistory(_bandId).single.totalMinor, 1200,
          reason: 'an empty cache snapshot must not turn a paid night into a '
              'blank one');
    });

    test('a finalized session keeps working off its doc — no double-count',
        () async {
      await seed();
      await seedUnfinalizedNight();
      // The archive lands late (the device came back online).
      await inner.doc('users/$_uid/bands/$_bandId/sessions/ses_1').set({
        'id': 'ses_1',
        'startedAt': DateTime.utc(2026, 7, 12).millisecondsSinceEpoch,
        'endedAt': DateTime.utc(2026, 7, 12, 2).millisecondsSinceEpoch,
        'currency': 'usd',
        'goalMinor': 10000,
        'bankedMinor': 0,
        'bankedJars': 0,
        'tips': [_tip('cs_1', 500).toJson(), _tip('cs_2', 700).toJson()],
      });
      final repository = repo();
      addTearDown(repository.dispose);
      repository.readSessionHistory(_bandId);
      await settle();

      final session = repository.readSessionHistory(_bandId).single;
      expect(session.tips.length, 2, reason: 'deduped by tip id');
      expect(session.totalMinor, 1200);
      expect(session.endedAt, isNotNull);
    });
  });

  group('deleting a profile deletes its tips', () {
    Future<void> seedNight(String sessionId, List<Tip> tips) async {
      await inner
          .doc('users/$_uid/bands/$_bandId/sessions/$sessionId')
          .set({
        'id': sessionId,
        'startedAt': DateTime.utc(2026, 7, 12).millisecondsSinceEpoch,
        'endedAt': DateTime.utc(2026, 7, 12, 2).millisecondsSinceEpoch,
        'currency': 'usd',
        'goalMinor': 10000,
        'tips': [for (final tip in tips) tip.toJson()],
      });
      for (final tip in tips) {
        await inner
            .doc('users/$_uid/bands/$_bandId/sessions/$sessionId/tips/'
                '${tip.id}')
            .set(tip.toJson());
      }
    }

    test(
        'wipeAccountData leaves no orphaned tips — every fan name, message and '
        'amount goes with the band', () async {
      await seed();
      await seedNight('ses_1', [_tip('cs_1', 500), _tip('cs_2', 700)]);
      await seedNight('ses_2', [_tip('cs_3', 900)]);
      final repository = FirestoreRepository(
        uid: _uid,
        db: inner,
        local: store,
        resolveSecure: FakeSecureStore.new,
      );
      addTearDown(repository.dispose);

      await repository.wipeAccountData(_bandId);

      expect((await sessionsCol().get()).docs, isEmpty);
      for (final sessionId in ['ses_1', 'ses_2']) {
        final tips =
            await sessionsCol().doc(sessionId).collection('tips').get();
        expect(tips.docs, isEmpty,
            reason: 'Firestore does not delete a doc\'s subcollections with '
                'it: $sessionId\'s tips outlived the band they belonged to, '
                'unreachable from any screen and deletable by nobody');
      }
    });

    test('purgeSimulatedData takes the simulated tips with the demo session',
        () async {
      await seed();
      await seedNight('demo', [_tip('demo_1', 500, livemode: false)]);
      await seedNight('live', [_tip('cs_1', 500)]);
      final repository = FirestoreRepository(
        uid: _uid,
        db: inner,
        local: store,
        resolveSecure: FakeSecureStore.new,
      );
      addTearDown(repository.dispose);

      await repository.purgeSimulatedData(_bandId);

      expect((await sessionsCol().get()).docs.map((d) => d.id), ['live']);
      expect((await sessionsCol().doc('demo').collection('tips').get()).docs,
          isEmpty,
          reason: 'demo money outliving the purge that exists to remove it');
      expect(
          (await sessionsCol().doc('live').collection('tips').get())
              .docs
              .length,
          1);
    });
  });

  testWidgets(
      'the revocation guard, end to end: the set is archived complete before '
      'the app it was queued in is deleted', (tester) async {
    await seed();
    final container = newContainer(batches: [
      [_tip('cs_1', 500), _tip('cs_2', 700)],
    ]);
    addTearDown(container.dispose);
    final repo = container.read(accountDataRepositoryProvider);
    for (var i = 0; i < 50; i++) {
      await tester.pump(Duration.zero);
      if (repo.listBands().any((b) => b.id == _bandId)) break;
    }
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        home: const DeviceSessionGuard(child: Scaffold(body: SizedBox())),
      ),
    ));
    await tester.pumpAndSettle();

    await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await tester.pumpAndSettle();
    final session = container.read(liveSessionProvider)!.session;
    expect(session.totalMinor, 1200);

    await inner
        .doc('users/$_uid/devices/$_deviceId')
        .set({'revoked': true, 'lastSeenAtMs': 1});
    await tester.pumpAndSettle();

    expect(container.read(liveSessionProvider), isNull);
    expect(container.read(authControllerProvider).user, isNull);
    final data = (await sessionsCol().doc(session.id).get()).data();
    expect(data!['endedAt'], isNotNull,
        reason: 'the revocation deleted the FirebaseApp the archive write was '
            'queued in, and the night stayed a €0 skeleton forever');
    expect((data['tips'] as List).length, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
