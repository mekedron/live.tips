import 'dart:convert';

import '../../../../domain/rollover_math.dart';
import '../../../../domain/stage_settings.dart';

/// Dart side of renderer/PROTOCOL.md (v1). Pure data + (en/de)coding — no
/// I/O — so the whole protocol surface is unit-testable without a WebView.
const int kStageProtocolVersion = 1;

// ---------------------------------------------------------------- outgoing

sealed class StageOutMessage {
  Map<String, dynamic> toJson();

  /// The exact string handed to the JavaScriptChannel dispatcher.
  String encode() => jsonEncode({'v': kStageProtocolVersion, ...toJson()});
}

/// Renderer-facing view of [StageSettings] (+ layout insets). The `auto`
/// vessel is an app-side sentinel the renderer knows nothing about — callers
/// resolve it against the goal (see WebStage) before encoding.
Map<String, dynamic> stageConfigJson(
  StageSettings s, {
  required bool reducedMotion,
  required double insetTop,
  required double insetBottom,
  double insetRight = 0,
}) {
  assert(s.vessel != JarVessel.auto,
      'auto is an app-side sentinel — resolve it before crossing the bridge');
  return {
    'vessel': s.vessel.wire,
    'scene': s.scene.wire,
    'theme': s.theme.wire,
    'notes': s.showNotes,
    'sound': s.soundEnabled,
    'tipSound': s.tipSoundEnabled,
    'quality': s.quality.wire,
    'reducedMotion': reducedMotion,
    'insets': {'top': insetTop, 'bottom': insetBottom, 'right': insetRight},
  };
}

class StageInit extends StageOutMessage {
  StageInit({
    required this.renderer,
    required this.config,
    required this.jarPct,
    required this.bankedJars,
  });

  /// '3d' | '2d'
  final String renderer;
  final Map<String, dynamic> config;
  final double jarPct;
  final int bankedJars;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'init',
        'renderer': renderer,
        'config': config,
        'state': {'jarPct': jarPct, 'bankedJars': bankedJars},
      };
}

class StageTipMsg extends StageOutMessage {
  StageTipMsg(this.tip);

  final JarTipAttribution tip;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tip',
        'id': tip.tip.id,
        'deltaPct': tip.deltaPct,
        'jarPctAfter': tip.jarPctAfter,
        'rollovers': tip.rollovers,
      };
}

class StageSyncState extends StageOutMessage {
  StageSyncState({
    required this.jarPct,
    required this.bankedJars,
    this.instant = false,
  });

  final double jarPct;
  final int bankedJars;
  final bool instant;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'syncState',
        'state': {'jarPct': jarPct, 'bankedJars': bankedJars},
        if (instant) 'instant': true,
      };
}

class StageSetConfig extends StageOutMessage {
  StageSetConfig(this.partialConfig);

  /// Any subset of the config keys.
  final Map<String, dynamic> partialConfig;

  @override
  Map<String, dynamic> toJson() => {'type': 'setConfig', 'config': partialConfig};
}

class StageSetPaused extends StageOutMessage {
  StageSetPaused(this.paused);

  final bool paused;

  @override
  Map<String, dynamic> toJson() => {'type': 'setPaused', 'paused': paused};
}

class StageDemoPulse extends StageOutMessage {
  @override
  Map<String, dynamic> toJson() => {'type': 'demoPulse'};
}

// ---------------------------------------------------------------- incoming

sealed class StageInMessage {
  const StageInMessage();

  /// Null for malformed input or unknown types (ignored by contract).
  static StageInMessage? decode(String raw) {
    Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (parsed is! Map) return null;
    final map = Map<String, dynamic>.from(parsed);
    switch (map['type']) {
      case 'hello':
        return StageHello((map['protocol'] as num?)?.toInt() ?? 0);
      case 'ready':
        return const StageReady();
      case 'event':
        final kind = StageEventKind.fromWire(map['kind'] as String?);
        if (kind == null) return null; // unknown celebration — ignore
        return StageEvent(kind, ((map['jarPct'] as num?) ?? 0).toDouble());
      case 'perf':
        return StagePerf(
          fps: ((map['fps'] as num?) ?? 0).toDouble(),
          quality: map['quality'] as String? ?? '',
        );
      case 'error':
        return StageError(
          message: map['message'] as String? ?? 'unknown',
          fatal: map['fatal'] as bool? ?? false,
        );
      default:
        return null;
    }
  }
}

class StageHello extends StageInMessage {
  StageHello(this.protocol);
  final int protocol;
}

class StageReady extends StageInMessage {
  const StageReady();
}

enum StageEventKind {
  milestone('milestone'),
  goalReached('goalReached'),
  zoneFull('zoneFull'),
  rolloverDone('rolloverDone');

  const StageEventKind(this.wire);
  final String wire;

  static StageEventKind? fromWire(String? wire) {
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return null;
  }
}

class StageEvent extends StageInMessage {
  StageEvent(this.kind, this.jarPct);
  final StageEventKind kind;
  final double jarPct;
}

class StagePerf extends StageInMessage {
  StagePerf({required this.fps, required this.quality});
  final double fps;
  final String quality;
}

class StageError extends StageInMessage {
  StageError({required this.message, required this.fatal});
  final String message;
  final bool fatal;
}
