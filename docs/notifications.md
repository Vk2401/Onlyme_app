# Notifications

OnlyMe uses **on-device scheduled notifications** via `flutter_local_notifications`. The OS fires them at the requested time even when the app is closed or the device has rebooted. There is no FCM / APNs / server component — this is consistent with the app's local-only posture.

## What can be scheduled

| Domain | Trigger | Fires |
|---|---|---|
| `TaskItem.scheduledAt` | Set in the Task add/edit sheet via the "No reminder" row | Once, at the chosen date + time |
| `PlannedEvent.scheduledAt` | Set in the Event add/edit sheet | Twice: 24h before, and at the chosen time |

Tasks and events without a `scheduledAt` generate no notifications — they behave exactly as before. The app is fully usable without granting notification permission.

## Architecture

```
lib/services/notifications_service.dart   ← single wrapper around the plugin
  ├─ init()                                 — timezone DB + plugin init (called from main())
  ├─ requestPermission()                    — iOS/Android prompt, called lazily
  ├─ scheduleTask({id, title, body, at})
  ├─ cancelTask(id)
  ├─ scheduleEvent({id, title, body, at})   — schedules BOTH at-time and day-before
  ├─ cancelEvent(id)                        — cancels both slots
  ├─ cancelAll()
  └─ pending()                              — for debugging
```

Every task/event CRUD method in `AppState` reschedules automatically:

- `addTask` / `addEvent` → schedule if `scheduledAt` set.
- `editTask` / `editEvent` → cancel existing + schedule new (or cancel if cleared).
- `toggleTask` → cancel when marked done, re-schedule if uncompleted and future.
- `deleteTask` / `deleteEvent` → cancel.

Two private helpers on `AppState` — `_rescheduleTask` and `_rescheduleEvent` — encapsulate the cancel-then-reschedule flow. If you add a new mutation that changes `scheduledAt`, call the appropriate helper.

## Notification IDs

The plugin requires integer IDs. We derive them from the domain `id` (which is a milliseconds-since-epoch):

- **Tasks:** `id & 0x7FFFFFFE` — the low bit is cleared so the integer fits Android's 31-bit constraint and doesn't collide with the event day-before slot.
- **Events:** reserves two slots. `id & 0x7FFFFFFE` for at-time, `(id & 0x7FFFFFFE) | 1` for day-before.

Consequence: two domain records created in the same millisecond would collide. Practically impossible since ids come from `DateTime.now().millisecondsSinceEpoch` in user-driven code.

## Permission flow

We do NOT request notification permission at app launch — Apple's guidelines and Android 13+ UX both recommend requesting permissions only when they're about to be used. `NotificationsService._ensureReadyAndPermitted` is called from every `scheduleX`; the first call triggers:

1. **iOS:** `DarwinFlutterLocalNotificationsPlugin.requestPermissions(alert, badge, sound)` — the standard system prompt.
2. **Android:** `requestNotificationsPermission()` (for Android 13+) AND `requestExactAlarmsPermission()` (for Android 12+). Exact alarms are optional — if denied, notifications still fire but can drift by up to ~15 minutes.

If the user denies either, `requestPermission` returns `false`. We don't block — we still call `zonedSchedule`, it silently no-ops on iOS, and on Android it falls back to inexact delivery. The user can grant later via System Settings.

## What happens when the app is killed / the device reboots

- **iOS:** The OS retains every pending `UNNotificationRequest` for the app's bundle ID. Kill the app — notifications still fire. Reboot — still fire (the OS persists them).
- **Android:** Scheduled alarms are persisted across reboots thanks to the `ScheduledNotificationBootReceiver` we register in `AndroidManifest.xml` with `RECEIVE_BOOT_COMPLETED`. The plugin re-arms the alarm manager on `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED`.
- **Fresh install (or OS version migration that wipes scheduled alarms):** `AppState.replayScheduledNotifications()` runs on every app launch after `NotificationsService.init()`. It iterates every task/event whose `scheduledAt` is still in the future and re-schedules them, best-effort. This is idempotent — re-calling `scheduleX` with the same ID replaces the existing pending notification.

## Backup

`scheduledAt` is part of every task/event `toJson` / `fromJson`, so it round-trips through the export/import pipeline in `lib/storage/export_io.dart`. After import, `importAll` calls `AppState.reloadFromStorage()` and then `replayScheduledNotifications()`, so imported reminders start firing automatically on the new device.

## Testing manually

1. `flutter run` on a real device (simulators sometimes drop scheduled notifications after a long sleep).
2. Create a task, tap the bell row, set a date + time 2 minutes in the future, save.
3. Background the app (home button). Wait. The OS fires the alert at the chosen time.
4. Repeat with an event for 2 days out — the day-before notification should land ~24h early.

## Open work

- Global "Notifications" master-toggle in the Tweaks sheet or Profile so users can silence the app without uninstalling or revoking OS permission.
- Recurring schedules (daily / weekly) — the plugin supports `matchDateTimeComponents: DateTimeComponents.time` for daily; wiring this up needs a `RepeatRule` enum on `TaskItem`.

## Why local and not FCM?

The app has no backend. FCM would require a server to deliver pushes + identity on the device. Local notifications achieve the same user outcome ("the phone buzzes at the scheduled time") without any network or account infrastructure, which is the whole point of OnlyMe.
