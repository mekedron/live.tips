import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/custom_token.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/features/venue/venue_code_entry.dart';
import 'package:live_tips/features/venue/venue_reapproval_screen.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';
import 'venue_sign_in_test.dart' show FakeLinkCodeService, fakeCustomToken;

/// Switching profiles on a venue device re-runs the approval cycle — and
/// only the SAME account's approval counts. The uid is read off the
/// collected token; a different approver changes nothing.
void main() {
  test('uidOfCustomToken reads the claim and refuses junk', () {
    expect(uidOfCustomToken(fakeCustomToken('uid_x')), 'uid_x');
    expect(uidOfCustomToken('not-a-jwt'), isNull);
    expect(uidOfCustomToken('a.b.c'), isNull);
    expect(uidOfCustomToken(''), isNull);
  });

  Future<({List<bool?> results, FakeLinkCodeService link})> pumpGate(
    WidgetTester tester, {
    required String tokenUid,
    required String expectedUid,
  }) async {
    final store = await seededStore();
    final link = FakeLinkCodeService(token: fakeCustomToken(tokenUid));
    final results = <bool?>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(FakeSecureStore()),
          linkCodeServiceProvider.overrideWithValue(link),
          venueCameraAvailableProvider.overrideWithValue(false),
          describeDeviceProvider.overrideWithValue(() async =>
              const DeviceDescription(name: 'Bar iPad', platform: 'android')),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: kTestL10nDelegates,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  results.add(await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          VenueReapprovalScreen(expectedUid: expectedUid),
                    ),
                  ));
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).first, 'AAAAAAAAAAAAAAAAAAAAAA');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    return (results: results, link: link);
  }

  testWidgets('the same account approving lets the switch proceed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final env = await pumpGate(tester,
        tokenUid: 'uid_artist', expectedUid: 'uid_artist');
    expect(env.results, [true]);
  });

  testWidgets('a DIFFERENT approver is refused with a clear message',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final env = await pumpGate(tester,
        tokenUid: 'uid_stranger', expectedUid: 'uid_artist');
    expect(env.results, isEmpty, reason: 'the gate stays up');
    expect(
        find.textContaining('a different account'), findsOneWidget);
  });
}
