import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/poster/poster_document.dart';
import 'package:live_tips/domain/poster.dart';
import 'package:live_tips/domain/tip_jar.dart';

const _pdfMagic = [0x25, 0x50, 0x44, 0x46]; // "%PDF"

const _jar = TipJar(
  productId: 'prod_test',
  priceId: 'price_test',
  paymentLinkId: 'plink_test',
  url: 'https://buy.stripe.com/test_poster_doc',
  currency: 'usd',
  displayName: 'The Midnight Foxes',
  livemode: false,
);

void main() {
  // rootBundle.load (used to embed the poster fonts) needs the test
  // asset-loading shim, even outside a testWidgets tree.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildPosterPdf', () {
    for (final theme in PosterTheme.values) {
      for (final paperSize in PosterPaperSize.values) {
        test('builds a valid PDF for ${theme.wire} on ${paperSize.wire}', () async {
          final bytes = await buildPosterPdf(
            jar: _jar,
            theme: theme,
            language: PosterLanguage.english,
            paperSize: paperSize,
          );
          expect(bytes, isNotEmpty);
          expect(bytes.sublist(0, 4), _pdfMagic);
        });
      }
    }

    for (final language in PosterLanguage.values) {
      test('builds a valid PDF captioned in ${language.wire}', () async {
        final bytes = await buildPosterPdf(
          jar: _jar,
          theme: PosterTheme.minimalFrame,
          language: language,
          paperSize: PosterPaperSize.a4,
        );
        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 4), _pdfMagic);
      });
    }

    test('a blank displayName override still builds a valid PDF', () async {
      // Not byte-compared against the no-override case: package:pdf embeds
      // a /CreationDate timestamp, so two separate builds are never
      // byte-identical even with identical visible content.
      final bytes = await buildPosterPdf(
        jar: _jar,
        theme: PosterTheme.minimalFrame,
        language: PosterLanguage.english,
        paperSize: PosterPaperSize.a4,
        displayName: '   ',
      );
      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 4), _pdfMagic);
    });

    test('a non-empty displayName override builds a valid PDF', () async {
      // Not asserted against actual rendered text: the poster embeds a
      // subset TTF with Identity-H glyph encoding, so the name never
      // appears as a readable substring in the (compressed) PDF bytes.
      // That the override actually reaches the page is checked visually
      // via tool/render_poster_samples.dart + qlmanage.
      final bytes = await buildPosterPdf(
        jar: _jar,
        theme: PosterTheme.minimalFrame,
        language: PosterLanguage.english,
        paperSize: PosterPaperSize.a4,
        displayName: 'DJ Overridden',
      );
      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 4), _pdfMagic);
    });
  });
}
