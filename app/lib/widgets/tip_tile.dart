import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/money.dart';
import '../core/theme.dart';
import '../domain/tip.dart';
import '../domain/tip_method.dart';
import '../l10n/app_localizations.dart';
import 'lt_ui.dart';
import 'method_badges.dart';

/// One tip row in the design language: tinted initial avatar, name,
/// message (or relative time), coral Outfit amount. Used on Home, in
/// History, and in session details.
class TipTile extends StatelessWidget {
  const TipTile({
    super.key,
    required this.tip,
    this.showTime = false,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.onTap,
  });

  final Tip tip;

  /// true → right-aligned time under the amount (History style).
  final bool showTime;
  final EdgeInsetsGeometry padding;

  /// When set, the row becomes tappable and shows a subtle open-in-new hint —
  /// History uses it to open the tip's transaction in Stripe.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final anonymous = tip.name == null || tip.name!.trim().isEmpty;
    final row = Padding(
      padding: padding,
      child: Row(
        children: [
          InitialAvatar(name: tip.displayName, anonymous: anonymous),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tip.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.text,
                        ),
                      ),
                    ),
                    if (tip.method != TipMethod.stripe) ...[
                      const SizedBox(width: 6),
                      MethodBadge(tip.method),
                    ],
                    if (tip.inPerson) ...[
                      const SizedBox(width: 6),
                      const InPersonTag(),
                    ],
                    if (!tip.verified) ...[
                      const SizedBox(width: 6),
                      const UnverifiedTag(),
                    ],
                    if (!tip.viaService) ...[
                      const SizedBox(width: 6),
                      const ExternalTag(),
                    ],
                  ],
                ),
                Text(
                  tip.hasMessage
                      ? tip.message!.trim()
                      : (showTime
                            ? context.s.t('widgets.tip_tile.no_message')
                            : relativeTime(context, tip.createdAt)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    color: tip.hasMessage ? c.textSecondary : c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatAmount(tip.amountMinor, tip.currency),
                style: outfitStyle(15, c.accent, weight: FontWeight.w700),
              ),
              if (showTime)
                Text(
                  shortTime(tip.createdAt),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 11,
                    color: c.textMuted,
                  ),
                ),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(width: 10),
            Icon(Icons.open_in_new_rounded, size: 14, color: c.textFaint),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Muted "External" pill flagging a payment that did NOT come through the
/// live.tips tip link — surfaced in History now that it lists every payment in
/// the account, not only the current link's. Ordinary live.tips tips are left
/// unmarked, so the tag draws the eye straight to the exceptions.
class ExternalTag extends StatelessWidget {
  const ExternalTag({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Tooltip(
      message: context.s.t('widgets.tip_tile.external_tooltip'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: c.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          context.s.t('widgets.tip_tile.external'),
          style: outfitStyle(
            10.5,
            c.textMuted,
            weight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// "just now / 4 min ago / 3 h ago / Jun 28"
String relativeTime(BuildContext context, DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) {
    return context.s.t('widgets.tip_tile.just_now');
  }
  if (diff.inMinutes < 60) {
    return context.s.t('widgets.tip_tile.min_ago', {'n': diff.inMinutes});
  }
  if (diff.inHours < 24) {
    return context.s.t('widgets.tip_tile.hours_ago', {'n': diff.inHours});
  }
  return DateFormat('MMM d').format(time);
}

/// "23:41" today, "Jun 28" otherwise.
String shortTime(DateTime time) {
  final now = DateTime.now();
  final sameDay =
      time.year == now.year && time.month == now.month && time.day == now.day;
  return sameDay
      ? DateFormat('HH:mm').format(time)
      : DateFormat('MMM d').format(time);
}
