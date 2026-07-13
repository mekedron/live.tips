import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/external_link.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/enum_labels.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/tip.dart';
import '../../domain/live_session.dart';
import '../../domain/tip_method.dart';
import '../../features/live/live_screen.dart' show formatDuration;
import '../../state/live_session_controller.dart';
import '../../state/providers.dart';
import '../../widgets/tip_tile.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/method_badges.dart';
import '../shell/app_shell.dart';

// Session-first, then the relay methods artists lean on day to day, with
// Stripe last — it's the recommended path but the least-used tab in
// practice.
enum _HistoryTab { sessions, mobilepay, revolut, monzo, tips }

/// The relay method a tab lists, or null for the tabs that aren't per-method.
TipMethod? _tabMethod(_HistoryTab tab) => switch (tab) {
  _HistoryTab.mobilepay => TipMethod.mobilepay,
  _HistoryTab.revolut => TipMethod.revolut,
  _HistoryTab.monzo => TipMethod.monzo,
  _HistoryTab.sessions || _HistoryTab.tips => null,
};

/// The tab that lists a relay method, in the fixed left-to-right tab order.
const _relayTabs = [
  _HistoryTab.mobilepay,
  _HistoryTab.revolut,
  _HistoryTab.monzo,
];

/// Header note over the device-local tip-page lists — honesty first: these
/// rows are fan-declared, not settled payments.
String _relayHistoryNote(BuildContext context) =>
    context.s.t('history.relay_note');

String _relayHistoryEmpty(BuildContext context, TipMethod method) =>
    context.s.t('history.relay_empty', {'method': method.l10nLabel(context)});

/// Opens the tip's transaction in the artist's Stripe Dashboard (a new
/// browser tab on web). No-op for tips that have no link — demo tips, or
/// records archived before the PaymentIntent id was captured.
void _openTipInStripe(Tip tip) {
  final url = tip.stripeDashboardUrl;
  if (url == null) return;
  openExternal(url);
}

/// The tap handler for a tip row, or null when it has no Stripe link
/// (so the row stays non-interactive rather than looking tappable but dead).
VoidCallback? _stripeTap(Tip tip) =>
    tip.stripeDashboardUrl == null
    ? null
    : () => _openTipInStripe(tip);

/// A subtle link that opens the artist's whole Stripe payments list in the
/// Dashboard — the escape hatch to *every* transaction in the account,
/// including anything that didn't come in through live.tips.
class _ViewInStripeButton extends StatelessWidget {
  const _ViewInStripeButton(this.url);

  final String url;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return TextButton(
      onPressed: () => openExternal(url),
      style: TextButton.styleFrom(
        foregroundColor: c.textSecondary,
        textStyle: outfitStyle(12.5, c.textSecondary, weight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.s.t('history.view_all_stripe')),
          SizedBox(width: 5),
          Icon(Icons.open_in_new_rounded, size: 14),
        ],
      ),
    );
  }
}

