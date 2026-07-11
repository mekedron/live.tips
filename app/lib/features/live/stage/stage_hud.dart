import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../domain/rollover_math.dart';
import '../../../l10n/app_localizations.dart';
import 'stage_types.dart';

/// Vertical space the HUD occupies at the top / the mini-feed at the bottom —
/// sent to the renderer as `insets` so the vessel frames into the free band.
const double kStageHudTopInset = 150;
const double kStageHudBottomInset = 96;

/// Clear strip reserved on the right of a wide stage so the jar frames to the
/// LEFT of the QR rail — centring it in the visible working area instead of
/// letting the rail crowd it. Sent to the renderer as `insets.right` (it pans
/// the camera / pivot left by half of this). = the (now drag-resizable) rail
/// [railWidth] + its 16px right margin + a 16px breathing gap.
double stageRailInset(double railWidth) => railWidth + 32;

/// Coral accent + warm whites of the always-dark stage.
const kStageAccent = Color(0xFFFF7C55);
const kStageAmount = Color(0xFFFF9E7E);
const kStageGlass = Color(0xE614110E); // rgba(20,17,20,.9-ish) legible glass
const kStageGlassSoft = Color(0xB314110E);

/// Native text overlay for the jar stages. The renderer draws NO text — real
/// currency formatting, fonts and accessibility all live here. Wrapped in
/// IgnorePointer by the caller so orbit gestures reach the WebView below.
class StageHud extends StatelessWidget {
  const StageHud({super.key, required this.snapshot, this.trophyPulse = 0});

  final StageSnapshot snapshot;

