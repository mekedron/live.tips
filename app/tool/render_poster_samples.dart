// Dev-only visual QA tool — NOT part of the app bundle.
//
// Renders every poster theme (currently at one caption language each, plus
// a Russian pass to catch Cyrillic/font regressions) to a scratch folder as
// plain PDFs, so they can be rasterized and eyeballed without running the
// full Flutter app:
//
//   dart run tool/render_poster_samples.dart
//   qlmanage -t -s 900 -o /tmp/poster-samples /tmp/poster-samples/*.pdf
//
// Runs via plain `dart run` (no Flutter engine/widget test binding needed)
// — fonts are loaded via dart:io instead of rootBundle, everything else is
// the same core/poster code the real app uses.
import 'dart:io';

import 'package:live_tips/core/poster/poster_kit.dart';
import 'package:live_tips/core/poster/poster_paper.dart';
import 'package:live_tips/core/poster/poster_strings.dart';
import 'package:live_tips/core/poster/poster_templates.dart';
import 'package:live_tips/domain/poster.dart';
import 'package:pdf/widgets.dart' as pw;

const _sampleJarUrl = 'https://buy.stripe.com/test_sample_link';
const _sampleArtistName = 'The Midnight Foxes';

Future<void> main(List<String> args) async {
  final outDir = Directory(
    args.isNotEmpty ? args[0] : '/tmp/poster-samples',
  )..createSync(recursive: true);

  final regular = pw.Font.ttf(
    (await File('assets/fonts/NotoSans-Regular.ttf').readAsBytes())
        .buffer
        .asByteData(),
  );
  final bold = pw.Font.ttf(
    (await File('assets/fonts/NotoSans-Bold.ttf').readAsBytes())
        .buffer
        .asByteData(),
  );

  for (final entry in posterTemplates.entries) {
    for (final sample in _captionSamples.entries) {
      final data = PosterData(
        qrData: _sampleJarUrl,
        artistName: _sampleArtistName,
        strings: sample.value,
        format: posterPageFormats[PosterPaperSize.a4]!,
      );
      final doc = pw.Document(
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
      );
      doc.addPage(
        pw.Page(
          pageFormat: data.format,
          margin: pw.EdgeInsets.zero,
          build: (context) => entry.value(data),
        ),
      );
      final file = File(
        '${outDir.path}/${entry.key.wire}-${sample.key}.pdf',
      );
      await file.writeAsBytes(await doc.save());
      stdout.writeln('wrote ${file.path}');
    }
  }
}

/// Two caption passes per theme: the default English wording, plus a
/// Russian one to catch Cyrillic/font regressions. Captions are plain text
/// now (no per-language table), so these live right here in the QA tool.
const Map<String, PosterStrings> _captionSamples = {
  'en': kDefaultPosterStrings,
  'ru': PosterStrings(
    headline: 'Отсканируйте для чаевых',
    subline: 'Поддержите выступление',
    footer: 'Спасибо за чаевые!',
  ),
};
