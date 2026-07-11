import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:live_tips/features/live/stage/web_stage/web_stage.dart';
import 'package:live_tips/main.dart' as app;

/// End-to-end demo flow on a real device/simulator:
/// welcome → demo mode → start a session → demo tips arrive →
/// stop → summary. Captures screenshots for visual review.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(String name) async {
    // integration_test screenshots are mobile-only; desktop runs verify
    // behavior, not pixels (grab those manually if needed).
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }
    await binding.takeScreenshot(name);
  }

  testWidgets('demo session collects tips and stops with a summary',
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
    // Don't pumpAndSettle: the live screen has repeating timers + confetti
    // (and in jar styles a continuously-rendering WebView).
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // First demo poll fires immediately and always tips. The default stage
    // style is the 3D jar (native HUD says "this jar: …"); platforms without
    // WebView fall back to the classic screen ("of … goal").
    final jarHud = find.textContaining('this jar');
    final classicGoal = find.textContaining('goal');
    expect(jarHud.evaluate().isNotEmpty || classicGoal.evaluate().isNotEmpty,
        isTrue);
    await shoot('02_live_session');

    // On WebView platforms the 3D stage must actually come up: handshake
    // done (poster spinner gone) and no fallback to classic happened.
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      for (var i = 0;
          i < 40 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(WebStage), findsOneWidget,
          reason: 'jar3d should not have fallen back');
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'renderer must reach ready (first frame drawn)');
    }

    // Let a couple more tips roll in (demo polls every ~4s).
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
