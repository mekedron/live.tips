import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_bridge.dart';
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

/// The Safari bug, and the shape of the fix.
///
/// A popup sign-in is dead on the web (blocked on iOS Safari, hangs forever in
/// an installed PWA) — and so is the SDK's own signInWithRedirect: Safari
/// partitions the cross-origin iframe storage it delivers results through, so
/// a Google sign-in COMPLETED and the app never heard about it. No user, no
/// error, nothing. So the web signs in through the auth bridge on
/// auth.live.tips: the app navigates away carrying a nonce, and the bridge
/// brings the session back as a custom token in the boot URL's fragment.
///
/// These tests cover both halves of that trip — the departure (what gets
/// recorded, what the bridge URL carries) and the return (a token, a nonce
/// mismatch, a cancellation and a failure each do the right thing) — including
/// the one that has burned us before: a LINK must come back as an upgrade of
/// the guest account, never as a second account beside it.
///
/// What they CANNOT cover: Safari itself. No fake reproduces partitioned
/// storage; only a real WebKit browser can prove the trip leaves and lands.

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
/// is the whole point of a link — a new uid would leave every band the guest
/// owns behind.
const _upgraded = AuthUser(
  uid: 'uid_guest',
  kind: AccountKind.google,
  displayName: 'Casey',
  email: 'casey@example.com',
);

Future<
    ({
      ProviderContainer container,
      LocalStore local,
      FakeAuthService auth,
      List<Uri> launched,
    })> _harness({
  AuthUser? user,
  AuthUser? nextUser,
  BridgeResponse? bridge,
  Object? launchError,
  PendingRedirect? pending,
  AccountsDirectory? directory,
}) async {
  final local = await seededStore();
  if (directory != null) await local.saveAccountsDirectory(directory);
  if (pending != null) await local.savePendingRedirect(pending);
  final auth = FakeAuthService(
    user: user,
    nextUser: nextUser ?? _google,
  );
  final launched = <Uri>[];
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    authServiceProvider.overrideWithValue(auth),
    // What kIsWeb resolves to in the browser — the only reason this provider
    // exists is so the redirect machinery is testable off it.
    webRedirectSignInProvider.overrideWithValue(true),
    // The bridge's answer, as main() would have parsed it off the boot URL.
    bridgeResponseProvider.overrideWithValue(bridge),
    // Navigating away is untestable; capture where the page would have gone.
    bridgeLauncherProvider.overrideWithValue((uri) async {
      if (launchError != null) throw launchError;
      launched.add(uri);
    }),
    // A link's outbound token, without Cloud Functions underneath.
    linkTokenMinterProvider.overrideWithValue(() async => 'token_guest_out'),
  ]);
  addTearDown(container.dispose);
  return (container: container, local: local, auth: auth, launched: launched);
}

