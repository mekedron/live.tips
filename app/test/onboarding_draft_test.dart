import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/state/onboarding_draft.dart';

void main() {
  group('totalSteps', () {
    test('stripe-only → 3', () {
      expect(
        const OnboardingDraft(methods: {TipMethod.stripe}).totalSteps,
        3,
      );
    });

    test('stripe + any relay method → 4', () {
      expect(
        const OnboardingDraft(methods: {TipMethod.stripe, TipMethod.revolut})
            .totalSteps,
        4,
      );
      expect(
        const OnboardingDraft(
            methods: {TipMethod.stripe, TipMethod.mobilepay}).totalSteps,
        4,
      );
      expect(
        const OnboardingDraft(methods: {
          TipMethod.stripe,
          TipMethod.revolut,
          TipMethod.mobilepay,
        }).totalSteps,
        4,
      );
    });

    test('relay-only → 2, regardless of which relay methods', () {
      expect(
        const OnboardingDraft(methods: {TipMethod.revolut}).totalSteps,
        2,
      );
      expect(
        const OnboardingDraft(methods: {TipMethod.mobilepay}).totalSteps,
        2,
      );
      expect(
        const OnboardingDraft(
            methods: {TipMethod.revolut, TipMethod.mobilepay}).totalSteps,
        2,
      );
    });
  });

  group('stepOf', () {
    const stripeOnly = OnboardingDraft(methods: {TipMethod.stripe});
    const both =
        OnboardingDraft(methods: {TipMethod.stripe, TipMethod.mobilepay});
    const relayOnly = OnboardingDraft(methods: {TipMethod.revolut});

    test('method select is always step 1', () {
      for (final draft in [stripeOnly, both, relayOnly]) {
        expect(draft.stepOf(OnboardingDraft.stepMethodSelect), 1);
      }
    });

    test('stripe flow: connect 2, jar setup 3', () {
      for (final draft in [stripeOnly, both]) {
        expect(draft.stepOf(OnboardingDraft.stepConnect), 2);
        expect(draft.stepOf(OnboardingDraft.stepJarSetup), 3);
      }
    });

    test('relay setup is always the last step', () {
      expect(both.stepOf(OnboardingDraft.stepRelaySetup), 4);
      expect(relayOnly.stepOf(OnboardingDraft.stepRelaySetup), 2);
      expect(both.stepOf(OnboardingDraft.stepRelaySetup), both.totalSteps);
      expect(relayOnly.stepOf(OnboardingDraft.stepRelaySetup),
          relayOnly.totalSteps);
    });
  });

  group('wants flags', () {
    test('wantsStripe / wantsRelay reflect the selection', () {
      const draft =
          OnboardingDraft(methods: {TipMethod.stripe, TipMethod.revolut});
      expect(draft.wantsStripe, isTrue);
      expect(draft.wantsRelay, isTrue);
      expect(
          const OnboardingDraft(methods: {TipMethod.stripe}).wantsRelay,
          isFalse);
      expect(
          const OnboardingDraft(methods: {TipMethod.mobilepay}).wantsStripe,
          isFalse);
    });
  });

  test('copyWith replaces only what is passed', () {
    const draft = OnboardingDraft(
      methods: {TipMethod.revolut},
      revolutUsername: 'maya',
    );
    final copy = draft.copyWith(mobilepayBoxId: 'box-1');
    expect(copy.methods, {TipMethod.revolut});
    expect(copy.revolutUsername, 'maya');
    expect(copy.mobilepayBoxId, 'box-1');
  });
}
