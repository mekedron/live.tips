import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../core/fullscreen.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../domain/donation.dart';
import '../../../widgets/qr_card.dart';
import '../../poster/poster_screen.dart';
import 'stage_hud.dart' show kStageGlassSoft, kStageAmount, kStageAccent;

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

/// Fullscreen control for the stage. Where the browser has a real Fullscreen
/// API (desktop, Android, iPad) this is a native DOM button (see
/// [fullscreenButton]) whose raw click keeps the user gesture
/// `requestFullscreen()` needs. On iPhone — which has no Fullscreen API at all
/// — it becomes an "Add to Home Screen" hint, the only way to get a chrome-free
/// stage there. Renders nothing where neither applies, so callers can gate on
/// [fullscreenAvailable] and drop it in.
class StageFullscreenButton extends StatelessWidget {
  const StageFullscreenButton({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    if (fullscreenSupported) return fullscreenButton(size: size);
    if (fullscreenNeedsInstall) {
      return StageGlassButton(
        icon: Icons.fullscreen_rounded,
        tooltip: 'Fullscreen',
        size: size,
        onTap: () => showAddToHomeScreenSheet(context),
      );
    }
    return const SizedBox.shrink();
  }
}

/// iPhone Safari can't enter true fullscreen, but a Home-Screen PWA runs
/// without browser bars — this sheet walks the performer through installing it.
/// Shown from [StageFullscreenButton] on iPhone in place of a dead toggle.
void showAddToHomeScreenSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1B1613),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kStageAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fullscreen_rounded,
                    color: kStageAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Go fullscreen on iPhone',
                    style:
                        outfitStyle(18, Colors.white, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'iPhone Safari can’t expand a web page to fullscreen. Add live.tips '
            'to your Home Screen once and it launches with no browser bars — a '
            'clean, full-screen stage.',
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 18),
          const _InstallStep(
            n: '1',
            icon: Icons.ios_share_rounded,
            text: 'Tap the Share button in Safari’s toolbar.',
          ),
          const _InstallStep(
            n: '2',
            icon: Icons.add_box_outlined,
            text: 'Choose “Add to Home Screen”.',
          ),
          const _InstallStep(
            n: '3',
            icon: Icons.rocket_launch_rounded,
            text: 'Open live.tips from your Home Screen — fullscreen.',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kStageAccent,
                foregroundColor: const Color(0xFF40160A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it',
                  style: outfitStyle(15, const Color(0xFF40160A),
                      weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InstallStep extends StatelessWidget {
  const _InstallStep({required this.n, required this.icon, required this.text});

  final String n;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Text(n,
                style: outfitStyle(13, Colors.white, weight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 14,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
                    onPressed: () => openPoster(context),
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
