import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/donation_source.dart';
import '../data/local_store.dart';
import '../data/relay/relay_client.dart';
import '../data/relay/relay_config.dart';
import '../data/relay/relay_tip_channel.dart';
import '../data/secure_store.dart';
import '../data/stripe/stripe_client.dart';
import '../data/stripe/stripe_requests.dart';
import '../domain/app_settings.dart';
import '../domain/donation.dart';
import '../domain/relay_jar.dart';
import '../domain/tip_jar.dart';

/// Overridden in main() with initialized instances.
final localStoreProvider =
    Provider<LocalStore>((ref) => throw UnimplementedError());
final secureStoreProvider =
    Provider<SecureStore>((ref) => throw UnimplementedError());

/// API key read from secure storage before the first frame.
final initialApiKeyProvider = Provider<String?>((ref) => null);

/// Relay jar secret read from secure storage before the first frame.
final initialRelaySecretProvider = Provider<String?>((ref) => null);

class AppState {
  const AppState({
    this.apiKey,
    this.tipJar,
    this.relayJar,
    this.relaySecret,
    required this.settings,
    this.demo = false,
  });

  final String? apiKey;
  final TipJar? tipJar;

  /// Connected-mode jar on the live.tips relay (MobilePay/Revolut tips).
  /// Either account — Stripe key or relay jar — is enough to run the app.
  final RelayJar? relayJar;
  final String? relaySecret;
  final AppSettings settings;
  final bool demo;

  bool get hasStripe => apiKey != null;
  bool get hasRelay => relayJar != null;
  bool get connected => demo || hasStripe || hasRelay;
  bool get isTestMode => demo || (apiKey?.contains('_test_') ?? false);
  TipJar? get effectiveTipJar => demo ? TipJar.demo : tipJar;
  RelayJar? get effectiveRelayJar => demo ? RelayJar.demo : relayJar;

  /// The name shown on home/stage/poster: the Stripe jar's display name when
  /// one exists, else the relay jar's artist name, else empty.
  String get displayName {
    final jarName = effectiveTipJar?.displayName ?? '';
    if (jarName.isNotEmpty) return jarName;
    return effectiveRelayJar?.artistName ?? '';
  }

  String get currency =>
      effectiveTipJar?.currency ?? effectiveRelayJar?.currency ?? 'usd';

  /// [AppSettings.qrMode] clamped to what's actually configured: the setting
  /// may name a mode whose jar doesn't exist (defaults, half-configured
  /// installs), and every QR surface must still resolve to something real.
  QrMode get effectiveQrMode {
    switch (settings.qrMode) {
      case QrMode.connected:
        return effectiveRelayJar != null ? QrMode.connected : QrMode.stripe;
      case QrMode.stripe:
        if (effectiveTipJar != null) return QrMode.stripe;
        return effectiveRelayJar != null ? QrMode.connected : QrMode.stripe;
    }
  }

  /// The one URL every QR surface encodes — Stripe payment link or the
  /// connected-mode donor page, per [effectiveQrMode]. Null only when
  /// nothing is configured at all.
  String? get activeQrUrl => effectiveQrMode == QrMode.connected
      ? effectiveRelayJar?.donateUrl
      : effectiveTipJar?.url;

  /// Whether the artist could actually toggle between the two QR modes.
  bool get hasBothQrModes =>
      effectiveTipJar != null && effectiveRelayJar != null;
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    final local = ref.read(localStoreProvider);
    return AppState(
      apiKey: ref.read(initialApiKeyProvider),
      tipJar: local.readTipJar(),
      relayJar: local.readRelayJar(),
      relaySecret: ref.read(initialRelaySecretProvider),
      settings: local.readSettings(),
    );
  }

  Future<void> connect(String apiKey) async {
    final trimmed = apiKey.trim();
    await ref.read(secureStoreProvider).writeApiKey(trimmed);
    // A newly connected account must not inherit demo/test tips from earlier
    // play — otherwise its history shows donations that never happened.
    await ref.read(localStoreProvider).purgeSimulatedData();
    state = AppState(
      apiKey: trimmed,
      tipJar: state.tipJar,
      relayJar: state.relayJar,
      relaySecret: state.relaySecret,
      settings: state.settings,
    );
  }

  void enterDemo() {
    state = AppState(
      apiKey: state.apiKey,
      tipJar: state.tipJar,
      relayJar: state.relayJar,
      relaySecret: state.relaySecret,
      settings: state.settings,
      demo: true,
    );
  }

  void exitDemo() {
    state = AppState(
      apiKey: state.apiKey,
      tipJar: state.tipJar,
      relayJar: state.relayJar,
      relaySecret: state.relaySecret,
      settings: state.settings,
    );
  }

  Future<void> setTipJar(TipJar jar) async {
    await ref.read(localStoreProvider).saveTipJar(jar);
    state = AppState(
      apiKey: state.apiKey,
      tipJar: jar,
      relayJar: state.relayJar,
      relaySecret: state.relaySecret,
      settings: state.settings,
      demo: state.demo,
    );
  }

  /// Adopts a freshly created relay jar: the secret goes to the keychain,
  /// the jar itself to local prefs. Like [connect], a real account must not
  /// inherit demo/test tips from earlier play.
  Future<void> setRelayJar(RelayJar jar, String secret) async {
    await ref.read(secureStoreProvider).writeRelaySecret(secret);
    await ref.read(localStoreProvider).saveRelayJar(jar);
    await ref.read(localStoreProvider).purgeSimulatedData();
    state = AppState(
      apiKey: state.apiKey,
      tipJar: state.tipJar,
      relayJar: jar,
      relaySecret: secret,
      settings: state.settings,
    );
  }

  /// Saves an edited relay jar (rename etc.) locally — the secret is
  /// untouched and telling the relay itself is the caller's job.
  Future<void> updateRelayJarLocal(RelayJar jar) async {
    await ref.read(localStoreProvider).saveRelayJar(jar);
    state = AppState(
      apiKey: state.apiKey,
      tipJar: state.tipJar,
      relayJar: jar,
      relaySecret: state.relaySecret,
      settings: state.settings,
      demo: state.demo,
    );
  }

  /// Forgets the relay jar on this device. Deleting it on the relay itself
  /// (network DELETE) is the caller's job.
  Future<void> clearRelayJar() async {
    await ref.read(secureStoreProvider).deleteRelaySecret();
    await ref.read(localStoreProvider).clearRelayJar();
    state = AppState(
      apiKey: state.apiKey,
      tipJar: state.tipJar,
      settings: state.settings,
      demo: state.demo,
    );
  }

  Future<void> updateSettings(AppSettings settings) async {
    await ref.read(localStoreProvider).saveSettings(settings);
    state = AppState(
      apiKey: state.apiKey,
      tipJar: state.tipJar,
      relayJar: state.relayJar,
      relaySecret: state.relaySecret,
      settings: settings,
      demo: state.demo,
    );
  }

  /// Removes the key and every trace of local data.
  Future<void> disconnect() async {
    // Best effort: retire the connected-mode jar on the relay so the public
    // donor page dies with the local copy. Failures are ignored — the wipe
    // must succeed even offline.
    final relayJar = state.relayJar;
    final relaySecret = state.relaySecret;
    if (relayJar != null && relaySecret != null) {
      final client = RelayClient();
      try {
        await client.deleteJar(jarId: relayJar.jarId, secret: relaySecret);
      } catch (_) {
        // Offline, already gone, or a rotated secret — nothing more to do.
      } finally {
        client.close();
      }
    }
    await ref.read(secureStoreProvider).wipeAll();
    await ref.read(localStoreProvider).wipeAll();
    // The wipe took relay_history_v1 with it — drop the in-memory copy too.
    ref.invalidate(relayHistoryProvider);
    state = const AppState(settings: AppSettings());
  }
}

