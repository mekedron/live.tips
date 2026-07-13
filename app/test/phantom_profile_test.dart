import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/migrations.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/features/onboarding/welcome_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// The journey no single test used to cross — and the reason a green suite
/// could not see #50. The widget suite never runs `main()`: every test builds
/// its own registry and hands it to the app, so the boot-time mint was not
/// merely untested, it was written into the fixtures as the expected starting
/// state. And the bug needs three boundaries in one run:
///
/// **boot** (which minted a nameless local band) → **cloud onboarding** (which
/// never touches it: the profile is minted into the cloud repository) →
/// **sign-out** (which lands the device back on the local profile, where one
/// band is not a choice, so the app opens it).
///
/// So this test boots the way `main()` boots — `ensureAccountsRegistry` over
/// genuinely empty prefs — and then walks the artist through it.
const _artist = AuthUser(
  uid: 'uid_artist',
  kind: AccountKind.google,
  displayName: 'Ana',
  email: 'ana@example.com',
);

/// A fresh install, booted exactly as `main()` boots it.
Future<LocalStore> _freshInstall() async {
  SharedPreferences.setMockInitialValues({});
  final local = LocalStore(await SharedPreferences.getInstance());
  await ensureAccountsRegistry(local);
  return local;
}

ProviderContainer _container(
  LocalStore local,
  FakeFirebaseFirestore db,
  FakeAuthService auth,
) {
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    initialRelaySecretProvider.overrideWithValue(null),
    firestoreProvider.overrideWithValue(db),
    authServiceProvider.overrideWithValue(auth),
    relayClientProvider.overrideWithValue(fakeRelayClient(FakeCallables())),
    tipSourceFactoryProvider.overrideWithValue(
        ({required demo, required apiKey, required jar}) => NullTipSource()),
    relayChannelFactoryProvider.overrideWithValue(
        ({required demo, required jar, required secret}) => null),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install → Google sign-in → the first profile is named → sign out: '
      'the device is holding NOTHING it was not given (#50)', () async {
    final local = await _freshInstall();
    expect(local.readAccountsRegistry()!.accounts, isEmpty,
        reason: 'the boot invents no band — this is the mint that was found');

    final container = _container(
        local, FakeFirebaseFirestore(), FakeAuthService(nextUser: _artist));
    container.read(appStateProvider);
    await pumpEventQueue();

    // Onboarding, the cloud path: sign in, then NAME the first profile — the
    // one birthplace of a band (#44).
    await container.read(authControllerProvider.notifier).signInWithGoogle();
    await pumpEventQueue();
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        _artist.uid);
    expect(container.read(activeProfileRenderProvider), ProfileRender.create,
        reason: 'a fresh cloud account has no profile, and none is invented');

    final notifier = container.read(appStateProvider.notifier);
    final created = await notifier.createFirstBand();
    await notifier.renameBand('The Foxes');
    await pumpEventQueue();
    expect(container.read(appStateProvider).accountId, created!.id);

    // The profile went into the CLOUD account. The local registry is exactly
    // as the artist left it: empty. This is the assertion the old code failed
    // — the local registry held one nameless band, minted at boot, that the
    // whole cloud path never looked at.
    expect(local.readAccountsRegistry()!.accounts, isEmpty,
        reason: 'a cloud profile is not a local band');

    // Sign out — the moment the artist met the phantom.
    await container.read(signOutProvider)();
    await pumpEventQueue();

    expect(local.readAccountsRegistry()!.accounts, isEmpty,
        reason: 'no profile appears on its own; the app never creates one '
            'behind the artist\'s back (#26)');
    expect(container.read(appStateProvider).accountId, '',
        reason: 'the device opens no band, because it has none');
    expect(container.read(activeProfileRenderProvider), ProfileRender.create,
        reason: 'and "no profile" is a state the app renders, not a hole it '
            'plugs with a fabricated band');
  });

  testWidgets('an upgrading device drops the phantom at boot and ASKS — it does '
      'not open a profile the artist never made', (tester) async {
    // The reporter's device, on the build before this one: the local registry
    // holds the band main() minted at first boot — unnamed, empty, and ACTIVE
    // (main() made it so, and the cloud sign-in never came back to it). Fixing
    // the mint does nothing for a device that already has one.
    SharedPreferences.setMockInitialValues({});
    final local = LocalStore(await SharedPreferences.getInstance());
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [BandAccount(id: 'acc_phantom', name: '', createdAtMs: 0)],
      activeId: 'acc_phantom',
    ));

    // Boot, exactly as main() boots: the sweep runs before the first frame.
    final secure = FakeSecureStore();
    await sweepPhantomBands(local, secure, local.readAccountsRegistry()!);
    expect(local.readAccountsRegistry()!.accounts, isEmpty);

    await tester.binding.setSurfaceSize(const Size(700, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(local),
          secureStoreProvider.overrideWithValue(secure),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The device holds nothing, so it says so and asks. What it must NOT be is
    // a shell built around a band nobody created — the "Unnamed profile / Not
    // set up yet" row of the reporter's screenshot.
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Unnamed profile'), findsNothing);
  });
}
