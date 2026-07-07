import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/poster/poster_document.dart';
import '../../core/poster/poster_paper.dart';
import '../../core/poster/poster_strings.dart';
import '../../core/theme.dart';
import '../../domain/poster.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../shell/app_shell.dart';

/// Open the poster designer as a modal route with a back arrow — poster is no
/// longer a bottom-nav tab, so this gives a clear way back. PosterScreen draws
/// its own header + back button (shown whenever it can pop), so no AppBar
/// wrapper is needed.
void openPoster(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: SafeArea(child: PosterScreen())),
    ),
  );
}

/// Pick a poster theme / paper size, preview it live in a pan-and-zoom
/// canvas, then print or save a PDF — the print-ready alternative to
/// reading a QR off a screen.
class PosterScreen extends ConsumerWidget {
  const PosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final qrData = app.activeQrUrl;

    if (qrData == null) {
      // Shouldn't happen (every entry point already requires some jar), but
      // mirrors LiveScreen's defensive guard rather than crashing.
      return const SizedBox();
    }

    final artistName = app.displayName;
    final posterSettings = app.settings.poster;
    // The name actually printed: the poster's own override when set, else
    // the artist name from whichever jar is configured.
    final resolvedName = posterSettings.displayName.trim().isEmpty
        ? artistName
        : posterSettings.displayName.trim();
    // In the shell it follows the rail; opened as a modal route (no shell
    // scope) it falls back to the screen width, so desktop keeps the wide
    // layout there too.
    final isRail = AppShellScope.of(context)?.isRail ??
        (MediaQuery.sizeOf(context).width >= kRailBreakpoint);

    // Reads fresh state at call time: the customize sheet outlives this
    // build, and consecutive edits must not clobber each other.
    void updatePoster(PosterSettings Function(PosterSettings) update) {
      final current = ref.read(appStateProvider).settings;
      ref.read(appStateProvider.notifier).updateSettings(
            current.copyWith(poster: update(current.poster)),
          );
    }

    // Theme · Format · Customize — one plain select list, mirroring the
    // Style/Vessel rows in the stage settings.
    final optionsCard = LtCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          LtRow(
            icon: Icons.palette_outlined,
            title: 'Theme',
            trailing: _ValueText(posterSettings.theme.label),
            chevron: true,
            onTap: () async {
              final picked = await showLtPicker<PosterTheme>(
                context: context,
                title: 'Poster theme',
                values: PosterTheme.values,
                selected: posterSettings.theme,
                labelOf: (t) => t.label,
              );
              if (picked != null) {
                updatePoster((s) => s.copyWith(theme: picked));
              }
            },
          ),
          Divider(height: 1, color: c.divider),
          LtRow(
            icon: Icons.crop_free_rounded,
            title: 'Format',
            trailing: _ValueText(posterSettings.paperSize.label),
            chevron: true,
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
          ),
          Divider(height: 1, color: c.divider),
          LtRow(
            icon: Icons.edit_outlined,
            title: 'Customize text & name',
            chevron: true,
            onTap: () => _showCustomizeSheet(
              context,
              settings: posterSettings,
              jarDisplayName: artistName,
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
        name: _pdfName(resolvedName),
        onLayout: (format) => buildPosterPdf(
          qrData: qrData,
          theme: posterSettings.theme,
          paperSize:
              posterPaperSizeForFormat(format) ?? posterSettings.paperSize,
          displayName: resolvedName,
          headline: posterSettings.headline,
          subline: posterSettings.subline,
          footer: posterSettings.footer,
        ),
      ),
    );

    final shareButton = OutlinedButton.icon(
      onPressed: () async {
        final bytes = await buildPosterPdf(
          qrData: qrData,
          theme: posterSettings.theme,
          paperSize: posterSettings.paperSize,
          displayName: resolvedName,
          headline: posterSettings.headline,
          subline: posterSettings.subline,
          footer: posterSettings.footer,
        );
        await Printing.sharePdf(
            bytes: bytes, filename: _pdfName(resolvedName));
      },
      icon: Icon(Icons.ios_share_rounded, size: 18, color: c.textSecondary),
      label: const Text('Share PDF'),
    );

