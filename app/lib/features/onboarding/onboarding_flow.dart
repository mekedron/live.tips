import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/install_prompt.dart';
import '../../domain/tip_method.dart';
import '../../state/onboarding_draft.dart';
import 'connect_screen.dart';
import 'install_hint_screen.dart';
import 'onboarding_details_screen.dart';
import 'onboarding_done_screen.dart';
import 'onboarding_method_screen.dart';

/// The screen that starts the band-setup half of onboarding. Phones and
/// tablets in a browser get the one-time "Add to Home Screen" nudge first
/// (it carries on to the details step itself); desktop and the installed
/// PWA go straight to the band details.
///
/// [createsProfile] rides along to the details step: this run was started by an
/// artist asking for a NEW profile ("Add a profile", "Create a new profile"), so
/// the name they type names a profile that does not exist yet instead of
/// renaming the one they are standing in. The profile is written there, as it is
/// named — never on the tap that opened this (#44).
Widget firstBandSetupScreen({bool createsProfile = false}) =>
    shouldSuggestInstall
        ? InstallHintScreen(createsProfile: createsProfile)
        : OnboardingDetailsScreen(createsProfile: createsProfile);

/// Pushes the next onboarding setup step after [after] (null = the first one).
/// Steps run in a fixed order — Stripe, then the relay methods — for whichever
/// methods the artist picked, then the final QR screen. Each step screen
/// calls this on Save or Skip, so the chain advances the same way either way.
void pushOnboardingStep(BuildContext context, WidgetRef ref,
    {TipMethod? after}) {
  final order = ref.read(onboardingDraftProvider)?.setupOrder ?? const [];
  final startIdx = after == null ? 0 : order.indexOf(after) + 1;
  final Widget next;
  if (startIdx >= 0 && startIdx < order.length) {
    final method = order[startIdx];
    next = method == TipMethod.stripe
        ? const ConnectScreen()
        : OnboardingMethodScreen(method: method);
  } else {
    next = const OnboardingDoneScreen();
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => next));
}
