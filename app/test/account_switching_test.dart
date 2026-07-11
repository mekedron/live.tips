import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/band_settings.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip_jar.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/onboarding_draft.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/seen_ping.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const _jarA = TipJar(
  productId: 'prod_a',
  priceId: 'price_a',
  paymentLinkId: 'plink_a',
  url: 'https://buy.stripe.com/a',
  currency: 'eur',
  displayName: 'Solo Act',
  livemode: true,
);

const _relayB = RelayJar(
  jarId: 'jar_b',
  tipUrl: 'https://live.tips/t/jar_b',
  artistName: 'The Midnight Foxes',
  currency: 'dkk',
  revolutUsername: 'foxes',
  createdAtMs: 0,
);

/// Two configured bands: A is Stripe (eur), B is relay-only (dkk).
Future<(LocalStore, FakeSecureStore)> _twoBands() async {
  SharedPreferences.setMockInitialValues({});
  final local = LocalStore(await SharedPreferences.getInstance());
  await local.saveAccountsRegistry(const AccountsRegistry(
    accounts: [
      BandAccount(id: 'acc_a', name: 'Solo Act', createdAtMs: 0),
      BandAccount(id: 'acc_b', name: 'The Midnight Foxes', createdAtMs: 1),
    ],
    activeId: 'acc_a',
  ));
  await local.saveTipJar('acc_a', _jarA);
  await local.saveBandSettings(
      'acc_a', const BandSettings(lastGoalMinor: 50000));
  await local.saveRelayJar('acc_b', _relayB);
  await local.saveBandSettings(
      'acc_b', const BandSettings(lastGoalMinor: 7000));
  final secure = FakeSecureStore({
    '${SecureStore.kApiKeyBase}_acc_a': 'rk_live_a',
    '${SecureStore.kRelaySecretBase}_acc_b': 'sec_b',
  });
  return (local, secure);
}

