import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
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
  Future<ProviderContainer> device(String deviceId,
      {List<List<Tip>> batches = const []}) async {
    final container = ProviderContainer(overrides: [
      repoRevisionProvider.overrideWith(_NoopRevision.new),
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(FakeSecureStore(
          {'${SecureStore.kApiKeyBase}_$_bandId': 'sk_test_key'})),
      firestoreProvider.overrideWithValue(db),
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
      'lease takeover: a follower with a Stripe key claims a session whose '
      'leader went silent past the staleness window, then polls', () async {
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

  test('LocalStore.deviceId is minted once and stays put', () async {
    final id = store.deviceId();
    expect(id, startsWith('dev_'));
    expect(store.deviceId(), id);
    final reopened = LocalStore(await SharedPreferences.getInstance());
    expect(reopened.deviceId(), id);
  });
}
