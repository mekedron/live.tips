import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/relay/relay_client.dart';
import '../../domain/tip_method.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

/// Connected-mode helpers shared across the app. The dedicated relay setup
/// screen was retired in favour of per-method editors (onboarding steps and
/// the Settings method pages); these standalone functions live on.

final _uuidRe = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

/// Pulls the MobilePay Box id out of whatever the artist pasted: the full
/// share link (`https://qr.mobilepay.fi/box/<uuid>/pay-in`), any URL that
/// contains the uuid, or the bare uuid itself. Null when nothing uuid-shaped
/// is in there.
String? extractMobilePayBoxId(String input) =>
    _uuidRe.firstMatch(input.trim())?.group(0)?.toLowerCase();

final _monzoLinkRe = RegExp(
  r'(?:^|//)monzo\.me/([^/?#\s]+)',
  caseSensitive: false,
);
final _monzoHandleRe = RegExp(r'^[a-z0-9][a-z0-9._-]{0,29}$');

/// Pulls the Monzo.me handle out of whatever the artist pasted: their profile
/// link (`https://monzo.me/<handle>`, with or without a trailing amount path),
/// or the bare handle with or without a leading `@`. Null when what's left
/// isn't handle-shaped. Mirrors the worker's `MONZO_USERNAME` gate — the handle
/// lands in a URL *path*, so a stray `/` must never survive.
String? extractMonzoUsername(String input) {
  final trimmed = input.trim();
  final link = _monzoLinkRe.firstMatch(trimmed);
  final handle = (link?.group(1) ?? trimmed)
      .replaceFirst(RegExp(r'^@+'), '')
      .toLowerCase();
  return _monzoHandleRe.hasMatch(handle) ? handle : null;
}

/// The value the artist typed, reduced to the atom the relay stores. Null =
/// what they pasted isn't usable for this method.
String? parseRelayMethodValue(TipMethod method, String raw) => switch (method) {
  TipMethod.revolut =>
    RegExp(
          r'^[A-Za-z0-9._-]{3,32}$',
        ).hasMatch(raw.replaceFirst(RegExp(r'^@+'), ''))
        ? raw.replaceFirst(RegExp(r'^@+'), '')
        : null,
  TipMethod.mobilepay => extractMobilePayBoxId(raw),
  TipMethod.monzo => extractMonzoUsername(raw),
  TipMethod.stripe => null,
};

/// Literal placeholder for the link-shaped fields. Null when the method's hint
/// is localized prose instead (Revolut takes a name, not a link).
String? relayMethodHint(TipMethod method) => switch (method) {
  TipMethod.mobilepay => 'https://qr.mobilepay.fi/box/…',
  TipMethod.monzo => 'https://monzo.me/…',
  _ => null,
};

/// Confirms, then replaces the connected-mode jar with a fresh one carrying
/// the same profile — the shared "New tip page link" action behind Home and
/// Settings. Deleting the old jar is best effort; failures surface as
/// SnackBars.
Future<void> confirmAndRegenerateRelayJar(
  BuildContext context,
  WidgetRef ref,
) async {
  final app = ref.read(appStateProvider);
  final old = app.relayJar;
  final secret = app.relaySecret;
  if (old == null || secret == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.s.t('onboarding.relay_setup.regenerate_title')),
      content: Text(context.s.t('onboarding.relay_setup.regenerate_body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.s.t('onboarding.relay_setup.cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.s.t('onboarding.relay_setup.replace')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final successMessage = context.s.t(
    'onboarding.relay_setup.regenerate_success',
  );
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
      monzoUsername: old.hasMonzo ? old.monzoUsername : null,
    );
    await ref
        .read(appStateProvider.notifier)
        .setRelayJar(result.jar, result.secret);
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
  } on RelayApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
  } on RelayNetworkException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } finally {
    client.close();
  }
}
