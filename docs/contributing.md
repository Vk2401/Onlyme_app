# Contributing

This is a personal project but the following conventions keep the codebase consistent, so please follow them.

## Before you commit

1. `flutter analyze` — should still report only the two pre-existing infos (see [ci.md](ci.md)).
2. Run the relevant screen on a simulator and try the feature end-to-end. The two pre-existing infos don't warrant a fix in an unrelated PR; new issues do.

## Adding a new domain

Concrete walkthrough based on the Notes feature.

### 1. Model — `lib/models/your_thing.dart`

Copy `note.dart` as a template. Every model has:

- An `int id` (timestamp-based).
- `copyWith`, `toJson`, `fromJson`.
- Optional fields are nullable + `copyWith({bool clearX = false})` for explicit null.

### 2. Storage — `lib/storage/local_storage.dart`

Add three lines:

```dart
static const _kThing = 'onlyme:thing';

List<Thing>? readThing() { /* jsonDecode pattern, see readNotes */ }
Future<void> writeThing(List<Thing> t) =>
    _p.setString(_kThing, jsonEncode(t.map((e) => e.toJson()).toList()));
```

### 3. State — `lib/app_state.dart`

- Add `late List<Thing> thing;` to the field block.
- Initialise in `AppState.load()`: `state.thing = s.readThing() ?? [];`.
- Add `addThing / editThing / deleteThing` mutation methods.
- Add `thing = storage.readThing() ?? [];` to `reloadFromStorage()`.

### 4. Screen — `lib/screens/your_thing_screen.dart`

Copy `notes_screen.dart`. Every screen has:

- `ListView` root (no Scaffold).
- `AppHeader` at the top with a `+` button opening the add sheet.
- Empty state in an `AppCard` if the list is empty.
- Swipe-to-delete rows wrapping in `confirmDismiss: (_) => confirmDelete(...)`.

### 5. Wire it

- Add a `case 'thing': content = const ThingScreen(); break;` to `AppShell`.
- Add a row to `MoreScreen` in the appropriate section, with a real sub-text computed from state.
- Optionally add an option to `AddSheet` (quick-add grid) and an icon key in `app_icons.dart`.

### 6. Backup

Update `lib/storage/export_io.dart`:

- Add `'thing': state.thing.map((t) => t.toJson()).toList()` to the `data` map in `exportAll`.
- Add a decode branch in `importAll` that calls `LocalStorage.writeThing(...)`.

That's it. No routes to configure, no providers to register, no generated code to run.

### 7. (Optional) Scheduled reminders

If the domain has a `scheduledAt: DateTime?` field, follow the Tasks / Events pattern:

- Add `bool isAlarm = false` to the model. Update `copyWith`, `toJson` (`'isAlarm': isAlarm`), and `fromJson` (`j['isAlarm'] as bool? ?? false`).
- Add a private `_rescheduleThing(Thing t)` helper to `AppState` that calls `NotificationsService.instance.scheduleTask(...)` or `cancelTask(...)`. Wire it into every mutator that touches `scheduledAt` or `isAlarm`.
- Add `cancelTask(id)` / `cancelEvent(id)` in `deleteThing`.
- Include `replayScheduledNotifications` coverage for the new domain.
- Add an alarm-mode toggle in the add/edit sheet (shown only when `scheduledAt != null`), using the `_AlarmToggleRow` design from `tasks_screen.dart` as a template.
- See [notifications.md](notifications.md) for full details.

## Code style

- Dart `format` is on by default; there's no CI formatter check, but keep lines ≤100 chars.
- Prefer `Widget` trees over helper methods. Only split if the tree exceeds ~40 lines or is reused.
- No comments explaining *what* — use self-documenting names. Comments for *why* (non-obvious constraints, workarounds) are welcome.
- Don't introduce new dependencies without a clear reason. We have ~7 runtime deps; keep the bar high.

## Deletions

Every destructive action **must** go through `confirmDelete()` from `lib/widgets/confirm_sheet.dart`. No exceptions — a user expects a confirmation before losing data.

## Currency

Never hard-code `₹`, `$`, or any symbol. Read `state.profile.currencySymbol` at the render site. If the render is deep in a widget tree without `state`, either pass it down from the parent or use `context.watch<AppState>().profile.currencySymbol`.

## Theme

- Pass `theme: AppTheme` explicitly to widgets.
- Don't use `Theme.of(context)` for app colours — only Flutter's own Material widgets do that.
- If a widget needs re-rendering on accent change, it must be reached from a `context.watch<AppState>()`.

## Transitions

Screen transitions are bottom-to-top (`_IosSwitchTransition` in `app.dart`). Sheets animate up from the bottom. Keep new animations consistent.

## PRs

- Small, focused PRs. One feature or one fix.
- Title under 70 chars.
- Body: summary bullets + test plan checklist (the existing CLAUDE Code workflow helps with this).
- CI must pass.
