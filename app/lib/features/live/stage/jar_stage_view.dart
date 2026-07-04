import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/rollover_math.dart';
import '../../../domain/stage_settings.dart';
import 'classic_stage.dart';
import 'stage_resolver.dart';
import 'stage_types.dart';
import 'web_stage/web_stage.dart';

/// The one widget the live screen embeds: resolves the effective stage style
/// (requested + platform capability + runtime health) and renders it.
/// Declarative all the way — pass fresh value props, the stages diff inside.
class JarStageView extends ConsumerWidget {
  const JarStageView({
    super.key,
    required this.snapshot,
    required this.tips,
    required this.tipSerial,
    required this.config,
    this.demoPulseTick = 0,
  });

  final StageSnapshot snapshot;
  final List<JarTipAttribution> tips;

  /// LiveState.confettiTick — [tips] is only acted on when this advances.
  final int tipSerial;
  final StageSettings config;

  /// Preview screens bump this to make the stage invent a small tip.
  final int demoPulseTick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = resolveEffectiveStyle(
      config.style,
      webViewSupported: ref.watch(stageCapabilityProvider),
      health: ref.watch(stageHealthProvider),
    );
    return switch (style) {
      StageStyle.classic => ClassicStage(snapshot: snapshot),
      StageStyle.jar2d || StageStyle.jar3d => WebStage(
          // recreate the WebView when the renderer flips — cheap and rare
          key: ValueKey('stage-${style.wire}'),
          renderer: style == StageStyle.jar3d ? '3d' : '2d',
          snapshot: snapshot,
          tips: tips,
          tipSerial: tipSerial,
          config: config,
          demoPulseTick: demoPulseTick,
        ),
    };
  }
}
