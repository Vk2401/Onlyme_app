# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Deep docs:** see [`docs/`](docs/) — one focused file per concern (architecture, state, storage, navigation, theme, models, screens, widgets, backup, icon pipeline, CI, testing, contributing). When something here contradicts what you find in code, the code wins; when it contradicts `docs/`, `docs/` is the source of truth.

## What this app is

**Only Me** is a private, local-only personal tracker: tasks with streaks, debt/finance tracking, planned events with budgets, a weekly gym plan with body-weight log, a snapshot journal, simple notes, saved links, and a password vault. It is a Flutter app with all state persisted via `SharedPreferences` (no backend). UI is iOS-native dark with configurable accent colors and a default mint accent; screen transitions slide bottom-to-top.

## Commands

```bash
flutter pub get                 # install deps
flutter run                     # run on connected device / simulator
flutter analyze                 # lint
flutter test                    # all tests
flutter pub run flutter_launcher_icons  # propagate icon PNGs to every platform size
flutter build apk --release --split-per-abi
flutter build ios --release
```

> Platform folders are committed. If you ever need to regenerate: `flutter create . --org com.webronic --platforms ios,android,macos,web`

## Architecture (30-second version)

```
main.dart → ChangeNotifierProvider<AppState> → AppShell (switch on state.screen)
                                             ├─ outer Container(color: theme.bg)  ← only place bg is painted
                                             ├─ _ScreenSwitcher (bottom-to-top)
                                             ├─ BottomNav (floating)
                                             └─ TweaksSheet / AddSheet (overlays)
```

- **State:** one `ChangeNotifier` — `lib/app_state.dart`. Every domain has fields + `add/edit/delete` mutators. Every mutator writes to storage + calls `notifyListeners`.
- **Storage:** one class — `lib/storage/local_storage.dart`. One `onlyme:*` key per domain, JSON-encoded via each model's `toJson/fromJson`.
- **Navigation:** no `Navigator`, no routes. `state.setScreen('notes')` + a `switch` in `AppShell`. Screen-change persists.
- **Theme:** `AppTheme` is a plain value object (not `ThemeData`). Passed explicitly as `theme:` — don't use `Theme.of(context)` for app colours.

For detail, read [`docs/architecture.md`](docs/architecture.md) → [`docs/state-management.md`](docs/state-management.md) → [`docs/storage.md`](docs/storage.md).

## Domains

| Domain | Model | Storage key | Screen |
|---|---|---|---|
| Tasks | `TaskItem` | `onlyme:tasks` | `tasks_screen.dart` |
| Debts | `Debt` | `onlyme:debts` | `finance_screen.dart` |
| Events | `PlannedEvent` + `EventItem` | `onlyme:events` | `events_screen.dart` |
| Gym | `GymPlan` / `GymDay` / `Exercise` | `onlyme:gym` | `gym_screen.dart` |
| Snapshots | `Snapshot` | `onlyme:snapshots` | `snapshots_screen.dart` |
| Weight logs | `WeightEntry` | `onlyme:weight` | inside `gym_screen.dart` |
| Profile | `Profile` | `onlyme:profile` | `profile_screen.dart` |
| Notes | `Note` | `onlyme:notes` | `notes_screen.dart` |
| Saved links | `SavedLink` | `onlyme:links` | `links_screen.dart` |
| Vault | `VaultEntry` | `onlyme:vault` | `vault_screen.dart` |

Full field reference in [`docs/models.md`](docs/models.md). Screen behaviour in [`docs/screens.md`](docs/screens.md).

## Key conventions (these matter)

1. **Every destructive action goes through `confirmDelete()`** from `lib/widgets/confirm_sheet.dart`. No raw `state.deleteX()` calls from the UI.
2. **Currency is always `state.profile.currencySymbol`** — never hard-code `₹`, `$`, etc. The only exceptions: `Profile` constructor default + the preset chip list in `profile_screen.dart`.
3. **No `Theme.of(context)` for app colours.** Pass `theme: AppTheme` explicitly (or read `context.watch<AppState>().theme` in leaf widgets).
4. **`theme.bg` is painted exactly once** — on the outer `Container` in `AppShell.build`. Wrapping screens in another `Container(color: theme.bg)` causes the theme-toggle flicker bug. Don't do it.
5. **Transitions animate bottom-to-top.** Screen switch, add sheet, confirm sheet, tweaks sheet — all slide up.
6. **Lint is intentionally relaxed** — `prefer_const_constructors` and `use_key_in_widget_constructors` are disabled; `deprecated_member_use` is suppressed. Don't add noise fixing those.
7. **Font: `Plus Jakarta Sans`** via `google_fonts`, applied at `MaterialApp` level. Don't override per-widget.
8. **Adding a new domain?** [`docs/contributing.md`](docs/contributing.md) walks through the six edits (model → storage → state → screen → routing → backup).
9. **Scheduled reminders.** Tasks and events have an optional `scheduledAt: DateTime?`. The `NotificationsService` wrapper (`lib/services/notifications_service.dart`) schedules local OS notifications that fire even when the app is closed. Every CRUD mutator on AppState reschedules automatically — don't call the service from the UI directly. See [`docs/notifications.md`](docs/notifications.md).

## Roadmap-shaped holes

- **Sync is a placeholder** — `AppState.syncNow()` only stamps a timestamp. The JSON payload is already the exported backup format, so future work is POSTing it somewhere.
- **Snapshots have no real image storage** yet — `Snapshot.hue` is a placeholder gradient tint.
- **Vault is plain-JSON on disk** — see the security note in [`docs/models.md`](docs/models.md).
- **Task streaks are set manually** — no auto-increment on daily completion.
- **Skincare screen is a placeholder** — no model, no storage; just falls through to `PlaceholderScreen`.

## Claude Code project scaffolding

The repo ships `.claude/` so slash commands and project-specific agents are available when you open the repo in Claude Code:

### Slash commands (`.claude/commands/`)

- **`/icon-regen`** — propagate `assets/icon/app_icon{,_fg}.png` → iOS/Android sizes via `flutter_launcher_icons`.
- **`/add-domain <name>`** — scaffold a new domain end-to-end (model + storage + state + screen + routing + backup + doc row). Follows the existing conventions automatically.
- **`/analyze-fix`** — run `flutter analyze` and fix every issue that isn't in the known baseline (two pre-existing infos).
- **`/ship-apk [version]`** — build a release APK the same way CI does and drop it in `releases/`.
- **`/run-dev [device-id]`** — launch `flutter run` in the background.

### Agents (`.claude/agents/`)

- **`onlyme-explorer`** — use for "how is X wired end-to-end" questions. Knows the 6-touchpoint convention (model → storage → state → screen → backup → docs) and will flag any missing link.
- **`flutter-reviewer`** — reviews uncommitted diffs against the OnlyMe conventions. Catches hard-coded currency, missing `confirmDelete`, theme flicker regressions, missing backup wire-up, missing `reloadFromStorage` updates. Use proactively before asking the user to review.

### Permissions (`.claude/settings.json`)

Pre-approves read-only bash commands (git status/log/diff, ls, cat, grep, find) and the common Flutter commands (`flutter analyze`, `flutter pub get`, `flutter test`, `flutter build`, `flutter pub run flutter_launcher_icons`). Destructive or side-effectful commands still require explicit approval.

## When in doubt

Read in this order:
1. [`docs/README.md`](docs/README.md) — picks the right deep doc.
2. The deep doc it points you to.
3. One existing similar file in the codebase (e.g. `notes_screen.dart` as the template when building a new screen).
