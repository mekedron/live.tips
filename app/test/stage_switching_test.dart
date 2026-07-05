import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/domain/rollover_math.dart';
import 'package:live_tips/domain/stage_settings.dart';
import 'package:live_tips/features/live/stage/classic_stage.dart';
import 'package:live_tips/features/live/stage/jar_stage_view.dart';
import 'package:live_tips/features/live/stage/stage_resolver.dart';
import 'package:live_tips/features/live/stage/stage_types.dart';
import 'package:live_tips/features/live/stage/web_stage/stage_bridge_codec.dart';
import 'package:live_tips/features/live/stage/web_stage/stage_transport.dart';
import 'package:live_tips/features/live/stage/web_stage/web_stage.dart';

/// Records everything the widget sends; lets tests inject renderer messages.
class FakeStageTransport extends StageTransport {
  final sent = <Map<String, dynamic>>[];
  var reloads = 0;
  var disposed = false;

  @override
  Future<void> send(StageOutMessage msg) async {
    sent.add(jsonDecode(msg.encode()) as Map<String, dynamic>);
  }

  @override
  Future<void> reload() async {
    reloads++;
  }

  @override
  void dispose() => disposed = true;

  void receive(Map<String, dynamic> msg) {
    final decoded = StageInMessage.decode(jsonEncode({'v': 1, ...msg}));
    if (decoded != null) onMessage?.call(decoded);
  }

  List<Map<String, dynamic>> ofType(String type) =>
      sent.where((m) => m['type'] == type).toList();
}

StageSnapshot snap({
  int total = 5000,
  int goal = 10000,
  int banked = 0,
  int jars = 0,
}) =>
    StageSnapshot(
      totalMinor: total,
      goalMinor: goal,
      currentJarMinor: total - banked,
      bankedMinor: banked,
      bankedJars: jars,
      jarPct: goal <= 0 ? 0 : ((total - banked) / goal).clamp(0.0, 2.0),
      count: 1,
      currency: 'eur',
      goalReached: total >= goal,
    );

JarTipAttribution tip(String id, double delta, double after, int rolls) =>
    JarTipAttribution(
      donation: Donation(
        id: id,
        amountMinor: 500,
        currency: 'eur',
        createdAt: DateTime.utc(2026, 7, 3),
        livemode: false,
      ),
      deltaPct: delta,
      jarPctAfter: after,
      rollovers: rolls,
      bankedJarsAfter: 0,
    );

