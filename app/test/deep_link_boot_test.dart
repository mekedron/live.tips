import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/deep_links.dart';

/// The web bug: `DeepLinks` read `Uri.base` lazily, long after Flutter's URL
/// strategy had normalized the address bar and dropped the `#c=…` fragment the
/// add-device code rides in. Every scanned QR opened the app and did nothing.
///
/// main() now captures the launch URL before anything can touch it and hands
/// it in — this is the seam that makes that testable.
void main() {
  test('a boot URL with the code in the fragment yields the code', () async {
    const url = 'https://tip.live.tips/link#c=abcdefghijklmnopqrstuv';
    final codes =
        await DeepLinks(bootUrl: url).codes().take(1).toList();

    expect(codes, ['abcdefghijklmnopqrstuv']);
  });

  test('no boot URL yields nothing at all', () async {
    expect(await DeepLinks().codes().isEmpty, isTrue);
  });

  test('a boot URL that is not one of ours yields nothing', () async {
    final codes = await DeepLinks(
      bootUrl: 'https://example.com/link#c=abcdefghijklmnopqrstuv',
    ).codes().toList();

    expect(codes, isEmpty);
  });
}