final appStateProvider =
    NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

/// Builds the donation feed for a session — a seam so controller tests can
/// inject a scripted source instead of the demo/Stripe pollers. The Stripe
/// source constructs and OWNS its HTTP client (closed in dispose): sharing
/// [stripeRequestsProvider]'s client killed every session — any AppState
/// change rebuilt the provider and closed the client mid-poll.
typedef DonationSourceFactory = DonationSource Function({
  required bool demo,
  required String? apiKey,
  required TipJar? jar,
});

final donationSourceFactoryProvider = Provider<DonationSourceFactory>(
  (ref) => ({required demo, required apiKey, required jar}) {
    if (demo) return DemoDonationSource();
    // No Stripe key or no real payment link (relay-only installs): a live
    // session must NEVER pour fake tips, so poll a silent no-op source.
    // Relay tips arrive over their own channel, wired in a later step.
    if (apiKey == null || jar == null || jar.isDemo) {
      return NullDonationSource();
    }
    final client = StripeClient(apiKey);
    return StripeDonationSource(
      StripeRequests(client),
      paymentLinkId: jar.paymentLinkId,
      onDispose: client.close,
    );
  },
);

/// Builds the relay WebSocket tip feed for a session — a seam mirroring
/// [donationSourceFactoryProvider] so controller tests can hand in a fake
/// channel. Null means "this session has no relay feed": demo sessions
/// synthesize their tips, and without a jar + secret there is nothing to
/// authenticate against.
typedef RelayChannelFactory = RelayTipChannel? Function({
  required bool demo,
  required RelayJar? jar,
  required String? secret,
});

final relayChannelFactoryProvider = Provider<RelayChannelFactory>(
  (ref) => ({required demo, required jar, required secret}) {
    if (demo || jar == null || secret == null) return null;
    return RelayTipChannel(wsUri: relayWsUri(jar.jarId), secret: secret);
  },
);

/// Live Stripe API surface for one-off calls (recent tips, jar setup), or
/// null when in demo mode / signed out. Depends ONLY on the key — settings
/// or jar changes must not tear down a client somebody may be awaiting.
final stripeRequestsProvider = Provider<StripeRequests?>((ref) {
  final apiKey =
      ref.watch(appStateProvider.select((s) => s.demo ? null : s.apiKey));
  if (apiKey == null) return null;
  final client = StripeClient(apiKey);
  ref.onDispose(client.close);
  return StripeRequests(client);
});

/// Small preview of latest donations for the home screen.
final recentDonationsProvider =
    FutureProvider.autoDispose<List<Donation>>((ref) async {
  final requests = ref.watch(stripeRequestsProvider);
  final jar = ref.watch(appStateProvider).effectiveTipJar;
  if (requests == null || jar == null || jar.isDemo) return const [];
  final page = await requests.listDonations(limit: 5);
  return page.donations;
});

/// The device-local archive of tip-page (Revolut/MobilePay) tips, newest
/// first. This device is the only witness to these tips — the Stripe API
/// never sees them — so every list that mixes them in reads this. Mirrors
/// StoredSessionNotifier: SharedPreferences can't notify, so the session
/// controller refreshes this explicitly after each write.
class RelayHistoryNotifier extends Notifier<List<Donation>> {
  @override
  List<Donation> build() => ref.read(localStoreProvider).readRelayHistory();

  void refresh() => state = ref.read(localStoreProvider).readRelayHistory();
}

final relayHistoryProvider =
    NotifierProvider<RelayHistoryNotifier, List<Donation>>(
        RelayHistoryNotifier.new);
