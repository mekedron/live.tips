import 'live_session.dart';
import 'tip.dart';

/// One song in the live request queue: every request tip for it folded into
/// a total, plus the artist's played/skipped verdict.
class RequestQueueEntry {
  const RequestQueueEntry({
    required this.songId,
    required this.title,
    required this.totalMinor,
    required this.requesterCount,
    required this.status,
    required this.tips,
  });

  final String songId;

  /// From the NEWEST request's stored songTitle — the fan page's wording at
  /// the time, so a renamed (or deleted) library entry can't orphan the
  /// card. Falls back to the id only when no tip carried a title at all.
  final String title;

  /// Everything requested for this song, in the SESSION's currency where a
  /// rate exists (same fx table [LiveSession.totalMinor] folds with). A tip
  /// whose currency can't convert counts at its raw minor amount instead of
  /// vanishing: a rough rank beats a missing request.
  final int totalMinor;

  /// How many tips back this song ( == tips.length).
  final int requesterCount;

  /// [LiveSession.statusPlayed] / [LiveSession.statusSkipped], or null while
  /// the song is still queued.
  final String? status;

  /// The individual request tips, newest first.
  final List<Tip> tips;

  bool get active => status == null;

  int get unverifiedCount => tips.where((t) => !t.verified).length;
}

/// The ranked request queue of one live session — pure: derived entirely
/// from the session's tips (those with a songId) and its song statuses.
///
/// The order, top to bottom:
///  1. active (no status) before played/skipped — the money on the table
///     comes first, the finished pile sinks;
///  2. within each group: totalMinor desc, then requesterCount desc, then
///     newest-request-first, then songId (a pure determinism tiebreak).
/// The sunk group keeps the same money order — statuses carry no timestamp,
/// so "most recently played first" is not promised, and the pile is only
/// there for reference anyway.
class RequestQueue {
  const RequestQueue(this.entries);

  /// Ranked, see the class doc.
  final List<RequestQueueEntry> entries;

  /// The relay accepts at most this many queue entries per publish
  /// (functions validate.ts MAX_QUEUE_ENTRIES) — [toWirePayload] keeps the
  /// top of the ranking and drops the tail.
  static const maxWireEntries = 150;

  // Server bounds for one entry's totals (validate.ts rejects, we clamp —
  // an absurd total should cost precision on the fan page, not the publish).
  static const _maxWireTotalMinor = 100000000;
  static const _maxWireCount = 10000;

  factory RequestQueue.fromSession(LiveSession session) {
    final bySong = <String, List<Tip>>{};
    for (final tip in session.tips) {
      final songId = tip.songId;
      if (songId == null) continue;
      bySong.putIfAbsent(songId, () => []).add(tip);
    }
    final statuses = session.songStatuses;
    final entries = <RequestQueueEntry>[];
    for (final e in bySong.entries) {
      final tips = e.value
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
      final title = tips
              .map((t) => t.songTitle)
              .firstWhere((t) => t != null && t.trim().isNotEmpty,
                  orElse: () => null) ??
          e.key;
      entries.add(RequestQueueEntry(
        songId: e.key,
        title: title,
        totalMinor: tips.fold(
            0,
            (sum, t) =>
                sum + (session.amountInSessionCurrency(t) ?? t.amountMinor)),
        requesterCount: tips.length,
        status: statuses[e.key],
        tips: tips,
      ));
    }
    entries.sort(_rank);
    return RequestQueue(entries);
  }

  static int _rank(RequestQueueEntry a, RequestQueueEntry b) {
    if (a.active != b.active) return a.active ? -1 : 1;
    if (a.totalMinor != b.totalMinor) return b.totalMinor - a.totalMinor;
    if (a.requesterCount != b.requesterCount) {
      return b.requesterCount - a.requesterCount;
    }
    final byNewest = b.tips.first.createdAt.compareTo(a.tips.first.createdAt);
    if (byNewest != 0) return byNewest;
    return a.songId.compareTo(b.songId);
  }

  /// The `queue` argument for `setJarRequests`, exactly as the server pins
  /// it (validate.ts validateRequestsQueue): a flat songId → `{t, c, s}`
  /// map — totals in minor units, requester count, status wire ("q" queued,
  /// "p" played, "k" skipped). Capped to the top [maxWireEntries] by rank
  /// and clamped to the server's bounds so a publish is never refused. The
  /// currency is NOT sent: the server stamps the jar's own onto
  /// `requestsLive` — requests are always denominated in it.
  Map<String, dynamic> toWirePayload() => {
        for (final entry in entries.take(maxWireEntries))
          entry.songId: {
            't': entry.totalMinor.clamp(0, _maxWireTotalMinor),
            'c': entry.requesterCount.clamp(0, _maxWireCount),
            's': entry.status ?? 'q',
          },
      };
}
