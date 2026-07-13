import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tip_method.dart';

/// The in-flight onboarding run, carried across its screens. Onboarding now
/// starts by collecting the band's details (name / currency / thank-you
/// message), then which methods to set up, then each method in turn — so the
/// draft holds all of that until the final screen commits it. Null in
/// [onboardingDraftProvider] means nobody is onboarding right now; every step
/// screen falls back to its standalone behavior.
class OnboardingDraft {
  const OnboardingDraft({
    this.name = '',
    this.currency = 'eur',
    this.thankYouMessage = '',
    this.methods = const {},
    this.revolutUsername,
    this.mobilepayBoxId,
    this.monzoUsername,
  });

  /// Band / artist name from the details step.
  final String name;

  /// Currency from the details step (lowercase ISO-4217).
  final String currency;

  /// Thank-you / tip-page message from the details step.
  final String thankYouMessage;

  /// Which methods the artist chose to set up.
  final Set<TipMethod> methods;

  /// Values entered on each method's step (null = skipped / not entered).
  final String? revolutUsername;
  final String? mobilepayBoxId;
  final String? monzoUsername;

  bool get wantsStripe => methods.contains(TipMethod.stripe);
  bool get wantsRevolut => methods.contains(TipMethod.revolut);
  bool get wantsMobilePay => methods.contains(TipMethod.mobilepay);
  bool get wantsMonzo => methods.contains(TipMethod.monzo);

  /// Any method that needs the live.tips relay (a fan page + jar).
  bool get wantsRelay => methods.any(TipMethod.relayMethods.contains);

  /// The selected methods in the fixed setup order: Stripe, then the relay
  /// methods — the sequence the step screens walk through.
  List<TipMethod> get setupOrder => [
        if (wantsStripe) TipMethod.stripe,
        ...TipMethod.relayMethods.where(methods.contains),
      ];

  /// Screen keys for [stepOf].
  static const stepDetails = 'details';
  static const stepMethodSelect = 'methodSelect';

  /// Details (1) + method select (2) + one step per chosen method. The final
  /// QR screen is the celebration, not a numbered step.
  ///
  /// Nothing chosen yet still counts as one method: you cannot finish
  /// onboarding without picking one, and a total that says "3" on the way in
  /// and "2" on the way back reads like the app lost a step.
  int get totalSteps => 2 + (methods.isEmpty ? 1 : methods.length);

  /// 1-based position of a fixed screen in this draft's flow.
  int stepOf(String screenKey) => switch (screenKey) {
        stepDetails => 1,
        stepMethodSelect => 2,
        _ => 1,
      };

  /// 1-based position of a per-method step (after details + method select).
  int stepOfMethod(TipMethod method) => 3 + setupOrder.indexOf(method);

  OnboardingDraft copyWith({
    String? name,
    String? currency,
    String? thankYouMessage,
    Set<TipMethod>? methods,
    String? revolutUsername,
    String? mobilepayBoxId,
    String? monzoUsername,
  }) =>
      OnboardingDraft(
        name: name ?? this.name,
        currency: currency ?? this.currency,
        thankYouMessage: thankYouMessage ?? this.thankYouMessage,
        methods: methods ?? this.methods,
        revolutUsername: revolutUsername ?? this.revolutUsername,
        mobilepayBoxId: mobilepayBoxId ?? this.mobilepayBoxId,
        monzoUsername: monzoUsername ?? this.monzoUsername,
      );
}

class OnboardingDraftNotifier extends Notifier<OnboardingDraft?> {
  @override
  OnboardingDraft? build() => null;

  /// Starts (or replaces) an onboarding run.
  void set(OnboardingDraft draft) => state = draft;

  /// Updates the in-flight draft; no-op when nobody is onboarding.
  void update(OnboardingDraft Function(OnboardingDraft) mutate) {
    final current = state;
    if (current != null) state = mutate(current);
  }

  /// Onboarding finished or was abandoned — step screens go back to their
  /// standalone fallbacks.
  void clear() => state = null;
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft?>(
        OnboardingDraftNotifier.new);

/// How many account-flavored steps (the account question, the account name)
/// this onboarding run walked through BEFORE the band draft existed. Kept
/// outside [OnboardingDraft] on purpose: the sign-in between those steps
/// flips the active profile, which clears the draft — and the step counter
/// losing its first two steps mid-flow is exactly the bug being fixed.
///
/// Marks only ever raise the count. Going Back re-marks the same step, so
/// the total a user saw on the way in can never shrink on the way back.
class OnboardingPreludeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// The account question was actually shown (not auto-skipped).
  void markAccountStep() {
    if (state < 1) state = 1;
  }

  /// The account-name step was shown too.
  void markNameStep() {
    if (state < 2) state = 2;
  }

  /// A new run begins (Welcome's "Get started", adding a band later, a
  /// device wipe) — the prelude belongs to the run, not the device.
  void reset() => state = 0;
}

final onboardingPreludeProvider =
    NotifierProvider<OnboardingPreludeNotifier, int>(
        OnboardingPreludeNotifier.new);
