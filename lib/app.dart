import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/events_screen.dart';
import 'screens/gym_screen.dart';
import 'screens/snapshots_screen.dart';
import 'screens/more_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/links_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/placeholder_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/tweaks_sheet.dart';
import 'widgets/add_sheet.dart';

class OnlyMeApp extends StatelessWidget {
  const OnlyMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Only me',
      theme: ThemeData(
        useMaterial3: true,
        brightness: theme.dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: theme.bg,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          theme.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.accent,
          brightness: theme.dark ? Brightness.dark : Brightness.light,
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool showTweaks = false;
  bool addOpen = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;

    Widget content;
    switch (state.screen) {
      case 'home':
        content = const HomeScreen();
        break;
      case 'tasks':
        content = const TasksScreen();
        break;
      case 'finance':
        content = const FinanceScreen();
        break;
      case 'events':
        content = const EventsScreen();
        break;
      case 'gym':
        content = const GymScreen();
        break;
      case 'snapshots':
        content = const SnapshotsScreen();
        break;
      case 'more':
        content = MoreScreen(
          onOpenTweaks: () => setState(() => showTweaks = true),
          onSync: () => context.read<AppState>().syncNow(),
        );
        break;
      case 'profile':
        content = const ProfileScreen();
        break;
      case 'notes':
        content = const NotesScreen();
        break;
      case 'links':
        content = const LinksScreen();
        break;
      case 'vault':
        content = const VaultScreen();
        break;
      case 'expenses':
        content = const ExpensesScreen();
        break;
      default:
        content = PlaceholderScreen(label: _placeholderLabel(state.screen));
    }

    final screenKey = ValueKey(state.screen);

    return Scaffold(
      backgroundColor: theme.bg,
      body: Container(
        color: theme.bg,
        child: SafeArea(
          child: Stack(children: [
            Positioned.fill(
              child: Column(children: [
                Expanded(
                  child: _ScreenSwitcher(
                    child: KeyedSubtree(
                      key: screenKey,
                      child: content,
                    ),
                  ),
                ),
              ]),
            ),

          // Bottom nav (floating translucent)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomNav(
              active: state.screen,
              onChange: (k) {
                if (k == 'add') {
                  setState(() => addOpen = true);
                } else {
                  state.setScreen(k);
                }
              },
              theme: theme,
            ),
          ),

          // Tweaks popup
          if (showTweaks) ...[
            Positioned.fill(child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => showTweaks = false),
              child: Container(color: Colors.black.withOpacity(0.0)),
            )),
            TweaksSheet(onClose: () => setState(() => showTweaks = false)),
          ],

          // Add sheet
          if (addOpen) ...[
            Positioned.fill(child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => addOpen = false),
              child: Container(color: Colors.black.withOpacity(0.5)),
            )),
            Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Transform.translate(
                  offset: Offset(0, (1 - v) * 300),
                  child: Opacity(opacity: v, child: child),
                ),
                child: AddSheet(onClose: () => setState(() => addOpen = false)),
              ),
            ),
          ],
          ]),
        ),
      ),
    );
  }

  String _placeholderLabel(String key) => switch (key) {
        'skincare' => 'Skincare',
        _ => 'Soon',
      };
}

/// iOS-style cross-fade + slight slide switch between screens.
class _ScreenSwitcher extends StatelessWidget {
  final Widget child;
  const _ScreenSwitcher({required this.child});

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 340),
      transitionBuilder: (child, primary, secondary) => _IosSwitchTransition(
        primary: primary, secondary: secondary, child: child,
      ),
      child: child,
    );
  }
}

/// A combined slide + fade + soft scale transition tuned to feel iOS-native.
class _IosSwitchTransition extends StatelessWidget {
  final Animation<double> primary;
  final Animation<double> secondary;
  final Widget child;
  const _IosSwitchTransition({required this.primary, required this.secondary, required this.child});

  @override
  Widget build(BuildContext context) {
    final slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic)).animate(primary);
    final fadeIn = CurvedAnimation(parent: primary, curve: Curves.easeOut);
    final scaleIn = Tween<double>(begin: 0.985, end: 1).chain(CurveTween(curve: Curves.easeOutCubic)).animate(primary);

    final slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.06))
        .chain(CurveTween(curve: Curves.easeIn)).animate(secondary);
    final fadeOut = Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeIn)).animate(secondary);

    return FadeTransition(
      opacity: fadeOut,
      child: SlideTransition(
        position: slideOut,
        child: FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: slideIn,
            child: ScaleTransition(scale: scaleIn, child: child),
          ),
        ),
      ),
    );
  }
}

/// A simple replacement for `animations` package's PageTransitionSwitcher.
/// Kept inline so we don't need an extra dependency.
class PageTransitionSwitcher extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Widget Function(Widget child, Animation<double> primary, Animation<double> secondary) transitionBuilder;
  const PageTransitionSwitcher({super.key, required this.child, required this.duration, required this.transitionBuilder});

  @override
  State<PageTransitionSwitcher> createState() => _PageTransitionSwitcherState();
}

class _PageTransitionSwitcherState extends State<PageTransitionSwitcher> with TickerProviderStateMixin {
  late AnimationController _primary;
  late AnimationController _secondary;
  Widget? _outgoing;
  late Widget _current;

  @override
  void initState() {
    super.initState();
    _primary = AnimationController(vsync: this, duration: widget.duration)..value = 1;
    _secondary = AnimationController(vsync: this, duration: widget.duration)..value = 0;
    _current = widget.child;
  }

  @override
  void didUpdateWidget(covariant PageTransitionSwitcher old) {
    super.didUpdateWidget(old);
    if (_current.key != widget.child.key) {
      setState(() {
        _outgoing = _current;
        _current = widget.child;
      });
      _primary.forward(from: 0);
      _secondary.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _outgoing = null);
      });
    }
  }

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      if (_outgoing != null)
        widget.transitionBuilder(_outgoing!, const AlwaysStoppedAnimation(1), _secondary),
      widget.transitionBuilder(_current, _primary, const AlwaysStoppedAnimation(0)),
    ]);
  }
}