void main() {
  test('the web never opens a popup or an in-page redirect — the sign-in '
      'leaves for the bridge, and everything the return leg needs is written '
      'down first', () async {
    final h = await _harness();
    // Mid-onboarding: a draft in memory — the run, and the only thing the
    // reload must not eat (the step counter is derived from it now).
    h.container.read(onboardingDraftProvider.notifier).set(const OnboardingDraft(
          name: 'Nightbirds',
          currency: 'dkk',
          thankYouMessage: 'thank you!',
          methods: {TipMethod.stripe, TipMethod.revolut},
          revolutUsername: 'nightbirds',
        ));

    final user = await h.container
        .read(authControllerProvider.notifier)
        .signInWithGoogle(origin: RedirectOrigin.onboarding);

    // No user, no popup: the page is on its way to the bridge.
    expect(user, isNull);
    expect(h.launched, hasLength(1));
    final target = h.launched.single;
    expect(target.toString(), startsWith('https://auth.live.tips/signin#req='));

    final record = h.local.readPendingRedirect();
    expect(record, isNotNull);
    expect(record!.link, isFalse);
    expect(record.provider, 'google');
    expect(record.origin, RedirectOrigin.onboarding);
    expect(record.nonce, isNotEmpty,
        reason: 'the nonce is what pairs the answer with THIS attempt');
    // And the bridge was told the same story the record tells.
    expect(target.fragment, contains(Uri.encodeComponent('"google"')));
    expect(target.fragment, contains(Uri.encodeComponent(record.nonce)));
    // The half-filled band setup survives the reload — in memory it would not.
    final draft = OnboardingDraft.fromJson(record.draft!);
    expect(draft.name, 'Nightbirds');
    expect(draft.currency, 'dkk');
    expect(draft.thankYouMessage, 'thank you!');
    expect(draft.methods, {TipMethod.stripe, TipMethod.revolut});
    expect(draft.revolutUsername, 'nightbirds');
  });

  test('a token that echoes the nonce comes back as a fully adopted account',
      () async {
    final h = await _harness(
      bridge: const BridgeResponse(nonce: 'n1', token: 'token_casey'),
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.onboarding,
        nonce: 'n1',
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume, isNotNull);
    expect(resume!.user?.uid, 'uid_casey');
    expect(resume.error, isNull);
    expect(resume.record.origin, RedirectOrigin.onboarding);
    expect(h.auth.redeemedTokens, ['token_casey'],
        reason: 'the session arrives as a custom token, nothing else');

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

  test('a response whose nonce does not match is NOT ours — no token is '
      'redeemed, and no account is conjured', () async {
    // A stale fragment (an old bookmark, a crafted link) must not be able to
    // answer an attempt it did not start — that would be a drive-by sign-in.
    final h = await _harness(
      bridge: const BridgeResponse(nonce: 'somebody_else', token: 'token_evil'),
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.settings,
        nonce: 'n1',
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume?.user, isNull);
    expect(resume?.error, isNull, reason: 'silently ignored, like a back-out');
    expect(h.auth.redeemedTokens, isEmpty,
        reason: 'a foreign token must never be signed in with');
    expect(h.container.read(authControllerProvider).busy, isFalse);
    expect(h.local.readPendingRedirect(), isNull);
  });

  test('a token on a LINK is only believed when the provider really attached',
      () async {
    // The bridge said "linked" — but the truth is whatever the account says
    // after the token signs in. Still a guest? Then no upgrade happened, and
    // claiming one would tell someone their guest account is now a Google
    // account when it is not.
    final h = await _harness(
      user: _guest,
      nextUser: _guest, // the token resolves… to a still-anonymous account
      bridge: const BridgeResponse(nonce: 'n1', token: 'token_guest_back'),
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
        nonce: 'n1',
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
      nextUser: _upgraded,
      bridge: const BridgeResponse(nonce: 'n1', token: 'token_guest_back'),
      directory: AccountsDirectory.initial()
          .withAccount(_guestEntry)
          .withActive('uid_guest'),
      pending: const PendingRedirect(
        appName: '[DEFAULT]',
        provider: 'google',
        link: true,
        uid: 'uid_guest',
        origin: RedirectOrigin.settings,
        nonce: 'n1',
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

  test('a LINK whose token resolves to a DIFFERENT uid is refused — the wrong '
      'account must not replace the guest', () async {
    final h = await _harness(
      user: _guest,
      nextUser: _google, // uid_casey — not the guest this link was for
      bridge: const BridgeResponse(nonce: 'n1', token: 'token_wrong'),
      directory: AccountsDirectory.initial()
          .withAccount(_guestEntry)
          .withActive('uid_guest'),
      pending: const PendingRedirect(
        appName: '[DEFAULT]',
        provider: 'google',
        link: true,
        uid: 'uid_guest',
        origin: RedirectOrigin.settings,
        nonce: 'n1',
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume?.user, isNull);
    final directory = h.container.read(accountsDirectoryProvider);
    expect(directory.contains('uid_casey'), isFalse,
        reason: 'the stranger stays out of the directory');
    expect(h.container.read(authControllerProvider).busy, isFalse);
  });

  test('a cancelled sign-in (no token, no error) leaves the guest exactly '
      'where it was', () async {
    final h = await _harness(
      user: _guest,
      // Backed out on the provider's page: the bridge echoes the nonce alone.
      bridge: const BridgeResponse(nonce: 'n1'),
      directory: AccountsDirectory.initial()
          .withAccount(_guestEntry)
          .withActive('uid_guest'),
      pending: const PendingRedirect(
        appName: '[DEFAULT]',
        provider: 'google',
        link: true,
        uid: 'uid_guest',
        origin: RedirectOrigin.settings,
        nonce: 'n1',
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

  test('a record with NO response at all — the user walked back without '
      'finishing — is cleared, not carried forever', () async {
    final h = await _harness(
      bridge: null,
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        nonce: 'n1',
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume!.user, isNull);
    expect(resume.error, isNull);
    expect(h.container.read(authControllerProvider).busy, isFalse);
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

  test('a failed sign-in surfaces an error instead of hanging', () async {
    final h = await _harness(
      bridge: const BridgeResponse(
          nonce: 'n1', error: 'auth/account-exists-with-different-credential'),
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'apple',
        link: false,
        nonce: 'n1',
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume!.user, isNull);
    expect(resume.error, isNotNull);
    final state = h.container.read(authControllerProvider);
    expect(state.busy, isFalse, reason: 'THE bug: a spinner with no way out');
    expect(state.error, contains('different sign-in method'));
    // A failed record is not retried forever.
    expect(h.local.readPendingRedirect(), isNull);
  });

  test('operation-not-allowed is permanent — the message names the provider '
      'and does not say "try again"', () async {
    // A provider the console never enabled/configured (#56): no fake can
    // produce this — every fake provider is always enabled — but the bridge
    // carries it as an opaque string, so the mapping itself is testable. The
    // fallback's "Try again." would invite the user to re-run the whole
    // bridge round trip forever, against an error only the console can fix.
    final h = await _harness(
      bridge: const BridgeResponse(
          nonce: 'n1', error: 'auth/operation-not-allowed'),
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'apple',
        link: false,
        nonce: 'n1',
      ),
    );

    final resume = await h.container
        .read(authControllerProvider.notifier)
        .consumePendingRedirect();

    expect(resume!.user, isNull);
    expect(resume.error, contains('Apple'),
        reason: 'the record knows which method was refused — say it');
    expect(resume.error, isNot(contains('ry again')),
        reason: 'retrying a console-config error is advice that cannot work');
    expect(h.container.read(authControllerProvider).busy, isFalse);
    // Consumed, not retried: the record is gone whatever the message says.
    expect(h.local.readPendingRedirect(), isNull);
  });

  test('a sign-in that cannot even leave is an error, not a spinner',
      () async {
    final h = await _harness(
      launchError: const AuthUnavailableException('bridge unreachable'),
    );

    await h.container
        .read(authControllerProvider.notifier)
        .signInWithApple(origin: RedirectOrigin.settings);

    final state = h.container.read(authControllerProvider);
    expect(state.busy, isFalse);
    expect(state.error, 'bridge unreachable');
    // Nothing left behind to be consumed by the next boot.
    expect(h.local.readPendingRedirect(), isNull);
  });

  testWidgets('the gate holds the boot until the redirect resolves, then lets '
      'the app through signed in', (tester) async {
    final h = await _harness(
      bridge: const BridgeResponse(nonce: 'n1', token: 'token_casey'),
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.app,
        nonce: 'n1',
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
      bridge: const BridgeResponse(nonce: 'n1', error: 'auth/user-disabled'),
      pending: const PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.app,
        nonce: 'n1',
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
    expect(find.text('This account has been disabled.'), findsOneWidget);
  });

  testWidgets('the onboarding draft the reload destroyed is put back',
      (tester) async {
    final h = await _harness(
      bridge: const BridgeResponse(nonce: 'n1', token: 'token_casey'),
      pending: PendingRedirect(
        appName: 'acct_slot_0',
        provider: 'google',
        link: false,
        origin: RedirectOrigin.app,
        nonce: 'n1',
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
    // And with the draft comes the step counter: the run's length IS the draft
    // (one method chosen → "3 of 3"), so restoring one restores the other.
    expect(draft.totalSteps, 3);
  });

  test('the bridge fragment round-trips: what signin.html sends is what the '
      'boot parses', () {
    // The exact encoding the bridge page produces (encodeURIComponent(JSON)).
    const json = '{"v":1,"state":"n1","token":"tok.en-123"}';
    final url = 'https://live.tips/app/#signin=${Uri.encodeComponent(json)}';
    final resp = parseBridgeResponse(url);
    expect(resp, isNotNull);
    expect(resp!.nonce, 'n1');
    expect(resp.token, 'tok.en-123');
    expect(resp.error, isNull);
    expect(resp.cancelled, isFalse);

    expect(parseBridgeResponse('https://live.tips/app/'), isNull);
    expect(parseBridgeResponse('https://live.tips/app/#c=abc'), isNull,
        reason: 'the add-device deep link is somebody else\'s fragment');
    expect(parseBridgeResponse('https://live.tips/app/#signin=garbage'),
        isNull);
  });
}
