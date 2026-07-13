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

  /// The draft as plain JSON. It lives in memory only — but a WEB sign-in
  /// redirect reloads the whole app (see PendingRedirect), and a half-filled
  /// band setup that evaporated across that reload would read as data loss.
  /// So the redirect snapshots the draft through here and restores it on the
  /// way back.
  Map<String, dynamic> toJson() => {
        'name': name,
        'currency': currency,
        'thankYouMessage': thankYouMessage,
        'methods': [for (final m in methods) m.wire],
        if (revolutUsername != null) 'revolutUsername': revolutUsername,
        if (mobilepayBoxId != null) 'mobilepayBoxId': mobilepayBoxId,
        if (monzoUsername != null) 'monzoUsername': monzoUsername,
      };

  static OnboardingDraft fromJson(Map<String, dynamic> json) => OnboardingDraft(
        name: json['name'] as String? ?? '',
        currency: json['currency'] as String? ?? 'eur',
        thankYouMessage: json['thankYouMessage'] as String? ?? '',
        methods: {
          for (final wire in (json['methods'] as List? ?? const []))
            ?TipMethod.fromWire(wire as String?),
        },
        revolutUsername: json['revolutUsername'] as String?,
        mobilepayBoxId: json['mobilepayBoxId'] as String?,
        monzoUsername: json['monzoUsername'] as String?,
      );

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
