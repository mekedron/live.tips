import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tip_method.dart';

/// What the artist picked on the "How do you want to get tipped?" step,
/// carried through the rest of onboarding. Null in [onboardingDraftProvider]
/// means nobody is onboarding right now — every step screen falls back to
/// its standalone behavior.
class OnboardingDraft {
  const OnboardingDraft({
    this.methods = const {},
    this.revolutUsername,
    this.mobilepayBoxId,
  });

  final Set<TipMethod> methods;
  final String? revolutUsername;
  final String? mobilepayBoxId;

  bool get wantsStripe => methods.contains(TipMethod.stripe);

  /// Any method that needs the live.tips relay (a donor page + jar).
  bool get wantsRelay =>
      methods.contains(TipMethod.revolut) ||
      methods.contains(TipMethod.mobilepay);

  /// Screen keys for [stepOf].
  static const stepMethodSelect = 'methodSelect';
  static const stepConnect = 'connect';
  static const stepJarSetup = 'jarSetup';
  static const stepRelaySetup = 'relaySetup';

  /// How many onboarding steps this selection takes:
  /// Stripe-only 3 (MethodSelect → Connect → JarSetup), Stripe+relay 4
  /// (… → RelaySetup), relay-only 2 (MethodSelect → RelaySetup).
  int get totalSteps {
    if (!wantsStripe) return 2;
    return wantsRelay ? 4 : 3;
  }

  /// 1-based position of a screen in this draft's flow.
  int stepOf(String screenKey) => switch (screenKey) {
        stepMethodSelect => 1,
        stepConnect => 2,
        stepJarSetup => 3,
        stepRelaySetup => wantsStripe ? 4 : 2,
        _ => 1,
      };

  OnboardingDraft copyWith({
    Set<TipMethod>? methods,
    String? revolutUsername,
    String? mobilepayBoxId,
  }) =>
      OnboardingDraft(
        methods: methods ?? this.methods,
        revolutUsername: revolutUsername ?? this.revolutUsername,
        mobilepayBoxId: mobilepayBoxId ?? this.mobilepayBoxId,
      );
}

class OnboardingDraftNotifier extends Notifier<OnboardingDraft?> {
  @override
  OnboardingDraft? build() => null;

  /// Starts (or replaces) an onboarding run with the chosen methods.
  void set(OnboardingDraft draft) => state = draft;

  /// Onboarding finished or was abandoned — step screens go back to their
  /// standalone fallbacks.
  void clear() => state = null;
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft?>(
        OnboardingDraftNotifier.new);
