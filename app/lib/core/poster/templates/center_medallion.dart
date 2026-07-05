import 'package:pdf/widgets.dart' as pw;

import '../poster_kit.dart';

/// A bold ring around the QR, badge-style, with the headline/subline
/// centered above and below. Straight (not curved-baseline) text — `pw`
/// has no baseline-following text primitive, so curved text is left as a
/// future stretch rather than faked with manual per-glyph rotation.
pw.Widget buildCenterMedallion(PosterData data) {
  final w = data.format.width;
  final h = data.format.height;

  return posterFullBleed(
    data,
    padding: w * 0.09,
    child: pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          posterHeadline(data.strings.headline, fontSize: w * 0.055),
          pw.SizedBox(height: h * 0.05),
          pw.Container(
            width: w * 0.52,
            height: w * 0.52,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(width: 3),
            ),
            child: posterQr(data, size: w * 0.24),
          ),
          pw.SizedBox(height: h * 0.05),
          pw.Text(
            data.artistName,
            style: pw.TextStyle(
              fontSize: w * 0.032,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: h * 0.012),
          posterSubline(data.strings.subline, fontSize: w * 0.024),
        ],
      ),
    ),
  );
}
