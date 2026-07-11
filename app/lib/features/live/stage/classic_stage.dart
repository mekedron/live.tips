import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../domain/donation.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/donation_tile.dart';
import 'stage_hud.dart' show kStageAccent, kStageAmount;
import 'stage_types.dart';

/// The original numbers-first stage: big total, animated goal bar, stat
/// chips, last-donation hero, feed. Extracted verbatim from the live screen —
/// fully native, no WebView, the terminal fallback everywhere.
class ClassicStage extends StatelessWidget {
  const ClassicStage({super.key, required this.snapshot});

  final StageSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final donations = snapshot.recentDonations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatAmount(
              snapshot.totalMinor,
              snapshot.currency,
              approximate: snapshot.approximateTotal,
            ),
            style: const TextStyle(
              fontFamily: kFontOutfit,
              fontSize: 96,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.s.t('stage.of_goal', {
            'goal': formatAmount(snapshot.goalMinor, snapshot.currency),
            'pct': (snapshot.progress * 100).round(),
          }),
          textAlign: TextAlign.center,
          style: outfitStyle(16, Colors.white.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 14),
        _GoalProgressBar(
          progress: snapshot.progress,
          reached: snapshot.goalReached,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              icon: Icons.favorite_rounded,
              label: context.s.t('stage.tips_count', {'count': snapshot.count}),
            ),
            if (snapshot.bankedJars > 0) ...[
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.emoji_events_rounded,
                label: context.s.t('stage.full_jars', {
                  'count': snapshot.bankedJars,
                }),
              ),
            ] else if (snapshot.biggest != null) ...[
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.emoji_events_rounded,
                label: context.s.t('stage.top_amount', {
                  'amount': formatAmount(
                    snapshot.biggest!.amountMinor,
                    snapshot.currency,
                  ),
                }),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        LastDonationHero(donation: snapshot.lastDonation),
        const SizedBox(height: 8),
        Expanded(
          child: donations.isEmpty
              ? Center(
                  child: Text(
                    context.s.t('stage.waiting_first_tip_qr'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: donations.length,
                  itemBuilder: (context, index) =>
                      DonationTile(donation: donations[index]),
                ),
        ),
      ],
    );
  }
}

class _GoalProgressBar extends StatelessWidget {
  const _GoalProgressBar({required this.progress, required this.reached});

  final double progress;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Container(
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.015, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                  colors: [kStageAccent, kStageAmount],
                ),
                boxShadow: reached
                    ? [
                        BoxShadow(
                          color: kStageAccent.withValues(alpha: 0.7),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kStageAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: outfitStyle(13.5, Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

/// "💛 Anna tipped €5" card with a fade+slide entrance. Shared with the jar
/// stages' HUD, hence public.
class LastDonationHero extends StatelessWidget {
  const LastDonationHero({super.key, this.donation, this.compact = false});

  final Donation? donation;

  /// Jar HUD variant: smaller text, no message body.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: donation == null
          ? SizedBox(height: compact ? 0 : 8, key: const ValueKey('empty'))
          : Container(
              key: ValueKey(donation!.id),
              padding: EdgeInsets.all(compact ? 10 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: kStageAccent.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                color: kStageAccent.withValues(alpha: compact ? 0.16 : 0.08),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.s.t('stage.tipped', {
                      'name': donation!.displayName,
                      'amount': formatAmount(
                        donation!.amountMinor,
                        donation!.currency,
                      ),
                    }),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kFontOutfit,
                      fontSize: compact ? 17 : 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (!compact && donation!.hasMessage) ...[
                    const SizedBox(height: 6),
                    Text(
                      '“${donation!.message!.trim()}”',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
