import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../poster_kit.dart';

/// Masthead-style full-width headline over a thick+thin double rule, body
/// split into two columns: QR on one side, a short line of text on the
/// other. Ink-light, editorial feel.
pw.Widget buildNewspaperColumn(PosterData data) {
  final w = data.format.width;
  final h = data.format.height;

  return posterFullBleed(
    data,
    padding: w * 0.08,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        posterHeadline(data.strings.headline, fontSize: w * 0.068),
        pw.SizedBox(height: h * 0.018),
        pw.Container(height: 3, color: PdfColors.black),
        pw.SizedBox(height: 2),
        pw.Container(height: 0.75, color: PdfColors.black),
        pw.SizedBox(height: h * 0.06),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Center(child: posterQr(data, size: w * 0.3)),
            ),
            pw.Container(width: 1, height: h * 0.26, color: PdfColors.grey400),
            pw.Expanded(
              child: pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: w * 0.045),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      data.artistName,
                      style: pw.TextStyle(
                        fontSize: w * 0.034,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: h * 0.018),
                    posterSubline(
                      data.strings.subline,
                      align: pw.TextAlign.left,
                      fontSize: w * 0.024,
                    ),
                    pw.SizedBox(height: h * 0.024),
                    posterFooter(data.strings.footer, align: pw.TextAlign.left),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.Spacer(),
      ],
    ),
  );
}
