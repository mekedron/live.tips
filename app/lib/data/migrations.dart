import 'dart:convert';

import '../domain/band_account.dart';
import 'local_store.dart';
import 'secure_store.dart';

/// One-time (and crash-safe) move from the single-band storage layout to
/// per-band namespaced keys plus an accounts registry.
///
/// Two independent phases, because prefs writes are reliable while keychain
/// access fails transiently (locked keychain, first unlock, macOS ad-hoc
/// build prompts) and must stay retriable without blocking boot:
///
/// * **Prefs phase** (in [ensureAccountsRegistry]): copy the legacy blobs
///   into `<key>_<id>` slots, lift the band-scoped settings out of
///   `settings_v1`, write `accounts_v1` (the commit point), then delete the
///   legacy keys. The pending account id is persisted *before* any copy so
///   a crash mid-migration resumes under the same id instead of stranding
///   half-moved data under a lost one.
/// * **Keychain phase** ([migrateKeychainIfNeeded]): copy the legacy
///   `stripe_api_key` / `relay_jar_secret` slots into the first account's
///   suffixed keys, delete the legacy slots, and flag completion in prefs.
///   Any keychain error just postpones it to the next boot — the app runs
///   signed-out-with-data meanwhile, exactly like a failed keychain read
///   does today. This phase also adopts secrets surviving an app reinstall
///   (the keychain outlives prefs on iOS/macOS).
const kKeychainMigratedFlag = 'keychain_migrated_v1';
const kMigrationPendingId = 'migration_pending_id_v1';

/// Which account the next keychain phase should adopt the legacy secrets
/// into — set by whichever prefs-phase path (re)arms the keychain phase, so
/// a downgrade sweep's secrets land in the swept band, never in whoever
/// happens to be first in the registry.
const kKeychainTargetId = 'keychain_target_id_v1';

