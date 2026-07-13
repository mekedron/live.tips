import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform_support.dart';
import 'data/cloud_migrator.dart';
import 'data/firebase/account_sessions.dart';
import 'data/firebase/auth_bridge.dart';
import 'data/firebase/auth_domain.dart';
import 'data/local_store.dart';
import 'data/migrations.dart';
import 'data/secure_store.dart';
import 'data/venue_boot.dart';
import 'domain/app_account.dart';
import 'domain/device_kind.dart';
import 'features/venue/venue_boot_blocked_screen.dart';
import 'firebase_options.dart';
import 'l10n/app_locale.dart';
import 'l10n/app_localizations.dart';
import 'state/auth_providers.dart';
import 'state/device_providers.dart';
import 'state/providers.dart';

/// Dev convenience (debug builds only): skip the keychain and use this key.
/// On macOS every freshly built ad-hoc binary counts as a "new app" to the
/// keychain, so dev runs otherwise hang on a permission prompt before the
/// first frame. `flutter run --dart-define=DEV_STRIPE_KEY=rk_test_…`
const _devStripeKey = String.fromEnvironment('DEV_STRIPE_KEY');

Future<void> main() async {
  // FIRST, before anything can touch the URL: on the web, Flutter's URL
  // strategy normalizes the address bar during startup and the `#c=…`
  // fragment an add-device QR carries is simply gone afterwards. Read it now
  // and hand it to the deep-link provider below.
  final bootUrl = kIsWeb ? Uri.base.toString() : null;
  // The auth bridge's `#signin=…` answer rides the same fragment (see
  // auth_bridge.dart) — parsed now for the same reason, and the scrub is
  // welcome: the custom token must not outlive this read in the address bar.
  final bridgeResponse = bootUrl == null ? null : parseBridgeResponse(bootUrl);

  WidgetsFlutterBinding.ensureInitialized();

  final localStore = await LocalStore.init();
  final secureStore = SecureStore();

  // The venue cipher attaches BEFORE any typed read: on a venue install
  // every stored string is an envelope, and reading around the cipher would
  // hand ciphertext to the JSON parsers. The kind key itself is plaintext by
  // design (see LocalStore.readDeviceKind).
  final deviceKind = localStore.readDeviceKind();
  if (deviceKind == DeviceKind.venue) {
    final block = await attachVenueCipher(localStore, secureStore);
    if (block != null) {
      // A cipher that can't attach is a STOP, not a run-degraded condition
      // — see attachVenueCipher for what a degraded boot used to destroy.
      // Nothing below this line runs: nothing is seeded, minted or
      // overwritten. The saved language is an envelope too, so the device
      // locale picks the blocking screen's words.
      final blockedLocale = resolveSupportedLocale(
          WidgetsBinding.instance.platformDispatcher.locale);
      await AppLocalizations.load(blockedLocale);
      runApp(VenueBootBlockedApp(
        block: block,
        locale: blockedLocale,
        // A blocked boot returns before Firebase or any provider exists,
        // so a retry is simply main() again, from the top.
        onRetry: () => unawaited(main()),
        onErase: () async {
          // The confirmed reset — same order as wipeDevice(): keychain
          // first, then prefs, so nothing left can NAME a surviving
          // keychain entry if the wipe half-fails.
          try {
            await secureStore.wipeAll();
          } catch (e) {
            debugPrint('keychain wipe failed: $e');
          }
          await localStore.wipeAll();
          await main();
        },
      ));
      return;
    }
  }

  // Cloud accounts are strictly additive: a failed Firebase boot (or an
  // unsupported platform) leaves the sessions service refusing everything
  // and the app runs local mode exactly as it always has.
  FirebaseAuth? firebaseAuth;
  FirebaseFirestore? firestore;
  FirebaseOptions? firebaseOptions;
  if (platformSupportsCloudAccounts) {
    try {
      // The OAuth handler runs on our own domain (auth.live.tips), not on
      // livetips-app.firebaseapp.com — see data/firebase/auth_domain.dart for
      // why the domain is layered on here instead of in the generated options.
      firebaseOptions =
          withCustomAuthDomain(DefaultFirebaseOptions.currentPlatform);
      await Firebase.initializeApp(options: firebaseOptions);
      firebaseAuth = FirebaseAuth.instance;
      applyCustomAuthDomain(firebaseAuth);
      firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('firebase unavailable, running local-only: $e');
    }
  }

  // One FirebaseApp per signed-in account (see AccountSessions). The default
  // app stays the relay's transport home; restore() revives every persisted
  // slot so switching accounts after this needs no re-auth.
  final sessions = firebaseAuth == null
      ? AccountSessions.unavailable()
      : AccountSessions(
          options: firebaseOptions,
          defaultHandles: SessionHandles(
            auth: firebaseAuth,
            firestore: firestore,
            functionsFor: (region) =>
                FirebaseFunctions.instanceFor(region: region),
          ),
          readSlots: localStore.readAccountSessionSlots,
          saveSlots: localStore.saveAccountSessionSlots,
        );
  sessions.disableFirestorePersistence = deviceKind == DeviceKind.venue;
  await sessions.restore();

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

  // Installs from before per-account apps have their one session on the
  // DEFAULT app; adopt it so it keeps working without a re-auth. The
  // directory is the discriminator: the relay's transport-anonymous uid is
  // never in it, so it can never be adopted as an account.
  final directory = localStore.readAccountsDirectory();
  final defaultUid = firebaseAuth?.currentUser?.uid;
  if (defaultUid != null &&
      (directory?.contains(defaultUid) ?? false) &&
      !sessions.isAlive(defaultUid)) {
    await sessions.adoptDefault(defaultUid);
  }

  // A cloud profile can only be active while its session is alive on this
  // device — a signed-out or dead session falls back to the local profile
  // rather than showing another account's cache.
  if (directory != null && directory.activeAccountId != kLocalAccountId) {
    if (sessions.isAlive(directory.activeAccountId)) {
      // The keychain secrets below must belong to the CLOUD profile's
      // active band, not the local registry's.
      activeId =
          localStore.readActiveCloudBand(directory.activeAccountId) ??
              activeId;
    } else {
      await localStore
          .saveAccountsDirectory(directory.withActive(kLocalAccountId));
    }
  }

  // A local→cloud upload that crashed mid-flight resumes before the UI
  // needs the bands; for a different (or signed-out) user the migrator
  // clears the stale flag itself on its next run.
  final pendingUpload = localStore.readCloudUploadPending();
  if (pendingUpload != null) {
    final db = sessions.sessionFor(pendingUpload.uid)?.firestore ?? firestore;
    if (db != null && sessions.isAlive(pendingUpload.uid)) {
      final migrator =
          CloudMigrator(local: localStore, secure: secureStore, db: db);
      // The migrator logs the reason and, when it is permanent, drops the flag
      // so this boot is the LAST one that tries. Nobody is looking at a
      // resumed upload, so there is nothing here to show — but the failure
      // must not sail off as an unhandled async error either.
      unawaited(migrator
          .uploadLocalBands(pendingUpload.uid)
          .catchError((Object _) => null));
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
        accountSessionsProvider.overrideWithValue(sessions),
        bootLinkUrlProvider.overrideWithValue(bootUrl),
        bridgeResponseProvider.overrideWithValue(bridgeResponse),
      ],
      child: const LiveTipsApp(),
    ),
  );
}
