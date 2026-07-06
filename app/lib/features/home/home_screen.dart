import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/live_session.dart';
import '../../domain/tip_jar.dart';
import '../../state/live_session_controller.dart';
import '../../state/providers.dart';
import '../../widgets/donation_tile.dart';
import '../../widgets/goal_editor.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/qr_card.dart';
import '../live/live_screen.dart';
import '../poster/poster_screen.dart';
import '../settings/stage_preview_screen.dart';
import '../settings/stage_settings_section.dart';
import '../setup/jar_setup_screen.dart';
import '../shell/app_shell.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _goalMinor;

  /// Dev convenience: `flutter run --dart-define=AUTO_RESUME=1` jumps
  /// straight back into a stored session — no clicking through the UI.
  static const _autoResume =
      bool.fromEnvironment('AUTO_RESUME', defaultValue: false);

  @override
  void initState() {
    super.initState();
    if (_autoResume) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final controller = ref.read(liveSessionProvider.notifier);
        if (ref.read(liveSessionProvider) == null &&
            controller.hasStoredSession) {
          final resumed = await controller.resumeStored();
          if (resumed && mounted) _openLive();
        }
      });
    }
    _goalMinor = ref.read(appStateProvider).settings.lastGoalMinor;
  }

  void _setGoal(int minor) {
    if (minor <= 0) return;
    setState(() => _goalMinor = minor);
    // Persist so the next night starts from tonight's number.
    final app = ref.read(appStateProvider);
    ref
        .read(appStateProvider.notifier)
        .updateSettings(app.settings.copyWith(lastGoalMinor: minor));
  }

  Future<void> _editGoal(String currency) async {
    final newGoal = await showGoalEditorSheet(
      context,
      initialMinor: _goalMinor,
      currency: currency,
    );
    if (newGoal != null) _setGoal(newGoal);
  }

  Future<void> _startSession() async {
    await ref.read(liveSessionProvider.notifier).start(goalMinor: _goalMinor);
    if (mounted) _openLive();
  }

  void _openLive() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LiveScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final live = ref.watch(liveSessionProvider);
    final jar = app.effectiveTipJar!;
    final isRail = AppShellScope.of(context)?.isRail ?? false;

    final goalCard = _GoalCard(
      goalMinor: _goalMinor,
      currency: jar.currency,
      live: live,
      onEditGoal: () => _editGoal(jar.currency),
      onBump: _setGoal,
      onStart: _startSession,
      onReturn: _openLive,
    );

    if (isRail) {
      return _DesktopHome(jar: jar, app: app, goalCard: goalCard);
    }
    return _MobileHome(jar: jar, app: app, goalCard: goalCard);
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning,';
  if (hour < 18) return 'Good afternoon,';
  return 'Good evening,';
}

LtKeyStatus _keyStatus(AppState app) => app.demo
    ? LtKeyStatus.demo
    : app.isTestMode
        ? LtKeyStatus.test
        : LtKeyStatus.live;

/// The artist / band name with an inline pencil to rename it. Renaming changes
/// only the *local* display name (home, stage, poster) — it never touches the
/// Stripe link or its QR code, so it's safe any time. The pencil is hidden in
/// demo mode (there's no real jar to name).
class _EditableJarName extends ConsumerWidget {
  const _EditableJarName({
    required this.jar,
    required this.demo,
    required this.fontSize,
    required this.weight,
  });

  final TipJar jar;
  final bool demo;
  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final style = outfitStyle(fontSize, c.text, weight: weight);
    if (demo) return Text(jar.displayName, style: style);
    // A WidgetSpan keeps the pencil flowing with the text, so long names still
    // wrap / ellipsize naturally instead of overflowing a fixed-width Row.
    return Text.rich(
      TextSpan(
        text: jar.displayName,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _editJarName(context, ref, jar),
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.edit_outlined,
                    size: fontSize * 0.6, color: c.textMuted),
              ),
            ),
          ),
        ],
      ),
      style: style,
    );
  }
}

