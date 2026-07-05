import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../poster_kit.dart';

/// The one deliberately dark theme — full-bleed black background with gold
/// rules/text, mirroring this app's own on-stage brand identity
/// (core/theme.dart's `kGold`/`kStageBlack`). The QR still sits on its
/// mandatory white card, with a thin gold ring behind it suggesting a
/// spotlight.
pw.Widget buildGoldOnBlack(PosterData data) {
  final w = data.format.width;
  final h = data.format.height;

  return posterFullBleed(
    data,
    background: kPosterStageBlack,
    padding: w * 0.09,
    child: pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          posterHeadline(
            data.strings.headline,
            color: kPosterGold,
            fontSize: w * 0.075,
          ),
          pw.SizedBox(height: h * 0.05),
          pw.Container(
            width: w * 0.52,
            height: w * 0.52,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: kPosterGold, width: 2),
            ),
            child: posterQr(data, size: w * 0.24),
          ),
          pw.SizedBox(height: h * 0.05),
          pw.Container(width: w * 0.16, height: 1.2, color: kPosterGold),
          pw.SizedBox(height: h * 0.025),
          pw.Text(
            data.artistName,
            style: pw.TextStyle(
              fontSize: w * 0.032,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: h * 0.012),
          posterSubline(data.strings.subline, color: kPosterGold, fontSize: w * 0.026),
        ],
      ),
    ),
  );
}
