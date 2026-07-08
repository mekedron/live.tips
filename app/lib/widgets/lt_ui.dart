import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Shared live.tips 2.0 building blocks: cards, pills, chips, segmented
/// controls, list rows — the vocabulary every screen speaks.

/// White (light) / #1E1A16 (dark) card with the 1px warm border.
class LtCard extends StatelessWidget {
  const LtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final body = Padding(padding: padding, child: child);
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// "TONIGHT'S GOAL" — tracked-out Outfit micro label.
class LtSectionLabel extends StatelessWidget {
  const LtSectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: outfitStyle(11, color ?? context.lt.textMuted,
          weight: FontWeight.w700, letterSpacing: 1.2),
    );
  }
}

/// Status of the connected account: green Live, soft-accent Test, neutral
/// Demo, amber-dotted Relay (a live.tips jar with no Stripe key).
enum LtKeyStatus { live, test, demo, relay }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.compact = false});

  final LtKeyStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final (bg, fg, label) = switch (status) {
      LtKeyStatus.live => (c.successContainer, c.onSuccessContainer, 'Live key'),
      LtKeyStatus.test => (c.warningContainer, c.onWarningContainer, 'Test key'),
      LtKeyStatus.demo => (c.chip, c.textSecondary, 'Demo'),
      LtKeyStatus.relay => (c.chip, c.textSecondary, 'No Stripe'),
    };
    final dot = switch (status) {
      LtKeyStatus.live => c.success,
      LtKeyStatus.test => c.warning,
      LtKeyStatus.demo => c.textMuted,
      LtKeyStatus.relay => kGold,
    };
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: outfitStyle(compact ? 11 : 12, fg)),
        ],
      ),
    );
  }
}

/// Soft rounded pill — "Step 1 of 2", "~2 min", the A4 selector…
class LtPill extends StatelessWidget {
  const LtPill({
    super.key,
    required this.label,
    this.soft = true,
    this.icon,
    this.trailing,
    this.onTap,
  });

  final String label;

  /// true → accent-soft (coral tint); false → neutral chip.
  final bool soft;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final bg = soft ? c.accentSoft : c.chip;
    final fg = soft ? c.onAccentSoft : c.textSecondary;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
          ],
          Text(label, style: outfitStyle(12, fg)),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: pill,
    );
  }
}

/// Two-step onboarding progress: filled coral segments on a warm track.
class LtProgressSegments extends StatelessWidget {
  const LtProgressSegments({super.key, required this.total, required this.filled});

  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < filled ? c.accent : c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The hero CTA: coral, radius 14, soft coral glow in light mode.
class LtPrimaryButton extends StatelessWidget {
  const LtPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final light = Theme.of(context).brightness == Brightness.light;
    final child = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: c.onAccent),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 20),
              ],
            ],
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: light && onPressed != null && !busy
            ? [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: child,
      ),
    );
  }
}

/// Full-width destructive secondary action — red outline, quieter than the
/// coral primary. Shared by the payment-method editors ("Disconnect Stripe",
/// "Remove Revolut", …) so every method screen removes the same way.
class LtDangerButton extends StatelessWidget {
  const LtDangerButton({
    super.key,
    required this.label,
    this.icon = Icons.link_off_rounded,
    this.onPressed,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.danger,
          side: BorderSide(color: c.danger.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: c.danger),
              )
            : Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

/// 36px round accent-soft icon button — the copy/share/print trio.
class LtIconCircleButton extends StatelessWidget {
  const LtIconCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final button = Material(
      color: c.accentSoft,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.47, color: c.onAccentSoft),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Circle with the donor's initial: named donors get the coral tint,
/// anonymous ones stay neutral.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.name,
    this.anonymous = false,
    this.size = 36,
  });

  final String name;
  final bool anonymous;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final bg = anonymous ? c.chip : c.accentSoft;
    final fg = anonymous ? c.textSecondary : c.onAccentSoft;
    final initial =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(initial,
          style: outfitStyle(size * 0.39, fg, weight: FontWeight.w700)),
    );
  }
}

/// Segmented control on the warm chip track; the selected segment floats
/// on a card-colored pill.
class LtSegmented<T> extends StatelessWidget {
  const LtSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.iconOf,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final IconData? Function(T)? iconOf;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: v == selected ? c.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: v == selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : const [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (iconOf?.call(v) != null) ...[
                          Icon(iconOf!(v),
                              size: 17,
                              color: v == selected ? c.text : c.textSecondary),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          labelOf(v),
                          style: outfitStyle(
                              13, v == selected ? c.text : c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A settings-card row: icon · title/subtitle · trailing. Compose inside
/// [LtRowGroup] which draws the dividers.
class LtRow extends StatelessWidget {
  const LtRow({
    super.key,
    this.icon,
    this.iconColor,
    this.leading,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.chevron = false,
    this.onTap,
  });

  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          if (icon != null) ...[
            Icon(icon, size: 22, color: iconColor ?? c.textSecondary),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? c.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 12.5,
                      color: c.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          if (chevron)
            Icon(Icons.chevron_right_rounded, size: 22, color: c.textMuted),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Card that stacks [LtRow]s (or anything) with hairline dividers between.
class LtRowGroup extends StatelessWidget {
  const LtRowGroup({super.key, this.header, required this.children});

  /// Optional section label rendered inside the card ("ACCOUNT", …).
  final String? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: LtSectionLabel(header!),
            ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Bottom-sheet single-choice picker. Returns the tapped value.
Future<T?> showLtPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> values,
  required T selected,
  required String Function(T) labelOf,
  String Function(T)? detailOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = context.lt;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
                child: Text(title,
                    style: outfitStyle(18, c.text, weight: FontWeight.w700)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    for (final v in values)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(v),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: v == selected
                                ? c.accentSoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      labelOf(v),
                                      style: TextStyle(
                                        fontFamily: kFontBody,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: v == selected
                                            ? c.onAccentSoft
                                            : c.text,
                                      ),
                                    ),
                                    if (detailOf != null)
                                      Text(
                                        detailOf(v),
                                        style: TextStyle(
                                          fontFamily: kFontBody,
                                          fontSize: 12.5,
                                          color: v == selected
                                              ? c.onAccentSoft
                                              : c.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (v == selected)
                                Icon(Icons.check_rounded,
                                    size: 20, color: c.onAccentSoft),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Numbered step bullet (soft coral circle).
class LtStepNumber extends StatelessWidget {
  const LtStepNumber(this.number, {super.key, this.size = 26});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
      child: Text('$number',
          style: outfitStyle(size * 0.5, c.onAccentSoft,
              weight: FontWeight.w700)),
    );
  }
}

/// Small stat card — "ALL-TIME / $1,824".
class LtStatCard extends StatelessWidget {
  const LtStatCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LtSectionLabel(label),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: moneyStyle(20, c.text, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
