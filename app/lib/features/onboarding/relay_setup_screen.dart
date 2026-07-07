import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currencies.dart';
import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../domain/relay_jar.dart';
import '../../domain/tip_method.dart';
import '../../state/onboarding_draft.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/qr_card.dart';

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

/// Creates or edits the connected-mode jar on the live.tips relay — the
/// donor page behind "one QR for every way to tip".
///
/// Create mode fields come from the onboarding draft (or
/// [initialMethods] when opened from Settings before any jar exists); edit
/// mode prefills from the stored jar and shows both method fields so either
/// can be added or cleared.
class RelaySetupScreen extends ConsumerStatefulWidget {
  const RelaySetupScreen({super.key, this.edit = false, this.initialMethods});

  final bool edit;

  /// Create-from-Settings: which method field(s) to show when there's no
  /// onboarding draft to consult.
  final Set<TipMethod>? initialMethods;

  @override
  ConsumerState<RelaySetupScreen> createState() => _RelaySetupScreenState();
}

class _RelaySetupScreenState extends ConsumerState<RelaySetupScreen> {
  final _nameController = TextEditingController();
  final _revolutController = TextEditingController();
  final _mobilepayController = TextEditingController();
  String _currency = 'eur';
  bool _busy = false;
  String? _error;
  String? _revolutError;
  String? _mobilepayError;
  RelayJar? _created;

  /// Edit means "a jar already exists" — an edit request without one falls
  /// back to create so the screen never dead-ends.
  late final bool _editing;
  late final bool _showRevolut;
  late final bool _showMobilePay;

  @override
  void initState() {
    super.initState();
    final app = ref.read(appStateProvider);
    final jar = app.relayJar;
    _editing = widget.edit && jar != null;

    if (_editing) {
      _showRevolut = true;
      _showMobilePay = true;
      _nameController.text = jar!.artistName;
      _currency = jar.currency;
      _revolutController.text = jar.revolutUsername ?? '';
      _mobilepayController.text = jar.mobilepayBoxId ?? '';
    } else {
      final methods = widget.initialMethods ??
          ref.read(onboardingDraftProvider)?.methods ??
          {TipMethod.revolut, TipMethod.mobilepay};
      _showRevolut = methods.contains(TipMethod.revolut);
      _showMobilePay = methods.contains(TipMethod.mobilepay);
    }
    // A Stripe jar fixes name + currency for the whole account.
    final tipJar = app.tipJar;
    if (tipJar != null) {
      _nameController.text = tipJar.displayName;
      _currency = tipJar.currency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _revolutController.dispose();
    _mobilepayController.dispose();
    super.dispose();
  }

  String get _revolutInput =>
      _revolutController.text.trim().replaceFirst(RegExp(r'^@+'), '');

  bool _validate({required bool hasStripeUrl}) {
    String? revolutError;
    String? mobilepayError;
    String? error;

    final revolut = _showRevolut ? _revolutInput : '';
    final mobilepayRaw = _showMobilePay ? _mobilepayController.text.trim() : '';
    final boxId = mobilepayRaw.isEmpty ? null : extractMobilePayBoxId(mobilepayRaw);

    if (_nameController.text.trim().isEmpty) {
      error = 'Add your artist or band name — fans will see it.';
    }
    if (revolut.isNotEmpty &&
        !RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch(revolut)) {
      revolutError = 'That doesn\'t look like a Revolut username.';
    }
    if (mobilepayRaw.isNotEmpty && boxId == null) {
      mobilepayError = 'That doesn\'t look like a Box link or id — paste '
          'the share link from MobilePay.';
    }
    if (mobilepayRaw.isNotEmpty && boxId != null) {
      mobilepayError ??= mobilePayCurrencyError(_currency);
    }
    if (revolut.isEmpty && mobilepayRaw.isEmpty && !hasStripeUrl) {
      error ??= 'Add at least one way to get paid.';
    }

    setState(() {
      _revolutError = revolutError;
      _mobilepayError = mobilepayError;
      _error = error;
    });
    return revolutError == null && mobilepayError == null && error == null;
  }

  Future<void> _submit() async {
    final app = ref.read(appStateProvider);
    if (!_validate(hasStripeUrl: app.tipJar != null)) return;

    final name = _nameController.text.trim();
    final revolut = _showRevolut && _revolutInput.isNotEmpty ? _revolutInput : null;
    final boxId = _showMobilePay
        ? extractMobilePayBoxId(_mobilepayController.text)
        : null;

    setState(() => _busy = true);
    final client = RelayClient();
    try {
      if (_editing) {
        final jar = app.relayJar!;
        final updated = RelayJar(
          jarId: jar.jarId,
          donateUrl: jar.donateUrl,
          artistName: name,
          currency: _currency,
          revolutUsername: revolut,
          mobilepayBoxId: boxId,
          createdAtMs: jar.createdAtMs,
        );
        await client.updateJar(
          jar: updated,
          secret: app.relaySecret!,
          artistName: name,
          stripeUrl: app.tipJar?.url,
        );
        await ref.read(appStateProvider.notifier).updateRelayJarLocal(updated);
        // The registry name is what home/stage/poster show — keep it in
        // step when the edit renamed the act (only possible without a
        // Stripe jar; with one the name field is locked to it).
        if (name != app.displayName) {
          await ref.read(appStateProvider.notifier).renameBand(name);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tip page updated')));
          Navigator.of(context).pop();
        }
      } else {
        final result = await client.createJar(
          artistName: name,
          message: null,
          currency: _currency,
          stripeUrl: app.tipJar?.url,
          revolutUsername: revolut,
          mobilepayBoxId: boxId,
        );
        await ref
            .read(appStateProvider.notifier)
            .setRelayJar(result.jar, result.secret);
        if (mounted) setState(() => _created = result.jar);
      }
    } on RelayApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } on RelayNetworkException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Onboarding is over (or this was a one-off create from Settings): drop
  /// the draft and let RootGate's shell surface.
  void _done() {
    ref.read(onboardingDraftProvider.notifier).clear();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _editing ? null : ref.watch(onboardingDraftProvider);
    final step = draft?.stepOf(OnboardingDraft.stepRelaySetup);
    final total = draft?.totalSteps;

    return Scaffold(
      appBar: _created != null
          ? null
          : AppBar(
              title: Text(_editing ? 'Payment methods' : 'Your tip page'),
              actions: [
                if (step != null && total != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child:
                        Center(child: LtPill(label: 'Step $step of $total')),
                  ),
              ],
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _created != null
              ? _buildSuccess()
              : _buildForm(step: step, total: total),
        ),
      ),
    );
  }

