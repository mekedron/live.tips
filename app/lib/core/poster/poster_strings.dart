import '../../domain/poster.dart';

/// The poster's printed caption text in one language. All three fields are
/// always required — no language ships half-translated — but a template
/// may simply choose not to render [subline]/[footer] in a minimalist
/// composition. Deliberately no interpolation: the artist's name is a
/// separate field on `PosterData`, rendered by each template on its own.
class PosterStrings {
  const PosterStrings({
    required this.headline,
    required this.subline,
    required this.footer,
  });

  /// The primary call to action, e.g. "Scan to tip".
  final String headline;

  /// A short supporting line, e.g. "Support the show".
  final String subline;

  /// Small-print thank-you line.
  final String footer;
}

/// Caption text for every [PosterLanguage]. Short signage phrases — get a
/// native speaker to skim before relying on these for anything more formal.
const Map<PosterLanguage, PosterStrings> kPosterStrings = {
  PosterLanguage.english: PosterStrings(
    headline: 'Scan to tip',
    subline: 'Support the show',
    footer: 'Thank you for the tip!',
  ),
  PosterLanguage.spanish: PosterStrings(
    headline: 'Escanea para dar propina',
    subline: 'Apoya el espectáculo',
    footer: '¡Gracias por tu propina!',
  ),
  PosterLanguage.french: PosterStrings(
    headline: 'Scannez pour un pourboire',
    subline: 'Soutenez le spectacle',
    footer: 'Merci pour votre générosité !',
  ),
  PosterLanguage.german: PosterStrings(
    headline: 'Scannen für Trinkgeld',
    subline: 'Unterstütze die Show',
    footer: 'Danke für dein Trinkgeld!',
  ),
  PosterLanguage.italian: PosterStrings(
    headline: 'Scansiona per una mancia',
    subline: 'Sostieni lo spettacolo',
    footer: 'Grazie per la mancia!',
  ),
  PosterLanguage.portuguese: PosterStrings(
    headline: 'Escaneie para dar uma gorjeta',
    subline: 'Apoie o espetáculo',
    footer: 'Obrigado pela gorjeta!',
  ),
  PosterLanguage.russian: PosterStrings(
    headline: 'Отсканируйте для чаевых',
    subline: 'Поддержите выступление',
    footer: 'Спасибо за чаевые!',
  ),
  PosterLanguage.polish: PosterStrings(
    headline: 'Zeskanuj, aby dać napiwek',
    subline: 'Wesprzyj występ',
    footer: 'Dziękujemy za napiwek!',
  ),
  PosterLanguage.dutch: PosterStrings(
    headline: 'Scan voor een fooi',
    subline: 'Steun de show',
    footer: 'Bedankt voor je fooi!',
  ),
};
