import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('boots to welcome, demo mode reaches home screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localStore = await LocalStore.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(localStore),
          secureStoreProvider.overrideWithValue(SecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );

    expect(find.text('live.tips'), findsOneWidget);
    expect(find.text('Try the demo'), findsOneWidget);

    await tester.ensureVisible(find.text('Try the demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try the demo'));
    await tester.pumpAndSettle();

    expect(find.text('Go live'), findsOneWidget);
  });
}
