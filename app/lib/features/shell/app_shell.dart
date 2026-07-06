import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/app_settings.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../poster/poster_screen.dart';
import '../settings/settings_screen.dart';

/// Above this width the bottom tab bar becomes a 240px side rail.
const double kRailBreakpoint = 940;

/// Set from outside the shell (e.g. jar-setup success → Poster) to land on
/// a specific tab; the shell consumes and clears it.
final shellTabRequestProvider =
    NotifierProvider<ShellTabRequest, ShellTab?>(ShellTabRequest.new);

class ShellTabRequest extends Notifier<ShellTab?> {
  @override
  ShellTab? build() => null;

  void request(ShellTab tab) => state = tab;

  void clear() => state = null;
}

enum ShellTab {
  home('Home', Icons.home_rounded, Icons.home_outlined),
  history('History', Icons.receipt_long_rounded, Icons.receipt_long_outlined),
  // Poster still lives in the shell (so the bottom nav / rail stay visible while
  // you design it), but it has no nav item of its own — it's reached only from
  // Home's tip-link "Poster" button. inNav: false keeps it out of the bars.
  poster('Poster', Icons.print_rounded, Icons.print_outlined, inNav: false),
  settings('Settings', Icons.settings_rounded, Icons.settings_outlined);

  const ShellTab(this.label, this.activeIcon, this.inactiveIcon,
      {this.inNav = true});
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  /// Whether this tab appears in the bottom bar / side rail.
  final bool inNav;

  /// The tabs that get a nav item (everything but the poster designer).
  static List<ShellTab> get navTabs => values.where((t) => t.inNav).toList();
}

/// Lets any tab switch tabs (Home's "View all" → History, …) and tells
/// screens whether the side rail (vs the bottom tab bar) is showing.
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.select,
    required this.isRail,
    required super.child,
  });

  final void Function(ShellTab) select;

  /// true → 240px side rail is visible; screens skip their own logo bar.
  final bool isRail;

  static AppShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>();

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      oldWidget.isRail != isRail;
}

/// The signed-in shell: Home · History · Poster · Settings behind a bottom
/// tab bar (phones) or a side rail (tablets / desktop).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  ShellTab _tab = ShellTab.home;

  /// Tabs are built on first visit and then kept alive in the stack —
  /// Poster's PDF preview shouldn't render before anyone asks for it.
  final _visited = <ShellTab>{ShellTab.home};

  @override
  void initState() {
    super.initState();
    // A tab may have been requested before this shell mounted
    // (jar-setup success → Poster).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final requested = ref.read(shellTabRequestProvider);
      if (requested != null) {
        _select(requested);
        ref.read(shellTabRequestProvider.notifier).clear();
      }
    });
  }

  void _select(ShellTab tab) {
    if (_tab != tab || !_visited.contains(tab)) {
      setState(() {
        _tab = tab;
        _visited.add(tab);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ShellTab?>(shellTabRequestProvider, (previous, next) {
      if (next != null) {
        _select(next);
        ref.read(shellTabRequestProvider.notifier).clear();
      }
    });
    final body = IndexedStack(
      index: _tab.index,
      children: [
        for (final t in ShellTab.values)
          if (_visited.contains(t))
            switch (t) {
              ShellTab.home => const HomeScreen(),
              ShellTab.history => const HistoryScreen(),
              ShellTab.poster => const PosterScreen(),
              ShellTab.settings => const SettingsScreen(),
            }
          else
            const SizedBox.shrink(),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kRailBreakpoint;
        if (wide) {
          return AppShellScope(
            select: _select,
            isRail: true,
            child: Scaffold(
              body: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SideRail(tab: _tab, onSelect: _select),
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
          );
        }
        return AppShellScope(
          select: _select,
          isRail: false,
          child: Scaffold(
            body: SafeArea(bottom: false, child: body),
            bottomNavigationBar: _BottomTabBar(tab: _tab, onSelect: _select),
          ),
        );
      },
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.tab, required this.onSelect});

  final ShellTab tab;
  final ValueChanged<ShellTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final t in ShellTab.navTabs)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(t),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 3),
                          decoration: BoxDecoration(
                            color: t == tab
                                ? c.accentSoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            t == tab ? t.activeIcon : t.inactiveIcon,
                            size: 22,
                            color: t == tab ? c.accent : c.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.label,
                          style: outfitStyle(
                            11,
                            t == tab ? c.accent : c.textMuted,
                            weight: t == tab
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideRail extends ConsumerWidget {
  const _SideRail({required this.tab, required this.onSelect});

  final ShellTab tab;
  final ValueChanged<ShellTab> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final themeMode = app.settings.themeMode;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: c.card,
        border: Border(right: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const LtLogoMark(size: 34),
                const SizedBox(width: 10),
                Text('live.tips',
                    style: outfitStyle(18, c.text, weight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          for (final t in ShellTab.navTabs)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: t == tab ? c.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelect(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        Icon(
                          t == tab ? t.activeIcon : t.inactiveIcon,
                          size: 21,
                          color: t == tab ? c.accent : c.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t.label,
                          style: outfitStyle(
                            14,
                            t == tab ? c.onAccentSoft : c.textSecondary,
                            weight: t == tab
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          _RailKeyChip(app: app),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                final picked = await showLtPicker<AppThemeMode>(
                  context: context,
                  title: 'App theme',
                  values: AppThemeMode.values,
                  selected: themeMode,
                  labelOf: (m) => switch (m) {
                    AppThemeMode.system => 'Auto — follow the system',
                    AppThemeMode.light => 'Light',
                    AppThemeMode.dark => 'Dark',
                  },
                );
                if (picked != null) {
                  final s = ref.read(appStateProvider).settings;
                  await ref
                      .read(appStateProvider.notifier)
                      .updateSettings(s.copyWith(themeMode: picked));
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      switch (themeMode) {
                        AppThemeMode.system => Icons.brightness_auto_rounded,
                        AppThemeMode.light => Icons.light_mode_rounded,
                        AppThemeMode.dark => Icons.dark_mode_rounded,
                      },
                      size: 18,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Theme: ${themeMode.label == 'System' ? 'Auto' : themeMode.label}',
                        style: outfitStyle(13, c.textSecondary),
                      ),
                    ),
                    Icon(Icons.expand_more_rounded,
                        size: 18, color: c.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailKeyChip extends StatelessWidget {
  const _RailKeyChip({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final (bg, dot, fg, label) = app.demo
        ? (c.chip, c.textMuted, c.textSecondary, 'Demo — simulated tips')
        : app.isTestMode
            ? (c.accentSoft, c.accent, c.onAccentSoft, 'Test key — simulated')
            : (c.successContainer, c.success, c.onSuccessContainer,
                'Live key connected');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: outfitStyle(13, fg))),
        ],
      ),
    );
  }
}

/// The coral rounded-square app mark with the giving-hand icon.
class LtLogoMark extends StatelessWidget {
  const LtLogoMark({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(Icons.volunteer_activism,
          size: size * 0.57, color: c.onAccent),
    );
  }
}
