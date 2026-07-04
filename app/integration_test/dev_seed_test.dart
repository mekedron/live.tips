import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/data/stripe/stripe_client.dart';
import 'package:live_tips/data/stripe/stripe_requests.dart';

/// Dev utility, not a test of the app: seeds this device with a Stripe
/// TEST-mode key and a freshly created tip jar, so a normal `flutter run`
/// boots straight into the connected home screen. Usage:
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/dev_seed_test.dart \
///     --dart-define=SEED_KEY=rk_test_… -d macos
const _key = String.fromEnvironment('SEED_KEY');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dev seed: store key + create a sandbox tip jar',
      (tester) async {
    if (_key.isEmpty) {
      markTestSkipped('pass --dart-define=SEED_KEY=rk_test_…');
      return;
    }
    expect(_key.contains('_test_'), isTrue,
        reason: 'refusing to seed a LIVE key — this tool is test-mode only');

    // Real HTTP + platform channels need runAsync inside testWidgets.
    await tester.runAsync(() async {
      final requests = StripeRequests(StripeClient(_key));
      final jar = await requests.createTipJar(
        currency: 'eur',
        displayName: 'Nikita — stage test',
        thankYouMessage: 'Thanks for the tip! 💛',
      );

      await SecureStore().writeApiKey(_key);
      final local = await LocalStore.init();
      await local.saveTipJar(jar);
      debugPrint('SEEDED_TIP_JAR_URL=${jar.url}');
      debugPrint('SEEDED_PAYMENT_LINK=${jar.paymentLinkId}');
    });
  });
}
