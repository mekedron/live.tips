import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currencies.dart';
import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../data/stripe/stripe_client.dart';
import '../../domain/tip_jar.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../onboarding/relay_setup_screen.dart' show mobilePayCurrencyError;

/// Edits everything a band carries from onboarding — the artist/band name,
/// its currency, and the thank-you message — from one page, and pushes the
/// change everywhere it lives: the local registry, the Stripe payment link,
/// and the connected-mode tip page on the relay.
///
/// The currency is the sharp edge: a Stripe price can't change currency, so
/// switching it means a fresh payment link (and a dead old QR). The screen
/// warns before doing that; a name/message-only edit is updated in place and
/// keeps the link.
class AccountDetailsScreen extends ConsumerStatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  final _nameController = TextEditingController();
  final _thanksController = TextEditingController();
  late String _currency;
  bool _busy = false;
  String? _error;

  static const _defaultThanks = 'Thank you! 💛';

  @override
  void initState() {
    super.initState();
    final app = ref.read(appStateProvider);
    _nameController.text = app.displayName;
    _currency = app.currency;
    _thanksController.text =
        app.tipJar?.thankYouMessage ?? app.relayJar?.message ?? _defaultThanks;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thanksController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final name = _nameController.text.trim();
    final currency = _currency;
    final thankYou = _thanksController.text.trim().isEmpty
        ? _defaultThanks
        : _thanksController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Add your artist or band name — fans will see it.');
      return;
    }
    final relayJar = app.relayJar;
    if (relayJar?.hasMobilePay ?? false) {
      final err = mobilePayCurrencyError(currency);
      if (err != null) {
        setState(() => _error = err);
        return;
      }
    }

    final tipJar = app.tipJar;
    final currencyChanged =
        tipJar != null && !tipJar.isDemo && tipJar.currency != currency;

    // A Stripe price can't switch currency — warn that the link is replaced.
    if (currencyChanged) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace your Stripe link?'),
          content: const Text(
            'Stripe can\'t change a link\'s currency, so switching it creates '
            'a new payment link. Printed QR codes with the old Stripe-only '
            'link stop working. Your tip page QR is unaffected.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace link'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // ------------------------------------------------------------ Stripe
      TipJar? newTipJar;
      if (tipJar != null && !tipJar.isDemo) {
        final requests = ref.read(stripeRequestsProvider);
        if (currencyChanged) {
          if (requests == null) {
            throw const StripeNetworkException('Stripe key unavailable.');
          }
          newTipJar = await requests.createTipJar(
            currency: currency,
            displayName: name,
            thankYouMessage: thankYou,
          );
          try {
            await requests.deactivatePaymentLink(tipJar.paymentLinkId);
          } catch (_) {
            // Best effort — the new link matters more than retiring the old.
          }
        } else {
          // Name / message only: edit the product + link in place, link lives.
          await requests?.updateTipJarDetails(
            productId: tipJar.productId,
            paymentLinkId: tipJar.paymentLinkId,
            displayName: name,
            thankYouMessage: thankYou,
          );
          newTipJar = tipJar.copyWith(
            displayName: name,
            currency: currency,
            thankYouMessage: thankYou,
          );
        }
        await notifier.setTipJar(newTipJar);
      }

      // ------------------------------------------------------------- relay
      if (relayJar != null) {
        final secret = app.relaySecret;
        final updated = relayJar.copyWith(
          artistName: name,
          currency: currency,
          message: thankYou,
        );
        if (secret != null) {
          final client = RelayClient();
          try {
            await client.updateJar(
              jar: updated,
              secret: secret,
              artistName: name,
              message: thankYou,
              stripeUrl: newTipJar?.url ?? app.tipJar?.url,
            );
          } finally {
            client.close();
          }
        }
        await notifier.updateRelayJarLocal(updated);
      }

      // Registry name (the switcher's label) + re-affirm both jar names.
      await notifier.renameBand(name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account details updated')));
        Navigator.of(context).pop();
      }
    } on StripeApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } on StripeNetworkException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on RelayApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } on RelayNetworkException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final currencyReplacesLink = app.tipJar != null &&
        !(app.tipJar!.isDemo) &&
        app.tipJar!.currency != _currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Account details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'The name, currency and thank-you message you set at sign-up. '
                'Changes sync to your Stripe link and your tip page.',
                style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 14,
                    height: 1.5,
                    color: c.textSecondary),
              ),
              const SizedBox(height: 20),
              LtCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel('Artist or band name'),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          hintText: 'The Midnight Foxes'),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Fans see this on your tip page, the stage and posters.',
                      style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12,
                          color: c.textMuted),
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
                        if (picked != null) {
                          setState(() {
                            _currency = picked;
                            _error = null;
                          });
                        }
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
                    const SizedBox(height: 16),
                    const _FieldLabel('Thank-you message'),
                    TextField(
                      controller: _thanksController,
                      maxLength: 200,
                      maxLines: 2,
                      minLines: 1,
                      buildCounter: (context,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      decoration: const InputDecoration(counterText: ''),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Shown after a Stripe tip and on your tip page.',
                      style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12,
                          color: c.textMuted),
                    ),
                  ],
                ),
              ),
              if (currencyReplacesLink) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.danger.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 20, color: c.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Changing the currency creates a new Stripe link — '
                          'the old Stripe-only QR stops working.',
                          style: TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 13,
                              height: 1.4,
                              color: c.text),
                        ),
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
                label: 'Save changes',
                busy: _busy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
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
