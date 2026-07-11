import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/donation_source.dart';
import '../data/fx_source.dart';
import '../data/local_store.dart';
import '../data/relay/relay_client.dart';
import '../data/relay/relay_config.dart';
import '../data/relay/relay_tip_channel.dart';
import '../data/secure_store.dart';
import '../data/stripe/stripe_client.dart';
import '../data/stripe/stripe_requests.dart';
import '../domain/app_settings.dart';
import '../domain/band_account.dart';
import '../domain/band_settings.dart';
import '../domain/donation.dart';
import '../domain/fx_rates.dart';
import '../domain/relay_jar.dart';
import '../domain/tip_jar.dart';
import 'live_session_controller.dart';
import 'onboarding_draft.dart';

/// Overridden in main() with initialized instances.
final localStoreProvider =
    Provider<LocalStore>((ref) => throw UnimplementedError());
final secureStoreProvider =
    Provider<SecureStore>((ref) => throw UnimplementedError());

/// Active band's API key, read from secure storage before the first frame.
final initialApiKeyProvider = Provider<String?>((ref) => null);

/// Active band's relay jar secret, read from secure storage before the
/// first frame.
final initialRelaySecretProvider = Provider<String?>((ref) => null);

class AppState {
  const AppState({
    this.accountId = '',
    this.accounts = const [],
    this.apiKey,
    this.tipJar,
    this.relayJar,
    this.relaySecret,
    required this.settings,
    this.band = const BandSettings(),
    this.demo = false,
    this.switching = false,
  });

  /// The active band — every jar/secret below belongs to it, and every
  /// per-band storage read/write is keyed by it.
  final String accountId;

  /// All local bands, creation order (the switcher lists them as-is).
  final List<BandAccount> accounts;

  final String? apiKey;
  final TipJar? tipJar;

  /// Connected-mode jar on the live.tips relay (MobilePay/Revolut tips).
  /// Either account — Stripe key or relay jar — is enough to run the app.
  final RelayJar? relayJar;
  final String? relaySecret;

  /// Device-wide preferences (theme, stage look, poll cadence).
  final AppSettings settings;

  /// The active band's own preferences (QR mode, goal, poster).
  final BandSettings band;

  final bool demo;

  /// True while a band switch is loading its keychain secrets — sessions
  /// must not start and further switches are refused until it commits.
  final bool switching;

  bool get hasStripe => apiKey != null;
  bool get hasRelay => relayJar != null;
  bool get connected => demo || hasStripe || hasRelay;
  bool get isTestMode => demo || (apiKey?.contains('_test_') ?? false);
  TipJar? get effectiveTipJar => demo ? TipJar.demo : tipJar;
  RelayJar? get effectiveRelayJar => demo ? RelayJar.demo : relayJar;

  BandAccount? get activeAccount {
    for (final a in accounts) {
      if (a.id == accountId) return a;
    }
    return null;
  }

  /// The name shown on home/stage/poster: the band's registry name when set,
  /// else the Stripe jar's display name, else the relay jar's artist name.
  String get displayName {
    if (demo) return TipJar.demo.displayName;
    final bandName = activeAccount?.name.trim() ?? '';
    if (bandName.isNotEmpty) return bandName;
    final jarName = effectiveTipJar?.displayName ?? '';
    if (jarName.isNotEmpty) return jarName;
    return effectiveRelayJar?.artistName ?? '';
  }

  String get currency =>
      effectiveTipJar?.currency ?? effectiveRelayJar?.currency ?? 'usd';

