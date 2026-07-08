import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Shared "Add to Home Screen" instructions — the single source of truth for
/// both the stage's fullscreen hint and the onboarding install nudge, so the
/// wording and glyphs only ever change in one place.

/// One install step: a glyph and its line of copy.
class InstallStep {
  const InstallStep(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// The platform-appropriate steps. iOS/iPadOS installs through Safari's Share
/// sheet; Android through the browser menu.
List<InstallStep> installSteps(BuildContext context, {required bool apple}) =>
    apple
    ? [
        InstallStep(
          Icons.ios_share_rounded,
          context.s.t('widgets.install_steps.ios_share'),
        ),
        InstallStep(
          Icons.add_box_outlined,
          context.s.t('widgets.install_steps.ios_add'),
        ),
        InstallStep(
          Icons.rocket_launch_rounded,
          context.s.t('widgets.install_steps.open_fullscreen'),
        ),
      ]
    : [
        InstallStep(
          Icons.more_vert_rounded,
          context.s.t('widgets.install_steps.android_menu'),
        ),
        InstallStep(
          Icons.install_mobile_rounded,
          context.s.t('widgets.install_steps.android_install'),
        ),
        InstallStep(
          Icons.rocket_launch_rounded,
          context.s.t('widgets.install_steps.open_fullscreen'),
        ),
      ];

/// Renders [steps] as numbered rows — a number bubble, the action's glyph, then
/// the instruction. Colors are injected so the identical list sits on the dark
/// stage sheet and on a themed onboarding card alike.
class InstallStepList extends StatelessWidget {
  const InstallStepList({
    super.key,
    required this.steps,
    required this.numberBg,
    required this.numberFg,
    required this.iconColor,
    required this.textColor,
  });

  final List<InstallStep> steps;
  final Color numberBg;
  final Color numberFg;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: numberBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${i + 1}',
                  style: outfitStyle(13, numberFg, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Icon(steps[i].icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  steps[i].text,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 14,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
