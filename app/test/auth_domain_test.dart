import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/auth_domain.dart';
import 'package:live_tips/firebase_options.dart';

void main() {
  group('custom auth domain', () {
    test('overrides the generated web authDomain', () {
      // The generated file still says livetips-app.firebaseapp.com — that is
      // fine and expected, `flutterfire configure` writes it. What must hold is
      // that the options we actually hand to Firebase.initializeApp carry ours.
      final options = withCustomAuthDomain(DefaultFirebaseOptions.web);
      expect(options.authDomain, 'auth.live.tips');
      expect(options.authDomain, kFirebaseAuthDomain);
    });

    test('leaves every other option untouched', () {
      const generated = DefaultFirebaseOptions.web;
      final options = withCustomAuthDomain(generated);
      expect(options.apiKey, generated.apiKey);
      expect(options.appId, generated.appId);
      expect(options.projectId, generated.projectId);
      expect(options.messagingSenderId, generated.messagingSenderId);
      expect(options.storageBucket, generated.storageBucket);
    });
  });
}