  /// [BandSettings.qrMode] clamped to what's actually configured: the
  /// setting may name a mode whose jar doesn't exist (defaults,
  /// half-configured bands), and every QR surface must still resolve to
  /// something real.
  QrMode get effectiveQrMode {
    switch (band.qrMode) {
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

  static const _unset = Object();

  AppState copyWith({
    String? accountId,
    List<BandAccount>? accounts,
    Object? apiKey = _unset,
    Object? tipJar = _unset,
    Object? relayJar = _unset,
    Object? relaySecret = _unset,
    AppSettings? settings,
    BandSettings? band,
    bool? demo,
    bool? switching,
  }) =>
      AppState(
        accountId: accountId ?? this.accountId,
        accounts: accounts ?? this.accounts,
        apiKey: apiKey == _unset ? this.apiKey : apiKey as String?,
        tipJar: tipJar == _unset ? this.tipJar : tipJar as TipJar?,
        relayJar:
            relayJar == _unset ? this.relayJar : relayJar as RelayJar?,
        relaySecret: relaySecret == _unset
            ? this.relaySecret
            : relaySecret as String?,
        settings: settings ?? this.settings,
        band: band ?? this.band,
        demo: demo ?? this.demo,
        switching: switching ?? this.switching,
      );
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    final local = ref.read(localStoreProvider);
    // main() migrates/creates the registry before runApp; the fallback here
    // covers tests that wire a bare store straight into the ProviderScope.
    var registry = local.readAccountsRegistry();
    if (registry == null) {
      final account = BandAccount(
        id: BandAccount.newId(),
        name: '',
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      registry = AccountsRegistry(accounts: [account], activeId: account.id);
      local.saveAccountsRegistry(registry); // fire-and-forget
    }
    final accountId = registry.activeId;
    return AppState(
      accountId: accountId,
      accounts: registry.accounts,
      apiKey: ref.read(initialApiKeyProvider),
      tipJar: local.readTipJar(accountId),
      relayJar: local.readRelayJar(accountId),
      relaySecret: ref.read(initialRelaySecretProvider),
      settings: local.readSettings(),
      band: local.readBandSettings(accountId),
    );
  }

  AccountsRegistry get _registry =>
      AccountsRegistry(accounts: state.accounts, activeId: state.accountId);

  Future<void> connect(String apiKey) async {
    final accountId = state.accountId;
    final trimmed = apiKey.trim();
    await ref.read(secureStoreProvider).writeApiKey(accountId, trimmed);
    // A newly connected account must not inherit demo/test tips from earlier
    // play — otherwise its history shows donations that never happened.
    await ref.read(localStoreProvider).purgeSimulatedData(accountId);
    if (state.accountId != accountId) return; // switched bands mid-await
    state = state.copyWith(apiKey: trimmed, demo: false);
  }

  void enterDemo() {
    state = state.copyWith(demo: true);
  }

  void exitDemo() {
    state = state.copyWith(demo: false);
  }

  Future<void> setTipJar(TipJar jar) async {
    final accountId = state.accountId;
    await ref.read(localStoreProvider).saveTipJar(accountId, jar);
    // A jar names the band — adopt its display name as the registry name so
    // the switcher never shows "Unnamed band" for a configured one.
    await _renameInRegistry(accountId, jar.displayName);
    if (state.accountId != accountId) return;
    state = state.copyWith(tipJar: jar);
  }

  /// Adopts a freshly created relay jar: the secret goes to the keychain,
  /// the jar itself to local prefs. Like [connect], a real account must not
  /// inherit demo/test tips from earlier play.
  Future<void> setRelayJar(RelayJar jar, String secret) async {
    final accountId = state.accountId;
    await ref.read(secureStoreProvider).writeRelaySecret(accountId, secret);
    await ref.read(localStoreProvider).saveRelayJar(accountId, jar);
    await ref.read(localStoreProvider).purgeSimulatedData(accountId);
    final current = _registry;
    if (current.contains(accountId) &&
        current.accounts.firstWhere((a) => a.id == accountId).name.isEmpty) {
      await _renameInRegistry(accountId, jar.artistName);
    }
    if (state.accountId != accountId) return;
    state = state.copyWith(relayJar: jar, relaySecret: secret, demo: false);
  }

  /// Saves an edited relay jar (rename etc.) locally — the secret is
  /// untouched and telling the relay itself is the caller's job.
  Future<void> updateRelayJarLocal(RelayJar jar) async {
    final accountId = state.accountId;
    await ref.read(localStoreProvider).saveRelayJar(accountId, jar);
    if (state.accountId != accountId) return;
    state = state.copyWith(relayJar: jar);
  }

  /// Forgets the relay jar on this device. Deleting it on the relay itself
  /// (network DELETE) is the caller's job.
  Future<void> clearRelayJar() async {
    final accountId = state.accountId;
    await ref.read(secureStoreProvider).deleteRelaySecret(accountId);
    await ref.read(localStoreProvider).clearRelayJar(accountId);
    await ref.read(localStoreProvider).clearRelayLinkReplaced(accountId);
    ref.read(relayLinkNoticeProvider.notifier).refresh();
    if (state.accountId != accountId) return;
    state = state.copyWith(relayJar: null, relaySecret: null);
  }

  /// Persists a replacement jar minted by the keep-alive when the old one was
  /// gone (404) or its secret was stale (401), for [accountId] (which may not
  /// be the active band). Records the old donate URL so the artist is told to
  /// reprint, and updates live state when it's the active band's jar.
  Future<void> adoptRelinkedJar(
    String accountId,
    RelayJar jar,
    String secret,
    String oldDonateUrl,
  ) async {
    await ref.read(secureStoreProvider).writeRelaySecret(accountId, secret);
    await ref.read(localStoreProvider).saveRelayJar(accountId, jar);
    await ref
        .read(localStoreProvider)
        .writeRelayLinkReplaced(accountId, oldDonateUrl);
    ref.read(relayLinkNoticeProvider.notifier).refresh();
    if (state.accountId == accountId) {
      state = state.copyWith(relayJar: jar, relaySecret: secret);
    }
  }

  /// Dismisses the "your tip page link changed, please reprint" notice.
  Future<void> dismissRelayLinkNotice() async {
    final accountId = state.accountId;
    await ref.read(localStoreProvider).clearRelayLinkReplaced(accountId);
    ref.read(relayLinkNoticeProvider.notifier).refresh();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await ref.read(localStoreProvider).saveSettings(settings);
    state = state.copyWith(settings: settings);
  }

  /// Persists the active band's own preferences (QR mode, goal, poster).
  Future<void> updateBand(BandSettings band) async {
    final accountId = state.accountId;
    await ref.read(localStoreProvider).saveBandSettings(accountId, band);
    if (state.accountId != accountId) return;
    state = state.copyWith(band: band);
  }

  /// Renames the active band everywhere local: the registry (the switcher's
  /// label) and both jars' embedded names. Pushing the new name to the relay
  /// stays the caller's job (best effort, needs the network).
  Future<void> renameBand(String name) async {
    final accountId = state.accountId;
    final local = ref.read(localStoreProvider);
    await _renameInRegistry(accountId, name);
    final tipJar = state.tipJar;
    final relayJar = state.relayJar;
    if (tipJar != null) {
      await local.saveTipJar(accountId, tipJar.copyWith(displayName: name));
    }
    if (relayJar != null) {
      await local.saveRelayJar(
          accountId, relayJar.copyWith(artistName: name));
    }
    if (state.accountId != accountId) return;
    state = state.copyWith(
      tipJar: tipJar?.copyWith(displayName: name),
      relayJar: relayJar?.copyWith(artistName: name),
      accounts: _registry.withRenamed(accountId, name).accounts,
    );
  }

  Future<void> _renameInRegistry(String accountId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final renamed = _registry.withRenamed(accountId, trimmed);
    await ref.read(localStoreProvider).saveAccountsRegistry(renamed);
    state = state.copyWith(accounts: renamed.accounts);
  }

  /// Whether bands can be switched/added/removed right now. A running
  /// session is bound to its band's key, payment link, and relay socket —
  /// the app must never show band B around band A's live numbers.
  bool get accountActionsBlocked =>
      state.switching || ref.read(liveSessionProvider) != null;

  /// Makes [id] the active band. Returns false when refused (unknown id,
  /// mid-switch, or a live session running). Exits demo mode — switching is
  /// an explicit "work with this band now".
  Future<bool> switchAccount(String id) async {
    if (state.switching) return false;
    if (id == state.accountId) {
      // "Switch to the band I'm already on" while playing with demo mode
      // means "back to the real thing".
      if (state.demo) exitDemo();
      return true;
    }
    if (!_registry.contains(id)) return false;
    if (ref.read(liveSessionProvider) != null) return false;

    final previousId = state.accountId;
    state = state.copyWith(switching: true);
    // A stale onboarding draft must never leak across bands — it would
    // hijack the next band's setup flow with this band's method choices.
    ref.read(onboardingDraftProvider.notifier).clear();

    final local = ref.read(localStoreProvider);
    final secure = ref.read(secureStoreProvider);
    String? apiKey;
    String? relaySecret;
    var keychainOk = true;
    try {
      apiKey = await secure.readApiKey(id);
      relaySecret = await secure.readRelaySecret(id);
    } catch (_) {
      // Locked/prompting keychain: the band opens signed-out this once,
      // exactly like a failed boot read. Its data is untouched.
      keychainOk = false;
    }

    // The guard ran before the awaits — re-check nothing slipped in.
    if (ref.read(liveSessionProvider) != null) {
      state = state.copyWith(switching: false);
      return false;
    }

    await local.saveAccountsRegistry(_registry.withActive(id));
    state = AppState(
      accountId: id,
      accounts: state.accounts,
      apiKey: apiKey,
      tipJar: local.readTipJar(id),
      relayJar: local.readRelayJar(id),
      relaySecret: relaySecret,
      settings: state.settings,
      band: local.readBandSettings(id),
    );
    if (keychainOk) {
      await _maybeCollectAbandoned(previousId);
    }
    return true;
  }

  /// Creates a fresh unnamed band and makes it active — the caller sends the
  /// user into onboarding (method select). Returns null when refused.
  Future<BandAccount?> addAccount() async {
    if (accountActionsBlocked) return null;
    final account = BandAccount(
      id: BandAccount.newId(),
      name: '',
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    final registry = _registry.withAccount(account).withActive(account.id);
    await ref.read(localStoreProvider).saveAccountsRegistry(registry);
    ref.read(onboardingDraftProvider.notifier).clear();
    state = AppState(
      accountId: account.id,
      accounts: registry.accounts,
      settings: state.settings,
    );
    return account;
  }

  /// Deletes [id]'s local data and secrets (and, best effort, its relay jar
  /// on the server), then activates the first remaining band — or a fresh
  /// empty one when it was the last. Refused during a live session.
  Future<bool> removeAccount(String id) async {
    if (accountActionsBlocked) return false;
    if (!_registry.contains(id)) return false;
    state = state.copyWith(switching: true);
    ref.read(onboardingDraftProvider.notifier).clear();

    final local = ref.read(localStoreProvider);
    final secure = ref.read(secureStoreProvider);

    // Best effort: retire the band's connected-mode jar on the relay so the
    // public donor page dies with the local copy. Failures are ignored —
    // the removal must succeed even offline.
    final jar = local.readRelayJar(id);
    String? secret;
    if (id == state.accountId) {
      secret = state.relaySecret;
    } else {
      try {
        secret = await secure.readRelaySecret(id);
      } catch (_) {}
    }
    if (jar != null && secret != null) {
      final client = RelayClient();
      try {
        await client.deleteJar(jarId: jar.jarId, secret: secret);
      } catch (_) {
        // Offline, already gone, or a rotated secret — nothing more to do.
      } finally {
        client.close();
      }
    }

    var registry = _registry.withoutAccount(id);
    if (registry.accounts.isEmpty) {
      final fresh = BandAccount(
        id: BandAccount.newId(),
        name: '',
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      registry =
          AccountsRegistry(accounts: [fresh], activeId: fresh.id);
    }

    // Load the successor BEFORE wiping, so the UI lands on coherent state.
    final successorId = id == state.accountId
        ? registry.accounts.first.id
        : state.accountId;
    String? apiKey;
    String? relaySecret;
    if (successorId == state.accountId) {
      apiKey = state.apiKey;
      relaySecret = state.relaySecret;
    } else {
      try {
        apiKey = await secure.readApiKey(successorId);
        relaySecret = await secure.readRelaySecret(successorId);
      } catch (_) {}
    }
    await local.saveAccountsRegistry(registry.withActive(successorId));
    state = AppState(
      accountId: successorId,
      accounts: registry.accounts,
      apiKey: apiKey,
      tipJar: local.readTipJar(successorId),
      relayJar: local.readRelayJar(successorId),
      relaySecret: relaySecret,
      settings: state.settings,
      band: local.readBandSettings(successorId),
    );

    await local.wipeAccount(id);
    try {
      await secure.wipeAccount(id);
    } catch (_) {
      // A locked keychain leaves the secrets behind — tombstone them so
      // the boot-time retry deletes them once the keychain cooperates.
      await local.addPendingSecretWipe(id);
    }
    ref.invalidate(relayHistoryProvider);
    return true;
  }

  /// Backs out of Stripe setup for the active band: removes only the just-
  /// connected API key, leaving jars, history, and other bands untouched.
  /// RootGate then falls back to the shell (relay-only band) or welcome.
  Future<void> cancelStripeSetup() async {
    final accountId = state.accountId;
    try {
      await ref.read(secureStoreProvider).deleteApiKey(accountId);
    } catch (_) {
      // Locked keychain: the in-memory key still goes away this session;
      // the next boot re-reads the entry and the user can cancel again.
    }
    if (state.accountId != accountId) return;
    state = state.copyWith(apiKey: null);
  }

  /// Disconnects Stripe from the active band: forgets the API key and the tip
  /// jar on this device, leaving relay methods, history, and other bands
  /// intact. The artist's Stripe account and past payments are untouched —
  /// deactivating the old payment link and dropping it from the relay donor
  /// page is the caller's job (best effort, needs the network).
  Future<void> disconnectStripe() async {
    final accountId = state.accountId;
    try {
      await ref.read(secureStoreProvider).deleteApiKey(accountId);
    } catch (_) {
      // Locked keychain: the in-memory key still goes away this session; the
      // next boot re-reads the entry and the user can disconnect again.
    }
    await ref.read(localStoreProvider).clearTipJar(accountId);
    if (state.accountId != accountId) return;
    state = state.copyWith(apiKey: null, tipJar: null);
  }

  /// Drops a band the user walked away from without ever configuring:
  /// no name, no local data, and (confirmed, not just unloaded) no secrets.
  /// Any doubt — a keychain error, one leftover key — keeps the band.
  Future<void> _maybeCollectAbandoned(String id) async {
    final registry = _registry;
    if (!registry.contains(id) || registry.accounts.length < 2) return;
    if (registry.accounts
        .firstWhere((a) => a.id == id)
        .name
        .trim()
        .isNotEmpty) {
      return;
    }
    final local = ref.read(localStoreProvider);
    if (local.accountHasData(id)) return;
    try {
      final secure = ref.read(secureStoreProvider);
      if (await secure.readApiKey(id) != null) return;
      if (await secure.readRelaySecret(id) != null) return;
    } catch (_) {
      return;
    }
    // Prune from the registry as it is NOW — the keychain awaits above are
    // wide enough for another add/switch to have changed it, and saving a
    // stale snapshot would clobber their entries.
    final current = _registry;
    if (!current.contains(id) ||
        current.activeId == id ||
        current.accounts.length < 2) {
      return;
    }
    final pruned = current.withoutAccount(id);
    await local.saveAccountsRegistry(pruned);
    state = state.copyWith(accounts: pruned.accounts);
  }

  /// Removes the active band and every local trace of it. Kept as the
  /// last-band form of [removeAccount] for the settings screen.
  Future<void> disconnect() => removeAccount(state.accountId);
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

/// The device-local archive of tip-page (Revolut/MobilePay) tips for the
/// ACTIVE band, newest first. This device is the only witness to these tips
/// — the Stripe API never sees them — so every list that mixes them in
/// reads this. Mirrors StoredSessionNotifier: SharedPreferences can't
/// notify, so the session controller refreshes this explicitly after each
/// write; watching the account id rebuilds it on every band switch.
class RelayHistoryNotifier extends Notifier<List<Donation>> {
  @override
  List<Donation> build() {
    final accountId =
        ref.watch(appStateProvider.select((s) => s.accountId));
    return ref.read(localStoreProvider).readRelayHistory(accountId);
  }

  void refresh() => state = ref
      .read(localStoreProvider)
      .readRelayHistory(ref.read(appStateProvider).accountId);
}

final relayHistoryProvider =
    NotifierProvider<RelayHistoryNotifier, List<Donation>>(
        RelayHistoryNotifier.new);

/// Exchange rates for totalling a set that mixed currencies (a £5 Monzo tip
/// alongside €10 Revolut ones). Serves the cached table immediately — the
/// stage must never block on the network — and refreshes it in the background
/// when it's missing or stale. A failed refresh is a no-op: the last good table
/// stands, and with none at all the session declines to count foreign tips
/// rather than guess. See [FxRates].
class FxRatesNotifier extends Notifier<FxRates?> {
  @override
  FxRates? build() {
    final cached = ref.read(localStoreProvider).readFxRates();
    if (cached == null || cached.isStaleAt(DateTime.now())) {
      unawaited(refresh());
    }
    return cached;
  }

  Future<void> refresh() async {
    final source = FxSource();
    try {
      final fresh = await source.fetch();
      await ref.read(localStoreProvider).saveFxRates(fresh);
      state = fresh;
    } catch (_) {
      // Offline, rate-limited, or the service moved — keep whatever we have.
    } finally {
      source.close();
    }
  }
}

final fxRatesProvider =
    NotifierProvider<FxRatesNotifier, FxRates?>(FxRatesNotifier.new);

/// The old donate URL of the active band's auto-replaced tip page, or null
/// when there's nothing to warn about. Home shows a "please reprint" card
/// while this is set; [AppStateNotifier.dismissRelayLinkNotice] clears it.
class RelayLinkNoticeNotifier extends Notifier<String?> {
  @override
  String? build() {
    final accountId =
        ref.watch(appStateProvider.select((s) => s.accountId));
    return ref.read(localStoreProvider).readRelayLinkReplaced(accountId);
  }

  void refresh() => state = ref
      .read(localStoreProvider)
      .readRelayLinkReplaced(ref.read(appStateProvider).accountId);
}

final relayLinkNoticeProvider =
    NotifierProvider<RelayLinkNoticeNotifier, String?>(
        RelayLinkNoticeNotifier.new);
