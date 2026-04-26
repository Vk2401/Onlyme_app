# Backup (Export / Import)

The app has no server, so "backup" means **a single JSON file the user carries themselves**. The feature lives in `lib/storage/export_io.dart` and in the **Backup** section of `MoreScreen`.

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
    "profile": {
      "name": "...",
      "currencySymbol": "₹",
      "alarmSoundData": "<base64>",
      "alarmSoundExt": "mp3"
    },
    "notes": [...],
    "links": [...],
    "vault": [...],
    "expenses": [...],
    "accent": "mint",
    "dark": true
  }
}
```

Every array element / object is the model's `toJson()` output. Import uses each model's `fromJson()`.

### Binary assets in the payload

| Asset | Export | Import |
|---|---|---|
| Snapshot images (`imagePath`) | `imagePath` stripped; file base64-encoded into `imageData` on each snapshot entry | `imageData` decoded → saved to `<documents>/snapshots/snap_<id>.jpg` |
| Alarm sound (`alarmSoundPath`) | `alarmSoundPath` stripped; file base64-encoded into `profile.alarmSoundData`; extension into `profile.alarmSoundExt` | `alarmSoundData` decoded → saved to `<documents>/alarms/alarm_sound.<ext>` |

## Export flow

`exportAll(state)` is called from `MoreScreen._runExport`:

1. Build the payload map (all domains + theme).
2. For each snapshot with `imagePath`, read the file, base64-encode it into `imageData`, remove `imagePath`.
3. For `profile.alarmSoundPath`, base64-encode the file into `alarmSoundData`; add `alarmSoundExt`.
4. `jsonEncode` the payload to a string.
5. Write to `<temp>/onlyme-backup-YYYYMMDD-HHMM.json` via `path_provider`.
6. Hand the file to the native share sheet via `share_plus`.

## Import flow

`importAll(state, File)` is called from `MoreScreen._runImport`:

1. Confirm overwrite via `confirmDelete(...)`.
2. `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'])`.
3. Read + validate `app == 'onlyme'` and `version <= _kPayloadVersion`.
4. For each domain key present in `data`, decode via the model's `fromJson` and call `LocalStorage.writeX(...)`.
5. Snapshot `imageData` entries are decoded and written to `<documents>/snapshots/`.
6. `profile.alarmSoundData` is decoded and written to `<documents>/alarms/alarm_sound.<ext>`.
7. Call `AppState.reloadFromStorage()` to refresh all in-memory state.
8. Call `AppState.replayScheduledNotifications()` so imported task/event reminders start firing.
9. Show result via SnackBar.

Missing keys are **silently skipped** — old backups are forward-compatible with new domains.

## Error handling

Every failure returns `ImportResult(false, message)` and surfaces via SnackBar. No partial restore — if `vault` parsing fails mid-decode, the previous storage value is untouched (write-on-success only).

## Evolving the payload

| Change | Approach |
|---|---|
| Add a new domain | Add a key to `data` in `exportAll` + a decode branch in `importAll`. Old app versions ignore it; new app versions fall back to `[]` when absent. |
| Rename a field | Bump `_kPayloadVersion` to 2. Keep the version check so old backups still import. |
| Breaking change | Bump version + add a migration branch that reads both shapes. Write a test for the old shape. |

## Why the temp directory?

Android 13+ and iOS sandboxing prevent writes outside the app container. `getTemporaryDirectory()` is always writable; the share sheet copies the file to the user's chosen destination (Files / Drive / email / AirDrop).

## What is **not** in the backup

- `lastSyncAt` — not useful to restore.
- `screen` — last active screen. The importing user starts on their own last tab.
- App version — `version` is the schema version, not the app version.

## Security

The vault is stored **unencrypted** in the backup because it's unencrypted on disk. If you encrypt the on-disk vault in the future, also encrypt it in the backup.
