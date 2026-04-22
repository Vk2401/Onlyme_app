# State management

`lib/app_state.dart` contains a single class, `AppState extends ChangeNotifier`. It is the only source of truth in the app. Every screen reads from it via `context.watch<AppState>()` and every mutation goes through one of its methods.

## Why one big ChangeNotifier?

We considered Bloc, Riverpod, multiple providers, and a repository layer. For ~10 domains with trivial mutations, all of those would add more code than the mutations themselves. The rule of thumb: **if the class grows past ~600 lines, split by domain**. Until then, one class is the right tool.

## Lifecycle

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();       // reads SharedPreferences
  runApp(ChangeNotifierProvider.value(
    value: state,
    child: const OnlyMeApp(),
  ));
}
```

`AppState.load()` is the only constructor. It:

1. Opens `LocalStorage` (wraps `SharedPreferences.getInstance()`).
2. Reads every domain key; falls back to seeds or empty lists when a key is missing.
3. Persists a default profile on first launch so `createdAt` is stable (used for "Since Apr 2026" in More).
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
| `screen` | `String` | `onlyme:screen` |
| `theme` | `AppTheme` | derived from `onlyme:accent` + `onlyme:dark` |
| `lastSyncAt` | `DateTime?` | `onlyme:lastSync` (placeholder — no backend yet) |

## The mutation contract

Every public mutation follows the same shape:

```dart
void addThing(…) {
  thing = <updated>;         // immutable list / replaced object
  storage.writeThing(thing); // persist
  notifyListeners();         // rebuild all watchers
}
```

Do **not**:

- Mutate list elements in place (always use spreads or `map`).
- Skip `storage.writeX`. If the app is killed, the change is lost.
- Skip `notifyListeners()`. The UI will go stale.
- Push the mutation into the widget layer. All mutations go through `AppState`.

## Reading state

```dart
// subscribe + rebuild on change
final state = context.watch<AppState>();

// one-shot read inside a callback (does not subscribe)
context.read<AppState>().deleteTask(id);
```

For widgets deep in the tree that only need the theme, it's fine to read it via a parameter passed from the parent — that's the convention across this repo.

## Full-reload (used by import)

`AppState.reloadFromStorage()` re-reads every key and refreshes every field + the theme, then notifies. It's used *only* by `lib/storage/export_io.dart` after an import overwrites everything on disk. Don't call it from UI code — ordinary mutations update state directly.

## Debugging

- **Why didn't my screen rebuild?** You used `context.read<AppState>()` in `build` instead of `watch`.
- **Why is the value stale after a hot restart?** You forgot to call `storage.writeX(…)` in the mutator.
- **Why is my new field `null` on first launch?** You didn't initialise it in `AppState.load()`.
