# State management

`lib/app_state.dart` contains a single class, `AppState extends ChangeNotifier`. It is the only source of truth in the app. Every screen reads from it via `context.watch<AppState>()` and every mutation goes through one of its methods.

## Why one big ChangeNotifier?

We considered Bloc, Riverpod, multiple providers, and a repository layer. For ~10 domains with trivial mutations, all of those add more code than the mutations themselves. Rule of thumb: **if the class grows past ~600 lines, split by domain**. Until then, one class is the right tool.

## Lifecycle

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationsService.instance.init();   // timezone DB + plugin channels
  final state = await AppState.load();          // reads SharedPreferences
  runApp(ChangeNotifierProvider.value(
    value: state,
    child: const OnlyMeApp(),
  ));
}
```

`AppState.load()` is the only constructor. It:

1. Opens `LocalStorage` (wraps `SharedPreferences.getInstance()`).
2. Reads every domain key; falls back to seeds or empty lists when a key is missing.
3. Persists a default profile on first launch so `createdAt` is stable.
4. Restores the last active `screen`, accent, dark mode, and last-sync timestamp.
5. Returns the initialised state.

## Fields

| Field | Type | Source |
|---|---|---|
| `tasks` | `List<TaskItem>` | `onlyme:tasks` |
| `debts` | `List<Debt>` | `onlyme:debts` |
| `events` | `List<PlannedEvent>` | `onlyme:events` |
| `gym` | `GymPlan` | `onlyme:gym` (falls back to `seedGymPlan`) |
| `snapshots` | `Map<String, List<Snapshot>>` | `onlyme:snapshots` |
| `weightLogs` | `List<WeightEntry>` | `onlyme:weight` |
| `profile` | `Profile` | `onlyme:profile` (persisted on first launch) |
| `notes` | `List<Note>` | `onlyme:notes` |
| `links` | `List<SavedLink>` | `onlyme:links` |
| `vault` | `List<VaultEntry>` | `onlyme:vault` |
| `expenses` | `List<Expense>` | `onlyme:expenses` |
| `screen` | `String` | `onlyme:screen` |
| `theme` | `AppTheme` | derived from `onlyme:accent` + `onlyme:dark` |
| `lastSyncAt` | `DateTime?` | `onlyme:lastSync` (placeholder — no backend yet) |

## The mutation contract

Every public mutation follows the same shape:

```dart
void addThing(…) {
  thing = <updated>;          // immutable list / replaced object
  storage.writeThing(thing);  // persist immediately
  notifyListeners();           // rebuild all watchers
}
```

Do **not**:
- Mutate lists in-place (use spread / `where` / `map`).
- Call `notifyListeners()` without writing to storage first.
- Call `NotificationsService` directly from the UI — go through AppState mutators.

## Notification integration

Domains with `scheduledAt` fields wire `NotificationsService` inside their mutators via two private helpers:

```dart
void _rescheduleTask(TaskItem t) {
  // cancels if done or no scheduledAt; otherwise schedules with isAlarm flag
}

void _rescheduleEvent(PlannedEvent e) {
  // cancels if no scheduledAt; otherwise schedules both at-time + day-before
}
```

Every `addTask`, `editTask`, `toggleTask`, `addEvent`, `editEvent` calls the appropriate helper. `deleteTask` / `deleteEvent` call `cancelTask` / `cancelEvent` directly.

```dart
Future<void> replayScheduledNotifications() async {
  // Re-arms all future task + event reminders from current state.
  // Called: (a) on app startup in main.dart, (b) after import.
}
```

## Profile mutations

```dart
void setAlarmSound({required String? path, required String? name}) {
  // Stores custom alarm sound path+name in profile.
  // Pass null/null to clear.
}
```

Also: `setAccent(AccentKey)`, `setDark(bool)`, `setScreen(String)`, `syncNow()` (placeholder), `reloadFromStorage()`.

## `reloadFromStorage()`

Reads every domain from storage into the in-memory fields, then calls `notifyListeners()`. Called after import to make the UI reflect the restored data without restarting the app.

## Adding a new domain

See [contributing.md](contributing.md). The short version: add a `late List<Thing> things` field, initialise it in `load()` and `reloadFromStorage()`, add `addThing / editThing / deleteThing`, call `storage.writeThing(...)` + `notifyListeners()` in each.
