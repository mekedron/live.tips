import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/device_kind.dart';
import '../../state/device_providers.dart';
import '../../state/venue_providers.dart';
import '../settings/scan_device_screen.dart';

/// Invisible root widget that turns a universal link
/// (`https://tip.live.tips/link#c=<code>`) into the redeem flow: opening the
/// QR from a photo, an AirDrop, or a browser lands in exactly the screen the
/// camera would have led to, with the code already in hand.
///
/// One screen at a time — a second link while the first is still open is
/// dropped rather than stacking redeem screens on top of each other.
class DeepLinkGate extends ConsumerStatefulWidget {
  const DeepLinkGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkGate> createState() => _DeepLinkGateState();
}

class _DeepLinkGateState extends ConsumerState<DeepLinkGate> {
  bool _redeeming = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(deepLinkCodesProvider, (previous, next) {
      final code = next.value;
      if (code != null) _openRedeem(code);
    });
    return widget.child;
  }

  void _openRedeem(String code) {
    // Not on a venue device: its ONE way in is the venue sign-in screen,
    // with the identity check and the 12-hour clock behind it. A deep link
    // that signed in around that ceremony would put an account on a public
    // tablet with no ceiling and no banner.
    if (ref.read(deviceKindProvider) == DeviceKind.venue) return;
    if (_redeeming) return;
    _redeeming = true;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => ScanDeviceScreen(initialCode: code),
        ))
        .whenComplete(() => _redeeming = false);
  }
}
