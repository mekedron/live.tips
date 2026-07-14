/// The band's song-request setup, persisted inside [BandSettings]: a
/// hand-typed song library, a default price, which payment methods fans may
/// request with, and the master toggle. The band doc is the source of truth
/// (it syncs with the profile and works for local accounts too); a copy is
/// published to the relay jar via the `setJarRequests` callable so the
/// server-rendered fan page can show it.
library;

import 'dart:math';

/// The record of a Stripe payment link minted for one song — product, price
/// and link ids plus the public URL. Modelled now so the schema is stable;
/// the minting flow that fills it comes later. [priceMinor] and [title] are
/// what the link was created FOR: when the song's price or title changes the
/// link is stale and must be re-minted, and this is how that is detected.
class StripeSongLink {
  const StripeSongLink({
    required this.productId,
    required this.priceId,
    required this.paymentLinkId,
    required this.url,
    required this.priceMinor,
    required this.title,
  });

  final String productId;
  final String priceId;
  final String paymentLinkId;

  /// Public `https://buy.stripe.com/…` URL — the only part the fan page needs.
  final String url;

  /// The fixed price this link charges, in minor units of the jar currency.
  final int priceMinor;

  /// The song title the link's product was named after.
  final String title;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'priceId': priceId,
        'paymentLinkId': paymentLinkId,
        'url': url,
        'priceMinor': priceMinor,
        'title': title,
      };

  /// Null for anything that isn't a complete link record — a half-written
  /// blob is a link we cannot trust, and dropping it just means the song
  /// gets a fresh one minted.
  static StripeSongLink? fromJson(Object? json) {
    if (json is! Map) return null;
    final productId = json['productId'];
    final priceId = json['priceId'];
    final paymentLinkId = json['paymentLinkId'];
    final url = json['url'];
    final priceMinor = json['priceMinor'];
    final title = json['title'];
    if (productId is! String ||
        priceId is! String ||
        paymentLinkId is! String ||
        url is! String ||
        priceMinor is! num ||
        title is! String) {
      return null;
    }
    return StripeSongLink(
      productId: productId,
      priceId: priceId,
      paymentLinkId: paymentLinkId,
      url: url,
      priceMinor: priceMinor.toInt(),
      title: title,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StripeSongLink &&
      other.productId == productId &&
      other.priceId == priceId &&
      other.paymentLinkId == paymentLinkId &&
      other.url == url &&
      other.priceMinor == priceMinor &&
      other.title == title;

  @override
  int get hashCode =>
      Object.hash(productId, priceId, paymentLinkId, url, priceMinor, title);
}

/// One song in the artist's request library.
class SongEntry {
  const SongEntry({
    required this.id,
    required this.title,
    this.artist,
    this.priceMinor,
    this.stripe,
  });

  /// App-minted stable id (see [mintId]) — what a request's Tip carries as
  /// `songId`. Pinned to [idPattern] on both sides of the wire.
  final String id;

  /// Required, at most [maxTitleCodePoints] code points (the editor enforces
  /// it; the relay rejects over-limit titles rather than truncating them).
  final String title;
  final String? artist;

  /// Per-song price override in minor units; null means the library's
  /// [SongRequestSettings.defaultPriceMinor] applies.
  final int? priceMinor;

  /// The Stripe payment link minted for this song, once one exists.
  final StripeSongLink? stripe;

  /// The shape a song id must have — shared with the pendingTips decoder,
  /// which drops any `songId` that doesn't match.
  static final RegExp idPattern = RegExp(r'^[A-Za-z0-9_-]{1,32}$');

  static const maxTitleCodePoints = 60;

  static final _rng = Random();
  static const _alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Mints a fresh id: `sng_` + creation time in base-36 + 4 random chars —
  /// unique enough for a 100-song library, and always [idPattern]-shaped.
  static String mintId({DateTime Function()? now, Random? random}) {
    final r = random ?? _rng;
    final ts = (now ?? DateTime.now)().millisecondsSinceEpoch.toRadixString(36);
    final tail = String.fromCharCodes([
      for (var i = 0; i < 4; i++)
        _alphabet.codeUnitAt(r.nextInt(_alphabet.length)),
    ]);
    return 'sng_$ts$tail';
  }

  static const _unset = Object();

  SongEntry copyWith({
    String? id,
    String? title,
    Object? artist = _unset,
    Object? priceMinor = _unset,
    Object? stripe = _unset,
  }) =>
      SongEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist == _unset ? this.artist : artist as String?,
        priceMinor:
            priceMinor == _unset ? this.priceMinor : priceMinor as int?,
        stripe: stripe == _unset ? this.stripe : stripe as StripeSongLink?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (artist != null) 'artist': artist,
        if (priceMinor != null) 'priceMinor': priceMinor,
        if (stripe != null) 'stripe': stripe!.toJson(),
      };

  /// Null for an entry with no usable id or title — a song that can neither
  /// be requested nor shown is not a song. Optional fields degrade alone:
  /// a garbled price or link record is dropped, the song stays.
  static SongEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title'];
    if (id is! String || !idPattern.hasMatch(id)) return null;
    if (title is! String || title.trim().isEmpty) return null;
    final artist = json['artist'];
    final priceMinor = json['priceMinor'];
    return SongEntry(
      id: id,
      title: title,
      artist: artist is String && artist.trim().isNotEmpty ? artist : null,
      priceMinor: priceMinor is num ? priceMinor.toInt() : null,
      stripe: StripeSongLink.fromJson(json['stripe']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SongEntry &&
      other.id == id &&
      other.title == title &&
      other.artist == artist &&
      other.priceMinor == priceMinor &&
      other.stripe == stripe;

  @override
  int get hashCode => Object.hash(id, title, artist, priceMinor, stripe);
}

/// Whether fans may request with [methodWire] on a jar priced in
/// [jarCurrency]. Stripe and Revolut take any currency; MobilePay boxes are
/// EUR-only and Monzo links GBP-only, so a jar in any other currency cannot
/// honestly offer them for a fixed-price request. Mirrored by the server —
/// it filters the published config by the same rule.
bool requestMethodEligible(String methodWire, String jarCurrency) {
  final currency = jarCurrency.toLowerCase();
  return switch (methodWire) {
    'stripe' || 'revolut' => true,
    'mobilepay' => currency == 'eur',
    'monzo' => currency == 'gbp',
    _ => false,
  };
}

/// Per-band song-request preferences. Const-default (disabled, empty
/// library) so old stored [BandSettings] blobs load unchanged.
class SongRequestSettings {
  const SongRequestSettings({
    this.enabled = false,
    this.defaultPriceMinor = 500,
    this.methods = const [],
    this.songs = const [],
  });

  /// The relay caps the library at this; the editor refuses the 101st song.
  static const maxSongs = 100;

  /// Master toggle — the fan page shows no request UI while this is off.
  final bool enabled;

  /// What a request costs unless the song overrides it (minor units of the
  /// jar currency).
  final int defaultPriceMinor;

  /// [TipMethod] wire names fans may request with, as the artist ticked them.
  /// Stored unfiltered; the currency rule ([requestMethodEligible]) is
  /// applied when the config is published, so a currency change never
  /// silently rewrites the artist's choices.
  final List<String> methods;

  final List<SongEntry> songs;

  SongRequestSettings copyWith({
    bool? enabled,
    int? defaultPriceMinor,
    List<String>? methods,
    List<SongEntry>? songs,
  }) =>
      SongRequestSettings(
        enabled: enabled ?? this.enabled,
        defaultPriceMinor: defaultPriceMinor ?? this.defaultPriceMinor,
        methods: methods ?? this.methods,
        songs: songs ?? this.songs,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'defaultPriceMinor': defaultPriceMinor,
        'methods': methods,
        'songs': [for (final song in songs) song.toJson()],
      };

  /// Tolerant like the rest of the settings tree: garbage falls back to the
  /// default, malformed songs are dropped one by one, unknown keys ignored.
  factory SongRequestSettings.fromJson(Map<String, dynamic> json) {
    final enabled = json['enabled'];
    final price = json['defaultPriceMinor'];
    final methods = json['methods'];
    final songs = json['songs'];
    return SongRequestSettings(
      enabled: enabled is bool && enabled,
      defaultPriceMinor: price is num ? price.toInt() : 500,
      methods: methods is List
          ? [
              for (final m in methods)
                if (m is String) m,
            ]
          : const [],
      songs: songs is List
          ? [for (final s in songs) ?SongEntry.fromJson(s)]
          : const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! SongRequestSettings) return false;
    if (other.enabled != enabled ||
        other.defaultPriceMinor != defaultPriceMinor ||
        other.methods.length != methods.length ||
        other.songs.length != songs.length) {
      return false;
    }
    for (var i = 0; i < methods.length; i++) {
      if (other.methods[i] != methods[i]) return false;
    }
    for (var i = 0; i < songs.length; i++) {
      if (other.songs[i] != songs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
      enabled, defaultPriceMinor, Object.hashAll(methods), songs.length);
}
