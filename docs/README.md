# Only Me — Project Documentation

Only Me is a **private, local-only personal tracker** built with Flutter. It bundles tasks-with-streaks, debt tracking, event budgets, a weekly gym plan with weight log, snapshot journals, notes, saved links, and a password vault — all persisted on-device via `SharedPreferences`, no backend.

This folder holds the engineering-facing docs. User-facing copy lives in [`../README.md`](../README.md); contributor rules and style live in [`../CLAUDE.md`](../CLAUDE.md).

## Start here

| Doc | Read when |
|---|---|
| [architecture.md](architecture.md) | You're new to the codebase — understand the big picture. |
| [state-management.md](state-management.md) | You need to add a mutation, a domain, or debug re-renders. |
| [storage.md](storage.md) | You're touching persistence, migrations, or the backup format. |
| [navigation.md](navigation.md) | You want to add/remove a screen. Why there is *no* Navigator. |
| [theme.md](theme.md) | You need accent/dark support on a new widget. |
| [models.md](models.md) | You want the quick reference of every domain type. |
| [screens.md](screens.md) | You're working on UI and need to know what each screen does. |
| [widgets.md](widgets.md) | You want to reuse a primitive or add a new shared widget. |
| [backup.md](backup.md) | You're extending export/import. |
| [icon-pipeline.md](icon-pipeline.md) | You need to change the app icon. |
| [ci.md](ci.md) | You want to understand/modify GitHub Actions. |
| [testing.md](testing.md) | You want to run tests or write new ones. |
| [contributing.md](contributing.md) | You're opening a PR. |

## Why this architecture?

This app is deliberately small. Every decision in the codebase optimises for **one engineer, one state object, one storage target**:

- **One `ChangeNotifier`** (`AppState`) — not multiple providers, not a repository layer, not Bloc. The app has ~10 domains, so one class with typed mutation methods is less code than abstraction layers.
- **No routing package** — navigation is a `state.screen` string. A `switch` in `AppShell` renders the right screen. Adding a screen = adding a case.
- **No `Theme.of(context)` for colors** — `AppTheme` is a plain value object passed explicitly. Makes it trivial to preview the same widget under both dark/light and any accent, and prevents the "baked into the build tree" problem we ran into with the theme-flicker bug.
- **Storage is one class, many keys** — `LocalStorage` owns all `onlyme:*` keys. JSON-encoded via each model's `toJson`/`fromJson`. The full state is (by construction) round-trip-serialisable, which is what makes the export/import feature trivial.

When in doubt, read [architecture.md](architecture.md) first.

## Conventions

- Every model is immutable with `copyWith` / `toJson` / `fromJson`.
- Every `AppState` mutation ends with `storage.write<X>(...)` + `notifyListeners()`.
- Every destructive action goes through `confirmDelete()` from `lib/widgets/confirm_sheet.dart` — no raw `deleteX()` calls from the UI.
- Every currency render uses `state.profile.currencySymbol`, never `'₹'`.
- Screen transitions are bottom-to-top (`lib/app.dart`'s `_IosSwitchTransition`) — if you add animation elsewhere, match that direction.
