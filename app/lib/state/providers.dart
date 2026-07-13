import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tip_source.dart';
import '../data/fx_source.dart';
import '../data/local_store.dart';
import '../data/relay/relay_client.dart';
import '../data/relay/relay_config.dart';
import '../data/relay/relay_tip_channel.dart';
import '../data/repository/account_data_repository.dart';
import '../data/repository/firestore_repository.dart';
import '../data/secure_store.dart';
import '../domain/app_account.dart';
import 'auth_providers.dart';
import '../data/stripe/stripe_client.dart';
import '../data/stripe/stripe_requests.dart';
import '../domain/app_settings.dart';
import '../domain/band_account.dart';
import '../domain/band_settings.dart';
import '../domain/tip.dart';
import '../domain/fx_rates.dart';
import '../domain/relay_jar.dart';
import '../domain/tip_jar.dart';
import 'cloud_session_coordinator.dart';
import 'live_session_controller.dart';
import 'onboarding_draft.dart';
import 'session_coordinator.dart';

/// Overridden in main() with initialized instances.
final localStoreProvider =
    Provider<LocalStore>((ref) => throw UnimplementedError());
final secureStoreProvider =
    Provider<SecureStore>((ref) => throw UnimplementedError());

/// Bumped by the cloud repository on every remote snapshot that changed a
/// mirror — everything serving sync reads from those mirrors re-reads when
/// this moves. The local repository never bumps it.
class RepoRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final repoRevisionProvider =
    NotifierProvider<RepoRevisionNotifier, int>(RepoRevisionNotifier.new);

