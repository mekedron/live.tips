/// The performer's print-poster preferences, persisted inside [AppSettings].
///
/// Same `wire`/`label`/`fromWire` shape as the stage-settings enums
/// (stage_settings.dart) — `wire` is the stable persisted value, tolerant
/// decoding falls back to a default so an old build never chokes on a
/// newer stored value.
library;

/// A visual layout for the printable QR poster.
enum PosterTheme {
  /// White background, thin inset rule frame, centered headline/QR/name.
  /// Lightest ink, print-shop-safe — the default.
  minimalFrame('minimal-frame', 'Minimal Frame'),

  /// Bordered rectangle split by a dashed "perforation"; a narrow
  /// counterfoil strip carries the artist name rotated 90°.
  ticketStub('ticket-stub', 'Ticket Stub'),

  /// Heavy border with rows of small "bulb" circles along the top and
  /// bottom, large bold caps headline.
  marqueeBold('marquee-bold', 'Marquee Bold'),

  /// Full-bleed dark background with gold rules/text — this app's own
  /// brand identity, the one deliberately dark template.
  goldOnBlack('gold-on-black', 'Gold on Black'),

  /// Masthead-style full-width headline over a thick+thin rule, QR and a
  /// short line of text split into two columns below.
  newspaperColumn('newspaper-column', 'Newspaper Column'),

  /// Soft-cornered flat-color card holding headline+QR, with a smaller
  /// overlapping card for the artist name.
  roundedCard('rounded-card', 'Rounded Card'),

  /// A bold ring around the QR, badge-style, with headline/subline
  /// centered above and below.
  centerMedallion('center-medallion', 'Center Medallion'),

  /// Page split into a solid-color block (reversed headline) and a plain
  /// white block (QR + subline + footer).
  splitDuotone('split-duotone', 'Split Duotone');

  const PosterTheme(this.wire, this.label);
  final String wire;
  final String label;

  static PosterTheme fromWire(
    String? wire, {
    PosterTheme fallback = PosterTheme.minimalFrame,
  }) => values.firstWhere((v) => v.wire == wire, orElse: () => fallback);
}

/// A paper size to print the poster on — the ISO 216 A-series plus US
/// Letter.
enum PosterPaperSize {
  a2('a2', 'A2 · 420 × 594 mm'),
  a3('a3', 'A3 · 297 × 420 mm'),
  a4('a4', 'A4 · 210 × 297 mm'),
  a5('a5', 'A5 · 148 × 210 mm'),
  a6('a6', 'A6 · 105 × 148 mm'),
  letter('letter', 'US Letter · 8.5 × 11 in');

  const PosterPaperSize(this.wire, this.label);
  final String wire;
  final String label;

  static PosterPaperSize fromWire(
    String? wire, {
    PosterPaperSize fallback = PosterPaperSize.a4,
  }) => values.firstWhere((v) => v.wire == wire, orElse: () => fallback);
}

/// The performer's last-picked poster options — reprints (a new venue, a
/// worn-out copy) stay consistent by default.
class PosterSettings {
  const PosterSettings({
    this.theme = PosterTheme.minimalFrame,
    this.paperSize = PosterPaperSize.a4,
    this.displayName = '',
    this.headline = '',
    this.subline = '',
    this.footer = '',
  });

  final PosterTheme theme;
  final PosterPaperSize paperSize;

  /// Overrides the jar's own display name on the printed poster — e.g. a
  /// shorter or friendlier name than the one used for the payment link.
  /// Empty (the default) prints the jar's own name as-is.
  final String displayName;

  /// Overrides for the poster's headline/subline/footer captions — each
  /// empty by default, meaning "use the default wording"
  /// ([kDefaultPosterStrings] in poster_strings.dart).
  final String headline;
  final String subline;
  final String footer;

  PosterSettings copyWith({
    PosterTheme? theme,
    PosterPaperSize? paperSize,
    String? displayName,
    String? headline,
    String? subline,
    String? footer,
  }) => PosterSettings(
    theme: theme ?? this.theme,
    paperSize: paperSize ?? this.paperSize,
    displayName: displayName ?? this.displayName,
    headline: headline ?? this.headline,
    subline: subline ?? this.subline,
    footer: footer ?? this.footer,
  );

  Map<String, dynamic> toJson() => {
    'theme': theme.wire,
    'paperSize': paperSize.wire,
    'displayName': displayName,
    'headline': headline,
    'subline': subline,
    'footer': footer,
  };

  factory PosterSettings.fromJson(Map<String, dynamic> json) =>
      PosterSettings(
        theme: PosterTheme.fromWire(json['theme'] as String?),
        paperSize: PosterPaperSize.fromWire(json['paperSize'] as String?),
        displayName: json['displayName'] as String? ?? '',
        headline: json['headline'] as String? ?? '',
        subline: json['subline'] as String? ?? '',
        footer: json['footer'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is PosterSettings &&
      other.theme == theme &&
      other.paperSize == paperSize &&
      other.displayName == displayName &&
      other.headline == headline &&
      other.subline == subline &&
      other.footer == footer;

  @override
  int get hashCode =>
      Object.hash(theme, paperSize, displayName, headline, subline, footer);
}
