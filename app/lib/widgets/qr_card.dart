import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/external_link.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Copy the tip link — the desktop-friendly path (nobody scans a QR code on
/// the machine that displays it).
Future<void> copyTipLink(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.t('widgets.qr_card.link_copied'))),
    );
  }
}

/// Open the tip link in the default browser.
Future<void> openTipLink(String url) => openExternal(url);

/// White-backed QR block for the tip link — scannable from a dark screen.
class QrBlock extends StatelessWidget {
  const QrBlock({
    super.key,
    required this.data,
    this.size = 220,
    this.padding = 12,
    this.radius = 16,
  });

  final String data;
  final double size;
  final double padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Fullscreen QR so a phone camera can scan it from across the room.
void showFullscreenQr(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => QrBlock(
                data: url,
                size: constraints.maxWidth.clamp(0, 420) - 60,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.s.t('widgets.qr_card.scan_to_tip'),
              style: outfitStyle(22, Colors.white, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => copyTipLink(context, url),
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                  label: Text(context.s.t('widgets.qr_card.copy_link')),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: () => openTipLink(url),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(context.s.t('common.open')),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
