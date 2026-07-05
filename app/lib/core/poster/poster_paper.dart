import 'package:pdf/pdf.dart';

import '../../domain/poster.dart';

/// Physical dimensions for each [PosterPaperSize]. Margins are zero here —
/// insetting the content is `poster_kit.dart`'s job ([posterFullBleed]),
/// so full-bleed themes can paint all the way to the paper edge while
/// bordered themes just use a bigger padding.
///
/// `PdfPageFormat.a2` doesn't exist in `package:pdf` (only a3/a4/a5/a6/
/// letter/legal ship as constants) — defined here from the ISO 216 spec.
const Map<PosterPaperSize, PdfPageFormat> posterPageFormats = {
  PosterPaperSize.a2: PdfPageFormat(
    420 * PdfPageFormat.mm,
    594 * PdfPageFormat.mm,
  ),
  PosterPaperSize.a3: PdfPageFormat(
    297 * PdfPageFormat.mm,
    420 * PdfPageFormat.mm,
  ),
  PosterPaperSize.a4: PdfPageFormat(
    210 * PdfPageFormat.mm,
    297 * PdfPageFormat.mm,
  ),
  PosterPaperSize.letter: PdfPageFormat(
    8.5 * PdfPageFormat.inch,
    11.0 * PdfPageFormat.inch,
  ),
};

/// `PdfPreview`'s own paper-format picker wants `Map<String, PdfPageFormat>`
/// keyed by display label.
final Map<String, PdfPageFormat> posterPickerFormats = {
  for (final entry in posterPageFormats.entries) entry.key.label: entry.value,
};

/// Reverse lookup for `PdfPreview`'s `onPageFormatChanged` callback, so the
/// user's paper-size choice can be persisted back as a [PosterPaperSize].
PosterPaperSize? posterPaperSizeForFormat(PdfPageFormat format) {
  for (final entry in posterPageFormats.entries) {
    if (entry.value == format) return entry.key;
  }
  return null;
}
