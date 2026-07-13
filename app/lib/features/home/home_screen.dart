import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/app_settings.dart';
import '../../domain/tip.dart';
import '../../domain/live_session.dart';
import '../onboarding/relay_setup_screen.dart'
    show confirmAndRegenerateRelayJar;
import '../../state/live_session_controller.dart';
import '../../state/providers.dart';
import '../../state/session_coordinator.dart';
import '../../widgets/profile_switcher.dart';
import '../../widgets/tip_tile.dart';
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
  static const _autoResume = bool.fromEnvironment(
    'AUTO_RESUME',
    defaultValue: false,
  );

  @override
  void initState() {
    super.initState();
    if (_autoResume) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (ref.read(liveSessionProvider) == null &&
            ref.read(storedSessionProvider) != null) {
          final resumed = await _resumeStored();
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
    try {
      await ref
          .read(liveSessionProvider.notifier)
          .start(goalMinor: _goalMinor);
    } on SessionAlreadyActiveException catch (e) {
      _showAlreadyLive(e);
      return;
    }
    // start() refuses quietly in edge states (mid band switch, nothing
    // configured) — never open the stage over a session that isn't there.
    if (mounted && ref.read(liveSessionProvider) != null) _openLive();
  }

  /// Resumes the stored (crash-recovery) session, absorbing the "another
  /// device holds this session" outcome into the same snackbar Go live
  /// shows — a silently dead Resume button teaches the artist nothing.
  Future<bool> _resumeStored() async {
    try {
      return await ref.read(liveSessionProvider.notifier).resumeStored();
    } on SessionAlreadyActiveException catch (e) {
      _showAlreadyLive(e);
      return false;
    }
  }

  /// The account is already live on another device — point at the Join
  /// banner instead of forking the night into two sessions.
  void _showAlreadyLive(SessionAlreadyActiveException e) {
    if (!mounted) return;
    final accounts = ref.read(appStateProvider).accounts;
    final bandName = accounts
            .where((a) => a.id == e.bandId)
            .map((a) => a.name.trim())
            .firstOrNull ??
        '';
    final band = bandName.isEmpty
        ? context.s.t('widgets.profile_switcher.unnamed')
        : bandName;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.s.t('home.already_live', {'band': band})),
    ));
  }

  void _openLive() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LiveScreen()));
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
      onResume: _resumeStored,
      onReturn: _openLive,
    );

    if (isRail) {
      return _DesktopHome(app: app, goalCard: goalCard);
    }
    return _MobileHome(app: app, goalCard: goalCard);
  }
}

