import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../core/fullscreen.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../domain/donation.dart';
import '../../../widgets/qr_card.dart';
import '../../poster/poster_screen.dart';
import 'stage_hud.dart' show kStageGlassSoft, kStageAmount;

/// Frosted-glass floating controls and the QR panel shared by the live stage
/// and its preview — extracted so both screens present identical chrome.

/// Round frosted-glass control on the dark stage: stop / goal / palette /
/// lock on the live screen, back on the preview.
class StageGlassButton extends StatelessWidget {
  const StageGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.tooltip,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: kStageGlassSoft,
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.45,
            color: iconColor ?? Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
    final control = tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
    // Web: the jar is an <iframe> platform view that would otherwise swallow
    // real clicks landing on this control — intercept so it stays tappable (a
    // harmless no-op off web). Orbit still works wherever no control sits.
    return PointerInterceptor(child: control);
  }
}

/// Squared-off sibling of [StageGlassButton] for the mobile bottom action bar.
class StageGlassSquare extends StatelessWidget {
  const StageGlassSquare({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child:
              Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.85)),
        ),
      ),
    );
    final control = tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
    return PointerInterceptor(child: control);
  }
}

/// Web-only fullscreen toggle for the stage — a native DOM button (see
/// [fullscreenButton]) styled to match the glass controls, so its click keeps
/// the user gesture `requestFullscreen()` needs. Renders nothing where
/// fullscreen isn't supported, so callers can drop it in unconditionally.
class StageFullscreenButton extends StatelessWidget {
  const StageFullscreenButton({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) => fullscreenButton(size: size);
}

/// How many recent-message tiles fit under the QR block of the wide-layout
/// panel. The QR always wins — messages only take what's left over after
/// the QR core (~430 px) and the section header, at ~84 px a tile.
int qrPanelMessageSlots(double maxHeight) =>
    ((maxHeight - 460) / 84).floor().clamp(0, 3);

/// The floating QR block on the wide (tablet/desktop) stage: scannable code,
/// the jar name, copy/open/print, and the latest tips that carried a message.
class StageQrPanel extends StatelessWidget {
  const StageQrPanel({
    super.key,
    required this.url,
    required this.name,
    this.messages = const [],
  });

  final String url;
  final String name;

  /// Latest tips that came with a message, newest first (capped upstream).
  final List<Donation> messages;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kStageGlassSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shown = messages.take(
            qrPanelMessageSlots(constraints.maxHeight),
          );
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrBlock(data: url, size: 200),
              const SizedBox(height: 14),
              Text(
                'Scan to tip',
                style: outfitStyle(20, Colors.white,
                    weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 6),
              // desktop reality: nobody scans a QR shown on their own screen
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Copy link',
                    onPressed: () => copyTipLink(context, url),
                    icon: Icon(Icons.content_copy_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  IconButton(
                    tooltip: 'Open link',
                    onPressed: () => openTipLink(url),
                    icon: Icon(Icons.open_in_new_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  IconButton(
                    tooltip: 'Print poster',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Poster')),
                          body: const PosterScreen(),
                        ),
                      ),
                    ),
                    icon: Icon(Icons.print_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              if (shown.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'RECENT MESSAGES',
                    style: outfitStyle(
                        10.5, Colors.white.withValues(alpha: 0.4),
                        weight: FontWeight.w700, letterSpacing: 1.4),
                  ),
                ),
                const SizedBox(height: 8),
                for (final d in shown) _QrPanelMessage(donation: d),
              ],
            ],
          );
        },
      ),
    );
    return PointerInterceptor(child: panel);
  }
}

class _QrPanelMessage extends StatelessWidget {
  const _QrPanelMessage({required this.donation});

  final Donation donation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  donation.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              Text(
                formatAmount(donation.amountMinor, donation.currency),
                style: const TextStyle(
                  fontFamily: kFontOutfit,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kStageAmount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '“${donation.message!.trim()}”',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
