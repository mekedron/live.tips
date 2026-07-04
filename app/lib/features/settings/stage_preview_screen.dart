import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/stage_settings.dart';
import '../../state/providers.dart';
import '../live/stage/jar_stage_view.dart';
import '../live/stage/stage_types.dart';

/// Try-before-the-gig: renders the stage with the performer's saved settings
/// and lets them pour pretend tips. No session, no Stripe, no persistence —
/// the renderer invents the amounts itself (`demoPulse`).
class StagePreviewScreen extends ConsumerStatefulWidget {
  const StagePreviewScreen({super.key});

  @override
  ConsumerState<StagePreviewScreen> createState() => _StagePreviewScreenState();
}

class _StagePreviewScreenState extends ConsumerState<StagePreviewScreen> {
  var _pulseTick = 0;

  // A believable mid-show snapshot so the HUD has something to say.
  static const _fakeSnapshot = StageSnapshot(
    totalMinor: 8700,
    goalMinor: 20000,
    currentJarMinor: 8700,
    bankedMinor: 0,
    bankedJars: 0,
    jarPct: 0.435,
    count: 12,
    currency: 'eur',
    goalReached: false,
  );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appStateProvider).settings;
    // Forced dark regardless of the app's light/dark setting — this previews
    // the same always-dark stage the performer sees live.
    return Theme(
      data: buildDarkTheme(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Stage preview'),
          backgroundColor: Colors.transparent,
        ),
        floatingActionButton: settings.stage.style == StageStyle.classic
            ? null
            : FloatingActionButton.extended(
                onPressed: () => setState(() => _pulseTick++),
                icon: const Icon(Icons.volunteer_activism_rounded),
                label: const Text('Pretend tip'),
              ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: JarStageView(
              snapshot: _fakeSnapshot,
              tips: const [],
              tipSerial: 0,
              config: settings.stage,
              demoPulseTick: _pulseTick,
            ),
          ),
        ),
      ),
    );
  }
}
