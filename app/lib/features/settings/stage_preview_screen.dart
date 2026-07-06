import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../app.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/donation.dart';
import '../../domain/live_session.dart';
import '../../domain/rollover_math.dart';
import '../../domain/stage_settings.dart';
import '../../domain/tip_jar.dart';
import '../../state/live_session_controller.dart';
import '../../state/providers.dart';
import '../../widgets/goal_editor.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/qr_card.dart';
import '../live/stage/jar_stage_view.dart';
import '../live/stage/stage_chrome.dart';
import '../live/stage/stage_hud.dart';
import '../live/stage/stage_resolver.dart';
import '../live/stage/stage_types.dart';
import '../shell/app_shell.dart';
import 'stage_settings_section.dart';

/// Try-before-the-gig: a faithful replica of the live stage — same jar, HUD,
/// QR, tip banners and celebration — driven by an in-memory session instead
/// of Stripe. The performer pours *pretend* tips (name, message, amount) and
/// sees exactly what a real one looks like. No session, no polling, no
/// live/Stripe status chrome; nothing is persisted.
class StagePreviewScreen extends ConsumerStatefulWidget {
  const StagePreviewScreen({super.key});

  @override
  ConsumerState<StagePreviewScreen> createState() => _StagePreviewScreenState();
}

class _StagePreviewScreenState extends ConsumerState<StagePreviewScreen> {
  late final ConfettiController _confetti;

  /// The pretend set, mutated in place exactly like a real [LiveSession].
  late final LiveSession _session;
  Donation? _lastDonation;

  /// Advances once per pretend tip — the serial the stage/banner act on.
  var _tipSerial = 0;
  List<JarTipAttribution> _newTips = const [];

