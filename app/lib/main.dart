import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform_support.dart';
import 'data/cloud_migrator.dart';
import 'data/local_store.dart';
import 'data/migrations.dart';
import 'data/secure_store.dart';
import 'domain/app_account.dart';
import 'firebase_options.dart';
import 'l10n/app_locale.dart';
import 'l10n/app_localizations.dart';
import 'state/auth_providers.dart';
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

  // Cloud accounts are strictly additive: a failed Firebase boot (or an
  // unsupported platform) leaves both handles null and the app runs local
  // mode exactly as it always has.
  FirebaseAuth? firebaseAuth;
  FirebaseFirestore? firestore;
  if (platformSupportsCloudAccounts) {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      firebaseAuth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('firebase unavailable, running local-only: $e');
    }
  }

  // Warm the active locale's string table before the first frame so the UI
  // opens already translated (the saved language, else the device language,
  // resolved to the nearest shipped locale).
  final settings = localStore.readSettings();
  var savedLocaleCode = settings.localeCode;
  // Opened from a localized landing page (…/app/?lang=fi)? Select that language
  // and remember it, so the app matches the page the visitor came from. A
  // valid `lang` always wins; an unknown/absent code leaves the saved (or
  // device) language untouched.
  if (kIsWeb) {
    final adopted = localeCodeFromLandingParam(
        savedLocaleCode, Uri.base.queryParameters['lang']);
    if (adopted != null) {
      savedLocaleCode = adopted;
      await localStore.saveSettings(settings.copyWith(localeCode: adopted));
    }
  }
  final bootLocale = resolveSupportedLocale(
    savedLocaleCode != null
        ? Locale(savedLocaleCode)
        : WidgetsBinding.instance.platformDispatcher.locale,
  );
  await AppLocalizations.load(bootLocale);

  // Prefs-side migration/creation of the accounts registry. Never touches
  // the keychain, so it can't block or fail transiently.
  final registry = await ensureAccountsRegistry(localStore);
  var activeId = registry.activeId;

  // A cloud profile can only be active while its Firebase user is the one
  // signed in — a signed-out or switched session falls back to the local
  // profile rather than showing another account's cache.
  final directory = localStore.readAccountsDirectory();
  final currentUid = firebaseAuth?.currentUser?.uid;
  if (directory != null && directory.activeAccountId != kLocalAccountId) {
    if (currentUid == directory.activeAccountId) {
      // The keychain secrets below must belong to the CLOUD profile's
      // active band, not the local registry's.
      activeId = localStore.readActiveCloudBand(currentUid!) ?? activeId;
    } else {
      await localStore
          .saveAccountsDirectory(directory.withActive(kLocalAccountId));
    }
  }

  // A local→cloud upload that crashed mid-flight resumes before the UI
  // needs the bands; for a different (or signed-out) user the migrator
  // clears the stale flag itself on its next run.
  if (firestore != null && currentUid != null) {
    final migrator = CloudMigrator(
        local: localStore, secure: secureStore, db: firestore);
    if (migrator.hasPendingUpload) {
      unawaited(migrator.uploadLocalBands(currentUid));
    }
  }

  String? apiKey;
  String? relaySecret;
  if (kDebugMode && _devStripeKey.isNotEmpty) {
    assert(
      _devStripeKey.contains('_test_'),
      'DEV_STRIPE_KEY must be a test-mode key',
    );
    apiKey = _devStripeKey;
  } else {
    try {
      // Keychain-side migration is retried each boot until it sticks; a
      // locked/prompting keychain just means booting signed-out this once.
      await migrateKeychainIfNeeded(localStore, secureStore, registry);
      apiKey = await secureStore.readApiKey(activeId);
      relaySecret = await secureStore.readRelaySecret(activeId);
    } catch (_) {
      // Keychain read can fail transiently (fresh installs, locked keychain);
      // treat as signed out rather than crashing before the first frame.
    }
  }

  // A real account — live Stripe key or a connected relay jar — must never
  // surface tips left over from demo or test play. connect()/setRelayJar()
  // scrub on the way in; this covers accounts that were already connected
  // before that scrubbing existed. Test-mode sessions are the user's own
  // real integration tests, so they're left alone here.
  final hasRealAccount =
      (apiKey != null && !apiKey.contains('_test_')) ||
      localStore.readRelayJar(activeId) != null;
  if (hasRealAccount) {
    await localStore.purgeSimulatedData(activeId);
  }

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(secureStore),
        initialApiKeyProvider.overrideWithValue(apiKey),
        initialRelaySecretProvider.overrideWithValue(relaySecret),
        firebaseAuthProvider.overrideWithValue(firebaseAuth),
        firestoreProvider.overrideWithValue(firestore),
      ],
      child: const LiveTipsApp(),
    ),
  );
}
