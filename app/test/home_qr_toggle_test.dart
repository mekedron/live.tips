import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/app_settings.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip_jar.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  donateUrl: 'https://live.tips/t/jar_1',
  artistName: 'The Midnight Foxes',
  currency: 'eur',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

void main() {
  testWidgets(
      'home shows the QR toggle with both jars; switching persists the mode',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'tip_jar_v1': jsonEncode(_tipJar.toJson()),
      'relay_jar_v1': jsonEncode(_relayJar.toJson()),
    });
    final localStore = await LocalStore.init();

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
      find.text('Fans pick Stripe, Revolut or MobilePay on your tip page.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Stripe only'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stripe only'));
    await tester.pumpAndSettle();

    // The switch is persisted, the caption yields to the Stripe URL.
    expect(localStore.readSettings().qrMode, QrMode.stripe);
    expect(
      find.text('Fans pick Stripe, Revolut or MobilePay on your tip page.'),
      findsNothing,
    );
    expect(find.textContaining('buy.stripe.com'), findsOneWidget);

    // And back.
    await tester.tap(find.text('All methods'));
    await tester.pumpAndSettle();
    expect(localStore.readSettings().qrMode, QrMode.connected);
  });

  testWidgets('single-mode installs get no toggle', (tester) async {
    SharedPreferences.setMockInitialValues({
      'relay_jar_v1': jsonEncode(_relayJar.toJson()),
    });
    final localStore = await LocalStore.init();

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
}
