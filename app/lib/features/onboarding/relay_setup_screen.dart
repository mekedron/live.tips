import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/relay/relay_client.dart';
import '../../state/providers.dart';

/// Connected-mode helpers shared across the app. The dedicated relay setup
/// screen was retired in favour of per-method editors (onboarding steps and
/// the Settings method pages); these standalone functions live on.

final _uuidRe = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');

/// Pulls the MobilePay Box id out of whatever the artist pasted: the full
/// share link (`https://qr.mobilepay.fi/box/<uuid>/pay-in`), any URL that
/// contains the uuid, or the bare uuid itself. Null when nothing uuid-shaped
/// is in there.
String? extractMobilePayBoxId(String input) =>
    _uuidRe.firstMatch(input.trim())?.group(0)?.toLowerCase();

/// MobilePay Boxes settle in euros only — every other currency is rejected
/// client-side before the relay ever sees it. Null means fine.
String? mobilePayCurrencyError(String currency) =>
    currency.toLowerCase() == 'eur'
        ? null
        : 'MobilePay is EUR only — your tip jar uses '
            '${currency.toUpperCase()}. Switch the currency to EUR or '
            'remove MobilePay.';

/// Confirms, then replaces the connected-mode jar with a fresh one carrying
/// the same profile — the shared "New tip page link" action behind Home and
/// Settings. Deleting the old jar is best effort; failures surface as
/// SnackBars.
Future<void> confirmAndRegenerateRelayJar(
    BuildContext context, WidgetRef ref) async {
  final app = ref.read(appStateProvider);
  final old = app.relayJar;
  final secret = app.relaySecret;
  if (old == null || secret == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New tip page link?'),
      content: const Text(
        'This replaces your tip page link. Printed QR codes with the old '
        'link stop working.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Replace link'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final client = RelayClient();
  try {
    // Best effort: the old jar should die, but a fresh link matters more.
    try {
      await client.deleteJar(jarId: old.jarId, secret: secret);
    } catch (_) {}
    final result = await client.createJar(
      artistName: old.artistName,
      message: old.message,
      currency: old.currency,
      stripeUrl: app.tipJar?.url,
      revolutUsername: old.hasRevolut ? old.revolutUsername : null,
      mobilepayBoxId: old.hasMobilePay ? old.mobilepayBoxId : null,
    );
    await ref
        .read(appStateProvider.notifier)
        .setRelayJar(result.jar, result.secret);
    messenger.showSnackBar(
        const SnackBar(content: Text('New tip page link created')));
  } on RelayApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
  } on RelayNetworkException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } finally {
    client.close();
  }
}
