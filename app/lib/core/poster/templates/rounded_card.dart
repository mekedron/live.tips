import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../poster_kit.dart';

/// A soft sky-blue pastel accent — flat color only, no gradient/shadow
/// (box-shadows render muddy in print).
const _cardAccent = PdfColor.fromInt(0xFFDCEAF7);

/// Two stacked soft-cornered cards (reusing this app's own established
/// `BorderRadius.circular(20)` from core/theme.dart): a larger flat-color
/// card holding headline+QR, and a smaller white card below it for the
/// artist name/subline.
pw.Widget buildRoundedCard(PosterData data) {
  final w = data.format.width;
  final h = data.format.height;

  return posterFullBleed(
    data,
    padding: w * 0.08,
    child: pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
              color: _cardAccent,
              borderRadius: pw.BorderRadius.circular(28),
            ),
            padding: pw.EdgeInsets.all(w * 0.06),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                posterHeadline(data.strings.headline, fontSize: w * 0.065),
                pw.SizedBox(height: h * 0.045),
                posterQr(data, size: w * 0.3),
              ],
            ),
          ),
          pw.SizedBox(height: h * 0.03),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
              border: pw.Border.all(color: _cardAccent, width: 2.5),
            ),
            padding: pw.EdgeInsets.symmetric(
              horizontal: w * 0.07,
              vertical: h * 0.02,
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  data.artistName,
                  style: pw.TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: h * 0.008),
                posterSubline(data.strings.subline, fontSize: w * 0.022),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
