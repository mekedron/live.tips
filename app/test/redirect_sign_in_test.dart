import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/pending_redirect.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/features/account/redirect_sign_in_gate.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/onboarding_draft.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// The iOS bug, and the shape of the fix.
///
/// A popup sign-in is dead on the web: Mobile Safari blocks it, and inside an
/// installed PWA it does not even fail — it hangs, forever, with a spinner and
/// no error. So the web signs in by REDIRECT, which reloads the whole app: the
/// navigation stack, the auth controller and the onboarding draft all die
/// mid-flow, and everything the return leg needs has to have been written down
/// first.
///
/// These tests cover both halves of that trip — the departure (what gets
/// recorded) and the return (what a result, a cancellation and a failure each
/// do) — including the one that has burned us before: a LINK must come back as
/// an upgrade of the guest account, never as a second account beside it.
///
/// What they CANNOT cover: Safari itself. No fake reproduces a popup blocker or
/// a standalone PWA's window context; only a real iPhone can prove the redirect
/// actually leaves and lands.

const _google = AuthUser(
  uid: 'uid_casey',
  kind: AccountKind.google,
  displayName: 'Casey',
  email: 'casey@example.com',
);

const _guest = AuthUser(uid: 'uid_guest', kind: AccountKind.anonymous);

const _guestEntry = AppAccount(
  id: 'uid_guest',
  name: 'Nightbirds',
  kind: AccountKind.anonymous,
);

/// The guest, upgraded: SAME uid, now carrying a real provider. That identity
/// is the whole point of linkWithRedirect — a new uid would leave every band
/// the guest owns behind.
const _upgraded = AuthUser(
  uid: 'uid_guest',
  kind: AccountKind.google,
  displayName: 'Casey',
  email: 'casey@example.com',
);

Future<({ProviderContainer container, LocalStore local, FakeAuthService auth})>
    _harness({
  AuthUser? user,
  AuthUser? redirectResult,
  AuthUser? restoredAfterRedirect,
  Set<OAuthProviderKind> linkedProviders = const {},
  Object? redirectError,
  Object? redirectStartError,
  PendingRedirect? pending,
  AccountsDirectory? directory,
}) async {
  final local = await seededStore();
  if (directory != null) await local.saveAccountsDirectory(directory);
  if (pending != null) await local.savePendingRedirect(pending);
  final auth = FakeAuthService(user: user)
    ..redirectResult = redirectResult
    ..restoredAfterRedirect = restoredAfterRedirect
    ..redirectError = redirectError
    ..redirectStartError = redirectStartError;
  auth.linkedProviders.addAll(linkedProviders);
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    authServiceProvider.overrideWithValue(auth),
    // What kIsWeb resolves to in the browser — the only reason this provider
    // exists is so the redirect machinery is testable off it.
    webRedirectSignInProvider.overrideWithValue(true),
  ]);
  addTearDown(container.dispose);
  return (container: container, local: local, auth: auth);
}

