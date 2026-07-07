import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/donation_source.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/relay/relay_tip_channel.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hands out pre-scripted batches, one per pollNew() call (same scaffold as
/// live_session_controller_test.dart).
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

/// A relay channel the test drives by hand: push donations/health through
/// the controllers, observe start/dispose through the flags.
class FakeRelayChannel extends RelayTipChannel {
  FakeRelayChannel()
      : super(wsUri: Uri.parse('wss://fake.invalid/ws'), secret: 'sec_fake');

  final tipsCtrl = StreamController<Donation>.broadcast();
  final statusCtrl = StreamController<RelayHealth>.broadcast();
  var started = false;
  var disposed = false;

  @override
  Stream<Donation> get tips => tipsCtrl.stream;

  @override
  Stream<RelayHealth> get status => statusCtrl.stream;

  @override
  void start() => started = true;

  @override
  Future<void> dispose() async => disposed = true;
}

const relayJar = RelayJar(
  jarId: 'jar_relay',
  donateUrl: 'https://live.tips/t/jar_relay',
  artistName: 'Foxy Live',
  currency: 'eur',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

Donation relayTip(int serial, {int amountMinor = 500}) => Donation.relayTip(
      amountMinor: amountMinor,
      currency: 'eur',
      method: TipMethod.mobilepay,
      name: 'Maya',
      message: 'Encore!',
      ts: 1751500000000,
      serial: serial,
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
  late FakeRelayChannel channel;

  /// Relay-only install: a relay jar + secret, NO Stripe key, NO demo.
  Future<void> setUpContainer(
      {List<List<Donation>> stripeBatches = const []}) async {
    SharedPreferences.setMockInitialValues({
      'relay_jar_v1': jsonEncode(relayJar.toJson()),
    });
    store = LocalStore(await SharedPreferences.getInstance());
    channel = FakeRelayChannel();
    container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      initialRelaySecretProvider.overrideWithValue('sec_1'),
      donationSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              ScriptedSource(stripeBatches)),
      relayChannelFactoryProvider.overrideWithValue(
          ({required demo, required jar, required secret}) => channel),
    ]);
    addTearDown(container.dispose);
  }

  test(
      'a relay tip lands in the session, fires the celebration serial, and '
      'is persisted — with no Stripe key at all', () async {
    await setUpContainer();
    final app = container.read(appStateProvider);
    expect(app.hasStripe, isFalse);
    expect(app.hasRelay, isTrue);

    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();
    expect(channel.started, isTrue);

    channel.tipsCtrl.add(relayTip(0, amountMinor: 700));
    await settle();

    final state = container.read(liveSessionProvider)!;
    expect(state.session.totalMinor, 700);
    expect(state.confettiTick, 1, reason: 'same celebration path as Stripe');
    expect(state.newTips, hasLength(1));
    expect(state.newTips.single.donation.verified, isFalse);
    expect(state.lastDonation!.id, 'relay_1751500000000_0');

    // Crash-recovery snapshot carries the relay tip.
    final stored = store.readActiveSession()!;
    expect(stored.donations.map((d) => d.id), ['relay_1751500000000_0']);
    expect(stored.donations.single.method, TipMethod.mobilepay);
    expect(stored.donations.single.verified, isFalse);
  });

  test('a duplicate donation id is ingested exactly once', () async {
    await setUpContainer();
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    channel.tipsCtrl.add(relayTip(0));
    channel.tipsCtrl.add(relayTip(0)); // relay redelivery — same id
    channel.tipsCtrl.add(relayTip(1));
    await settle();

    final state = container.read(liveSessionProvider)!;
    expect(state.session.count, 2);
    expect(state.session.totalMinor, 1000);
    expect(state.confettiTick, 2,
        reason: 'the duplicate must not fire a second celebration');
  });

  test('relay status transitions are reflected in LiveState.relay', () async {
    await setUpContainer();
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    expect(container.read(liveSessionProvider)!.relay, RelayHealth.connecting,
        reason: 'a session with a relay channel starts out connecting');

    channel.statusCtrl.add(RelayHealth.ok);
    await settle();
    expect(container.read(liveSessionProvider)!.relay, RelayHealth.ok);

    channel.statusCtrl.add(RelayHealth.down);
    await settle();
    expect(container.read(liveSessionProvider)!.relay, RelayHealth.down);

    channel.statusCtrl.add(RelayHealth.unauthorized);
    await settle();
    expect(container.read(liveSessionProvider)!.relay,
        RelayHealth.unauthorized);
  });

  test('stopping the session disposes the channel', () async {
    await setUpContainer();
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();
    expect(channel.disposed, isFalse);

    await controller.stop();
    await settle();

    expect(channel.disposed, isTrue);
    // Late events after teardown must not resurrect the session.
    channel.tipsCtrl.add(relayTip(9));
    channel.statusCtrl.add(RelayHealth.ok);
    await settle();
    expect(container.read(liveSessionProvider), isNull);
  });

  test('relay and Stripe tips merge into one session, deduped by id',
      () async {
    await setUpContainer(stripeBatches: [
      [
        Donation(
          id: 'cs_1',
          amountMinor: 1200,
          currency: 'eur',
          createdAt: DateTime.utc(2026, 7, 6),
          livemode: false,
        ),
      ],
    ]);
    final controller = container.read(liveSessionProvider.notifier);
    await controller.start(goalMinor: 10000);
    await settle();

    channel.tipsCtrl.add(relayTip(0));
    await settle();

    final state = container.read(liveSessionProvider)!;
    expect(state.session.count, 2);
    expect(state.session.totalMinor, 1700);
    expect(state.confettiTick, 2);
  });

  test(
      'the DEFAULT factory returns null for demo or missing jar/secret and '
      'a real channel otherwise', () async {
    await setUpContainer();
    // Read the default (un-overridden) implementation from a fresh container.
    final defaults = ProviderContainer();
    addTearDown(defaults.dispose);
    final factory = defaults.read(relayChannelFactoryProvider);

    expect(factory(demo: true, jar: relayJar, secret: 's'), isNull);
    expect(factory(demo: false, jar: null, secret: 's'), isNull);
    expect(factory(demo: false, jar: relayJar, secret: null), isNull);

    final real = factory(demo: false, jar: relayJar, secret: 's');
    expect(real, isNotNull);
    await real!.dispose(); // never started — nothing to tear down but streams
  });
}
