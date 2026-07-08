import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Loud reminder that money on screen is not real (test key or demo mode).
class TestModeBanner extends StatelessWidget {
  const TestModeBanner({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final label =
        this.label ?? context.s.t('widgets.test_mode_banner.test_mode');
    return Container(
      width: double.infinity,
      color: const Color(0xFFB25E09),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        context.s.t('widgets.test_mode_banner.banner', {'label': label}),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
