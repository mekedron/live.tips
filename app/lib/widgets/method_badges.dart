import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/tip_method.dart';

/// Small icon chip naming how a tip was paid (Revolut / MobilePay) — shown
/// only for relayed tips, so card tips stay unadorned and the eye goes
/// straight to the exceptions. Same chip language as [ExternalTag].
class MethodBadge extends StatelessWidget {
  const MethodBadge(this.method, {super.key});

  final TipMethod method;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Tooltip(
      message: 'Paid with ${method.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: c.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(method.icon, size: 11, color: c.textMuted),
            const SizedBox(width: 3),
            Text(
              method.label,
              style: outfitStyle(
                10.5,
                c.textMuted,
                weight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muted "unverified" pill for donor-declared tips: the relay can't see the
/// MobilePay/Revolut ledger, so it can't confirm the money actually moved.
/// Modeled on [ExternalTag] in donation_tile.dart — same size, same chip.
class UnverifiedTag extends StatelessWidget {
  const UnverifiedTag({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Tooltip(
      message:
          'Sent from your tip page — live.tips can\'t confirm the '
          'payment completed.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: c.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'unverified',
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
