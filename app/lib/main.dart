import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/local_store.dart';
import 'data/secure_store.dart';
import 'state/providers.dart';

/// Dev convenience (debug builds only): skip the keychain and use this key.
/// On macOS every freshly built ad-hoc binary counts as a "new app" to the
/// keychain, so dev runs otherwise hang on a permission prompt before the
/// first frame. `flutter run --dart-define=DEV_STRIPE_KEY=rk_test_…`
const _devStripeKey = String.fromEnvironment('DEV_STRIPE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStore = await LocalStore.init();
  final secureStore = SecureStore();
  String? apiKey;
  if (kDebugMode && _devStripeKey.isNotEmpty) {
    assert(_devStripeKey.contains('_test_'),
        'DEV_STRIPE_KEY must be a test-mode key');
    apiKey = _devStripeKey;
  } else {
    try {
      apiKey = await secureStore.readApiKey();
    } catch (_) {
      // Keychain read can fail transiently (fresh installs, locked keychain);
      // treat as signed out rather than crashing before the first frame.
      apiKey = null;
    }
  }

  // A real (live) account must never surface tips left over from demo or
  // test play. connect() scrubs on the way in; this covers accounts that were
  // already connected before that scrubbing existed. Test-mode sessions are
  // the user's own real integration tests, so they're left alone here.
  if (apiKey != null && !apiKey.contains('_test_')) {
    await localStore.purgeSimulatedData();
  }

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(secureStore),
        initialApiKeyProvider.overrideWithValue(apiKey),
      ],
      child: const LiveTipsApp(),
    ),
  );
}
