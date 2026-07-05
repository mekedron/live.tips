import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../poster_kit.dart';

/// White background, thin inset rule frame, centered headline/QR/name.
/// Lightest ink of all 8 themes, print-shop-safe — the default.
pw.Widget buildMinimalFrame(PosterData data) {
  final w = data.format.width;
  final h = data.format.height;

  return posterFullBleed(
    data,
    padding: w * 0.07,
    child: pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
      ),
      padding: pw.EdgeInsets.all(w * 0.06),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            posterHeadline(data.strings.headline, fontSize: w * 0.075),
            pw.SizedBox(height: h * 0.05),
            posterQr(data, size: w * 0.34),
            pw.SizedBox(height: h * 0.05),
            pw.Container(width: w * 0.16, height: 1.2, color: PdfColors.black),
            pw.SizedBox(height: h * 0.025),
            pw.Text(
              data.artistName,
              style: pw.TextStyle(fontSize: w * 0.032, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: h * 0.012),
            posterSubline(data.strings.subline, fontSize: w * 0.026),
          ],
        ),
      ),
    ),
  );
}
