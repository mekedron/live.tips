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

/// Pick a poster theme/caption language, preview it live, then print/share/
/// save a PDF — the print-ready alternative to reading a QR off a phone or
/// tablet screen.
class PosterScreen extends ConsumerWidget {
  const PosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final jar = app.effectiveTipJar;

    if (jar == null) {
      // Shouldn't happen (every entry point already requires a jar), but
      // mirrors LiveScreen's defensive guard rather than crashing.
      return const Scaffold(body: SizedBox());
    }

    final posterSettings = app.settings.poster;

    void updatePoster(PosterSettings Function(PosterSettings) update) {
      ref
          .read(appStateProvider.notifier)
          .updateSettings(
            app.settings.copyWith(poster: update(posterSettings)),
          );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Print poster')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 820;
          final controls = _PosterControls(
            settings: posterSettings,
            jarDisplayName: jar.displayName,
            onThemeChanged: (t) =>
                updatePoster((s) => s.copyWith(theme: t)),
            onLanguageChanged: (l) =>
                updatePoster((s) => s.copyWith(language: l)),
            onDisplayNameChanged: (n) =>
                updatePoster((s) => s.copyWith(displayName: n)),
            onHeadlineChanged: (v) =>
                updatePoster((s) => s.copyWith(headline: v)),
            onSublineChanged: (v) =>
                updatePoster((s) => s.copyWith(subline: v)),
            onFooterChanged: (v) =>
                updatePoster((s) => s.copyWith(footer: v)),
          );
          final preview = _PosterPreview(
            jar: jar,
            settings: posterSettings,
            onPaperSizeChanged: (p) =>
                updatePoster((s) => s.copyWith(paperSize: p)),
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 320, child: controls),
                const VerticalDivider(width: 1),
                Expanded(child: preview),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              controls,
              const Divider(height: 1),
              Expanded(child: preview),
            ],
          );
        },
      ),
    );
  }
}

class _PosterControls extends StatefulWidget {
  const _PosterControls({
    required this.settings,
    required this.jarDisplayName,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onDisplayNameChanged,
    required this.onHeadlineChanged,
    required this.onSublineChanged,
    required this.onFooterChanged,
  });

  final PosterSettings settings;
  final String jarDisplayName;
  final ValueChanged<PosterTheme> onThemeChanged;
  final ValueChanged<PosterLanguage> onLanguageChanged;
  final ValueChanged<String> onDisplayNameChanged;
  final ValueChanged<String> onHeadlineChanged;
  final ValueChanged<String> onSublineChanged;
  final ValueChanged<String> onFooterChanged;

  @override
  State<_PosterControls> createState() => _PosterControlsState();
}

class _PosterControlsState extends State<_PosterControls> {
  late final _nameController = TextEditingController(
    text: widget.settings.displayName,
  );
  late final _headlineController = TextEditingController(
    text: widget.settings.headline,
  );
  late final _sublineController = TextEditingController(
    text: widget.settings.subline,
  );
  late final _footerController = TextEditingController(
    text: widget.settings.footer,
  );

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
    final settings = widget.settings;
    final theme = Theme.of(context);
    final languageStrings = kPosterStrings[settings.language]!;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        Text('Name on poster', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: widget.jarDisplayName,
            helperText: "Defaults to your jar's name — override it just "
                'for the poster',
            helperMaxLines: 2,
          ),
          onChanged: widget.onDisplayNameChanged,
        ),
        const SizedBox(height: 24),
        Text('Poster text', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Leave blank to use the language\'s own wording',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _headlineController,
          decoration: InputDecoration(
            labelText: 'Main message',
            hintText: languageStrings.headline,
          ),
          onChanged: widget.onHeadlineChanged,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _sublineController,
          decoration: InputDecoration(
            labelText: 'Subtitle',
            hintText: languageStrings.subline,
          ),
          onChanged: widget.onSublineChanged,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _footerController,
          decoration: InputDecoration(
            labelText: 'Thank-you line',
            hintText: languageStrings.footer,
          ),
          onChanged: widget.onFooterChanged,
        ),
        const SizedBox(height: 24),
        Text('Theme', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in PosterTheme.values)
              ChoiceChip(
                label: Text(t.label),
                selected: settings.theme == t,
                onSelected: (_) => widget.onThemeChanged(t),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Language', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        DropdownButton<PosterLanguage>(
          value: settings.language,
          isExpanded: true,
          underline: const SizedBox(),
          items: [
            for (final l in PosterLanguage.values)
              DropdownMenuItem(value: l, child: Text(l.label)),
          ],
          onChanged: (v) {
            if (v != null) widget.onLanguageChanged(v);
          },
        ),
      ],
    );
  }
}

class _PosterPreview extends StatelessWidget {
  const _PosterPreview({
    required this.jar,
    required this.settings,
    required this.onPaperSizeChanged,
  });

  final TipJar jar;
  final PosterSettings settings;
  final ValueChanged<PosterPaperSize> onPaperSizeChanged;

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
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
      pageFormats: posterPickerFormats,
      canChangePageFormat: true,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
      pdfFileName:
          '${settings.displayName.trim().isEmpty ? jar.displayName : settings.displayName.trim()}-tip-poster.pdf',
      onPageFormatChanged: (format) {
        final size = posterPaperSizeForFormat(format);
        if (size != null) onPaperSizeChanged(size);
      },
      actionBarTheme: const PdfActionBarTheme(
        backgroundColor: kStageBlack,
        iconColor: kGold,
      ),
    );
  }
}
