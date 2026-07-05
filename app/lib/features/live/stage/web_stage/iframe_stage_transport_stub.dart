import 'stage_bridge_codec.dart';
import 'stage_transport.dart';

/// Non-web stub, selected everywhere except Flutter Web by the conditional
/// import in stage_transport.dart. `stageTransportFactoryProvider` only ever
/// builds the real (web) implementation when `kIsWeb`, so reaching this
/// constructor means that guard is broken — fail loudly rather than silently
/// half-working.
class IframeStageTransport extends StageTransport {
  IframeStageTransport() {
    throw UnsupportedError(
        'IframeStageTransport is web-only (see iframe_stage_transport_web.dart)');
  }

  /// Mirrors the real (web) implementation's API so call sites like
  /// `web_stage.dart` type-check under both conditional-import branches.
  String get viewType => throw UnsupportedError('web-only');

  @override
  Future<void> send(StageOutMessage msg) async {}

  @override
  Future<void> reload() async {}
}
