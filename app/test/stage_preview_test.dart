import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/features/live/stage/stage_resolver.dart';
import 'package:live_tips/features/settings/stage_preview_screen.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the real preview: open the form, fill name/message/amount, submit,
/// and after the ~1 s beat the tip lands on the stage exactly like a live one.
/// [stageCapabilityProvider] is forced off so the WebView-free classic
/// fallback renders the tip (the jar's own banner is covered by
/// tip_banner_test) — no real WebView, no dangling renderer timers.
Future<ProviderScope> _host() async {
  SharedPreferences.setMockInitialValues({});
  final localStore = await LocalStore.init();
  return ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(localStore),
      secureStoreProvider.overrideWithValue(SecureStore()),
      initialApiKeyProvider.overrideWithValue(null),
      stageCapabilityProvider.overrideWithValue(false),
    ],
    child: const MaterialApp(home: StagePreviewScreen()),
  );
}

void main() {
  testWidgets('shows preview chrome, never live/Stripe status', (tester) async {
    await tester.pumpWidget(await _host());
    await tester.pump();

    expect(find.text('Stage preview'), findsOneWidget);
    expect(find.text('Pretend tip'), findsOneWidget);
    expect(find.text('Scan to tip'), findsOneWidget, reason: 'QR is shown');

    // The stage's live-only status chrome must be gone.
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('Watching Stripe'), findsNothing);
  });

  testWidgets('a pretend tip lands on the stage after the processing beat',
      (tester) async {
    await tester.pumpWidget(await _host());
    await tester.pumpAndSettle();

    // Open the fan-facing form.
    await tester.tap(find.text('Pretend tip'));
    await tester.pumpAndSettle();
    expect(find.text('Send a pretend tip'), findsOneWidget);

    // Fill amount, name, message (fields in column order).
    await tester.enterText(find.byType(TextField).at(0), '42');
    await tester.enterText(find.byType(TextField).at(1), 'Nadia');
    await tester.enterText(find.byType(TextField).at(2), 'Loved it!');

    await tester.tap(find.text('Drop it in the jar'));
    // Let the sheet close and the pending beat begin.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Adding your tip…'), findsOneWidget,
        reason: 'the ~1 s beat before the tip lands');
    expect(find.textContaining('Nadia tipped'), findsNothing,
        reason: 'not until the beat is over');

    // The beat elapses → the tip lands with its name, amount and message.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Adding your tip…'), findsNothing);
    expect(find.textContaining('Nadia tipped'), findsAtLeastNWidgets(1));
    expect(find.text('“Loved it!”'), findsAtLeastNWidgets(1));
  });

  testWidgets('mobile lays out its bottom bar without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await _host());
    await tester.pump();

    // A RenderFlex overflow would throw and fail this test.
    expect(find.text('Pretend tip'), findsOneWidget);
    expect(find.byTooltip('Show QR'), findsOneWidget);
    expect(find.byTooltip('Stage look'), findsOneWidget);
  });

  testWidgets('an empty amount is rejected', (tester) async {
    await tester.pumpWidget(await _host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pretend tip'));
    await tester.pumpAndSettle();

    // Submit with no amount → error, sheet stays open.
    await tester.tap(find.text('Drop it in the jar'));
    await tester.pump();
    expect(find.text('Enter an amount greater than 0'), findsOneWidget);
    expect(find.text('Send a pretend tip'), findsOneWidget);
  });
}
