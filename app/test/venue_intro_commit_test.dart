import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/features/onboarding/welcome_screen.dart';
import 'package:live_tips/features/venue/venue_intro_screen.dart';
import 'package:live_tips/features/venue/venue_sign_in_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/venue_providers.dart';

import 'helpers.dart';

/// The venue link ASKS; the intro's Continue COMMITS — and Back writes
/// nothing (#42).
///
/// The link used to save `device_kind = venue` on the tap and push the warning
/// afterwards, so the root gate had already rebuilt into the venue sign-in door
/// beneath a screen that still hadn't said what a venue device is. Pressing
/// Back on it — "I've read this, no thanks" — landed the artist on a code-entry
/// screen for a code they don't have, with a destructive wipe as the only exit.
///
/// No test in this suite ever pressed Back, and none ever flipped a provider
/// under a pushed route; the flip-then-pop IS the bug, and it is invisible to a
/// test that builds one screen in its own ProviderScope. These build the real
/// RootGate and walk it.
void main() {
  Future<({LocalStore store, FakeSecureStore secure})> pumpApp(
      WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // A genuinely fresh install: one nameless band, no method, no account.
    final store = await seededStore();
    final secure = FakeSecureStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(secure),
          initialApiKeyProvider.overrideWithValue(null),
          // The venue link is only offered where cloud accounts can exist.
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();
    return (store: store, secure: secure);
  }

  testWidgets(
      'the venue link explains before it commits: Back leaves the device '
      'unset, on Welcome — not in venue mode behind a code entry (#42)',
      (tester) async {
    final env = await pumpApp(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Setting up a shared venue device?'));
    await tester.pumpAndSettle();

    // The warning is up, and NOTHING has been decided yet: no kind, and no
    // at-rest cipher minted for a device that may never be a venue device.
    expect(find.byType(VenueIntroScreen), findsOneWidget);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(VenueIntroScreen)));
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
      'Continue on the warning is what chooses venue mode — the kind is saved '
      'and the venue front door is the root (#42)', (tester) async {
    final env = await pumpApp(tester);

    await tester.tap(find.text('Setting up a shared venue device?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up sign-in'));
    await tester.pumpAndSettle();

    // The commit happens at the END of the flow, when the artist confirms what
    // they read — and the route stack drops onto the gate it rebuilt.
    expect(env.store.readDeviceKind(), DeviceKind.venue);
    expect(find.byType(VenueSignInScreen), findsOneWidget);
    expect(find.byType(VenueIntroScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsNothing);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(VenueSignInScreen)));
    expect(container.read(deviceKindProvider), DeviceKind.venue);
    // The at-rest cipher a venue device may not exist without is attached by
    // the same commit — it was the link's job, and it moved with the choice.
    expect(env.secure.values.keys, contains('venue_local_cipher_key_v1'));
  });

  testWidgets(
      'a keychain that refuses leaves the device unchosen, and says so where '
      'the artist is standing (#42)', (tester) async {
    final env = await pumpApp(tester);
    // A shared device without its at-rest cipher must not exist: the choice
    // does not take, and the artist stays on the screen that offered it.
    env.secure.failing = true;

    await tester.tap(find.text('Setting up a shared venue device?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up sign-in'));
    await tester.pumpAndSettle();

    expect(find.byType(VenueIntroScreen), findsOneWidget);
    expect(find.textContaining("secure storage didn't answer"), findsOneWidget);
    expect(env.store.readDeviceKind(), isNull);

    // And the way back is still a plain Back — no wipe, no code entry.
    env.secure.failing = false;
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
