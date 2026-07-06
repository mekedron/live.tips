import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme.dart';
import '../../../../domain/rollover_math.dart';
import '../../../../domain/stage_settings.dart';
import '../stage_hud.dart';
import '../stage_overlay.dart';
import '../stage_resolver.dart';
import '../stage_types.dart';
import 'stage_bridge_codec.dart';
import 'stage_transport.dart';

/// Hosts one renderer of the JS stage library and keeps it honest:
/// handshake (hello → init → ready), tip/сonfig diffing, lifecycle pause,
/// and a watchdog that reloads once and then falls back gracefully.
class WebStage extends ConsumerStatefulWidget {
  const WebStage({
    super.key,
    required this.renderer, // '3d' | '2d'
    required this.snapshot,
    required this.tips,
    required this.tipSerial,
    required this.config,
    this.demoPulseTick = 0,
  });

  final String renderer;
  final StageSnapshot snapshot;
  final List<JarTipAttribution> tips;
  final int tipSerial;
  final StageSettings config;
  final int demoPulseTick;

  @override
  ConsumerState<WebStage> createState() => _WebStageState();
}

class _WebStageState extends ConsumerState<WebStage> {
  late final StageTransport _transport;
  late final AppLifecycleListener _lifecycle;

  var _ready = false;
  var _reloadedOnce = false;
  var _paused = false;
  var _seenTipSerial = 0;
  var _seenPulseTick = 0;
  var _trophyPulse = 0;
  var _weakPerfStreak = 0;
  double _syncedJarPct = 0;
  int _syncedGoal = 0;
  double _sentRailInset = 0;
  Timer? _readyDeadline;
  Timer? _heartbeatCheck;
  DateTime _lastAlive = DateTime.now();

