import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves screenshots emitted by integration tests into .validation/
/// (gitignored — local verification artifacts only).
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('.validation/$name.png')
        ..createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      return true;
    },
  );
}
