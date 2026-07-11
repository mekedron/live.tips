import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip_jar.dart';
import 'package:live_tips/features/settings/settings_screen.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

const _tipJar = TipJar(
  productId: 'prod_1',
  priceId: 'price_1',
  paymentLinkId: 'plink_1',
  url: 'https://buy.stripe.com/test_settings',
  currency: 'eur',
  displayName: 'The Midnight Foxes',
  livemode: false,
  thankYouMessage: 'Cheers! 🎶',
);

const _relayJar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'The Midnight Foxes',
  currency: 'eur',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

Future<void> _pumpSettings(
  WidgetTester tester, {
  required bool withStripe,
}) async {
  // Tall surface so the whole settings list lays out without a scroll.
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localStore = await seededStore(
    accountValues: {
      if (withStripe) LocalStore.kTipJarBase: jsonEncode(_tipJar.toJson()),
      LocalStore.kRelayJarBase: jsonEncode(_relayJar.toJson()),
    },
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(SecureStore()),
        initialApiKeyProvider.overrideWithValue(
          withStripe ? 'rk_test_0123456789abcd' : null,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),

        theme: buildLightTheme(),
        home: const Scaffold(body: SettingsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Account details replaces the old account/key section', (
    tester,
  ) async {
    await _pumpSettings(tester, withStripe: true);

    // The new top section (LtSectionLabel upper-cases its header) and its rows.
    expect(find.text('ACCOUNT DETAILS'), findsOneWidget);
    expect(find.text('Name, currency and thank-you message'), findsOneWidget);
    expect(find.text('Switch account'), findsOneWidget);
    expect(find.text('Remove this account from this device'), findsOneWidget);

    // The retired payment-methods rows are gone.
    expect(find.text('New tip page link'), findsNothing);
    expect(find.text('Disconnect tip page'), findsNothing);
  });

  testWidgets('band name row opens the Account Details editor', (tester) async {
    await _pumpSettings(tester, withStripe: true);

    await tester.tap(find.text('Name, currency and thank-you message'));
    await tester.pumpAndSettle();

    // The editor shows the three onboarding fields, prefilled.
    expect(find.text('Artist or band name'), findsOneWidget);
    expect(find.text('Thank-you message'), findsOneWidget);
    expect(find.text('Cheers! 🎶'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('Stripe row opens the key editor; Revolut opens its own page', (
    tester,
  ) async {
    await _pumpSettings(tester, withStripe: true);

    // Stripe is now a tappable full page with a paste button and a disconnect.
    await tester.tap(find.text('Stripe'));
    await tester.pumpAndSettle();
    expect(find.text('Verify & update'), findsOneWidget);
    expect(find.byTooltip('Paste'), findsOneWidget);
    expect(find.text('Disconnect Stripe'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Revolut opens its own single-method editor with a Paste button and a
    // separate Remove button (shown because the jar already has Revolut set).
    await tester.tap(find.text('Revolut'));
    await tester.pumpAndSettle();
    expect(find.text('Revolut username'), findsOneWidget);
    expect(find.byTooltip('Paste'), findsOneWidget);
    expect(find.text('Remove Revolut'), findsOneWidget);
    // Prefilled from the stored jar.
    expect(find.text('foxy'), findsOneWidget);
  });

  testWidgets(
    'with no Stripe, the row invites connecting and skips onboarding',
    (tester) async {
      await _pumpSettings(tester, withStripe: false);

      // The row reads "Add Stripe" and opens the minimal key editor — not the
      // full onboarding jar-setup form (no name / currency / thank-you here).
      await tester.tap(find.text('Add Stripe'));
      await tester.pumpAndSettle();
      expect(find.text('Verify & connect'), findsOneWidget);
      expect(find.text('Paste your key'), findsOneWidget);
      expect(find.text('Thank-you message'), findsNothing);
      expect(find.text('Currency'), findsNothing);
    },
  );
}
