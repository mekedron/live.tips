import '../../domain/poster.dart';
import 'poster_kit.dart';
import 'templates/center_medallion.dart';
import 'templates/gold_on_black.dart';
import 'templates/marquee_bold.dart';
import 'templates/minimal_frame.dart';
import 'templates/newspaper_column.dart';
import 'templates/rounded_card.dart';
import 'templates/split_duotone.dart';
import 'templates/ticket_stub.dart';

/// One builder per [PosterTheme]. Top-level function tear-offs are valid
/// Dart consts, so this dispatch table — not the domain enum — is the only
/// place a `package:pdf` dependency leaks into poster-related code that
/// isn't already `core/poster/*`.
const Map<PosterTheme, PosterTemplateBuilder> posterTemplates = {
  PosterTheme.minimalFrame: buildMinimalFrame,
  PosterTheme.ticketStub: buildTicketStub,
  PosterTheme.marqueeBold: buildMarqueeBold,
  PosterTheme.goldOnBlack: buildGoldOnBlack,
  PosterTheme.newspaperColumn: buildNewspaperColumn,
  PosterTheme.roundedCard: buildRoundedCard,
  PosterTheme.centerMedallion: buildCenterMedallion,
  PosterTheme.splitDuotone: buildSplitDuotone,
};
