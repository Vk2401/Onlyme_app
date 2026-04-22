# Backup (Export / Import)

The app has no server, so "backup" means **a single JSON file the user carries themselves**. The feature lives in `lib/storage/export_io.dart` and in the `Backup` section of `MoreScreen`.

## Payload shape

```json
{
  "app": "onlyme",
  "version": 1,
  "exportedAt": "2026-04-22T14:13:00.000",
  "data": {
    "tasks": [...],
    "debts": [...],
    "events": [...],
    "gym": { ... },
    "snapshots": { "hair": [...], "body": [...], "skin": [...] },
    "weightLogs": [...],
    "profile": { ... },
    "notes": [...],
    "links": [...],
    "vault": [...],
    "accent": "mint",
    "dark": true
  }
}
```

Every array element/object is the model's `toJson()` output. Import uses the same model's `fromJson()`.

## Export flow

`exportAll(state)` is called from `MoreScreen._runExport`:

1. Build the payload map (every domain + theme).
2. `jsonEncode` to a string.
3. Write to `<temp>/onlyme-backup-YYYYMMDD-HHMM.json` via `path_provider.getTemporaryDirectory`.
4. Hand the file to the native share sheet via `share_plus` (`Share.shareXFiles([XFile(path)])`).

The temp file lives until the OS cleans the temp dir. We don't delete it ourselves — the user may need to re-share from the share sheet.

## Import flow

`importAll(state, File)` is called from `MoreScreen._runImport`:

1. Confirm overwrite via `confirmDelete(...)` (styled with a red "Choose file" button; the message warns about data replacement).
2. `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'])`.
3. Read the JSON, validate `app == 'onlyme'` and `version <= _kPayloadVersion`.
4. For each domain field present in `data`, decode via the model's `fromJson` and call the corresponding `LocalStorage.writeX(...)`.
5. Call `AppState.reloadFromStorage()` to refresh every in-memory field + the theme.
6. SnackBar with the result.

Missing keys are **silently skipped** — this makes old backups forward-compatible with new domains (they just won't overwrite what's there).

## Error handling

Every failure path returns an `ImportResult(false, message)` and surfaces via SnackBar. We do not auto-retry, we do not partial-restore. If `vault` parsing fails mid-decode, the previous storage value stays untouched.

## Evolving the payload

- **Additive (safe):** adding a new top-level field under `data` — old app versions ignore it, new app versions fall back to `[]`/default when absent.
- **Renamed field:** bump `_kPayloadVersion` to `2`. Keep the version check at `map['version'] > _kPayloadVersion` so old backups still import into new app versions.
- **Breaking:** bump `_kPayloadVersion` to `2` **and** add a migration branch inside `importAll` that reads both shapes. Write a test for the old shape.

## Why the temp directory?

Some platforms (Android 13+, iOS sandboxing) prevent apps from writing outside their own container. `getTemporaryDirectory()` is always writable; the share sheet copies the file into the user's chosen destination (Files / iCloud / AirDrop / email / Drive).

## What's **not** in the backup

- `lastSyncAt` — not useful to restore.
- `screen` — the last active screen. Not useful to restore either; the UI lands on the last tab the *importing* user was viewing.
- App version — the payload's `version` field is the schema version, not the app version.

## Security

The vault is stored **unencrypted** in the backup file, because it's stored unencrypted on disk to begin with. If you encrypt the on-disk vault in the future, you must also encrypt it in the backup or decide to strip vault entries from the payload.
