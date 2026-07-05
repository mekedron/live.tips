import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/poster/poster_document.dart';
import '../../core/poster/poster_paper.dart';
import '../../core/poster/poster_strings.dart';
import '../../core/theme.dart';
import '../../domain/poster.dart';
import '../../domain/tip_jar.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../shell/app_shell.dart';

/// Pick a poster theme / caption language, preview it live, then print or
/// save a PDF — the print-ready alternative to reading a QR off a screen.
class PosterScreen extends ConsumerWidget {
  const PosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final jar = app.effectiveTipJar;

    if (jar == null) {
      // Shouldn't happen (every entry point already requires a jar), but
      // mirrors LiveScreen's defensive guard rather than crashing.
      return const SizedBox();
    }

    final posterSettings = app.settings.poster;
    final isRail = AppShellScope.of(context)?.isRail ?? false;

    // Reads fresh state at call time: the customize sheet outlives this
    // build, and consecutive edits must not clobber each other.
    void updatePoster(PosterSettings Function(PosterSettings) update) {
      final current = ref.read(appStateProvider).settings;
      ref.read(appStateProvider.notifier).updateSettings(
            current.copyWith(poster: update(current.poster)),
          );
    }

    final paperPill = LtPill(
      label: posterSettings.paperSize.label,
      soft: false,
      trailing: Icon(Icons.expand_more_rounded,
          size: 16, color: c.textSecondary),
      onTap: () async {
        final picked = await showLtPicker<PosterPaperSize>(
          context: context,
          title: 'Paper size',
          values: PosterPaperSize.values,
          selected: posterSettings.paperSize,
          labelOf: (p) => p.label,
        );
        if (picked != null) {
          updatePoster((s) => s.copyWith(paperSize: picked));
        }
      },
    );

    final themeChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final t in PosterTheme.values) ...[
            _ThemeChip(
              label: t.label,
              selected: posterSettings.theme == t,
              onTap: () => updatePoster((s) => s.copyWith(theme: t)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );

    final optionsCard = LtCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          LtRow(
            icon: Icons.language_rounded,
            title: 'Language',
            trailing: Text(
              posterSettings.language.label,
              style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 13.5,
                  color: c.textSecondary),
            ),
            chevron: true,
            onTap: () async {
              final picked = await showLtPicker<PosterLanguage>(
                context: context,
                title: 'Caption language',
                values: PosterLanguage.values,
                selected: posterSettings.language,
                labelOf: (l) => l.label,
              );
              if (picked != null) {
                updatePoster((s) => s.copyWith(language: picked));
              }
            },
          ),
          Divider(height: 1, color: c.divider),
          LtRow(
            icon: Icons.edit_outlined,
            title: 'Customize text & name',
            chevron: true,
            onTap: () => _showCustomizeSheet(
              context,
              settings: posterSettings,
              jarDisplayName: jar.displayName,
              updatePoster: updatePoster,
            ),
          ),
        ],
      ),
    );

    final printButton = LtPrimaryButton(
      label: 'Print / Save PDF',
      icon: Icons.print_rounded,
      onPressed: () => Printing.layoutPdf(
        name: _pdfName(posterSettings, jar),
        onLayout: (format) => buildPosterPdf(
          jar: jar,
          theme: posterSettings.theme,
          language: posterSettings.language,
          paperSize:
              posterPaperSizeForFormat(format) ?? posterSettings.paperSize,
          displayName: posterSettings.displayName,
          headline: posterSettings.headline,
          subline: posterSettings.subline,
          footer: posterSettings.footer,
        ),
      ),
    );

    final shareButton = OutlinedButton.icon(
      onPressed: () async {
        final bytes = await buildPosterPdf(
          jar: jar,
          theme: posterSettings.theme,
          language: posterSettings.language,
          paperSize: posterSettings.paperSize,
          displayName: posterSettings.displayName,
          headline: posterSettings.headline,
          subline: posterSettings.subline,
          footer: posterSettings.footer,
        );
        await Printing.sharePdf(
            bytes: bytes, filename: _pdfName(posterSettings, jar));
      },
      icon: Icon(Icons.ios_share_rounded, size: 18, color: c.textSecondary),
      label: const Text('Share PDF'),
    );

    final preview = _PosterPreview(jar: jar, settings: posterSettings);

    if (isRail) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Poster',
                              style: outfitStyle(32, c.text,
                                  weight: FontWeight.w800)),
                        ),
                        paperPill,
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LtSectionLabel('Theme'),
                    ),
                    themeChips,
                    const SizedBox(height: 16),
                    optionsCard,
                    const SizedBox(height: 16),
                    printButton,
                    const SizedBox(height: 10),
                    shareButton,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(child: preview),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Poster',
                          style: outfitStyle(20, c.text,
                              weight: FontWeight.w700)),
                    ),
                    paperPill,
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: preview,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LtSectionLabel('Theme'),
                    ),
                  ),
                  themeChips,
                  const SizedBox(height: 14),
                  optionsCard,
                  const SizedBox(height: 14),
                  printButton,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pdfName(PosterSettings settings, TipJar jar) {
    final name = settings.displayName.trim().isEmpty
        ? jar.displayName
        : settings.displayName.trim();
    return '$name-tip-poster.pdf';
  }

  void _showCustomizeSheet(
    BuildContext context, {
    required PosterSettings settings,
    required String jarDisplayName,
    required void Function(PosterSettings Function(PosterSettings)) updatePoster,
  }) {
    final languageStrings = kPosterStrings[settings.language]!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final c = context.lt;
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: _CustomizeForm(
            settings: settings,
            jarDisplayName: jarDisplayName,
            languageStrings: languageStrings,
            updatePoster: updatePoster,
            textColor: c.text,
          ),
        );
      },
    );
  }
}

