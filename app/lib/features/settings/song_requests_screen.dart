import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../data/stripe/stripe_client.dart';
import '../../data/stripe/stripe_requests.dart';
import '../../data/stripe/stripe_song_link_sync.dart';
import '../../domain/song_request_settings.dart';
import '../../domain/tip_method.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/enum_labels.dart';
import '../../state/providers.dart';
import '../../widgets/goal_editor.dart';
import '../../widgets/lt_ui.dart';

/// Edits the band's song-request setup (issue #64): the master toggle, the
/// default price, which of the band's payment methods fans may request with,
/// and the hand-typed song library. Everything persists on [BandSettings]
/// through updateBand — the source of truth, synced with the profile — and
/// each save is then published to the relay jar best-effort so the fan page
/// follows; a failed publish warns but never blocks the local save.
class SongRequestsScreen extends ConsumerStatefulWidget {
  const SongRequestsScreen({super.key});

  @override
  ConsumerState<SongRequestsScreen> createState() =>
      _SongRequestsScreenState();
}

class _SongRequestsScreenState extends ConsumerState<SongRequestsScreen> {
  /// Persists [next] locally, mints/retires Stripe song links to match when
  /// this device can, then pushes the fresh config to the jar — so the
  /// publish carries the new `stripeUrl`s in the same save.
  Future<void> _apply(SongRequestSettings next) async {
    final band = ref.read(appStateProvider).band;
    final previousSongs = band.songRequests.songs;
    await ref
        .read(appStateProvider.notifier)
        .updateBand(band.copyWith(songRequests: next));
    final synced = await _syncStripeLinks(previousSongs, next);
    await _publish(synced ?? next);
  }

