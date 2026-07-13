import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/firebase/link_codes.dart';
import '../../l10n/app_localizations.dart';
import '../../state/device_providers.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/qr_card.dart';

/// Device A: mint a link code, show it as a QR, and watch it come to life.
///
/// The QR carries the code and nothing else — no nonce, no token. A stranger
/// who photographs the screen can redeem the code, but redeeming only parks it
/// in `claimed`: this screen then shows WHO is asking, and nobody gets in until
/// the artist taps confirm. That tap is the whole security model, so the copy
/// asks the question honestly ("is that device in front of you, right now?").
class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  LinkCode? _code;

  /// Held, not re-derived per build: the countdown rebuilds this screen every
  /// second, and a fresh stream each time would tear down and re-open the
  /// Firestore listener on every tick.
  Stream<LinkCodeState>? _codeStream;
  LinkCodeErrorKind? _error;
  bool _creating = true;
  bool _confirming = false;
  bool _denied = false;
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    unawaited(_create());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _creating = true;
      _error = null;
      _denied = false;
      _code = null;
      _codeStream = null;
    });
    try {
      final service = ref.read(linkCodeServiceProvider);
      final code = await service.createLinkCode();
      if (!mounted) return;
      setState(() {
        _code = code;
        _codeStream = service.watchLinkCode(code.code);
        _creating = false;
      });
      _startTicker();
    } on LinkCodeError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.kind;
        _creating = false;
      });
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    void tick() {
      final code = _code;
      if (code == null) return;
      final left = DateTime.fromMillisecondsSinceEpoch(code.expiresAtMs)
          .difference(DateTime.now());
      if (!mounted) return;
      setState(() => _remaining = left.isNegative ? Duration.zero : left);
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  bool get _expired => _code != null && _remaining == Duration.zero;

  Future<void> _confirm(String code) async {
    setState(() => _confirming = true);
    try {
      await ref.read(linkCodeServiceProvider).confirmLinkCode(code);
    } on LinkCodeError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.kind);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  /// "That's not my device." Nothing to call: an unconfirmed code is inert and
  /// dies on its own within two minutes. We stop showing it and stop watching.
  void _deny() {
    _ticker?.cancel();
    setState(() {
      _denied = true;
      _code = null;
      _codeStream = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings.add_device.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: _body(context),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_creating) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) return _errorCard(context, _error!);
    if (_denied) return _deniedCard(context);
    final code = _code;
    if (code == null) return _errorCard(context, LinkCodeErrorKind.unknown);
    if (_expired) return _expiredCard(context);

    // The code is live: the doc tells us the moment somebody scans it.
    return StreamBuilder<LinkCodeState>(
      stream: _codeStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        return switch (state?.status) {
          LinkCodeStatus.claimed => _claimedCard(context, code, state!),
          LinkCodeStatus.confirmed => _waitingCard(context),
          LinkCodeStatus.used => _successCard(context, state!),
          LinkCodeStatus.expired => _expiredCard(context),
          _ => _qrCard(context, code),
        };
      },
    );
  }

  Widget _qrCard(BuildContext context, LinkCode code) {
    final c = context.lt;
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.t('settings.add_device.intro'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 13.5,
            height: 1.45,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        LtCard(
          child: Column(
            children: [
              QrBlock(data: code.url),
              const SizedBox(height: 14),
              LtPill(
                icon: Icons.timer_outlined,
                label: s.t('settings.add_device.expires_in', {
                  'time': _mmss(_remaining),
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LtSectionLabel(s.t('settings.add_device.code_label')),
        const SizedBox(height: 6),
        SelectableText(
          code.code,
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 13,
            letterSpacing: 0.6,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _claimedCard(BuildContext context, LinkCode code, LinkCodeState state) {
    final c = context.lt;
    final s = context.s;
    final name = state.requesterName?.trim().isNotEmpty == true
        ? state.requesterName!
        : s.t('settings.security.unnamed_device');
    final platform = state.requesterPlatform ?? '';
    return LtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.shield_outlined, size: 36, color: c.accent),
          const SizedBox(height: 12),
          Text(
            s.t('settings.add_device.claimed_title', {'name': name}),
            textAlign: TextAlign.center,
            style: outfitStyle(19, c.text, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            s.t('settings.add_device.claimed_body', {
              'name': name,
              'platform': platform,
            }),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13,
              height: 1.45,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          // This tap is the ONLY thing between that device and the whole
          // account — and the name above is whatever the device claims to
          // be. Say both plainly, especially for a tablet the artist does
          // not own; do not soften it.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.warningContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: c.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.t('settings.add_device.claimed_unverified'),
                        style: outfitStyle(12.5, c.text,
                            weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.t('settings.add_device.claimed_risk'),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    height: 1.45,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LtPrimaryButton(
            label: s.t('settings.add_device.confirm'),
            icon: Icons.check_rounded,
            busy: _confirming,
            onPressed: () => _confirm(code.code),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _confirming ? null : _deny,
            child: Text(s.t('settings.add_device.deny')),
          ),
        ],
      ),
    );
  }

  Widget _waitingCard(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    return LtCard(
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 14),
          Text(
            s.t('settings.add_device.finishing'),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: kFontBody, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _successCard(BuildContext context, LinkCodeState state) {
    final c = context.lt;
    final s = context.s;
    final name = state.requesterName?.trim().isNotEmpty == true
        ? state.requesterName!
        : s.t('settings.security.unnamed_device');
    return LtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_rounded, size: 40, color: c.success),
          const SizedBox(height: 12),
          Text(
            s.t('settings.add_device.success_title'),
            textAlign: TextAlign.center,
            style: outfitStyle(19, c.text, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            s.t('settings.add_device.success_body', {'name': name}),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13,
              height: 1.45,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          LtPrimaryButton(
            label: s.t('settings.add_device.done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _expiredCard(BuildContext context) => _noticeCard(
        context,
        icon: Icons.timer_off_rounded,
        message: context.s.t('settings.add_device.expired'),
        actionLabel: context.s.t('settings.add_device.regenerate'),
        onAction: _create,
      );

  Widget _deniedCard(BuildContext context) => _noticeCard(
        context,
        icon: Icons.block_rounded,
        message: context.s.t('settings.add_device.denied'),
        actionLabel: context.s.t('settings.add_device.regenerate'),
        onAction: _create,
      );

  Widget _errorCard(BuildContext context, LinkCodeErrorKind kind) {
    final s = context.s;
    final message = switch (kind) {
      LinkCodeErrorKind.failedPrecondition =>
        s.t('settings.add_device.error_anonymous'),
      LinkCodeErrorKind.resourceExhausted =>
        s.t('settings.add_device.error_too_many'),
      LinkCodeErrorKind.unauthenticated =>
        s.t('settings.add_device.error_signed_out'),
      _ => s.t('settings.add_device.error_generic'),
    };
    return _noticeCard(
      context,
      icon: Icons.error_outline_rounded,
      message: message,
      // An anonymous account cannot mint a code however many times it retries.
      actionLabel: kind == LinkCodeErrorKind.failedPrecondition
          ? null
          : s.t('settings.add_device.regenerate'),
      onAction: _create,
    );
  }

  Widget _noticeCard(
    BuildContext context, {
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final c = context.lt;
    return LtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 34, color: c.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13.5,
              height: 1.45,
              color: c.textSecondary,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            LtPrimaryButton(
              label: actionLabel,
              icon: Icons.refresh_rounded,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

String _mmss(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
