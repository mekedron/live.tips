import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/tip_method.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/enum_labels.dart';
import '../../state/onboarding_draft.dart';
import '../../widgets/lt_ui.dart';
import 'onboarding_flow.dart';
import 'relay_setup_screen.dart'
    show extractMobilePayBoxId, mobilePayCurrencyError;

/// One onboarding step for a relay method — Revolut or MobilePay. The value is
/// stashed in the draft (no jar is created yet; the final screen registers one
/// tip page from every method at once). "Save" validates and advances; "Skip"
/// advances without setting the method, so a mis-tap on the method picker is
/// painless.
class OnboardingMethodScreen extends ConsumerStatefulWidget {
  const OnboardingMethodScreen({super.key, required this.method})
    : assert(method != TipMethod.stripe);

  final TipMethod method;

  @override
  ConsumerState<OnboardingMethodScreen> createState() =>
      _OnboardingMethodScreenState();
}

class _OnboardingMethodScreenState
    extends ConsumerState<OnboardingMethodScreen> {
  final _controller = TextEditingController();
  String? _error;

  bool get _isRevolut => widget.method == TipMethod.revolut;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingDraftProvider);
    _controller.text =
        (_isRevolut ? draft?.revolutUsername : draft?.mobilepayBoxId) ?? '';
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

  void _skip() {
    // Leave this method unset in the draft, then move on.
    ref
        .read(onboardingDraftProvider.notifier)
        .update(
          (d) => _isRevolut
              ? d.copyWith(revolutUsername: '')
              : d.copyWith(mobilepayBoxId: ''),
        );
    pushOnboardingStep(context, ref, after: widget.method);
  }

  void _save() {
    final draft = ref.read(onboardingDraftProvider);
    if (_isRevolut) {
      final raw = _controller.text.trim().replaceFirst(RegExp(r'^@+'), '');
      if (raw.isEmpty) {
        _skip();
        return;
      }
      if (!RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch(raw)) {
        setState(
          () => _error = context.s.t('onboarding.method.revolut_invalid'),
        );
        return;
      }
      ref
          .read(onboardingDraftProvider.notifier)
          .update((d) => d.copyWith(revolutUsername: raw));
    } else {
      final raw = _controller.text.trim();
      if (raw.isEmpty) {
        _skip();
        return;
      }
      final box = extractMobilePayBoxId(raw);
      if (box == null) {
        setState(
          () => _error = context.s.t('onboarding.method.mobilepay_invalid'),
        );
        return;
      }
      final curErr = mobilePayCurrencyError(
        draft?.currency ?? 'eur',
        context: context,
      );
      if (curErr != null) {
        setState(() => _error = curErr);
        return;
      }
      ref
          .read(onboardingDraftProvider.notifier)
          .update((d) => d.copyWith(mobilepayBoxId: box));
    }
    pushOnboardingStep(context, ref, after: widget.method);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final draft = ref.watch(onboardingDraftProvider);
    final step = draft?.stepOfMethod(widget.method);
    final total = draft?.totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.method.l10nLabel(context)),
        actions: [
          if (step != null && total != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: LtPill(
                  label: context.s.t('onboarding.method.step_pill', {
                    'step': step,
                    'total': total,
                  }),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (step != null && total != null) ...[
                LtProgressSegments(total: total, filled: step),
                const SizedBox(height: 16),
              ],
              Text(
                _isRevolut
                    ? context.s.t('onboarding.method.intro_revolut')
                    : context.s.t('onboarding.method.intro_mobilepay'),
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
                      _isRevolut
                          ? context.s.t('onboarding.method.revolut_label')
                          : context.s.t('onboarding.method.mobilepay_label'),
                    ),
                    _isRevolut
                        ? TextField(
                            controller: _controller,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              prefixText: '@',
                              hintText: context.s.t(
                                'onboarding.method.revolut_hint',
                              ),
                              errorText: _error,
                              errorMaxLines: 3,
                              suffixIcon: _pasteButton(c),
                            ),
                            onChanged: (_) {
                              if (_error != null) setState(() => _error = null);
                            },
                            onSubmitted: (_) => _save(),
                          )
                        : TextField(
                            controller: _controller,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'https://qr.mobilepay.fi/box/…',
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
                      _isRevolut
                          ? context.s.t('onboarding.method.revolut_help')
                          : context.s.t('onboarding.method.mobilepay_help'),
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
                label: context.s.t('onboarding.method.save'),
                onPressed: _save,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _skip,
                child: Text(
                  context.s.t('onboarding.method.skip'),
                  style: outfitStyle(14, c.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pasteButton(LtColors c) => IconButton(
    tooltip: context.s.t('onboarding.method.paste_tooltip'),
    icon: Icon(Icons.content_paste_rounded, size: 20, color: c.accent),
    onPressed: _pasteFromClipboard,
  );
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