/// Rename the local display name — a light in-place edit that leaves the tip
/// link untouched (see [_EditableJarName]).
Future<void> _editJarName(
    BuildContext context, WidgetRef ref, TipJar jar) async {
  final notifier = ref.read(appStateProvider.notifier);
  final controller = TextEditingController(text: jar.displayName);
  final saved = await showDialog<String>(
    context: context,
    builder: (context) {
      final c = context.lt;
      return AlertDialog(
        title: const Text('Display name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(hintText: 'Artist or band name'),
              onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
            ),
            const SizedBox(height: 10),
            Text(
              'Shown on your home screen, stage and poster. Your tip link and '
              'its QR code aren\'t affected.',
              style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 12.5,
                  height: 1.4,
                  color: c.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (saved != null && saved.isNotEmpty && saved != jar.displayName) {
    await notifier.setTipJar(jar.copyWith(displayName: saved));
  }
}

// ---------------------------------------------------------------------------
// Mobile · 390-style single column with the logo top bar
// ---------------------------------------------------------------------------

class _MobileHome extends StatelessWidget {
  const _MobileHome({
    required this.jar,
    required this.app,
    required this.goalCard,
  });

  final TipJar jar;
  final AppState app;
  final Widget goalCard;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    // Phones skip Recent tips — History sits one tap away in the nav. Tablets
    // keep it to fill out the roomier canvas.
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const LtLogoMark(size: 30),
                const SizedBox(width: 10),
                Text('live.tips',
                    style: outfitStyle(17, c.text, weight: FontWeight.w700)),
                const Spacer(),
                StatusPill(status: _keyStatus(app)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text(_greeting(),
                      style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 14,
                          color: c.textSecondary)),
                  _EditableJarName(
                    jar: jar,
                    demo: app.demo,
                    fontSize: 24,
                    weight: FontWeight.w700,
                  ),
                  const SizedBox(height: 14),
                  goalCard,
                  const SizedBox(height: 14),
                  _TipLinkRowCard(url: jar.url),
                  if (isTablet) ...[
                    const SizedBox(height: 14),
                    _RecentTipsCard(compact: true),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop · rail mode, two-column grid
// ---------------------------------------------------------------------------

class _DesktopHome extends ConsumerWidget {
  const _DesktopHome({
    required this.jar,
    required this.app,
    required this.goalCard,
  });

  final TipJar jar;
  final AppState app;
  final Widget goalCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final sessions = ref.read(localStoreProvider).readSessionHistory();
    final last = sessions.isEmpty ? null : sessions.last;
    final dateLine = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(),
                          style: TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 15,
                              color: c.textSecondary)),
                      _EditableJarName(
                        jar: jar,
                        demo: app.demo,
                        fontSize: 32,
                        weight: FontWeight.w800,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    last == null
                        ? dateLine
                        : '$dateLine · Last session: '
                            '${formatAmount(last.totalMinor, last.currency)}',
                    style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        color: c.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        goalCard,
                        const SizedBox(height: 24),
                        _RecentTipsCard(compact: false),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DesktopTipLinkCard(url: jar.url),
                        const SizedBox(height: 24),
                        if (last != null) _LastSessionCard(session: last),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal card
// ---------------------------------------------------------------------------

class _GoalCard extends ConsumerWidget {
  const _GoalCard({
    required this.goalMinor,
    required this.currency,
    required this.live,
    required this.onEditGoal,
    required this.onBump,
    required this.onStart,
    required this.onReturn,
  });

  final int goalMinor;
  final String currency;
  final LiveState? live;
  final VoidCallback onEditGoal;
  final ValueChanged<int> onBump;
  final VoidCallback onStart;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final controller = ref.read(liveSessionProvider.notifier);
    final hasStored = live == null && controller.hasStoredSession;

    final money = InkWell(
      onTap: onEditGoal,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatAmount(goalMinor, currency),
                style: moneyStyle(40, c.text),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.edit_outlined, size: 20, color: c.textMuted),
        ],
      ),
    );
    final chips = _BumpChips(
      goalMinor: goalMinor,
      currency: currency,
      onBump: onBump,
    );

    final goalBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LtSectionLabel('Tonight\'s goal'),
        const SizedBox(height: 6),
        money,
        const SizedBox(height: 12),
        chips,
      ],
    );

    final actionBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StageLookRow(onTap: () => showStageLookSheet(context)),
        const SizedBox(height: 12),
        if (live != null)
          LtPrimaryButton(
            label: 'Return to session · '
                '${formatAmount(live!.session.totalMinor, live!.session.currency)} so far',
            icon: Icons.play_arrow_rounded,
            onPressed: onReturn,
          )
        else ...[
          LtPrimaryButton(
            label: 'Go live',
            icon: Icons.sensors_rounded,
            onPressed: onStart,
          ),
          if (hasStored) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final resumed = await controller.resumeStored();
                      if (resumed && context.mounted) onReturn();
                    },
                    icon: Icon(Icons.restore_rounded,
                        size: 18, color: c.textSecondary),
                    label: const Text('Resume interrupted session'),
                  ),
                ),
                IconButton(
                  tooltip: 'Discard it',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    await controller.discardStored();
                    // hasStored is read in build; poke a rebuild
                    ref.invalidate(liveSessionProvider);
                  },
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 10),
        // A no-stakes dry run of the stage — pour pretend tips before going live.
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StagePreviewScreen()),
          ),
          icon: Icon(Icons.play_circle_outline_rounded,
              size: 18, color: c.textSecondary),
          label: const Text('Preview stage'),
        ),
      ],
    );

    return LtCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop: goal on the left, stage look + Go live on the right,
          // hairline divider between (per the 1440 design).
          if (constraints.maxWidth > 560) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: goalBlock),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(width: 1, color: c.divider),
                  ),
                  Expanded(child: actionBlock),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LtSectionLabel('Tonight\'s goal'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(child: money),
                  const Spacer(),
                  chips,
                ],
              ),
              const SizedBox(height: 14),
              actionBlock,
            ],
          );
        },
      ),
    );
  }
}

