import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/song_request_settings.dart';
import 'stripe_requests.dart';

/// What one editor save did to the band's Stripe song links.
class SongLinkSyncOutcome {
  const SongLinkSyncOutcome({
    required this.songs,
    required this.failures,
    required this.capReached,
  });

  /// The library with fresh link records stamped on (and records the sync
  /// retired or could not replace cleared) — what the caller persists via
  /// updateBand, and what the jar publish then reduces to `stripeUrl`s.
  final List<SongEntry> songs;

  /// How many songs could not get — or shed — their link this pass. Non-zero
  /// is a SnackBar, not an error state: the next save diffs the library
  /// against its records again and retries exactly what is still wrong.
  final int failures;

  /// The lifetime song-link cap said no. Every further create would fail
  /// the same way, so the sync stopped asking; the songs left without a
  /// record simply take no card requests. Deserves its own message — this
  /// is not transient, and saving again will not fix it.
  final bool capReached;
}

/// Diffs the song library against its own [SongEntry.stripe] records and
/// makes Stripe match: no record → create; effective price or title drifted
/// → deactivate + create (Stripe prices are immutable, so "same link, new
/// price" does not exist as an operation — and the record's title is what
/// attribution was minted for, so a rename that should reach the stage is
/// the same surgery); song deleted → deactivate.
///
/// Per-song and non-blocking throughout: one song's failure never stops the
/// others, and a failed mint just leaves that song without a record for the
/// next save to retry. The one exception is [isCapError] — a refusal that
/// would repeat for every song, so it stops further creates (deactivations
/// still run: a stale link must not keep selling at the wrong price).
class StripeSongLinkSync {
  StripeSongLinkSync(this._requests);

  final StripeRequests _requests;

  /// The server's lifetime song-link cap refusing a create — the
  /// `failed-precondition` the stripeProxy `createSongLink` op throws once a
  /// connection tracks its 200th link (deactivated ones included). The
  /// direct Stripe path has no such cap — app-minted links live in the
  /// artist's own account, not on a connection doc — so today this only
  /// guards the proxy-backed minter cloud-custody accounts will get; the
  /// stop-creating behaviour is pinned by test now so that cut inherits it.
  static bool isCapError(Object error) =>
      error is FirebaseFunctionsException && error.code == 'failed-precondition';

  /// Brings Stripe in line with [next]. [previousSongs] is the library as it
  /// was before this save — the only witness to deletions.
  Future<SongLinkSyncOutcome> sync({
    required List<SongEntry> previousSongs,
    required SongRequestSettings next,
    required String currency,
  }) async {
    var failures = 0;
    var capReached = false;

    // Deleted songs first: their links must stop selling. Best-effort — a
    // failed deactivate leaves a live link selling a song the artist no
    // longer plays, which is worth the SnackBar, but the record is gone
    // with the song either way so there is nothing to retry from.
    final keptIds = {for (final song in next.songs) song.id};
    for (final song in previousSongs) {
      final record = song.stripe;
      if (record == null || keptIds.contains(song.id)) continue;
      try {
        await _requests.deactivateSongLink(record.paymentLinkId);
      } catch (_) {
        failures++;
      }
    }

    final songs = <SongEntry>[];
    for (final song in next.songs) {
      final record = song.stripe;
      final priceMinor = song.priceMinor ?? next.defaultPriceMinor;
      if (record != null &&
          record.priceMinor == priceMinor &&
          record.title == song.title) {
        songs.add(song); // the link still sells exactly this song
        continue;
      }

      // Stale record: retire the old link before minting — even when the
      // cap blocks the replacement, a link selling the song at the wrong
      // price (or under the wrong name) must not stay live.
      if (record != null) {
        try {
          await _requests.deactivateSongLink(record.paymentLinkId);
        } catch (_) {
          // Keep the record: the old link is still live, and forgetting it
          // would both orphan it (nothing would ever retire it) and stop
          // the poller attributing the payments it still takes.
          failures++;
          songs.add(song);
          continue;
        }
      }

      if (capReached) {
        songs.add(song.copyWith(stripe: null));
        continue;
      }
      try {
        final minted = await _requests.createSongLink(
          songId: song.id,
          title: song.title,
          priceMinor: priceMinor,
          currency: currency,
        );
        songs.add(song.copyWith(stripe: minted));
      } catch (e) {
        if (isCapError(e)) {
          capReached = true;
        } else {
          failures++;
        }
        songs.add(song.copyWith(stripe: null));
      }
    }

    return SongLinkSyncOutcome(
      songs: songs,
      failures: failures,
      capReached: capReached,
    );
  }
}
