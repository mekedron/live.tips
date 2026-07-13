import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_migrator.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';

/// Invisible wrapper that watches for a sign-in and offers — once per
/// account — to move this device's local bands (jars, settings, history,
/// secrets) into it. Sits at the app root because the sign-in sheets pop
/// themselves before the offer could run from their own contexts.
///
/// A crashed upload resumes from main() without asking again; declining is
/// remembered per uid, so nobody gets nagged on every profile switch.
class CloudUploadOfferGate extends ConsumerStatefulWidget {
  const CloudUploadOfferGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CloudUploadOfferGate> createState() =>
      _CloudUploadOfferGateState();
}

class _CloudUploadOfferGateState extends ConsumerState<CloudUploadOfferGate> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider.select((s) => s.user?.uid),
        (previous, uid) {
      if (uid != null && uid != previous) _maybeOffer(uid);
    });
    return widget.child;
  }

  Future<void> _maybeOffer(String uid) async {
    if (_running) return;
    final db = ref.read(firestoreProvider);
    if (db == null) return;
    final local = ref.read(localStoreProvider);
    if (local.readCloudUploadOffered(uid)) return;
    // Anything worth moving? A band counts once it was named or holds any
    // data — pristine placeholder bands travel as noise, not value.
    final registry = local.readAccountsRegistry();
    final hasData = registry != null &&
        registry.accounts.any(
            (a) => a.name.trim().isNotEmpty || local.accountHasData(a.id));
    if (!hasData) return;
    if (!mounted) return;

    final s = context.s;
    unawaited(local.markCloudUploadOffered(uid));
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('account.upload_offer.title')),
        content: Text(s.t('account.upload_offer.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('account.upload_offer.decline')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('account.upload_offer.accept')),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    // The signed-in user may have changed while the dialog sat open.
    if (ref.read(authControllerProvider).user?.uid != uid) return;

    _running = true;
    final progress = ValueNotifier<String>('');
    if (mounted) {
      // Fire-and-forget: the upload below pops it when done.
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: progress,
                    builder: (context, value, child) => Text(value.isEmpty
                        ? s.t('account.upload_offer.progress')
                        : value),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    var failed = false;
    try {
      final migrator = CloudMigrator(
        local: local,
        secure: ref.read(secureStoreProvider),
        db: db,
      );
      await migrator.uploadLocalBands(uid, onProgress: (band, done, total) {
        progress.value = s.t('account.upload_offer.progress_band', {
          'band': band,
          'done': '$done',
          'total': '$total',
        });
      });
    } catch (_) {
      // The pending flag survives — the next boot resumes the upload.
      failed = true;
    } finally {
      _running = false;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // the progress dialog
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(s.t(failed
          ? 'account.upload_offer.failed'
          : 'account.upload_offer.done')),
    ));
  }
}
