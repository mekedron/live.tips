import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/lt_ui.dart';

/// The one explanatory step of venue onboarding: what a shared device is,
/// how artists get on it, and how they leave. Continue drops the route stack
/// — the device kind is already saved, so the root gate is showing the venue
/// sign-in screen underneath.
class VenueIntroScreen extends StatelessWidget {
  const VenueIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('venue.intro.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text(
                s.t('venue.intro.heading'),
                style: outfitStyle(22, c.text, weight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _Point(
                icon: Icons.phone_iphone_rounded,
                text: s.t('venue.intro.point_phone'),
              ),
              _Point(
                icon: Icons.timer_outlined,
                text: s.t('venue.intro.point_ceiling'),
              ),
              _Point(
                icon: Icons.logout_rounded,
                text: s.t('venue.intro.point_leave'),
              ),
              const SizedBox(height: 8),
              LtCard(
                radius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 22, color: c.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.t('venue.intro.warning'),
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13,
                          height: 1.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: s.t('venue.intro.continue'),
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: c.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
