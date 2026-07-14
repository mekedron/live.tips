import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/data/firebase/link_codes.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/features/onboarding/welcome_screen.dart';
import 'package:live_tips/features/venue/venue_code_entry.dart';
import 'package:live_tips/features/venue/venue_identity_screen.dart';
import 'package:live_tips/features/venue/venue_intro_screen.dart';
import 'package:live_tips/features/venue/venue_sign_in_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/venue_providers.dart';

import 'helpers.dart';
import 'venue_sign_in_test.dart' show FakeLinkCodeService, fakeCustomToken;

/// The venue link ASKS; the intro explains; the code step signs in — and the
/// COMMIT rides on the collected token, at the very end (#42).
///
/// The link used to save `device_kind = venue` on the tap and push the warning
/// afterwards, so Back popped into a code-entry screen whose only exit was a
/// destructive wipe. Moving the commit to the intro's Continue fixed Back on
/// the warning — and re-created the same dead end one screen later: Continue
/// dropped the whole route stack onto the venue front door, no Back, the wipe
/// again the only way out for a person still holding no code. So the commit
/// moved once more, to where the flow actually finishes: a successfully
/// collected sign-in token chooses the kind (cipher first, account data
/// after), and until that moment every step is an ordinary pushed route whose
/// Back writes nothing.
///
/// These tests build the real RootGate and walk the whole staircase — Back
/// included, failures included — because the flip-under-a-pushed-route bugs
/// this file guards against are invisible to any test that builds one screen
/// in its own ProviderScope.
void main() {
  const artistCode = 'AAAAAAAAAAAAAAAAAAAAAA'; // 22 chars, the real shape

  Future<
      ({
        LocalStore store,
        FakeSecureStore secure,
        FakeAuthService auth,
        FakeLinkCodeService link,
      })> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // A genuinely fresh install: one nameless band, no method, no account.
    final store = await seededStore();
    final secure = FakeSecureStore();
    const artist = AuthUser(
      uid: 'uid_ana',
      kind: AccountKind.google,
      displayName: 'Ana',
      email: 'ana@example.com',
    );
    final auth = FakeAuthService(nextUser: artist);
    final link = FakeLinkCodeService(token: fakeCustomToken(artist.uid));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(secure),
          initialApiKeyProvider.overrideWithValue(null),
          // The venue link is only offered where cloud accounts can exist.
          authServiceProvider.overrideWithValue(auth),
          linkCodeServiceProvider.overrideWithValue(link),
          deviceRegistryProvider.overrideWithValue(
              DeviceRegistry(db: null, deviceId: 'dev_tablet')),
          // The host test platform claims android; there is no camera and
          // no device-info channel.
          venueCameraAvailableProvider.overrideWithValue(false),
          describeDeviceProvider.overrideWithValue(() async =>
              const DeviceDescription(name: 'Bar iPad', platform: 'android')),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();
    return (store: store, secure: secure, auth: auth, link: link);
  }

  Future<void> walkToCodeStep(WidgetTester tester) async {
    await tester.tap(find.text('Setting up a shared venue device?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up sign-in'));
    await tester.pumpAndSettle();
  }

  Future<void> typeCodeAndGo(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, artistCode);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'the venue link explains before anything commits: Back on the intro '
      'leaves the device unset, on Welcome (#42)', (tester) async {
    final env = await pumpApp(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Setting up a shared venue device?'));
    await tester.pumpAndSettle();

    // The warning is up, and NOTHING has been decided yet: no kind, and no
    // at-rest cipher minted for a device that may never be a venue device.
    expect(find.byType(VenueIntroScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(VenueIntroScreen)));
    expect(container.read(deviceKindProvider), isNull);
    expect(env.store.readDeviceKind(), isNull);
    expect(env.secure.values, isEmpty);

    // The reported gesture: the automatic Back arrow of the pushed warning.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Exactly where the artist started. The old code popped into
    // VenueSignInScreen — "this device belongs to the venue" — and charged a
    // full device wipe to take it back.
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(VenueSignInScreen), findsNothing);
    expect(container.read(deviceKindProvider), isNull);
    expect(env.store.readDeviceKind(), isNull,
        reason: 'a warning that has been declined may not have been obeyed');
  });

  testWidgets(
      '"Set up sign-in" pushes the code step — an ordinary route with a Back '
      'arrow to the intro, and still nothing is committed', (tester) async {
    final env = await pumpApp(tester);
    await walkToCodeStep(tester);

    // Step 2 of 2 is a plain pushed screen: pill up, code entry up, Back up.
    expect(find.byType(VenueSignInScreen), findsOneWidget);
    expect(find.text('Sign in from your phone'), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    // No wipe link: this is setup, not the front door — leaving is just Back.
    expect(find.text("This isn't a venue device"), findsNothing);

    // Walking IN commits nothing: the kind is chosen by a collected token,
    // not by reaching the screen that asks for one.
    expect(env.store.readDeviceKind(), isNull);
    expect(env.secure.values, isEmpty);

    // Back returns to "How a shared device works" — the reported gesture.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(VenueIntroScreen), findsOneWidget);
    expect(find.text('How a shared device works'), findsOneWidget);

    // And Back again to Welcome, the device exactly as it was: unset.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(env.store.readDeviceKind(), isNull);
    expect(env.secure.values, isEmpty);
  });

  testWidgets(
      'a collected token is the commit: kind saved, cipher attached, session '
      'started — and the setup stack drops onto the identity check (#42)',
      (tester) async {
    final env = await pumpApp(tester);
    await walkToCodeStep(tester);
    await typeCodeAndGo(tester);

    expect(env.link.calls,
        ['redeem:$artistCode:dev_tablet', 'collect:nonce_1']);

    // The commit happened at the END of the flow, on the token that finished
    // it: the kind is saved and the at-rest cipher a venue device may not
    // exist without arrived with it, before any account data landed.
    expect(env.store.readDeviceKind(), DeviceKind.venue);
    expect(env.secure.values.keys, contains('venue_local_cipher_key_v1'));

    // The 12-hour clock started, and the setup routes are gone: the tablet
    // stands where every future boot will stand — the gate's identity check.
    final session = env.store.readVenueSession();
    expect(session, isNotNull);
    expect(session!.uid, 'uid_ana');
    expect(find.byType(VenueIdentityScreen), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.byType(VenueIntroScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets(
      'a refused code shows its error ON the code step without breaking the '
      'stack: retry works, Back still returns to the intro, nothing committed',
      (tester) async {
    final env = await pumpApp(tester);
    env.link.failWith =
        const LinkCodeError(LinkCodeErrorKind.notFound, 'unknown code');
    await walkToCodeStep(tester);
    await typeCodeAndGo(tester);

    // The error lands inline on the same screen — no navigation, no modal.
    expect(find.textContaining('Unknown code'), findsOneWidget);
    expect(find.byType(VenueSignInScreen), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(env.store.readDeviceKind(), isNull,
        reason: 'a code that failed may not have made this a venue device');
    expect(env.secure.values, isEmpty);

    // Try again puts the entry back and the handshake succeeds this time.
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await typeCodeAndGo(tester);
    expect(find.byType(VenueIdentityScreen), findsOneWidget);
    expect(env.store.readDeviceKind(), DeviceKind.venue);
  });

  testWidgets(
      'a refused code, then Back: the intro is still behind the error, and '
      'the device is still nothing', (tester) async {
    final env = await pumpApp(tester);
    env.link.failWith =
        const LinkCodeError(LinkCodeErrorKind.failedPrecondition, 'expired');
    await walkToCodeStep(tester);
    await typeCodeAndGo(tester);

    expect(find.textContaining('code expired'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(VenueIntroScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(env.store.readDeviceKind(), isNull);
  });

  testWidgets(
      'a keychain that refuses leaves the device unchosen, says so on the '
      'code card, and the way back is still a plain Back (#42)',
      (tester) async {
    final env = await pumpApp(tester);
    // A shared device without its at-rest cipher must not exist: the choice
    // does not take, and the artist stays on the screen that asked for it.
    env.secure.failing = true;
    await walkToCodeStep(tester);
    await typeCodeAndGo(tester);

    expect(find.textContaining("secure storage didn't answer"), findsOneWidget);
    expect(env.store.readDeviceKind(), isNull);
    expect(find.byType(VenueSignInScreen), findsOneWidget);

    // The keychain unlocks; the retry finishes what the first attempt
    // couldn't — with a fresh handshake, since the first token was spent.
    env.secure.failing = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await typeCodeAndGo(tester);
    expect(env.store.readDeviceKind(), DeviceKind.venue);
    expect(find.byType(VenueIdentityScreen), findsOneWidget);
  });
}
