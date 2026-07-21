import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/notifications_providers.dart';

/// Home's one-time offer to turn notifications on — for the artist who will
/// never find the Settings section on their own. Shows only while the tap
/// can actually deliver ([pushNudgeVisibleProvider]); Enable runs the whole
/// permission-and-token flow inside the tap, and "Not now" is forever on
/// this device — the nudge must never become a nag. _ReprintNoticeCard's
/// shape, in the accent tint instead of warning gold.
class PushNudgeCard extends ConsumerStatefulWidget {
  const PushNudgeCard({super.key});

  @override
  ConsumerState<PushNudgeCard> createState() => _PushNudgeCardState();
}

class _PushNudgeCardState extends ConsumerState<PushNudgeCard> {
  bool _busy = false;

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final outcome =
          await ref.read(pushRegistrationProvider).enableThisDevice();
      if (!mounted) return;
      if (outcome == PushEnableOutcome.failed ||
          outcome == PushEnableOutcome.noRegistration) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.s.t(outcome == PushEnableOutcome.noRegistration
              ? 'settings.notifications.enable_no_push'
              : 'settings.notifications.enable_failed')),
        ));
      }
    } finally {
      // Either way the status moved (granted → the enabled check hides the
      // card; denied → no longer canRequest, same outcome): re-read it.
      ref.invalidate(pushStatusProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(pushNudgeVisibleProvider)) return const SizedBox.shrink();
    final c = context.lt;
    final s = context.s;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_rounded,
                    size: 20, color: c.onAccentSoft),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.t('home.push_nudge.title'),
                    style: outfitStyle(14, c.text, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.t('home.push_nudge.body'),
              style:
                  TextStyle(fontSize: 13, color: c.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: _busy ? null : () => unawaited(_enable()),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.onAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    s.t('home.push_nudge.enable'),
                    style: outfitStyle(13.5, c.onAccent,
                        weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => unawaited(
                          ref.read(pushNudgeDismissedProvider.notifier).dismiss()),
                  child: Text(
                    s.t('home.push_nudge.dismiss'),
                    style: outfitStyle(13.5, c.textSecondary,
                        weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
