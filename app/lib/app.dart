import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'domain/app_settings.dart';
import 'features/live/stage/stage_overlay.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/setup/jar_setup_screen.dart';
import 'features/shell/app_shell.dart';
import 'state/providers.dart';

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
      home: const RootGate(),
    );
  }
}

/// Routes to the right top-level screen from app state alone:
/// signed out → welcome; connected but no tip jar yet → setup; else home.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    if (!app.connected) return const WelcomeScreen();
    if (app.effectiveTipJar == null) return const JarSetupScreen();
    return const AppShell();
  }
}
