import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:live_tips/state/onboarding_draft.dart';

void main() {
  group('totalSteps', () {
    // Details (1) + method select (2) + one step per chosen method.
    test('stripe-only → 3', () {
      expect(
        const OnboardingDraft(methods: {TipMethod.stripe}).totalSteps,
        3,
      );
    });

    test('stripe + one relay method → 4', () {
      expect(
        const OnboardingDraft(methods: {TipMethod.stripe, TipMethod.revolut})
            .totalSteps,
        4,
      );
    });

    test('all three methods → 5', () {
      expect(
        const OnboardingDraft(methods: {
          TipMethod.stripe,
          TipMethod.revolut,
          TipMethod.mobilepay,
        }).totalSteps,
        5,
      );
    });

    test('relay-only single method → 3', () {
      expect(
        const OnboardingDraft(methods: {TipMethod.revolut}).totalSteps,
        3,
      );
    });
  });

  group('stepOf / stepOfMethod', () {
    const stripeOnly = OnboardingDraft(methods: {TipMethod.stripe});
    const all = OnboardingDraft(methods: {
      TipMethod.stripe,
      TipMethod.revolut,
      TipMethod.mobilepay,
    });
    const relayOnly = OnboardingDraft(methods: {TipMethod.mobilepay});

    test('details is 1, method select is 2', () {
      for (final draft in [stripeOnly, all, relayOnly]) {
        expect(draft.stepOf(OnboardingDraft.stepDetails), 1);
        expect(draft.stepOf(OnboardingDraft.stepMethodSelect), 2);
      }
    });

    test('methods are numbered in setup order after the first two steps', () {
      expect(all.stepOfMethod(TipMethod.stripe), 3);
      expect(all.stepOfMethod(TipMethod.revolut), 4);
      expect(all.stepOfMethod(TipMethod.mobilepay), 5);
      // The last method is always the last numbered step.
      expect(all.stepOfMethod(TipMethod.mobilepay), all.totalSteps);
      expect(relayOnly.stepOfMethod(TipMethod.mobilepay), 3);
      expect(relayOnly.stepOfMethod(TipMethod.mobilepay), relayOnly.totalSteps);
    });

    test('setupOrder keeps the fixed Stripe → Revolut → MobilePay order', () {
      expect(all.setupOrder,
          [TipMethod.stripe, TipMethod.revolut, TipMethod.mobilepay]);
      expect(const OnboardingDraft(methods: {TipMethod.mobilepay, TipMethod.stripe})
          .setupOrder, [TipMethod.stripe, TipMethod.mobilepay]);
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
      name: 'Maya',
      currency: 'eur',
      methods: {TipMethod.revolut},
      revolutUsername: 'maya',
    );
    final copy = draft.copyWith(mobilepayBoxId: 'box-1');
    expect(copy.name, 'Maya');
    expect(copy.currency, 'eur');
    expect(copy.methods, {TipMethod.revolut});
    expect(copy.revolutUsername, 'maya');
    expect(copy.mobilepayBoxId, 'box-1');
  });
}
