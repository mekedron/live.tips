import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/money.dart';
import '../core/theme.dart';
import '../domain/donation.dart';
import 'lt_ui.dart';

/// One donation row in the design language: tinted initial avatar, name,
/// message (or relative time), coral Outfit amount. Used on Home, in
/// History, and in session details.
class DonationTile extends StatelessWidget {
  const DonationTile({
    super.key,
    required this.donation,
    this.showTime = false,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  final Donation donation;

  /// true → right-aligned time under the amount (History style).
  final bool showTime;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final anonymous = donation.name == null || donation.name!.trim().isEmpty;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          InitialAvatar(name: donation.displayName, anonymous: anonymous),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                Text(
                  donation.hasMessage
                      ? donation.message!.trim()
                      : (showTime ? 'No message' : relativeTime(donation.createdAt)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    color: donation.hasMessage ? c.textSecondary : c.textMuted,
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
                formatAmount(donation.amountMinor, donation.currency),
                style: outfitStyle(15, c.accent, weight: FontWeight.w700),
              ),
              if (showTime)
                Text(
                  shortTime(donation.createdAt),
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 11,
                      color: c.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "just now / 4 min ago / 3 h ago / Jun 28"
String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
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
