import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../core/fullscreen.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../domain/tip.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/install_steps.dart';
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
          child: Icon(
            icon,
            size: 20,
            color: Colors.white.withValues(alpha: 0.85),
          ),
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
        tooltip: context.s.t('stage.fullscreen'),
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
        24,
        20,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
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
                child: const Icon(
                  Icons.fullscreen_rounded,
                  color: kStageAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.s.t('stage.fullscreen_iphone_title'),
                  style: outfitStyle(18, Colors.white, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.s.t('stage.fullscreen_iphone_body'),
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 18),
          // Shared with the onboarding install nudge — see widgets/install_steps.
          // The stage hint only ever fires on iPhone, so the Apple steps apply.
          InstallStepList(
            steps: installSteps(context, apple: true),
            numberBg: Colors.white.withValues(alpha: 0.08),
            numberFg: Colors.white,
            iconColor: Colors.white.withValues(alpha: 0.7),
            textColor: Colors.white.withValues(alpha: 0.85),
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
              child: Text(
                context.s.t('stage.got_it'),
                style: outfitStyle(
                  15,
                  const Color(0xFF40160A),
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
  final List<Tip> messages;

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
          // The code grows with the rail (a wider rail was the whole point of
          // making it resizable) but stays scannable-square, capped so it never
          // eats the header/messages room.
          final qrSize = constraints.maxWidth.clamp(180.0, 320.0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrBlock(data: url, size: qrSize),
              const SizedBox(height: 14),
              Text(
                context.s.t('stage.scan_to_tip'),
                style: outfitStyle(20, Colors.white, weight: FontWeight.w700),
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
                    tooltip: context.s.t('stage.copy_link'),
                    onPressed: () => copyTipLink(context, url),
                    icon: Icon(
                      Icons.content_copy_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  IconButton(
                    tooltip: context.s.t('stage.open_link'),
                    onPressed: () => openTipLink(url),
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  IconButton(
                    tooltip: context.s.t('stage.print_poster'),
                    onPressed: () => openPoster(context),
                    icon: Icon(
                      Icons.print_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
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
                    context.s.t('stage.recent_messages'),
                    style: outfitStyle(
                      10.5,
                      Colors.white.withValues(alpha: 0.4),
                      weight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final d in shown) _QrPanelMessage(tip: d),
              ],
            ],
          );
        },
      ),
    );
    return PointerInterceptor(child: panel);
  }
}

/// The wide-stage QR rail with a drag handle on its inner (left) edge. The rail
/// is right-anchored, so dragging the handle LEFT widens it and RIGHT narrows
/// it. The parent owns the width: [onResize] fires live with the new, clamped
/// value each drag frame (re-flowing every left-side element and re-centring
/// the jar as it feeds the width back into the layout + renderer insets), and
/// [onResizeCommit] fires once on release so the parent can persist the choice.
class ResizableQrRail extends StatelessWidget {
  const ResizableQrRail({
    super.key,
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.url,
    required this.name,
    required this.onResize,
    required this.onResizeCommit,
    this.messages = const [],
  });

  final double width;
  final double minWidth;
  final double maxWidth;
  final String url;
  final String name;
  final List<Tip> messages;
  final ValueChanged<double> onResize;
  final VoidCallback onResizeCommit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: StageQrPanel(url: url, name: name, messages: messages),
        ),
        // The grip straddles the rail's left edge, running its full height so
        // it's easy to grab from a distance on a tablet. Its own interceptor is
        // deliberately WIDE (reaching ~26px into the jar) so that at the start
        // of a leftward drag the cursor is still over an interceptor while the
        // full-stage shield mounts a frame later — no gap for the iframe to
        // grab the pointer and abort the resize.
        Positioned(
          left: -26,
          top: 0,
          bottom: 0,
          width: 52,
          child: _RailResizeHandle(
            onDrag: (dx) =>
                onResize((width - dx).clamp(minWidth, maxWidth).toDouble()),
            onDragEnd: onResizeCommit,
          ),
        ),
      ],
    );
  }
}

/// The draggable pill grip for [ResizableQrRail]. A wide invisible hit-strip
/// around a slim visible bar; shows a resize cursor and reports the horizontal
/// drag delta via [onDrag], committing on release with [onDragEnd].
///
/// The tricky part is the web jar: it renders as an <iframe> platform view that
/// swallows every mouse/touch event the moment the cursor is over it. The grip
/// itself sits in a [PointerInterceptor] so the drag can *start*, but as soon as
/// the performer drags left onto the jar, the raw pointer stream would fall into
/// the iframe and the resize would stall. So on pointer-down we drop a
/// FULL-STAGE [PointerInterceptor] shield into the overlay: it covers the iframe
/// for the duration of the gesture, keeping every move/up event flowing to
/// Flutter (this Listener), and tears down on release. All of this is a harmless
/// no-op off web, where nothing steals the events in the first place.
class _RailResizeHandle extends StatefulWidget {
  const _RailResizeHandle({required this.onDrag, required this.onDragEnd});

  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;

  @override
  State<_RailResizeHandle> createState() => _RailResizeHandleState();
}

class _RailResizeHandleState extends State<_RailResizeHandle> {
  OverlayEntry? _shield;
  double _lastX = 0;

  void _onDown(PointerDownEvent e) {
    _lastX = e.position.dx;
    _shield?.remove();
    // The pointer-down hit-test routes the whole gesture's move/up events back
    // to THIS listener; the shield's only job is to stop the iframe from eating
    // them so they ever reach Flutter. Hence it needs no listener of its own.
    _shield = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: PointerInterceptor(
          child: const MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_shield!);
  }

  void _onMove(PointerMoveEvent e) {
    final dx = e.position.dx - _lastX;
    _lastX = e.position.dx;
    if (dx != 0) widget.onDrag(dx);
  }

  void _onUp([PointerEvent? _]) {
    if (_shield == null) return;
    _shield!.remove();
    _shield = null;
    widget.onDragEnd();
  }

  @override
  void dispose() {
    _shield?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onUp,
          child: Center(
            child: Container(
              width: 5,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrPanelMessage extends StatelessWidget {
  const _QrPanelMessage({required this.tip});

  final Tip tip;

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
                  tip.displayName,
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
                formatAmount(tip.amountMinor, tip.currency),
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
            '“${tip.message!.trim()}”',
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
