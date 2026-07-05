import 'package:pdf/widgets.dart' as pw;

import '../poster_kit.dart';

/// Heavy border frame evoking a theater marquee, with rows of small
/// "bulb" circles along the top and bottom edges and a large bold caps
/// headline.
pw.Widget buildMarqueeBold(PosterData data) {
  final w = data.format.width;
  final h = data.format.height;
  const dotCount = 9;

  return posterFullBleed(
    data,
    padding: w * 0.05,
    child: pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 5)),
      padding: pw.EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.035),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          posterDotRow(count: dotCount, dotSize: w * 0.02),
          pw.Expanded(
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  posterHeadline(
                    data.strings.headline.toUpperCase(),
                    fontSize: w * 0.08,
                  ),
                  pw.SizedBox(height: h * 0.05),
                  posterQr(data, size: w * 0.3),
                  pw.SizedBox(height: h * 0.04),
                  pw.Text(
                    data.artistName,
                    style: pw.TextStyle(
                      fontSize: w * 0.03,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: h * 0.01),
                  posterSubline(data.strings.subline, fontSize: w * 0.024),
                ],
              ),
            ),
          ),
          posterDotRow(count: dotCount, dotSize: w * 0.02),
        ],
      ),
    ),
  );
}
