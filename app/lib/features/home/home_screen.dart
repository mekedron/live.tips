import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../domain/app_settings.dart';
import '../../domain/donation.dart';
import '../../domain/live_session.dart';
import '../onboarding/relay_setup_screen.dart' show confirmAndRegenerateRelayJar;
import '../../state/live_session_controller.dart';
import '../../state/providers.dart';
import '../../widgets/band_switcher.dart';
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
            ref.read(storedSessionProvider) != null) {
          final resumed = await controller.resumeStored();
          if (resumed && mounted) _openLive();
        }
      });
    }
    _goalMinor = ref.read(appStateProvider).band.lastGoalMinor;
  }

  void _setGoal(int minor) {
    if (minor <= 0) return;
    setState(() => _goalMinor = minor);
    // Persist so the next night starts from tonight's number.
    final app = ref.read(appStateProvider);
    ref
        .read(appStateProvider.notifier)
        .updateBand(app.band.copyWith(lastGoalMinor: minor));
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
    // start() refuses quietly in edge states (mid band switch, nothing
    // configured) — never open the stage over a session that isn't there.
    if (mounted && ref.read(liveSessionProvider) != null) _openLive();
  }

  void _openLive() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LiveScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final live = ref.watch(liveSessionProvider);
    final isRail = AppShellScope.of(context)?.isRail ?? false;

    final goalCard = _GoalCard(
      goalMinor: _goalMinor,
      currency: app.currency,
      live: live,
      onEditGoal: () => _editGoal(app.currency),
      onBump: _setGoal,
      onStart: _startSession,
      onReturn: _openLive,
    );

    if (isRail) {
      return _DesktopHome(app: app, goalCard: goalCard);
    }
    return _MobileHome(app: app, goalCard: goalCard);
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
    : !app.hasStripe && app.hasRelay
        ? LtKeyStatus.relay
        : app.isTestMode
            ? LtKeyStatus.test
            : LtKeyStatus.live;

/// The band name row: the name itself (with a chevron) opens the band
/// switcher, and a small pencil beside it renames the band. Renaming changes
/// only the *local* display name (home, stage, poster) — it never touches the
/// Stripe link or its QR code, so it's safe any time. (Relay-connected bands
/// also push the new name to their live.tips page, best effort.) The pencil
/// is hidden in demo mode (there's no real jar to name).
class _EditableJarName extends ConsumerWidget {
  const _EditableJarName({
    required this.app,
    required this.fontSize,
    required this.weight,
  });

  final AppState app;
  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: BandNameButton(fontSize: fontSize, weight: weight),
        ),
        if (!app.demo)
          IconButton(
            tooltip: 'Rename',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined,
                size: fontSize * 0.6, color: c.textMuted),
            onPressed: () => _editJarName(context, ref, app),
          ),
      ],
    );
  }
}

/// Rename the local display name — a light in-place edit that leaves the tip
/// link untouched (see [_EditableJarName]). Opens as a bottom sheet, matching
/// the Tonight's-goal editor.
Future<void> _editJarName(
    BuildContext context, WidgetRef ref, AppState app) async {
  final notifier = ref.read(appStateProvider.notifier);
  final controller = TextEditingController(text: app.displayName);
  final saved = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = context.lt;
      void submit() => Navigator.of(context).pop(controller.text.trim());
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
            Text('Display name',
                style: outfitStyle(18, c.text, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Shown on your home screen, stage and poster. Your tip link and '
              'its QR code aren\'t affected.',
              style: TextStyle(
                  fontFamily: kFontBody, fontSize: 13, color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              style: outfitStyle(20, c.text, weight: FontWeight.w700),
              decoration:
                  const InputDecoration(hintText: 'Artist or band name'),
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 20),
            LtPrimaryButton(label: 'Save name', onPressed: submit),
          ],
        ),
      );
    },
  );
  // Dispose after the sheet's exit animation is fully done.
  Future.delayed(const Duration(seconds: 1), controller.dispose);
  if (saved == null || saved.isEmpty || saved == app.displayName) return;
  await notifier.renameBand(saved);
  // Best effort: keep the public live.tips page's name in sync. The local
  // rename already took; on failure the relay copy just drifts until the
  // next successful update. The Stripe URL rides along because the relay
  // treats an update as a full profile replace — omitting it would wipe the
  // donor page's card button.
  final relayJar = app.relayJar;
  final secret = app.relaySecret;
  if (relayJar == null || secret == null) return;
  final client = RelayClient();
  try {
    await client.updateJar(
      jar: relayJar.copyWith(artistName: saved),
      secret: secret,
      artistName: saved,
      stripeUrl: app.tipJar?.url,
    );
  } catch (_) {
    // Offline or a rotated secret — purely cosmetic drift, ignore.
  } finally {
    client.close();
  }
}

