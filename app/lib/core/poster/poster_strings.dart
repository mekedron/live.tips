/// The poster's printed caption text — three short signage phrases. All
/// three are always present; a template may simply choose not to render
/// [subline]/[footer] in a minimalist composition. Deliberately no
/// interpolation: the artist's name is a separate field on `PosterData`,
/// rendered by each template on its own.
class PosterStrings {
  const PosterStrings({
    required this.headline,
    required this.subline,
    required this.footer,
  });

  /// The primary call to action, e.g. "Scan to tip".
  final String headline;

  /// A short supporting line, e.g. "Support the show".
  final String subline;

  /// Small-print thank-you line.
  final String footer;
}

/// The wording every poster starts from. The performer types their own
/// phrasing in the customize sheet (any language they like — it's a plain
/// text field now); a field left blank falls back to the matching line
/// here.
const PosterStrings kDefaultPosterStrings = PosterStrings(
  headline: 'Scan to tip',
  subline: 'Support the show',
  footer: 'Thank you for the tip!',
);
