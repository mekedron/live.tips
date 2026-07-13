import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/migrations.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const _legacyTipJar = '{"productId":"prod_1","priceId":"price_1",'
    '"paymentLinkId":"plink_1","url":"https://buy.stripe.com/x",'
    '"currency":"eur","displayName":"The Midnight Foxes","livemode":true,'
    '"thankYouMessage":"Thanks!"}';

const _legacyRelayJar = '{"jarId":"jar_1",'
    '"tipUrl":"https://live.tips/t/jar_1","artistName":"Foxy Live",'
    '"currency":"eur","revolutUsername":"foxy","createdAtMs":5}';

const _legacySettings = '{"pollIntervalSec":8,"lastGoalMinor":25000,'
    '"themeMode":"dark","qrMode":"stripe",'
    '"poster":{"displayName":"Foxy","headline":"Tip us!"}}';

const _legacyHistory = '[{"id":"ses_1","startedAt":1000,"currency":"eur",'
    '"goalMinor":5000,"tips":[]}]';

/// The full pre-multi-band layout of a connected install, including the
/// int-typed seen marker that a naive string copy would trip over.
Map<String, Object> _legacyPrefs() => {
      'tip_jar_v1': _legacyTipJar,
      'relay_jar_v1': _legacyRelayJar,
      'settings_v1': _legacySettings,
      'session_history_v1': _legacyHistory,
      'active_session_v1': '{"id":"ses_2","startedAt":2000,'
          '"currency":"eur","goalMinor":5000,"tips":[]}',
      'active_session_cursor_v1': 'evt_123',
      'relay_seen_at_v1': 1751900000000,
      'relay_history_v1': '[]',
    };

Future<LocalStore> _store(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalStore(await SharedPreferences.getInstance());
}

