import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/onboarding/account_name_screen.dart';
import 'package:live_tips/features/onboarding/account_step_screen.dart';
import 'package:live_tips/features/onboarding/profile_pick_screen.dart';
import 'package:live_tips/features/onboarding/welcome_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Onboarding, walked as a GRAPH — pushed routes over a live RootGate, and the
/// Back arrow pressed at every step (#41, #46).
///
/// Every screen of this flow had a test, and every one of those tests pumped
/// the screen inside its own ProviderScope, tapped forward, and asserted the
/// next widget. So the root could never change under a pushed route — which is
/// exactly the mechanism: the account step signs the artist in ON THE TAP and
/// replaces itself, and the Back arrow left behind on the account-name screen
/// popped not to the question the artist came from, but into the world their
/// tap had just created (an account they were only trying out, a picker with no
/// way back to onboarding). Here the whole app is pumped, so the flip is real.
const _guest = AuthUser(uid: 'uid_guest', kind: AccountKind.anonymous);

Future<ProviderContainer> _bootFresh(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(700, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final local = LocalStore(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(local),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        authServiceProvider
            .overrideWithValue(FakeAuthService(nextUser: _guest)),
        // The guest account's cloud mirror: warm, and empty — so the root the
        // sign-in rebuilds is the picker's create form, exactly as on a phone.
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
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

/// Fresh install → Get started → the account step → "Anonymous cloud account" →
/// through the what-you-lose confirmation: the guest account exists from here
/// on, and the name step is on screen.
Future<ProviderContainer> _signInAsGuest(WidgetTester tester) async {
  final container = await _bootFresh(tester);
  expect(find.byType(WelcomeScreen), findsOneWidget);

  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Anonymous cloud account'));
  await tester.pumpAndSettle();
  // Guest is a downgrade, so it asks first — and the filled button is the one
  // that backs OUT. Taking it here would be the artist changing their mind.
  await tester.tap(find.text('Continue anyway'));
  await tester.pumpAndSettle();

  expect(find.byType(AccountNameScreen), findsOneWidget);
  expect(container.read(authControllerProvider).user?.uid, _guest.uid);
  return container;
}

void main() {
  testWidgets('the sign-in flips the root under the pushed step — and the step '
      'stays exactly where it is', (tester) async {
    final container = await _signInAsGuest(tester);

    // The root is no longer Welcome: the account exists, it has no profile, and
    // RootGate has rebuilt itself into the picker's create form UNDER the name
    // step. The pushed route does not care, and must not.
    expect(container.read(activeProfileRenderProvider), ProfileRender.create);
    expect(find.byType(AccountNameScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets('the account-name step offers no Back arrow that lies',
      (tester) async {
    await _signInAsGuest(tester);

    // Flutter's automatic leading is gone: it would pop into the rebuilt root,
    // out of onboarding, signed into an account the artist was trying out.
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Not this account — sign out and go back'), findsOneWidget);
  });

  testWidgets('"Not this account" undoes the sign-in and asks the question '
      'again', (tester) async {
    final container = await _signInAsGuest(tester);

    await tester.tap(find.text('Not this account — sign out and go back'));
    await tester.pumpAndSettle();

    // The question, not the picker — and nothing was left signed in behind it.
    expect(find.byType(AccountStepScreen), findsOneWidget);
    expect(find.byType(ProfilePickScreen), findsNothing);
    expect(container.read(authControllerProvider).user, isNull);
    expect(
        container
            .read(accountsDirectoryProvider)
            .accounts
            .any((a) => !a.isLocal),
        isFalse,
        reason: 'the account left the device with the session (#31)');
    // …and the pitch is under it again: the root is Welcome, so the demo, the
    // venue link and the account choice are all reachable.
    expect(container.read(deviceIsSetUpProvider), isFalse);

    // The artist answers differently this time.
    await tester.tap(find.text('Continue without an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountStepScreen), findsNothing);
  });

  testWidgets('the system Back (Android, the iOS edge-swipe) runs the same '
      'undo — it does not pop into the new world', (tester) async {
    final container = await _signInAsGuest(tester);

    // The pop every phone can fire whatever the app bar shows.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AccountStepScreen), findsOneWidget);
    expect(find.byType(ProfilePickScreen), findsNothing);
    expect(container.read(authControllerProvider).user, isNull);
  });

  testWidgets('the Settings rename keeps its ordinary Back arrow',
      (tester) async {
    // The same screen, reached from Settings, is not a commit point: it saves
    // and pops, and popping is all Back has ever meant there.
    await tester.binding.setSurfaceSize(const Size(700, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final local = LocalStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(local),
          secureStoreProvider.overrideWithValue(FakeSecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
        child: MaterialApp(
          localizationsDelegates: kTestL10nDelegates,
          locale: const Locale('en'),
          theme: buildLightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountNameScreen(rename: true),
                  ),
                ),
                child: const Text('rename'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('rename'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountNameScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Not this account — sign out and go back'), findsNothing);
  });
}