/// All-time tips (straight from the Stripe API, paginated) and the
/// locally recorded session archive.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryTab _tab = _HistoryTab.sessions;
  final List<Tip> _tips = [];
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_tab == _HistoryTab.tips &&
          _scrollController.position.extentAfter < 300) {
        _loadMore();
      }
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading) return;
    final requests = ref.read(stripeRequestsProvider);
    final jar = ref.read(appStateProvider).effectiveTipJar;
    if (requests == null || jar == null || jar.isDemo) return;

    setState(() {
      _loading = true;
      if (reset) {
        _tips.clear();
        _hasMore = true;
        _error = null;
      }
    });
    try {
      if (!_hasMore) return;
      final page = await requests.listTips(
        startingAfter: _tips.isEmpty ? null : _tips.last.id,
      );
      if (!mounted) return;
      setState(() {
        _tips.addAll(page.tips);
        _hasMore = page.hasMore;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A session that just ended likely brought in tips this list hasn't seen —
    // reload from Stripe the moment live mode exits so History isn't stuck on a
    // pre-session snapshot. (History stays mounted in the shell's IndexedStack,
    // so this fires even while the artist is still on the summary screen.)
    ref.listen<LiveState?>(liveSessionProvider, (previous, next) {
      if (previous != null && next == null) _loadMore(reset: true);
    });
    final isRail = AppShellScope.of(context)?.isRail ?? false;
    final app = ref.watch(appStateProvider);
    // Cloud mirrors fill in asynchronously — re-read when a snapshot lands.
    ref.watch(repoRevisionProvider);
    final sessions = ref
        .watch(accountDataRepositoryProvider)
        .readSessionHistory(app.accountId)
        .reversed
        .toList();
    final jar = app.effectiveTipJar;
    final stripeAllUrl = (jar == null || jar.isDemo)
        ? null
        : jar.stripePaymentsUrl;
    // Each relay-method tab exists for anyone whose jar offers it, and for
    // anyone whose device still remembers tips from it (jar deleted, tips
    // kept). Stripe-only installs keep the familiar two tabs untouched.
    final relayHistory = ref.watch(relayHistoryProvider);
    final relayJar = app.effectiveRelayJar;
    // A relay tab shows when the method is configured now, or when this device
    // still remembers tips from it (jar deleted, tips kept).
    final configured = {
      if (relayJar?.hasMobilePay ?? false) TipMethod.mobilepay,
      if (relayJar?.hasRevolut ?? false) TipMethod.revolut,
      if (relayJar?.hasMonzo ?? false) TipMethod.monzo,
    };
    final relayTabs = _relayTabs
        .where(
          (t) =>
              configured.contains(_tabMethod(t)) ||
              relayHistory.any((d) => d.method == _tabMethod(t)),
        )
        .toSet();
    // Demo mode has no real key but still previews the Stripe tab (with its
    // own explanatory empty state below); a real, key-less account gets no
    // tab at all — there's nothing to fetch and nothing archived locally.
    final showTips = app.demo || app.hasStripe;
    if (_relayTabs.contains(_tab) && !relayTabs.contains(_tab)) {
      _tab = _HistoryTab.sessions; // the tab just vanished under us
    }
    if (_tab == _HistoryTab.tips && !showTips) {
      _tab = _HistoryTab.sessions;
    }
    return isRail
        ? _buildDesktop(
            sessions,
            stripeAllUrl,
            relayTabs,
            showTips,
            relayHistory,
          )
        : _buildMobile(
            sessions,
            stripeAllUrl,
            relayTabs,
            showTips,
            relayHistory,
          );
  }

  /// Tabs in fixed left-to-right order (Sessions, then relay methods, then
  /// Stripe last — it's recommended but the least-used tab in practice),
  /// filtered to the ones that currently apply.
  List<_HistoryTab> _visibleTabs(
    Set<_HistoryTab> relayTabs,
    bool showTips,
  ) => [
    _HistoryTab.sessions,
    ..._relayTabs.where(relayTabs.contains),
    if (showTips) _HistoryTab.tips,
  ];

  String _tabLabel(
    BuildContext context,
    _HistoryTab t,
    Set<_HistoryTab> relayTabs,
  ) {
    final method = _tabMethod(t);
    if (method != null) return method.label;
    return switch (t) {
      _HistoryTab.sessions => context.s.t('history.tab_sessions'),
      // 'Stripe' only makes sense next to a relay tab — alone it stays
      // 'Tips', so Stripe-only users see no churn.
      _ => relayTabs.isNotEmpty
          ? 'Stripe'
          : context.s.t('history.tab_tips'),
    };
  }

  // -------------------------------------------------------------- stats ---

  ({String allTime, String tips, String sessions, String avg}) _stats(
    List<LiveSession> sessions,
  ) {
    final currency = sessions.isNotEmpty
        ? sessions.first.currency
        : ref.read(appStateProvider).currency;
    final total = sessions.fold(0, (sum, s) => sum + s.totalMinor);
    final tips = sessions.fold(0, (sum, s) => sum + s.count);
    return (
      allTime: formatAmount(total, currency),
      tips: '$tips',
      sessions: '${sessions.length}',
      avg: formatAmount(tips == 0 ? 0 : total ~/ tips, currency),
    );
  }

  // ------------------------------------------------------------- mobile ---

  Widget _buildMobile(
    List<LiveSession> sessions,
    String? stripeAllUrl,
    Set<_HistoryTab> relayTabs,
    bool showTips,
    List<Tip> relayHistory,
  ) {
    final c = context.lt;
    final stats = _stats(sessions);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: RefreshIndicator(
          onRefresh: () => _loadMore(reset: true),
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Text(
                      context.s.t('history.title'),
                      style: outfitStyle(20, c.text, weight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (_tab == _HistoryTab.tips && stripeAllUrl != null)
                      _ViewInStripeButton(stripeAllUrl),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: LtStatCard(
                      label: context.s.t('history.stat_all_time_short'),
                      value: stats.allTime,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LtStatCard(
                      label: context.s.t('history.stat_tips'),
                      value: stats.tips,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LtStatCard(
                      label: context.s.t('history.stat_sessions'),
                      value: stats.sessions,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LtSegmented<_HistoryTab>(
                values: _visibleTabs(relayTabs, showTips),
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
                labelOf: (t) => _tabLabel(context, t, relayTabs),
              ),
              const SizedBox(height: 14),
              if (_tab == _HistoryTab.tips) ...[
                ..._tipGroups(),
              ] else if (_tabMethod(_tab) case final method?)
                ..._relayGroups(relayHistory, method)
              else
                ..._sessionCards(sessions),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ desktop ---

  Widget _buildDesktop(
    List<LiveSession> sessions,
    String? stripeAllUrl,
    Set<_HistoryTab> relayTabs,
    bool showTips,
    List<Tip> relayHistory,
  ) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final stats = _stats(sessions);
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    context.s.t('history.title'),
                    style: outfitStyle(32, c.text, weight: FontWeight.w800),
                  ),
                  const Spacer(),
                  if (_tab == _HistoryTab.tips &&
                      !app.demo &&
                      stripeAllUrl != null)
                    _ViewInStripeButton(stripeAllUrl),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: LtStatCard(
                      label: context.s.t('history.stat_all_time'),
                      value: stats.allTime,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LtStatCard(
                      label: context.s.t('history.stat_tips'),
                      value: stats.tips,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LtStatCard(
                      label: context.s.t('history.stat_sessions'),
                      value: stats.sessions,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LtStatCard(
                      label: context.s.t('history.stat_avg'),
                      value: stats.avg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LtSegmented<_HistoryTab>(
                values: _visibleTabs(relayTabs, showTips),
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
                labelOf: (t) => _tabLabel(context, t, relayTabs),
              ),
              const SizedBox(height: 24),
              if (_tab == _HistoryTab.tips)
                _TipsTable(
                  title: relayTabs.isNotEmpty
                      ? 'Stripe'
                      : context.s.t('history.tab_tips'),
                  demo: app.demo,
                  relayOnly: !app.demo && !app.hasStripe,
                  tips: _tips,
                  loading: _loading,
                  hasMore: _hasMore,
                  error: _error,
                  onLoadMore: _loadMore,
                )
              else if (_tabMethod(_tab) case final method?)
                _RelayTable(
                  title: method.label,
                  method: method,
                  tips: _byMethod(relayHistory, method),
                )
              else if (sessions.isEmpty)
                Text(
                  context.s.t('history.sessions_empty'),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 13.5,
                    color: c.textSecondary,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final s in sessions) ...[
                      _SessionCard(
                        session: s,
                        onTap: () => _showSessionDetail(context, s),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------- tips grouping ---

  List<Widget> _tipGroups() {
    final c = context.lt;
    final app = ref.watch(appStateProvider);

    if (app.demo) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            context.s.t('history.demo_no_stripe'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
        ),
      ];
    }
    if (!app.hasStripe) {
      // Relay-only: there's no Stripe account to list tips from.
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            context.s.t('history.relay_only_tabs'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
        ),
      ];
    }
    if (_error != null && _tips.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13,
                  color: c.danger,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _loadMore(reset: true),
                child: Text(context.s.t('history.retry')),
              ),
            ],
          ),
        ),
      ];
    }
    if (_tips.isEmpty && !_loading) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            context.s.t('history.tips_empty'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              color: c.textSecondary,
            ),
          ),
        ),
      ];
    }

    final widgets = _dayGroupedTiles(_tips);

    if (_hasMore || _loading) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        ),
      );
    }
    return widgets;
  }

  /// [tips] (newest first) as day-labelled cards of [TipTile]s —
  /// the shared body of the Stripe and tip-page mobile lists.
  List<Widget> _dayGroupedTiles(List<Tip> tips) {
    final c = context.lt;
    final widgets = <Widget>[];
    List<Tip> group = [];
    String? groupLabel;

    void flush() {
      if (group.isEmpty) return;
      final rows = group;
      widgets
        ..add(
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
            child: LtSectionLabel(groupLabel!),
          ),
        )
        ..add(
          LtCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: c.divider),
                  TipTile(
                    tip: rows[i],
                    showTime: true,
                    // Null for tip-page tips (no Stripe transaction to open) —
                    // the row stays inert instead of tappable-but-dead.
                    onTap: _stripeTap(rows[i]),
                  ),
                ],
              ],
            ),
          ),
        );
      group = [];
    }

    for (final d in tips) {
      final label = _dayLabel(context, d.createdAt);
      if (label != groupLabel) {
        flush();
        groupLabel = label;
      }
      group.add(d);
    }
    flush();
    return widgets;
  }

  // --------------------------------------------------- tip-page history ---

  List<Tip> _byMethod(List<Tip> tips, TipMethod method) =>
      tips.where((d) => d.method == method).toList();

  List<Widget> _relayGroups(List<Tip> relayHistory, TipMethod method) {
    final c = context.lt;
    final tips = _byMethod(relayHistory, method);
    if (tips.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            _relayHistoryEmpty(context, method),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
        child: Text(
          _relayHistoryNote(context),
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 12.5,
            height: 1.4,
            color: c.textMuted,
          ),
        ),
      ),
      ..._dayGroupedTiles(tips),
    ];
  }

  String _dayLabel(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final day = DateTime(time.year, time.month, time.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return context.s.t('history.tonight');
    if (day == today.subtract(const Duration(days: 1))) {
      return context.s.t('history.yesterday');
    }
    return DateFormat('EEEE, MMM d').format(time);
  }

  // ------------------------------------------------------------ sessions ---

  List<Widget> _sessionCards(List<LiveSession> sessions) {
    final c = context.lt;
    if (sessions.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            context.s.t('history.sessions_empty'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              color: c.textSecondary,
            ),
          ),
        ),
      ];
    }
    return [
      for (final s in sessions) ...[
        _SessionCard(session: s, onTap: () => _showSessionDetail(context, s)),
        const SizedBox(height: 12),
      ],
    ];
  }

  void _showSessionDetail(BuildContext context, LiveSession session) {
    final c = context.lt;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                children: [
                  Text(
                    formatAmount(
                      session.totalMinor,
                      session.currency,
                      approximate: session.isMixedCurrency,
                    ),
                    style: moneyStyle(34, c.text),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.s.t('history.session_meta', {
                          'date': DateFormat(
                            'EEE, MMM d',
                          ).format(session.startedAt),
                          'count': session.count,
                          'duration': formatDuration(
                            session.elapsed(session.endedAt),
                          ),
                        }) +
                        (session.goalReached
                            ? context.s.t('history.goal_reached_suffix')
                            : ''),
                    style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.divider),
            Expanded(
              child: session.tips.isEmpty
                  ? Center(
                      child: Text(
                        context.s.t('history.session_no_tips'),
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 13.5,
                          color: c.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: session.tips.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: c.divider),
                      itemBuilder: (context, index) {
                        final tip = session
                            .tips[session.tips.length - 1 - index];
                        return TipTile(
                          tip: tip,
                          showTime: true,
                          onTap: _stripeTap(tip),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Width of the trailing open-in-Stripe icon column — shared by the header
/// spacer and the rows so the money column stays aligned above and below.
const double _kStripeColWidth = 32;

/// FAN · MESSAGE · WHEN · AMOUNT (+ trailing ↗ spacer) — the header row the
/// Stripe and tip-page desktop tables share, so their columns line up.
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.lt;

    Widget cell(String text, {int flex = 1, TextAlign? align}) => Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: outfitStyle(
          11,
          c.textMuted,
          weight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          cell(context.s.t('history.col_fan'), flex: 5),
          cell(context.s.t('history.col_message'), flex: 8),
          cell(context.s.t('history.col_when'), flex: 3),
          cell(
            context.s.t('history.col_amount'),
            flex: 2,
            align: TextAlign.right,
          ),
          const SizedBox(width: _kStripeColWidth),
        ],
      ),
    );
  }
}

/// Desktop tips table: FAN · MESSAGE · WHEN · AMOUNT · ↗ (Stripe link).
class _TipsTable extends StatelessWidget {
  const _TipsTable({
    required this.title,
    required this.demo,
    required this.relayOnly,
    required this.tips,
    required this.loading,
    required this.hasMore,
    required this.error,
    required this.onLoadMore,
  });

  /// 'Tips' alone; 'Stripe' when the tip-page table sits below it.
  final String title;

  final bool demo;

  /// Connected-mode jar without a Stripe key: no account to list from.
  final bool relayOnly;
  final List<Tip> tips;
  final bool loading;
  final bool hasMore;
  final String? error;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;

    return LtCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: outfitStyle(17, c.text, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (demo)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                context.s.t('history.demo_no_stripe_inline'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
            )
          else if (relayOnly)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                context.s.t('history.relay_only_below'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
            )
          else ...[
            const _TableHeader(),
            Divider(height: 1, color: c.border),
            if (tips.isEmpty && !loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  error ?? context.s.t('history.tips_empty'),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 13.5,
                    color: error != null ? c.danger : c.textSecondary,
                  ),
                ),
              ),
            for (var i = 0; i < tips.length; i++) ...[
              if (i > 0) Divider(height: 1, color: c.divider),
              _TableRow(
                tip: tips[i],
                onTap: _stripeTap(tips[i]),
              ),
            ],
            if (loading)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else if (hasMore && tips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed: onLoadMore,
                    child: Text(context.s.t('history.load_more')),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Desktop table for one relay method's (Revolut or MobilePay) device-local
/// archive. Same columns as the Stripe table; the trailing link column stays
/// empty — these tips have no Stripe transaction to open.
class _RelayTable extends StatelessWidget {
  const _RelayTable({
    required this.title,
    required this.method,
    required this.tips,
  });

  final String title;
  final TipMethod method;

  /// Newest first, already filtered to [method].
  final List<Tip> tips;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: outfitStyle(17, c.text, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            _relayHistoryNote(context),
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 12.5,
              height: 1.4,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          if (tips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _relayHistoryEmpty(context, method),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
            )
          else ...[
            const _TableHeader(),
            Divider(height: 1, color: c.border),
            for (var i = 0; i < tips.length; i++) ...[
              if (i > 0) Divider(height: 1, color: c.divider),
              _TableRow(
                tip: tips[i],
                // Always null here (no dashboard link) — kept as the shared
                // helper so the row logic stays identical to the Stripe table.
                onTap: _stripeTap(tips[i]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.tip, this.onTap});

  final Tip tip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final anonymous = tip.name == null || tip.name!.trim().isEmpty;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                InitialAvatar(
                  name: tip.displayName,
                  anonymous: anonymous,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    tip.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ),
                if (tip.method != TipMethod.stripe) ...[
                  const SizedBox(width: 6),
                  MethodBadge(tip.method),
                ],
                if (tip.inPerson) ...[
                  const SizedBox(width: 6),
                  const InPersonTag(),
                ],
                if (!tip.verified) ...[
                  const SizedBox(width: 6),
                  const UnverifiedTag(),
                ],
                if (!tip.viaService) ...[
                  const SizedBox(width: 6),
                  const ExternalTag(),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                tip.hasMessage ? tip.message!.trim() : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  color: tip.hasMessage ? c.textSecondary : c.textFaint,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _when(context, tip.createdAt),
              style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 12.5,
                color: c.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatAmount(tip.amountMinor, tip.currency),
              textAlign: TextAlign.right,
              style: outfitStyle(15, c.accent, weight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: _kStripeColWidth,
            child: onTap == null
                ? null
                : Center(
                    child: Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: c.textMuted,
                    ),
                  ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }

  String _when(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final sameDay =
        time.year == now.year && time.month == now.month && time.day == now.day;
    return sameDay
        ? context.s.t('history.today_at', {
            'time': DateFormat('HH:mm').format(time),
          })
        : DateFormat('MMM d').format(time);
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final LiveSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final pct = session.goalMinor <= 0
        ? 0
        : (session.totalMinor / session.goalMinor * 100).round();
    final reached = session.goalReached;
    final now = DateTime.now();
    final started = session.startedAt;
    final sameDay =
        started.year == now.year &&
        started.month == now.month &&
        started.day == now.day;
    final dayLabel = sameDay
        ? context.s.t('history.tonight')
        : DateFormat('MMM d').format(started);

    return LtCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatAmount(
                      session.totalMinor,
                      session.currency,
                      approximate: session.isMixedCurrency,
                    ),
                          style: moneyStyle(22, c.text, height: 1.1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (session.goalMinor > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: reached ? c.successContainer : c.chip,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          session.bankedJars > 0
                              ? context.s.t('history.session_pct_jars', {
                                  'pct': pct,
                                  'jars': session.bankedJars,
                                })
                              : '$pct%',
                          style: outfitStyle(
                            11,
                            reached ? c.onSuccessContainer : c.textSecondary,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.s.t('history.session_meta', {
                    'date': dayLabel,
                    'count': session.count,
                    'duration': formatDuration(
                      session.elapsed(session.endedAt),
                    ),
                  }),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 22, color: c.textMuted),
        ],
      ),
    );
  }
}
