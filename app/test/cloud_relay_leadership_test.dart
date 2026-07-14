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
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/cloud_session_coordinator.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Who attaches the relay tip feed in a cloud session, proven end to end
/// through the real controller, the real [CloudSessionCoordinator] and the
/// real [FirestoreTipChannel] — with a device that has NO Stripe API key,
/// which is exactly the desktop a cloud account signs into fresh (the key
/// lives on the phone's keychain, or in cloud custody; it never travels).
///
/// The ground truth these tests pin: `canLead` (providers.dart, the
/// `app.apiKey != null` line) gates ONLY the follower-side lease takeover
/// (`_maybeTakeOver`). The device that STARTS the session leads
/// unconditionally — `_claim` installs it as leader with no key check — and
/// the leader runs the relay channel, so a key-less desktop that goes live
/// still drains `jars/{jarId}/pendingTips`. Every other coordinator test
/// seeds a leader-capable device, which is how "does a key-less starter
/// still get a relay?" went unasked.
///
/// The gap that remains — a key-less follower can NEVER take over a dead
/// leader, so the relay feed is orphaned for the rest of the set — is the
/// deliberate `_maybeTakeOver` refusal, and its fix is a product decision
/// (see the issue this file cites); it is not pinned here.

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late LocalStore store;

  DocumentReference<Map<String, dynamic>> liveDoc() =>
      db.doc('users/$_uid/live/current');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = FakeFirebaseFirestore();
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
  /// key): `app.apiKey == null`, so the coordinator gets `canLead: false`.
  /// Its relay is the real [FirestoreTipChannel] over the shared fake.
  Future<({ProviderContainer container, FakeCallables backend})> device(
      String deviceId) async {
    final backend = FakeCallables();
    final container = ProviderContainer(overrides: [
      repoRevisionProvider.overrideWith(_NoopRevision.new),
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(FakeSecureStore()),
      firestoreProvider.overrideWithValue(db),
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

    // The starter leads unconditionally — canLead gates only takeovers.
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
      'a key-less JOINER stays a follower with no relay pill at all — '
      'LiveState.relay is null, so "Tip page connecting…" can only come '
      'from a device that leads', () async {
    final (container: a, backend: _) = await device('dev_a');
    await a.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    await _settle();

    final (container: b, backend: backendB) = await device('dev_b');
    final info =
        ActiveSessionInfo.fromData((await liveDoc().get()).data())!;
    final joined = await b.read(liveSessionProvider.notifier).join(info);
    await _settle();

    expect(joined, isTrue);
    expect(b.read(liveSessionProvider)!.relay, isNull,
        reason: 'a follower runs no relay channel and shows no second pill');
    expect(backendB.names, isNot(contains('claimJar')),
        reason: 'only the leader claims the jar');
  });
}
