import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// Drives the reordered onboarding: Welcome → details → method select → the
/// first per-method step, checking each screen renders and carries through.
void main() {
  testWidgets('onboarding runs details → methods → per-method step',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await seededStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(SecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Welcome → device kind → details (no install nudge off the web).
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('What is this device?'), findsOneWidget);
    await tester.tap(find.text('My own device'));
    await tester.pumpAndSettle();

    // Step 1: details. Name is required to advance.
    expect(find.text('Let\'s set up your tip jar'), findsOneWidget);
    await tester.enterText(
        find.byType(TextField).first, 'The Midnight Foxes');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: method select. The band name was saved to the registry.
    expect(find.text('How do you want to get tipped?'), findsOneWidget);
    expect(store.readAccountsRegistry()!.accounts.first.name,
        'The Midnight Foxes');
    await tester.tap(find.text('Revolut'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3: the Revolut method step, with Save, Skip, and Paste.
    expect(find.text('Revolut username'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Skip — set up later'), findsOneWidget);
    expect(find.byTooltip('Paste'), findsOneWidget);

    // Skipping advances to the final screen (no methods entered → all set).
    await tester.tap(find.text('Skip — set up later'));
    await tester.pumpAndSettle();
    expect(find.text('You\'re all set'), findsOneWidget);
  });

  testWidgets('a named profile with no method yet comes back to a PREFILLED '
      'details step', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // The profile was named on the details step and then abandoned before a
    // payment method — "Set it up" must not act like the name never existed.
    final store = await seededStore(bandName: 'The Midnight Foxes');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(SecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My own device'));
    await tester.pumpAndSettle();

    final name = tester.widget<TextField>(find.byType(TextField).first);
    expect(name.controller?.text, 'The Midnight Foxes');
  });
}
