import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/poster/poster_screen.dart';

/// Copy the tip link — the desktop-friendly path (nobody scans a QR code on
/// the machine that displays it).
Future<void> copyTipLink(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }
}

/// Open the tip link in the default browser.
Future<void> openTipLink(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// White-backed QR block for the tip link — scannable from a dark screen.
class QrBlock extends StatelessWidget {
  const QrBlock({super.key, required this.data, this.size = 220});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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

/// QR + link + copy/share actions. Tapping the QR opens it fullscreen so a
/// phone camera can scan it from across the room.
class TipLinkCard extends StatelessWidget {
  const TipLinkCard({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
            ],
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => showFullscreenQr(context, url),
                child: QrBlock(data: url, size: 190),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              url,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => copyTipLink(context, url),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () =>
                      SharePlus.instance.share(ShareParams(text: url)),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PosterScreen()),
                  ),
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
            const SizedBox(height: 16),
            const Text(
              'Scan to tip 💛',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => copyTipLink(context, url),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy link'),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: () => openTipLink(url),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
