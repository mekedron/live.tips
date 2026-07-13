import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_support.dart';
import '../../core/theme.dart';
import '../../domain/device_kind.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import '../../widgets/lt_ui.dart';
import '../venue/venue_intro_screen.dart';
import 'account_step_screen.dart';
import 'onboarding_flow.dart';

/// The FIRST onboarding step: what is this device? The answer is a property
/// of the install (see [DeviceKind]) and shapes everything after it — a
/// performer's phone walks the account/band flow, a venue tablet goes to the
/// shared-device sign-in, demo just plays.
class DeviceKindScreen extends ConsumerWidget {
  const DeviceKindScreen({super.key});

  Future<void> _pickPerformer(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await ref.read(deviceKindProvider.notifier).choose(DeviceKind.performer);
    if (!context.mounted) return;
    final offerSignIn = platformSupportsCloudAccounts &&
        ref.read(authControllerProvider.notifier).available &&
        ref.read(authControllerProvider).user == null;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => offerSignIn
            ? const AccountStepScreen()
            : firstBandSetupScreen(),
      ),
    );
  }

  Future<void> _pickVenue(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await ref.read(deviceKindProvider.notifier).choose(DeviceKind.venue);
    if (!context.mounted) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => const VenueIntroScreen()),
    );
  }

  Future<void> _pickDemo(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await ref.read(deviceKindProvider.notifier).choose(DeviceKind.demo);
    ref.read(appStateProvider.notifier).enterDemo();
    // The root gate swaps to the demo shell underneath — drop this stack.
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final s = context.s;
    final venueAvailable = platformSupportsCloudAccounts &&
        ref.read(authControllerProvider.notifier).available;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('onboarding.device_kind.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text(
                s.t('onboarding.device_kind.heading'),
                style: outfitStyle(22, c.text, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                s.t('onboarding.device_kind.subtitle'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _KindCard(
                icon: Icons.mic_external_on_rounded,
                iconColor: c.accent,
                iconBackground: c.accentSoft,
                title: s.t('onboarding.device_kind.performer_title'),
                body: s.t('onboarding.device_kind.performer_body'),
                onTap: () => unawaited(_pickPerformer(context, ref)),
              ),
              const SizedBox(height: 12),
              // The venue card wears warning colors on purpose: a shared
              // device is a different trust decision, and it should not look
              // like just another option.
              _KindCard(
                icon: Icons.storefront_rounded,
                iconColor: c.warning,
                iconBackground: c.warningContainer,
                border: c.warning,
                title: s.t('onboarding.device_kind.venue_title'),
                body: venueAvailable
                    ? s.t('onboarding.device_kind.venue_body')
                    : s.t('onboarding.device_kind.venue_unavailable'),
                enabled: venueAvailable,
                onTap: () => unawaited(_pickVenue(context, ref)),
              ),
              const SizedBox(height: 12),
              _KindCard(
                icon: Icons.play_circle_outline_rounded,
                iconColor: c.textSecondary,
                iconBackground: c.chip,
                title: s.t('onboarding.device_kind.demo_title'),
                body: s.t('onboarding.device_kind.demo_body'),
                onTap: () => unawaited(_pickDemo(context, ref)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.body,
    required this.onTap,
    this.border,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color? border;
  final String title;
  final String body;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      radius: 16,
      padding: EdgeInsets.zero,
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: border == null
            ? null
            : BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border!, width: 1.5),
              ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: outfitStyle(15.5, c.text,
                              weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13,
                          height: 1.4,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 22, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
