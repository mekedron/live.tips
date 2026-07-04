import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../domain/rollover_math.dart';
import 'stage_types.dart';

/// Vertical space the HUD occupies at the top / the mini-feed at the bottom —
/// sent to the renderer as `insets` so the vessel frames into the free band.
const double kStageHudTopInset = 132;
const double kStageHudBottomInset = 84;

/// Native text overlay for the jar stages. The renderer draws NO text — real
/// currency formatting, fonts and accessibility all live here. Wrapped in
/// IgnorePointer by the caller so orbit gestures reach the WebView below.
class StageHud extends StatelessWidget {
  const StageHud({
    super.key,
    required this.snapshot,
    this.trophyPulse = 0,
  });

  final StageSnapshot snapshot;

  /// Bumped when the renderer reports `rolloverDone` — pulses the trophy line.
  final int trophyPulse;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final jarPctRounded = (s.jarPct * 100).round();
    return Column(
      children: [
        // ---- top band: the numbers that matter, readable from the bar ----
        SizedBox(
          height: kStageHudTopInset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatAmount(s.totalMinor, s.currency),
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                    shadows: [Shadow(blurRadius: 18, color: Colors.black87)],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // the user's ask: ALWAYS show what belongs to the current jar
              Text(
                'this jar: ${formatAmount(s.currentJarMinor, s.currency)}'
                ' of ${formatAmount(s.goalMinor, s.currency)}'
                ' · $jarPctRounded%',
                style: TextStyle(
                  fontSize: 16,
                  color: s.jarPct >= 1 ? const Color(0xFF7DDE8A) : Colors.white70,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(blurRadius: 12, color: Colors.black)],
                ),
              ),
              if (s.bankedJars > 0) ...[
                const SizedBox(height: 3),
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
          const Icon(Icons.emoji_events_rounded, size: 17, color: kGold),
          const SizedBox(width: 5),
          Text(
            '${formatAmount(bankedMinor, currency)} in $bankedJars full '
            '${bankedJars == 1 ? 'jar' : 'jars'}',
            style: const TextStyle(
              fontSize: 15,
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

/// Compact donation ticker for the jar stages: the last few tips, faded,
/// bottom-left — the jar is the show, the feed just whispers.
class StageMiniFeed extends StatelessWidget {
  const StageMiniFeed({super.key, required this.snapshot});

  final StageSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tips = snapshot.recentDonations.take(3).toList();
    if (tips.isEmpty) {
      return Text(
        'Waiting for the first tip…',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tips.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Opacity(
              opacity: 1 - i * 0.28,
              child: Text(
                '${tips[i].displayName} · '
                '${formatAmount(tips[i].amountMinor, tips[i].currency)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
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
/// notification. One donation at a time: name, amount and the full message,
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
        : _current!.donation.hasMessage
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
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        // just below the HUD numbers, over the jar's headroom
        padding: const EdgeInsets.only(top: kStageHudTopInset + 10),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 480),
          reverseDuration: const Duration(milliseconds: 320),
          transitionBuilder: (child, animation) {
            // separate curves: the pop may overshoot, opacity must not
            final fade =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            final pop =
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
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
                  key: ValueKey(_current!.donation.id), tip: _current!),
        ),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({super.key, required this.tip});

  final JarTipAttribution tip;

  @override
  Widget build(BuildContext context) {
    final d = tip.donation;
    final big = tip.deltaPct >= 0.1; // a tenth of tonight's goal in one tip
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: kGold.withValues(alpha: big ? 0.95 : 0.55),
          width: big ? 2 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: big ? 0.4 : 0.2),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${big ? '👑' : '💛'} ${d.displayName} tipped '
            '${formatAmount(d.amountMinor, d.currency)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: big ? 22 : 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (d.hasMessage) ...[
            const SizedBox(height: 6),
            Text(
              '“${d.message!.trim()}”',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Color(0xFFFFE9B0),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