void main() {
  test('the web never opens a popup — the sign-in leaves the page, and every '
      'thing the return leg needs is written down first', () async {
    final h = await _harness();
    // Mid-onboarding: a draft in memory, and two prelude steps already walked.
    h.container.read(onboardingDraftProvider.notifier).set(const OnboardingDraft(
          name: 'Nightbirds',
          currency: 'dkk',
          thankYouMessage: 'thank you!',
          methods: {TipMethod.stripe, TipMethod.revolut},
          revolutUsername: 'nightbirds',
        ));
    h.container.read(onboardingPreludeProvider.notifier).markNameStep();

    final user = await h.container
        .read(authControllerProvider.notifier)
        .signInWithGoogle(origin: RedirectOrigin.onboarding);

    // No user, no popup: the page is on its way to Google.
    expect(user, isNull);
    expect(h.auth.redirectStarts, [(kind: OAuthProviderKind.google, link: false)]);

    final record = h.local.readPendingRedirect();
    expect(record, isNotNull);
    expect(record!.link, isFalse);
    expect(record.provider, 'google');
    expect(record.origin, RedirectOrigin.onboarding);
    expect(record.prelude, 2);
    // The half-filled band setup survives the reload — in memory it would not.
    final draft = OnboardingDraft.fromJson(record.draft!);
    expect(draft.name, 'Nightbirds');
    expect(draft.currency, 'dkk');
    expect(draft.thankYouMessage, 'thank you!');
    expect(draft.methods, {TipMethod.stripe, TipMethod.revolut});
    expect(draft.revolutUsername, 'nightbirds');
  });

  test('a redirect result comes back as a fully adopted account', () async {
    final h = await _harness(
      redirectResult: _google,
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.onboarding,
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume, isNotNull);
    expect(resume!.user?.uid, 'uid_casey');
    expect(resume.error, isNull);
    expect(resume.record.origin, RedirectOrigin.onboarding);

    final state = h.container.read(authControllerProvider);
    expect(state.user?.uid, 'uid_casey');
    expect(state.busy, isFalse, reason: 'the spinner must end');
    expect(state.error, isNull);

    // The same adoption a native sign-in performs: in the directory, active.
    final directory = h.container.read(accountsDirectoryProvider);
    expect(directory.contains('uid_casey'), isTrue);
    expect(directory.activeAccountId, 'uid_casey');
    // Consumed exactly once.
    expect(h.local.readPendingRedirect(), isNull);
  });

  test('the sign-in landed but the redirect result came back EMPTY — the '
      'account must still appear', () async {
    // Reported from an iPhone: Google finished, the app came back, and no
    // cloud account existed. getRedirectResult() lies by omission — WebKit
    // does not always hand back the sessionStorage marker that says a redirect
    // was in flight, so the result is empty even though the SDK completed the
    // sign-in and is holding the user. Reading that as "nothing happened" threw
    // a successful sign-in on the floor, silently: no error, no spinner, no
    // account.
    final h = await _harness(
      redirectResult: null,
      restoredAfterRedirect: _google,
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.settings,
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume?.user?.uid, 'uid_casey',
        reason: 'the instance has the user; an empty result does not undo that');
    final state = h.container.read(authControllerProvider);
    expect(state.user?.uid, 'uid_casey');
    expect(state.busy, isFalse);
    expect(state.error, isNull);
    final directory = h.container.read(accountsDirectoryProvider);
    expect(directory.contains('uid_casey'), isTrue,
        reason: 'this is the bug: the account never appeared in Settings');
    expect(directory.activeAccountId, 'uid_casey');
    expect(h.local.readPendingRedirect(), isNull);
  });

  test('an empty result on a LINK is only believed when the provider really '
      'attached', () async {
    // The same fallback, but a guest is signed in ALREADY — so currentUser is
    // non-null whether or not the upgrade landed. Taking it as success would
    // tell someone their guest account is now a Google account when it is not.
    final guest = const AuthUser(uid: 'uid_guest', kind: AccountKind.anonymous);
    final h = await _harness(
      user: guest,
      redirectResult: null,
      restoredAfterRedirect: guest, // still a guest: nothing attached
      linkedProviders: const {}, // the link did NOT land
      directory: AccountsDirectory.initial()
          .withAccount(const AppAccount(
              id: 'uid_guest', name: 'Guest', kind: AccountKind.anonymous))
          .withActive('uid_guest'),
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: true,
        uid: 'uid_guest',
        origin: RedirectOrigin.settings,
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume?.user, isNull,
        reason: 'an unattached provider is not a successful upgrade');
    final directory = h.container.read(accountsDirectoryProvider);
    final cloud = directory.accounts.where((a) => !a.isLocal);
    expect(cloud.length, 1, reason: 'no second account was conjured');
    expect(cloud.single.id, 'uid_guest');
    expect(cloud.single.kind, AccountKind.anonymous,
        reason: 'still a guest — we must not claim the upgrade happened');
    expect(h.container.read(authControllerProvider).busy, isFalse);
  });

  test('a LINK comes back as the guest upgraded in place — not as a second '
      'account, and never as a stranded guest', () async {
    final h = await _harness(
      user: _guest,
      redirectResult: _upgraded,
      directory: AccountsDirectory.initial()
          .withAccount(_guestEntry)
          .withActive('uid_guest'),
      pending: const PendingRedirect(
        appName: '[DEFAULT]',
        provider: 'google',
        link: true,
        uid: 'uid_guest',
        origin: RedirectOrigin.settings,
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume!.record.link, isTrue);
    final state = h.container.read(authControllerProvider);
    expect(state.user?.uid, 'uid_guest', reason: 'the uid must not change — '
        'every band the guest owns hangs off it');
    expect(state.user?.kind, AccountKind.google);
    expect(state.busy, isFalse);

    final directory = h.container.read(accountsDirectoryProvider);
    final cloud = directory.accounts.where((a) => !a.isLocal).toList();
    expect(cloud.length, 1, reason: 'a link upgrades; it does not add');
    expect(cloud.single.id, 'uid_guest');
    expect(cloud.single.kind, AccountKind.google);
    // The name the artist chose beats the provider's.
    expect(cloud.single.name, 'Nightbirds');
    expect(directory.activeAccountId, 'uid_guest');
  });

  test('a cancelled link leaves the guest exactly where it was', () async {
    final h = await _harness(
      user: _guest,
      // Backed out of Google's page: no result, no error.
      directory: AccountsDirectory.initial()
          .withAccount(_guestEntry)
          .withActive('uid_guest'),
      pending: const PendingRedirect(
        appName: '[DEFAULT]',
        provider: 'google',
        link: true,
        uid: 'uid_guest',
        origin: RedirectOrigin.settings,
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume!.user, isNull);
    expect(resume.error, isNull);
    final state = h.container.read(authControllerProvider);
    expect(state.busy, isFalse);
    expect(state.user?.uid, 'uid_guest');
    expect(state.user?.kind, AccountKind.anonymous);
    expect(h.container.read(accountsDirectoryProvider).contains('uid_guest'),
        isTrue);
    expect(h.local.readPendingRedirect(), isNull);
  });

  test('no redirect pending: a normal boot, and nothing to spin about',
      () async {
    final h = await _harness();

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume, isNull);
    expect(h.container.read(authControllerProvider).busy, isFalse);
  });

  test('a failed redirect surfaces an error instead of hanging', () async {
    final h = await _harness(
      redirectError: Exception('[firebase_auth/invalid-credential] expired'),
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'apple',
        link: false,
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume!.user, isNull);
    expect(resume.error, isNotNull);
    final state = h.container.read(authControllerProvider);
    expect(state.busy, isFalse, reason: 'THE bug: a spinner with no way out');
    expect(state.error, contains('expired'));
    // A failed record is not retried forever.
    expect(h.local.readPendingRedirect(), isNull);
  });

  test('a redirect that cannot even start is an error, not a spinner',
      () async {
    final h = await _harness(
      redirectStartError: const AuthUnavailableException('popup blocked'),
    );

    await h.container
        .read(authControllerProvider.notifier)
        .signInWithApple(origin: RedirectOrigin.settings);

    final state = h.container.read(authControllerProvider);
    expect(state.busy, isFalse);
    expect(state.error, 'popup blocked');
    // Nothing left behind to be consumed by the next boot.
    expect(h.local.readPendingRedirect(), isNull);
  });

  testWidgets('the gate holds the boot until the redirect resolves, then lets '
      'the app through signed in', (tester) async {
    final h = await _harness(
      redirectResult: _google,
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.app,
      ),
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const RedirectSignInGate(
          child: Scaffold(body: Text('the app')),
        ),
      ),
    ));

    // First frame: the redirect is still in the air, and the app must NOT show
    // its signed-out self (Welcome) to somebody who just signed in.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('the app'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('the app'), findsOneWidget);
    expect(h.container.read(authControllerProvider).user?.uid, 'uid_casey');
  });

  testWidgets('a boot with nothing pending never shows the gate spinner',
      (tester) async {
    final h = await _harness();

    await tester.pumpWidget(UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const RedirectSignInGate(
          child: Scaffold(body: Text('the app')),
        ),
      ),
    ));

    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failed redirect lands the user in the app with the error '
      'said out loud', (tester) async {
    final h = await _harness(
      redirectError: Exception('[firebase_auth/user-cancelled] no thanks'),
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.app,
      ),
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const RedirectSignInGate(
          child: Scaffold(body: Text('the app')),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('the app'), findsOneWidget);
    expect(find.text('no thanks'), findsOneWidget);
  });

  testWidgets('the onboarding draft the reload destroyed is put back',
      (tester) async {
    final h = await _harness(
      redirectResult: _google,
      pending: PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.app,
        prelude: 2,
        draft: const OnboardingDraft(
          name: 'Nightbirds',
          currency: 'dkk',
          methods: {TipMethod.mobilepay},
          mobilepayBoxId: '12345',
        ).toJson(),
      ),
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const RedirectSignInGate(
          child: Scaffold(body: Text('the app')),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final draft = h.container.read(onboardingDraftProvider);
    expect(draft, isNotNull);
    expect(draft!.name, 'Nightbirds');
    expect(draft.currency, 'dkk');
    expect(draft.methods, {TipMethod.mobilepay});
    expect(draft.mobilepayBoxId, '12345');
    // And the step counter it was walking, so the flow does not restart at 1.
    expect(h.container.read(onboardingPreludeProvider), 2);
  });
}
