import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../poster_kit.dart';

/// A deep teal accent — billboard-style flat color block, distinct from
/// every line/border-based theme and from Gold on Black's warm brand tone.
const _duotoneAccent = PdfColor.fromInt(0xFF1B4B5A);

/// Page split ~55/45: a solid-color block with a reversed light headline
/// on top, a plain white block with QR + subline + footer below. Two
/// independent full-width bands, so this builds its own page frame rather
/// than going through [posterFullBleed] (which assumes one background).
pw.Widget buildSplitDuotone(PosterData data) {
  final w = data.format.width;
  final h = data.format.height;

  return pw.SizedBox(
    width: w,
    height: h,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          flex: 55,
          child: pw.Container(
            color: _duotoneAccent,
            padding: pw.EdgeInsets.all(w * 0.08),
            alignment: pw.Alignment.center,
            child: posterHeadline(
              data.strings.headline,
              color: PdfColors.white,
              fontSize: w * 0.072,
            ),
          ),
        ),
        pw.Expanded(
          flex: 45,
          child: pw.Container(
            color: PdfColors.white,
            padding: pw.EdgeInsets.all(w * 0.08),
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                posterQr(data, size: w * 0.26),
                pw.SizedBox(height: h * 0.025),
                pw.Text(
                  data.artistName,
                  style: pw.TextStyle(
                    fontSize: w * 0.03,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: h * 0.012),
                posterSubline(data.strings.subline, fontSize: w * 0.022),
                pw.SizedBox(height: h * 0.012),
                posterFooter(data.strings.footer),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
