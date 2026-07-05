import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../domain/poster.dart';
import '../../domain/tip_jar.dart';
import 'poster_fonts.dart';
import 'poster_kit.dart';
import 'poster_paper.dart';
import 'poster_strings.dart';
import 'poster_templates.dart';

/// Renders a print-ready poster PDF for [jar]'s tip link.
///
/// [displayName], when non-empty, overrides [TipJar.displayName] on the
/// poster — e.g. a shorter or friendlier name than the one used for the
/// payment link. [headline]/[subline]/[footer], when non-empty, override
/// the chosen [language]'s own caption text (poster_strings.dart).
Future<Uint8List> buildPosterPdf({
  required TipJar jar,
  required PosterTheme theme,
  required PosterLanguage language,
  required PosterPaperSize paperSize,
  String displayName = '',
  String headline = '',
  String subline = '',
  String footer = '',
}) async {
  final fonts = await loadPosterFonts();
  final format = posterPageFormats[paperSize]!;
  final languageStrings = kPosterStrings[language]!;
  final data = PosterData(
    qrData: jar.url,
    artistName: displayName.trim().isEmpty
        ? jar.displayName
        : displayName.trim(),
    strings: PosterStrings(
      headline: headline.trim().isEmpty
          ? languageStrings.headline
          : headline.trim(),
      subline: subline.trim().isEmpty
          ? languageStrings.subline
          : subline.trim(),
      footer: footer.trim().isEmpty ? languageStrings.footer : footer.trim(),
    ),
    format: format,
  );

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
  );
  doc.addPage(
    pw.Page(
      pageFormat: format,
      margin: pw.EdgeInsets.zero,
      build: (context) => posterTemplates[theme]!(data),
    ),
  );
  return doc.save();
}