// ---------------------------------------------------------------------------
// Mobile · 390-style single column with the logo top bar
// ---------------------------------------------------------------------------

class _MobileHome extends StatelessWidget {
  const _MobileHome({
    required this.app,
    required this.goalCard,
  });

  final AppState app;
  final Widget goalCard;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final url = app.activeQrUrl;
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
                    app: app,
                    fontSize: 24,
                    weight: FontWeight.w700,
                  ),
                  const SizedBox(height: 14),
                  goalCard,
                  if (url != null) ...[
                    const SizedBox(height: 14),
                    _TipLinkRowCard(url: url),
                  ],
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
    required this.app,
    required this.goalCard,
  });

  final AppState app;
  final Widget goalCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final url = app.activeQrUrl;
    final sessions =
        ref.read(localStoreProvider).readSessionHistory(app.accountId);
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
                        app: app,
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
                        if (url != null) ...[
                          _DesktopTipLinkCard(url: url),
                          const SizedBox(height: 24),
                        ],
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
    final storedSession = ref.watch(storedSessionProvider);
    final hasStored = live == null && storedSession != null;

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
            onPressed: () async {
              if (storedSession == null) {
                onStart();
                return;
              }
              final choice =
                  await _confirmStartOverStored(context, storedSession);
              if (choice == _StoredSessionChoice.resume) {
                final resumed = await controller.resumeStored();
                if (resumed && context.mounted) onReturn();
              } else if (choice == _StoredSessionChoice.discardAndStart) {
                onStart();
              }
            },
          ),
          if (hasStored) ...[
            const SizedBox(height: 10),
            Text(
              'Started ${_startedAgo(storedSession)}'
              '${_tipsSummary(storedSession)}',
              style: TextStyle(
                  fontFamily: kFontBody, fontSize: 12, color: c.textMuted),
            ),
            const SizedBox(height: 6),
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
                    label: const Text(
                      'Resume session',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Discard it',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    final confirmed =
                        await _confirmDiscardStored(context, storedSession);
                    if (confirmed) await controller.discardStored();
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
// Stored (interrupted) session — resume / discard / overwrite dialogs
// ---------------------------------------------------------------------------

enum _StoredSessionChoice { resume, discardAndStart }

/// "38 min ago", "2h ago", or the weekday once it's over a day old.
String _startedAgo(LiveSession session) {
  final elapsed = DateTime.now().difference(session.startedAt);
  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  return DateFormat('EEEE, MMMM d').format(session.startedAt);
}

/// A trailing clause, not a sentence: " with 4 tips ($128.00)" / " with no
/// tips yet".
String _tipsSummary(LiveSession session) => session.count == 0
    ? ' with no tips yet'
    : ' with ${session.count} tip${session.count == 1 ? '' : 's'} '
        '(${formatAmount(session.totalMinor, session.currency)})';

/// Confirms before wiping a stored session for good — names what's about to
/// be lost so a stray tap can't silently erase a tracked set.
Future<bool> _confirmDiscardStored(
    BuildContext context, LiveSession session) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Discard this session?'),
      content: Text(
        'Started ${_startedAgo(session)}${_tipsSummary(session)}. '
        'This can\'t be undone — it won\'t be saved to your history.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// "Go live" while a set is still stored would otherwise silently overwrite
/// it — this lets the artist resume it, discard it and start fresh, or back
/// out instead.
Future<_StoredSessionChoice?> _confirmStartOverStored(
    BuildContext context, LiveSession session) {
  return showDialog<_StoredSessionChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Unfinished session found'),
      content: Text(
        'Your last set started ${_startedAgo(session)}'
        '${_tipsSummary(session)}. Starting a new one discards it for good.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_StoredSessionChoice.resume),
          child: const Text('Resume it'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context)
              .pop(_StoredSessionChoice.discardAndStart),
          child: const Text('Discard & start new'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Tip link cards
// ---------------------------------------------------------------------------

class _TipLinkRowCard extends ConsumerWidget {
  const _TipLinkRowCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final connected = app.effectiveQrMode == QrMode.connected;
    return LtCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (app.hasBothQrModes) ...[
            const _QrModeToggle(),
            const SizedBox(height: 12),
          ],
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
                    Text(connected ? 'Your tip page' : 'Your tip link',
                        style: outfitStyle(15, c.text)),
                    Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 8),
                      child: Text(
                        // The Stripe URL is worth reading; the tip page URL
                        // matters less than what fans find behind it.
                        connected
                            ? 'Fans pick Stripe, Revolut or MobilePay on '
                                'your tip page.'
                            : url.replaceFirst(RegExp('^https?://'), ''),
                        maxLines: connected ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: connected
                            ? TextStyle(
                                fontFamily: kFontBody,
                                fontSize: 12,
                                height: 1.35,
                                color: c.textSecondary)
                            : TextStyle(
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
          if (_showRecreate(app)) ...[
            const SizedBox(height: 12),
            const _NewTipLinkButton(),
          ],
        ],
      ),
    );
  }
}

/// Whether the "new link" button makes sense right now: in Stripe mode it
/// recreates the payment link (needs a Stripe key; demo fakes it), in
/// connected mode it regenerates the relay jar (needs one).
bool _showRecreate(AppState app) {
  if (app.demo) return true;
  return app.effectiveQrMode == QrMode.connected
      ? app.hasRelay
      : app.hasStripe;
}

/// The Stripe-link ⇄ tip-page switch shown when both exist. Persisted in
/// the band's settings; every QR surface (home, stage, poster) follows it.
class _QrModeToggle extends ConsumerWidget {
  const _QrModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final band = ref.watch(appStateProvider.select((s) => s.band));
    final mode = ref.watch(appStateProvider.select((s) => s.effectiveQrMode));
    return LtSegmented<QrMode>(
      values: QrMode.values,
      selected: mode,
      labelOf: (m) => m.label,
      onChanged: (m) => ref
          .read(appStateProvider.notifier)
          .updateBand(band.copyWith(qrMode: m)),
    );
  }
}

class _DesktopTipLinkCard extends ConsumerWidget {
  const _DesktopTipLinkCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final connected = app.effectiveQrMode == QrMode.connected;
    return LtCard(
      radius: 24,
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(connected ? 'Your tip page' : 'Your tip link',
                style: outfitStyle(17, c.text, weight: FontWeight.w700)),
          ),
          const SizedBox(height: 18),
          if (app.hasBothQrModes) ...[
            const _QrModeToggle(),
            const SizedBox(height: 16),
          ],
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
          if (connected) ...[
            const SizedBox(height: 10),
            Text(
              'Fans pick Stripe, Revolut or MobilePay on your tip page.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 12.5,
                  height: 1.4,
                  color: c.textSecondary),
            ),
          ],
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
          if (_showRecreate(app)) ...[
            const SizedBox(height: 12),
            const _NewTipLinkButton(),
          ],
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

/// "Create new tip link" / "New tip page link" — shared by both tip-link
/// cards. Understated on purpose: it's rare and destructive (it retires the
/// current QR), so it sits quietly below the everyday actions and always
/// confirms first. Mode-aware: in Stripe mode it opens the recreate editor
/// for the payment link; in connected mode it regenerates the relay jar
/// (same profile, fresh link). Demo keeps the harmless Stripe path.
class _NewTipLinkButton extends ConsumerWidget {
  const _NewTipLinkButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final connected = !app.demo && app.effectiveQrMode == QrMode.connected;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        // Stripe mode opens the recreate editor: prefilled name / currency /
        // thank-you message plus a warning that the old link and its QR
        // codes stop working. The old link is only retired once the new one
        // is created. Connected mode confirms, then swaps the relay jar.
        onPressed: () => connected
            ? confirmAndRegenerateRelayJar(context, ref)
            : Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const JarSetupScreen(recreate: true)),
              ),
        style: TextButton.styleFrom(
          foregroundColor: c.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        icon: const Icon(Icons.autorenew_rounded, size: 17),
        label: Text(connected ? 'New tip page link' : 'Create new tip link',
            style: outfitStyle(13, c.textSecondary)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent tips + last session
// ---------------------------------------------------------------------------

/// One preview list from two feeds: the Stripe API's latest donations and
/// the device-local tip-page (Revolut/MobilePay) archive — which Stripe
/// never sees, so without this merge relay tips were invisible here.
/// Both inputs arrive newest-first; the result is newest-first, capped.
@visibleForTesting
List<Donation> mergeRecentTips(
  List<Donation> stripe,
  List<Donation> relay, {
  int limit = 5,
}) {
  final merged = [...stripe.take(limit), ...relay.take(limit)]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged.take(limit).toList();
}

class _RecentTipsCard extends ConsumerWidget {
  const _RecentTipsCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final recent = ref.watch(recentDonationsProvider);
    // Refreshed by the session controller the moment a tip-page tip lands,
    // so this card updates mid-session — just like it shows Stripe tips.
    final relayRecent = ref.watch(relayHistoryProvider);

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
              data: (donations) {
                final shown = mergeRecentTips(donations, relayRecent);
                return shown.isEmpty
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
                          for (var i = 0; i < shown.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: c.divider),
                            DonationTile(
                                donation: shown[i], showTime: !compact),
                          ],
                        ],
                      );
              },
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