  /// Makes the band's Stripe payment links match the library — only when the
  /// feature is on, card is ticked, and THIS device holds the key (minting is
  /// a direct Stripe call with the artist's own key; a device without one —
  /// cloud key custody, a linked follower — skips it, and the card checkbox
  /// row says so). The diff itself lives in [StripeSongLinkSync]; this is
  /// the glue: persist what landed, surface what didn't, once.
  Future<SongRequestSettings?> _syncStripeLinks(
    List<SongEntry> previousSongs,
    SongRequestSettings next,
  ) async {
    final app = ref.read(appStateProvider);
    final apiKey = app.demo ? null : app.apiKey;
    if (apiKey == null ||
        !next.enabled ||
        !next.methods.contains(TipMethod.stripe.wire)) {
      return null;
    }
    // Links are priced in the currency the editor showed the artist —
    // the number they typed must be the number the checkout charges.
    final currency = app.relayJar?.currency ?? app.currency;
    // Own client, closed when done: never borrow stripeRequestsProvider's —
    // a provider rebuild would close it under an in-flight mint.
    final client = StripeClient(apiKey);
    SongLinkSyncOutcome outcome;
    try {
      outcome = await StripeSongLinkSync(StripeRequests(client)).sync(
        previousSongs: previousSongs,
        next: next,
        currency: currency,
      );
    } finally {
      client.close();
    }

    var result = next;
    if (!listEquals(outcome.songs, next.songs)) {
      result = next.copyWith(songs: outcome.songs);
      final band = ref.read(appStateProvider).band;
      await ref
          .read(appStateProvider.notifier)
          .updateBand(band.copyWith(songRequests: result));
    }
    if (mounted && (outcome.capReached || outcome.failures > 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.s.t(outcome.capReached
              ? 'settings.requests.stripe_limit_reached'
              : 'settings.requests.stripe_sync_failed')),
        ),
      );
    }
    return result;
  }

  /// Best-effort copy to the fan page — only when a relay jar exists to
  /// carry it. The band doc already holds the truth, so a failure costs a
  /// stale fan page, not data; the next save retries with the full config.
  Future<void> _publish(SongRequestSettings requests) async {
    final app = ref.read(appStateProvider);
    final jar = app.relayJar;
    final secret = app.relaySecret;
    if (jar == null || secret == null) return;
    try {
      await ref.read(relayClientProvider).setJarRequests(
            jar: jar,
            secret: secret,
            config: requestsConfigWire(requests, jarCurrency: jar.currency),
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.t('settings.requests.publish_failed'))),
      );
    }
  }

  Future<void> _editDefaultPrice(
    SongRequestSettings requests,
    String currency,
  ) async {
    final picked = await showGoalEditorSheet(
      context,
      initialMinor: requests.defaultPriceMinor,
      currency: currency,
      title: context.s.t('settings.requests.default_price_sheet_title'),
    );
    if (picked == null || picked <= 0) return;
    await _apply(requests.copyWith(defaultPriceMinor: picked));
  }

  Future<void> _toggleMethod(
    SongRequestSettings requests,
    TipMethod method,
    bool ticked,
  ) {
    final methods = [
      for (final m in requests.methods)
        if (m != method.wire) m,
      if (ticked) method.wire,
    ];
    return _apply(requests.copyWith(methods: methods));
  }

  Future<void> _addSong(SongRequestSettings requests, String currency) async {
    final entry = await showSongEditorSheet(
      context,
      currency: currency,
      defaultPriceMinor: requests.defaultPriceMinor,
    );
    if (entry == null) return;
    // Re-read the cap against current state — the sheet was open a while.
    if (requests.songs.length >= SongRequestSettings.maxSongs) return;
    await _apply(requests.copyWith(songs: [...requests.songs, entry]));
  }

  Future<void> _editSong(
    SongRequestSettings requests,
    SongEntry song,
    String currency,
  ) async {
    final edited = await showSongEditorSheet(
      context,
      existing: song,
      currency: currency,
      defaultPriceMinor: requests.defaultPriceMinor,
    );
    if (edited == null) return;
    await _apply(requests.copyWith(songs: [
      for (final s in requests.songs)
        if (s.id == song.id) edited else s,
    ]));
  }

  Future<void> _deleteSong(SongRequestSettings requests, SongEntry song) =>
      _apply(requests.copyWith(songs: [
        for (final s in requests.songs)
          if (s.id != song.id) s,
      ]));

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final requests =
        ref.watch(appStateProvider.select((state) => state.band.songRequests));
    final app = ref.watch(appStateProvider);
    final jar = app.relayJar;
    final currency = jar?.currency ?? app.currency;

    // Only what the jar actually offers appears here — a checkbox for a
    // method the fan page can't show would be a promise nobody keeps.
    final offered = <TipMethod>[
      if (app.tipJar != null) TipMethod.stripe,
      if (jar?.hasRevolut ?? false) TipMethod.revolut,
      if (jar?.hasMobilePay ?? false) TipMethod.mobilepay,
      if (jar?.hasMonzo ?? false) TipMethod.monzo,
    ];
    // Ticked, offered, currency-eligible relay methods — the set the fan
    // page will really show, and the trigger for the unverified warning.
    final tickedRelay = [
      for (final m in offered)
        if (m != TipMethod.stripe &&
            requests.methods.contains(m.wire) &&
            requestMethodEligible(m.wire, currency))
          m,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings.requests.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                s.t('settings.requests.intro'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              LtRowGroup(
                children: [
                  LtRow(
                    icon: Icons.queue_music_rounded,
                    title: s.t('settings.requests.enable'),
                    subtitle: s.t('settings.requests.enable_subtitle'),
                    trailing: Switch(
                      value: requests.enabled,
                      onChanged: (v) => _apply(requests.copyWith(enabled: v)),
                    ),
                  ),
                  LtRow(
                    icon: Icons.sell_rounded,
                    title: s.t('settings.requests.default_price'),
                    trailing: _ValueText(
                      formatAmount(requests.defaultPriceMinor, currency),
                    ),
                    chevron: true,
                    onTap: () => _editDefaultPrice(requests, currency),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LtRowGroup(
                header: s.t('settings.requests.methods_header'),
                children: [
                  if (offered.isEmpty)
                    LtRow(
                      icon: Icons.info_outline_rounded,
                      title: s.t('settings.requests.methods_empty'),
                    )
                  else
                    for (final method in offered)
                      _methodRow(requests, method, currency),
                ],
              ),
              if (tickedRelay.isNotEmpty) ...[
                const SizedBox(height: 14),
                // Plain words, on purpose: the app cannot see the
                // MobilePay/Revolut/Monzo ledgers, so a request paid through
                // them is the fan's claim, not a receipt.
                LtCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.visibility_outlined,
                          size: 20, color: c.onWarningContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.t('settings.requests.unverified_warning'),
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 13,
                            height: 1.45,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              LtRowGroup(
                header: s.t('settings.requests.songs_header'),
                children: [
                  for (final song in requests.songs)
                    LtRow(
                      icon: Icons.music_note_rounded,
                      title: song.title,
                      subtitle: _songSubtitle(song, currency),
                      trailing: IconButton(
                        tooltip: s.t('settings.requests.delete_song'),
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 20, color: c.danger),
                        onPressed: () => _deleteSong(requests, song),
                      ),
                      onTap: () => _editSong(requests, song, currency),
                    ),
                  if (requests.songs.length < SongRequestSettings.maxSongs)
                    LtRow(
                      icon: Icons.add_rounded,
                      iconColor: c.accent,
                      title: s.t('settings.requests.add_song'),
                      titleColor: c.accent,
                      onTap: () => _addSong(requests, currency),
                    )
                  else
                    LtRow(
                      icon: Icons.block_rounded,
                      title: s.t('settings.requests.limit_reached'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Artist · €7.50" — only what the song overrides; nothing for a plain
  /// title-only entry.
  String? _songSubtitle(SongEntry song, String currency) {
    final parts = [
      if (song.artist != null) song.artist!,
      if (song.priceMinor != null) formatAmount(song.priceMinor!, currency),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _methodRow(
    SongRequestSettings requests,
    TipMethod method,
    String currency,
  ) {
    final eligible = requestMethodEligible(method.wire, currency);
    // Card request links are minted right here, with the artist's own key —
    // a device that doesn't hold it (cloud key custody, a linked follower)
    // can tick the box but can't create the links, and must say so.
    final needsKey = method == TipMethod.stripe &&
        ref.read(appStateProvider).apiKey == null;
    return LtRow(
      icon: method.icon,
      title: method.l10nLabel(context),
      // Say WHY a method the band offers can't take requests: fixed-price
      // request links only exist for the currency these services settle in.
      subtitle: !eligible
          ? context.s.t(
              'settings.requests.currency_excluded_${method.wire}',
            )
          : needsKey
              ? context.s.t('settings.requests.stripe_hint_no_key')
              : null,
      trailing: Checkbox(
        value: eligible && requests.methods.contains(method.wire),
        onChanged: eligible
            ? (v) => _toggleMethod(requests, method, v ?? false)
            : null,
      ),
    );
  }
}

/// Bottom-sheet editor for one library song — title (required, ≤60 code
/// points: the relay rejects longer rather than truncating), optional artist
/// and optional per-song price. Returns the resulting [SongEntry] (a fresh
/// id for a new song, [existing]'s id — and its Stripe link record — kept on
/// an edit), or null when dismissed.
Future<SongEntry?> showSongEditorSheet(
  BuildContext context, {
  SongEntry? existing,
  required String currency,
  required int defaultPriceMinor,
}) {
  final titleController = TextEditingController(text: existing?.title ?? '');
  final artistController = TextEditingController(text: existing?.artist ?? '');
  final priceController = TextEditingController(
    text: existing?.priceMinor == null
        ? ''
        : formatMajorPlain(existing!.priceMinor!, currency),
  );
  return showModalBottomSheet<SongEntry>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _SongEditor(
      existing: existing,
      currency: currency,
      defaultPriceMinor: defaultPriceMinor,
      titleController: titleController,
      artistController: artistController,
      priceController: priceController,
    ),
  ).whenComplete(() {
    // Dispose after the sheet's exit animation is fully done.
    Future.delayed(const Duration(seconds: 1), () {
      titleController.dispose();
      artistController.dispose();
      priceController.dispose();
    });
  });
}

class _SongEditor extends StatefulWidget {
  const _SongEditor({
    required this.existing,
    required this.currency,
    required this.defaultPriceMinor,
    required this.titleController,
    required this.artistController,
    required this.priceController,
  });

  final SongEntry? existing;
  final String currency;
  final int defaultPriceMinor;
  final TextEditingController titleController;
  final TextEditingController artistController;
  final TextEditingController priceController;

  @override
  State<_SongEditor> createState() => _SongEditorState();
}

class _SongEditorState extends State<_SongEditor> {
  String? _titleError;
  String? _priceError;

  void _save() {
    final s = context.s;
    final title = widget.titleController.text.trim();
    if (title.isEmpty) {
      setState(
          () => _titleError = s.t('settings.requests.error_title_required'));
      return;
    }
    // Code points, not graphemes — the relay's unit (see RelayClient's
    // clamp notes); an over-limit title would be refused, never shortened.
    if (title.runes.length > SongEntry.maxTitleCodePoints) {
      setState(() => _titleError = s.t('settings.requests.error_title_long'));
      return;
    }
    final rawPrice = widget.priceController.text.trim();
    int? priceMinor;
    if (rawPrice.isNotEmpty) {
      priceMinor = parseMajorToMinor(rawPrice, widget.currency);
      if (priceMinor == null) {
        setState(
            () => _priceError = s.t('settings.requests.error_price_invalid'));
        return;
      }
    }
    final artist = widget.artistController.text.trim();
    Navigator.of(context).pop(SongEntry(
      id: widget.existing?.id ?? SongEntry.mintId(),
      title: title,
      artist: artist.isEmpty ? null : artist,
      priceMinor: priceMinor,
      // The link record survives an edit untouched; whether it still matches
      // the song (title/price drift) is the minting flow's question.
      stripe: widget.existing?.stripe,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
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
          Text(
            s.t(widget.existing == null
                ? 'settings.requests.add_song'
                : 'settings.requests.edit_song'),
            style: outfitStyle(18, c.text, weight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.titleController,
            // Never autofocus inside a bottom sheet: on iPhone the keyboard
            // summoned mid-animation breaks the sheet. The artist taps it.
            decoration: InputDecoration(
              labelText: s.t('settings.requests.song_title'),
              errorText: _titleError,
              errorMaxLines: 2,
            ),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.artistController,
            decoration: InputDecoration(
              labelText: s.t('settings.requests.song_artist'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.priceController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.t('settings.requests.song_price'),
              hintText: s.t('settings.requests.song_price_hint', {
                'amount':
                    formatAmount(widget.defaultPriceMinor, widget.currency),
              }),
              suffixText: widget.currency.toUpperCase(),
              errorText: _priceError,
              errorMaxLines: 2,
            ),
            onChanged: (_) {
              if (_priceError != null) setState(() => _priceError = null);
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          LtPrimaryButton(
            label: s.t('settings.requests.save_song'),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _ValueText extends StatelessWidget {
  const _ValueText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: kFontBody,
        fontSize: 13.5,
        color: context.lt.textSecondary,
      ),
    );
  }
}