/// The registry a device has once the artist has actually made a profile —
/// which, since #50, is the ONLY way a band ever gets into one. The boot
/// migration mints nothing on a fresh install, so a test that needs a band to
/// exist has to say so, exactly like the artist does.
Future<AccountsRegistry> _withBand(
  LocalStore local, {
  String id = 'acc_first',
  String name = 'The Foxes',
}) async {
  final registry = AccountsRegistry(
    accounts: [BandAccount(id: id, name: name, createdAtMs: 0)],
    activeId: id,
  );
  await local.saveAccountsRegistry(registry);
  return registry;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prefs phase', () {
    test('moves every legacy blob byte-identically under one account',
        () async {
      final local = await _store(_legacyPrefs());
      final registry = await ensureAccountsRegistry(local);
      final id = registry.activeId;

      expect(registry.accounts, hasLength(1));
      expect(registry.accounts.single.name, 'The Midnight Foxes',
          reason: 'the Stripe jar names the migrated band');

      final prefs = local.prefs;
      expect(prefs.getString('tip_jar_v1_$id'), _legacyTipJar);
      expect(prefs.getString('relay_jar_v1_$id'), _legacyRelayJar);
      expect(prefs.getString('session_history_v1_$id'), _legacyHistory);
      expect(prefs.getString('active_session_cursor_v1_$id'), 'evt_123');
      expect(prefs.getInt('relay_seen_at_v1_$id'), 1751900000000,
          reason: 'the seen marker is an int and must stay one');

      for (final base in LocalStore.accountKeyBases) {
        expect(prefs.containsKey(base), isFalse,
            reason: 'legacy key $base must be gone after the commit');
      }
      expect(prefs.getString(kMigrationPendingId), isNull);
    });

    test('lifts qrMode/goal/poster into band settings, keeps device settings',
        () async {
      final local = await _store(_legacyPrefs());
      final registry = await ensureAccountsRegistry(local);
      final band = local.readBandSettings(registry.activeId);

      expect(band.qrMode.wire, 'stripe');
      expect(band.lastGoalMinor, 25000);
      expect(band.poster.displayName, 'Foxy');
      expect(band.poster.headline, 'Tip us!');

      final settings = local.readSettings();
      expect(settings.pollIntervalSec, 8);
      expect(settings.themeMode.wire, 'dark');
    });

    test('is idempotent — a second run returns the same registry', () async {
      final local = await _store(_legacyPrefs());
      final first = await ensureAccountsRegistry(local);
      final second = await ensureAccountsRegistry(local);
      expect(second.activeId, first.activeId);
      expect(second.accounts, hasLength(1));
    });

    test('a crash mid-copy resumes under the SAME pending id', () async {
      // First attempt died after persisting the pending id and copying one
      // key, before the registry commit.
      final local = await _store({
        ..._legacyPrefs(),
        kMigrationPendingId: 'acc_pending',
        'tip_jar_v1_acc_pending': _legacyTipJar,
      });
      final registry = await ensureAccountsRegistry(local);
      expect(registry.activeId, 'acc_pending');
      expect(local.prefs.getString('relay_jar_v1_acc_pending'),
          _legacyRelayJar,
          reason: 'the rest of the copy completes under the pending id');
      expect(local.readTipJar('acc_pending')?.displayName,
          'The Midnight Foxes');
    });

    test('fresh install → an EMPTY registry: no band is minted (#50)',
        () async {
      // The boot sequence used to write one nameless band here, before the
      // artist had tapped anything. Down the cloud path nothing ever named it,
      // opened it or cleaned it up — and a sign-out landed the device on the
      // local profile, whose single band is not a choice, so the app opened it:
      // a profile the artist never made, appearing on its own (#26's invariant).
      final local = await _store({});
      final registry = await ensureAccountsRegistry(local);
      expect(registry.accounts, isEmpty);
      expect(registry.activeId, '');
      // And it is a REGISTRY, not the absence of one: written, so it is an
      // answer ("no bands") and not a fresh install to be seeded again.
      expect(local.readAccountsRegistry()?.accounts, isEmpty);
    });

    test('a fresh install boots empty again and again', () async {
      final local = await _store({});
      await ensureAccountsRegistry(local);
      final second = await ensureAccountsRegistry(local);
      expect(second.accounts, isEmpty);
    });

    test('a deliberately emptied registry stays empty across boots',
        () async {
      // Removing the last local profile leaves the registry with no
      // accounts. That is an ANSWER, not a fresh install — the boot
      // migration re-minting a band here is how a removed profile used to
      // come back on the next launch, un-deletable forever.
      final local = await _store({});
      await local.saveAccountsRegistry(
          const AccountsRegistry(accounts: [], activeId: ''));

      final registry = await ensureAccountsRegistry(local);
      expect(registry.accounts, isEmpty);
      // …and the keychain phase has no band to adopt legacy secrets into —
      // it must skip, never crash.
      await migrateKeychainIfNeeded(local, FakeSecureStore(), registry);
    });

    test('relay-only install names the band from the relay jar', () async {
      final local = await _store({'relay_jar_v1': _legacyRelayJar});
      final registry = await ensureAccountsRegistry(local);
      expect(registry.accounts.single.name, 'Foxy Live');
    });

    test('broken jar JSON still migrates, with an unnamed band', () async {
      final local = await _store({
        'tip_jar_v1': 'not json',
        'session_history_v1': _legacyHistory,
      });
      final registry = await ensureAccountsRegistry(local);
      expect(registry.accounts.single.name, '');
      expect(
          local.prefs.getString('tip_jar_v1_${registry.activeId}'), 'not json',
          reason: 'even unparseable bytes are moved, never dropped');
    });

    test('downgrade-era legacy keys are swept into a new account', () async {
      final local = await _store(_legacyPrefs());
      final before = await ensureAccountsRegistry(local);
      // A downgraded build wrote fresh legacy keys, then the user upgraded.
      await local.prefs.setString('tip_jar_v1', _legacyTipJar);
      final after = await ensureAccountsRegistry(local);
      expect(after.accounts, hasLength(2));
      expect(after.activeId, before.activeId,
          reason: 'the active band does not change under the user');
      final swept =
          after.accounts.firstWhere((a) => a.id != before.activeId);
      expect(local.readTipJar(swept.id)?.displayName, 'The Midnight Foxes');
      expect(local.prefs.containsKey('tip_jar_v1'), isFalse);
      expect(local.prefs.getBool(kKeychainMigratedFlag), isNull,
          reason: 'the keychain phase re-runs to pick up legacy secrets');
    });
  });

  group('keychain phase', () {
    test('moves legacy secrets into the first account and flags done',
        () async {
      final local = await _store(_legacyPrefs());
      final registry = await ensureAccountsRegistry(local);
      final secure = FakeSecureStore({
        'stripe_api_key': 'rk_live_secret',
        'relay_jar_secret': 'sec_relay',
      });

      await migrateKeychainIfNeeded(local, secure, registry);

      final id = registry.accounts.first.id;
      expect(await secure.readApiKey(id), 'rk_live_secret');
      expect(await secure.readRelaySecret(id), 'sec_relay');
      expect(await secure.readLegacyApiKey(), isNull);
      expect(await secure.readLegacyRelaySecret(), isNull);
      expect(local.prefs.getBool(kKeychainMigratedFlag), isTrue);
    });

    test('keychain failure postpones without corrupting anything', () async {
      final local = await _store(_legacyPrefs());
      final registry = await ensureAccountsRegistry(local);
      final secure = FakeSecureStore({'stripe_api_key': 'rk_live_secret'})
        ..failing = true;

      await migrateKeychainIfNeeded(local, secure, registry);
      expect(local.prefs.getBool(kKeychainMigratedFlag), isNull);

      secure.failing = false;
      await migrateKeychainIfNeeded(local, secure, registry);
      expect(await secure.readApiKey(registry.accounts.first.id),
          'rk_live_secret');
      expect(local.prefs.getBool(kKeychainMigratedFlag), isTrue);
    });

    test('a reinstall waits for a band, then adopts the secrets the keychain '
        'kept alive', () async {
      // Fresh prefs (the uninstall wiped them), surviving legacy keychain. The
      // reinstall boots with an EMPTY registry now — no band is invented to
      // hold the secrets, and none has to be: they stay in their legacy slots.
      final local = await _store({});
      final empty = await ensureAccountsRegistry(local);
      final secure = FakeSecureStore({'stripe_api_key': 'rk_live_kept'});

      await migrateKeychainIfNeeded(local, secure, empty);
      expect(await secure.readLegacyApiKey(), 'rk_live_kept',
          reason: 'nothing to adopt into — the secret is left where it is');
      expect(local.prefs.getBool(kKeychainMigratedFlag), isNull,
          reason: 'the phase stays armed for the boot after the first profile');

      // The artist makes their first profile; the next boot adopts into it.
      final registry = await _withBand(local);
      await migrateKeychainIfNeeded(local, secure, registry);
      expect(await secure.readApiKey('acc_first'), 'rk_live_kept',
          reason: 'reinstall-stays-connected behavior is preserved');
    });

    test('a reinstall NEVER deletes surviving per-band secrets', () async {
      // Prefs are gone after the reinstall, but the keychain kept the old
      // install's suffixed secrets. They are unknown, not deletable.
      final local = await _store({});
      await ensureAccountsRegistry(local);
      final registry = await _withBand(local);
      final secure = FakeSecureStore({
        '${SecureStore.kApiKeyBase}_acc_old': 'rk_live_survivor',
        '${SecureStore.kRelaySecretBase}_acc_old': 'sec_survivor',
      });

      await migrateKeychainIfNeeded(local, secure, registry);
      expect(await secure.readApiKey('acc_old'), 'rk_live_survivor',
          reason: '"not in the registry" must never mean "delete"');
    });

    test('tombstoned secrets are wiped at boot once the keychain works',
        () async {
      final local = await _store({});
      final registry = await ensureAccountsRegistry(local);
      final secure = FakeSecureStore({
        '${SecureStore.kApiKeyBase}_acc_removed': 'rk_live_gone',
        '${SecureStore.kRelaySecretBase}_acc_removed': 'sec_gone',
      });
      await local.addPendingSecretWipe('acc_removed');

      secure.failing = true;
      await migrateKeychainIfNeeded(local, secure, registry);
      expect(local.readPendingSecretWipes(), ['acc_removed'],
          reason: 'a locked keychain keeps the tombstone for next boot');

      secure.failing = false;
      await migrateKeychainIfNeeded(local, secure, registry);
      expect(await secure.readApiKey('acc_removed'), isNull);
      expect(await secure.readRelaySecret('acc_removed'), isNull);
      expect(local.readPendingSecretWipes(), isEmpty);
    });

    test('does not clobber an already-migrated per-account secret',
        () async {
      final local = await _store(_legacyPrefs());
      final registry = await ensureAccountsRegistry(local);
      final id = registry.accounts.first.id;
      final secure = FakeSecureStore({
        'stripe_api_key': 'rk_live_old',
        '${SecureStore.kApiKeyBase}_$id': 'rk_live_already_moved',
      });

      await migrateKeychainIfNeeded(local, secure, registry);
      expect(await secure.readApiKey(id), 'rk_live_already_moved');
    });

    test('downgrade-era secrets land in the SWEPT band, not the first one',
        () async {
      final local = await _store(_legacyPrefs());
      var registry = await ensureAccountsRegistry(local);
      final firstId = registry.accounts.first.id;
      final secure = FakeSecureStore({'stripe_api_key': 'rk_live_first'});
      await migrateKeychainIfNeeded(local, secure, registry);
      expect(await secure.readApiKey(firstId), 'rk_live_first');

      // Downgrade: an old build writes fresh legacy prefs AND secrets.
      await local.prefs.setString('tip_jar_v1', _legacyTipJar);
      secure.values['stripe_api_key'] = 'rk_live_downgrade';
      secure.values['relay_jar_secret'] = 'sec_downgrade';

      registry = await ensureAccountsRegistry(local);
      await migrateKeychainIfNeeded(local, secure, registry);

      final sweptId =
          registry.accounts.firstWhere((a) => a.id != firstId).id;
      expect(await secure.readApiKey(sweptId), 'rk_live_downgrade');
      expect(await secure.readRelaySecret(sweptId), 'sec_downgrade');
      expect(await secure.readApiKey(firstId), 'rk_live_first',
          reason: 'the first band keeps its own key untouched');
    });

    test('a crash between commit and cleanup never duplicates the account',
        () async {
      final local = await _store(_legacyPrefs());
      final before = await ensureAccountsRegistry(local);
      // Simulate the crash window: legacy keys and the pending id are back
      // as if cleanup never ran, but the registry entry already exists.
      await local.prefs.setString('tip_jar_v1', _legacyTipJar);
      final sweptOnce = (await ensureAccountsRegistry(local))
          .accounts
          .firstWhere((a) => a.id != before.activeId);
      await local.prefs.setString('tip_jar_v1', _legacyTipJar);
      await local.prefs.setString(kMigrationPendingId, sweptOnce.id);

      final after = await ensureAccountsRegistry(local);
      expect(
          after.accounts.where((a) => a.id == sweptOnce.id), hasLength(1),
          reason: 'the replayed pending id must not append a duplicate');
    });

    test('a stale pending id never swallows NEWER downgrade-era data',
        () async {
      final local = await _store(_legacyPrefs());
      final before = await ensureAccountsRegistry(local);
      // Sweep once so an account exists whose id matches the pending id.
      await local.prefs.setString('tip_jar_v1', _legacyTipJar);
      final sweptOnce = (await ensureAccountsRegistry(local))
          .accounts
          .firstWhere((a) => a.id != before.activeId);
      // Downgrade writes DIFFERENT data; the stale pending id resurfaces.
      const newerJar = '{"productId":"prod_9","priceId":"price_9",'
          '"paymentLinkId":"plink_9","url":"https://buy.stripe.com/new",'
          '"currency":"usd","displayName":"Fresh Act","livemode":true}';
      await local.prefs.setString('tip_jar_v1', newerJar);
      await local.prefs.setString(kMigrationPendingId, sweptOnce.id);

      final after = await ensureAccountsRegistry(local);
      final holders = after.accounts
          .where((a) => local.prefs.getString('tip_jar_v1_${a.id}') == newerJar);
      expect(holders, hasLength(1),
          reason: 'the newer bytes must survive in some account');
      expect(local.prefs.getString('tip_jar_v1_${sweptOnce.id}'),
          _legacyTipJar,
          reason: 'the older sweep\'s copy is untouched');
    });

    test('tombstones are processed even after migration completed', () async {
      final local = await _store({});
      await ensureAccountsRegistry(local);
      final registry = await _withBand(local);
      final secure = FakeSecureStore();
      await migrateKeychainIfNeeded(local, secure, registry);
      expect(local.prefs.getBool(kKeychainMigratedFlag), isTrue);

      // A removeAccount with a locked keychain left this behind.
      secure.values['${SecureStore.kApiKeyBase}_acc_removed'] = 'rk_live_x';
      await local.addPendingSecretWipe('acc_removed');
      await migrateKeychainIfNeeded(local, secure, registry);
      expect(
          secure.values.containsKey('${SecureStore.kApiKeyBase}_acc_removed'),
          isFalse,
          reason: 'tombstone processing must run on every boot');
    });
  });

  // The devices already in the wild carry the band the old boot minted. Fixing
  // the mint does nothing for them: the phantom is what their sign-out lands on
  // and what their switcher lists as "Unnamed profile — Not set up yet". It is
  // swept — and the sweep's whole job is knowing what is NOT a phantom.
  group('phantom sweep', () {
    test('drops the unnamed, dataless band — even though it is the ACTIVE one',
        () async {
      // Exactly the state the reporter's device is in: main() minted this band
      // at first boot and made it active, the artist onboarded into a cloud
      // account, and nothing ever came back for it.
      final local = await _store({});
      await local.saveAccountsRegistry(const AccountsRegistry(
        accounts: [BandAccount(id: 'acc_phantom', name: '', createdAtMs: 0)],
        activeId: 'acc_phantom',
      ));
      final swept = await sweepPhantomBands(
          local, FakeSecureStore(), local.readAccountsRegistry()!);

      expect(swept.accounts, isEmpty);
      expect(swept.activeId, '');
      expect(local.readAccountsRegistry()!.accounts, isEmpty,
          reason: 'and it is gone from prefs, not just from this answer');
    });

    test('KEEPS a nameless band that holds data — relay tips are the only '
        'copy of those tips anywhere', () async {
      // A pre-registry install whose jar carried no display name: the boot
      // migration adopts it into a nameless band. Nameless, but the artist's.
      final local = await _store({});
      await local.saveAccountsRegistry(const AccountsRegistry(
        accounts: [BandAccount(id: 'acc_legacy', name: '', createdAtMs: 0)],
        activeId: 'acc_legacy',
      ));
      await local.prefs.setString('relay_history_v1_acc_legacy',
          '[{"id":"tip_1","createdAt":1,"amountMinor":500}]');

      final swept = await sweepPhantomBands(
          local, FakeSecureStore(), local.readAccountsRegistry()!);
      expect(swept.accounts.map((b) => b.id), ['acc_legacy']);
      expect(swept.activeId, 'acc_legacy');
      expect(local.prefs.containsKey('relay_history_v1_acc_legacy'), isTrue);
    });

    test('KEEPS a nameless band whose Stripe key is in the keychain', () async {
      // A reinstall re-adopted the legacy key into the first band it found and
      // the artist never finished the jar. Prefs hold nothing for that band —
      // and the key it holds exists nowhere else on earth.
      final local = await _store({});
      await local.saveAccountsRegistry(const AccountsRegistry(
        accounts: [BandAccount(id: 'acc_keyed', name: '', createdAtMs: 0)],
        activeId: 'acc_keyed',
      ));
      final secure = FakeSecureStore(
          {'${SecureStore.kApiKeyBase}_acc_keyed': 'rk_live_only_copy'});

      final swept = await sweepPhantomBands(
          local, secure, local.readAccountsRegistry()!);
      expect(swept.accounts.map((b) => b.id), ['acc_keyed']);
      expect(await secure.readApiKey('acc_keyed'), 'rk_live_only_copy');
    });

    test('KEEPS a nameless band holding only a relay secret', () async {
      final local = await _store({});
      await local.saveAccountsRegistry(const AccountsRegistry(
        accounts: [BandAccount(id: 'acc_relay', name: '', createdAtMs: 0)],
        activeId: 'acc_relay',
      ));
      final secure = FakeSecureStore(
          {'${SecureStore.kRelaySecretBase}_acc_relay': 'sec_only_copy'});

      final swept = await sweepPhantomBands(
          local, secure, local.readAccountsRegistry()!);
      expect(swept.accounts.map((b) => b.id), ['acc_relay']);
    });

    test('a locked keychain deletes NOTHING — it proves nothing', () async {
      final local = await _store({});
      await local.saveAccountsRegistry(const AccountsRegistry(
        accounts: [BandAccount(id: 'acc_phantom', name: '', createdAtMs: 0)],
        activeId: 'acc_phantom',
      ));
      final secure = FakeSecureStore()..failing = true;

      final swept = await sweepPhantomBands(
          local, secure, local.readAccountsRegistry()!);
      expect(swept.accounts.map((b) => b.id), ['acc_phantom'],
          reason: 'a keychain that cannot answer is not a keychain that is '
              'empty; the sweep retries at the next boot');
      expect(local.readAccountsRegistry()!.accounts, hasLength(1));
    });

    test('a NAMED band is never touched, however empty', () async {
      // The artist typed that name. An abandoned named band is the discard
      // offer's business — and the discard offer ASKS.
      final local = await _store({});
      await local.saveAccountsRegistry(const AccountsRegistry(
        accounts: [BandAccount(id: 'acc_named', name: 'Half Done',
            createdAtMs: 0)],
        activeId: 'acc_named',
      ));
      final swept = await sweepPhantomBands(
          local, FakeSecureStore(), local.readAccountsRegistry()!);
      expect(swept.accounts.map((b) => b.id), ['acc_named']);
    });

    test('sweeps the phantom out from beside a real band, and lands the '
        'active id on the survivor', () async {
      final local = await _store({});
      await local.saveAccountsRegistry(const AccountsRegistry(
        accounts: [
          BandAccount(id: 'acc_real', name: 'The Foxes', createdAtMs: 0),
          BandAccount(id: 'acc_phantom', name: '', createdAtMs: 1),
        ],
        activeId: 'acc_phantom',
      ));
      final swept = await sweepPhantomBands(
          local, FakeSecureStore(), local.readAccountsRegistry()!);
      expect(swept.accounts.map((b) => b.id), ['acc_real']);
      expect(swept.activeId, 'acc_real',
          reason: 'an activeId naming a swept band opens nothing');
    });

    test('a registry with nothing to sweep is not rewritten', () async {
      final local = await _store({});
      final registry = await _withBand(local);
      final swept =
          await sweepPhantomBands(local, FakeSecureStore(), registry);
      expect(swept.accounts.map((b) => b.id), ['acc_first']);
    });
  });

  test('purging a pristine band leaves no empty history key behind',
      () async {
    final local = await _store({});
    final registry = await _withBand(local);
    await local.purgeSimulatedData(registry.activeId);
    expect(local.accountHasData(registry.activeId), isFalse,
        reason: 'an empty-history write would block abandoned-band GC');
  });

  test('band settings JSON round-trips through the store', () async {
    final local = await _store({});
    final registry = await _withBand(local);
    final id = registry.activeId;
    final band = local.readBandSettings(id);
    await local.saveBandSettings(id, band.copyWith(lastGoalMinor: 4200));
    expect(local.readBandSettings(id).lastGoalMinor, 4200);
    expect(jsonDecode(local.prefs.getString('band_settings_v1_$id')!),
        containsPair('lastGoalMinor', 4200));
  });
}
