import 'package:flutter/material.dart';

import '../core/money.dart';
import '../core/theme.dart';
import 'lt_ui.dart';

/// Bottom-sheet editor for tonight's goal. Returns the new goal in minor
/// units, or null when dismissed.
Future<int?> showGoalEditorSheet(
  BuildContext context, {
  required int initialMinor,
  required String currency,
  String title = 'Tonight\'s goal',
}) {
  final controller =
      TextEditingController(text: formatMajorPlain(initialMinor, currency));
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = context.lt;
      int current() =>
          parseMajorToMinor(controller.text, currency) ?? initialMinor;
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: outfitStyle(18, c.text, weight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: outfitStyle(20, c.text, weight: FontWeight.w700),
              decoration: InputDecoration(
                suffixText: currency.toUpperCase(),
                suffixStyle: outfitStyle(14, c.textSecondary),
              ),
              onSubmitted: (_) => Navigator.of(context)
                  .pop(parseMajorToMinor(controller.text, currency)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final bump in [50, 100, 200]) ...[
                  _BumpChip(
                    label: '+$bump',
                    onTap: () => controller.text = formatMajorPlain(
                      current() + bump * minorUnitsPerMajor(currency),
                      currency,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _BumpChip(
                  label: '×2',
                  onTap: () => controller.text =
                      formatMajorPlain(current() * 2, currency),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LtPrimaryButton(
              label: 'Save goal',
              onPressed: () => Navigator.of(context)
                  .pop(parseMajorToMinor(controller.text, currency)),
            ),
          ],
        ),
      );
    },
  ).whenComplete(() {
    // Dispose after the sheet's exit animation is fully done.
    Future.delayed(const Duration(seconds: 1), controller.dispose);
  });
}

/// "+50 / +100 / ×2" quick-adjust chip.
class _BumpChip extends StatelessWidget {
  const _BumpChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: c.chip,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(label, style: outfitStyle(13, c.textSecondary)),
        ),
      ),
    );
  }
}