  /// Bumped when the renderer reports `rolloverDone` — pulses the trophy line.
  final int trophyPulse;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final jarPctRounded = (s.jarPct * 100).round();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 780;
        final barWidth = wide ? 320.0 : 220.0;
        // Tablet: the money clears the top control row — the LIVE / status
        // pills (44px tall) flank the centred total, so drop it below them
        // instead of letting them sit on top of the number.
        // Phone: it drops below the 40px control row.
        final topOffset =
            MediaQuery.paddingOf(context).top + (wide ? 68.0 : 72.0);
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: topOffset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatAmount(
                        s.totalMinor,
                        s.currency,
                        approximate: s.approximateTotal,
                      ),
                      style: TextStyle(
                        fontFamily: kFontOutfit,
                        fontSize: wide ? 60 : 46,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                        shadows: const [
                          Shadow(blurRadius: 24, color: Colors.black87),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: wide ? 12 : 10),
                  SizedBox(
                    width: barWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: wide ? 6 : 5,
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                            FractionallySizedBox(
                              widthFactor: s.jarPct.clamp(0.0, 1.0).toDouble(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kStageAccent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: wide ? 8 : 7),
                  Text(
                    context.s.t('stage.jar_progress', {
                          'current': formatAmount(
                            s.currentJarMinor,
                            s.currency,
                          ),
                          'goal': formatAmount(s.goalMinor, s.currency),
                          'pct': jarPctRounded,
                        }) +
                        (wide ? context.s.t('stage.of_tonights_goal') : ''),
                    style: TextStyle(
                      fontFamily: kFontOutfit,
                      fontSize: wide ? 14 : 12.5,
                      fontWeight: FontWeight.w600,
                      color: s.jarPct >= 1
                          ? const Color(0xFF4FCB8D)
                          : Colors.white.withValues(alpha: 0.7),
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black),
                      ],
                    ),
                  ),
                  if (s.bankedJars > 0) ...[
                    const SizedBox(height: 4),
                    _TrophyLine(
                      bankedJars: s.bankedJars,
                      bankedMinor: s.bankedMinor,
                      currency: s.currency,
                      pulse: trophyPulse,
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}

class _TrophyLine extends StatelessWidget {
  const _TrophyLine({
    required this.bankedJars,
    required this.bankedMinor,
    required this.currency,
    required this.pulse,
  });

  final int bankedJars;
  final int bankedMinor;
  final String currency;
  final int pulse;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(pulse),
      tween: Tween(begin: pulse == 0 ? 1 : 1.35, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, size: 16, color: kGold),
          const SizedBox(width: 5),
          Text(
            context.s.t('stage.trophy_line', {
              'amount': formatAmount(bankedMinor, currency),
              'count': bankedJars,
            }),
            style: const TextStyle(
              fontFamily: kFontOutfit,
              fontSize: 14,
              color: kGold,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(blurRadius: 12, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact tip ticker for the jar stages: the last few tips as fading
/// glass pills, bottom-left — the jar is the show, the feed just whispers.
class StageMiniFeed extends StatelessWidget {
  const StageMiniFeed({super.key, required this.snapshot});

  final StageSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tips = snapshot.recentTips.take(3).toList();
    if (tips.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: kStageGlassSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Text(
          context.s.t('stage.waiting_first_tip'),
          style: TextStyle(
            fontFamily: kFontOutfit,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tips.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Opacity(
              opacity: (1 - i * 0.25).clamp(0.3, 1.0).toDouble(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: kStageGlassSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tips[i].displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kFontOutfit,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      // "~" flags an unverified (fan-declared) amount.
                      '${tips[i].verified ? '' : '~'}'
                      '${formatAmount(tips[i].amountMinor, tips[i].currency)}',
                      style: const TextStyle(
                        fontFamily: kFontOutfit,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kStageAmount,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// How long a tip banner holds on screen (the exit animation comes on top).
/// Long on purpose: the artist is mid-song — the name and the message must
/// survive until the phrase ends and they can look down and say thanks.
const kTipBannerHold = Duration(seconds: 7);
const kTipBannerHoldWithMessage = Duration(seconds: 10);

/// With more tips waiting behind, banners rotate at this pace instead —
/// busy nights keep moving, quiet nights linger.
const kTipBannerHoldCrowded = Duration(seconds: 4);

/// A tip arriving mid-banner gives the current one this much time to wrap
/// up (never yanked away mid-read) before the queue advances.
const kTipBannerWrapUp = Duration(milliseconds: 2500);

const _kTipBannerGap = Duration(milliseconds: 260);

/// Long-lived "a tip arrived" banner over the stage — the artist-facing
/// notification. One tip at a time: name, amount and the full message,
/// held long enough to be read from a music stand; arrivals queue instead
/// of overlapping, so nobody's message is lost in a burst.
class TipBannerLayer extends StatefulWidget {
  const TipBannerLayer({
    super.key,
    required this.tips,
    required this.tipSerial,
  });

  final List<JarTipAttribution> tips;

  /// LiveState.confettiTick — [tips] is only enqueued when this advances.
  final int tipSerial;

  @override
  State<TipBannerLayer> createState() => _TipBannerLayerState();
}

class _TipBannerLayerState extends State<TipBannerLayer> {
  final _queue = <JarTipAttribution>[];
  JarTipAttribution? _current;
  int _seenSerial = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seenSerial = widget.tipSerial;
  }

  @override
  void didUpdateWidget(TipBannerLayer old) {
    super.didUpdateWidget(old);
    if (widget.tipSerial == _seenSerial) return;
    _seenSerial = widget.tipSerial;
    _queue.addAll(widget.tips);
    if (_current == null) {
      _timer?.cancel(); // may be idling in the inter-banner gap
      _showNext();
    } else {
      _timer?.cancel();
      _timer = Timer(kTipBannerWrapUp, _dismiss);
    }
  }

  void _showNext() {
    if (_queue.isEmpty) return;
    setState(() => _current = _queue.removeAt(0));
    final hold = _queue.isNotEmpty
        ? kTipBannerHoldCrowded
        : _current!.tip.hasMessage
        ? kTipBannerHoldWithMessage
        : kTipBannerHold;
    _timer = Timer(hold, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _current = null);
    if (_queue.isNotEmpty) _timer = Timer(_kTipBannerGap, _showNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 780;
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            // just below the HUD numbers, over the jar's headroom — follows the
            // total's tablet drop (see StageHud.topOffset) so it stays clear of it
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + (wide ? 204 : 188),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 480),
              reverseDuration: const Duration(milliseconds: 320),
              transitionBuilder: (child, animation) {
                // separate curves: the pop may overshoot, opacity must not
                final fade = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                final pop = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                );
                return FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.86, end: 1.0).animate(pop),
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(pop),
                      child: child,
                    ),
                  ),
                );
              },
              child: _current == null
                  ? const SizedBox.shrink(key: ValueKey('no-banner'))
                  : _TipBanner(
                      key: ValueKey(_current!.tip.id),
                      tip: _current!,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({super.key, required this.tip});

  final JarTipAttribution tip;

  @override
  Widget build(BuildContext context) {
    final d = tip.tip;
    // A tenth of tonight's goal in one tip — but never crown a fan-declared
    // (unverified) relay tip: the crown must stay worth trusting.
    final big = tip.deltaPct >= 0.1 && d.verified;
    final anonymous = d.name == null || d.name!.trim().isEmpty;
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kStageGlass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: kStageAccent.withValues(alpha: big ? 0.9 : 0.45),
          width: big ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          if (big)
            BoxShadow(
              color: kStageAccent.withValues(alpha: 0.35),
              blurRadius: 26,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: anonymous
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFF3E2018),
              shape: BoxShape.circle,
            ),
            child: Text(
              d.displayName.characters.first.toUpperCase(),
              style: TextStyle(
                fontFamily: kFontOutfit,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: anonymous
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFFFFB79F),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // "~" flags an unverified (fan-declared) amount.
                  '${big ? '👑 ' : ''}${context.s.t('stage.tipped', {'name': d.displayName, 'amount': '${d.verified ? '' : '~'}${formatAmount(d.amountMinor, d.currency)}'})}',
                  style: TextStyle(
                    fontFamily: kFontOutfit,
                    fontSize: big ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (d.hasMessage) ...[
                  const SizedBox(height: 2),
                  Text(
                    '“${d.message!.trim()}”',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