  /// The ~1 s "your tip is landing" beat between submitting the form and the
  /// banner — mirrors the real gap between paying and the poll picking it up.
  var _pending = false;
  var _seq = 0;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
      duration: const Duration(milliseconds: 1400),
    );
    _session = _seedSession();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  /// A believable mid-show jar (~45% of tonight's goal, a handful of named
  /// tips with messages) so the HUD, fill and feed have something to say the
  /// instant the preview opens — just like walking up to a set in progress.
  LiveSession _seedSession() {
    final app = ref.read(appStateProvider);
    final jar = app.effectiveTipJar ?? TipJar.demo;
    final goal = app.settings.lastGoalMinor;
    final now = DateTime.now();
    final session = LiveSession(
      id: 'preview',
      startedAt: now.subtract(const Duration(minutes: 37)),
      currency: jar.currency,
      goalMinor: goal,
    );
    for (final s in _seedTips) {
      final donation = Donation(
        id: 'preview_seed_${s.minutesAgo}',
        amountMinor: (s.goalFraction * goal).round().clamp(1, goal),
        currency: jar.currency,
        createdAt: now.subtract(Duration(minutes: s.minutesAgo)),
        name: s.name,
        message: s.message,
        livemode: false,
      );
      session.addDonationAttributed(donation);
      _lastDonation = donation;
    }
    return session;
  }

  /// The whole point of the preview: pour a real, attributed tip so the jar
  /// pours, the HUD ticks up, the banner reads out the name/message/amount,
  /// and (on the classic stage) confetti flies — identical to a live tip.
  ///
  /// [context] must come from below the forced-dark [Theme] so the form sheet
  /// inherits the stage's dark palette (State.context sits above it).
  Future<void> _onPretendTip(BuildContext context) async {
    final tip = await showPretendTipSheet(context, _session.currency);
    if (tip == null || !mounted) return;

    final seq = ++_seq;
    setState(() => _pending = true);
    // The real world has latency between paying and the tip appearing.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted || seq != _seq) return;

    final donation = Donation(
      id: 'preview_tip_$seq',
      amountMinor: tip.amountMinor,
      currency: _session.currency,
      createdAt: DateTime.now(),
      name: tip.name,
      message: tip.message,
      livemode: false,
    );
    final attributed = _session.addDonationAttributed(donation);
    setState(() {
      _pending = false;
      if (attributed != null) {
        _tipSerial += 1;
        _newTips = [attributed];
        _lastDonation = donation;
      }
    });

    // jar stages celebrate in-scene — screen confetti is classic-only
    final style = resolveEffectiveStyle(
      ref.read(appStateProvider).settings.stage.style,
      webViewSupported: ref.read(stageCapabilityProvider),
      health: ref.read(stageHealthProvider),
    );
    if (style == StageStyle.classic) _confetti.play();
    HapticFeedback.mediumImpact();
  }

  /// Back arrow: pop to wherever we came from, but when there's nothing to
  /// pop (e.g. the preview was opened directly on a fresh web load) fall back
  /// to Home rather than stranding the performer on a dead-end screen.
  void _handleBack(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      ref.read(shellTabRequestProvider.notifier).request(ShellTab.home);
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RootGate()),
      );
    }
  }

  Future<void> _editGoal(BuildContext context) async {
    final newGoal = await showGoalEditorSheet(
      context,
      initialMinor: _session.goalMinor,
      currency: _session.currency,
      title: 'Preview goal',
    );
    if (newGoal == null || !mounted) return;
    setState(() {
      _session.goalMinor = newGoal;
      // Lowering the goal can instantly owe rollovers (total ≥ 2× new goal).
      _session.applyRollovers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final stageConfig = app.settings.stage;
    final jar = app.effectiveTipJar ?? TipJar.demo;
    final snapshot = StageSnapshot.fromState(
      LiveState(session: _session, lastDonation: _lastDonation),
    );

    // Forced dark regardless of the app's light/dark setting — this previews
    // the same always-dark stage the performer sees live.
    return Theme(
      data: buildDarkTheme(),
      child: Scaffold(
        backgroundColor: kStageBlack,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 780;
            final safeTop = MediaQuery.paddingOf(context).top;
            final safeBottom = MediaQuery.paddingOf(context).bottom;
            return Stack(
              children: [
                // ---- the stage itself, edge to edge ----
                Positioned.fill(
                  child: stageConfig.style == StageStyle.classic
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            safeTop + 72,
                            16,
                            wide ? 16 : 100,
                          ),
                          child: JarStageView(
                            snapshot: snapshot,
                            tips: _newTips,
                            tipSerial: _tipSerial,
                            config: stageConfig,
                          ),
                        )
                      : JarStageView(
                          snapshot: snapshot,
                          tips: _newTips,
                          tipSerial: _tipSerial,
                          config: stageConfig,
                        ),
                ),
                // ---- wide: floating QR + messages panel ----
                if (wide)
                  Positioned(
                    right: 16,
                    top: safeTop + 76,
                    bottom: 16,
                    width: 280,
                    child: StageQrPanel(
                      url: jar.url,
                      name: jar.displayName,
                      messages: _session.donations.reversed
                          .where((d) => d.hasMessage)
                          .take(3)
                          .toList(),
                    ),
                  ),
                // ---- top controls: back + "Stage preview", no live/Stripe ----
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        StageGlassButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          size: wide ? 44 : 40,
                          onTap: () => _handleBack(context),
                        ),
                        const SizedBox(width: 8),
                        const _PreviewPill(),
                        const Spacer(),
                        StageGlassButton(
                          icon: Icons.flag_rounded,
                          tooltip: 'Preview goal',
                          size: wide ? 44 : 40,
                          onTap: () => _editGoal(context),
                        ),
                        if (wide) ...[
                          const SizedBox(width: 8),
                          StageGlassButton(
                            icon: Icons.palette_rounded,
                            tooltip: 'Stage look',
                            onTap: () => showStageLookSheet(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // ---- wide: the pretend-tip CTA floats bottom-center ----
                if (wide)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24 + safeBottom),
                      child: _PretendTipButton(
                        busy: _pending,
                        onTap: () => _onPretendTip(context),
                      ),
                    ),
                  ),
                // ---- mobile: bottom glass action bar ----
                if (!wide)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kStageGlassSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _PretendTipButton(
                                busy: _pending,
                                onTap: () => _onPretendTip(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StageGlassSquare(
                              icon: Icons.qr_code_2_rounded,
                              tooltip: 'Show QR',
                              onTap: () => showFullscreenQr(context, jar.url),
                            ),
                            const SizedBox(width: 8),
                            StageGlassSquare(
                              icon: Icons.palette_rounded,
                              tooltip: 'Stage look',
                              onTap: () => showStageLookSheet(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // ---- "your tip is landing…" beat, where the banner appears ----
                if (_pending)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: safeTop + (wide ? 160 : 188)),
                      child: const _PendingPill(),
                    ),
                  ),
                // classic celebrates with screen confetti; jars do it in-scene
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confetti,
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: 28,
                    maxBlastForce: 30,
                    minBlastForce: 8,
                    gravity: 0.25,
                    shouldLoop: false,
                    colors: const [
                      kStageAccent,
                      Colors.white,
                      Color(0xFFFFB79F),
                      kGold,
                      Colors.pinkAccent,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Fractions of tonight's goal for the pre-seeded set — poured in on open so
/// the preview looks like a gig already in progress, not an empty jar.
class _SeedTip {
  const _SeedTip(this.minutesAgo, this.name, this.goalFraction, [this.message]);

  final int minutesAgo;
  final String? name;
  final double goalFraction;
  final String? message;
}

const _seedTips = <_SeedTip>[
  _SeedTip(34, 'Marco', 0.05, 'First song hit me right in the feels 🎸'),
  _SeedTip(29, 'Anna', 0.10, 'Encore!!'),
  _SeedTip(24, null, 0.025),
  _SeedTip(20, 'Sofia', 0.075, 'You sound incredible tonight'),
  _SeedTip(16, 'Liam', 0.03),
  _SeedTip(12, 'Noah', 0.04, 'Play the one from the first EP?'),
  _SeedTip(9, 'Emma', 0.02),
  _SeedTip(6, 'Olivia', 0.05, 'Worth every cent 💛'),
  _SeedTip(3, null, 0.015),
  _SeedTip(1, 'Lucas', 0.045),
];

/// The static "Stage preview" glass pill that replaces the live LIVE·clock.
class _PreviewPill extends StatelessWidget {
  const _PreviewPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kStageGlassSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined,
              size: 16, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            'Stage preview',
            style: outfitStyle(13, Colors.white,
                weight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

/// The coral pretend-tip CTA — an expanded bar button on phones, a floating
/// pill on wide screens. Spins while the tip is "landing".
class _PretendTipButton extends StatelessWidget {
  const _PretendTipButton({required this.onTap, this.busy = false});

  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: kStageAccent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Color(0xFF40160A)),
                )
              else
                const Icon(Icons.volunteer_activism_rounded,
                    size: 19, color: Color(0xFF40160A)),
              const SizedBox(width: 8),
              Text(
                busy ? 'Landing…' : 'Pretend tip',
                style: outfitStyle(14.5, const Color(0xFF40160A),
                    weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
    // Intercept real pointer events so the CTA is tappable over the jar's
    // web <iframe> platform view (no-op off web).
    return PointerInterceptor(child: button);
  }
}

/// The glass "adding your tip…" pill shown for the ~1 s processing beat,
/// positioned where the real tip banner is about to appear.
class _PendingPill extends StatelessWidget {
  const _PendingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: kStageGlass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2.2, color: kStageAccent),
          ),
          const SizedBox(width: 10),
          Text(
            'Adding your tip…',
            style: outfitStyle(14, Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

/// What a submitted pretend tip carries.
typedef PretendTip = ({int amountMinor, String? name, String? message});

/// The fan-facing tip form the preview stands in for: amount (required),
/// nickname and message (both optional) — the same fields Stripe collects.
/// Returns null if dismissed.
Future<PretendTip?> showPretendTipSheet(
    BuildContext context, String currency) {
  final amountCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  final zeroDecimal = minorUnitsPerMajor(currency) == 1;
  final presets = zeroDecimal ? [500, 1000, 2000, 5000] : [5, 10, 20, 50];

  return showModalBottomSheet<PretendTip>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = context.lt;
      // Lives above the StatefulBuilder so it survives setSheet rebuilds.
      String? amountError;
      return StatefulBuilder(
        builder: (context, setSheet) {
          void submit() {
            final minor = parseMajorToMinor(amountCtrl.text, currency);
            if (minor == null) {
              setSheet(() => amountError = 'Enter an amount greater than 0');
              return;
            }
            final name = nameCtrl.text.trim();
            final message = messageCtrl.text.trim();
            Navigator.of(context).pop((
              amountMinor: minor,
              name: name.isEmpty ? null : name,
              message: message.isEmpty ? null : message,
            ));
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Send a pretend tip',
                    style: outfitStyle(18, c.text, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Exactly what your fans fill in — see how it lands on stage.',
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13,
                      color: c.textSecondary),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: outfitStyle(22, c.text, weight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: '0',
                    errorText: amountError,
                    suffixText: currency.toUpperCase(),
                    suffixStyle: outfitStyle(14, c.textSecondary),
                  ),
                  onChanged: (_) {
                    if (amountError != null) {
                      setSheet(() => amountError = null);
                    }
                  },
                  onSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final p in presets) ...[
                      _AmountChip(
                        label: formatAmount(
                            p * minorUnitsPerMajor(currency), currency),
                        onTap: () => setSheet(() {
                          amountCtrl.text = p.toString();
                          amountError = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                    hintText: 'Anonymous',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    hintText: 'Say something nice…',
                  ),
                ),
                const SizedBox(height: 20),
                LtPrimaryButton(
                  label: 'Drop it in the jar',
                  icon: Icons.volunteer_activism_rounded,
                  onPressed: submit,
                ),
              ],
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    // Dispose after the sheet's exit animation is fully done.
    Future.delayed(const Duration(seconds: 1), () {
      amountCtrl.dispose();
      nameCtrl.dispose();
      messageCtrl.dispose();
    });
  });
}

/// A preset-amount chip in the pretend-tip form ("€5", "€10", …).
class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: c.chip,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label, style: outfitStyle(13, c.textSecondary)),
        ),
      ),
    );
  }
}
