import 'package:flutter/material.dart';

import '../core/money.dart';
import '../domain/donation.dart';

/// One donation row, used in the live feed and in history.
class DonationTile extends StatelessWidget {
  const DonationTile({super.key, required this.donation, this.dense = false});

  final Donation donation;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: dense,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          donation.displayName.characters.first.toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        donation.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: donation.hasMessage
          ? Text(
              donation.message!.trim(),
              maxLines: dense ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              _relativeTime(donation.createdAt),
              style: theme.textTheme.bodySmall,
            ),
      trailing: Text(
        formatAmount(donation.amountMinor, donation.currency),
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-'
      '${time.day.toString().padLeft(2, '0')}';
}
