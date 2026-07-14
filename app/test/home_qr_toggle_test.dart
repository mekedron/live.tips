import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/app_settings.dart';
import 'package:live_tips/domain/band_settings.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/song_request_settings.dart';
import 'package:live_tips/domain/tip_jar.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

const _tipJar = TipJar(
  productId: 'prod_1',
  priceId: 'price_1',
  paymentLinkId: 'plink_1',
  url: 'https://buy.stripe.com/test_toggle',
  currency: 'eur',
  displayName: 'The Midnight Foxes',
  livemode: false,
);

const _relayJar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'The Midnight Foxes',
  currency: 'eur',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

void main() {
  testWidgets(
      'home shows the QR toggle with both jars; switching persists the mode',
      (tester) async {
    final localStore = await seededStore(accountValues: {
      LocalStore.kTipJarBase: jsonEncode(_tipJar.toJson()),
      LocalStore.kRelayJarBase: jsonEncode(_relayJar.toJson()),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(localStore),
          secureStoreProvider.overrideWithValue(SecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Both modes exist → the toggle renders; the default mode is connected,
    // so the caption explains the tip page instead of showing the raw URL.
    expect(find.text('All methods'), findsOneWidget);
    expect(find.text('Stripe only'), findsOneWidget);
    expect(
      find.text(
        'Fans pick Stripe, Revolut, MobilePay or Monzo on your tip page.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Stripe only'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stripe only'));
    await tester.pumpAndSettle();

    // The switch is persisted into the band's settings, the caption yields
    // to the Stripe URL.
    expect(localStore.readBandSettings(kTestAccountId).qrMode, QrMode.stripe);
    expect(
      find.text(
        'Fans pick Stripe, Revolut, MobilePay or Monzo on your tip page.',
      ),
      findsNothing,
    );
    expect(find.textContaining('buy.stripe.com'), findsOneWidget);

    // And back.
    await tester.tap(find.text('All methods'));
    await tester.pumpAndSettle();
    expect(
      localStore.readBandSettings(kTestAccountId).qrMode,
      QrMode.connected,
    );
  });

  testWidgets('single-mode installs get no toggle', (tester) async {
    final localStore = await seededStore(accountValues: {
      LocalStore.kRelayJarBase: jsonEncode(_relayJar.toJson()),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(localStore),
          secureStoreProvider.overrideWithValue(SecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All methods'), findsNothing);
    expect(find.text('Stripe only'), findsNothing);
  });

  testWidgets(
      'song requests OFF: no take-requests row, no Requests tab — the page '
      'stays exactly as it was before the feature', (tester) async {
    final localStore = await seededStore(accountValues: {
      LocalStore.kRelayJarBase: jsonEncode(_relayJar.toJson()),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(localStore),
          secureStoreProvider.overrideWithValue(SecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Take song requests'), findsNothing);
    expect(find.text('Requests'), findsNothing);
  });

  testWidgets(
      'song requests ON: the go-live switch row appears (on by default) and '
      'the Requests tab joins the nav', (tester) async {
    final localStore = await seededStore(accountValues: {
      LocalStore.kRelayJarBase: jsonEncode(_relayJar.toJson()),
      LocalStore.kBandSettingsBase: jsonEncode(const BandSettings(
        songRequests: SongRequestSettings(enabled: true),
      ).toJson()),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(localStore),
          secureStoreProvider.overrideWithValue(SecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Take song requests'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);

    // The nav tab opens the queue screen.
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('No live set right now'), findsOneWidget);
  });
}
