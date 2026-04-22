# Storage

All persistence lives in `lib/storage/local_storage.dart`. It is a thin wrapper around `shared_preferences`. Every domain is stored as a single JSON string under a key prefixed `onlyme:`.

## Keys

| Constant | Key | Payload |
|---|---|---|
| `_kTasks` | `onlyme:tasks` | `List<TaskItem>.toJson()` |
| `_kDebts` | `onlyme:debts` | `List<Debt>.toJson()` |
| `_kEvents` | `onlyme:events` | `List<PlannedEvent>.toJson()` |
| `_kGym` | `onlyme:gym` | `GymPlan.toJson()` |
| `_kSnapshots` | `onlyme:snapshots` | `Map<String, List<Snapshot>>.toJson()` |
| `_kWeight` | `onlyme:weight` | `List<WeightEntry>.toJson()` |
| `_kProfile` | `onlyme:profile` | `Profile.toJson()` |
| `_kNotes` | `onlyme:notes` | `List<Note>.toJson()` |
| `_kLinks` | `onlyme:links` | `List<SavedLink>.toJson()` |
| `_kVault` | `onlyme:vault` | `List<VaultEntry>.toJson()` |
| `_kScreen` | `onlyme:screen` | current screen key (`home`, `tasks`, …) |
| `_kAccent` | `onlyme:accent` | `AccentKey.name` |
| `_kDark` | `onlyme:dark` | `bool` |
| `_kLastSync` | `onlyme:lastSync` | ISO8601 timestamp |

## Pattern for adding a new domain

1. Add `_kThing = 'onlyme:thing'`.
2. Add `readThing() -> List<Thing>?` and `writeThing(List<Thing>)`.
3. Both methods JSON-encode via the model's `toJson` / `fromJson`. See `readNotes`/`writeNotes` for the one-line template.

## Migrations

The schema has no explicit version field on disk. Backward compatibility is instead enforced in each `fromJson`:

- New nullable fields — read with `j['x'] as String?` and default.
- New non-null fields — read with `(j['x'] as int?) ?? <fallback>`.
- Currency default: `(j['currencySymbol'] as String?) ?? '₹'` — see `Profile.fromJson`.

If you ever need to break compatibility, introduce a wrapper JSON with `{ "version": N, "data": {…} }` at the storage-key level and migrate in `LocalStorage.readThing`.

## Why SharedPreferences (and not sqflite, Hive, Isar)?

The data is small (tens of KB per user), entirely read/written in bulk per domain, and never queried. A key-value store with JSON blobs has zero schema-migration cost and makes the export/import feature a memcpy. If the app ever grows query needs (e.g. "tasks due this week indexed by category"), a proper DB is a straightforward migration, but today it'd be overkill.

## Export/import

`lib/storage/export_io.dart` serialises every domain + the theme into a single JSON document and hands it to the OS share sheet (`share_plus`). Import does the reverse via `file_picker` and then calls `AppState.reloadFromStorage()`. Full details in [backup.md](backup.md).
