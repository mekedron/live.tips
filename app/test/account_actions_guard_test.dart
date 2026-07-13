import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/state/cloud_session_coordinator.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';

import 'helpers.dart';

/// The other soft-lock: `users/{uid}/live/current` only gets `active: false`
/// on a CLEAN stop, so a closed tab, a crash or a dropped network leaves the
/// account "live" forever. The guard used to read that flag alone and refuse
/// every add/remove for good — "Stop the live session first" about a session
/// that ended days ago, with no session to stop.
///
/// The lease is the thing that actually decays, and CloudSessionCoordinator
/// takes a stale-leased session over. The guard has to agree with it.

ActiveSessionInfo _session({required int leaseUntilMs, bool active = true}) =>
    ActiveSessionInfo(
      active: active,
      bandId: 'acc_test',
      sessionId: 'sess_1',
      startedAtMs: 0,
      currency: 'eur',
      goalMinor: 0,
      goalUpdatedAtMs: 0,
      leaderDeviceId: 'other_device',
      leaderLeaseUntilMs: leaseUntilMs,
    );

Future<ProviderContainer> _container(ActiveSessionInfo? info) async {
  final local = await seededStore();
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(SecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    activeSessionProvider.overrideWith((ref) => Stream.value(info)),
  ]);
  addTearDown(container.dispose);
  // Keep the stream alive and let its single value land before the guards
  // read it — an AsyncLoading would read as "no session" for the wrong reason.
  container.listen(activeSessionProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  expect(container.read(activeSessionProvider).value, info);
  return container;
}

void main() {
  final now = DateTime.now().millisecondsSinceEpoch;

  test('a fresh lease blocks — the account really is live somewhere', () async {
    final container = await _container(
      _session(leaseUntilMs: now + CloudSessionCoordinator.leaseMs),
    );
    final notifier = container.read(appStateProvider.notifier);

    expect(notifier.accountActionBlock, AccountActionBlock.remoteSession);
    expect(await notifier.addAccount(), isNull);
    expect(await notifier.removeAccount('acc_test'), isFalse);
    // The device-local removal touches no cloud data at all, but it still
    // reshuffles the bands under a set that is running somewhere — same guard,
    // same refusal.
    expect(await notifier.removeAccountFromDevice('acc_test'), isFalse);
  });

  test('a stale lease does NOT block — the session died with its tab',
      () async {
    // `active: true` still sitting there, but nobody has heartbeaten it since
    // well past the staleness window.
    final container = await _container(_session(
      leaseUntilMs: now - CloudSessionCoordinator.staleMs - 60 * 1000,
    ));
    final notifier = container.read(appStateProvider.notifier);

    expect(notifier.accountActionBlock, isNull);
    expect(notifier.accountActionsBlocked, isFalse);
    final added = await notifier.addAccount();
    expect(added, isNotNull);
    expect(container.read(appStateProvider).accounts, hasLength(2));
  });

  test('a lease inside the staleness window still blocks', () async {
    // Expired, but only just: a leader that is merely slow keeps its claim.
    final container = await _container(
      _session(leaseUntilMs: now - CloudSessionCoordinator.staleMs ~/ 2),
    );

    expect(
      container.read(appStateProvider.notifier).accountActionBlock,
      AccountActionBlock.remoteSession,
    );
  });

  test('an inactive doc never blocks, whatever its lease says', () async {
    final container = await _container(
      _session(active: false, leaseUntilMs: now + 60 * 1000),
    );

    expect(container.read(appStateProvider.notifier).accountActionBlock, isNull);
  });

  test('switch, add and remove all consult the same guard', () async {
    final container = await _container(
      _session(leaseUntilMs: now + CloudSessionCoordinator.leaseMs),
    );
    final notifier = container.read(appStateProvider.notifier);
    // Two bands, so there is somewhere to switch TO.
    final other = await notifier.addAccount(); // refused (blocked)
    expect(other, isNull);

    // The switch refuses for the same reason add and remove did — the three
    // used to disagree, and only switch let you move while live elsewhere.
    expect(await notifier.switchAccount('acc_other'), isFalse);
  });

  test('CloudSessionCoordinator.leaseAlive is the single definition', () {
    expect(CloudSessionCoordinator.leaseAlive(now, nowMs: now), isTrue);
    expect(
      CloudSessionCoordinator.leaseAlive(
        now - CloudSessionCoordinator.staleMs + 1,
        nowMs: now,
      ),
      isTrue,
    );
    expect(
      CloudSessionCoordinator.leaseAlive(
        now - CloudSessionCoordinator.staleMs - 1,
        nowMs: now,
      ),
      isFalse,
    );
  });
}