class _CustomizeForm extends StatefulWidget {
  const _CustomizeForm({
    required this.settings,
    required this.jarDisplayName,
    required this.languageStrings,
    required this.updatePoster,
    required this.textColor,
  });

  final PosterSettings settings;
  final String jarDisplayName;
  final PosterStrings languageStrings;
  final void Function(PosterSettings Function(PosterSettings)) updatePoster;
  final Color textColor;

  @override
  State<_CustomizeForm> createState() => _CustomizeFormState();
}

class _CustomizeFormState extends State<_CustomizeForm> {
  late final _nameController =
      TextEditingController(text: widget.settings.displayName);
  late final _headlineController =
      TextEditingController(text: widget.settings.headline);
  late final _sublineController =
      TextEditingController(text: widget.settings.subline);
  late final _footerController =
      TextEditingController(text: widget.settings.footer);

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _sublineController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 14),
          child: Text(text, style: outfitStyle(13, c.text)),
        );
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Customize text & name',
              style: outfitStyle(18, c.text, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Leave a field blank to use the language\'s own wording.',
            style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 12.5,
                color: c.textSecondary),
          ),
          label('Name on poster'),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: widget.jarDisplayName),
            onChanged: (v) =>
                widget.updatePoster((s) => s.copyWith(displayName: v)),
          ),
          label('Main message'),
          TextField(
            controller: _headlineController,
            decoration:
                InputDecoration(hintText: widget.languageStrings.headline),
            onChanged: (v) =>
                widget.updatePoster((s) => s.copyWith(headline: v)),
          ),
          label('Subtitle'),
          TextField(
            controller: _sublineController,
            decoration:
                InputDecoration(hintText: widget.languageStrings.subline),
            onChanged: (v) =>
                widget.updatePoster((s) => s.copyWith(subline: v)),
          ),
          label('Thank-you line'),
          TextField(
            controller: _footerController,
            decoration:
                InputDecoration(hintText: widget.languageStrings.footer),
            onChanged: (v) =>
                widget.updatePoster((s) => s.copyWith(footer: v)),
          ),
          const SizedBox(height: 20),
          LtPrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: selected ? c.accent : c.card,
      shape: StadiumBorder(
        side: selected ? BorderSide.none : BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: outfitStyle(13, selected ? c.onAccent : c.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _PosterPreview extends StatelessWidget {
  const _PosterPreview({required this.jar, required this.settings});

  final TipJar jar;
  final PosterSettings settings;

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      key: ValueKey(
        '${settings.theme.wire}-${settings.language.wire}-'
        '${settings.paperSize.wire}-${settings.displayName}-'
        '${settings.headline}-${settings.subline}-${settings.footer}',
      ),
      build: (format) => buildPosterPdf(
        jar: jar,
        theme: settings.theme,
        language: settings.language,
        paperSize: posterPaperSizeForFormat(format) ?? settings.paperSize,
        displayName: settings.displayName,
        headline: settings.headline,
        subline: settings.subline,
        footer: settings.footer,
      ),
      initialPageFormat: posterPageFormats[settings.paperSize],
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      useActions: false,
      scrollViewDecoration: const BoxDecoration(color: Colors.transparent),
      previewPageMargin:
          const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
    );
  }
}
