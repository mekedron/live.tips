import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// The Unicode font pair (Latin Extended + Cyrillic) embedded in every
/// poster PDF. `package:pdf`'s built-in core fonts are WinAnsi-only and
/// can't render Russian/Polish captions — bundled instead of fetched from
/// the Google Fonts API at runtime, so generation stays fully offline.
///
/// These must be genuinely static per-weight TTFs, not a variable font:
/// `package:pdf`'s TTF parser has no `fvar`/`gvar` support, so embedding a
/// variable font as both "regular" and "bold" would silently render both
/// at the same weight.
class PosterFontSet {
  const PosterFontSet({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}

Future<PosterFontSet>? _cached;

/// Loads the bundled Noto Sans TTFs once; concurrent callers await the
/// same in-flight load.
Future<PosterFontSet> loadPosterFonts() => _cached ??= _load();

Future<PosterFontSet> _load() async {
  final regularData = await rootBundle.load(
    'assets/fonts/NotoSans-Regular.ttf',
  );
  final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
  return PosterFontSet(
    regular: pw.Font.ttf(regularData),
    bold: pw.Font.ttf(boldData),
  );
}