/// The active profile's data home: the local profile reads the prefs +
/// keychain stores; a signed-in profile reads its Firestore subtree —
/// but only while the signed-in Firebase user IS that profile (a signed-out
/// or mismatched session falls back to local rather than showing someone
/// else's cache). Device-wide plumbing that is local by design — the fx
/// cache, pending secret wipes, boot migrations — stays on
/// [localStoreProvider].
final accountDataRepositoryProvider = Provider<AccountDataRepository>((ref) {
  final local = ref.watch(localStoreProvider);
  final activeProfile = ref
      .watch(accountsDirectoryProvider.select((d) => d.activeAccountId));
  final db = ref.watch(firestoreProvider);
  final signedInUid =
      ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (activeProfile != kLocalAccountId &&
      db != null &&
      signedInUid == activeProfile) {
    final repo = FirestoreRepository(
      uid: activeProfile,
      db: db,
      local: local,
      resolveSecure: () => ref.read(secureStoreProvider),
      onChanged: () => ref.read(repoRevisionProvider.notifier).bump(),
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return LocalStoreRepository(local, () => ref.read(secureStoreProvider));
});

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
  /// connected-mode fan page, per [effectiveQrMode]. Null only when
  /// nothing is configured at all.
  String? get activeQrUrl => effectiveQrMode == QrMode.connected
      ? effectiveRelayJar?.tipUrl
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
    // Profile switches (directory) and remote snapshots (cloud revision)
    // arrive as listens, not watches: a watch would rebuild the notifier
    // and wipe in-flight switching state.
    ref.listen(
        accountsDirectoryProvider.select((d) => d.activeAccountId),
        (previous, next) {
      if (previous != null && previous != next) {
        unawaited(_reloadForProfile());
      }
    });
    ref.listen(repoRevisionProvider, (previous, next) => _onRemoteChange());
    final repo = ref.read(accountDataRepositoryProvider);
    // main() migrates/creates the registry before runApp; the fallback here
    // covers tests that wire a bare store straight into the ProviderScope.
    var accounts = repo.listBands();
    if (accounts.isEmpty) {
      final account = BandAccount(
        id: BandAccount.newId(),
        name: '',
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      accounts = [account];
      repo.upsertBandEntry(account); // fire-and-forget
    }
    final activeId = repo.readActiveBandId();
    final accountId =
        accounts.any((a) => a.id == activeId) ? activeId! : accounts.first.id;
    // Booting straight into a cloud profile: main() read the keychain for
    // the LOCAL registry's band, not this one — fetch the right secrets as
    // soon as the first frame is out.
    if (!ref.read(accountsDirectoryProvider).active.isLocal) {
      unawaited(_refreshSecrets(accountId));
    }
    return AppState(
      accountId: accountId,
      accounts: accounts,
      apiKey: ref.read(initialApiKeyProvider),
      tipJar: repo.readTipJar(accountId),
      relayJar: repo.readRelayJar(accountId),
      relaySecret: ref.read(initialRelaySecretProvider),
      settings: repo.readSettings(),
      band: repo.readBandSettings(accountId),
    );
  }

  /// Reloads everything for the (already switched) active profile — the
  /// directory listener calls this after a sign-in or a profile switch.
  Future<void> _reloadForProfile() async {
    if (ref.read(liveSessionProvider) != null) return; // never yank a live set
    state = state.copyWith(switching: true);
    ref.read(onboardingDraftProvider.notifier).clear();
    final repo = ref.read(accountDataRepositoryProvider);
    var accounts = repo.listBands();
    if (accounts.isEmpty) {
      // Fresh profile — or a cloud mirror that hasn't warmed yet. The band
      // exists in memory only; its doc materializes on the first real write,
      // and if synced bands arrive a moment later, _onRemoteChange drops
      // this placeholder for them.
      accounts = [
        BandAccount(
          id: BandAccount.newId(),
          name: '',
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      ];
    }
    final storedActive = repo.readActiveBandId();
    final accountId = accounts.any((a) => a.id == storedActive)
        ? storedActive!
        : accounts.first.id;
    String? apiKey;
    String? relaySecret;
    try {
      apiKey = await repo.readApiKey(accountId);
      relaySecret = await repo.readRelaySecret(accountId);
    } catch (_) {
      // Locked keychain — the profile opens signed-out this once.
    }
    state = AppState(
      accountId: accountId,
      accounts: accounts,
      apiKey: apiKey,
      tipJar: repo.readTipJar(accountId),
      relayJar: repo.readRelayJar(accountId),
      relaySecret: relaySecret,
      settings: repo.readSettings(),
      band: repo.readBandSettings(accountId),
    );
    // The history/stored-session notifiers watch the band id and the cloud
    // revision themselves — pushing refreshes at them from here would make
    // them depend on this notifier that already depends on them.
  }

  /// A cloud snapshot moved a mirror: fold the fresh reads into state.
  void _onRemoteChange() {
    // Mid-set the session owns the stage; the archives refresh on their own.
    if (ref.read(liveSessionProvider) != null) return;
    final repo = ref.read(accountDataRepositoryProvider);
    final accounts = repo.listBands();
    if (accounts.isEmpty) return; // mirror not warm yet
    final accountId = state.accountId;
    if (!accounts.any((a) => a.id == accountId)) {
      // The active band vanished remotely (deleted on another device), or
      // we sat on a cold-mirror placeholder — land on a real band.
      unawaited(_reloadForProfile());
      return;
    }
    state = state.copyWith(
      accounts: accounts,
      tipJar: repo.readTipJar(accountId),
      relayJar: repo.readRelayJar(accountId),
      band: repo.readBandSettings(accountId),
      settings: repo.readSettings(),
    );
    // A key synced from another device shows up without a re-entry.
    unawaited(_refreshSecrets(accountId));
  }

  Future<void> _refreshSecrets(String accountId) async {
    final repo = ref.read(accountDataRepositoryProvider);
    try {
      final apiKey = await repo.readApiKey(accountId);
      final relaySecret = await repo.readRelaySecret(accountId);
      if (state.accountId != accountId) return;
      if (apiKey != state.apiKey || relaySecret != state.relaySecret) {
        state = state.copyWith(apiKey: apiKey, relaySecret: relaySecret);
      }
    } catch (_) {
      // Locked keychain — the next remote change retries.
    }
  }

  AccountsRegistry get _registry =>
      AccountsRegistry(accounts: state.accounts, activeId: state.accountId);

  Future<void> connect(String apiKey) async {
    final accountId = state.accountId;
    final trimmed = apiKey.trim();
    final repo = ref.read(accountDataRepositoryProvider);
    await repo.writeApiKey(accountId, trimmed);
    // A newly connected account must not inherit demo/test tips from earlier
    // play — otherwise its history shows tips that never happened.
    await repo.purgeSimulatedData(accountId);
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
    await ref.read(accountDataRepositoryProvider).saveTipJar(accountId, jar);
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
    final repo = ref.read(accountDataRepositoryProvider);
    await repo.writeRelaySecret(accountId, secret);
    await repo.saveRelayJar(accountId, jar);
    await repo.purgeSimulatedData(accountId);
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
    await ref
        .read(accountDataRepositoryProvider)
        .saveRelayJar(accountId, jar);
    if (state.accountId != accountId) return;
    state = state.copyWith(relayJar: jar);
  }

  /// Forgets the relay jar on this device. Deleting it on the relay itself
  /// (network DELETE) is the caller's job.
  Future<void> clearRelayJar() async {
    final accountId = state.accountId;
    final repo = ref.read(accountDataRepositoryProvider);
    await repo.deleteRelaySecret(accountId);
    await repo.clearRelayJar(accountId);
    await repo.clearRelayLinkReplaced(accountId);
    ref.read(relayLinkNoticeProvider.notifier).refresh();
    if (state.accountId != accountId) return;
    state = state.copyWith(relayJar: null, relaySecret: null);
  }

  /// Persists a replacement jar minted by the keep-alive when the old one was
  /// gone (404) or its secret was stale (401), for [accountId] (which may not
  /// be the active band). Records the old tip URL so the artist is told to
  /// reprint, and updates live state when it's the active band's jar.
  Future<void> adoptRelinkedJar(
    String accountId,
    RelayJar jar,
    String secret,
    String oldTipUrl,
  ) async {
    final repo = ref.read(accountDataRepositoryProvider);
    await repo.writeRelaySecret(accountId, secret);
    await repo.saveRelayJar(accountId, jar);
    await repo.writeRelayLinkReplaced(accountId, oldTipUrl);
    ref.read(relayLinkNoticeProvider.notifier).refresh();
    if (state.accountId == accountId) {
      state = state.copyWith(relayJar: jar, relaySecret: secret);
    }
  }

  /// Dismisses the "your tip page link changed, please reprint" notice.
  Future<void> dismissRelayLinkNotice() async {
    final accountId = state.accountId;
    await ref
        .read(accountDataRepositoryProvider)
        .clearRelayLinkReplaced(accountId);
    ref.read(relayLinkNoticeProvider.notifier).refresh();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await ref.read(accountDataRepositoryProvider).saveSettings(settings);
    state = state.copyWith(settings: settings);
  }

  /// Persists the active band's own preferences (QR mode, goal, poster).
  Future<void> updateBand(BandSettings band) async {
    final accountId = state.accountId;
    await ref
        .read(accountDataRepositoryProvider)
        .saveBandSettings(accountId, band);
    if (state.accountId != accountId) return;
    state = state.copyWith(band: band);
  }

  /// Renames the active band everywhere local: the registry (the switcher's
  /// label) and both jars' embedded names. Pushing the new name to the relay
  /// stays the caller's job (best effort, needs the network).
  Future<void> renameBand(String name) async {
    final accountId = state.accountId;
    final repo = ref.read(accountDataRepositoryProvider);
    await _renameInRegistry(accountId, name);
    final tipJar = state.tipJar;
    final relayJar = state.relayJar;
    if (tipJar != null) {
      await repo.saveTipJar(accountId, tipJar.copyWith(displayName: name));
    }
    if (relayJar != null) {
      await repo.saveRelayJar(
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
    final entry =
        renamed.accounts.where((a) => a.id == accountId).firstOrNull;
    if (entry == null) return;
    await ref.read(accountDataRepositoryProvider).upsertBandEntry(entry);
    state = state.copyWith(accounts: renamed.accounts);
  }

  /// Whether bands can be switched/added/removed right now. A running
  /// session is bound to its band's key, payment link, and relay socket —
  /// the app must never show band B around band A's live numbers. On a
  /// cloud profile a session running on ANY device blocks too: the account
  /// is live somewhere, and reshuffling bands under it invites exactly the
  /// cross-band leaks the local guard exists to prevent.
  bool get accountActionsBlocked {
    if (state.switching || ref.read(liveSessionProvider) != null) return true;
    try {
      return ref.read(activeSessionProvider).value?.active ?? false;
    } catch (_) {
      // Unwired in tests / provider errored — the local guards stand alone.
      return false;
    }
  }

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

    final repo = ref.read(accountDataRepositoryProvider);
    String? apiKey;
    String? relaySecret;
    var keychainOk = true;
    try {
      apiKey = await repo.readApiKey(id);
      relaySecret = await repo.readRelaySecret(id);
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

    await repo.saveActiveBandId(id);
    state = AppState(
      accountId: id,
      accounts: state.accounts,
      apiKey: apiKey,
      tipJar: repo.readTipJar(id),
      relayJar: repo.readRelayJar(id),
      relaySecret: relaySecret,
      settings: state.settings,
      band: repo.readBandSettings(id),
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
    final repo = ref.read(accountDataRepositoryProvider);
    await repo.upsertBandEntry(account);
    await repo.saveActiveBandId(account.id);
    ref.read(onboardingDraftProvider.notifier).clear();
    state = AppState(
      accountId: account.id,
      accounts: [...state.accounts, account],
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

    final repo = ref.read(accountDataRepositoryProvider);

    // Best effort: retire the band's connected-mode jar on the relay so the
    // public fan page dies with the local copy. Failures are ignored —
    // the removal must succeed even offline.
    final jar = repo.readRelayJar(id);
    String? secret;
    if (id == state.accountId) {
      secret = state.relaySecret;
    } else {
      try {
        secret = await repo.readRelaySecret(id);
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

    // Subtree first, band entry second: the cloud repository enumerates a
    // band's session/tip/secret docs by its collections, and deleting the
    // band doc first would leave the wipe nothing to hang the query on.
    await repo.wipeAccountData(id);
    var registry = _registry.withoutAccount(id);
    await repo.removeBandEntry(id);
    if (registry.accounts.isEmpty) {
      final fresh = BandAccount(
        id: BandAccount.newId(),
        name: '',
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      registry =
          AccountsRegistry(accounts: [fresh], activeId: fresh.id);
      await repo.upsertBandEntry(fresh);
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
        apiKey = await repo.readApiKey(successorId);
        relaySecret = await repo.readRelaySecret(successorId);
      } catch (_) {}
    }
    await repo.saveActiveBandId(successorId);
    state = AppState(
      accountId: successorId,
      accounts: registry.accounts,
      apiKey: apiKey,
      tipJar: repo.readTipJar(successorId),
      relayJar: repo.readRelayJar(successorId),
      relaySecret: relaySecret,
      settings: state.settings,
      band: repo.readBandSettings(successorId),
    );

    try {
      await repo.wipeAccountSecrets(id);
    } catch (_) {
      // A locked keychain leaves the secrets behind — tombstone them so
      // the boot-time retry deletes them once the keychain cooperates.
      await ref.read(localStoreProvider).addPendingSecretWipe(id);
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
      await ref.read(accountDataRepositoryProvider).deleteApiKey(accountId);
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
  /// deactivating the old payment link and dropping it from the relay fan
  /// page is the caller's job (best effort, needs the network).
  Future<void> disconnectStripe() async {
    final accountId = state.accountId;
    final repo = ref.read(accountDataRepositoryProvider);
    try {
      await repo.deleteApiKey(accountId);
    } catch (_) {
      // Locked keychain: the in-memory key still goes away this session; the
      // next boot re-reads the entry and the user can disconnect again.
    }
    await repo.clearTipJar(accountId);
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
    final repo = ref.read(accountDataRepositoryProvider);
    if (repo.accountHasData(id)) return;
    try {
      if (await repo.readApiKey(id) != null) return;
      if (await repo.readRelaySecret(id) != null) return;
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
    await repo.removeBandEntry(id);
    state = state.copyWith(accounts: pruned.accounts);
  }

  /// Removes the active band and every local trace of it. Kept as the
  /// last-band form of [removeAccount] for the settings screen.
  Future<void> disconnect() => removeAccount(state.accountId);
}

final appStateProvider =
    NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

/// Builds the tip feed for a session — a seam so controller tests can
/// inject a scripted source instead of the demo/Stripe pollers. The Stripe
/// source constructs and OWNS its HTTP client (closed in dispose): sharing
/// [stripeRequestsProvider]'s client killed every session — any AppState
/// change rebuilt the provider and closed the client mid-poll.
typedef TipSourceFactory = TipSource Function({
  required bool demo,
  required String? apiKey,
  required TipJar? jar,
});

final tipSourceFactoryProvider = Provider<TipSourceFactory>(
  (ref) => ({required demo, required apiKey, required jar}) {
    if (demo) return DemoTipSource();
    // No Stripe key or no real payment link (relay-only installs): a live
    // session must NEVER pour fake tips, so poll a silent no-op source.
    // Relay tips arrive over their own channel, wired in a later step.
    if (apiKey == null || jar == null || jar.isDemo) {
      return NullTipSource();
    }
    final client = StripeClient(apiKey);
    return StripeTipSource(
      StripeRequests(client),
      paymentLinkId: jar.paymentLinkId,
      onDispose: client.close,
    );
  },
);

/// Builds the relay push tip feed for a session — a seam mirroring
/// [tipSourceFactoryProvider] so controller tests can hand in a fake
/// channel. Null means "this session has no relay feed": demo sessions
/// synthesize their tips, and without a jar + secret there is nothing to
/// authenticate against.
typedef RelayChannelFactory = TipChannel? Function({
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

/// Stable per-device id for multi-device session coordination (who leads,
/// whose lease it is). A provider so two "devices" in one test process can
/// disagree; the default persists once in prefs.
final deviceIdProvider =
    Provider<String>((ref) => ref.watch(localStoreProvider).deviceId());

/// Builds the coordination/transport layer for one session — a seam
/// mirroring [tipSourceFactoryProvider] so tests can hand in a fake. The
/// default picks the cloud coordinator when the active profile is a
/// signed-in cloud account with Firestore wired, else the local one —
/// exactly today's single-device behavior.
typedef SessionCoordinatorFactory = SessionCoordinator Function(
    SessionEvents events);

final sessionCoordinatorFactoryProvider =
    Provider<SessionCoordinatorFactory>((ref) => (events) {
      final app = ref.read(appStateProvider);
      final repo = ref.read(accountDataRepositoryProvider);
      // No tip jar is fine (relay-only): the factory returns a silent
      // source. Null relay means "this session has no push feed".
      final source = ref.read(tipSourceFactoryProvider)(
          demo: app.demo, apiKey: app.apiKey, jar: app.effectiveTipJar);
      final relay = ref.read(relayChannelFactoryProvider)(
          demo: app.demo, jar: app.effectiveRelayJar, secret: app.relaySecret);
      final profile = ref.read(accountsDirectoryProvider).active;
      final db = ref.read(firestoreProvider);
      final uid = ref.read(authControllerProvider).user?.uid;
      if (!profile.isLocal && db != null && uid == profile.id) {
        return CloudSessionCoordinator(
          db: db,
          uid: uid!,
          bandId: app.accountId,
          deviceId: ref.read(deviceIdProvider),
          repository: repo,
          source: source,
          relay: relay,
          // Leadership needs the band's Stripe key to poll with; without
          // one this device can only ever follow.
          canLead: app.apiKey != null,
          pollIntervalSec: app.settings.pollIntervalSec,
          events: events,
        );
      }
      return LocalSessionCoordinator(
        accountId: app.accountId,
        repository: repo,
        source: source,
        relay: relay,
        pollIntervalSec: app.settings.pollIntervalSec,
        events: events,
      );
    });

/// The account's `users/{uid}/live/current` coordination doc, live — what
/// the Join banner and the account-action guards watch. Null in local mode
/// (no Firestore snapshots are ever requested for the local profile), when
/// signed out, or while the doc doesn't exist.
final activeSessionProvider = StreamProvider<ActiveSessionInfo?>((ref) {
  final profileId = ref
      .watch(accountsDirectoryProvider.select((d) => d.activeAccountId));
  final db = ref.watch(firestoreProvider);
  final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (profileId == kLocalAccountId || db == null || uid != profileId) {
    return Stream<ActiveSessionInfo?>.value(null);
  }
  return db
      .doc('users/$profileId/live/current')
      .snapshots()
      .map((snap) => ActiveSessionInfo.fromData(snap.data()));
});

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

/// Small preview of latest tips for the home screen.
final recentTipsProvider =
    FutureProvider.autoDispose<List<Tip>>((ref) async {
  final requests = ref.watch(stripeRequestsProvider);
  final jar = ref.watch(appStateProvider).effectiveTipJar;
  if (requests == null || jar == null || jar.isDemo) return const [];
  final page = await requests.listTips(limit: 5);
  return page.tips;
});

/// The device-local archive of tip-page (Revolut/MobilePay) tips for the
/// ACTIVE band, newest first. This device is the only witness to these tips
/// — the Stripe API never sees them — so every list that mixes them in
/// reads this. Mirrors StoredSessionNotifier: SharedPreferences can't
/// notify, so the session controller refreshes this explicitly after each
/// write; watching the account id rebuilds it on every band switch.
class RelayHistoryNotifier extends Notifier<List<Tip>> {
  @override
  List<Tip> build() {
    final accountId =
        ref.watch(appStateProvider.select((s) => s.accountId));
    // A cloud snapshot (another device's tip) lands as a revision bump.
    ref.watch(repoRevisionProvider);
    return ref.read(accountDataRepositoryProvider).readRelayHistory(accountId);
  }

  void refresh() => state = ref
      .read(accountDataRepositoryProvider)
      .readRelayHistory(ref.read(appStateProvider).accountId);
}

final relayHistoryProvider =
    NotifierProvider<RelayHistoryNotifier, List<Tip>>(
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
    // Never leave the stage with no table at all: a first run with no network
    // still gets the compiled-in rates, so a foreign tip counts (approximately)
    // instead of being dropped from the night's total. A real cached table
    // always wins over them.
    return cached ?? FxRates.builtin();
  }

  /// Walks the provider chain. A total failure is not an error state — the
  /// cached (or built-in) table simply stands until the next attempt.
  Future<void> refresh() async {
    final source = FxSource();
    try {
      final fresh = await source.fetch();
      // Only a fetched table is ever written back; the built-in one must never
      // be cached over a real one, or it would look like a successful fetch.
      await ref.read(localStoreProvider).saveFxRates(fresh);
      state = fresh;
    } catch (_) {
      // Every provider is down, or we're offline. Keep what we have.
    } finally {
      source.close();
    }
  }
}

final fxRatesProvider =
    NotifierProvider<FxRatesNotifier, FxRates?>(FxRatesNotifier.new);

/// The old tip URL of the active band's auto-replaced tip page, or null
/// when there's nothing to warn about. Home shows a "please reprint" card
/// while this is set; [AppStateNotifier.dismissRelayLinkNotice] clears it.
class RelayLinkNoticeNotifier extends Notifier<String?> {
  @override
  String? build() {
    final accountId =
        ref.watch(appStateProvider.select((s) => s.accountId));
    return ref
        .read(accountDataRepositoryProvider)
        .readRelayLinkReplaced(accountId);
  }

  void refresh() => state = ref
      .read(accountDataRepositoryProvider)
      .readRelayLinkReplaced(ref.read(appStateProvider).accountId);
}

final relayLinkNoticeProvider =
    NotifierProvider<RelayLinkNoticeNotifier, String?>(
        RelayLinkNoticeNotifier.new);
