import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/tip_method.dart';
import '../../state/onboarding_draft.dart';
import 'connect_screen.dart';
import 'onboarding_done_screen.dart';
import 'onboarding_method_screen.dart';

/// Pushes the next onboarding setup step after [after] (null = the first one).
/// Steps run in a fixed order — Stripe, Revolut, MobilePay — for whichever
/// methods the artist picked, then the final QR screen. Each step screen
/// calls this on Save or Skip, so the chain advances the same way either way.
void pushOnboardingStep(BuildContext context, WidgetRef ref,
    {TipMethod? after}) {
  final order = ref.read(onboardingDraftProvider)?.setupOrder ?? const [];
  final startIdx = after == null ? 0 : order.indexOf(after) + 1;
  final Widget next;
  if (startIdx >= 0 && startIdx < order.length) {
    next = switch (order[startIdx]) {
      TipMethod.stripe => const ConnectScreen(),
      TipMethod.revolut =>
        const OnboardingMethodScreen(method: TipMethod.revolut),
      TipMethod.mobilepay =>
        const OnboardingMethodScreen(method: TipMethod.mobilepay),
    };
  } else {
    next = const OnboardingDoneScreen();
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => next));
}
