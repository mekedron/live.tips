import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/state/auth_providers.dart';
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

    // Welcome → details: "Get started" claims the device for the performer
    // (no device-kind question, no install nudge off the web, and no account
    // step — auth is unavailable in this test). Unavailable auth also means
    // no venue link: it hides entirely rather than render disabled.
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Setting up a shared venue device?'), findsNothing);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Step 1: details. Name is required to advance.
    expect(find.text('Let\'s set up your tip jar'), findsOneWidget);
    await tester.enterText(
        find.byType(TextField).first, 'The Midnight Foxes');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: method select. The band name was saved to the registry — on the
    // ONE band, the one main() seeded for this fresh install. The details step
    // names it; it does not mint a second one beside it. (Sending the local
    // path down `createsProfile: true` — the tempting fix for #47 — is exactly
    // how a fresh install ends up with an unnamed duplicate.)
    expect(find.text('How do you want to get tipped?'), findsOneWidget);
    expect(store.readAccountsRegistry()!.accounts, hasLength(1));
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

    final name = tester.widget<TextField>(find.byType(TextField).first);
    expect(name.controller?.text, 'The Midnight Foxes');
  });

  // This test used to assert the bug as the rule ("claims the device for the
  // venue AND opens the intro"): the link wrote the kind on the tap and the
  // warning explained it afterwards, so Back popped into the venue sign-in door
  // and the only way home was a wipe (#42). The link asks; the steps explain;
  // only a collected sign-in token commits, at the very end.
  // venue_intro_commit_test.dart walks the whole path, Back included.
  testWidgets('the quiet venue link on Welcome opens the intro and claims '
      'nothing — walking the steps is not the choice', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await seededStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(FakeSecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
          // Cloud accounts on offer — the venue link only exists then.
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The link is there but quiet — no card, no icon, just text. And LAST:
    // below the trust row, deliberately far from "Try the demo", so a tipsy
    // artist aiming at the demo can't fat-finger a venue-mode conversion.
    final link = find.text('Setting up a shared venue device?');
    expect(tester.getTopLeft(link).dy,
        greaterThan(tester.getBottomLeft(find.text('Try the demo')).dy));
    expect(
        tester.getTopLeft(link).dy,
        greaterThan(tester
            .getBottomLeft(find.text('Open source · your key never leaves '
                'this device'))
            .dy));

    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text('How a shared device works'), findsOneWidget);
    expect(store.readDeviceKind(), isNull,
        reason: 'asking what a venue device is may not make this one');

    await tester.tap(find.text('Set up sign-in'));
    await tester.pumpAndSettle();

    // The code step is up — and STILL nothing is committed: the kind is
    // chosen by a successfully collected token, not by reaching the screen
    // that asks for one.
    expect(find.text('Sign in from your phone'), findsOneWidget);
    expect(store.readDeviceKind(), isNull);
  });
}