class _BumpChips extends StatelessWidget {
  const _BumpChips({
    required this.goalMinor,
    required this.currency,
    required this.onBump,
  });

  final int goalMinor;
  final String currency;
  final ValueChanged<int> onBump;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    Widget chip(String label, int Function() next) => Material(
          color: c.chip,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onBump(next()),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(label, style: outfitStyle(12, c.textSecondary)),
            ),
          ),
        );
    final perMajor = minorUnitsPerMajor(currency);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip('+50', () => goalMinor + 50 * perMajor),
        const SizedBox(width: 6),
        chip('+100', () => goalMinor + 100 * perMajor),
        const SizedBox(width: 6),
        chip('×2', () => goalMinor * 2),
      ],
    );
  }
}

class _StageLookRow extends ConsumerWidget {
  const _StageLookRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final stage =
        ref.watch(appStateProvider.select((s) => s.settings.stage));
    return Material(
      color: c.bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.theater_comedy_rounded, size: 20, color: c.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stage look', style: outfitStyle(13.5, c.text)),
                    Text(
                      stageLookSummary(stage),
                      style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12.5,
                          color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tip link cards
// ---------------------------------------------------------------------------

class _TipLinkRowCard extends StatelessWidget {
  const _TipLinkRowCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showFullscreenQr(context, url),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrBlock(data: url, size: 84, padding: 0, radius: 6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your tip link', style: outfitStyle(15, c.text)),
                    Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 8),
                      child: Text(
                        url.replaceFirst(RegExp('^https?://'), ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: c.textMuted),
                      ),
                    ),
                    Row(
                      children: [
                        LtIconCircleButton(
                          icon: Icons.open_in_new_rounded,
                          tooltip: 'Open in new tab',
                          onTap: () => openTipLink(url),
                        ),
                        const SizedBox(width: 8),
                        LtIconCircleButton(
                          icon: Icons.content_copy_rounded,
                          tooltip: 'Copy link',
                          onTap: () => copyTipLink(context, url),
                        ),
                        const SizedBox(width: 8),
                        LtIconCircleButton(
                          icon: Icons.ios_share_rounded,
                          tooltip: 'Share',
                          onTap: () =>
                              SharePlus.instance.share(ShareParams(text: url)),
                        ),
                        const SizedBox(width: 8),
                        LtIconCircleButton(
                          icon: Icons.print_rounded,
                          tooltip: 'Poster',
                          onTap: () => openPoster(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _NewTipLinkButton(),
        ],
      ),
    );
  }
}

class _DesktopTipLinkCard extends StatelessWidget {
  const _DesktopTipLinkCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      radius: 24,
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Your tip link', style: outfitStyle(17, c.text, weight: FontWeight.w700)),
          ),
          const SizedBox(height: 18),
          QrBlock(data: url, size: 210),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => copyTipLink(context, url),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: c.bg,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      url.replaceFirst(RegExp('^https?://'), ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          color: c.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.content_copy_rounded,
                      size: 17, color: c.accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SoftMini(
                  icon: Icons.open_in_new_rounded,
                  label: 'Open',
                  onTap: () => openTipLink(url),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SoftMini(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onTap: () =>
                      SharePlus.instance.share(ShareParams(text: url)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SoftMini(
                  icon: Icons.print_rounded,
                  label: 'Poster',
                  onTap: () => openPoster(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _NewTipLinkButton(),
        ],
      ),
    );
  }
}

class _SoftMini extends StatelessWidget {
  const _SoftMini({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: c.accentSoft,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: c.onAccentSoft),
              const SizedBox(width: 6),
              Text(label, style: outfitStyle(13, c.onAccentSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Create new tip link" — shared by both tip-link cards. Understated on
/// purpose: it's rare and destructive (it retires the current QR), so it sits
/// quietly below the everyday actions and always confirms first.
class _NewTipLinkButton extends StatelessWidget {
  const _NewTipLinkButton();

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        // Opens the recreate editor: prefilled name / currency / thank-you
        // message plus a warning that the old link and its QR codes stop
        // working. The old link is only retired once the new one is created.
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const JarSetupScreen(recreate: true)),
        ),
        style: TextButton.styleFrom(
          foregroundColor: c.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        icon: const Icon(Icons.autorenew_rounded, size: 17),
        label: Text('Create new tip link',
            style: outfitStyle(13, c.textSecondary)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent tips + last session
// ---------------------------------------------------------------------------

class _RecentTipsCard extends ConsumerWidget {
  const _RecentTipsCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final recent = ref.watch(recentDonationsProvider);

    return LtCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      radius: compact ? 20 : 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Recent tips',
                    style: outfitStyle(compact ? 15 : 17, c.text,
                        weight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () =>
                    AppShellScope.of(context)?.select(ShellTab.history),
                child: const Text('View all'),
              ),
            ],
          ),
          if (app.demo)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Demo mode — start a session to watch pretend fans shower '
                'you with tips.',
                style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 13.5,
                    height: 1.5,
                    color: c.textSecondary),
              ),
            )
          else
            recent.when(
              data: (donations) => donations.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No tips yet. Put that QR code where people can '
                        'see it! 🎯',
                        style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 13.5,
                            color: c.textSecondary),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < donations.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: c.divider),
                          DonationTile(
                              donation: donations[i], showTime: !compact),
                        ],
                      ],
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5)),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Couldn\'t load recent tips: $error',
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13,
                      color: c.danger),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LastSessionCard extends StatelessWidget {
  const _LastSessionCard({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final pct = session.goalMinor <= 0
        ? 0
        : (session.totalMinor / session.goalMinor * 100).round();
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13.5,
                      color: c.textSecondary)),
              Text(value,
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.text)),
            ],
          ),
        );

    return LtCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last session',
              style: outfitStyle(17, c.text, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatAmount(session.totalMinor, session.currency),
                    style: moneyStyle(34, c.text),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (session.goalReached)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.successContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Goal reached 🎉',
                      style: outfitStyle(12, c.onSuccessContainer,
                          weight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          row('Tips', '${session.count}'),
          row('Duration',
              formatDuration(session.elapsed(session.endedAt))),
          if (session.goalMinor > 0) row('Goal', '$pct%'),
          if (session.count > 0)
            row('Average tip',
                formatAmount(session.averageMinor, session.currency)),
          if (session.biggest != null)
            row(
              'Biggest tip',
              '${formatAmount(session.biggest!.amountMinor, session.currency)}'
              ' · ${session.biggest!.displayName}',
            ),
        ],
      ),
    );
  }
}
