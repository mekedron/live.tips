import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/deep_links.dart';
import '../../core/theme.dart';
import '../../data/firebase/device_registry.dart';
import '../../data/firebase/link_codes.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/device_providers.dart';
import '../../widgets/lt_ui.dart';

/// Whether this build can show a camera. mobile_scanner also runs on macOS
/// and the web, but a laptop webcam pointed at a phone is a worse experience
/// than typing 22 characters — those platforms get the paste field instead.
bool get _cameraAvailable =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

enum _Phase { scanning, redeeming, waiting, signingIn, done, failed }

/// Device B: scan (or paste) the code the signed-in device shows, then wait
/// for its owner to confirm. On confirmation the server hands over a custom
/// token, this device signs in with it, registers itself, and drops back into
/// the app — already on the account.
class ScanDeviceScreen extends ConsumerStatefulWidget {
  const ScanDeviceScreen({super.key, this.initialCode});

  /// Set when a universal link (`…/link#c=…`) brought us here: the code is
  /// already known and the camera never opens.
  final String? initialCode;

  @override
  ConsumerState<ScanDeviceScreen> createState() => _ScanDeviceScreenState();
}

class _ScanDeviceScreenState extends ConsumerState<ScanDeviceScreen> {
  final _manual = TextEditingController();
  MobileScannerController? _scanner;
  _Phase _phase = _Phase.scanning;
  LinkCodeErrorKind? _error;

  /// Set once a code is in flight, so a camera that keeps firing frames (or a
  /// double-tapped Continue) cannot start a second handshake.
  bool _busy = false;

  bool _manualMode = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCode;
    if (initial != null) {
      unawaited(_redeem(initial));
      return;
    }
    if (_cameraAvailable) {
      _scanner = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
    } else {
      _manualMode = true;
    }
  }

  @override
  void dispose() {
    _manual.dispose();
    unawaited(_scanner?.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final code = parseLinkCode(raw);
      if (code != null) {
        unawaited(_redeem(code));
        return;
      }
    }
  }

  void _submitManual() {
    final code = parseLinkCode(_manual.text);
    if (code == null) {
      setState(() {
        _error = LinkCodeErrorKind.notFound;
        _phase = _Phase.failed;
      });
      return;
    }
    unawaited(_redeem(code));
  }

  Future<void> _redeem(String code) async {
    if (_busy) return;
    _busy = true;
    unawaited(_scanner?.stop());
    setState(() {
      _phase = _Phase.redeeming;
      _error = null;
    });
    final service = ref.read(linkCodeServiceProvider);
    try {
      final description = await describeThisDevice();
      final nonce = await service.redeemLinkCode(
        code: code,
        deviceName: description.name,
        devicePlatform: description.platform,
        // Name this device, so a confirm re-admits it if the account ever
        // revoked it (#36) — this ceremony is the only way back in.
        deviceId: ref.read(deviceRegistryProvider).deviceId,
      );
      if (!mounted) return;
      setState(() => _phase = _Phase.waiting);

      // Blocks until the other device's owner taps confirm (or the code dies).
      // keepWaiting stops the poll the instant this screen is disposed: leaving
      // while waiting must not collect (and thereby burn) a token this device
      // will never use — see [LinkCodeService.awaitToken].
      final token = await service.awaitToken(
        code: code,
        nonce: nonce,
        keepWaiting: () => mounted,
      );
      if (!mounted) return;
      setState(() => _phase = _Phase.signingIn);

      final user = await ref
          .read(authControllerProvider.notifier)
          .signInWithCustomToken(token);
      if (user == null) {
        throw const LinkCodeError(LinkCodeErrorKind.unknown, 'sign-in failed');
      }
      // Claim our place in the account's device list before leaving — the
      // Security screen on the other device should list us immediately.
      await ref.read(deviceRegistryProvider).registerThisDevice(user.uid);
      if (!mounted) return;
      setState(() => _phase = _Phase.done);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      // The directory/repository providers already switched to the account —
      // drop the whole linking stack and let the shell rebuild on it.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on LinkCodeError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.kind;
        _phase = _Phase.failed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = LinkCodeErrorKind.unknown;
        _phase = _Phase.failed;
      });
    } finally {
      _busy = false;
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _phase = _Phase.scanning;
      _manual.clear();
      _manualMode = !_cameraAvailable;
    });
    unawaited(_scanner?.start());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings.scan_device.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: switch (_phase) {
              _Phase.scanning => _scanBody(context),
              _Phase.redeeming =>
                _progress(context, s.t('settings.scan_device.redeeming')),
              _Phase.waiting => _waitingBody(context),
              _Phase.signingIn =>
                _progress(context, s.t('settings.scan_device.signing_in')),
              _Phase.done => _doneBody(context),
              _Phase.failed => _errorBody(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _scanBody(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final scanner = _scanner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _manualMode
              ? s.t('settings.scan_device.manual_intro')
              : s.t('settings.scan_device.intro'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontBody,
            fontSize: 13.5,
            height: 1.45,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        if (!_manualMode && scanner != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1,
              child: MobileScanner(
                controller: scanner,
                onDetect: _onDetect,
                errorBuilder: (context, error) => Container(
                  color: c.chip,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    s.t('settings.scan_device.camera_unavailable'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kFontBody,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          LtCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _manual,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: s.t('settings.scan_device.manual_label'),
                    hintText: 'https://tip.live.tips/link#c=…',
                  ),
                  onSubmitted: (_) => _submitManual(),
                ),
                const SizedBox(height: 14),
                LtPrimaryButton(
                  label: s.t('settings.scan_device.manual_submit'),
                  onPressed: _submitManual,
                ),
              ],
            ),
          ),
        if (_cameraAvailable) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _manualMode = !_manualMode),
            child: Text(_manualMode
                ? s.t('settings.scan_device.use_camera')
                : s.t('settings.scan_device.manual_hint')),
          ),
        ],
      ],
    );
  }

  Widget _waitingBody(BuildContext context) {
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
          const SizedBox(height: 16),
          Text(
            s.t('settings.scan_device.waiting_title'),
            textAlign: TextAlign.center,
            style: outfitStyle(18, c.text, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            s.t('settings.scan_device.waiting_body'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13,
              height: 1.45,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(BuildContext context, String message) {
    final c = context.lt;
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
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: kFontBody, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _doneBody(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    return LtCard(
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, size: 40, color: c.success),
          const SizedBox(height: 12),
          Text(
            s.t('settings.scan_device.success'),
            textAlign: TextAlign.center,
            style: outfitStyle(18, c.text, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _errorBody(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final message = switch (_error) {
      LinkCodeErrorKind.notFound => s.t('settings.scan_device.error_not_found'),
      LinkCodeErrorKind.failedPrecondition =>
        s.t('settings.scan_device.error_expired'),
      LinkCodeErrorKind.resourceExhausted =>
        s.t('settings.scan_device.error_rate'),
      LinkCodeErrorKind.invalidArgument =>
        s.t('settings.scan_device.error_invalid'),
      LinkCodeErrorKind.network => s.t('settings.scan_device.error_network'),
      _ => s.t('settings.scan_device.error_generic'),
    };
    return LtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.error_outline_rounded, size: 34, color: c.textMuted),
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
          const SizedBox(height: 18),
          LtPrimaryButton(
            label: s.t('settings.scan_device.retry'),
            icon: Icons.refresh_rounded,
            onPressed: _retry,
          ),
        ],
      ),
    );
  }
}
