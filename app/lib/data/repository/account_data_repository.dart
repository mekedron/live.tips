import '../../domain/app_settings.dart';
import '../../domain/band_account.dart';
import '../../domain/band_settings.dart';
import '../../domain/live_session.dart';
import '../../domain/relay_jar.dart';
import '../../domain/tip.dart';
import '../../domain/tip_jar.dart';
import '../local_store.dart';
import '../secure_store.dart';

/// Everything a band (and the device) persists, behind one seam: the
/// local no-account profile is served by [LocalStoreRepository] over
/// SharedPreferences + the keychain, and a signed-in account will be served
/// by a Firestore-backed implementation with the same contract.
///
/// Contract notes carried over from the stores:
/// - Reads of non-secret data are synchronous (served from a local cache).
/// - Secret reads/writes go through the platform keychain and may THROW
///   transiently (locked keychain, denied prompt) — callers catch.
/// - The active-session crash snapshot is device-local in EVERY
///   implementation: it exists to survive a crash on THIS device, and two
///   devices' in-flight snapshots must never overwrite each other.
abstract interface class AccountDataRepository {
  /// Whether [listBands] can be believed yet. A cloud mirror starts out
  /// EMPTY AND SILENT: "no snapshot has landed" and "this account has no
  /// bands" are different answers, and a caller that reads the first as the
  /// second fabricates a band on every cold start. Emptiness is the SERVER's
  /// word alone — an offline boot's empty from-cache snapshot stays silence.
  /// The local store is warm the moment it exists.
  bool get isWarm;

  // --- The band list itself ---
  //
  // Local profile: the AccountsRegistry in prefs, exactly as always.
  // Cloud profile: the users/{uid}/bands collection (mirrored in memory),
  // with the ACTIVE band id kept device-local — which band you're looking
  // at is a device concern, not synced state.
  //
  // Only meaningful while [isWarm]; a cold repository answers with an empty
  // list because it has nothing to say, not because there is nothing.
  List<BandAccount> listBands();
  String? readActiveBandId();
  Future<void> saveActiveBandId(String bandId);

  /// THE INVARIANT: this is called only as the direct result of the artist
  /// creating (or renaming) a profile — [AppStateNotifier.addAccount] behind
  /// a tap, and the rename that names one. Never to repair an empty list.
  /// "This account has no profile" is a state the app renders (see
  /// [ProfileRender]), not a hole to be plugged: the fabricated band was
  /// written back to the cloud, and a deletion made on one device came back
  /// from the mirror of another.
  Future<void> upsertBandEntry(BandAccount band);
  Future<void> removeBandEntry(String bandId);

  // --- Stripe tip jar ---
  TipJar? readTipJar(String accountId);
  Future<void> saveTipJar(String accountId, TipJar jar);
  Future<void> clearTipJar(String accountId);

  // --- Relay jar (connected mode) ---
  RelayJar? readRelayJar(String accountId);
  Future<void> saveRelayJar(String accountId, RelayJar jar);
  Future<void> clearRelayJar(String accountId);
  String? readRelayLinkReplaced(String accountId);
  Future<void> writeRelayLinkReplaced(String accountId, String oldTipUrl);
  Future<void> clearRelayLinkReplaced(String accountId);

  // --- Band settings ---
  BandSettings readBandSettings(String accountId);
  Future<void> saveBandSettings(String accountId, BandSettings band);

  // --- Histories ---
  List<LiveSession> readSessionHistory(String accountId);
  Future<void> appendSessionToHistory(String accountId, LiveSession session);
  List<Tip> readRelayHistory(String accountId);
  Future<void> appendRelayHistory(String accountId, List<Tip> tips);

  // --- Active session (crash recovery; device-local everywhere) ---
  LiveSession? readActiveSession(String accountId);
  String? readActiveCursor(String accountId);
  Future<void> saveActiveSession(
      String accountId, LiveSession session, String? cursor);
  Future<void> clearActiveSession(String accountId);

