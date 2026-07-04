import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/donation_source.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hands out pre-scripted batches, one per pollNew() call.
class ScriptedSource extends DonationSource {
  ScriptedSource(this.batches);
  final List<List<Donation>> batches;
  var _i = 0;

  @override
  Future<void> prime(DateTime startedAt,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Donation>> pollNew() async =>
      _i < batches.length ? batches[_i++] : const [];

  @override
  String? get cursor => null;
}

Donation d(String id, int amountMinor) => Donation(
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

  Future<void> setUpContainer(List<List<Donation>> batches) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      donationSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              ScriptedSource(batches)),
    ]);
    addTearDown(container.dispose);
    container.read(appStateProvider.notifier).enterDemo();
  }

  test('a multi-donation poll tick surfaces EVERY donation in newTips',
      () async {
    await setUpContainer([
      [d('cs_1', 500), d('cs_2', 1200), d('cs_3', 300)],
    ]);
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    final state = container.read(liveSessionProvider)!;
    expect(state.confettiTick, 3);
    expect(state.newTips.map((t) => t.donation.id),
        ['cs_1', 'cs_2', 'cs_3']); // arrival order preserved
    expect(state.lastDonation!.id, 'cs_3');
    expect(state.newTips[1].deltaPct, closeTo(0.12, 1e-9));
    expect(state.session.totalMinor, 2000);
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

    // the crash-recovery snapshot carries the banked fields
    final stored =
        container.read(localStoreProvider).readActiveSession()!;
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
}
