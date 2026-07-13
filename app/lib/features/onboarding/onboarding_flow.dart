import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/install_prompt.dart';
import '../../domain/tip_method.dart';
import '../../l10n/app_localizations.dart';
import '../../state/onboarding_draft.dart';
import '../../widgets/lt_ui.dart';
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

/// Which screen of the numbered run a step screen IS. It names itself; what
/// NUMBER that is, only the flow can say ([OnboardingProgress]).
///
/// The account screens are deliberately not in here, and that is the fix the
/// counter needed. The run's length is not knowable while the account question
/// is open: whether the naming step is asked depends on what the provider hands
/// back, whether the profile fork is asked depends on what the account turns out
/// to hold, and picking an existing profile there ends onboarding on the spot.
/// Every number shown on those screens was a guess, and the guesses contradicted
/// each other — the account question promised "Step 1 of 4" and the very next
/// screen said "Step 2 of 5". A step indicator that revises its own total is
/// worse than none: it is the app telling the artist it has lost count.
///
/// So the counter numbers the run whose length IS known — the profile setup —
/// and it counts every screen of it, in order, from the draft that describes it.
/// The account phase is a branch, not a queue, and it shows no number at all.
enum OnboardingStep {
  /// Name, currency, thank-you — where the profile is created (#44).
  details,

  /// Which payment methods to set up. The one screen that can change the run's
  /// length, and the artist is the one changing it, as they tick the boxes.
  methodSelect,

  /// One per chosen method, in [OnboardingDraft.setupOrder].
  method,
}

/// The step indicator — the pill and the segments — from ONE source: the draft,
/// which IS the flow. No screen computes its own index any more; they used to,
/// each with its own arithmetic and its own fallback total, and they disagreed.
///
/// [selected] is the method screen's live selection: the artist is choosing the
/// length of their own run there, so the total follows their ticks before the
/// draft has been written. That is the only place the total may move, and it
/// moves under their finger.
class OnboardingProgress extends ConsumerWidget {
  const OnboardingProgress({
    super.key,
    required this.step,
    this.method,
    this.selected,
    this.pillOnly = false,
  });

  final OnboardingStep step;

  /// Which method's step this is ([OnboardingStep.method] only).
  final TipMethod? method;

  /// The live selection on the method-select screen.
  final Set<TipMethod>? selected;

  /// The app-bar form (the pill); false renders the segment bar.
  final bool pillOnly;

  /// The run's length and this screen's place in it, or null when there is no
  /// run to count (a method screen opened from Settings has no draft, and a
  /// step of nothing is not a step).
  static ({int step, int total})? positionOf(
    OnboardingDraft? draft,
    OnboardingStep step, {
    TipMethod? method,
    Set<TipMethod>? selected,
  }) {
    final methods = selected ?? draft?.methods ?? const <TipMethod>{};
    // Details + the method choice + one step per method. Nothing chosen yet
    // still counts as one: a run cannot finish without a method, and a total
    // that said "2" on the way in would have to grow the moment one is ticked.
    final total = 2 + (methods.isEmpty ? 1 : methods.length);
    switch (step) {
      case OnboardingStep.details:
        return (step: 1, total: total);
      case OnboardingStep.methodSelect:
        return (step: 2, total: total);
      case OnboardingStep.method:
        if (draft == null || method == null) return null;
        return (step: draft.stepOfMethod(method), total: total);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = positionOf(
      ref.watch(onboardingDraftProvider),
      step,
      method: method,
      selected: selected,
    );
    if (position == null) return const SizedBox.shrink();
    if (pillOnly) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Center(
          child: LtPill(
            label: context.s.t('onboarding.step_pill', {
              'step': position.step,
              'total': position.total,
            }),
          ),
        ),
      );
    }
    return LtProgressSegments(total: position.total, filled: position.step);
  }
}