  // --- Secrets (keychain-backed; reads/writes may throw transiently) ---
  Future<String?> readApiKey(String accountId);
  Future<void> writeApiKey(String accountId, String key);
  Future<void> deleteApiKey(String accountId);
  Future<String?> readRelaySecret(String accountId);
  Future<void> writeRelaySecret(String accountId, String secret);
  Future<void> deleteRelaySecret(String accountId);

  // --- Whole-band lifecycle ---

  /// Whether [accountId] holds anything worth keeping — a jar, a session,
  /// tip history. Tri-state on purpose: `true` is "yes", `false` is
  /// "CONFIRMED empty", and `null` is "nobody can say yet" — a cloud mirror
  /// that has not heard from the server cannot tell empty from not-loaded.
  /// Every caller of this method deletes on "empty", so a destructive
  /// caller must treat `null` exactly like `true` and keep its hands off.
  /// The local store always has an answer.
  bool? accountHasData(String accountId);
  Future<void> purgeSimulatedData(String accountId);

  /// Removes every non-secret blob belonging to [accountId]. A wipe must be
  /// COMPLETE, so the cloud implementation lists the band's docs on the
  /// server and throws without deleting anything when it can't be reached —
  /// a cache-backed listing would miss docs this device never synced and
  /// strand them under a deleted band. The local implementation never
  /// throws.
  Future<void> wipeAccountData(String accountId);

  /// Removes [accountId]'s secrets. May throw (locked keychain) — the
  /// caller tombstones and retries at boot.
  Future<void> wipeAccountSecrets(String accountId);

  /// Forgets [accountId] on THIS DEVICE and nowhere else: the cached copy of
  /// the band and every device-local blob it owns. The exact opposite of
  /// [wipeAccountData] — the cloud implementation touches no document, so the
  /// band keeps its place in the account, its tip page keeps serving, and the
  /// next snapshot brings the copy back. NEVER needs the network: this is the
  /// removal an artist can run on a venue tablet with no signal, and the one
  /// the words "remove from this device" have always promised.
  ///
  /// The local profile has no elsewhere for a band to stay, so there the copy
  /// IS the band and the two operations collapse into one — the local
  /// implementation removes it outright, which is what it has always done.
  ///
  /// The keychain is [wipeAccountSecrets]' job in both, as always.
  Future<void> forgetAccountOnDevice(String accountId);

  // --- Device settings ---
  AppSettings readSettings();
  Future<void> saveSettings(AppSettings settings);
}

/// The local no-account profile: a thin delegation to [LocalStore] and
/// [SecureStore], byte-for-byte today's behavior.
///
/// The keychain is resolved lazily, on the first secret access — consumers
/// that only ever read prefs-backed data (the session controller, history
/// views) must work without a keychain wired up at all.
class LocalStoreRepository implements AccountDataRepository {
  LocalStoreRepository(this._local, this._resolveSecure);

  final LocalStore _local;
  final SecureStore Function() _resolveSecure;
  SecureStore? _secureCache;
  SecureStore get _secure => _secureCache ??= _resolveSecure();

  AccountsRegistry? get _registry => _local.readAccountsRegistry();

  /// Prefs are read synchronously from a warmed cache — this repository has
  /// never had a cold moment.
  @override
  bool get isWarm => true;

  @override
  List<BandAccount> listBands() => _registry?.accounts ?? const [];

  @override
  String? readActiveBandId() => _registry?.activeId;

  @override
  Future<void> saveActiveBandId(String bandId) async {
    final registry = _registry;
    if (registry == null || !registry.contains(bandId)) return;
    await _local.saveAccountsRegistry(registry.withActive(bandId));
  }

  @override
  Future<void> upsertBandEntry(BandAccount band) async {
    final registry = _registry;
    if (registry == null) {
      await _local.saveAccountsRegistry(
          AccountsRegistry(accounts: [band], activeId: band.id));
      return;
    }
    final next = registry.contains(band.id)
        ? AccountsRegistry(
            accounts: [
              for (final a in registry.accounts)
                if (a.id == band.id) band else a,
            ],
            activeId: registry.activeId,
          )
        : registry.withAccount(band);
    await _local.saveAccountsRegistry(next);
  }

