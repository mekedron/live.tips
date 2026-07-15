import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// One tap → the song title on the clipboard. The artist reading a request
/// is usually holding the phone the chords app lives on: the title's whole
/// journey is copy here, paste there — so both the request queue and the
/// notifications feed wear this same little button.
class CopySongButton extends StatelessWidget {
  const CopySongButton({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return IconButton(
      tooltip: context.s.t('widgets.copy_song.tooltip'),
      icon: Icon(Icons.copy_rounded, size: 18, color: c.textMuted),
      onPressed: () => unawaited(copySongTitle(context, title)),
    );
  }
}

Future<void> copySongTitle(BuildContext context, String title) async {
  await Clipboard.setData(ClipboardData(text: title));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(context.s.t('widgets.copy_song.done', {'title': title})),
    duration: const Duration(seconds: 2),
  ));
}
