import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'core/theme.dart';
import 'domain/app_settings.dart';
import 'domain/device_kind.dart';
import 'features/account/cloud_upload_offer.dart';
import 'features/account/deep_link_gate.dart';
import 'features/account/device_session_guard.dart';
import 'features/account/redirect_sign_in_gate.dart';
import 'features/live/stage/stage_overlay.dart';
import 'features/onboarding/profile_pick_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/setup/jar_setup_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/venue/venue_banner.dart';
import 'features/venue/venue_gate.dart';
import 'l10n/app_locale.dart';
import 'l10n/app_localizations.dart';
import 'state/providers.dart';
import 'state/route_depth.dart';
import 'state/seen_ping.dart';
import 'state/venue_providers.dart';

class LiveTipsApp extends ConsumerWidget {
  const LiveTipsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(
      appStateProvider.select((s) => s.settings.themeMode),
    );
    final localeCode = ref.watch(
      appStateProvider.select((s) => s.settings.localeCode),
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
      // Null → follow the device language (resolved to the nearest shipped
      // locale below); a saved code pins that language.
      locale: localeCode == null ? null : Locale(localeCode),
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) => resolveSupportedLocale(
        localeCode == null ? device : Locale(localeCode),
      ),
      // Lets the web stage go inert while a sheet/dialog covers it, so modals
      // stay clickable over the jar's iframe. The depth observer tells the
      // upload offer when the user is actually looking at the root screen —
      // an offer shown under an onboarding route is an offer nobody sees.
      navigatorObservers: [
        StageOverlayObserver(),
        ref.read(routeDepthObserverProvider),
      ],
      // Above the navigator on purpose: the venue banner must survive every
      // pushed route — no screen on a public device may cover "whose account
      // is this" or "End session".
      builder: (context, child) =>
          VenueBannerHost(child: child ?? const SizedBox.shrink()),
      // The keep-alive pings the relay on launch/resume (≤ once a day) so a
      // connected-mode jar never expires under an active artist. The upload
      // gate offers to move local bands into a freshly signed-in account. The
      // session guard keeps this device's entry in the account's device list
      // and signs itself out when that account revokes it; the deep-link gate
      // turns a scanned/opened `…/link#c=…` URL into the redeem flow.
      // RedirectSignInGate sits INSIDE the upload gate: a web sign-in comes back
      // through a page reload, and the offer to move local profiles into the
      // fresh account only fires if the gate above is already listening when
      // the redirect's user lands.
      home: const RelayKeepalive(
        child: CloudUploadOfferGate(
          child: DeviceSessionGuard(
            child: DeepLinkGate(
              child: RedirectSignInGate(child: RootGate()),
            ),
          ),
        ),
      ),
    );
  }
}

/// Routes to the right top-level screen — from the DEVICE's state, not from
/// whether the active band happens to have a payment method.
///
/// Welcome is the first-run pitch and nothing else: nobody signed in, nothing
/// configured anywhere ([deviceIsSetUpProvider]). Every other "nothing set up
/// yet" state — a fresh cloud account with no bands, a half-created band, a
/// band whose method never saved — renders INSIDE the shell, so the switcher,
/// Settings, the account section and sign-out are always one tap away. A
/// half-made band used to be a room with no door: welcome had no chrome, the
/// shell was unreachable, and the user's other bands were invisible.
///
/// Two states have no band to build the shell AROUND, and neither of them is
/// answered by inventing one ([activeProfileRenderProvider]):
///
/// * A profile set that is warm and empty — a cloud account with no profile
///   yet, or the local profile after its last band was removed → the create
///   step. Nothing is written until the artist finishes it (#26). The empty
///   local profile used to land on the account switcher instead, which is the
///   screen it was tapped ON: the pushed copy popped into a root the flip had
///   just rebuilt as the same screen, and there was no door to a profile from
///   it — a room with no way out (#38).
/// * A cloud account with several profiles and no answer → ProfilePickScreen
///   asking WHICH one. The app used to pick (the stored id, else the first
///   band) and open the wrong gig (#28).
///
/// The Stripe-key-without-a-jar case still gets its own screen: that band is
/// mid-setup with a key already in the keychain, and JarSetupScreen is what
/// finishes it.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The install's kind gates everything: a venue tablet routes through
    // VenueGate whatever any account is doing, and a demo install re-enters
    // demo on boot (the demo flag itself is in-memory only).
    final kind = ref.watch(deviceKindProvider);
    if (kind == DeviceKind.venue) return const VenueGate();
    final app = ref.watch(appStateProvider);
    if (kind == DeviceKind.demo && !app.demo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
            Future(() => ref.read(appStateProvider.notifier).enterDemo()));
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final setUp = ref.watch(deviceIsSetUpProvider);
    final render = ref.watch(activeProfileRenderProvider);
    final screen = !setUp
        ? const WelcomeScreen()
        : render == ProfileRender.pick || render == ProfileRender.create
        ? const ProfilePickScreen(asRoot: true)
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
