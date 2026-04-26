# Notifications

OnlyMe uses **on-device scheduled notifications** via `flutter_local_notifications`. The OS fires them at the requested time even when the app is closed or the device has rebooted. There is no FCM / APNs / server component — consistent with the app's local-only posture.

## Delivery modes

Each task and event reminder supports two delivery modes, selectable in the add/edit sheet when a date+time is set:

| Mode | Android | iOS | Use for |
|---|---|---|---|
| **Notification** (default) | `exactAllowWhileIdle` — high-priority, survives Doze but subject to OEM battery killers | `timeSensitive` interruption level | Soft reminders that respect silent mode |
| **Alarm** | `alarmClock` (setAlarmClock API) — highest priority, exempt from Doze + most OEM optimisations, shows clock icon in status bar | `critical` interruption level | Wake-up alarms, medication, deadlines |

Alarm mode also plays at **alarm volume** — it bypasses silent/vibrate mode on Android via the `onlyme_alarms` channel with `AudioAttributesUsage.alarm`.

## What can be scheduled

| Domain | Trigger | Fires |
|---|---|---|
| `TaskItem.scheduledAt` | "No reminder" row in the Task add/edit sheet | Once, at the chosen date + time |
| `PlannedEvent.scheduledAt` | "No reminder" row in the Event add/edit sheet | Twice: 24 h before (normal mode only), and at the chosen time |

The day-before event notification always uses `exactAllowWhileIdle` regardless of the event's `isAlarm` flag — it is advisory, not an alarm.

Tasks and events without a `scheduledAt` generate no notifications. The app is fully usable without granting any permission.

## Architecture

```
lib/services/notifications_service.dart   ← single wrapper around the plugin
  ├─ init()                               — timezone DB + plugin init (called from main())
  ├─ hasNotificationPermission()          — real-time POST_NOTIFICATIONS status
  ├─ hasExactAlarmPermission()            — real-time SCHEDULE_EXACT_ALARM status
  ├─ isBatteryOptimizationDisabled()      — real-time battery unrestricted status
  ├─ requestPermission()                  — iOS/Android prompt
  ├─ openExactAlarmSettings()             — opens "Alarms & reminders" special-access page
  ├─ requestBatteryOptimizationExemption()— opens battery optimisation settings
  ├─ scheduleTask({id, title, body, at, isAlarm})
  ├─ cancelTask(id)
  ├─ scheduleEvent({id, title, body, at, isAlarm}) — schedules at-time + day-before
  ├─ cancelEvent(id)                      — cancels both slots
  ├─ cancelAll()
  ├─ pending()                            — for debugging
  └─ sendTestNotification()               — schedules a test 10 s from now; returns "ok" or error
```

Every task/event CRUD method in `AppState` reschedules automatically:

- `addTask` / `addEvent` → schedule if `scheduledAt` set.
- `editTask` / `editEvent` → cancel existing + schedule new (or cancel if cleared).
- `toggleTask` → cancel when marked done, re-schedule if uncompleted and future.
- `deleteTask` / `deleteEvent` → cancel all notification slots.

Two private helpers — `_rescheduleTask` and `_rescheduleEvent` — encapsulate the cancel-then-reschedule flow. If you add a new mutation that changes `scheduledAt` or `isAlarm`, call the appropriate helper.

## Notification channels (Android)

| Channel ID | Name | Importance | Notes |
|---|---|---|---|
| `onlyme_tasks` | Task reminders | High | Normal task notifications |
| `onlyme_events` | Event reminders | High | Normal event notifications |
| `onlyme_alarms` | Alarms | Max | Alarm-mode; plays at alarm volume (`AudioAttributesUsage.alarm`); `fullScreenIntent: true` |

## Notification IDs

The plugin requires 32-bit integer IDs derived from the domain `id` (milliseconds-since-epoch):

- **Tasks:** `id & 0x7FFFFFFE` — LSB cleared, top bit cleared (positive).
- **Events at-time:** `id & 0x7FFFFFFE` — same formula, different channel.
- **Events day-before:** `(id & 0x7FFFFFFE) | 1` — LSB set, distinct from the at-time slot.
- **Test notification:** `0x7FFFFFF0` — fixed constant, never collides with user data.

## Permission flow

Permissions are **never requested at app launch**. On Android 12+, `SCHEDULE_EXACT_ALARM` requires explicit user action in **Settings → Special app access → Alarms & reminders** — a manifest declaration alone is insufficient.

Three permissions matter:

| Permission | Why needed | What happens without it |
|---|---|---|
| `POST_NOTIFICATIONS` (Android 13+) | Show notification banners | Notifications fire but are invisible |
| `SCHEDULE_EXACT_ALARM` (Android 12+) | Fire at exact time | Falls back to inexact (±15 min drift) |
| Battery unrestricted | AlarmManager survives OEM battery killers | Alarms may not fire after app is cleared from recents |

### Checking status from the UI

**More → Notifications** shows real-time status of all three with direct action buttons. Status auto-refreshes via `WidgetsBindingObserver.didChangeAppLifecycleState` when the user returns from the Settings app.

## Custom alarm sound

Users can set a custom alarm sound in **More → Alarm Sound**:

1. `FilePicker` picks any audio file.
2. File is copied to `<app-documents>/alarms/alarm_sound.<ext>`.
3. Path + display name stored in `Profile.alarmSoundPath` / `Profile.alarmSoundName` via `AppState.setAlarmSound(...)`.

On iOS the sound field is not currently wired (uses system default).

## Reliability

- **iOS:** OS retains pending `UNNotificationRequest` across kills and reboots.
- **Android:** `ScheduledNotificationBootReceiver` in `AndroidManifest.xml` re-arms `AlarmManager` entries on `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED`.
- **AlarmClock mode** (`isAlarm=true`) uses `setAlarmClock()` — exempt from Doze, survives app cleared from recents, shown as a system clock alarm.
- **Fresh install:** `AppState.replayScheduledNotifications()` runs on every launch, re-scheduling all future tasks/events. Idempotent.

## Backup

`scheduledAt` and `isAlarm` round-trip through export/import. The custom alarm sound is base64-encoded into the backup under `profile.alarmSoundData` + `profile.alarmSoundExt`. After import, `replayScheduledNotifications()` is called automatically so reminders fire on the new device.

## Required Android manifest entries

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>

<!-- ScheduledNotificationReceiver must be exported so AlarmManager can deliver -->
<receiver android:exported="true"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
```

## Testing

1. Run on a real device (simulators drop scheduled notifications after sleep).
2. Go to **More → Notifications** — verify all three permission rows show "Granted".
3. Tap "Send test notification" — notification should arrive ~10 s later.
4. Create a task, set reminder 2 min in the future, background the app — notification fires.
5. Alarm mode: toggle "Alarm mode" on, set device to silent — notification still plays at alarm volume.
6. Boot test: set a future reminder, reboot — notification fires at the scheduled time.

## Open work

- Global notification master-toggle (mute all without revoking OS permission).
- Recurring schedules (`DateTimeComponents.time` for daily reminders).
- Custom alarm sound on iOS.

## Why local and not FCM?

The app has no backend. Local notifications achieve the same outcome without any network or account infrastructure, consistent with OnlyMe's privacy-first design.
