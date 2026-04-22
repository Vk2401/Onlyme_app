# Architecture

## One-screen mental model

```
┌──────────────────────────────────────────────────────────┐
│  main.dart                                               │
│    └─ ChangeNotifierProvider<AppState>                   │
│         └─ OnlyMeApp (MaterialApp)                       │
│              └─ AppShell                                 │
│                   ├─ outer Container(color: theme.bg)    │
│                   ├─ _ScreenSwitcher                     │
│                   │    └─ switch (state.screen)          │
│                   │         ├─ 'home'      → HomeScreen  │
│                   │         ├─ 'tasks'     → …           │
│                   │         ├─ 'finance'   → …           │
│                   │         ├─ 'events'    → …           │
│                   │         ├─ 'gym'       → …           │
│                   │         ├─ 'snapshots' → …           │
│                   │         ├─ 'more'      → …           │
│                   │         ├─ 'profile'   → …           │
│                   │         ├─ 'notes'     → …           │
│                   │         ├─ 'links'     → …           │
│                   │         └─ 'vault'     → …           │
│                   ├─ BottomNav (floating)                │
│                   ├─ TweaksSheet (optional overlay)      │
│                   └─ AddSheet    (optional overlay)      │
└──────────────────────────────────────────────────────────┘
```

## Layers

| Layer | Folder | What it owns |
|---|---|---|
| **Models** | `lib/models/` | Pure Dart value types. No Flutter imports except `dart:ui` Color. |
| **Storage** | `lib/storage/` | `LocalStorage` (`SharedPreferences` wrapper) and `export_io.dart` (JSON backup). |
| **State** | `lib/app_state.dart` | Single `ChangeNotifier`. CRUD on every domain. Entry point: `AppState.load()`. |
| **Theme** | `lib/theme/app_theme.dart` | Immutable value object with all colors + accent enum. |
| **Widgets** | `lib/widgets/` | Reusable primitives (cards, rings, confirm sheet, header, bottom nav, add/tweaks sheets). |
| **Screens** | `lib/screens/` | One file per top-level screen. Consume state via `context.watch<AppState>()`. |
| **App** | `lib/app.dart` + `main.dart` | Bootstrap, routing switch, transitions, overlays. |

## Dataflow

```
  user action ──► Screen widget ──► context.read<AppState>().mutatorX(…)
                                             │
                                             ├─► storage.writeX(…)  (persist)
                                             └─► notifyListeners()  (rebuild)
                                                      │
                                                      ▼
                                     every context.watch<AppState>() rebuilds
```

There is no repository, no event bus, no "use case" layer. Every domain has:

1. A model file (`lib/models/<thing>.dart`).
2. A key + read/write pair on `LocalStorage`.
3. An `AppState` field + `add<Thing>` / `edit<Thing>` / `delete<Thing>` methods.
4. A screen file that watches state and calls mutators.

## Key non-obvious invariants

1. **`theme.bg` is painted in exactly one place** — the outer `Container` in `AppShell.build`. If you wrap screens in a second `Container(color: theme.bg)`, the theme toggle will flicker during transitions. (See [the fix](https://github.com/…) in `lib/app.dart`.)
2. **`AppState.load()` is an `async` factory** — called once in `main.dart` before `runApp`. If you add a field, initialise it inside `load()`, not inside the private constructor.
3. **Screen transitions animate bottom-to-top** — `_IosSwitchTransition` uses `Offset(0, 0.08)` incoming and `Offset(0, -0.06)` outgoing. Don't revert to horizontal offsets.
4. **No Theme.of(context) for app colors** — pass `theme: state.theme` explicitly. `Theme.of(context)` is only used by Flutter's own Material widgets (buttons, text scale).
5. **Seed data is empty by default** — `data/seed_data.dart` ships zero tasks/debts/events/etc. The gym plan is the only seeded model (so a blank plan renders correctly). Users create their own data.

## Extending the app

Adding a new domain takes ~5 edits. See [contributing.md](contributing.md) for the step-by-step.
