# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

**Only Me** is a private personal tracker — tasks with streaks, debt/finance tracking, planned events with budgets, gym weekly plan, and a visual snapshot journal. It is a Flutter app with all state persisted locally via SharedPreferences (no backend). The UI aesthetic is iOS-native dark with configurable accent colors.

## Commands

```bash
# Install dependencies
flutter pub get

# Run on a connected device / simulator
flutter run

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/some_test.dart

# Build Android APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

> The project has no platform folders committed — if needed, regenerate with:
> `flutter create . --org com.webronic --platforms ios,android,macos,web`

## Architecture

### State management

`AppState` (`lib/app_state.dart`) is a single `ChangeNotifier` that owns **all** app data. It is instantiated via `AppState.load()` at startup (reads from `LocalStorage`) and provided to the widget tree via `ChangeNotifierProvider`. Every mutation method on `AppState` writes through to `LocalStorage` and calls `notifyListeners()` — there is no separate repository layer.

Screens read state with `context.watch<AppState>()`. One-shot reads (inside callbacks) use `context.read<AppState>()`.

### Navigation

Navigation is not Flutter's `Navigator`/routes. Instead, `AppState.screen` (a plain string) controls which screen `AppShell` renders inside a `switch`. Screen changes call `state.setScreen(key)`, which persists the last active screen. The `_ScreenSwitcher` / `_IosSwitchTransition` classes in `app.dart` provide iOS-style cross-fade + slide animations between screens without any routing package.

Valid screen keys: `home`, `tasks`, `finance`, `events`, `gym`, `snapshots`, `more`, plus placeholder keys `skincare`, `notes`, `links`, `vault`, `profile`.

### Storage layer

`LocalStorage` (`lib/storage/local_storage.dart`) wraps `SharedPreferences`. Each domain (tasks, debts, events, gym, accent, dark mode, last-sync timestamp) has its own `onlyme:<key>` string key. All domain objects are JSON-encoded/decoded with manual `toJson`/`fromJson` on each model.

### Theme

`AppTheme` (`lib/theme/app_theme.dart`) is a value object (not Flutter's `ThemeData`). It exposes typed color fields (`bg`, `surface`, `surface2`, `ink`, `ink2`, `muted`, `rule`, `accent`, `accent2`, `glow`, `danger`, `success`, `warning`). Accent choices are `violet`, `coral`, `mint`, `amber` (enum `AccentKey`). All widgets receive `theme` explicitly — do not use `Theme.of(context)` for custom colors.

### Widgets

Reusable primitives live in `lib/widgets/primitives.dart`: `AppCard`, `IconChip`, `Ring` (animated arc progress), `CheckBubble`, `SectionHead`.

Icon strings (used in seed data and models) are resolved to `LucideIcons` via `AppIcons.byKey(String)` in `lib/widgets/app_icons.dart`. When adding a new icon, register it there.

The bottom `+` button opens `AddSheet` (navigates to a section); the tweaks gear opens `TweaksSheet` (accent + dark toggle) — both are `Stack`-overlaid inside `AppShell`, not pushed via Navigator.

### Models

All models in `lib/models/` are immutable value types with `copyWith`, `toJson`, and `fromJson`. Seed data in `lib/data/seed_data.dart` is used as defaults on first launch.

| Model | Key fields |
|---|---|
| `TaskItem` | `id`, `title`, `time`, `cat`, `icon` (string key), `color`, `done`, `streak` |
| `Debt` | `id`, `person`, `type` (`DebtType.iOwe` / `DebtType.theyOwe`), `total`, `paid`, `settled` |
| `PlannedEvent` | `id`, `title`, `date`, `items` (`List<EventItem>` with `est`/`actual`/`done`) |
| `GymPlan` | `name`, `days` (`List<GymDay>` with `List<Exercise>`) |
| `Snapshot` | `id`, `date`, `note`, `hue` (placeholder color — no real image storage yet) |

## Key conventions

- **No routing package** — all navigation is `state.setScreen(key)`.
- **No `Theme.of(context)`** for colors — pass `AppTheme` explicitly from `state.theme`.
- **Linting is relaxed**: `prefer_const_constructors` and `use_key_in_widget_constructors` are disabled; `deprecated_member_use` is suppressed. Don't add noise trying to fix these.
- **Sync is a placeholder**: `AppState.syncNow()` only writes a local timestamp. The JSON payload shape is already in `LocalStorage` — future work is POSTing it to a remote endpoint.
- **Snapshots have no real images**: `Snapshot.hue` is a placeholder color int. Real image storage is future work.
- Font: `Plus Jakarta Sans` via `google_fonts`. Applied at `MaterialApp` level; don't override per-widget.
