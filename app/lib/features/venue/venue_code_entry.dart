import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/deep_links.dart';
import '../../core/theme.dart';
import '../../data/firebase/link_codes.dart';
import '../../l10n/app_localizations.dart';
import '../../state/device_providers.dart';
import '../../widgets/lt_ui.dart';

/// Same platform heuristic as the phone-side scanner: a camera is only worth
/// opening on iOS/Android — everywhere else the typed code is the whole
/// story. A provider so tests (whose defaultTargetPlatform claims android
/// with no camera plugin behind it) can switch the scanner off.
final venueCameraAvailableProvider = Provider<bool>((ref) =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android));

enum _Phase { idle, redeeming, waiting, finishing, failed }

/// The tablet's half of the add-device handshake, shared by the venue
/// sign-in screen and the re-approval gate: scan the QR the artist's phone
/// shows — or type the code under it, first-class, because a bar tablet's
/// camera is often the least reliable part of the room — then redeem, wait
/// for the artist's confirm tap, and hand the collected token to [onToken].
///
/// [onToken] finishes the flow its own way (sign in, or just verify the
/// uid). It returns null on success or an already-localized error to show;
/// a throw lands on the generic error card.
class VenueCodeEntry extends ConsumerStatefulWidget {
  const VenueCodeEntry({super.key, required this.onToken});

  final Future<String?> Function(String token) onToken;

  @override
  ConsumerState<VenueCodeEntry> createState() => _VenueCodeEntryState();
}

class _VenueCodeEntryState extends ConsumerState<VenueCodeEntry> {
  final _manual = TextEditingController();
  MobileScannerController? _scanner;
  _Phase _phase = _Phase.idle;
  String? _error;

  /// Set once a code is in flight — a camera that keeps firing frames (or a
  /// double-tapped button) must not start a second handshake.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(venueCameraAvailableProvider)) {
      _scanner = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
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
        _error = context.s.t('venue.code_entry.error_invalid');
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
    try {
      final service = ref.read(linkCodeServiceProvider);
      final description = await ref.read(describeDeviceProvider)();
      final nonce = await service.redeemLinkCode(
        code: code,
        deviceName: description.name,
        devicePlatform: description.platform,
        // The tablet names itself too: a venue device the artist revoked at
        // the end of a night is re-admitted by their confirm, and by nothing
        // else (#36).
        deviceId: ref.read(deviceRegistryProvider).deviceId,
      );
      if (!mounted) return;
      setState(() => _phase = _Phase.waiting);
      // Blocks until the artist taps confirm on their phone (or the code dies).
      // keepWaiting stops the poll the instant this widget is disposed: backing
      // out of "Confirm on your phone" must not collect (and thereby burn) a
      // token nobody is here to use — see [LinkCodeService.awaitToken].
      final token = await service.awaitToken(
        code: code,
        nonce: nonce,
        keepWaiting: () => mounted,
      );
      if (!mounted) return;
      setState(() => _phase = _Phase.finishing);
      final error = await widget.onToken(token);
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _error = error;
          _phase = _Phase.failed;
        });
      }
      // On success the parent flips whatever gate hosts this widget.
    } on LinkCodeError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _linkErrorText(e.kind);
        _phase = _Phase.failed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.s.t('venue.code_entry.error_generic');
        _phase = _Phase.failed;
      });
    } finally {
      _busy = false;
    }
  }

  String _linkErrorText(LinkCodeErrorKind kind) {
    final s = context.s;
    return switch (kind) {
      LinkCodeErrorKind.notFound => s.t('venue.code_entry.error_not_found'),
      LinkCodeErrorKind.failedPrecondition =>
        s.t('venue.code_entry.error_expired'),
      LinkCodeErrorKind.resourceExhausted =>
        s.t('venue.code_entry.error_rate'),
      LinkCodeErrorKind.invalidArgument =>
        s.t('venue.code_entry.error_invalid'),
      LinkCodeErrorKind.network => s.t('venue.code_entry.error_network'),
      _ => s.t('venue.code_entry.error_generic'),
    };
  }

  void _retry() {
    setState(() {
      _error = null;
      _phase = _Phase.idle;
      _manual.clear();
    });
    unawaited(_scanner?.start());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return switch (_phase) {
      _Phase.idle => _idleBody(context),
      _Phase.redeeming => _progress(context, s.t('venue.code_entry.redeeming')),
      _Phase.waiting => _waitingBody(context),
      _Phase.finishing =>
        _progress(context, s.t('venue.code_entry.finishing')),
      _Phase.failed => _errorBody(context),
    };
  }

  Widget _idleBody(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final scanner = _scanner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scanner != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1.4,
              child: MobileScanner(
                controller: scanner,
                onDetect: _onDetect,
                errorBuilder: (context, error) => Container(
                  color: c.chip,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    s.t('venue.code_entry.camera_unavailable'),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontFamily: kFontBody, color: c.textSecondary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // The typed code is a peer of the camera, not a fallback: it is
        // always on screen, ready for the phone whose QR won't focus.
        LtCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.t('venue.code_entry.manual_title'),
                style: outfitStyle(14.5, c.text, weight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _manual,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: s.t('venue.code_entry.manual_label'),
                ),
                onSubmitted: (_) => _submitManual(),
              ),
              const SizedBox(height: 12),
              LtPrimaryButton(
                label: s.t('venue.code_entry.manual_submit'),
                onPressed: _submitManual,
              ),
            ],
          ),
        ),
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
            s.t('venue.code_entry.waiting_title'),
            textAlign: TextAlign.center,
            style: outfitStyle(18, c.text, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            s.t('venue.code_entry.waiting_body'),
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

  Widget _errorBody(BuildContext context) {
    final c = context.lt;
    return LtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.error_outline_rounded, size: 34, color: c.textMuted),
          const SizedBox(height: 12),
          Text(
            _error ?? context.s.t('venue.code_entry.error_generic'),
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
            label: context.s.t('venue.code_entry.retry'),
            icon: Icons.refresh_rounded,
            onPressed: _retry,
          ),
        ],
      ),
    );
  }
}
