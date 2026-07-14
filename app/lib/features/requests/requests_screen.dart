import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/live_session.dart';
import '../../domain/request_queue.dart';
import '../../domain/song_request_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../state/live_session_controller.dart';
import '../../state/providers.dart';
import '../../state/session_coordinator.dart';
import '../../widgets/live_session_banner.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/tip_tile.dart';

/// The live request queue (#64): what fans are paying to hear, ranked by
/// money on the table. Only meaningful during a set — outside one it
/// explains itself; during one it is the artist's working surface: pause
/// taking requests, expand a song to see who asked, vouch for a relay tip,
/// and mark songs played or skipped (which sinks them below the queue).
class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  /// Which cards are expanded to their per-tip rows. By songId, so the set
  /// survives the constant re-ranking underneath.
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final live = ref.watch(liveSessionProvider);
    final requests =
        ref.watch(appStateProvider.select((s) => s.band.songRequests));

    final Widget body;
    if (live == null) {
      // The account may be live on ANOTHER device (the Join banner's case).
      // Then "no live set right now" is a lie, and the silent blank is how
      // requests got lost on the artist's second phone: the queue exists,
      // this device just hasn't attached. Offer the same join, inline.
      final remote = ref.watch(activeSessionProvider).value;
      if (remote != null && remote.active) {
        body = _JoinState(info: remote);
      } else {
        body = _Blurb(
          icon: Icons.queue_music_rounded,
          title: context.s.t('requests.empty_title'),
          message: context.s.t('requests.empty_body'),
        );
      }
    } else if (!live.session.requestsOpen) {
      body = _PausedState(
          onResume: ref.read(liveSessionProvider.notifier).toggleRequestsOpen);
    } else {
      body = _queueList(live.session, requests);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Text(
                    context.s.t('requests.title'),
                    style: outfitStyle(20, c.text, weight: FontWeight.w700),
                  ),
                  const Spacer(),
                  // The mid-set pause lever, right where the queue lives.
                  if (live != null) ...[
                    Text(
                      context.s.t(live.session.requestsOpen
                          ? 'requests.taking'
                          : 'requests.paused_pill'),
                      style: outfitStyle(12.5, c.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Switch(
                      value: live.session.requestsOpen,
                      onChanged: (_) => ref
                          .read(liveSessionProvider.notifier)
                          .toggleRequestsOpen(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            body,
          ],
        ),
      ),
    );
  }

  Widget _queueList(LiveSession session, SongRequestSettings requests) {
    final queue = RequestQueue.fromSession(session);
    if (queue.entries.isEmpty) {
      return _Blurb(
        icon: Icons.music_note_rounded,
        title: context.s.t('requests.waiting_title'),
        message: context.s.t('requests.waiting_body'),
      );
    }
    // The library still knows the artist line; the tips only carried titles.
    String? artistOf(String songId) {
      for (final song in requests.songs) {
        if (song.id == songId) return song.artist;
      }
      return null;
    }

    final controller = ref.read(liveSessionProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
            }),
            onSetStatus: (status) =>
                controller.setSongStatus(queue.entries[i].songId, status),
            onMarkVerified: controller.markVerified,
          ),
        ],
      ],
    );
  }
}

/// The account is live on another device and this one hasn't joined: say so
/// and offer the way in — the SAME join the shell banner performs, minus the
/// jump to the stage (here the artist wants the queue, and it fills in place
/// the moment the session attaches).
class _JoinState extends ConsumerStatefulWidget {
  const _JoinState({required this.info});

  final ActiveSessionInfo info;

  @override
  ConsumerState<_JoinState> createState() => _JoinStateState();
}

class _JoinStateState extends ConsumerState<_JoinState> {
  bool _joining = false;

  Future<void> _join() async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      await joinActiveSession(ref, widget.info);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Blurb(
          icon: Icons.sensors_rounded,
          title: context.s.t('requests.join_title'),
          message: context.s.t('requests.join_body'),
        ),
        const SizedBox(height: 14),
        LtPrimaryButton(
          label: context.s.t('requests.join'),
          icon: Icons.sensors_rounded,
          onPressed: _joining ? null : _join,
        ),
      ],
    );
  }
}

/// The requests-off surface during a live set: says so, offers the way back.
class _PausedState extends StatelessWidget {
  const _PausedState({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Blurb(
          icon: Icons.pause_circle_outline_rounded,
          title: context.s.t('requests.paused_title'),
          message: context.s.t('requests.paused_body'),
        ),
        const SizedBox(height: 14),
        LtPrimaryButton(
          label: context.s.t('requests.resume'),
          icon: Icons.play_arrow_rounded,
          onPressed: onResume,
        ),
      ],
    );
  }
}

/// Centered icon + title + one quiet sentence — the empty/waiting states.
class _Blurb extends StatelessWidget {
  const _Blurb({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 44, color: c.textMuted),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: outfitStyle(16, c.text, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One song in the queue: rank, title, money, requester count — expandable
/// to the individual tips with their verify buttons, plus Played/Skip.
class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.rank,
    required this.entry,
    required this.artist,
    required this.currency,
    required this.approximate,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onSetStatus,
    required this.onMarkVerified,
  });

  final int rank;
  final RequestQueueEntry entry;
  final String? artist;
  final String currency;

  /// Session mixed currencies — totals are fx-approximate, say so ("≈").
  final bool approximate;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  /// null restores a sunk card to the queue.
  final ValueChanged<String?> onSetStatus;
  final ValueChanged<String> onMarkVerified;

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
                              : context.s.t('requests.count',
                                  {'n': entry.requesterCount}),
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
                      formatAmount(entry.totalMinor, currency,
                          approximate: approximate),
                      style:
                          outfitStyle(15, c.accent, weight: FontWeight.w700),
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
            for (final tip in entry.tips)
              Row(
                children: [
                  Expanded(child: TipTile(tip: tip)),
                  if (!tip.verified) ...[
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () => onMarkVerified(tip.id),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(context.s.t('requests.mark_verified')),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (sunk)
                  TextButton.icon(
                    onPressed: () => onSetStatus(null),
                    icon: const Icon(Icons.restore_rounded, size: 17),
                    label: Text(context.s.t('requests.restore')),
                  )
                else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          onSetStatus(LiveSession.statusPlayed),
                      icon: Icon(Icons.check_rounded,
                          size: 18, color: c.textSecondary),
                      label: Text(context.s.t('requests.played')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => onSetStatus(LiveSession.statusSkipped),
                    child: Text(context.s.t('requests.skip')),
                  ),
                ],
              ],
            ),
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

/// "Played" / "Skipped" on a sunk card, where the money chip would be noise.
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
        context.s.t(status == LiveSession.statusPlayed
            ? 'requests.played'
            : 'requests.skipped'),
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

/// "{n} unverified" — some of this song's money is fan-declared (relay)
/// and not yet vouched for. Expanding the card shows exactly which tips.
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
