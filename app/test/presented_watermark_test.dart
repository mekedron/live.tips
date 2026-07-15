import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/tip_channel.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/session_coordinator.dart';

import 'helpers.dart';

/// The device-local presented watermark (#71) — the celebration gate for
/// sessions whose tip feed REPLAYS (the cloud tips subcollection redelivers
/// the whole session on every attach). The invariants pinned here, straight
/// from the owner's decisions:
///
/// * only tips this device has not presented yet celebrate; replayed money
///   still lands in the totals, quietly;
/// * the mark advances ONLY on actual presentation — never on attach, and
///   never to "now" because a snapshot (least of all a from-cache one, whose
///   emptiness proves nothing) seemed to carry nothing new;
/// * a first run seeds to "now", so a reinstalled device renders a backlog
///   without a stale confetti storm;
/// * same-millisecond siblings (Stripe stamps at SECOND resolution) are
///   refereed by the boundary ids, not by the timestamp alone;
/// * a consume-once feed (local profiles — replaysTips false) never touches
///   the watermark: today's behavior, byte for byte, forever.
///
/// Driven through the real controller with a scripted coordinator, so the
/// gate is exercised exactly where it lives — [LiveSessionController._ingest].

const relayJar = RelayJar(
  jarId: 'jar_wm',
  tipUrl: 'https://live.tips/t/jar_wm',
  artistName: 'Foxy Live',
  currency: 'eur',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

/// A coordinator whose feed replays like the cloud tips subcollection —
/// no transports, no Firestore; the test IS the feed (it drives [events]).
class _ReplayingCoordinator implements SessionCoordinator {
  _ReplayingCoordinator({this.replays = true});

  final bool replays;

  @override
  RelayHealth? get relayHealthSeed => null;

  @override
  bool get replaysTips => replays;

  @override
  Future<void> start(LiveSession session,
      {String? resumeCursor,
      SessionStartMode mode = SessionStartMode.fresh}) async {}

  @override
  void onTipsIngested(LiveSession session, List<Tip> fresh) {}

  @override
  void onGoalEdited(LiveSession session) {}

  @override
  void onRequestsEdited(LiveSession session) {}

  @override
  void onTipVerified(LiveSession session, Tip tip) {}

  @override
  bool get publishesRequests => false;

  @override
  Future<void> stop(LiveSession session, {bool durable = false}) async {}

  @override
  void reconnectNow() {}

  @override
  Future<void> dispose() async {}
}

Tip tipAt(String id, int ms, {int amountMinor = 500}) => Tip(
      id: id,
      amountMinor: amountMinor,
      currency: 'eur',
      createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
      livemode: false,
      method: TipMethod.revolut,
    );

Future<void> settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late LocalStore store;
  late SessionEvents events;

  Future<void> setUpContainer({bool replays = true, LocalStore? share}) async {
    store = share ??
        await seededStore(accountValues: {
          LocalStore.kRelayJarBase: jsonEncode(relayJar.toJson()),
        });
    container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      sessionCoordinatorFactoryProvider.overrideWithValue((e) {
        events = e;
        return _ReplayingCoordinator(replays: replays);
      }),
    ]);
    addTearDown(container.dispose);
  }

  test(
      'first run seeds the mark to NOW — a reinstalled device renders the '
      'backlog as money, without a stale confetti storm, and the mark does '
      'not move for it', () async {
    await setUpContainer();
    expect(store.readTipsPresented(kTestAccountId), isNull);

    final before = DateTime.now().millisecondsSinceEpoch;
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    await settle();
    final seeded = store.readTipsPresented(kTestAccountId)!;
    expect(seeded.ms, greaterThanOrEqualTo(before),
        reason: 'no watermark on record — seed to now, a deliberate '
            'begin-time act (never a reaction to a snapshot)');

    // The backlog: durable-collection tips older than the seed. Exactly
    // what a from-cache first snapshot replays into a warm rejoin.
    events.onTips([
      tipAt('relay_old1', seeded.ms - 60000),
      tipAt('relay_old2', seeded.ms - 30000, amountMinor: 700),
    ]);
    await settle();

    final state = container.read(liveSessionProvider)!;
    expect(state.session.totalMinor, 1200,
        reason: 'replayed money still counts — the gate is celebration-only');
    expect(state.confettiTick, 0, reason: 'no storm over re-downloaded money');
    expect(state.newTips, isEmpty);
    expect(store.readTipsPresented(kTestAccountId)!.ms, seeded.ms,
        reason: 'presenting nothing advances nothing — a snapshot arrival '
            '(cached or not) must never move the mark by itself');
  });

  test(
      'a genuinely new tip celebrates and advances the mark to its '
      'createdAt — and a second run does NOT re-celebrate it', () async {
    await setUpContainer();
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    await settle();
    final seedMs = store.readTipsPresented(kTestAccountId)!.ms;

    final fresh = tipAt('relay_new', seedMs + 5000, amountMinor: 900);
    events.onTips([fresh]);
    await settle();

    var state = container.read(liveSessionProvider)!;
    expect(state.confettiTick, 1);
    expect(state.lastTip!.id, 'relay_new');
    final advanced = store.readTipsPresented(kTestAccountId)!;
    expect(advanced.ms, seedMs + 5000,
        reason: 'the mark is the newest PRESENTED createdAt, not "now"');
    expect(advanced.ids, ['relay_new']);

    // The second run: a fresh session object (nothing to dedupe against),
    // the durable feed replays the night — exactly a rejoin or relaunch.
    await container.read(liveSessionProvider.notifier).stop();
    await settle();
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    await settle();
    events.onTips([fresh]);
    await settle();

    state = container.read(liveSessionProvider)!;
    expect(state.session.totalMinor, 900, reason: 'the money is real');
    expect(state.confettiTick, 0,
        reason: 'this device already presented relay_new — the boundary ids '
            'mute the exact tip AT the watermark millisecond too');
  });

  test(
      'same-millisecond siblings across two batches: the second one still '
      'celebrates (Stripe stamps whole seconds — a bare timestamp cut would '
      'mute real money mid-set), and the replay mutes both', () async {
    await setUpContainer();
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    await settle();
    final seedMs = store.readTipsPresented(kTestAccountId)!.ms;
    final sharedMs = seedMs + 1000;

    events.onTips([tipAt('cs_a', sharedMs)]);
    await settle();
    events.onTips([tipAt('cs_b', sharedMs, amountMinor: 700)]);
    await settle();

    var state = container.read(liveSessionProvider)!;
    expect(state.confettiTick, 2,
        reason: 'cs_b shares cs_a\'s millisecond but was never presented');
    final mark = store.readTipsPresented(kTestAccountId)!;
    expect(mark.ms, sharedMs);
    expect(mark.ids.toSet(), {'cs_a', 'cs_b'},
        reason: 'the boundary carries every id at the newest millisecond');

    await container.read(liveSessionProvider.notifier).stop();
    await settle();
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    await settle();
    events.onTips(
        [tipAt('cs_a', sharedMs), tipAt('cs_b', sharedMs, amountMinor: 700)]);
    await settle();
    state = container.read(liveSessionProvider)!;
    expect(state.confettiTick, 0);
    expect(state.session.totalMinor, 1200);
  });

  test(
      'an attach that presents nothing leaves the mark alone, so a tip that '
      'landed while every device was away STILL celebrates at the next run — '
      'the cache-first trap, pinned: absence is never concluded from silence',
      () async {
    await setUpContainer();
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    await settle();
    final seedMs = store.readTipsPresented(kTestAccountId)!.ms;
    events.onTips([tipAt('cs_seen', seedMs + 1000)]);
    await settle();
    await container.read(liveSessionProvider.notifier).stop();
    await settle();

    // Relaunch: the listener attaches, delivers only the already-presented
    // tip (a warm cache's word), and the night goes quiet for a while. If
    // the attach — or that snapshot — bumped the mark to "now", the tip
    // below (paid during the quiet spell, delivered late) would be muted.
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    await settle();
    events.onTips([tipAt('cs_seen', seedMs + 1000)]);
    await settle();
    expect(container.read(liveSessionProvider)!.confettiTick, 0);
    expect(store.readTipsPresented(kTestAccountId)!.ms, seedMs + 1000,
        reason: 'replaying the presented tip is not a presentation');

    events.onTips([tipAt('cs_late', seedMs + 2000, amountMinor: 800)]);
    await settle();
    expect(container.read(liveSessionProvider)!.confettiTick, 1,
        reason: 'the late tip is newer than anything this device presented');
  });

  test(
      'a consume-once feed (replaysTips: false — every local profile) never '
      'reads or writes the watermark: an old-stamped tip celebrates exactly '
      'as it always has', () async {
    await setUpContainer(replays: false);
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    await settle();
    expect(store.readTipsPresented(kTestAccountId), isNull,
        reason: 'no seed — the gate does not exist for local sessions');

    // A pendingTips redelivery after a crash carries the fan\'s original
    // (past) timestamp; delivery-is-deletion makes it new by definition.
    events.onTips([tipAt('relay_past', 1751500000000)]);
    await settle();

    expect(container.read(liveSessionProvider)!.confettiTick, 1);
    expect(store.readTipsPresented(kTestAccountId), isNull,
        reason: 'presented locally, recorded nowhere — untouched forever');
  });
}
