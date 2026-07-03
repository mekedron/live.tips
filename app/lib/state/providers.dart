import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import '../data/secure_store.dart';
import '../data/stripe/stripe_client.dart';
import '../data/stripe/stripe_requests.dart';
import '../domain/app_settings.dart';
import '../domain/donation.dart';
import '../domain/tip_jar.dart';

/// Overridden in main() with initialized instances.
final localStoreProvider =
    Provider<LocalStore>((ref) => throw UnimplementedError());
final secureStoreProvider =
    Provider<SecureStore>((ref) => throw UnimplementedError());

/// API key read from secure storage before the first frame.
final initialApiKeyProvider = Provider<String?>((ref) => null);

class AppState {
  const AppState({
    this.apiKey,
    this.tipJar,
    required this.settings,
    this.demo = false,
  });

  final String? apiKey;
  final TipJar? tipJar;
  final AppSettings settings;
  final bool demo;

  bool get connected => demo || apiKey != null;
  bool get isTestMode => demo || (apiKey?.contains('_test_') ?? false);
  TipJar? get effectiveTipJar => demo ? TipJar.demo : tipJar;
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    final local = ref.read(localStoreProvider);
    return AppState(
      apiKey: ref.read(initialApiKeyProvider),
      tipJar: local.readTipJar(),
      settings: local.readSettings(),
    );
  }

  Future<void> connect(String apiKey) async {
    final trimmed = apiKey.trim();
    await ref.read(secureStoreProvider).writeApiKey(trimmed);
    state = AppState(
      apiKey: trimmed,
      tipJar: state.tipJar,
      settings: state.settings,
    );
  }

  void enterDemo() {
    state = AppState(
      apiKey: state.apiKey,
      tipJar: state.tipJar,
      settings: state.settings,
      demo: true,
    );
  }

  void exitDemo() {
    state = AppState(
      apiKey: state.apiKey,
      tipJar: state.tipJar,
      settings: state.settings,
    );
  }

  Future<void> setTipJar(TipJar jar) async {
    await ref.read(localStoreProvider).saveTipJar(jar);
    state = AppState(
      apiKey: state.apiKey,
      tipJar: jar,
      settings: state.settings,
      demo: state.demo,
    );
  }

  Future<void> updateSettings(AppSettings settings) async {
    await ref.read(localStoreProvider).saveSettings(settings);
    state = AppState(
      apiKey: state.apiKey,
      tipJar: state.tipJar,
      settings: settings,
      demo: state.demo,
    );
  }

  /// Removes the key and every trace of local data.
  Future<void> disconnect() async {
    await ref.read(secureStoreProvider).wipeAll();
    await ref.read(localStoreProvider).wipeAll();
    state = const AppState(settings: AppSettings());
  }
}

final appStateProvider =
    NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

/// Live Stripe API surface, or null when in demo mode / signed out.
final stripeRequestsProvider = Provider<StripeRequests?>((ref) {
  final app = ref.watch(appStateProvider);
  if (app.demo || app.apiKey == null) return null;
  final client = StripeClient(app.apiKey!);
  ref.onDispose(client.close);
  return StripeRequests(client);
});

/// Small preview of latest donations for the home screen.
final recentDonationsProvider =
    FutureProvider.autoDispose<List<Donation>>((ref) async {
  final requests = ref.watch(stripeRequestsProvider);
  final jar = ref.watch(appStateProvider).effectiveTipJar;
  if (requests == null || jar == null || jar.isDemo) return const [];
  final page = await requests.listDonations(
    paymentLinkId: jar.paymentLinkId,
    limit: 5,
  );
  return page.donations;
});
