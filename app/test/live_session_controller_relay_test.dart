import 'dart:async';
import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/relay/firestore_tip_channel.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/tip_channel.dart';
import 'package:live_tips/domain/song_request_settings.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/jar_requests_publisher.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

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

/// A relay channel the test drives by hand: push tips/health through
/// the controllers, observe start/dispose through the flags.
class FakeRelayChannel implements TipChannel {
  final tipsCtrl = StreamController<Tip>.broadcast();
  final statusCtrl = StreamController<RelayHealth>.broadcast();
  var started = false;
  var disposed = false;
  var reconnects = 0;

  @override
  Stream<Tip> get tips => tipsCtrl.stream;

  @override
  Stream<RelayHealth> get status => statusCtrl.stream;

  @override
  void start() => started = true;

  @override
  void reconnectNow() => reconnects++;

  @override
  Future<void> dispose() async => disposed = true;
}

const relayJar = RelayJar(
  jarId: 'jar_relay',
  tipUrl: 'https://live.tips/t/jar_relay',
  artistName: 'Foxy Live',
  currency: 'eur',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

Tip relayTip(int serial, {int amountMinor = 500}) => Tip.relayTip(
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
  late FakeCallables backend;

  /// Relay-only install: a relay jar + secret, NO Stripe key, NO demo. The
  /// jar callables land in [backend]; the request publisher is the REAL one
  /// over it, with a test-sized throttle so the trailing edge fits a test.
  Future<void> setUpContainer({
    List<List<Tip>> stripeBatches = const [],
    Map<String, Map<String, dynamic> Function(Map<String, dynamic>)>
        callableRoutes = const {},
  }) async {
    store = await seededStore(accountValues: {
      LocalStore.kRelayJarBase: jsonEncode(relayJar.toJson()),
    });
    channel = FakeRelayChannel();
    backend = FakeCallables(callableRoutes);
    container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      initialRelaySecretProvider.overrideWithValue('sec_1'),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              ScriptedSource(stripeBatches)),
      relayChannelFactoryProvider.overrideWithValue(
          ({required demo, required jar, required secret}) => channel),
      jarRequestsPublisherFactoryProvider
          .overrideWithValue(({required serverComputesTotals}) =>
              JarRequestsPublisher(
                client: fakeRelayClient(backend),
                jar: relayJar,
                secret: 'sec_1',
                serverComputesTotals: serverComputesTotals,
                throttle: const Duration(milliseconds: 200),
              )),
    ]);
    addTearDown(container.dispose);
  }

  /// The band's song-request master switch, on.
  Future<void> enableRequests() async {
    final app = container.read(appStateProvider);
    await container.read(appStateProvider.notifier).updateBand(app.band
        .copyWith(songRequests: const SongRequestSettings(enabled: true)));
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
    expect(state.newTips.single.tip.verified, isFalse);
    expect(state.lastTip!.id, 'relay_1751500000000_0');

    // Crash-recovery snapshot carries the relay tip.
    final stored = store.readActiveSession(kTestAccountId)!;
    expect(stored.tips.map((d) => d.id), ['relay_1751500000000_0']);
    expect(stored.tips.single.method, TipMethod.mobilepay);
    expect(stored.tips.single.verified, isFalse);
  });

  test('a duplicate tip id is ingested exactly once', () async {
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
        Tip(
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

  group('device-local relay history (the tip-page archive)', () {
    test('a real relay tip is archived at ingest and survives stop()',
        () async {
      await setUpContainer();
      final controller = container.read(liveSessionProvider.notifier);
      await controller.start(goalMinor: 10000);
      await settle();

      channel.tipsCtrl.add(relayTip(0, amountMinor: 700));
      await settle();

      // Persisted the moment it reached the live screen…
      final archived = store.readRelayHistory(kTestAccountId).single;
      expect(archived.id, 'relay_1751500000000_0');
      expect(archived.verified, isFalse);
      expect(archived.method, TipMethod.mobilepay);
      // …and the in-memory provider was refreshed for watching widgets.
      expect(container.read(relayHistoryProvider).single.id,
          'relay_1751500000000_0');

      await controller.stop();
      expect(store.readRelayHistory(kTestAccountId), hasLength(1),
          reason: 'the archive outlives the session — that is its point');
    });

    test('duplicate relay ids are archived exactly once', () async {
      await setUpContainer();
      final controller = container.read(liveSessionProvider.notifier);
      await controller.start(goalMinor: 10000);
      await settle();

      channel.tipsCtrl.add(relayTip(0));
      channel.tipsCtrl.add(relayTip(0)); // relay redelivery — same id
      channel.tipsCtrl.add(relayTip(1));
      await settle();

      expect(store.readRelayHistory(kTestAccountId).map((d) => d.id), [
        'relay_1751500000000_1',
        'relay_1751500000000_0',
      ]);
    });

    test('Stripe tips never enter the relay archive', () async {
      await setUpContainer(stripeBatches: [
        [
          Tip(
            id: 'cs_1',
            amountMinor: 1200,
            currency: 'eur',
            createdAt: DateTime.utc(2026, 7, 6),
          ),
        ],
      ]);
      final controller = container.read(liveSessionProvider.notifier);
      await controller.start(goalMinor: 10000);
      await settle();

      channel.tipsCtrl.add(relayTip(0));
      await settle();

      expect(container.read(liveSessionProvider)!.session.count, 2);
      expect(store.readRelayHistory(kTestAccountId).map((d) => d.id),
          ['relay_1751500000000_0'],
          reason: 'verified (Stripe) tips live in the Stripe account — only '
              'fan-declared tip-page tips belong to the device archive');
    });

    test('demo relay tips (livemode:false) are never archived', () async {
      await setUpContainer();
      container.read(appStateProvider.notifier).enterDemo();
      final controller = container.read(liveSessionProvider.notifier);
      await controller.start(goalMinor: 10000);
      await settle();

      channel.tipsCtrl.add(relayTip(0).copyWith(livemode: false));
      await settle();

      expect(container.read(liveSessionProvider)!.session.count, 1,
          reason: 'the demo tip still plays on the stage');
      expect(store.readRelayHistory(kTestAccountId), isEmpty,
          reason: 'pretend money must never enter the real archive');
    });
  });

  group('song requests over the relay (#64)', () {
    Tip requestTip(int serial, {int amountMinor = 700}) => Tip.relayTip(
          amountMinor: amountMinor,
          currency: 'eur',
          method: TipMethod.mobilepay,
          name: 'Maya',
          ts: 1751500000000,
          serial: serial,
          songId: 'sng_1',
          songTitle: 'Wonderwall',
        );

    List<RelayCall> requestCalls() =>
        [for (final c in backend.calls) if (c.name == 'setJarRequests') c];

    test('going live arms the window; a request tip publishes the queue '
        'in the server\'s exact wire shape', () async {
      await setUpContainer();
      await enableRequests();
      final controller = container.read(liveSessionProvider.notifier);
      await controller.start(goalMinor: 10000);
      await settle();

      // Begin: open:true armed, queue along for the ride (still empty).
      final armed = requestCalls().single;
      expect(armed.args['open'], isTrue);
      expect(armed.args['queue'], isEmpty);
      expect(armed.args['jarId'], 'jar_relay');

      // Two request tips inside one throttle window coalesce into ONE
      // trailing-edge publish carrying the latest state — and FakeCallables
      // holds the payload to the relay's real schema.
      channel.tipsCtrl.add(requestTip(0));
      await settle();
      channel.tipsCtrl.add(requestTip(1, amountMinor: 300));
      await settle();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await settle();

      final publishes = requestCalls();
      expect(publishes, hasLength(2),
          reason: 'begin + one coalesced queue publish, not one per tip');
      final queued = publishes.last.args;
      expect(queued.containsKey('open'), isFalse,
          reason: 'a queue tick must not re-write the open flag');
      expect(queued['queue'], {
        'sng_1': {'t': 1000, 'c': 2, 's': 'q'},
      });
    });

    test('marking played reaches the wire as s:"p"; stop closes the window',
        () async {
      await setUpContainer();
      await enableRequests();
      final controller = container.read(liveSessionProvider.notifier);
      await controller.start(goalMinor: 10000);
      await settle();

      channel.tipsCtrl.add(requestTip(0));
      await settle();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      controller.setSongStatus('sng_1', 'p');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await settle();

      final statuses = [
        for (final c in requestCalls())
          if (c.args['queue'] is Map && (c.args['queue'] as Map).isNotEmpty)
            ((c.args['queue'] as Map)['sng_1'] as Map)['s'],
      ];
      expect(statuses.last, 'p');

      await controller.stop();
      await settle();
      final closing = requestCalls().last.args;
      expect(closing['open'], isFalse);
      expect(closing.containsKey('queue'), isFalse,
          reason: 'stop says only that the window is shut');
    });

    test('a relay refusal is swallowed — the set never feels the fan page',
        () async {
      await setUpContainer(callableRoutes: {
        'setJarRequests': (_) => throw FakeFunctionsException('internal'),
      });
      await enableRequests();

      final controller = container.read(liveSessionProvider.notifier);
      await controller.start(goalMinor: 10000);
      await settle();
      channel.tipsCtrl.add(requestTip(0));
      await settle();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await settle();

      final state = container.read(liveSessionProvider);
      expect(state, isNotNull);
      expect(state!.session.totalMinor, 700,
          reason: 'the tip landed; only the fan page mirror went stale');
      expect(state.lastError, isNull);
    });
  });

  test(
      'LOCAL account end to end, unchanged forever (#71): the session '
      'attaches a real FirestoreTipChannel, the claim stays a plain reader '
      'join (no route, ever), pendingTips drains into the session, and '
      'delivery IS deletion', () async {
    final db = FakeFirebaseFirestore();
    final localBackend = FakeCallables();
    final store = await seededStore(accountValues: {
      LocalStore.kRelayJarBase: jsonEncode(relayJar.toJson()),
    });
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      initialRelaySecretProvider.overrideWithValue('sec_1'),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              ScriptedSource(const [])),
      relayChannelFactoryProvider.overrideWithValue(
          ({required demo, required jar, required secret}) =>
              FirestoreTipChannel(
                db: db,
                // A local profile's transport identity never owns jars —
                // the gate that keeps pendingTips local accounts' forever.
                auth: FakeRelayAuth(owned: false),
                client: fakeRelayClient(localBackend),
                jarId: relayJar.jarId,
                secret: 'sec_1',
                backoff: (_) => null,
              )),
      jarRequestsPublisherFactoryProvider
          .overrideWithValue(({required serverComputesTotals}) =>
              JarRequestsPublisher(
                client: fakeRelayClient(localBackend),
                jar: relayJar,
                secret: 'sec_1',
                serverComputesTotals: serverComputesTotals,
              )),
    ]);
    addTearDown(container.dispose);

    await container.read(liveSessionProvider.notifier).start(goalMinor: 5000);
    for (var i = 0; i < 40; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    // The claim happened and asserted nothing about ownership or routes.
    expect(localBackend.argsFor('claimJar'), {
      'jarId': relayJar.jarId,
      'secret': 'sec_1',
    });
    expect(container.read(liveSessionProvider)!.relay, RelayHealth.ok,
        reason: 'the second pill lives on for local sessions');

    // A fan tip lands in the queue; the leader drain shows it and acks it.
    await db.collection('jars/${relayJar.jarId}/pendingTips').add({
      'method': 'revolut',
      'amountMinor': 700,
      'currency': 'EUR',
      'name': 'Sam',
      'message': 'Great set!',
      'tsMs': 1751500000000,
    });
    for (var i = 0; i < 40; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    final state = container.read(liveSessionProvider)!;
    expect(state.session.totalMinor, 700);
    expect(state.confettiTick, 1,
        reason: 'a past-stamped queue tip celebrates — no watermark gates a '
            'consume-once feed');
    expect(
        (await db.collection('jars/${relayJar.jarId}/pendingTips').get()).docs,
        isEmpty,
        reason: 'delivery IS deletion — the relay keeps no tip history for '
            'a local jar, byte for byte today\'s behavior');
  });

  test(
      'the DEFAULT factory returns null for demo or missing jar/secret and '
      'a real channel otherwise', () async {
    await setUpContainer();
    // Read the default (un-overridden) implementation from a fresh container,
    // with Firestore present — that is what a device with the relay looks like.
    final defaults = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
    ]);
    addTearDown(defaults.dispose);
    final factory = defaults.read(relayChannelFactoryProvider);

    expect(factory(demo: true, jar: relayJar, secret: 's'), isNull);
    expect(factory(demo: false, jar: null, secret: 's'), isNull);
    expect(factory(demo: false, jar: relayJar, secret: null), isNull);

    final real = factory(demo: false, jar: relayJar, secret: 's');
    expect(real, isNotNull);
    await real!.dispose(); // never started — nothing to tear down but streams
  });

  test('without Firebase there is no relay feed at all', () async {
    await setUpContainer();
    // firestoreProvider defaults to null: Windows/Linux, a failed Firebase
    // boot, tests. The session simply runs without a push feed.
    final defaults = ProviderContainer();
    addTearDown(defaults.dispose);

    expect(
      defaults.read(relayChannelFactoryProvider)(
          demo: false, jar: relayJar, secret: 's'),
      isNull,
    );
  });
}
