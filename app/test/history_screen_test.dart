import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/features/history/history_screen.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/widgets/tip_tile.dart';

import 'helpers.dart';

const relayJar = RelayJar(
  jarId: 'jar_relay',
  tipUrl: 'https://live.tips/t/jar_relay',
  artistName: 'Foxy Live',
  currency: 'eur',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

Tip relayTip(int serial) => Tip.relayTip(
  amountMinor: 700,
  currency: 'eur',
  method: TipMethod.mobilepay,
  name: 'Maya',
  message: 'Encore!',
  ts: 1751500000000,
  serial: serial,
);

/// Boots the screen over a store seeded straight through prefs — the same
/// bytes a real device would have (per-band keys plus the registry).
Future<void> pumpHistory(
  WidgetTester tester, {
  List<Tip> relayHistory = const [],
  bool withRelayJar = false,
  bool withStripe = false,
}) async {
  final store = await seededStore(
    accountValues: {
      if (withRelayJar) LocalStore.kRelayJarBase: jsonEncode(relayJar.toJson()),
      if (relayHistory.isNotEmpty)
        LocalStore.kRelayHistoryBase: jsonEncode([
          for (final d in relayHistory) d.toJson(),
        ]),
    },
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(SecureStore()),
        initialApiKeyProvider.overrideWithValue(
          withStripe ? 'rk_test_0123456789abcd' : null,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),

        theme: buildLightTheme(),
        home: const Scaffold(body: HistoryScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'Stripe connected, no relay anywhere → exactly the familiar two tabs, '
    'untouched labels',
    (tester) async {
      await pumpHistory(tester, withStripe: true);

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Tips'), findsOneWidget);
      expect(find.text('MobilePay'), findsNothing);
      expect(find.text('Revolut'), findsNothing);
      expect(find.text('Stripe'), findsNothing);
    },
  );

  testWidgets(
    'no Stripe key and no relay history → only the Sessions tab',
    (tester) async {
      await pumpHistory(tester);

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Tips'), findsNothing);
      expect(find.text('Stripe'), findsNothing);
      expect(find.text('MobilePay'), findsNothing);
      expect(find.text('Revolut'), findsNothing);
    },
  );

  testWidgets('a connected-mode jar (Revolut) brings a second tab, and the '
      'tips tab is relabelled Stripe', (tester) async {
    await pumpHistory(tester, withRelayJar: true, withStripe: true);

    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Stripe'), findsOneWidget);
    expect(find.text('Revolut'), findsOneWidget);
    expect(find.text('MobilePay'), findsNothing);
    expect(find.text('Tips'), findsNothing);

    // No archived tips yet → the honest empty state.
    await tester.tap(find.text('Revolut'));
    await tester.pump();
    expect(find.textContaining('after your next live session'), findsOneWidget);
  });

  testWidgets(
    'a connected-mode jar (Revolut) with no Stripe key → Revolut tab only, '
    'no Stripe/Tips tab',
    (tester) async {
      await pumpHistory(tester, withRelayJar: true);

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Revolut'), findsOneWidget);
      expect(find.text('Stripe'), findsNothing);
      expect(find.text('Tips'), findsNothing);
    },
  );

  testWidgets(
    'the MobilePay tab lists archived tips as badged TipTiles under '
    'the recorded-on-this-device note',
    (tester) async {
      await pumpHistory(
        tester,
        withRelayJar: true,
        relayHistory: [relayTip(0)],
      );

      // The jar's Revolut tab and the archived MobilePay tip's own tab both
      // show up.
      expect(find.text('Revolut'), findsOneWidget);
      expect(find.text('MobilePay'), findsOneWidget);

      await tester.tap(find.text('MobilePay'));
      await tester.pump();

      expect(find.textContaining('Recorded on this device'), findsOneWidget);
      final tile = find.byType(TipTile);
      expect(tile, findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Encore!'), findsOneWidget);
      // The MobilePay tab label plus the tile's own method badge.
      expect(find.text('MobilePay'), findsNWidgets(2));
      expect(find.text('unverified'), findsOneWidget);
      // No Stripe transaction behind it → the row must be inert.
      expect(
        find.descendant(of: tile, matching: find.byType(InkWell)),
        findsNothing,
      );
    },
  );

  testWidgets('relay history alone (jar since deleted) still shows its tab — '
      'the tips must stay reachable', (tester) async {
    await pumpHistory(tester, relayHistory: [relayTip(0)]);

    expect(find.text('MobilePay'), findsOneWidget);
    expect(find.text('Revolut'), findsNothing);
  });
}
