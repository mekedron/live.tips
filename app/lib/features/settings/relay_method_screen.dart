import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/relay/relay_client.dart';
import '../../domain/relay_jar.dart';
import '../../domain/tip_method.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/enum_labels.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../onboarding/relay_setup_screen.dart'
    show parseRelayMethodValue, relayMethodHint;

/// Edits a single connected-mode payment method — Revolut, MobilePay or Monzo
/// — on its own full-page screen (back arrow), mirroring the Stripe key editor.
/// The band's name and currency are set in Account Details, so they don't
/// appear here. The red trash button clears the field and saves, which is how
/// an artist removes a method; clearing the last one disconnects the tip page.
class RelayMethodScreen extends ConsumerStatefulWidget {
  const RelayMethodScreen({super.key, required this.method})
    : assert(method != TipMethod.stripe);

  final TipMethod method;

  @override
  ConsumerState<RelayMethodScreen> createState() => _RelayMethodScreenState();
}

/// The atom this method currently holds on [jar], or null when it's unset.
String? _jarValue(RelayJar? jar, TipMethod method) => switch (method) {
  TipMethod.revolut => (jar?.hasRevolut ?? false) ? jar!.revolutUsername : null,
  TipMethod.mobilepay =>
    (jar?.hasMobilePay ?? false) ? jar!.mobilepayBoxId : null,
  TipMethod.monzo => (jar?.hasMonzo ?? false) ? jar!.monzoUsername : null,
  TipMethod.stripe => null,
};

class _RelayMethodScreenState extends ConsumerState<RelayMethodScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool _removing = false;
  String? _error;

  /// i18n keys are suffixed with the method's wire name, so one lookup serves
  /// every method — adding one means adding strings, not another branch.
  String get _wire => widget.method.wire;

  @override
  void initState() {
    super.initState();
    _controller.text =
        _jarValue(ref.read(appStateProvider).relayJar, widget.method) ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        _controller.text = text;
        _error = null;
      });
    }
  }

  /// Clears the field and saves — the removal affordance, from the separate
  /// "Remove …" button so every method screen removes the same way.
  Future<void> _remove() async {
    _controller.clear();
    await _save(removing: true);
  }

  Future<void> _save({bool removing = false}) async {
    final s = context.s;
    final methodLabel = widget.method.l10nLabel(context);
    final app = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final jar = app.relayJar;

    // Resolve this method's new value from the field. An empty field clears it.
    String? value;
    final raw = _controller.text.trim();
    if (raw.isNotEmpty) {
      value = parseRelayMethodValue(widget.method, raw);
      if (value == null) {
        setState(
          () => _error = context.s.t(
            'settings.relay_method.error_${_wire}_invalid',
          ),
        );
        return;
      }
    }

    // The resulting method set after this edit — the others are untouched.
    final values = {
      for (final m in TipMethod.relayMethods)
        m: m == widget.method ? value : _jarValue(jar, m),
    };
    final allEmpty = values.values.every((v) => v == null || v.isEmpty);

    // Nothing to add for a band with no tip page and an empty field.
    if (jar == null && value == null) {
      Navigator.of(context).pop();
      return;
    }

    // Clearing the last method retires the whole tip page — confirm first.
    if (jar != null && allEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.s.t('settings.relay_method.disconnect_title')),
          content: Text(context.s.t('settings.relay_method.disconnect_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.s.t('settings.relay_method.cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                context.s.t('settings.relay_method.disconnect_confirm'),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() {
      _busy = true;
      _removing = removing;
      _error = null;
    });
    final client = RelayClient();
    try {
      if (jar == null) {
        // First tip-page method for this band: register a fresh jar. Name,
        // currency and message ride along from what's already configured.
        final result = await client.createJar(
          artistName: app.displayName,
          currency: app.currency,
          message: app.tipJar?.thankYouMessage,
          stripeUrl: app.tipJar?.url,
          revolutUsername: values[TipMethod.revolut],
          mobilepayBoxId: values[TipMethod.mobilepay],
          monzoUsername: values[TipMethod.monzo],
        );
        await notifier.setRelayJar(result.jar, result.secret);
        _finish(s.t('settings.relay_method.created_snack'));
      } else if (allEmpty) {
        final secret = app.relaySecret;
        if (secret != null) {
          try {
            await client.deleteJar(jarId: jar.jarId, secret: secret);
          } catch (_) {
            // Offline or already gone — the local forget still proceeds.
          }
        }
        await notifier.clearRelayJar();
        _finish(s.t('settings.relay_method.disconnected_snack'));
      } else {
        // Build the jar explicitly so a cleared method becomes null (copyWith
        // can't null a field), then push the full profile to the relay.
        final updated = RelayJar(
          jarId: jar.jarId,
          donateUrl: jar.donateUrl,
          artistName: jar.artistName,
          currency: jar.currency,
          message: jar.message,
          revolutUsername: values[TipMethod.revolut],
          mobilepayBoxId: values[TipMethod.mobilepay],
          monzoUsername: values[TipMethod.monzo],
          createdAtMs: jar.createdAtMs,
        );
        await client.updateJar(
          jar: updated,
          secret: app.relaySecret!,
          artistName: jar.artistName,
          message: jar.message,
          stripeUrl: app.tipJar?.url,
        );
        await notifier.updateRelayJarLocal(updated);
        _finish(
          value == null
              ? s.t('settings.relay_method.method_removed_snack', {
                  'method': methodLabel,
                })
              : s.t('settings.relay_method.method_saved_snack', {
                  'method': methodLabel,
                }),
        );
      }
    } on RelayApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } on RelayNetworkException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      client.close();
      if (mounted) {
        setState(() {
          _busy = false;
          _removing = false;
        });
      }
    }
  }

  void _finish(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop();
  }

  Widget _pasteButton(LtColors c) => IconButton(
    tooltip: context.s.t('settings.relay_method.paste_tooltip'),
    icon: Icon(Icons.content_paste_rounded, size: 20, color: c.accent),
    onPressed: _pasteFromClipboard,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final jar = ref.watch(appStateProvider).relayJar;
    final currentlySet = _jarValue(jar, widget.method) != null;
    // A pasted share link is shown monospace so a long URL stays readable;
    // Revolut takes a bare handle behind an `@` instead.
    final linkHint = relayMethodHint(widget.method);
    return Scaffold(
      appBar: AppBar(title: Text(widget.method.l10nLabel(context))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                context.s.t('settings.relay_method.intro_$_wire'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              LtCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldLabel(
                      context.s.t('settings.relay_method.label_$_wire'),
                    ),
                    TextField(
                      controller: _controller,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: linkHint == null
                          ? null
                          : const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13.5,
                            ),
                      decoration: InputDecoration(
                        prefixText: linkHint == null ? '@' : null,
                        hintText:
                            linkHint ??
                            context.s.t('settings.relay_method.hint_revolut'),
                        errorText: _error,
                        errorMaxLines: 3,
                        suffixIcon: _pasteButton(c),
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.s.t('settings.relay_method.help_$_wire'),
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12,
                        height: 1.4,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LtPrimaryButton(
                label: context.s.t('settings.relay_method.save_button'),
                busy: _busy && !_removing,
                onPressed: _busy ? null : _save,
              ),
              if (currentlySet) ...[
                const SizedBox(height: 12),
                LtDangerButton(
                  label: context.s.t('settings.relay_method.remove_button', {
                    'method': widget.method.l10nLabel(context),
                  }),
                  onPressed: _busy ? null : _remove,
                  busy: _removing,
                ),
              ],
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
