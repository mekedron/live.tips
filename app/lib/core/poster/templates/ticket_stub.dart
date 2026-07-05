import 'dart:math' as math;

import 'package:pdf/widgets.dart' as pw;

import '../poster_kit.dart';

/// A bordered rectangle split by a dashed "perforation"; the narrow
/// counterfoil strip carries the artist name rotated 90°.
pw.Widget buildTicketStub(PosterData data) {
  final w = data.format.width;
  final h = data.format.height;

  return posterFullBleed(
    data,
    padding: w * 0.06,
    child: pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(
            flex: 7,
            child: pw.Padding(
              padding: pw.EdgeInsets.all(w * 0.05),
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    posterHeadline(data.strings.headline, fontSize: w * 0.058),
                    pw.SizedBox(height: h * 0.04),
                    posterQr(data, size: w * 0.26),
                    pw.SizedBox(height: h * 0.03),
                    posterSubline(data.strings.subline, fontSize: w * 0.02),
                  ],
                ),
              ),
            ),
          ),
          pw.Container(
            width: 0,
            margin: pw.EdgeInsets.symmetric(vertical: h * 0.03),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(width: 1.4, style: pw.BorderStyle.dashed),
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Center(
              child: pw.Transform.rotateBox(
                angle: math.pi / 2,
                child: pw.Text(
                  data.artistName,
                  style: pw.TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