/// Shown when the keep-alive had to auto-replace a dead tip-page link. Warns
/// the artist that printed QR codes now point at the old (dead) link and
/// offers the fresh QR to reprint. Renders nothing when there's no notice.
class _ReprintNoticeCard extends ConsumerWidget {
  const _ReprintNoticeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oldUrl = ref.watch(relayLinkNoticeProvider);
    if (oldUrl == null) return const SizedBox.shrink();
    final c = context.lt;
    final url = ref.watch(appStateProvider).activeQrUrl;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGold.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: c.text),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.s.t('home.reprint.title'),
                    style: outfitStyle(14, c.text, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.s.t('home.reprint.body'),
              style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (url != null)
                  TextButton(
                    onPressed: () => showFullscreenQr(context, url),
                    child: Text(context.s.t('home.reprint.show_qr')),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => ref
                      .read(appStateProvider.notifier)
                      .dismissRelayLinkNotice(),
                  child: Text(context.s.t('home.reprint.dismiss')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile · 390-style single column with the logo top bar
// ---------------------------------------------------------------------------

class _MobileHome extends StatelessWidget {
  const _MobileHome({required this.app, required this.goalCard});

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
                Text(
                  'live.tips',
                  style: outfitStyle(17, c.text, weight: FontWeight.w700),
                ),
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
                  const BandNameButton(fontSize: 24, weight: FontWeight.w700),
                  const _ReprintNoticeCard(),
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
  const _DesktopHome({required this.app, required this.goalCard});

  final AppState app;
  final Widget goalCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = app.activeQrUrl;
    // Cloud mirrors fill in asynchronously — re-read when a snapshot lands.
    ref.watch(repoRevisionProvider);
    final sessions = ref
        .read(accountDataRepositoryProvider)
        .readSessionHistory(app.storageId);
    final last = sessions.isEmpty ? null : sessions.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BandNameButton(fontSize: 32, weight: FontWeight.w800),
              const _ReprintNoticeCard(),
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
    required this.onResume,
    required this.onReturn,
  });

  final int goalMinor;
  final String currency;
  final LiveState? live;
  final VoidCallback onEditGoal;
  final ValueChanged<int> onBump;
  final VoidCallback onStart;

  /// Resumes the stored session; false means nothing to return to (another
  /// device holds the session, or it ended elsewhere) — the owner already
  /// told the artist why, so the card only decides whether to open the stage.
  final Future<bool> Function() onResume;
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
        LtSectionLabel(context.s.t('home.tonights_goal')),
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
            label: context.s.t('home.return_to_session', {
              'amount': formatAmount(
                live!.session.totalMinor,
                live!.session.currency,
              ),
            }),
            icon: Icons.play_arrow_rounded,
            onPressed: onReturn,
          )
        else ...[
          LtPrimaryButton(
            label: context.s.t('home.go_live'),
            icon: Icons.sensors_rounded,
            onPressed: () async {
              if (storedSession == null) {
                onStart();
                return;
              }
              final choice = await _confirmStartOverStored(
                context,
                storedSession,
              );
              if (choice == _StoredSessionChoice.resume) {
                final resumed = await onResume();
                if (resumed && context.mounted) onReturn();
              } else if (choice == _StoredSessionChoice.discardAndStart) {
                onStart();
              }
            },
          ),
          if (hasStored) ...[
            const SizedBox(height: 10),
            Text(
              context.s.t('home.session.started', {
                'when': _startedAgo(context, storedSession),
                'summary': _tipsSummary(context, storedSession),
              }),
              style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 12,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final resumed = await onResume();
                      if (resumed && context.mounted) onReturn();
                    },
                    icon: Icon(
                      Icons.restore_rounded,
                      size: 18,
                      color: c.textSecondary,
                    ),
                    label: Text(
                      context.s.t('home.resume_session'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.s.t('home.discard_it'),
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    final confirmed = await _confirmDiscardStored(
                      context,
                      storedSession,
                    );
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
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const StagePreviewScreen())),
          icon: Icon(
            Icons.play_circle_outline_rounded,
            size: 18,
            color: c.textSecondary,
          ),
          label: Text(context.s.t('home.preview_stage')),
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
              LtSectionLabel(context.s.t('home.tonights_goal')),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    final stage = ref.watch(appStateProvider.select((s) => s.settings.stage));
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
                    Text(
                      context.s.t('home.stage_look'),
                      style: outfitStyle(13.5, c.text),
                    ),
                    Text(
                      stageLookSummary(context, stage),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
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
String _startedAgo(BuildContext context, LiveSession session) {
  final elapsed = DateTime.now().difference(session.startedAt);
  if (elapsed.inMinutes < 1) return context.s.t('home.time.just_now');
  if (elapsed.inMinutes < 60) {
    return context.s.t('home.time.min_ago', {'n': elapsed.inMinutes});
  }
  if (elapsed.inHours < 24) {
    return context.s.t('home.time.hours_ago', {'n': elapsed.inHours});
  }
  return DateFormat('EEEE, MMMM d').format(session.startedAt);
}

/// A trailing clause, not a sentence: " with 4 tips ($128.00)" / " with no
/// tips yet".
String _tipsSummary(BuildContext context, LiveSession session) =>
    session.count == 0
    ? context.s.t('home.session.no_tips')
    : context.s.t('home.session.with_tips', {
        'n': session.count,
        'amount': formatAmount(session.totalMinor, session.currency),
      });

/// Confirms before wiping a stored session for good — names what's about to
/// be lost so a stray tap can't silently erase a tracked set.
Future<bool> _confirmDiscardStored(
  BuildContext context,
  LiveSession session,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.s.t('home.discard.title')),
      content: Text(
        context.s.t('home.discard.body', {
          'when': _startedAgo(context, session),
          'summary': _tipsSummary(context, session),
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.s.t('home.cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.s.t('home.discard.confirm')),
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
  BuildContext context,
  LiveSession session,
) {
  return showDialog<_StoredSessionChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.s.t('home.unfinished.title')),
      content: Text(
        context.s.t('home.unfinished.body', {
          'when': _startedAgo(context, session),
          'summary': _tipsSummary(context, session),
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.s.t('home.cancel')),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_StoredSessionChoice.resume),
          child: Text(context.s.t('home.unfinished.resume')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () =>
              Navigator.of(context).pop(_StoredSessionChoice.discardAndStart),
          child: Text(context.s.t('home.unfinished.discard_start')),
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
                    Text(
                      connected
                          ? context.s.t('home.tip_page_title')
                          : context.s.t('home.tip_link_title'),
                      style: outfitStyle(15, c.text),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 8),
                      child: Text(
                        // The Stripe URL is worth reading; the tip page URL
                        // matters less than what fans find behind it.
                        connected
                            ? context.s.t('home.fans_pick_methods')
                            : url.replaceFirst(RegExp('^https?://'), ''),
                        maxLines: connected ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: connected
                            ? TextStyle(
                                fontFamily: kFontBody,
                                fontSize: 12,
                                height: 1.35,
                                color: c.textSecondary,
                              )
                            : TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                color: c.textMuted,
                              ),
                      ),
                    ),
                    Row(
                      children: [
                        LtIconCircleButton(
                          icon: Icons.open_in_new_rounded,
                          tooltip: context.s.t('home.open_in_new_tab'),
                          onTap: () => openTipLink(url),
                        ),
                        const SizedBox(width: 8),
                        LtIconCircleButton(
                          icon: Icons.content_copy_rounded,
                          tooltip: context.s.t('home.copy_link'),
                          onTap: () => copyTipLink(context, url),
                        ),
                        const SizedBox(width: 8),
                        LtIconCircleButton(
                          icon: Icons.ios_share_rounded,
                          tooltip: context.s.t('home.share'),
                          onTap: () =>
                              SharePlus.instance.share(ShareParams(text: url)),
                        ),
                        const SizedBox(width: 8),
                        LtIconCircleButton(
                          icon: Icons.print_rounded,
                          tooltip: context.s.t('home.poster'),
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
  return app.effectiveQrMode == QrMode.connected ? app.hasRelay : app.hasStripe;
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
            child: Text(
              connected
                  ? context.s.t('home.tip_page_title')
                  : context.s.t('home.tip_link_title'),
              style: outfitStyle(17, c.text, weight: FontWeight.w700),
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.content_copy_rounded, size: 17, color: c.accent),
                ],
              ),
            ),
          ),
          if (connected) ...[
            const SizedBox(height: 10),
            Text(
              context.s.t('home.fans_pick_methods'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 12.5,
                height: 1.4,
                color: c.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SoftMini(
                  icon: Icons.open_in_new_rounded,
                  label: context.s.t('home.open'),
                  onTap: () => openTipLink(url),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SoftMini(
                  icon: Icons.ios_share_rounded,
                  label: context.s.t('home.share'),
                  onTap: () => SharePlus.instance.share(ShareParams(text: url)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SoftMini(
                  icon: Icons.print_rounded,
                  label: context.s.t('home.poster'),
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
                  builder: (_) => const JarSetupScreen(recreate: true),
                ),
              ),
        style: TextButton.styleFrom(
          foregroundColor: c.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        icon: const Icon(Icons.autorenew_rounded, size: 17),
        label: Text(
          connected
              ? context.s.t('home.new_tip_page_link')
              : context.s.t('home.create_new_tip_link'),
          style: outfitStyle(13, c.textSecondary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent tips + last session
// ---------------------------------------------------------------------------

/// One preview list from two feeds: the Stripe API's latest tips and
/// the device-local tip-page (Revolut/MobilePay) archive — which Stripe
/// never sees, so without this merge relay tips were invisible here.
/// Both inputs arrive newest-first; the result is newest-first, capped.
@visibleForTesting
List<Tip> mergeRecentTips(
  List<Tip> stripe,
  List<Tip> relay, {
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
    final recent = ref.watch(recentTipsProvider);
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
                child: Text(
                  context.s.t('home.recent_tips'),
                  style: outfitStyle(
                    compact ? 15 : 17,
                    c.text,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    AppShellScope.of(context)?.select(ShellTab.history),
                child: Text(context.s.t('home.view_all')),
              ),
            ],
          ),
          if (app.demo)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                context.s.t('home.demo_mode'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
            )
          else
            recent.when(
              data: (tips) {
                final shown = mergeRecentTips(tips, relayRecent);
                return shown.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          context.s.t('home.no_tips_yet'),
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 13.5,
                            color: c.textSecondary,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < shown.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: c.divider),
                            TipTile(
                              tip: shown[i],
                              showTime: !compact,
                            ),
                          ],
                        ],
                      );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.s.t('home.recent_tips_error', {'error': error}),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 13,
                    color: c.danger,
                  ),
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
          Text(
            label,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              color: c.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
        ],
      ),
    );

    return LtCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.s.t('home.last_session'),
            style: outfitStyle(17, c.text, weight: FontWeight.w700),
          ),
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
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.successContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.s.t('home.goal_reached'),
                    style: outfitStyle(
                      12,
                      c.onSuccessContainer,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          row(context.s.t('home.stat.tips'), '${session.count}'),
          row(
            context.s.t('home.stat.duration'),
            formatDuration(session.elapsed(session.endedAt)),
          ),
          if (session.goalMinor > 0)
            row(context.s.t('home.stat.goal'), '$pct%'),
          if (session.count > 0)
            row(
              context.s.t('home.stat.average_tip'),
              formatAmount(session.averageMinor, session.currency),
            ),
          if (session.biggest != null)
            row(
              context.s.t('home.stat.biggest_tip'),
              '${formatAmount(session.biggest!.amountMinor, session.currency)}'
              ' · ${session.biggest!.displayName}',
            ),
        ],
      ),
    );
  }
}
