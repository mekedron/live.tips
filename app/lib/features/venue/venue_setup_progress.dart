import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/lt_ui.dart';

/// The venue setup's own two-step counter, shaped exactly like the performer
/// onboarding's (`OnboardingProgress`): the pill in the app bar, the segments
/// above the heading, so the two flows read as the same app.
///
/// Unlike the performer run — whose account phase made every number a guess
/// and lost the right to show one — this run's length is a constant. Venue
/// setup is always the same two screens: how a shared device works, then the
/// sign-in code. That is why this widget may hard-code its total where the
/// performer one must derive it from the draft.
class VenueSetupProgress extends StatelessWidget {
  const VenueSetupProgress({
    super.key,
    required this.step,
    this.pillOnly = false,
  });

  static const int _total = 2;

  /// 1-based position in the setup run.
  final int step;

  /// The app-bar form (the pill); false renders the segment bar.
  final bool pillOnly;

  @override
  Widget build(BuildContext context) {
    if (pillOnly) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Center(
          child: LtPill(
            label: context.s
                .t('onboarding.step_pill', {'step': step, 'total': _total}),
          ),
        ),
      );
    }
    return LtProgressSegments(total: _total, filled: step);
  }
}
