import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'domain/app_settings.dart';
import 'features/live/stage/stage_overlay.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/setup/jar_setup_screen.dart';
import 'features/shell/app_shell.dart';
import 'state/providers.dart';
import 'state/seen_ping.dart';

class LiveTipsApp extends ConsumerWidget {
  const LiveTipsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(
      appStateProvider.select((s) => s.settings.themeMode),
    );
    return MaterialApp(
      title: 'live.tips',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: switch (appThemeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      // Lets the web stage go inert while a sheet/dialog covers it, so modals
      // stay clickable over the jar's iframe.
      navigatorObservers: [StageOverlayObserver()],
      // The keep-alive pings the relay on launch/resume (≤ once a day) so a
      // connected-mode jar never expires under an active artist.
      home: const RelayKeepalive(child: RootGate()),
    );
  }
}

/// Routes to the right top-level screen from the ACTIVE band's state alone:
/// signed out → welcome; Stripe connected but no tip jar yet → setup;
/// else home (a relay-only band needs no Stripe jar setup).
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final screen = !app.connected
        ? const WelcomeScreen()
        : (app.hasStripe && app.effectiveTipJar == null)
            ? const JarSetupScreen()
            : const AppShell();
    // Keyed by band: a switch remounts the whole subtree, so every widget-
    // local cache (home's goal, History's Stripe pagination, prefilled
    // forms) restarts from the new band's state instead of showing the old
    // band's numbers.
    return KeyedSubtree(key: ValueKey(app.accountId), child: screen);
  }
}