  @override
  void initState() {
    super.initState();
    _seenTipSerial = widget.tipSerial;
    _seenPulseTick = widget.demoPulseTick;
    _syncedJarPct = widget.snapshot.jarPct;
    _syncedGoal = widget.snapshot.goalMinor;
    _transport = ref.read(stageTransportFactoryProvider)();
    _transport.onMessage = _onMessage;
    stageOverlayDepth.addListener(_syncStageInteractive);
    _syncStageInteractive();
    _armReadyDeadline();
    _heartbeatCheck = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_ready &&
          !_paused &&
          DateTime.now().difference(_lastAlive).inSeconds > 16) {
        _fail('renderer went silent');
      }
    });
    _lifecycle = AppLifecycleListener(onStateChange: (s) {
      // `inactive` fires the instant focus merely shifts away from the top
      // Flutter view — on Flutter Web that includes focus moving into our
      // OWN iframe (e.g. dragging to rotate the 3D scene), which is normal,
      // continuous use, not backgrounding. Flutter Web synthesizes it from a
      // plain `window.blur`, with no matching `focus` while the user keeps
      // interacting with the stage — so treating it as "pause" freezes the
      // stage on the first drag and never un-freezes it. Only states that
      // mean genuinely-not-visible should pause.
      final pause = s == AppLifecycleState.hidden ||
          s == AppLifecycleState.paused ||
          s == AppLifecycleState.detached;
      if (pause == _paused) return;
      _paused = pause;
      _lastAlive = DateTime.now(); // don't count sleep as silence
      _transport.send(StageSetPaused(pause));
    });
  }

  void _armReadyDeadline() {
    _readyDeadline?.cancel();
    _readyDeadline = Timer(const Duration(seconds: 8), () {
      if (!_ready) _fail('renderer never became ready');
    });
  }

  void _onMessage(StageInMessage msg) {
    _lastAlive = DateTime.now();
    switch (msg) {
      case StageHello(:final protocol):
        if (protocol != kStageProtocolVersion) {
          _giveUp('protocol $protocol ≠ $kStageProtocolVersion');
          return;
        }
        _sendInit();
      case StageReady():
        _readyDeadline?.cancel();
        if (mounted) setState(() => _ready = true);
        if (_paused) _transport.send(StageSetPaused(true));
      case StageEvent(:final kind):
        switch (kind) {
          case StageEventKind.rolloverDone:
            HapticFeedback.heavyImpact();
            if (mounted) setState(() => _trophyPulse++);
          case StageEventKind.goalReached || StageEventKind.zoneFull:
            HapticFeedback.mediumImpact();
          case StageEventKind.milestone:
            break; // per-donation haptics already fire at screen level
        }
      case StagePerf(:final fps):
        if (widget.renderer == '3d' && _ready && !_paused) {
          if (fps > 0 && fps < 15) {
            if (++_weakPerfStreak >= 3) {
              ref.read(stageHealthProvider.notifier).reportJar3dUnfit();
            }
          } else {
            _weakPerfStreak = 0;
          }
        }
      case StageError(:final message, :final fatal):
        debugPrint('stage error: $message');
        if (fatal) _fail(message);
    }
  }

  /// Strip to keep clear on the right so the jar frames LEFT of the QR rail —
  /// only the wide (tablet+) layout floats that rail. See [kStageRailInset].
  double get _railInset =>
      MediaQuery.sizeOf(context).width > 780 ? kStageRailInset : 0;

  void _sendInit() {
    final railInset = _railInset;
    _transport.send(StageInit(
      renderer: widget.renderer,
      config: stageConfigJson(
        widget.config,
        reducedMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
        insetTop: kStageHudTopInset,
        insetBottom: kStageHudBottomInset,
        insetRight: railInset,
      ),
      jarPct: widget.snapshot.jarPct,
      bankedJars: widget.snapshot.bankedJars,
    ));
    _sentRailInset = railInset;
    _syncedJarPct = widget.snapshot.jarPct;
    _syncedGoal = widget.snapshot.goalMinor;
  }

  /// One silent reload, then admit defeat and let the resolver fall back.
  void _fail(String reason) {
    if (!_reloadedOnce) {
      _reloadedOnce = true;
      _ready = false;
      debugPrint('stage watchdog: $reason — reloading once');
      _transport.reload();
      _armReadyDeadline();
    } else {
      _giveUp(reason);
    }
  }

  void _giveUp(String reason) {
    debugPrint('stage failed permanently: $reason');
    _readyDeadline?.cancel();
    _heartbeatCheck?.cancel();
    ref.read(stageHealthProvider.notifier).reportWebViewFailure();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('The jar stage is unavailable here — showing the classic '
                'screen instead.'),
      ));
    }
  }

  @override
  void didUpdateWidget(WebStage old) {
    super.didUpdateWidget(old);

    // settings edited live → diff into one partial setConfig
    if (widget.config != old.config) {
      final o = old.config, n = widget.config;
      final patch = <String, dynamic>{
        if (n.vessel != o.vessel) 'vessel': n.vessel.wire,
        if (n.scene != o.scene) 'scene': n.scene.wire,
        if (n.theme != o.theme) 'theme': n.theme.wire,
        if (n.showNotes != o.showNotes) 'notes': n.showNotes,
        if (n.soundEnabled != o.soundEnabled) 'sound': n.soundEnabled,
        if (n.tipSoundEnabled != o.tipSoundEnabled)
          'tipSound': n.tipSoundEnabled,
        if (n.quality != o.quality) 'quality': n.quality.wire,
      };
      if (patch.isNotEmpty) _transport.send(StageSetConfig(patch));
    }

    // new donations → pour them exactly as attributed
    if (widget.tipSerial != _seenTipSerial) {
      _seenTipSerial = widget.tipSerial;
      for (final tip in widget.tips) {
        _transport.send(StageTipMsg(tip));
      }
      if (widget.tips.isNotEmpty) {
        _syncedJarPct = widget.tips.last.jarPctAfter;
        _syncedGoal = widget.snapshot.goalMinor;
      }
    } else if (widget.snapshot.goalMinor != _syncedGoal ||
        (widget.snapshot.jarPct - _syncedJarPct).abs() > 0.001) {
      // fill moved WITHOUT tips → a goal edit (possibly with owed rollovers)
      // or some other correction: resync absolutely, animated
      _syncedJarPct = widget.snapshot.jarPct;
      _syncedGoal = widget.snapshot.goalMinor;
      _transport.send(StageSyncState(
        jarPct: widget.snapshot.jarPct,
        bankedJars: widget.snapshot.bankedJars,
      ));
    }

    // preview screen poked the "tip" button
    if (widget.demoPulseTick != _seenPulseTick) {
      _seenPulseTick = widget.demoPulseTick;
      _transport.send(StageDemoPulse());
    }
  }

  /// Web: while a modal covers the stage, make the iframe inert so the modal
  /// stays clickable over it (see stage_overlay.dart). No-op on native.
  void _syncStageInteractive() =>
      _transport.setInteractive(stageOverlayDepth.value == 0);

  @override
  void dispose() {
    _readyDeadline?.cancel();
    _heartbeatCheck?.cancel();
    stageOverlayDepth.removeListener(_syncStageInteractive);
    _lifecycle.dispose();
    _transport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _transport;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 780;
      // Re-frame the jar when the QR rail appears/disappears after the renderer
      // is already live (e.g. rotating a tablet across the wide threshold) —
      // _sendInit only covers the first frame's inset.
      final railInset = wide ? kStageRailInset : 0.0;
      if (_ready && railInset != _sentRailInset) {
        _sentRailInset = railInset;
        _transport.send(StageSetConfig({
          'insets': {
            'top': kStageHudTopInset,
            'bottom': kStageHudBottomInset,
            'right': railInset,
          },
        }));
      }
      // Centred top overlays (HUD total/bar, tip banner) slide left with the
      // jar on wide stages so they stay over it, clear of the QR rail. Half the
      // reserved strip == the jar's own leftward shift, for any width.
      final overlayShift = -railInset / 2;
      final safeBottom = MediaQuery.paddingOf(context).bottom;
      // On phones the glass action bar floats over the bottom band — the
      // mini feed must clear it.
      final feedBottom = 12.0 + (wide ? 0 : 84) + safeBottom;
      return Stack(
        fit: StackFit.expand,
        children: [
          if (t is WebViewStageTransport)
            WebViewWidget(controller: t.controller)
          else if (t is IframeStageTransport)
            HtmlElementView(viewType: t.viewType)
          else
            const ColoredBox(color: kStageBlack),
          // native poster until the renderer's first frame — no white flash
          if (!_ready)
            const ColoredBox(
              color: kStageBlack,
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ),
          // the native HUD floats above; IgnorePointer keeps orbit gestures
          // flowing into the WebView. On wide stages it slides left with the
          // jar (overlayShift) so the total/bar stay centred over it.
          IgnorePointer(
            child: Transform.translate(
              offset: Offset(overlayShift, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StageHud(
                    snapshot: widget.snapshot, trophyPulse: _trophyPulse),
              ),
            ),
          ),
          // the donation banner rides the same shift so it pops up centred
          // over the jar, not under the rail
          IgnorePointer(
            child: Transform.translate(
              offset: Offset(overlayShift, 0),
              child: TipBannerLayer(
                  tips: widget.tips, tipSerial: widget.tipSerial),
            ),
          ),
          // The bottom-left mini feed duplicates the QR rail's recent list, so
          // it only shows when the rail is hidden (phone / narrow).
          if (!wide)
            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 16, bottom: feedBottom),
                  child: StageMiniFeed(snapshot: widget.snapshot),
                ),
              ),
            ),
        ],
      );
    });
  }
}
