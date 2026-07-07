import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/features/onboarding/method_select_screen.dart';

/// Tall surface: the screen is a lazy ListView, and the warning card plus
/// the Continue button must be on-screen for the finders to see them.
Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(600, 1500));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildLightTheme(),
        home: const MethodSelectScreen(),
      ),
    ),
  );
}

const _warningTitle = 'Before you add Revolut or MobilePay';

bool _continueEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

void main() {
  testWidgets('nothing is preselected; Stripe is recommended',
      (tester) async {
    await _pump(tester);

    expect(find.text('Recommended'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(3));
    expect(find.text(_warningTitle), findsNothing);
    expect(_continueEnabled(tester), isFalse,
        reason: 'no method picked yet — nothing to continue with');
  });

  testWidgets('selecting Stripe alone shows no warning and enables Continue',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Stripe'));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text(_warningTitle), findsNothing);
    expect(_continueEnabled(tester), isTrue);
  });

  testWidgets('selecting Revolut alongside Stripe surfaces the honest warning',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Stripe'));
    await tester.pump();
    await tester.tap(find.text('Revolut'));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
    expect(find.text(_warningTitle), findsOneWidget);
    // Stripe still selected → the stronger plea is absent.
    expect(find.textContaining('We strongly recommend keeping Stripe'),
        findsNothing);
  });

  testWidgets('a relay method without Stripe gets the stronger warning',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('MobilePay'));
    await tester.pump();

    expect(find.text(_warningTitle), findsOneWidget);
    expect(find.textContaining('We strongly recommend keeping Stripe'),
        findsOneWidget);
    expect(_continueEnabled(tester), isTrue,
        reason: 'MobilePay alone is still a valid selection');
  });

  testWidgets('deselecting back to empty disables Continue', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Stripe'));
    await tester.pump();
    await tester.tap(find.text('Stripe'));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(_continueEnabled(tester), isFalse);
    expect(find.text(_warningTitle), findsNothing);
  });
}
