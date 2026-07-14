import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/features/live/live_screen.dart';
import 'package:live_tips/features/live/stage/stage_resolver.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// A tip source with nothing to say — these tests are about the doors of the
/// stage, not the money coming through it.
class _SilentSource extends TipSource {
  @override
  Future<void> prime(DateTime startedAt,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Tip>> pollNew() async => const [];

  @override
  String? get cursor => null;
}

/// LiveScreen keeps the screen awake via wakelock_plus, whose pigeon channel
/// has no host in a widget test — an unanswered call becomes an uncaught
/// async error in initState/dispose. Answer `toggle` with a success envelope.
void mockWakelock() {
  const codec = StandardMessageCodec();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    (message) async => codec.encodeMessage(<Object?>[null]),
  );
}

/// The shell stand-in the stage pops back to: one button that re-enters the
/// stage the same way Home's "Return to session" does (push LiveScreen).
class _FakeHome extends StatelessWidget {
  const _FakeHome();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            key: const Key('open-stage'),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LiveScreen())),
            child: const Text('Return to session'),
          ),
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A container whose [liveSessionProvider] runs a real (demo) session —
  /// classic stage forced (no WebView in a test), no tips scripted.
  Future<ProviderContainer> liveContainer() async {
    final store = await seededStore();
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      tipSourceFactoryProvider.overrideWithValue(
          ({required demo, required apiKey, required jar}) =>
              _SilentSource()),
      stageCapabilityProvider.overrideWithValue(false),
    ]);
    addTearDown(container.dispose);
    container.read(appStateProvider.notifier).enterDemo();
    return container;
  }

  Widget app(ProviderContainer container) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: kTestL10nDelegates,
          locale: const Locale('en'),
          home: const _FakeHome(),
        ),
      );

  /// The stage's LIVE pill pulses forever, so pumpAndSettle never settles —
  /// pump the route animation through by hand.
  Future<void> pumpRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
      'the back arrow sits beside Stop, leaves the stage with the session '
      'untouched, and the stage can be re-entered', (tester) async {
    mockWakelock();
    final container = await liveContainer();
    await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);
    final sessionId = container.read(liveSessionProvider)!.session.id;

    await tester.pumpWidget(app(container));
    await tester.tap(find.byKey(const Key('open-stage')));
    await pumpRoute(tester);

    // Both doors are on stage, the arrow immediately beside Stop.
    final arrow = find.byIcon(Icons.arrow_back_rounded);
    final stop = find.byIcon(Icons.stop_rounded);
    expect(arrow, findsOneWidget);
    expect(stop, findsOneWidget);
    expect(tester.getCenter(arrow).dy, tester.getCenter(stop).dy,
        reason: 'the arrow lives in the same control row as Stop');
    expect(tester.getCenter(arrow).dx, lessThan(tester.getCenter(stop).dx),
        reason: 'back leads, Stop follows');

    // The arrow leaves — no dialog, no questions — and the session survives.
    await tester.tap(arrow);
    await pumpRoute(tester);
    expect(find.byKey(const Key('open-stage')), findsOneWidget,
        reason: 'back on the home stand-in');
    final live = container.read(liveSessionProvider);
    expect(live, isNotNull, reason: 'leaving the stage must not stop the set');
    expect(live!.session.id, sessionId,
        reason: 'the same session, not a restarted one');

    // The way back: re-entering the stage finds the same running session.
    await tester.tap(find.byKey(const Key('open-stage')));
    await pumpRoute(tester);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(container.read(liveSessionProvider)!.session.id, sessionId);

    // Wind the night down: the session's poll timer and the stage clock must
    // not outlive the test body (testWidgets' pending-timer invariant).
    await tester.pumpWidget(const SizedBox());
    await container.read(liveSessionProvider.notifier).stop();
  });

  testWidgets('Stop still stops: confirm → summary → home, session gone',
      (tester) async {
    mockWakelock();
    final container = await liveContainer();
    await container.read(liveSessionProvider.notifier).start(goalMinor: 10000);

    await tester.pumpWidget(app(container));
    await tester.tap(find.byKey(const Key('open-stage')));
    await pumpRoute(tester);

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await pumpRoute(tester);
    expect(find.text('Stop this session?'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await pumpRoute(tester);
    expect(container.read(liveSessionProvider), isNull,
        reason: 'Stop is still the door that ends the set');
    expect(find.text('Session done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await pumpRoute(tester);
    expect(find.byKey(const Key('open-stage')), findsOneWidget,
        reason: 'the summary pops the stage back to home');
  });
}
