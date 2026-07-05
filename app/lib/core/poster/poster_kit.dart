import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'poster_strings.dart';

/// This app's brand colors (core/theme.dart's `kGold`/`kStageBlack`),
/// redefined here as [PdfColor] constants — templates in this module never
/// import `package:flutter/material.dart`, keeping the PDF layer free of
/// the Flutter widget-tree dependency.
const kPosterGold = PdfColor.fromInt(0xFFFFC24D);
const kPosterStageBlack = PdfColor.fromInt(0xFF0D0E12);

/// Everything a poster template needs to render one page.
class PosterData {
  const PosterData({
    required this.qrData,
    required this.artistName,
    required this.strings,
    required this.format,
  });

  /// The tip-link URL encoded in the QR.
  final String qrData;
  final String artistName;
  final PosterStrings strings;
  final PdfPageFormat format;
}

typedef PosterTemplateBuilder = pw.Widget Function(PosterData data);

/// Paints the full page in [background], then insets [child] by [padding].
/// Full-bleed themes pass a small (or zero) padding to reach the paper
/// edge; bordered themes pass a larger one to frame their content.
pw.Widget posterFullBleed(
  PosterData data, {
  required pw.Widget child,
  PdfColor background = PdfColors.white,
  double padding = 32,
}) {
  return pw.Container(
    width: data.format.width,
    height: data.format.height,
    color: background,
    padding: pw.EdgeInsets.all(padding),
    child: child,
  );
}

/// The QR block — always on its own white card regardless of the theme's
/// background (mirrors `QrBlock` in `widgets/qr_card.dart`: "white-backed
/// — scannable from a dark screen"). Uses the `quartile` error-correction
/// level (~25% recoverable) rather than the barcode package's `low`
/// default (~7%) — a poster is taped up and viewed from a distance, worth
/// the extra QR density for resilience against wear/glare/dirt.
pw.Widget posterQr(
  PosterData data, {
  double size = 220,
  PdfColor cardColor = PdfColors.white,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: cardColor,
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.BarcodeWidget(
      data: data.qrData,
      barcode: pw.Barcode.qrCode(
        errorCorrectLevel: pw.BarcodeQRCorrectionLevel.quartile,
      ),
      width: size,
      height: size,
      drawText: false,
    ),
  );
}

/// The consistent three-tier type scale every template pulls from —
/// headline/subline/footer sizing stays uniform across all themes even as
/// color/position/rotation differ per template.
pw.Widget posterHeadline(
  String text, {
  PdfColor color = PdfColors.black,
  double fontSize = 36,
  pw.TextAlign align = pw.TextAlign.center,
}) => pw.Text(
  text,
  textAlign: align,
  style: pw.TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: pw.FontWeight.bold,
  ),
);

pw.Widget posterSubline(
  String text, {
  PdfColor color = PdfColors.black,
  double fontSize = 16,
  pw.TextAlign align = pw.TextAlign.center,
}) => pw.Text(
  text,
  textAlign: align,
  style: pw.TextStyle(color: color, fontSize: fontSize),
);

pw.Widget posterFooter(
  String text, {
  PdfColor color = PdfColors.grey700,
  double fontSize = 10,
  pw.TextAlign align = pw.TextAlign.center,
}) => pw.Text(
  text,
  textAlign: align,
  style: pw.TextStyle(color: color, fontSize: fontSize),
);

/// A row of evenly-spaced circles — the repeated-dot motif shared by the
/// Marquee Bold (bulb lights) and Ticket Stub (perforation) templates.
pw.Widget posterDotRow({
  required int count,
  double dotSize = 8,
  double spacing = 14,
  PdfColor color = PdfColors.black,
  bool filled = true,
}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
    children: List.generate(count, (_) {
      return pw.Container(
        width: dotSize,
        height: dotSize,
        margin: pw.EdgeInsets.symmetric(horizontal: spacing / 2),
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          color: filled ? color : PdfColors.white,
          border: filled ? null : pw.Border.all(color: color, width: 1),
        ),
      );
    }),
  );
}
