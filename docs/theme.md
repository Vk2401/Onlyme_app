# Theme

`lib/theme/app_theme.dart` defines a **plain value object**, not a `ThemeData`. It exposes typed color fields and an immutable accent enum. All OnlyMe widgets take `theme: AppTheme` as a parameter and read fields directly — `Theme.of(context)` is only used by Material's built-ins.

## The type

```dart
class AppTheme {
  final bool dark;
  final AccentKey accentKey;
  final Color bg, surface, surface2, ink, ink2, muted, rule;
  final Color accent, accent2, glow;
  final Color danger, success, warning;
}

enum AccentKey { violet, coral, mint, amber }
```

Each `AccentKey` maps to an `_Accent` record (`a`, `a2`, `glow`) inside the theme file. `AppTheme.build(dark: …, accentKey: …)` returns a fully populated theme.

## Why not `ThemeData`?

1. We render custom widgets with non-Material colors (ring progress, iOS-style cards, gradients). Material's `ColorScheme` doesn't map cleanly.
2. Having the theme be a plain value lets us A/B any widget under any accent × dark/light without a `MaterialApp` in tests.
3. Passing it explicitly makes the theme an obvious widget input, which caught the flicker bug early: every widget that claimed `theme: theme` and got re-rendered was obviously up-to-date.

Flutter's `ThemeData` is still set on `MaterialApp` for the sake of built-in widgets (buttons, scrollbar, text scale, color-scheme fromSeed for Material 3 fallbacks).

## Using the theme

```dart
// Parent passes theme explicitly (preferred)
Widget build(BuildContext context) {
  return MyCard(theme: state.theme, …);
}

// Child reads the field
Text(label, style: TextStyle(color: theme.ink));
```

If a deeply nested widget needs the theme and you don't want to plumb it, use `context.watch<AppState>().theme` at the leaf. That's fine — just don't combine both approaches in the same widget.

## Mutating the theme

Two entry points on `AppState`:

```dart
state.setAccent(AccentKey.mint);
state.setDark(true);
```

Both persist via `LocalStorage` (`onlyme:accent` / `onlyme:dark`) and call `notifyListeners()`, so every `context.watch<AppState>()` picks up the change on the next frame.

## Tweaks sheet

`lib/widgets/tweaks_sheet.dart` is the user-facing surface for accent + dark. It's opened via the ⚙ button in `MoreScreen`'s header. Animation is a simple bottom-sheet slide; tap outside to close. The theme writes happen inside the sheet's button handlers.

## Flicker fix (historical context)

The original `AppShell` painted `theme.bg` in three places:
- `Scaffold.backgroundColor`
- an outer `Container(color: theme.bg)`
- an inner `Container(color: theme.bg)` keyed by screen (inside `_ScreenSwitcher`)

During a screen transition, the inner container was *cached as part of the outgoing screen widget*. Toggling dark mid-transition updated the outer container immediately but left the outgoing screen rendering the old color for the 340ms transition duration — a visible flicker.

Fix: paint the bg exactly once, on the outermost `Container`. The keyed child inside `_ScreenSwitcher` is now a `KeyedSubtree` with no color. See `lib/app.dart` around the `AppShell.build` return.