// Riverpod v3 doesn't export the Override type, so the helper only wraps the
// Material shell — call sites build the ProviderScope (list type is inferred).
Widget shell(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('resolveEffectiveStyle', () {
    test('fallback chain', () {
      const ok = StageHealth();
      expect(
          resolveEffectiveStyle(StageStyle.jar3d,
              webViewSupported: true, health: ok),
          StageStyle.jar3d);
      expect(
          resolveEffectiveStyle(StageStyle.jar3d,
              webViewSupported: false, health: ok),
          StageStyle.classic);
      expect(
          resolveEffectiveStyle(StageStyle.jar3d,
              webViewSupported: true,
              health: const StageHealth(jar3dUnfit: true)),
          StageStyle.jar2d);
      expect(
          resolveEffectiveStyle(StageStyle.jar3d,
              webViewSupported: true,
              health: const StageHealth(webViewBroken: true)),
          StageStyle.classic);
      expect(
          resolveEffectiveStyle(StageStyle.jar2d,
              webViewSupported: true, health: ok),
          StageStyle.jar2d);
      expect(
          resolveEffectiveStyle(StageStyle.classic,
              webViewSupported: true, health: ok),
          StageStyle.classic);
    });
  });

  group('JarStageView switching', () {
    testWidgets('classic style renders ClassicStage', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: shell(JarStageView(
          snapshot: snap(),
          tips: const [],
          tipSerial: 0,
          config: const StageSettings(style: StageStyle.classic),
        )),
      ));
      expect(find.byType(ClassicStage), findsOneWidget);
      expect(find.byType(WebStage), findsNothing);
    });

    testWidgets('jar3d without WebView support falls back to classic',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [stageCapabilityProvider.overrideWithValue(false)],
        child: shell(JarStageView(
          snapshot: snap(),
          tips: const [],
          tipSerial: 0,
          config: const StageSettings(),
        )),
      ));
      expect(find.byType(ClassicStage), findsOneWidget);
    });

    testWidgets('jar3d with support mounts WebStage with the 3d renderer',
        (tester) async {
      final transport = FakeStageTransport();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          stageCapabilityProvider.overrideWithValue(true),
          stageTransportFactoryProvider.overrideWithValue(() => transport),
        ],
        child: shell(JarStageView(
          snapshot: snap(),
          tips: const [],
          tipSerial: 0,
          config: const StageSettings(),
        )),
      ));
      final stage = tester.widget<WebStage>(find.byType(WebStage));
      expect(stage.renderer, '3d');
    });
  });

  group('WebStage bridge behavior', () {
    late FakeStageTransport transport;

    Widget stage({
      StageSnapshot? s,
      List<JarTipAttribution> tips = const [],
      int serial = 0,
      StageSettings config = const StageSettings(),
      int pulse = 0,
    }) =>
        ProviderScope(
          overrides: [
            stageTransportFactoryProvider.overrideWithValue(() => transport),
          ],
          child: shell(WebStage(
            renderer: '3d',
            snapshot: s ?? snap(),
            tips: tips,
            tipSerial: serial,
            config: config,
            demoPulseTick: pulse,
          )),
        );

    setUp(() => transport = FakeStageTransport());

    testWidgets('handshake: hello → init(config+state), ready → poster gone',
        (tester) async {
      await tester.pumpWidget(stage(s: snap(total: 13000, jars: 2)));
      expect(transport.ofType('init'), isEmpty,
          reason: 'init waits for hello');

      transport.receive({'type': 'hello', 'protocol': 1});
      final init = transport.ofType('init').single;
      expect(init['renderer'], '3d');
      expect(init['state']['jarPct'], closeTo(1.3, 1e-9));
      expect(init['state']['bankedJars'], 2);
      expect(init['config']['vessel'], 'jar2');
      expect(init['config']['theme'], 'golden-hour');
      expect(init['config']['sound'], isFalse);
      expect(init['config']['tipSound'], isFalse);
      expect(init['config']['insets']['top'], greaterThan(0));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      transport.receive({'type': 'ready'});
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('tips are forwarded once per serial, in order',
        (tester) async {
      await tester.pumpWidget(stage());
      transport.receive({'type': 'hello', 'protocol': 1});
      transport.receive({'type': 'ready'});
      await tester.pump();

      final batch = [tip('cs_1', 0.05, 0.55, 0), tip('cs_2', 1.6, 0.15, 1)];
      await tester.pumpWidget(
          stage(s: snap(total: 21500), tips: batch, serial: 2));
      final sentTips = transport.ofType('tip');
      expect(sentTips, hasLength(2));
      expect(sentTips[0]['id'], 'cs_1');
      expect(sentTips[1]['id'], 'cs_2');
      expect(sentTips[1]['rollovers'], 1);
      expect(sentTips[1]['jarPctAfter'], closeTo(0.15, 1e-9));

      // same serial re-pumped → no duplicates
      await tester.pumpWidget(
          stage(s: snap(total: 21500), tips: batch, serial: 2));
      expect(transport.ofType('tip'), hasLength(2));
    });

    testWidgets('goal edit without tips sends an absolute syncState',
        (tester) async {
      await tester.pumpWidget(stage());
      transport.receive({'type': 'hello', 'protocol': 1});
      transport.receive({'type': 'ready'});
      await tester.pump();

      await tester.pumpWidget(stage(s: snap(total: 5000, goal: 4000)));
      final sync = transport.ofType('syncState').single;
      expect(sync['state']['jarPct'], closeTo(1.25, 1e-9));
    });

    testWidgets('config change diffs into one partial setConfig',
        (tester) async {
      await tester.pumpWidget(stage());
      transport.receive({'type': 'hello', 'protocol': 1});
      transport.receive({'type': 'ready'});
      await tester.pump();

      await tester.pumpWidget(stage(
          config: const StageSettings(
              scene: JarScene.pub,
              soundEnabled: true,
              tipSoundEnabled: true)));
      final patch = transport.ofType('setConfig').single['config'];
      expect(patch, {'scene': 'pub', 'sound': true, 'tipSound': true});
    });

    testWidgets(
        'fatal error → one reload; second fatal → webViewBroken health',
        (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          stageTransportFactoryProvider.overrideWithValue(() => transport),
        ],
        child: shell(Consumer(builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return WebStage(
            renderer: '3d',
            snapshot: snap(),
            tips: const [],
            tipSerial: 0,
            config: const StageSettings(),
          );
        })),
      ));

      transport.receive({'type': 'error', 'message': 'boom', 'fatal': true});
      expect(transport.reloads, 1);
      expect(container.read(stageHealthProvider).webViewBroken, isFalse);

      transport.receive({'type': 'error', 'message': 'boom2', 'fatal': true});
      await tester.pump();
      expect(container.read(stageHealthProvider).webViewBroken, isTrue);
      // watchdog timers were cancelled on give-up; nothing left pending
      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('demoPulse fires when the tick advances', (tester) async {
      await tester.pumpWidget(stage());
      transport.receive({'type': 'hello', 'protocol': 1});
      transport.receive({'type': 'ready'});
      await tester.pump();
      await tester.pumpWidget(stage(pulse: 1));
      expect(transport.ofType('demoPulse'), hasLength(1));
    });
  });

  group('codec', () {
    test('unknown incoming types and garbage decode to null', () {
      expect(StageInMessage.decode('not json'), isNull);
      expect(StageInMessage.decode('{"v":1,"type":"mystery"}'), isNull);
      expect(
          StageInMessage.decode('{"v":1,"type":"event","kind":"dance"}'),
          isNull);
    });

    test('events decode with kind and jarPct', () {
      final e = StageInMessage.decode(
              '{"v":1,"type":"event","kind":"rolloverDone","jarPct":0}')
          as StageEvent;
      expect(e.kind, StageEventKind.rolloverDone);
      expect(e.jarPct, 0);
    });

    test('outgoing messages carry the protocol version', () {
      final json =
          jsonDecode(StageSetPaused(true).encode()) as Map<String, dynamic>;
      expect(json['v'], kStageProtocolVersion);
      expect(json['type'], 'setPaused');
      expect(json['paused'], isTrue);
    });
  });
}
