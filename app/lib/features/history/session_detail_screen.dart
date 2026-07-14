import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/external_link.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/live_session.dart';
import '../../domain/request_queue.dart';
import '../../domain/tip.dart';
import '../../features/live/live_screen.dart' show formatDuration;
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/tip_tile.dart';

/// One past session as a full page (#67): the header the History sheet used
/// to show (total, date · count · duration, goal), the donations list, and —
/// when the set took song requests — the final queue as the set ended.
///
/// Read-only retrospection, all of it derived from the [session] History
/// already handed us: no network read on open, no schema, no actions. The
/// played/skipped verdicts and verified marks are the archive's word; there
/// is no editing the past from here (issue #67, open question 1).
///
/// Pushed via RootBoundRoute from both History session-card call sites: the
/// page describes THIS profile's history, so an account/profile switch pops
/// it rather than leaving one band's night over another's world (#48).
class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.session});

  final LiveSession session;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  /// Which request cards are expanded to their per-tip rows, by songId —
  /// the same expansion model as the live Requests tab.
  final _expanded = <String>{};

  /// The tap handler for a donation row, or null when the tip has no Stripe
  /// transaction to open (demo/relay tips) — the row stays inert rather than
  /// looking tappable but dead. Mirrors History's own helper.
  VoidCallback? _stripeTap(Tip tip) {
    final url = tip.stripeDashboardUrl;
    if (url == null) return null;
    return () => openExternal(url);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final session = widget.session;
    // The same pure helper the live Requests tab (and the fan-page publish)
    // builds on — grouping, titling and ranking are never reinvented here.
    // Empty for pre-#64 archives, requests-off sets and sets nobody
    // requested in: those pages are exactly the header + donations story.
    final queue = RequestQueue.fromSession(session);
    // The library still knows the artist line; the tips only carried titles.
    final songs = ref.watch(
      appStateProvider.select((s) => s.band.songRequests.songs),
    );
    String? artistOf(String songId) {
      for (final song in songs) {
        if (song.id == songId) return song.artist;
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.s.t('history.detail_title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _Header(session: session),
              const SizedBox(height: 16),
              Divider(height: 1, color: c.divider),
              if (session.tips.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    context.s.t('history.session_no_tips'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 13.5,
                      color: c.textSecondary,
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
                  child: LtSectionLabel(
                    context.s.t('history.detail_donations'),
                  ),
                ),
                // The sheet's TipTile list, unchanged: newest first, with the
                // Stripe-dashboard tap-through where a tip has one.
                LtCard(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      for (var i = session.tips.length - 1; i >= 0; i--) ...[
                        if (i < session.tips.length - 1)
                          Divider(height: 1, color: c.divider),
                        TipTile(
                          tip: session.tips[i],
                          showTime: true,
                          onTap: _stripeTap(session.tips[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (queue.entries.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
                  child: LtSectionLabel(
                    context.s.t('history.detail_requests'),
                  ),
                ),
                for (var i = 0; i < queue.entries.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _RequestCard(
                    rank: i + 1,
                    entry: queue.entries[i],
                    artist: artistOf(queue.entries[i].songId),
                    currency: session.currency,
                    approximate: session.isMixedCurrency,
                    expanded: _expanded.contains(queue.entries[i].songId),
                    onToggleExpanded: () => setState(() {
                      final id = queue.entries[i].songId;
                      _expanded.contains(id)
                          ? _expanded.remove(id)
                          : _expanded.add(id);
                    }),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The sheet's header, carried over: big total (approximate-marked when the
/// session mixed currencies), the date · count · duration line with the
/// goal-reached suffix, and the goal chip the session card already computes.
class _Header extends StatelessWidget {
  const _Header({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final pct = session.goalMinor <= 0
        ? 0
        : (session.totalMinor / session.goalMinor * 100).round();
    final reached = session.goalReached;
    return Column(
      children: [
        const SizedBox(height: 12),
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
                'date': DateFormat('EEE, MMM d').format(session.startedAt),
                'count': session.count,
                'duration': formatDuration(session.elapsed(session.endedAt)),
              }) +
              (session.goalReached
                  ? context.s.t('history.goal_reached_suffix')
                  : ''),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 13,
            color: c.textSecondary,
          ),
        ),
        if (session.goalMinor > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      ],
    );
  }
}

/// One song in the archived queue — the live Requests tab's card anatomy
/// (rank, title, money, requester count, PLAYED/SKIPPED, expandable per-tip
/// rows) rendered READ-ONLY: no pause switch, no mark-played, no
/// mark-verified, no restore. History is a record, not a control surface.
class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.rank,
    required this.entry,
    required this.artist,
    required this.currency,
    required this.approximate,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final int rank;
  final RequestQueueEntry entry;
  final String? artist;
  final String currency;

  /// Session mixed currencies — totals are fx-approximate, say so ("≈").
  final bool approximate;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final sunk = !entry.active;
    final card = LtCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            child: Row(
              children: [
                _RankBadge(rank: rank, sunk: sunk),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: outfitStyle(15, c.text, weight: FontWeight.w700),
                      ),
                      Text(
                        [
                          ?artist,
                          entry.requesterCount == 1
                              ? context.s.t('requests.count_one')
                              : context.s.t('requests.count', {
                                  'n': entry.requesterCount,
                                }),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(
                        entry.totalMinor,
                        currency,
                        approximate: approximate,
                      ),
                      style: outfitStyle(15, c.accent, weight: FontWeight.w700),
                    ),
                    if (sunk)
                      _StatusChip(status: entry.status!)
                    else if (entry.unverifiedCount > 0)
                      _UnverifiedCountChip(count: entry.unverifiedCount),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                  color: c.textMuted,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 4),
            Divider(height: 1, color: c.divider),
            // Newest first (RequestQueueEntry.tips). The TipTile itself wears
            // the unverified tag for relay money the artist never vouched
            // for — the archive's word, kept forever.
            for (final tip in entry.tips) TipTile(tip: tip),
          ],
        ],
      ),
    );
    // Played/skipped songs stay legible but visibly out of the running.
    return sunk ? Opacity(opacity: 0.55, child: card) : card;
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.sunk});

  final int rank;
  final bool sunk;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: sunk ? c.chip : c.accentSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: outfitStyle(
          12.5,
          sunk ? c.textMuted : c.onAccentSoft,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "{n} unverified" — some of this song's money was fan-declared (relay)
/// and never vouched for during the set. Expanding shows exactly which tips.
class _UnverifiedCountChip extends StatelessWidget {
  const _UnverifiedCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.s.t('requests.unverified_count', {'n': count}),
        style: outfitStyle(
          10.5,
          c.textMuted,
          weight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// "Played" / "Skipped" on a sunk card — the artist's verdict as the set
/// ended, straight from the archived songStatuses.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.s.t(
          status == LiveSession.statusPlayed
              ? 'requests.played'
              : 'requests.skipped',
        ),
        style: outfitStyle(
          10.5,
          c.textMuted,
          weight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
