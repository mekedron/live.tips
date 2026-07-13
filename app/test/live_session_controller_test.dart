import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// Hands out pre-scripted batches, one per pollNew() call.
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
      createdAt: DateTime.utc(2026, 7, 3),
      livemode: false,
    );

Future<void> settle() async {
  // let the unawaited first _tick and its awaits run to completion
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> setUpContainer(List<List<Tip>> batches) async {
    final store = await seededStore();
    container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              ScriptedSource(batches)),
    ]);
    addTearDown(container.dispose);
    container.read(appStateProvider.notifier).enterDemo();
  }

  test('a multi-tip poll tick surfaces EVERY tip in newTips',
      () async {
    await setUpContainer([
      [d('cs_1', 500), d('cs_2', 1200), d('cs_3', 300)],
    ]);
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    final state = container.read(liveSessionProvider)!;
    expect(state.confettiTick, 3);
    expect(state.newTips.map((t) => t.tip.id),
        ['cs_1', 'cs_2', 'cs_3']); // arrival order preserved
    expect(state.lastTip!.id, 'cs_3');
    expect(state.newTips[1].deltaPct, closeTo(0.12, 1e-9));
    expect(state.session.totalMinor, 2000);
  });

  test(
      'an in-person tap pours into the jar and counts toward the goal like '
      'any other tip', () async {
    final tap = Tip(
      id: 'ch_tap',
      amountMinor: 2000,
      currency: 'usd',
      createdAt: DateTime.utc(2026, 7, 3),
      livemode: false,
      inPerson: true,
    );
    await setUpContainer([
      [d('cs_1', 500), tap],
    ]);
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    final state = container.read(liveSessionProvider)!;
    expect(state.session.totalMinor, 2500);
    expect(state.session.count, 2);
    expect(state.confettiTick, 2, reason: 'the tap gets its celebration too');
    expect(state.newTips.last.tip.id, 'ch_tap');
    expect(state.newTips.last.deltaPct, closeTo(0.20, 1e-9));
    expect(state.lastTip!.inPerson, isTrue);

    // The relay archive is for tips that exist nowhere but this device. A tap
    // is a real Stripe charge in the artist's account, so it must NOT land
    // there — that archive is keyed on `verified == false`, and a tap is
    // verified.
    expect(
      container.read(localStoreProvider).readRelayHistory(kTestAccountId),
      isEmpty,
    );
  });

  test('rollovers are attributed inside the batch and persisted', () async {
    await setUpContainer([
      [d('cs_1', 15000), d('cs_2', 6000)],
    ]);
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    final state = container.read(liveSessionProvider)!;
    expect(state.newTips[0].rollovers, 0); // 150%: over goal, under brim
    expect(state.newTips[1].rollovers, 1); // 210% → trophy + 1000 remainder
    expect(state.session.bankedJars, 1);
    expect(state.session.bankedMinor, 20000);
    expect(state.session.currentJarMinor, 1000);

    // The crash-recovery snapshot carries the banked fields — under DEMO's
    // namespace, because this set is a demo's (setUpContainer enters demo to
    // get a connected app). A demo's snapshot in the band's slot is a demo's
    // night in the artist's History (#52); the band's slot stays untouched.
    final store = container.read(localStoreProvider);
    expect(store.readActiveSession(kTestAccountId), isNull);
    final stored = store.readActiveSession(LocalStore.kDemoAccountId)!;
    expect(stored.bankedJars, 1);
    expect(stored.bankedMinor, 20000);
  });

  test('editGoal downward banks owed rollovers on the spot', () async {
    await setUpContainer([
      [d('cs_1', 15000)],
    ]);
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    controller.editGoal(3000);
    final state = container.read(liveSessionProvider)!;
    expect(state.session.bankedJars, 2);
    expect(state.session.currentJarMinor, 3000);
    expect(state.session.jarPct, closeTo(1.0, 1e-9));
  });

  test('confettiTick is the batch serial — stale batches carry but do not grow',
      () async {
    await setUpContainer([
      [d('cs_1', 500)],
      [], // second poll: nothing new
    ]);
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    final s1 = container.read(liveSessionProvider)!;
    expect(s1.confettiTick, 1);
    expect(s1.newTips, hasLength(1));

    controller.setLocked(true); // any copyWith-based state change
    final s2 = container.read(liveSessionProvider)!;
    expect(s2.confettiTick, 1, reason: 'serial unchanged');
    expect(s2.newTips, hasLength(1),
        reason: 'batch is carried — consumers must gate on the serial');
  });

  test(
      'relay-only (no Stripe key, no tip jar): the session starts, polls the '
      'null source, and never sees a fake tip', () async {
    const relayJar = RelayJar(
      jarId: 'jar_relay',
      tipUrl: 'https://live.tips/t/jar_relay',
      artistName: 'Foxy Live',
      currency: 'eur',
      revolutUsername: 'foxy',
      createdAtMs: 1,
    );
    final store = await seededStore(accountValues: {
      LocalStore.kRelayJarBase: jsonEncode(relayJar.toJson()),
    });
    // Deliberately NOT overriding tipSourceFactoryProvider: the real
    // factory must hand out the silent NullTipSource here — the demo
    // source would pour fake tips into a real set.
    container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(container.dispose);

    final app = container.read(appStateProvider);
    expect(app.hasRelay, isTrue);
    expect(app.hasStripe, isFalse);
    expect(app.effectiveTipJar, isNull);
    expect(app.connected, isTrue);

    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    final state = container.read(liveSessionProvider);
    expect(state, isNotNull, reason: 'the session must start without a jar');
    expect(state!.health, PollHealth.ok);
    expect(state.session.currency, 'eur',
        reason: 'currency comes from the relay jar');
    expect(state.session.tips, isEmpty,
        reason: 'no Stripe, no demo — nothing may appear on its own');
    expect(state.confettiTick, 0);
    expect(state.lastError, isNull);
  });

  group('storedSessionProvider (resume/discard banner reactivity)', () {
    test('starts null when nothing is stored', () async {
      await setUpContainer([[]]);
      expect(container.read(storedSessionProvider), isNull);
    });

    test('start() populates it immediately', () async {
      await setUpContainer([[]]);
      await container.read(liveSessionProvider.notifier).start(
            goalMinor: 10000,
          );
      expect(container.read(storedSessionProvider), isNotNull);
    });

    test('discardStored() clears it AND notifies listeners', () async {
      // A session left behind by a crash: nothing in this app run called
      // start() — it's just sitting on disk when the container boots, same
      // as "Resume interrupted session" finding it cold.
      final store = await seededStore();
      await store.saveActiveSession(
        kTestAccountId,
        LiveSession(
          id: 'ses_crashed',
          startedAt: DateTime.utc(2026, 7, 3),
          currency: 'usd',
          goalMinor: 10000,
          tips: [d('cs_1', 500)],
        ),
        'cur_1',
      );
      container = ProviderContainer(overrides: [
        localStoreProvider.overrideWithValue(store),
        tipSourceFactoryProvider.overrideWithValue(
            ({required demo, required apiKey, required jar}) =>
                ScriptedSource(const [])),
      ]);
      addTearDown(container.dispose);
      expect(container.read(storedSessionProvider)?.id, 'ses_crashed');

      // The bug this guards against: discarding used to leave every watcher
      // un-notified (LiveState stayed null throughout), so the "Resume
      // interrupted session" row only vanished after a full page reload.
      final notified = <LiveSession?>[];
      container.listen(storedSessionProvider, (_, next) => notified.add(next));

      await container.read(liveSessionProvider.notifier).discardStored();

      expect(notified, [null],
          reason: 'a watcher must be notified — that is what makes the '
              'banner disappear without a refresh');
      expect(container.read(storedSessionProvider), isNull);
      expect(store.readActiveSession(kTestAccountId), isNull);
    });

    test('stop() also clears it — no stale banner after a clean end',
        () async {
      await setUpContainer([
        [d('cs_1', 500)],
      ]);
      final controller = container.read(liveSessionProvider.notifier);
      await controller.start(goalMinor: 10000);
      await settle();
      expect(container.read(storedSessionProvider), isNotNull);

      await controller.stop();

      expect(container.read(storedSessionProvider), isNull);
    });
  });
}
