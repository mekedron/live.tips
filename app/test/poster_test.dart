import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/band_settings.dart';
import 'package:live_tips/domain/poster.dart';

void main() {
  group('PosterSettings', () {
    test('defaults: minimal frame, A4, no overrides', () {
      const s = PosterSettings();
      expect(s.theme, PosterTheme.minimalFrame);
      expect(s.paperSize, PosterPaperSize.a4);
      expect(s.displayName, isEmpty);
      expect(s.headline, isEmpty);
      expect(s.subline, isEmpty);
      expect(s.footer, isEmpty);
    });

    test('json round-trip preserves every field', () {
      const s = PosterSettings(
        theme: PosterTheme.goldOnBlack,
        paperSize: PosterPaperSize.a3,
        displayName: 'The Midnight Foxes',
        headline: 'Custom headline',
        subline: 'Custom subline',
        footer: 'Custom footer',
      );
      expect(PosterSettings.fromJson(s.toJson()), s);
    });

    test('copyWith only changes the given field', () {
      const s = PosterSettings(theme: PosterTheme.ticketStub);
      final next = s.copyWith(paperSize: PosterPaperSize.letter);
      expect(next.theme, PosterTheme.ticketStub);
      expect(next.paperSize, PosterPaperSize.letter);
      expect(next.displayName, isEmpty);
      expect(next.headline, isEmpty);
    });

    test('copyWith can set an explicit empty override', () {
      const s = PosterSettings(
        displayName: 'The Midnight Foxes',
        headline: 'Custom headline',
      );
      final cleared = s.copyWith(displayName: '', headline: '');
      expect(cleared.displayName, isEmpty);
      expect(cleared.headline, isEmpty);
    });

    test('wire values are stable', () {
      expect(PosterTheme.minimalFrame.wire, 'minimal-frame');
      expect(PosterTheme.ticketStub.wire, 'ticket-stub');
      expect(PosterTheme.marqueeBold.wire, 'marquee-bold');
      expect(PosterTheme.goldOnBlack.wire, 'gold-on-black');
      expect(PosterTheme.newspaperColumn.wire, 'newspaper-column');
      expect(PosterTheme.roundedCard.wire, 'rounded-card');
      expect(PosterTheme.centerMedallion.wire, 'center-medallion');
      expect(PosterTheme.splitDuotone.wire, 'split-duotone');
      expect(PosterPaperSize.a4.wire, 'a4');
    });

    test('all 8 themes have distinct wire values', () {
      expect(PosterTheme.values.map((t) => t.wire).toSet().length, 8);
    });

    test('unknown / retired wire values decode to defaults', () {
      // 'language' is a retired key — a blob written by an old build that
      // still carries it must decode cleanly, ignoring it.
      final s = PosterSettings.fromJson({
        'theme': 'holographic',
        'language': 'klingon',
        'paperSize': 'a0',
      });
      expect(s, const PosterSettings());
    });
  });

  group('BandSettings + poster', () {
    test('round-trips the nested poster settings', () {
      const s = BandSettings(
        poster: PosterSettings(
          theme: PosterTheme.splitDuotone,
          paperSize: PosterPaperSize.a2,
        ),
      );
      final revived = BandSettings.fromJson(s.toJson());
      expect(revived.poster.theme, PosterTheme.splitDuotone);
      expect(revived.poster.paperSize, PosterPaperSize.a2);
    });

    test('band-settings blob without a poster key gets defaults', () {
      // A blob missing the poster key (or carrying retired extras) must
      // decode cleanly with poster defaults — same tolerance the legacy
      // settings_v1 blob used to guarantee before poster moved here.
      final legacy = {
        'lastGoalMinor': 20000,
        'preferDeviceAuth': false,
      };
      final s = BandSettings.fromJson(legacy);
      expect(s.poster, const PosterSettings());
      expect(s.lastGoalMinor, 20000);
    });
  });
}
