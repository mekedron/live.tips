import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/donation.dart';
import '../../domain/live_session.dart';
import '../../features/live/live_screen.dart' show formatDuration;
import '../../state/providers.dart';
import '../../widgets/donation_tile.dart';
import '../../widgets/lt_ui.dart';
import '../shell/app_shell.dart';

enum _HistoryTab { donations, sessions }

/// All-time donations (straight from the Stripe API, paginated) and the
/// locally recorded session archive.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryTab _tab = _HistoryTab.donations;
  final List<Donation> _donations = [];
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_tab == _HistoryTab.donations &&
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
        _donations.clear();
        _hasMore = true;
        _error = null;
      }
    });
    try {
      if (!_hasMore) return;
      final page = await requests.listDonations(
        paymentLinkId: jar.paymentLinkId,
        startingAfter: _donations.isEmpty ? null : _donations.last.id,
      );
      if (!mounted) return;
      setState(() {
        _donations.addAll(page.donations);
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
    final isRail = AppShellScope.of(context)?.isRail ?? false;
    final sessions =
        ref.watch(localStoreProvider).readSessionHistory().reversed.toList();
    return isRail ? _buildDesktop(sessions) : _buildMobile(sessions);
  }

  // -------------------------------------------------------------- stats ---

  ({String allTime, String tips, String sessions, String avg}) _stats(
      List<LiveSession> sessions) {
    final currency = sessions.isNotEmpty
        ? sessions.first.currency
        : ref.read(appStateProvider).effectiveTipJar?.currency ?? 'usd';
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

  Widget _buildMobile(List<LiveSession> sessions) {
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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('History',
                      style:
                          outfitStyle(20, c.text, weight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                      child: LtStatCard(
                          label: 'All-time', value: stats.allTime)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: LtStatCard(label: 'Tips', value: stats.tips)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: LtStatCard(
                          label: 'Sessions', value: stats.sessions)),
                ],
              ),
              const SizedBox(height: 14),
              LtSegmented<_HistoryTab>(
                values: _HistoryTab.values,
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
                labelOf: (t) => switch (t) {
                  _HistoryTab.donations => 'Donations',
                  _HistoryTab.sessions => 'Sessions',
                },
              ),
              const SizedBox(height: 14),
              if (_tab == _HistoryTab.donations)
                ..._donationGroups()
              else
                ..._sessionCards(sessions),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ desktop ---

  Widget _buildDesktop(List<LiveSession> sessions) {
    final c = context.lt;
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
              Text('History',
                  style: outfitStyle(32, c.text, weight: FontWeight.w800)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: LtStatCard(
                          label: 'All-time total', value: stats.allTime)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: LtStatCard(label: 'Tips', value: stats.tips)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: LtStatCard(
                          label: 'Sessions', value: stats.sessions)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: LtStatCard(
                          label: 'Average tip', value: stats.avg)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 17,
                    child: _DonationsTable(
                      demo: ref.watch(appStateProvider).demo,
                      donations: _donations,
                      loading: _loading,
                      hasMore: _hasMore,
                      error: _error,
                      onLoadMore: _loadMore,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 2, bottom: 12),
                          child: Text('Sessions',
                              style: outfitStyle(17, c.text,
                                  weight: FontWeight.w700)),
                        ),
                        if (sessions.isEmpty)
                          Text(
                            'No sessions yet — hit “Go live” before the '
                            'first song!',
                            style: TextStyle(
                                fontFamily: kFontBody,
                                fontSize: 13.5,
                                color: c.textSecondary),
                          )
                        else
                          for (final s in sessions) ...[
                            _SessionCard(
                                session: s,
                                onTap: () => _showSessionDetail(context, s)),
                            const SizedBox(height: 12),
                          ],
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

  // -------------------------------------------------- donations grouping ---

  List<Widget> _donationGroups() {
    final c = context.lt;
    final app = ref.watch(appStateProvider);

    if (app.demo) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Demo mode has no Stripe history.\nConnect your account to see '
            'every donation you\'ve ever received.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 13.5,
                height: 1.5,
                color: c.textSecondary),
          ),
        ),
      ];
    }
    if (_error != null && _donations.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13,
                      color: c.danger)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _loadMore(reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ];
    }
    if (_donations.isEmpty && !_loading) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No donations yet — they\'ll all show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 13.5,
                color: c.textSecondary),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    List<Donation> group = [];
    String? groupLabel;

    void flush() {
      if (group.isEmpty) return;
      final rows = group;
      widgets
        ..add(Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
          child: LtSectionLabel(groupLabel!),
        ))
        ..add(LtCard(
          radius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: c.divider),
                DonationTile(donation: rows[i], showTime: true),
              ],
            ],
          ),
        ));
      group = [];
    }

    for (final d in _donations) {
      final label = _dayLabel(d.createdAt);
      if (label != groupLabel) {
        flush();
        groupLabel = label;
      }
      group.add(d);
    }
    flush();

    if (_hasMore || _loading) {
      widgets.add(const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ));
    }
    return widgets;
  }

  String _dayLabel(DateTime time) {
    final now = DateTime.now();
    final day = DateTime(time.year, time.month, time.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Tonight';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
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
            'No sessions yet — hit “Go live” before the first song!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 13.5,
                color: c.textSecondary),
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
                    formatAmount(session.totalMinor, session.currency),
                    style: moneyStyle(34, c.text),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat('EEE, MMM d').format(session.startedAt)} · '
                    '${session.count} tips · '
                    '${formatDuration(session.elapsed(session.endedAt))}'
                    '${session.goalReached ? ' · goal reached 🎉' : ''}',
                    style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.divider),
            Expanded(
              child: session.donations.isEmpty
                  ? Center(
                      child: Text('No tips in this session.',
                          style: TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 13.5,
                              color: c.textSecondary)),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: session.donations.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: c.divider),
                      itemBuilder: (context, index) => DonationTile(
                        donation: session
                            .donations[session.donations.length - 1 - index],
                        showTime: true,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desktop donations table: FAN · MESSAGE · WHEN · AMOUNT.
class _DonationsTable extends StatelessWidget {
  const _DonationsTable({
    required this.demo,
    required this.donations,
    required this.loading,
    required this.hasMore,
    required this.error,
    required this.onLoadMore,
  });

  final bool demo;
  final List<Donation> donations;
  final bool loading;
  final bool hasMore;
  final String? error;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;

    Widget headerCell(String text, {int flex = 1, TextAlign? align}) =>
        Expanded(
          flex: flex,
          child: Text(
            text.toUpperCase(),
            textAlign: align,
            style: outfitStyle(11, c.textMuted,
                weight: FontWeight.w700, letterSpacing: 1),
          ),
        );

    return LtCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Donations',
              style: outfitStyle(17, c.text, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (demo)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Demo mode has no Stripe history. Connect your account to '
                'see every donation you\'ve ever received.',
                style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 13.5,
                    height: 1.5,
                    color: c.textSecondary),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  headerCell('Fan', flex: 5),
                  headerCell('Message', flex: 8),
                  headerCell('When', flex: 3),
                  headerCell('Amount', flex: 2, align: TextAlign.right),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            if (donations.isEmpty && !loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  error ?? 'No donations yet — they\'ll all show up here.',
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13.5,
                      color: error != null ? c.danger : c.textSecondary),
                ),
              ),
            for (var i = 0; i < donations.length; i++) ...[
              if (i > 0) Divider(height: 1, color: c.divider),
              _TableRow(donation: donations[i]),
            ],
            if (loading)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else if (hasMore && donations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed: onLoadMore,
                    child: const Text('Load more'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.donation});

  final Donation donation;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final anonymous = donation.name == null || donation.name!.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                InitialAvatar(
                    name: donation.displayName,
                    anonymous: anonymous,
                    size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    donation.displayName,
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
              ],
            ),
          ),
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                donation.hasMessage ? donation.message!.trim() : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  color:
                      donation.hasMessage ? c.textSecondary : c.textFaint,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _when(donation.createdAt),
              style: TextStyle(
                  fontFamily: kFontBody, fontSize: 12.5, color: c.textMuted),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatAmount(donation.amountMinor, donation.currency),
              textAlign: TextAlign.right,
              style: outfitStyle(15, c.accent, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _when(DateTime time) {
    final now = DateTime.now();
    final sameDay = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
    return sameDay
        ? 'Today ${DateFormat('HH:mm').format(time)}'
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
    final sameDay = started.year == now.year &&
        started.month == now.month &&
        started.day == now.day;
    final dayLabel =
        sameDay ? 'Tonight' : DateFormat('MMM d').format(started);

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
                          formatAmount(session.totalMinor, session.currency),
                          style: moneyStyle(22, c.text, height: 1.1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (session.goalMinor > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: reached
                              ? c.successContainer
                              : c.chip,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          session.bankedJars > 0
                              ? '$pct% · 🏆 ${session.bankedJars}'
                              : '$pct%',
                          style: outfitStyle(
                            11,
                            reached
                                ? c.onSuccessContainer
                                : c.textSecondary,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$dayLabel · ${session.count} tips · '
                  '${formatDuration(session.elapsed(session.endedAt))}',
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 12.5,
                      color: c.textSecondary),
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
