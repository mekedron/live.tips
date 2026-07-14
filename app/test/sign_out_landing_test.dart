import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/features/onboarding/profile_pick_screen.dart';
import 'package:live_tips/features/shell/app_shell.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// The owner tapped "Sign out" of a cloud account with a local profile beside
/// it, and the app dropped him — with no feedback — straight onto the local
/// profile's HOME. He tapped an action and got some other profile's home. The
/// rule: a user-initiated account EXIT must land on the chooser, never
/// auto-open the fallback account's profile ([AppStateNotifier
/// .holdPickerAfterAccountExit]).
///
/// A cold boot is a different event — a single-account single-profile device
/// still opens directly, and the last test here guards that the fix did not
/// turn every launch into a chooser.
const _uid = 'uid_cloud';

const _cloudUser = AuthUser(
  uid: _uid,
  kind: AccountKind.google,
  displayName: 'Casey',
  email: 'casey@example.com',
);

RelayJar _jar(String id, String name) => RelayJar(
      jarId: id,
      tipUrl: 'https://live.tips/t/$id',
      artistName: name,
      currency: 'eur',
      revolutUsername: id,
      createdAtMs: 0,
    );

Future<LocalStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

/// A device with [bands] CONFIGURED local profiles (each with a relay jar, so
/// the device reads as set up and its home is a real shell) — the exact state
/// the owner's device was in behind the cloud account he was signed into.
/// [cloud] signs a cloud account in and makes it the active one.
Future<LocalStore> _device({
  required List<String> bands,
  required bool cloud,
}) async {
  final local = await _store();
  await local.saveAccountsRegistry(AccountsRegistry(
    accounts: [
      for (final name in bands)
        BandAccount(id: 'local_$name', name: name, createdAtMs: 0),
    ],
    activeId: bands.isEmpty ? '' : 'local_${bands.first}',
  ));
  for (final name in bands) {
    await local.saveRelayJar('local_$name', _jar('local_$name', name));
  }
  if (cloud) {
    await local.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(const AppAccount(
            id: _uid,
            name: 'Casey',
            kind: AccountKind.google,
            email: 'casey@example.com',
          ))
          .withActive(_uid),
    );
  }
  return local;
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  LocalStore local, {
  AuthService? auth,
  FakeFirebaseFirestore? db,
}) async {
  await tester.binding.setSurfaceSize(const Size(700, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(local),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        initialRelaySecretProvider.overrideWithValue(null),
        if (auth != null) authServiceProvider.overrideWithValue(auth),
        if (db != null) firestoreProvider.overrideWithValue(db),
        tipSourceFactoryProvider.overrideWithValue(
            ({required demo, required apiKey, required jar}) =>
                NullTipSource()),
        relayChannelFactoryProvider.overrideWithValue(
            ({required demo, required jar, required secret}) => null),
      ],
      child: const LiveTipsApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
      tester.element(find.byType(LiveTipsApp)),
      listen: false);
}

void main() {
  testWidgets(
      'sign out of a cloud account → the ONE local profile is NOT auto-opened; '
      'the device lands on the chooser', (tester) async {
    final local = await _device(bands: ['Local Band'], cloud: true);
    final container = await _pump(tester, local,
        auth: FakeAuthService(user: _cloudUser), db: FakeFirebaseFirestore());

    await container.read(signOutProvider)();
    await tester.pumpAndSettle();

    // The active account fell back to the local mode — but its single profile
    // is NOT opened under the artist.
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        kLocalAccountId);
    expect(container.read(appStateProvider).accountId, isEmpty,
        reason: 'a sign-out resolves to the chooser, not a fallback profile');
    expect(container.read(activeProfileRenderProvider), ProfileRender.pick);

    // And the landing is legibly the chooser: the local account is named, the
    // profile it holds is a row the artist can pick — not a bare home.
    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text('On this device'), findsWidgets);
    expect(find.text('Local Band'), findsOneWidget);
  });

  testWidgets(
      'sign out with SEVERAL local profiles → the chooser, not a guessed one',
      (tester) async {
    final local =
        await _device(bands: ['The Foxes', 'Duo Sundays'], cloud: true);
    final container = await _pump(tester, local,
        auth: FakeAuthService(user: _cloudUser), db: FakeFirebaseFirestore());

    await container.read(signOutProvider)();
    await tester.pumpAndSettle();

    expect(container.read(appStateProvider).accountId, isEmpty);
    expect(container.read(activeProfileRenderProvider), ProfileRender.pick);
    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    // Both profiles are on the chooser, as rows — the app named neither.
    expect(find.text('The Foxes'), findsOneWidget);
    expect(find.text('Duo Sundays'), findsOneWidget);
  });

  testWidgets(
      'GUARD: a single-account single-profile COLD BOOT still opens directly',
      (tester) async {
    // No cloud account, one configured local profile, a fresh launch: opening
    // it is right — a chooser on every launch of a one-profile device would be
    // the over-correction. Passes before and after the fix; it exists to keep
    // the fix from becoming a blunt hammer.
    final local = await _device(bands: ['Solo Act'], cloud: false);
    final container = await _pump(tester, local);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ProfilePickScreen), findsNothing);
    expect(container.read(appStateProvider).accountId, 'local_Solo Act');
    expect(container.read(activeProfileRenderProvider), ProfileRender.band);
  });
}
