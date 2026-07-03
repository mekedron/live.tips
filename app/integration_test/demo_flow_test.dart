import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:live_tips/main.dart' as app;

/// End-to-end demo flow on a real device/simulator:
/// welcome → demo mode → start a session → demo donations arrive →
/// stop → summary. Captures screenshots for visual review.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(String name) async {
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }
    await binding.takeScreenshot(name);
  }

  testWidgets('demo session collects donations and stops with a summary',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Fresh install lands on welcome. (Simulator state may persist between
    // runs; if we're already in demo-home, skip the welcome step.)
    final demoButton = find.text('Try the demo');
    if (demoButton.evaluate().isNotEmpty) {
      await tester.ensureVisible(demoButton);
      await tester.pumpAndSettle();
      await tester.tap(demoButton);
      await tester.pumpAndSettle();
    }

    expect(find.text('Start live session'), findsOneWidget);
    await shoot('01_home_demo');

    await tester.tap(find.text('Start live session'));
    // Don't pumpAndSettle: the live screen has repeating timers + confetti.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // First demo poll fires immediately and always tips.
    expect(find.textContaining('tips'), findsWidgets);
    expect(find.textContaining('goal'), findsWidgets);
    await shoot('02_live_session');

    // Let a couple more donations roll in (demo polls every ~4s).
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await shoot('03_live_session_later');

    // Stop the session via the top-bar stop button → confirm dialog.
    await tester.tap(find.byTooltip('Stop session'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Stop'));
    await tester.pump(const Duration(seconds: 1));

    // Summary dialog shows either outcome depending on how generous the
    // random demo crowd felt.
    final summaryShown = find.text('Session done').evaluate().isNotEmpty ||
        find.text('🎉 Goal reached!').evaluate().isNotEmpty;
    expect(summaryShown, isTrue);
    await shoot('04_summary');

    await tester.tap(find.text('Done'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Start live session'), findsOneWidget);
  });
}