/// Idempotent: returns the existing registry, or migrates/creates one.
/// Also sweeps legacy prefs keys left behind by a downgraded app version
/// back into a (new) account, so downgrade-era data never becomes invisible.
///
/// **A registry may be born empty. A band may not be born unasked.** A band is
/// created here for exactly one reason: there is legacy data to adopt, and that
/// data needs a band to live in. A genuinely fresh install has nothing to
/// adopt, so it gets a registry with no accounts and no active band.
///
/// It did not always. This function used to mint one nameless band on every
/// fresh install, before the artist had tapped anything. Down the LOCAL path
/// the details step then renamed it, so it read as a harmless seed. Down the
/// CLOUD path nothing ever touched it — the cloud profile is minted into the
/// cloud repository — and that band sat in the local registry, unnamed, empty
/// and unreachable, until a sign-out landed the device back on the local
/// profile, where one band is not a choice and the app therefore opened it: a
/// profile the artist never made, appearing on their device by itself (#50).
/// The invariant is #26's — the app never creates a profile behind the artist's
/// back — and a profile's one birthplace is the name they type
/// (`AppStateNotifier.createFirstBand`, #44/#47).
///
/// Nothing downstream needs the seed. An empty profile set is routable in its
/// own right: `activeProfileRenderProvider` answers `create`, RootGate lands on
/// the create step (which carries the switcher and Settings itself, #40), and
/// the details step mints as it names (`activeAccount == null`) — the very path
/// an artist who deleted their last profile already walks.
///
/// An existing registry with NO accounts is returned as-is for the same reason:
/// it means the artist removed the last local profile, and minting a band here
/// is how a removed profile used to come back at the next boot.
Future<AccountsRegistry> ensureAccountsRegistry(LocalStore local) async {
  final prefs = local.prefs;
  final existing = local.readAccountsRegistry();
  if (existing != null) {
    if (!_hasLegacyPrefs(local)) {
      // A crash after cleanup could strand the pending id; left alone it
      // would confuse a much later downgrade sweep.
      await prefs.remove(kMigrationPendingId);
      return existing;
    }
    // A downgraded build wrote into the legacy slots — fold them into a
    // fresh account rather than losing them, and let the keychain phase
    // re-run to pick up any legacy secrets that came with them.
    var id = await _pendingId(local);
    // A pending id already in the registry is a crash between last run's
    // registry commit and its cleanup — UNLESS the legacy bytes no longer
    // match what that account holds, which means a downgrade wrote fresh
    // data since. Reusing the id then would skip the copy (targets exist)
    // and the cleanup below would destroy the only copy of the new data.
    if (existing.contains(id) && !_legacyMatchesAccount(local, id)) {
      await prefs.remove(kMigrationPendingId);
      id = await _pendingId(local);
    }
    await _copyLegacyPrefs(local, id);
    var registry = existing.contains(id)
        ? existing
        : existing.withAccount(BandAccount(
            id: id,
            name: _legacyBandName(local),
            createdAtMs: DateTime.now().millisecondsSinceEpoch,
          ));
    // An empty registry (the artist removed their last profile) that a
    // downgrade sweep just gave a band names no active one — and an activeId
    // pointing at nothing is a band nothing can open.
    if (!registry.contains(registry.activeId)) {
      registry = registry.withActive(id);
    }
    await prefs.setString(kKeychainTargetId, id);
    await local.saveAccountsRegistry(registry);
    await _deleteLegacyPrefs(local);
    await prefs.remove(kMigrationPendingId);
    await prefs.remove(kKeychainMigratedFlag);
    return registry;
  }

  // No registry and nothing to adopt: a genuinely fresh install. It gets an
  // empty registry — the app has been told nothing about any band yet, and
  // inventing one is the bug (#50). The keychain phase has nowhere to adopt
  // legacy secrets into and simply postpones itself (see
  // [migrateKeychainIfNeeded]) until the artist's first profile exists.
  if (!_hasLegacyPrefs(local)) {
    const registry = AccountsRegistry(accounts: [], activeId: '');
    await local.saveAccountsRegistry(registry);
    await prefs.remove(kMigrationPendingId);
    return registry;
  }

  final id = await _pendingId(local);
  await _copyLegacyPrefs(local, id);
  final registry = AccountsRegistry(
    accounts: [
      BandAccount(
        id: id,
        name: _legacyBandName(local),
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    ],
    activeId: id,
  );
  await prefs.setString(kKeychainTargetId, id);
  await local.saveAccountsRegistry(registry); // commit point
  await _deleteLegacyPrefs(local);
  await prefs.remove(kMigrationPendingId);
  return registry;
}

/// Drops the phantom bands older builds minted at boot: a band with no name,
/// no local data and no keychain secrets — nothing the artist ever made, and
/// nothing of theirs to lose. Returns the registry to boot on.
///
/// Devices in the wild carry these. Left alone, the phantom is what a sign-out
/// lands on (one band is not a choice, so it opens) and what the switcher lists
/// forever as "Unnamed profile — Not set up yet" (#50). Fixing the mint does
/// nothing for a device that already has one.
///
/// The predicate is the one the rest of the app already uses for "is this a
/// real profile?" — [ProfilePickScreen._real] and the upload offer both ignore
/// exactly this band — plus the keychain, which they have no reason to consult
/// and a deletion very much does:
///
/// * a **name** is the ask (#44), so a named band is the artist's, however
///   empty; it is never touched here (an abandoned named band is the discard
///   offer's business, and it asks).
/// * [LocalStore.accountHasData] covers every per-band prefs key — jars,
///   settings, session history, the relay-tip archive. A nameless band that
///   somehow holds data IS the artist's work (a pre-registry install adopted by
///   the migration above, whose jar carried no display name) and survives.
/// * a Stripe key or relay secret in the keychain is data too, and prefs cannot
///   see it: a reinstall re-adopts legacy secrets into the first band it finds,
///   and that band's key exists nowhere else on earth. A keychain that throws
///   proves nothing, so it means KEEP — the sweep just retries next boot.
///
/// The active band is not spared. On the device that reported this, the phantom
/// IS the local registry's active id (main() minted it active and the cloud
/// sign-in never came back to it), so sparing it would spare the whole bug.
Future<AccountsRegistry> sweepPhantomBands(
  LocalStore local,
  SecureStore secure,
  AccountsRegistry registry,
) async {
  final phantoms = <String>{};
  for (final band in registry.accounts) {
    if (band.name.trim().isNotEmpty) continue;
    if (local.accountHasData(band.id)) continue;
    try {
      if (await secure.readApiKey(band.id) != null) continue;
      if (await secure.readRelaySecret(band.id) != null) continue;
    } catch (_) {
      // Locked or prompting keychain: it cannot tell us this band is empty,
      // so it stays. Nothing is deleted on a guess.
      return registry;
    }
    phantoms.add(band.id);
  }
  if (phantoms.isEmpty) return registry;
  final remaining = [
    for (final band in registry.accounts)
      if (!phantoms.contains(band.id)) band,
  ];
  final swept = AccountsRegistry(
    accounts: remaining,
    activeId: remaining.any((b) => b.id == registry.activeId)
        ? registry.activeId
        : (remaining.isEmpty ? '' : remaining.first.id),
  );
  await local.saveAccountsRegistry(swept);
  return swept;
}

/// Moves the legacy keychain slots into [targetAccountId]'s suffixed keys.
/// Every failure is swallowed — the flag stays unset and the next boot
/// retries. Never call in the DEV_STRIPE_KEY debug branch (it exists to
/// avoid exactly these keychain prompts).
Future<void> migrateKeychainIfNeeded(
  LocalStore local,
  SecureStore secure,
  AccountsRegistry registry,
) async {
  final prefs = local.prefs;
  // Bands removed while the keychain was locked left tombstones — retry
  // their secret deletion every boot. Explicit tombstones only: the
  // keychain outlives prefs across reinstalls, so "not in the registry"
  // must never be read as "safe to delete".
  for (final id in local.readPendingSecretWipes()) {
    try {
      await secure.wipeAccount(id);
      await local.removePendingSecretWipe(id);
    } catch (_) {
      // Still locked — keep the tombstone for the next boot.
    }
  }
  if (prefs.getBool(kKeychainMigratedFlag) ?? false) return;
  // The prefs phase records which band the legacy secrets belong to; the
  // registry's first account covers pre-target installs and reinstalls.
  final stored = prefs.getString(kKeychainTargetId);
  final targetAccountId = (stored != null && registry.contains(stored))
      ? stored
      : registry.accounts.firstOrNull?.id;
  // An empty registry has nowhere to adopt legacy secrets into — the last
  // profile was removed, or this is a fresh install/reinstall that has not
  // been given a profile yet. The flag stays unset and the boot after the
  // artist names their first band adopts them into it. (Nothing is lost
  // meanwhile: the secrets sit in their legacy slots, untouched.)
  if (targetAccountId == null) return;
  try {
    final legacyKey = await secure.readLegacyApiKey();
    final legacySecret = await secure.readLegacyRelaySecret();
    if (legacyKey != null && legacyKey.isNotEmpty) {
      final current = await secure.readApiKey(targetAccountId);
      if (current == null) {
        await secure.writeApiKey(targetAccountId, legacyKey);
      }
    }
    if (legacySecret != null && legacySecret.isNotEmpty) {
      final current = await secure.readRelaySecret(targetAccountId);
      if (current == null) {
        await secure.writeRelaySecret(targetAccountId, legacySecret);
      }
    }
    await secure.deleteLegacySlots();
    await prefs.setBool(kKeychainMigratedFlag, true);
    await prefs.remove(kKeychainTargetId);
  } catch (_) {
    // Locked or prompting keychain — boot signed-out, retry next launch.
  }
}

/// The pending-migration account id: persisted before any data moves, so a
/// crash mid-migration resumes under the same id.
Future<String> _pendingId(LocalStore local) async {
  final prefs = local.prefs;
  final pending = prefs.getString(kMigrationPendingId);
  if (pending != null && pending.isNotEmpty) return pending;
  final id = BandAccount.newId();
  await prefs.setString(kMigrationPendingId, id);
  return id;
}

bool _hasLegacyPrefs(LocalStore local) => LocalStore.accountKeyBases
    .any((base) => local.prefs.containsKey(base));

/// Whether every present legacy value is byte-identical to [accountId]'s
/// copy — true only for leftovers of an already-committed migration run,
/// which are safe to delete without re-copying.
bool _legacyMatchesAccount(LocalStore local, String accountId) {
  final prefs = local.prefs;
  for (final base in LocalStore.accountKeyBases) {
    final source = prefs.get(base);
    if (source == null) continue;
    if (prefs.get(LocalStore.accountKey(base, accountId)) != source) {
      return false;
    }
  }
  return true;
}

/// Copy-only and type-aware: `relay_seen_at_v1` is an int, the rest are
/// strings — `prefs.get` + a runtime-type switch keeps every value
/// byte-identical without parsing any JSON (a parse failure must never be
/// able to eat data here). Skips keys whose target already exists (resumed
/// run) or whose source is gone.
Future<void> _copyLegacyPrefs(LocalStore local, String accountId) async {
  final prefs = local.prefs;
  for (final base in LocalStore.accountKeyBases) {
    final target = LocalStore.accountKey(base, accountId);
    if (prefs.containsKey(target)) continue;
    final value = prefs.get(base);
    switch (value) {
      case final String s:
        await prefs.setString(target, s);
      case final int i:
        await prefs.setInt(target, i);
      case final bool b:
        await prefs.setBool(target, b);
      case final double d:
        await prefs.setDouble(target, d);
      default:
        break; // absent or an unexpected type — nothing to move
    }
  }
  await _extractBandSettings(local, accountId);
}

/// Lifts the band-scoped fields out of the legacy `settings_v1` blob into
/// `band_settings_v1_<id>`. The originals stay in place — the new
/// [AppSettings] decoder simply ignores them.
Future<void> _extractBandSettings(LocalStore local, String accountId) async {
  final prefs = local.prefs;
  final target =
      LocalStore.accountKey(LocalStore.kBandSettingsBase, accountId);
  if (prefs.containsKey(target)) return;
  // prefs.get + type check, not getString: this runs before runApp, and a
  // foreign-typed value (possible on web, where prefs is just localStorage)
  // must degrade to "no settings", never crash the boot.
  final raw = prefs.get('settings_v1');
  if (raw is! String) return;
  Map<String, dynamic> legacy;
  try {
    legacy = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return;
  }
  final band = <String, dynamic>{
    if (legacy['qrMode'] is String) 'qrMode': legacy['qrMode'],
    if (legacy['lastGoalMinor'] is num) 'lastGoalMinor': legacy['lastGoalMinor'],
    if (legacy['poster'] is Map) 'poster': legacy['poster'],
  };
  if (band.isEmpty) return;
  await prefs.setString(target, jsonEncode(band));
}

/// The band's name, read from the raw legacy jar blobs (Stripe jar wins,
/// like the old `AppState.displayName` chain). Failures → ''.
String _legacyBandName(LocalStore local) {
  final prefs = local.prefs;
  for (final (key, field) in [
    (LocalStore.kTipJarBase, 'displayName'),
    (LocalStore.kRelayJarBase, 'artistName'),
  ]) {
    final raw = prefs.get(key);
    if (raw is! String) continue;
    try {
      final name = (jsonDecode(raw) as Map<String, dynamic>)[field];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    } catch (_) {}
  }
  return '';
}

/// Post-commit cleanup — safe to re-run; leftovers just get deleted again.
Future<void> _deleteLegacyPrefs(LocalStore local) async {
  for (final base in LocalStore.accountKeyBases) {
    await local.prefs.remove(base);
  }
}
