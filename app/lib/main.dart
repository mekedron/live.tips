import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/local_store.dart';
import 'data/secure_store.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStore = await LocalStore.init();
  final secureStore = SecureStore();
  String? apiKey;
  try {
    apiKey = await secureStore.readApiKey();
  } catch (_) {
    // Keychain read can fail transiently (fresh installs, locked keychain);
    // treat as signed out rather than crashing before the first frame.
    apiKey = null;
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
