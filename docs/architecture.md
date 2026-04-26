# Architecture

## One-screen mental model

```
┌──────────────────────────────────────────────────────────────┐
│  main.dart                                                   │
│    └─ ChangeNotifierProvider<AppState>                       │
│         └─ OnlyMeApp (MaterialApp)                           │
│              └─ AppShell (PopScope → Scaffold)               │
│                   ├─ outer Container(color: theme.bg)        │
│                   ├─ _ScreenSwitcher (bottom-to-top)         │
│                   │    └─ switch (state.screen)              │
│                   │         ├─ 'home'      → HomeScreen      │
│                   │         ├─ 'tasks'     → TasksScreen     │
│                   │         ├─ 'finance'   → FinanceScreen   │
│                   │         ├─ 'events'    → EventsScreen    │
│                   │         ├─ 'gym'       → GymScreen       │
│                   │         ├─ 'snapshots' → SnapshotsScreen │
│                   │         ├─ 'more'      → MoreScreen      │
│                   │         ├─ 'profile'   → ProfileScreen   │
│                   │         ├─ 'notes'     → NotesScreen     │
│                   │         ├─ 'links'     → LinksScreen     │
│                   │         ├─ 'vault'     → VaultScreen     │
│                   │         └─ 'expenses'  → ExpensesScreen  │
│                   ├─ BottomNav (floating)                    │
│                   ├─ TweaksSheet (optional overlay)          │
│                   └─ AddSheet    (optional overlay)          │
└──────────────────────────────────────────────────────────────┘
```

## Layers

| Layer | Folder | What it owns |
|---|---|---|
| **Models** | `lib/models/` | Pure Dart value types. No Flutter imports except `dart:ui` Color. |
| **Storage** | `lib/storage/` | `LocalStorage` (`SharedPreferences` wrapper) and `export_io.dart` (JSON backup). |
| **Services** | `lib/services/` | `NotificationsService` — singleton wrapper around `flutter_local_notifications`. |
| **State** | `lib/app_state.dart` | Single `ChangeNotifier`. CRUD on every domain. Entry point: `AppState.load()`. |
| **Theme** | `lib/theme/app_theme.dart` | Immutable value object with all colors + accent enum. |
| **Widgets** | `lib/widgets/` | Reusable primitives (cards, rings, confirm sheet, header, bottom nav, add/tweaks sheets). |
| **Screens** | `lib/screens/` | One file per top-level screen. Consume state via `context.watch<AppState>()`. |
| **App** | `lib/app.dart` + `main.dart` | Bootstrap, routing switch, transitions, back-press handling, overlays. |

## Dataflow

```
  user action ──► Screen widget ──► context.read<AppState>().mutatorX(…)
                                             │
                                             ├─► storage.writeX(…)          (persist)
                                             ├─► NotificationsService.scheduleX(…)  (optional)
                                             └─► notifyListeners()           (rebuild)
                                                      │
                                                      ▼
                                     every context.watch<AppState>() rebuilds
```

There is no repository, no event bus, no "use case" layer. Every domain has:

1. A model file (`lib/models/<thing>.dart`).
2. A key + read/write pair on `LocalStorage`.
3. An `AppState` field + `add<Thing>` / `edit<Thing>` / `delete<Thing>` methods.
4. A screen file that watches state and calls mutators.
5. For domains with scheduled reminders: `_rescheduleX` / `cancelX` wired into every mutator.

## Key non-obvious invariants

1. **`theme.bg` is painted in exactly one place** — the outer `Container` in `AppShell.build`. Wrapping screens in a second `Container(color: theme.bg)` causes the theme-toggle flicker bug.
2. **`AppState.load()` is an `async` factory** — called once in `main.dart` before `runApp`. Initialise new fields inside `load()`, not in the constructor.
3. **Screen transitions animate bottom-to-top** — `_IosSwitchTransition` uses `Offset(0, 0.08)` incoming / `Offset(0, -0.06)` outgoing. All sheets also animate up.
4. **No `Theme.of(context)` for app colors** — pass `theme: state.theme` explicitly. `Theme.of(context)` is only for Flutter's own Material widgets.
5. **Back-press is layered** — `PopScope(canPop: false)` in `AppShell` handles it: dismiss overlays first → go home → show "Exit app?" confirmation → `SystemNavigator.pop()`.
6. **`NotificationsService.scheduleX` is fire-and-forget** — called from `_rescheduleTask/Event` without `await`. Errors are silently caught inside the service. Never call the service directly from the UI.
7. **Seed data is empty by default** — only the gym plan is seeded. Users create everything else.

## Extending the app

Adding a new domain takes ~5 edits. See [contributing.md](contributing.md) for the step-by-step.