  @override
  Future<void> removeBandEntry(String bandId) async {
    final registry = _registry;
    if (registry == null) return;
    await _local.saveAccountsRegistry(registry.withoutAccount(bandId));
  }

  @override
  TipJar? readTipJar(String accountId) => _local.readTipJar(accountId);

  @override
  Future<void> saveTipJar(String accountId, TipJar jar) =>
      _local.saveTipJar(accountId, jar);

  @override
  Future<void> clearTipJar(String accountId) => _local.clearTipJar(accountId);

  @override
  RelayJar? readRelayJar(String accountId) => _local.readRelayJar(accountId);

  @override
  Future<void> saveRelayJar(String accountId, RelayJar jar) =>
      _local.saveRelayJar(accountId, jar);

  @override
  Future<void> clearRelayJar(String accountId) =>
      _local.clearRelayJar(accountId);

  @override
  String? readRelayLinkReplaced(String accountId) =>
      _local.readRelayLinkReplaced(accountId);

  @override
  Future<void> writeRelayLinkReplaced(String accountId, String oldTipUrl) =>
      _local.writeRelayLinkReplaced(accountId, oldTipUrl);

  @override
  Future<void> clearRelayLinkReplaced(String accountId) =>
      _local.clearRelayLinkReplaced(accountId);

  @override
  BandSettings readBandSettings(String accountId) =>
      _local.readBandSettings(accountId);

  @override
  Future<void> saveBandSettings(String accountId, BandSettings band) =>
      _local.saveBandSettings(accountId, band);

  @override
  List<LiveSession> readSessionHistory(String accountId) =>
      _local.readSessionHistory(accountId);

  @override
  Future<void> appendSessionToHistory(
          String accountId, LiveSession session) =>
      _local.appendSessionToHistory(accountId, session);

  @override
  List<Tip> readRelayHistory(String accountId) =>
      _local.readRelayHistory(accountId);

  @override
  Future<void> appendRelayHistory(String accountId, List<Tip> tips) =>
      _local.appendRelayHistory(accountId, tips);

  @override
  LiveSession? readActiveSession(String accountId) =>
      _local.readActiveSession(accountId);

  @override
  String? readActiveCursor(String accountId) =>
      _local.readActiveCursor(accountId);

  @override
  Future<void> saveActiveSession(
          String accountId, LiveSession session, String? cursor) =>
      _local.saveActiveSession(accountId, session, cursor);

  @override
  Future<void> clearActiveSession(String accountId) =>
      _local.clearActiveSession(accountId);

  @override
  Future<String?> readApiKey(String accountId) =>
      _secure.readApiKey(accountId);

  @override
  Future<void> writeApiKey(String accountId, String key) =>
      _secure.writeApiKey(accountId, key);

  @override
  Future<void> deleteApiKey(String accountId) =>
      _secure.deleteApiKey(accountId);

  @override
  Future<String?> readRelaySecret(String accountId) =>
      _secure.readRelaySecret(accountId);

  @override
  Future<void> writeRelaySecret(String accountId, String secret) =>
      _secure.writeRelaySecret(accountId, secret);

  @override
  Future<void> deleteRelaySecret(String accountId) =>
      _secure.deleteRelaySecret(accountId);

  @override
  bool accountHasData(String accountId) => _local.accountHasData(accountId);

  @override
  Future<void> purgeSimulatedData(String accountId) =>
      _local.purgeSimulatedData(accountId);

  @override
  Future<void> wipeAccountData(String accountId) =>
      _local.wipeAccount(accountId);

  @override
  Future<void> wipeAccountSecrets(String accountId) =>
      _secure.wipeAccount(accountId);

  /// The collapse: a local band lives on this device and nowhere else, so
  /// forgetting the copy IS deleting the band. Same two calls [wipeAccountData]
  /// and the notifier's removal make, in the same order — and no network, which
  /// the local profile never needed anyway.
  @override
  Future<void> forgetAccountOnDevice(String accountId) async {
    await _local.wipeAccount(accountId);
    await removeBandEntry(accountId);
  }

  @override
  AppSettings readSettings() => _local.readSettings();

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _local.saveSettings(settings);
}
