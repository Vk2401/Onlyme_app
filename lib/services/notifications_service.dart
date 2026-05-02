import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications so the rest of the app never sees the
/// plugin directly.
///
/// Two delivery modes:
///   * Normal (isAlarm=false) — high-priority notification, uses
///     exactAllowWhileIdle so it survives Doze mode but is still subject to
///     OEM battery-killer policies.
///   * Alarm (isAlarm=true) — uses setAlarmClock(), the highest-priority
///     Android alarm type. Shows a clock icon in the status bar, is exempt
///     from Doze and from most OEM battery optimisations, and fires reliably
///     after the app is removed from recents. On iOS the same notification
///     is promoted to time-sensitive interruption level.
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // IDs: tasks use id as-is; events reserve two slots (even=at-time, odd=day-before).
  static int _taskId(int domainId) => domainId & 0x7FFFFFFE;
  static int _eventAtId(int domainId) => domainId & 0x7FFFFFFE;
  static int _eventDayBeforeId(int domainId) => (domainId & 0x7FFFFFFE) | 1;
  static const _kTestId = 0x7FFFFFF0;

  // Channel IDs
  static const _chTasksId = 'onlyme_tasks';
  static const _chEventsId = 'onlyme_events';
  static const _chAlarmsId = 'onlyme_alarms';

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local));
    } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()!;

      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _chTasksId,
        'Task reminders',
        description: 'Reminders for scheduled tasks',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _chEventsId,
        'Event reminders',
        description: 'Reminders for planned events',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _chAlarmsId,
        'Alarms',
        description: 'Alarm-mode reminders — plays at alarm volume',
        importance: Importance.max,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
      ));

      // flutter_local_notifications v17 changed its Gson serialisation format.
      // Notifications saved by any older version cause "Missing type parameter"
      // when v17 tries to deserialise them inside saveScheduledNotification.
      // Run once: clear the stale cache so new notifications can be written;
      // AppState.replayScheduledNotifications() re-arms everything afterward.
      await _migrateStaleCache();
    }

    _ready = true;
  }

  // Runs once per install/upgrade. Clears the plugin's SharedPreferences cache
  // if it contains data in an incompatible format.
  //
  // Key is versioned: v2 forces a re-run on devices where the v1 migration ran
  // but used the wrong filename ('notification_plugin_cache.xml') and therefore
  // never actually cleared anything.
  Future<void> _migrateStaleCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const migratedKey = 'notif_cache_cleared_v2';
      if (prefs.getBool(migratedKey) == true) return;

      // pendingNotificationRequests() calls loadScheduledNotifications internally.
      // If it throws, the stored data is in an incompatible format.
      bool cacheOk = false;
      try {
        await _plugin.pendingNotificationRequests();
        cacheOk = true;
      } catch (_) {}

      if (!cacheOk) {
        // cancelAll() also reads before cancelling and may throw too — try it
        // anyway, then fall through to direct file deletion.
        try {
          await _plugin.cancelAll();
        } catch (_) {}

        // Delete the plugin's SharedPreferences XML directly.
        // The plugin stores scheduled notifications in a file called
        // "notification_details" (SharedPreferences name = file stem).
        // On Android that lives at <data-dir>/shared_prefs/notification_details.xml.
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final cacheFile = File(
            '${appDir.parent.path}/shared_prefs/notification_details.xml',
          );
          if (await cacheFile.exists()) await cacheFile.delete();
        } catch (_) {}
      }

      await prefs.setBool(migratedKey, true);
    } catch (_) {}
  }

  // ── Permission checks ─────────────────────────────────────────────────────

  /// POST_NOTIFICATIONS (Android 13+) or equivalent.
  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    return (await Permission.notification.status).isGranted;
  }

  /// SCHEDULE_EXACT_ALARM — must be user-granted in Special app access on Android 12+.
  /// Without this, exactAllowWhileIdle falls back to inexact (may be delayed >15 min).
  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (_) {
      return true; // Android < 12 — permission doesn't exist, assume granted
    }
  }

  /// Battery optimisation exemption — if not exempt the OS may kill the
  /// AlarmManager receiver on some OEMs when the app is cleared from recents.
  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    try {
      return (await Permission.ignoreBatteryOptimizations.status).isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Request POST_NOTIFICATIONS + exact alarm permission.
  Future<void> requestPermission() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }
    if (Platform.isAndroid) {
      await Permission.notification.request();
      // requestExactAlarmsPermission opens the "Alarms & reminders" settings
      // page on Android 12+ so the user can grant it manually.
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestExactAlarmsPermission();
    }
  }

  /// Open the "Alarms & reminders" special-access page (Android 12+).
  Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}
  }

  /// Open battery-optimisation exemption settings.
  Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    try {
      await Permission.ignoreBatteryOptimizations.request();
    } catch (_) {}
  }

  // ── Schedule / cancel API ─────────────────────────────────────────────────

  Future<void> scheduleTask({
    required int id,
    required String title,
    String? body,
    required DateTime at,
    bool isAlarm = false,
  }) async {
    if (!_ready) await init();
    if (at.isBefore(DateTime.now())) return;
    await _scheduleWithFallback(
      id: _taskId(id),
      title: title,
      body: body ?? 'Task reminder',
      at: at,
      isAlarm: isAlarm,
      payload: 'task:$id',
    );
  }

  Future<void> cancelTask(int id) => _plugin.cancel(_taskId(id));

  Future<void> scheduleEvent({
    required int id,
    required String title,
    String? body,
    required DateTime at,
    bool isAlarm = false,
  }) async {
    if (!_ready) await init();
    final now = DateTime.now();
    try {
      if (at.isAfter(now)) {
        await _scheduleWithFallback(
          id: _eventAtId(id),
          title: title,
          body: body ?? 'Event starting',
          at: at,
          isAlarm: isAlarm,
          payload: 'event:$id',
          normalDetails: _eventDetails(),
        );
      } else {
        await _plugin.cancel(_eventAtId(id));
      }

      final dayBefore = at.subtract(const Duration(days: 1));
      if (dayBefore.isAfter(now)) {
        await _scheduleWithFallback(
          id: _eventDayBeforeId(id),
          title: 'Tomorrow: $title',
          body: body ?? 'Event in 1 day',
          at: dayBefore,
          isAlarm: false,
          payload: 'event:$id',
          normalDetails: _eventDetails(),
        );
      } else {
        await _plugin.cancel(_eventDayBeforeId(id));
      }
    } catch (_) {}
  }

  Future<void> cancelEvent(int id) async {
    await _plugin.cancel(_eventAtId(id));
    await _plugin.cancel(_eventDayBeforeId(id));
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  /// Schedules a test notification 10 seconds from now.
  /// Use this to verify the pipeline works end-to-end.
  Future<String> sendTestNotification() async {
    if (!_ready) await init();
    try {
      final at = DateTime.now().add(const Duration(seconds: 10));
      await _scheduleWithFallback(
        id: _kTestId,
        title: 'Test notification',
        body: 'Notifications are working! ✓',
        at: at,
        isAlarm: false,
        payload: '',
      );
      return 'ok';
    } catch (e) {
      return 'error: $e';
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Schedules a notification with a three-tier fallback:
  ///   1. alarmClock (if isAlarm=true) — requires SCHEDULE_EXACT_ALARM on API 34+
  ///   2. exactAllowWhileIdle — requires SCHEDULE_EXACT_ALARM on API 31+
  ///   3. inexact — fires within ~15 min window, no special permission needed
  ///
  /// This ensures something always fires even when the user hasn't granted the
  /// exact-alarm special permission yet.
  Future<void> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required bool isAlarm,
    required String payload,
    NotificationDetails? normalDetails,
  }) async {
    final tzAt = tz.TZDateTime.from(at, tz.local);
    final details = isAlarm ? _alarmDetails() : (normalDetails ?? _taskDetails());

    // Tier 1: alarmClock mode (highest priority, requires SCHEDULE_EXACT_ALARM on API 34+)
    if (isAlarm) {
      try {
        await _plugin.zonedSchedule(
          id, title, body, tzAt, _alarmDetails(),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        return;
      } catch (_) {
        // SecurityException on API 34+ without SCHEDULE_EXACT_ALARM — fall through
      }
    }

    // Tier 2: exactAllowWhileIdle (requires SCHEDULE_EXACT_ALARM on API 31+)
    try {
      await _plugin.zonedSchedule(
        id, title, body, tzAt, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      return;
    } catch (_) {
      // SecurityException when SCHEDULE_EXACT_ALARM not granted — fall through
    }

    // Tier 3: inexact — always works, may fire up to ~15 min late
    try {
      await _plugin.zonedSchedule(
        id, title, body, tzAt, details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {}
  }

  NotificationDetails _taskDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _chTasksId,
          'Task reminders',
          channelDescription: 'Reminders for scheduled tasks',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  NotificationDetails _eventDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _chEventsId,
          'Event reminders',
          channelDescription: 'Reminders for planned events',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.event,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  NotificationDetails _alarmDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _chAlarmsId,
          'Alarms',
          channelDescription: 'Alarm-mode reminders',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          // fullScreenIntent omitted — Android 14+ restricts USE_FULL_SCREEN_INTENT
          // to communication/call apps. alarmClock schedule mode already provides
          // OS-level alarm priority and status-bar clock icon without it.
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      );
}
