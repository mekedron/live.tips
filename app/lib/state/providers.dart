import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tip_source.dart';
import '../data/fx_source.dart';
import '../data/local_store.dart';
import '../data/relay/firestore_tip_channel.dart';
import '../data/relay/relay_auth.dart';
import '../data/relay/relay_client.dart';
import '../data/tip_channel.dart';
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
import 'device_providers.dart';
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

/// Why an add/switch/remove was refused. A refusal must always be able to say
/// why: a button that silently does nothing is indistinguishable from a broken
/// one, and that is exactly how a stale session used to read.
enum AccountActionBlock {
  /// A band switch is loading its keychain secrets right now.
  switching,

  /// A session is running on THIS device.
  localSession,

  /// The account is live on another device (a fresh leader lease says so).
  remoteSession,
}

class AppStateNotifier extends Notifier<AppState> {
  /// A profile flip landed while a session was live and its reload was held
  /// (see [_reloadForProfile]) — the session-end listener in [build] runs it.
  bool _reloadHeld = false;

  @override
  AppState build() {
    // Profile switches (directory) and remote snapshots (cloud revision)
    // arrive as listens, not watches: a watch would rebuild the notifier
    // and wipe in-flight switching state.
    ref.listen(
        accountsDirectoryProvider.select((d) => d.activeAccountId),
        (previous, next) {
      if (previous != null && previous != next) {
        // A microtask, not a straight call: the repository provider is a
        // DEPENDENT of the directory, and reading it from inside this
        // notification still hands back the old profile's repository — which
        // is how a switch used to leave the whole app rendering the account
        // it had just left, until a reload.
        unawaited(Future.microtask(_reloadForProfile));
      }
    });
    ref.listen(repoRevisionProvider, (previous, next) => _onRemoteChange());
    final repo = ref.read(accountDataRepositoryProvider);
    // Nothing is created here, ever: an account with no bands has no bands,
    // and RootGate routes that state to the artist's own create-a-profile
    // step (see [ProfileRender]). The old seeding conjured a band on every
    // warm, empty read — and synced it, which undid a deletion made on
    // another device.
    final isLocal = ref.read(accountsDirectoryProvider).active.isLocal;
    final accounts = _bandsOf(repo);
    final accountId =
        _pickActive(accounts, repo.readActiveBandId(), ask: !isLocal);
    // Booting straight into a cloud profile: main() read the keychain for
    // the LOCAL registry's band, not this one — fetch the right secrets as
    // soon as the first frame is out.
    if (accountId.isNotEmpty && !isLocal) {
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

  /// The profiles [repo] can vouch for right now. A cold cloud mirror is
  /// SILENT, not empty — every caller sees no profiles and creates none,
  /// and [_onRemoteChange] adopts the real ones when the snapshot lands.
  static List<BandAccount> _bandsOf(AccountDataRepository repo) =>
      repo.isWarm ? repo.listBands() : const [];

  /// The band to open on — or NOTHING to open on, which is a real answer:
  /// empty means "nobody has said which band, and the app will not decide".
  ///
  /// One profile is not a choice, so it opens. Several are: [storedId] is
  /// only what THIS DEVICE last did with this profile, and "the first band"
  /// is arbitrary. On the artist's own device (the local profile) the stored
  /// id stands — the device IS the profile, and it has always been the one
  /// band the artist left open. A CLOUD account carries a whole shelf of
  /// gigs, and guessing among them opened the wrong QR, the wrong goal, and
  /// took tips into another band's history — so [ask] holds the answer open
  /// and RootGate lands on the picker, where the stored id merely
  /// PRE-SELECTS a row (see [ProfilePickScreen]).
  ///
  /// Empty is also what a cold mirror honestly has, and what an account with
  /// no profile yet has — neither is repaired with an invented band.
  static String _pickActive(
    List<BandAccount> accounts,
    String? storedId, {
    required bool ask,
  }) {
    if (accounts.isEmpty) return '';
    if (accounts.length == 1) return accounts.first.id;
    if (ask) return '';
    return accounts.any((a) => a.id == storedId)
        ? storedId!
        : accounts.first.id;
  }

  /// Whether the active profile's band question is the artist's to answer —
  /// true for every cloud account, false for the device's own local profile.
  bool get _askForBand =>
      !ref.read(accountsDirectoryProvider).active.isLocal;

  /// Reloads everything for the (already switched) active profile — the
  /// directory listener calls this after a sign-in or a profile switch.
  Future<void> _reloadForProfile() async {
    if (ref.read(liveSessionProvider) != null) {
      // Never yank a live set. But the flip is real and the directory
      // listener will not fire for it again — hold the reload, and the
      // session-end listener in build() runs it once the set is over.
      _reloadHeld = true;
      return;
    }
    _reloadHeld = false;
    state = state.copyWith(switching: true);
    ref.read(onboardingDraftProvider.notifier).clear();
    final repo = ref.read(accountDataRepositoryProvider);
    final ask = _askForBand;
    var accounts = _bandsOf(repo);
    // A profile with no bands has no bands — a fresh cloud account, or one
    // whose last profile was removed. Nothing is minted for it: RootGate
    // sends that state to the create-a-profile step. Several bands and no
    // stored answer is the OTHER open question — the picker asks it.
    var accountId = _pickActive(accounts, repo.readActiveBandId(), ask: ask);
    String? apiKey;
    String? relaySecret;
    if (accountId.isNotEmpty) {
      try {
        apiKey = await repo.readApiKey(accountId);
        relaySecret = await repo.readRelaySecret(accountId);
      } catch (_) {
        // Locked keychain — the profile opens signed-out this once.
      }
      // The keychain awaits are wide enough for the first cloud snapshot to
      // land: commit the band list as it is NOW, never the one read before.
      final fresh = _bandsOf(repo);
      if (fresh.isNotEmpty) {
        accounts = fresh;
        final landed = _pickActive(accounts, accountId, ask: ask);
        if (landed != accountId) {
          // Different band than the secrets above belong to — nobody must
          // ever see band A's key on band B; _refreshSecrets fetches B's.
          // Or no band at all: the snapshot brought several, the question is
          // the artist's, and a screen with no band holds no secrets either.
          accountId = landed;
          apiKey = null;
          relaySecret = null;
          if (landed.isNotEmpty) unawaited(_refreshSecrets(landed));
        }
      }
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

  /// The session just ended on this device: run the reload a live set held
  /// back (see [_reloadForProfile]), if any. Called by the session
  /// controller from stop() and _onRemoteEnded — the same push it already
  /// gives the stored-session and recent-tips providers, and for the same
  /// reason: listening to the session from here would be a circular
  /// dependency (the controller reads this notifier). The directory
  /// listener fires exactly ONCE per flip, so without this a flip that
  /// landed mid-session left the skipped reload skipped forever, and the
  /// app rendered the departed account until a restart.
  void onSessionEnded() {
    if (!_reloadHeld) return;
    // A microtask: the controller's stop() is still mid-flight here.
    unawaited(Future.microtask(_reloadForProfile));
  }

  /// A cloud snapshot moved a mirror: fold the fresh reads into state.
  void _onRemoteChange() {
    // Mid-set the session owns the stage; the archives refresh on their own.
    if (ref.read(liveSessionProvider) != null) return;
    final repo = ref.read(accountDataRepositoryProvider);
    if (!repo.isWarm) return; // silence — it says nothing about the bands
    final accounts = repo.listBands();
    final accountId = state.accountId;
    if (!accounts.any((a) => a.id == accountId)) {
      // The bands we were waiting for arrived (cold boot), the active one was
      // deleted on another device, or the account has none at all — reload
      // and land on whatever is really there, which may be nothing. Minting a
      // band here was the resurrection bug: the deletion the artist made on
      // their phone came straight back from the tablet's mirror.
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

  /// Why bands can't be switched/added/removed right now, or null when they
  /// can. A running session is bound to its band's key, payment link, and
  /// relay socket — the app must never show band B around band A's live
  /// numbers. On a cloud profile a session running on ANY device blocks too:
  /// the account is live somewhere, and reshuffling bands under it invites
  /// exactly the cross-band leaks the local guard exists to prevent.
  ///
  /// Every refusal names its reason, and add/switch/remove all ask THIS —
  /// three guards that disagreed is how a dead session used to lock the
  /// account out of its own switcher.
  AccountActionBlock? get accountActionBlock {
    if (state.switching) return AccountActionBlock.switching;
    return _sessionBlock;
  }

  bool get accountActionsBlocked => accountActionBlock != null;

  /// The session half of the guard, without the mid-switch flag — the only
  /// form usable from inside an action that has already set `switching`.
  AccountActionBlock? get _sessionBlock {
    if (ref.read(liveSessionProvider) != null) {
      return AccountActionBlock.localSession;
    }
    try {
      final info = ref.read(activeSessionProvider).value;
      // `active` never gets cleared by a crashed tab — only the lease decays.
      // Trusting the flag alone left the account blocked forever; the lease
      // is what CloudSessionCoordinator itself believes (it takes a stale one
      // over), so the guard must believe the same thing.
      if (info != null &&
          info.active &&
          CloudSessionCoordinator.leaseAlive(info.leaderLeaseUntilMs)) {
        return AccountActionBlock.remoteSession;
      }
    } catch (_) {
      // Unwired in tests / provider errored — the local guards stand alone.
    }
    return null;
  }

  /// One exception to the session guard, and only one: moving TO the band the
  /// account is already live on. That is what tapping Join on the banner does
  /// — the session is that band's, so following it can't show band B around
  /// band A's numbers. Every other move stays refused.
  bool _switchAllowedTo(String id) {
    final block = _sessionBlock;
    if (block == null) return true;
    if (block != AccountActionBlock.remoteSession) return false;
    try {
      return ref.read(activeSessionProvider).value?.bandId == id;
    } catch (_) {
      return false;
    }
  }

  /// Makes [id] the active band. Returns false when refused (unknown id,
  /// mid-switch, or a live session — here or on another device, unless [id]
  /// IS that session's band). Exits demo mode — switching is an explicit
  /// "work with this band now".
  Future<bool> switchAccount(String id) async {
    if (state.switching) return false;
    if (id == state.accountId) {
      // "Switch to the band I'm already on" while playing with demo mode
      // means "back to the real thing".
      if (state.demo) exitDemo();
      return true;
    }
    if (!_registry.contains(id)) return false;
    if (!_switchAllowedTo(id)) return false;

    final previousId = state.accountId;
    state = state.copyWith(switching: true);
    // A stale onboarding draft must never leak across bands — it would
    // hijack the next band's setup flow with this band's method choices.
    // The step-counter prelude goes with it: it belongs to the run.
    ref.read(onboardingDraftProvider.notifier).clear();
    ref.read(onboardingPreludeProvider.notifier).reset();

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
    if (!_switchAllowedTo(id)) {
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

  /// Writes a fresh unnamed band and makes it active. The ONE place a band
  /// entry is born, and its callers are the artist asking for a profile — the
  /// name they just typed into the first step ([createFirstBand], which is now
  /// every "Add a profile" / "Create a new profile" too), or Welcome seeding the
  /// device's first local band as onboarding begins ([addAccount]). An empty
  /// band list is never "repaired" by calling this.
  Future<BandAccount> _mintBand() async {
    final account = BandAccount(
      id: BandAccount.newId(),
      name: '',
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    final repo = ref.read(accountDataRepositoryProvider);
    await repo.upsertBandEntry(account);
    await repo.saveActiveBandId(account.id);
    return account;
  }

  /// Creates a fresh unnamed band and makes it active — Welcome's seed for the
  /// device's first local profile, as onboarding begins. Returns null when
  /// refused.
  ///
  /// NOT the way a profile is added any more: "Add a profile" and "Create a new
  /// profile" go through the details step, which mints as it names ([addProfile]
  /// → [createFirstBand]). A tap is not an ask (#44).
  Future<BandAccount?> addAccount() async {
    if (accountActionsBlocked) return null;
    ref.read(onboardingDraftProvider.notifier).clear();
    // A fresh band's onboarding has no account steps — step 1 is details.
    ref.read(onboardingPreludeProvider.notifier).reset();
    final account = await _mintBand();
    state = AppState(
      accountId: account.id,
      accounts: [...state.accounts, account],
      settings: state.settings,
    );
    return account;
  }

  /// A band, created as the artist NAMES it (onboarding's details step) and at
  /// no other moment — the account's first, or another one they asked for on
  /// "Add a profile". The app used to mint the first the instant a warm account
  /// read back empty, which invented a nameless profile nobody asked for and
  /// synced it over a deletion made on another device (#26); and it used to mint
  /// the others on the tap that opened the form, which left a phantom behind on
  /// every device whenever the form was abandoned (#44). Both are the same rule:
  /// a name is the ask.
  ///
  /// Unlike [addAccount] it leaves the onboarding draft and the step counter
  /// alone: this is the run already in progress, not a new one. Returns null
  /// when refused (a live session).
  Future<BandAccount?> createFirstBand() async {
    if (accountActionsBlocked) return null;
    final account = await _mintBand();
    // A whole new AppState, never copyWith: the band that was open may have had
    // a Stripe key, a jar and a relay secret, and carrying those over onto a
    // profile that owns none of them is another band's gig on this one's screen.
    state = AppState(
      accountId: account.id,
      accounts: [...state.accounts, account],
      settings: state.settings,
    );
    return account;
  }

  /// DELETES [id] — from the account, on every device, for good: its data,
  /// its secrets, its band entry, and (best effort) its relay jar on the
  /// server, so the public fan page dies with it. On a CLOUD profile this
  /// reaches the whole account; the local profile has nowhere else to reach.
  /// The ONLY removal a profile has (#37): a cloud account's profile set is
  /// identical on every device, so there is no such thing as taking a profile
  /// off one of them. Every surface that calls this must say *delete*, and say
  /// *account*.
  ///
  /// Then activates the first remaining band. Removing the LAST band leaves
  /// the registry honestly empty — no replacement is minted. That used to be
  /// the trap: removal always produced a fresh empty profile and the router
  /// always had somewhere to put it, so the last profile could never actually
  /// be deleted. "No profile" is a routable state now: RootGate lands it on
  /// the create-a-profile step (when the device still knows an account of any
  /// kind) or back on Welcome (when nothing at all remains). Refused during a
  /// live session, and
  /// when a cloud band's server-side wipe is unreachable (offline) — a refusal
  /// deletes nothing and returns false.
  Future<bool> removeAccount(String id) async {
    if (accountActionsBlocked) return false;
    if (!_registry.contains(id)) return false;
    state = state.copyWith(switching: true);
    ref.read(onboardingDraftProvider.notifier).clear();
    ref.read(onboardingPreludeProvider.notifier).reset();

    final repo = ref.read(accountDataRepositoryProvider);

    // Best effort: retire the band's connected-mode jar on the relay so the
    // public fan page dies with the local copy. Failures are ignored —
    // jar retirement must never block the removal.
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
      try {
        await ref
            .read(relayClientProvider)
            .deleteJar(jarId: jar.jarId, secret: secret);
      } catch (_) {
        // Offline, already gone, or a rotated secret — nothing more to do.
      }
    }

    // Subtree first, band entry second: the cloud repository enumerates a
    // band's session/tip/secret docs by its collections, and deleting the
    // band doc first would leave the wipe nothing to hang the query on.
    // The cloud wipe lists those docs on the SERVER and throws offline — a
    // cache-backed listing would miss docs this device never synced and
    // strand them under a deleted band. A refusal deletes nothing, so put
    // the switch flag back and report failure; the user retries online.
    // (The local profile's wipe is all-prefs and never throws.)
    try {
      await repo.wipeAccountData(id);
    } catch (_) {
      state = state.copyWith(switching: false);
      return false;
    }
    final registry = _registry.withoutAccount(id);
    await repo.removeBandEntry(id);
    await _landAfterRemoval(id, registry);
    return true;
  }

  /// The tail of a removal: land the app on a surviving band and drop [id]'s
  /// keychain secrets. Split out from [removeAccount] because the landing rule
  /// is worth stating once, away from the wipe that precedes it.
  Future<void> _landAfterRemoval(String id, AccountsRegistry registry) async {
    final repo = ref.read(accountDataRepositoryProvider);
    // Load the successor BEFORE wiping, so the UI lands on coherent state.
    // Which successor is not this method's to invent: it answers with
    // [_pickActive], the same rule every other landing obeys — the last
    // surviving band opens, several of them ask (RootGate shows the picker),
    // and none leaves '' behind. Naming a successor here instead would only
    // be overruled by the next rebuild, which asks; and picking a profile
    // for the artist is the very thing that opened the wrong gig.
    final successorId = id == state.accountId
        ? _pickActive(registry.accounts, repo.readActiveBandId(),
            ask: _askForBand)
        : state.accountId;
    String? apiKey;
    String? relaySecret;
    if (successorId == state.accountId) {
      apiKey = state.apiKey;
      relaySecret = state.relaySecret;
    } else if (successorId.isNotEmpty) {
      try {
        apiKey = await repo.readApiKey(successorId);
        relaySecret = await repo.readRelaySecret(successorId);
      } catch (_) {}
    }
    if (successorId.isNotEmpty) await repo.saveActiveBandId(successorId);
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
    // Nothing to push at the archives: RelayHistoryNotifier watches the band
    // id and the cloud revision, so it rebuilds itself. Invalidating it from
    // here made the removal complete with a CircularDependencyError instead —
    // it already watches THIS notifier.
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
  /// no name, no data, no secrets — each CONFIRMED, not just unloaded.
  /// Any doubt — an unsettled cloud mirror, a keychain error, one leftover
  /// key — keeps the band.
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
    // `!= false`, not `!`: a cloud repository whose history mirrors have not
    // heard from the server answers null — "nobody can say yet" — and
    // history synced from another device but never opened here must not be
    // collected as if it were nothing.
    if (repo.accountHasData(id) != false) return;
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

/// Whether this device has anything set up at all — the question that
/// decides whether the first-run pitch (WelcomeScreen) shows.
///
/// True as soon as SOME band of the active profile has a payment method, or a
/// cloud account is signed in, or the device knows a cloud account it could
/// sign back into. Only a device where none of that holds is genuinely on its
/// first run; everywhere else the artist has something to come back to, and
/// must land in the shell where the switcher, Settings and sign-out live —
/// never on a marketing page with no chrome.
///
/// Deliberately NOT "what there is to put on screen" — that is
/// [activeProfileRenderProvider]'s question. Conflating the two is how
/// removing the last local profile used to render AppShell around a band
/// that didn't exist, just because a cloud account was in the directory.
///
/// Bands of OTHER profiles aren't consulted: their jars sit in a repository
/// this profile can't read. The directory entry stands in for them, which is
/// what "a cloud account exists on this device" means anyway.
final deviceIsSetUpProvider = Provider<bool>((ref) {
  final app = ref.watch(appStateProvider);
  if (app.connected) return true;
  if (ref.watch(authControllerProvider.select((s) => s.user != null))) {
    return true;
  }
  final directory = ref.watch(accountsDirectoryProvider);
  if (!directory.active.isLocal) return true;
  if (directory.accounts.any((a) => !a.isLocal)) return true;
  // A cloud snapshot can bring bands in after the first frame.
  ref.watch(repoRevisionProvider);
  final repo = ref.watch(accountDataRepositoryProvider);
  return app.accounts.any((a) =>
      repo.readTipJar(a.id) != null || repo.readRelayJar(a.id) != null);
});

/// What the ACTIVE profile has to put on screen — the other half of the
/// question [deviceIsSetUpProvider] used to answer alone: "this device has an
/// account somewhere" and "this profile has a band to render" are two
/// different questions, and they get two answers.
enum ProfileRender {
  /// A band is active — the shell (or jar setup) builds around it. A cloud
  /// mirror that has not spoken yet counts too: its silence is not "no
  /// bands", and the empty-state home it lands on has all the doors.
  band,

  /// The account has several profiles and nobody has said which one is
  /// tonight's. The app used to answer for the artist — the stored id, else
  /// the first band — and opened the wrong gig: wrong QR on the merch table,
  /// wrong goal on the stage, tips against another band's history. It asks.
  pick,

  /// A profile set that is warm and has nothing in it — a fresh cloud account,
  /// or the local profile after its last band was removed. Not a hole to be
  /// plugged with a fabricated band: that band was written back to the cloud
  /// and undid deletions made on other devices. The artist creates the first
  /// profile, and nothing is written until they do.
  ///
  /// The empty LOCAL profile used to answer with the account list instead, and
  /// that was a dead end: the list is the screen the artist tapped the local
  /// row ON, it re-rendered as the root under the pushed copy, and there was no
  /// door to a profile from it (#38). An empty profile set is an empty profile
  /// set, whoever owns it, and the way out of one is to make a profile.
  create,
}

final activeProfileRenderProvider = Provider<ProfileRender>((ref) {
  final app = ref.watch(appStateProvider);
  if (app.accountId.isNotEmpty) return ProfileRender.band;
  if (app.accounts.isNotEmpty) return ProfileRender.pick;
  // No bands and no answer yet — but "no bands" only means something once the
  // mirror has spoken. A cold snapshot can bring them in after the first
  // frame, so watch the revision and keep the shell until it does. The local
  // store has never had a cold moment (LocalStoreRepository.isWarm), so the
  // local profile's emptiness is an answer the instant it is read: the removal
  // of its last band, and the create step is where that lands.
  ref.watch(repoRevisionProvider);
  return ref.watch(accountDataRepositoryProvider).isWarm
      ? ProfileRender.create
      : ProfileRender.band;
});

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

/// The relay's transport identity. Anonymous sign-in happens HERE, out of
/// band from [AuthController] — a local-profile artist gets a uid to talk to
/// the relay with, and nothing else: no directory entry, no switcher row, no
/// change of active profile.
final relayAuthProvider =
    Provider<RelayAuth>((ref) => RelayAuth(ref.watch(authServiceProvider)));

/// The jar callables. Long-lived: it holds no socket and no connection, so
/// there is nothing to close.
final relayClientProvider = Provider<RelayClient>(
  (ref) => RelayClient(
    auth: ref.watch(relayAuthProvider),
    functions: ref.watch(functionsProvider),
  ),
);

/// Builds the relay push tip feed for a session — a seam mirroring
/// [tipSourceFactoryProvider] so controller tests can hand in a fake
/// channel. Null means "this session has no relay feed": demo sessions
/// synthesize their tips, and without a jar + secret (or without Firebase)
/// there is nothing to listen to.
typedef RelayChannelFactory = TipChannel? Function({
  required bool demo,
  required RelayJar? jar,
  required String? secret,
});

final relayChannelFactoryProvider = Provider<RelayChannelFactory>(
  (ref) => ({required demo, required jar, required secret}) {
    if (demo || jar == null || secret == null) return null;
    // No Firestore, no feed — the app runs relay-less, as it does on the
    // platforms without Firebase.
    final db = ref.read(firestoreProvider);
    if (db == null) return null;
    return FirestoreTipChannel(
      db: db,
      auth: ref.read(relayAuthProvider),
      client: ref.read(relayClientProvider),
      jarId: jar.jarId,
      secret: secret,
    );
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