    final preview = _PosterViewport(
      qrData: qrData,
      displayName: resolvedName,
      settings: posterSettings,
    );

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
                        if (Navigator.of(context).canPop())
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: IconButton(
                              tooltip: 'Back',
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        Text('Poster',
                            style: outfitStyle(32, c.text,
                                weight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 24),
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
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  else
                    const SizedBox(width: 20),
                  Expanded(
                    child: Text('Poster',
                        style:
                            outfitStyle(20, c.text, weight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 20),
                ],
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

  String _pdfName(String resolvedName) => '$resolvedName-tip-poster.pdf';

  void _showCustomizeSheet(
    BuildContext context, {
    required PosterSettings settings,
    required String jarDisplayName,
    required void Function(PosterSettings Function(PosterSettings)) updatePoster,
  }) {
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
    required this.updatePoster,
    required this.textColor,
  });

  final PosterSettings settings;
  final String jarDisplayName;
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
            'Write these in any language you like. Leave a field blank to '
            'use the default wording.',
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
          label('“Scan to tip” line'),
          TextField(
            controller: _headlineController,
            decoration: InputDecoration(
                hintText: kDefaultPosterStrings.headline),
            onChanged: (v) =>
                widget.updatePoster((s) => s.copyWith(headline: v)),
          ),
          label('Subtitle'),
          TextField(
            controller: _sublineController,
            decoration:
                InputDecoration(hintText: kDefaultPosterStrings.subline),
            onChanged: (v) =>
                widget.updatePoster((s) => s.copyWith(subline: v)),
          ),
          label('Thank-you line'),
          TextField(
            controller: _footerController,
            decoration:
                InputDecoration(hintText: kDefaultPosterStrings.footer),
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

/// Trailing value text for a select row — matches the stage settings.
class _ValueText extends StatelessWidget {
  const _ValueText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: kFontBody,
        fontSize: 13.5,
        color: context.lt.textSecondary,
      ),
    );
  }
}

/// A pan-and-zoom canvas that rasterizes the current poster and shows it
/// inside an [InteractiveViewer]:
///   • mouse wheel / trackpad pinch → zoom toward the cursor
///   • left-drag / one-finger drag / two-finger trackpad → pan
///   • double-tap or the reset button → back to fit
///
/// Replaces the printing package's `PdfPreview`, whose built-in multi-page
/// scroller renders cramped and off-center on wide desktop layouts.
class _PosterViewport extends StatefulWidget {
  const _PosterViewport({
    required this.qrData,
    required this.displayName,
    required this.settings,
  });

  final String qrData;

  /// Already resolved by the caller: the poster's custom name when set,
  /// else the configured jar's artist name.
  final String displayName;
  final PosterSettings settings;

  @override
  State<_PosterViewport> createState() => _PosterViewportState();
}

class _PosterViewportState extends State<_PosterViewport> {
  final TransformationController _transform = TransformationController();
  Timer? _debounce;
  int _rasterToken = 0;
  ui.Image? _image;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _rasterize();
  }

  @override
  void didUpdateWidget(covariant _PosterViewport old) {
    super.didUpdateWidget(old);
    if (old.settings != widget.settings ||
        old.qrData != widget.qrData ||
        old.displayName != widget.displayName) {
      // Typing in the customize sheet fires many rebuilds a second — collapse
      // them so pdf.js doesn't re-rasterize on every keystroke.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 240), _rasterize);
    }
  }

  Future<void> _rasterize() async {
    final token = ++_rasterToken;
    final settings = widget.settings;
    try {
      final bytes = await buildPosterPdf(
        qrData: widget.qrData,
        theme: settings.theme,
        paperSize: settings.paperSize,
        displayName: widget.displayName,
        headline: settings.headline,
        subline: settings.subline,
        footer: settings.footer,
      );
      // Aim for ~2000px on the long edge whatever the paper size, so an A2
      // poster doesn't rasterize into a 60-megapixel image on the web.
      final format = posterPageFormats[settings.paperSize]!;
      final longEdgeInches = math.max(format.width, format.height) / 72.0;
      final dpi = (2000 / longEdgeInches).clamp(96.0, 300.0);
      final raster =
          await Printing.raster(bytes, pages: const [0], dpi: dpi).first;
      final image = await raster.toImage();
      if (!mounted || token != _rasterToken) {
        image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = image;
        _failed = false;
      });
    } catch (_) {
      if (!mounted || token != _rasterToken) return;
      setState(() => _failed = true);
    }
  }

  void _resetView() => _transform.value = Matrix4.identity();

  @override
  void dispose() {
    _debounce?.cancel();
    _rasterToken++; // orphan any in-flight raster so it can't setState
    _image?.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final image = _image;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.chip.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: image == null
            ? Center(
                child: _failed
                    ? Text('Preview unavailable',
                        style: outfitStyle(14, c.textSecondary))
                    : const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Keep the poster from being flung out of sight: cap
                        // the pan at half the canvas on each side, so at the
                        // extreme its centre only reaches a corner of the
                        // viewport — never further, never lost.
                        final boundary = EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth / 2,
                          vertical: constraints.maxHeight / 2,
                        );
                        return GestureDetector(
                          onDoubleTap: _resetView,
                          child: InteractiveViewer(
                            transformationController: _transform,
                            minScale: 0.5,
                            maxScale: 6,
                            boundaryMargin: boundary,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: _PosterPaper(image: image),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: IgnorePointer(
                      child: Center(child: _ViewportHint()),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _ResetButton(onTap: _resetView),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The rasterized poster sized to its own aspect ratio, on a white sheet
/// with a soft drop shadow.
class _PosterPaper extends StatelessWidget {
  const _PosterPaper({required this.image});

  final ui.Image image;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: image.width / image.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        // Cloned internally by RawImage, so the state's own handle stays
        // free to dispose on the next raster.
        child: RawImage(image: image, fit: BoxFit.contain),
      ),
    );
  }
}

class _ViewportHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Text(
        'Scroll or pinch to zoom · drag to move',
        style: outfitStyle(11, c.textSecondary),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: c.card.withValues(alpha: 0.9),
      shape: CircleBorder(side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: 'Reset zoom',
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(Icons.center_focus_strong_rounded,
                size: 18, color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}