ProviderContainer _container(LocalStore local, SecureStore secure,
    {String? initialApiKey}) {
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(secure),
    initialApiKeyProvider.overrideWithValue(initialApiKey),
    initialRelaySecretProvider.overrideWithValue(null),
    tipSourceFactoryProvider.overrideWithValue(
        ({required demo, required apiKey, required jar}) =>
            NullTipSource()),
    relayChannelFactoryProvider.overrideWithValue(
        ({required demo, required jar, required secret}) => null),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('switchAccount loads the other band\'s key, jars and settings',
      () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    final notifier = container.read(appStateProvider.notifier);

    var app = container.read(appStateProvider);
    expect(app.accountId, 'acc_a');
    expect(app.displayName, 'Solo Act');
    expect(app.band.lastGoalMinor, 50000);

    expect(await notifier.switchAccount('acc_b'), isTrue);
    app = container.read(appStateProvider);
    expect(app.accountId, 'acc_b');
    expect(app.apiKey, isNull);
    expect(app.relayJar?.jarId, 'jar_b');
    expect(app.relaySecret, 'sec_b');
    expect(app.band.lastGoalMinor, 7000);
    expect(app.displayName, 'The Midnight Foxes');
    expect(app.activeQrUrl, _relayB.tipUrl);
    expect(local.readAccountsRegistry()?.activeId, 'acc_b',
        reason: 'the next boot opens on the switched band');
    expect(app.switching, isFalse);
  });

  test('switch rebinds the stored-session and relay-history providers',
      () async {
    final (local, secure) = await _twoBands();
    await local.saveActiveSession(
      'acc_b',
      LiveSession(
        id: 'ses_b',
        startedAt: DateTime(2026, 7, 1, 20),
        currency: 'dkk',
        goalMinor: 7000,
      ),
      null,
    );
    final container = _container(local, secure, initialApiKey: 'rk_live_a');

    expect(container.read(storedSessionProvider), isNull,
        reason: 'band A has no resumable session');
    await container.read(appStateProvider.notifier).switchAccount('acc_b');
    expect(container.read(storedSessionProvider)?.id, 'ses_b',
        reason: 'band B\'s crash-recovery slot surfaces after the switch');
  });

  test('switching is refused while a live session runs', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    final notifier = container.read(appStateProvider.notifier);

    await container
        .read(liveSessionProvider.notifier)
        .start(goalMinor: 1000);
    expect(container.read(liveSessionProvider), isNotNull);

    expect(await notifier.switchAccount('acc_b'), isFalse);
    expect(container.read(appStateProvider).accountId, 'acc_a');
    expect(await notifier.addAccount(), isNull);
    expect(await notifier.removeAccount('acc_b'), isFalse);

    await container.read(liveSessionProvider.notifier).stop();
    expect(await notifier.switchAccount('acc_b'), isTrue);
  });

  test('sessions land in the band that started them, not the visible one',
      () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');

    await container
        .read(liveSessionProvider.notifier)
        .start(goalMinor: 1000);
    await container.read(liveSessionProvider.notifier).stop();

    expect(local.readSessionHistory('acc_a'), hasLength(1));
    expect(local.readSessionHistory('acc_b'), isEmpty);
  });

  test('addAccount creates an empty active band and clears the draft',
      () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    container
        .read(onboardingDraftProvider.notifier)
        .set(const OnboardingDraft());

    final account =
        await container.read(appStateProvider.notifier).addAccount();
    expect(account, isNotNull);
    final app = container.read(appStateProvider);
    expect(app.accountId, account!.id);
    expect(app.connected, isFalse, reason: 'nothing configured yet');
    expect(app.accounts, hasLength(3));
    expect(container.read(onboardingDraftProvider), isNull);
    expect(local.readAccountsRegistry()?.activeId, account.id);
  });

  test('an abandoned empty band is collected on switch-away', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    final notifier = container.read(appStateProvider.notifier);

    final ghost = await notifier.addAccount();
    expect(container.read(appStateProvider).accounts, hasLength(3));

    await notifier.switchAccount('acc_a');
    final app = container.read(appStateProvider);
    expect(app.accounts, hasLength(2));
    expect(app.accounts.any((a) => a.id == ghost!.id), isFalse);
    expect(local.readAccountsRegistry()?.accounts, hasLength(2));
  });

  test('a band with any data survives switch-away untouched', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    final notifier = container.read(appStateProvider.notifier);

    final fresh = await notifier.addAccount();
    // The user got as far as saving a goal — that's data.
    await notifier.updateBand(const BandSettings(lastGoalMinor: 123));
    await notifier.switchAccount('acc_a');
    expect(
        container
            .read(appStateProvider)
            .accounts
            .any((a) => a.id == fresh!.id),
        isTrue);
  });

  test('keychain doubt keeps the band (no GC on error)', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    final notifier = container.read(appStateProvider.notifier);

    final ghost = await notifier.addAccount();
    secure.failing = true;
    await notifier.switchAccount('acc_a');
    expect(
        container
            .read(appStateProvider)
            .accounts
            .any((a) => a.id == ghost!.id),
        isTrue,
        reason: 'a transiently unreadable keychain must never trigger GC');
  });

  test('removeAccount wipes the band and activates the survivor', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');

    expect(
        await container
            .read(appStateProvider.notifier)
            .removeAccount('acc_a'),
        isTrue);
    final app = container.read(appStateProvider);
    expect(app.accountId, 'acc_b');
    expect(app.relayJar?.jarId, 'jar_b');
    expect(app.relaySecret, 'sec_b');
    expect(local.accountHasData('acc_a'), isFalse);
    expect(secure.values.containsKey('${SecureStore.kApiKeyBase}_acc_a'),
        isFalse);
    expect(local.readAccountsRegistry()?.accounts, hasLength(1));
  });

  test('removing the last band leaves a fresh empty one', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    final notifier = container.read(appStateProvider.notifier);

    await notifier.removeAccount('acc_b');
    await notifier.removeAccount('acc_a');
    final app = container.read(appStateProvider);
    expect(app.accounts, hasLength(1));
    expect(app.connected, isFalse);
    expect(app.accountId, isNot(anyOf('acc_a', 'acc_b')));
  });

  test('cancelStripeSetup removes only the key', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    final notifier = container.read(appStateProvider.notifier);

    await notifier.cancelStripeSetup();
    final app = container.read(appStateProvider);
    expect(app.apiKey, isNull);
    expect(app.tipJar, isNotNull, reason: 'the jar record stays');
    expect(secure.values.containsKey('${SecureStore.kApiKeyBase}_acc_a'),
        isFalse);
  });

  test('renameBand updates registry and both jars locally', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');

    await container.read(appStateProvider.notifier).renameBand('Nightbirds');
    final app = container.read(appStateProvider);
    expect(app.displayName, 'Nightbirds');
    expect(app.tipJar?.displayName, 'Nightbirds');
    expect(local.readTipJar('acc_a')?.displayName, 'Nightbirds');
    expect(local.readAccountsRegistry()?.accounts.first.name, 'Nightbirds');
  });

  test('mid-await switch keeps a mutator write in its own band', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    final notifier = container.read(appStateProvider.notifier);

    // Fire the band-settings write and the switch "simultaneously" — the
    // write must land in acc_a's slot and must not leak into the new state.
    final write =
        notifier.updateBand(const BandSettings(lastGoalMinor: 999));
    final switched = notifier.switchAccount('acc_b');
    await Future.wait([write, switched]);

    expect(local.readBandSettings('acc_a').lastGoalMinor, 999);
    expect(local.readBandSettings('acc_b').lastGoalMinor, 7000);
    expect(container.read(appStateProvider).band.lastGoalMinor,
        anyOf(7000, 999));
  });

  test('tapping the already-active band while in demo exits demo', () async {
    final (local, secure) = await _twoBands();
    final container = _container(local, secure, initialApiKey: 'rk_live_a');
    final notifier = container.read(appStateProvider.notifier);

    notifier.enterDemo();
    expect(container.read(appStateProvider).demo, isTrue);
    expect(await notifier.switchAccount('acc_a'), isTrue);
    expect(container.read(appStateProvider).demo, isFalse,
        reason: 'picking a band in the switcher always leaves demo');
  });

  test('keepalive pings every band\'s jar, not just the active one',
      () async {
    final (local, secure) = await _twoBands();
    final service = SeenPingService();
    expect(service.isDue(store: local, accountId: 'acc_b'), isTrue);
    await local.writeRelaySeenAt(
        'acc_b', DateTime.now().millisecondsSinceEpoch);
    expect(service.isDue(store: local, accountId: 'acc_b'), isFalse);
    expect(service.isDue(store: local, accountId: 'acc_a'), isTrue,
        reason: 'seen markers are independent per band');
  });
}