  Widget _buildForm({int? step, int? total}) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final nameLocked = app.tipJar != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (step != null && total != null) ...[
          LtProgressSegments(total: total, filled: step),
          const SizedBox(height: 16),
        ],
        Text(
          _editing
              ? 'Fans open your tip page from the QR and pick how to pay. '
                  'Leave a field empty to drop that method.'
              : 'live.tips gives you one page fans open from your QR — with '
                  'a button for every way you accept tips.',
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 14,
            height: 1.5,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (!nameLocked)
          LtCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FieldLabel('Artist or band name'),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: 'The Midnight Foxes'),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                const SizedBox(height: 5),
                Text(
                  'Fans see this on your tip page and the stage.',
                  style: TextStyle(
                      fontFamily: kFontBody, fontSize: 12, color: c.textMuted),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Currency'),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await showLtPicker<String>(
                      context: context,
                      title: 'Currency',
                      values: kSupportedCurrencies,
                      selected: _currency,
                      labelOf: currencyLabel,
                    );
                    if (picked != null) setState(() => _currency = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: c.bg,
                      border: Border.all(color: c.border, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            currencyLabel(_currency),
                            style: TextStyle(
                                fontFamily: kFontBody,
                                fontSize: 15,
                                color: c.text),
                          ),
                        ),
                        Icon(Icons.expand_more_rounded,
                            size: 22, color: c.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          LtCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.person_rounded, size: 20, color: c.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _nameController.text,
                    style: outfitStyle(14.5, c.text),
                  ),
                ),
                LtPill(label: _currency.toUpperCase(), soft: false),
              ],
            ),
          ),
        if (_showRevolut) ...[
          const SizedBox(height: 14),
          LtCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FieldLabel('Revolut username'),
                TextField(
                  controller: _revolutController,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    prefixText: '@',
                    hintText: 'username',
                    errorText: _revolutError,
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) {
                    if (_revolutError != null) {
                      setState(() => _revolutError = null);
                    }
                  },
                ),
                const SizedBox(height: 5),
                Text(
                  'In the Revolut app: tap your profile → your @username is '
                  'under your name.',
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 12,
                      height: 1.4,
                      color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
        if (_showMobilePay) ...[
          const SizedBox(height: 14),
          LtCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FieldLabel('MobilePay Box'),
                TextField(
                  controller: _mobilepayController,
                  autocorrect: false,
                  enableSuggestions: false,
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'https://qr.mobilepay.fi/box/…',
                    errorText: _mobilepayError,
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) {
                    if (_mobilepayError != null) {
                      setState(() => _mobilepayError = null);
                    }
                  },
                ),
                const SizedBox(height: 5),
                Text(
                  'In MobilePay: open your Box → Share → the link contains '
                  'the box id (a long code with dashes). Paste the whole '
                  'link or just the code. MobilePay Boxes are EUR only.',
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 12,
                      height: 1.4,
                      color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 13,
                height: 1.45,
                color: c.danger),
          ),
        ],
        const SizedBox(height: 20),
        LtPrimaryButton(
          label: _editing ? 'Save changes' : 'Create my tip page',
          busy: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final c = context.lt;
    final jar = _created!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: c.successContainer, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 34, color: c.success),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your tip page is live!',
          textAlign: TextAlign.center,
          style: outfitStyle(26, c.text, weight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'One QR for every way to tip.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 14,
            height: 1.5,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        LtCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              QrBlock(data: jar.donateUrl, size: 180),
              const SizedBox(height: 14),
              Text(
                jar.donateUrl.replaceFirst(RegExp('^https?://'), ''),
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Open the app every now and then — an unused link expires after '
          '90 days.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 13,
            height: 1.5,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 28),
        LtPrimaryButton(label: 'Done', onPressed: _done),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: outfitStyle(13, context.lt.text)),
    );
  }
}
