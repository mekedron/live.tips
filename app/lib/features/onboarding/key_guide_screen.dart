import 'package:flutter/material.dart';
import '../../core/external_link.dart';

import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/lt_ui.dart';

/// In-app version of docs/onboarding/create-restricted-key.md — the full
/// walkthrough with screenshots lives in the repository.
class KeyGuideScreen extends StatelessWidget {
  const KeyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.t('onboarding.key_guide.title')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: LtPill(
                label: context.s.t('onboarding.key_guide.duration'),
                soft: false,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 22, color: c.onAccentSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.s.t('onboarding.key_guide.shortcut'),
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13,
                          height: 1.45,
                          color: c.onAccentSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: outfitStyle(12, Colors.white),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => openExternal(kCreateKeyUrl),
                      child: Text(
                        context.s.t('onboarding.key_guide.open_form'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _StepCard(
                number: 1,
                title: context.s.t('onboarding.key_guide.step1_title'),
                body: context.s.t('onboarding.key_guide.step1_body'),
              ),
              const SizedBox(height: 12),
              _StepCard(
                number: 2,
                title: context.s.t('onboarding.key_guide.step2_title'),
                body: context.s.t('onboarding.key_guide.step2_body'),
              ),
              const SizedBox(height: 12),
              _StepCard(
                number: 3,
                title: context.s.t('onboarding.key_guide.step3_title'),
                body: context.s.t('onboarding.key_guide.step3_body'),
              ),
              const SizedBox(height: 12),
              _StepCard(
                number: 4,
                title: context.s.t('onboarding.key_guide.step4_title'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    for (final p in kRequiredPermissions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p.resource,
                              style: TextStyle(
                                fontFamily: kFontBody,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.text,
                              ),
                            ),
                            Text(
                              p.access,
                              style: TextStyle(
                                fontFamily: kFontBody,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.access == 'Write'
                                    ? c.onAccentSoft
                                    : c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      context.s.t('onboarding.key_guide.everything_else_none'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _StepCard(
                number: 5,
                title: context.s.t('onboarding.key_guide.step5_title'),
                body: context.s.t('onboarding.key_guide.step5_body'),
              ),
              const SizedBox(height: 12),
              _StepCard(
                number: 6,
                title: context.s.t('onboarding.key_guide.step6_title'),
                body: context.s.t('onboarding.key_guide.step6_body'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => openExternal(kApiKeysDashboardUrl),
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: c.textSecondary,
                ),
                label: Text(context.s.t('onboarding.key_guide.open_dashboard')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    this.body,
    this.child,
  });

  final int number;
  final String title;
  final String? body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LtStepNumber(number),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: outfitStyle(14.5, c.text)),
                if (body != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    body!,
                    style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13,
                      height: 1.45,
                      color: c.textSecondary,
                    ),
                  ),
                ],
                ?child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
