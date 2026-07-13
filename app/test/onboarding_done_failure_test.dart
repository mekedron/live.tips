import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/features/onboarding/onboarding_done_screen.dart';
import 'package:live_tips/state/onboarding_draft.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// The wrong-state bug: when the relay refused to mint the jar, the final
/// onboarding screen still showed a green check and "You're all set" — the
/// failure notice was gated on `_url != null`, and a relay-only profile has no
/// Stripe link to fall back on, so it had no URL and said nothing. The artist
/// left onboarding believing they could be tipped.
///
/// A failure must always say so, and must always offer the retry.

const _draft = OnboardingDraft(
  name: 'Solo Act',
  currency: 'eur',
  methods: {TipMethod.revolut},
  revolutUsername: 'solo',
);

Future<FakeCallables> _pump(
  WidgetTester tester, {
  required bool failing,
  Object? error,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final local = await seededStore(bandName: 'Solo Act');
  final backend = FakeCallables({
    'createJar': (args) {
      if (failing) throw error ?? FakeFunctionsException('internal');
      return {
        'jarId': 'jar_1',
        'tipUrl': 'https://live.tips/t/jar_1',
        'secret': 'sec_1',
      };
    },
  });

  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    relayClientProvider.overrideWithValue(fakeRelayClient(backend)),
  ]);
  addTearDown(container.dispose);
  container.read(onboardingDraftProvider.notifier).set(_draft);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: kTestL10nDelegates,
      locale: const Locale('en'),
      theme: buildLightTheme(),
      home: const OnboardingDoneScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('a failed tip page is reported, never dressed up as success',
      (tester) async {
    await _pump(tester, failing: true);

    expect(find.text("Your tip page isn't ready"), findsOneWidget);
    // The old lie.
    expect(find.text("You're all set"), findsNothing);
    expect(find.text('Your tip QR is ready!'), findsNothing);
    // And a way forward, not just an apology.
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a relay VERDICT surfaces the server\'s own sentence — '
      '"couldn\'t reach live.tips" is only for calls that never landed',
      (tester) async {
    // The relay answered and refused the profile. Before #20, onboarding
    // dressed every failure as a connectivity problem, so an artist whose
    // band name was rejected had nothing to change and nowhere to go.
    await _pump(
      tester,
      failing: true,
      error: FakeFunctionsException(
          'invalid-argument', 'artistName is too long (max 50 characters)'),
    );

    expect(find.text("Your tip page isn't ready"), findsOneWidget);
    expect(find.textContaining('artistName is too long (max 50 characters)'),
        findsOneWidget);
    expect(find.textContaining("couldn't reach live.tips"), findsNothing);
  });

  testWidgets('a call that never landed still reads as a network failure',
      (tester) async {
    await _pump(
      tester,
      failing: true,
      error: FakeFunctionsException('unavailable', 'socket closed'),
    );

    expect(find.text("Your tip page isn't ready"), findsOneWidget);
    expect(find.textContaining("couldn't reach live.tips"), findsOneWidget);
    expect(find.textContaining('socket closed'), findsNothing);
  });

  testWidgets('retry re-runs the registration and lands on the QR',
      (tester) async {
    // First attempt fails; the relay comes back; the retry succeeds.
    final local = await seededStore(bandName: 'Solo Act');
    var attempts = 0;
    final backend = FakeCallables({
      'createJar': (args) {
        attempts++;
        if (attempts == 1) throw FakeFunctionsException('internal');
        return {
          'jarId': 'jar_1',
          'tipUrl': 'https://live.tips/t/jar_1',
          'secret': 'sec_1',
        };
      },
    });
    await tester.binding.setSurfaceSize(const Size(600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(local),
      secureStoreProvider.overrideWithValue(FakeSecureStore()),
      initialApiKeyProvider.overrideWithValue(null),
      relayClientProvider.overrideWithValue(fakeRelayClient(backend)),
    ]);
    addTearDown(container.dispose);
    container.read(onboardingDraftProvider.notifier).set(_draft);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const OnboardingDoneScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text("Your tip page isn't ready"), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Your tip QR is ready!'), findsOneWidget);
    expect(find.text("Your tip page isn't ready"), findsNothing);
    expect(container.read(appStateProvider).relayJar?.jarId, 'jar_1');
  });

  testWidgets('a successful registration still celebrates', (tester) async {
    await _pump(tester, failing: false);

    expect(find.text('Your tip QR is ready!'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });
}
