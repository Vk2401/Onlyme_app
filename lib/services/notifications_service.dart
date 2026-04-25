import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
  bool _permissionAsked = false;

  // IDs: tasks use id as-is; events reserve two slots (even=at-time, odd=day-before).
  static int _taskId(int domainId) => domainId & 0x7FFFFFFE;
  static int _eventAtId(int domainId) => domainId & 0x7FFFFFFE;
  static int _eventDayBeforeId(int domainId) => (domainId & 0x7FFFFFFE) | 1;

  // Channel IDs — must match what is declared in AndroidManifest (channels are
  // created at runtime via createNotificationChannel).
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

    // Create notification channels on Android. Channels are immutable after
    // creation, so we create all three up-front. The alarm channel uses the
    // ALARM audio stream so it plays at alarm volume (not silenced by DND
    // profiles that exclude alarms).
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

      // Alarm channel: plays through alarm volume, bypasses most DND modes.
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _chAlarmsId,
        'Alarms',
        description: 'Alarm-mode reminders — plays at alarm volume',
        importance: Importance.max,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
      ));
    }

    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (_permissionAsked) return true;
    _permissionAsked = true;

    if (Platform.isIOS || Platform.isMacOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final notifGranted = await android?.requestNotificationsPermission() ?? true;
      // Exact-alarm permission is required on Android 12+ (API 31+).
      // Without it, delivery can be delayed ~15 min. Without USE_EXACT_ALARM /
      // SCHEDULE_EXACT_ALARM being granted, alarm-clock mode falls back to
      // inexact but still fires eventually.
      await android?.requestExactAlarmsPermission();
      return notifGranted;
    }
    return true;
  }

  // ── Public schedule API ───────────────────────────────────────────────────

  Future<void> scheduleTask({
    required int id,
    required String title,
    String? body,
    required DateTime at,
    bool isAlarm = false,
  }) async {
    await _ensureReadyAndPermitted(at);
    if (at.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      _taskId(id),
      title,
      body ?? 'Task reminder',
      tz.TZDateTime.from(at, tz.local),
      isAlarm ? _alarmDetails() : _taskDetails(),
      // alarmClock uses setAlarmClock() — highest-priority Android alarm,
      // survives Doze + OEM battery killers; shows clock icon in status bar.
      androidScheduleMode: isAlarm
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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
    await _ensureReadyAndPermitted(at);
    final now = DateTime.now();
    final details = isAlarm ? _alarmDetails() : _eventDetails();
    final schedMode = isAlarm
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.exactAllowWhileIdle;

    if (at.isAfter(now)) {
      await _plugin.zonedSchedule(
        _eventAtId(id),
        title,
        body ?? 'Event starting',
        tz.TZDateTime.from(at, tz.local),
        details,
        androidScheduleMode: schedMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'event:$id',
      );
    } else {
      await _plugin.cancel(_eventAtId(id));
    }

    // Day-before reminder (skip if already within 24h; use normal mode regardless).
    final dayBefore = at.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        _eventDayBeforeId(id),
        'Tomorrow: $title',
        body ?? 'Event in 1 day',
        tz.TZDateTime.from(dayBefore, tz.local),
        _eventDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'event:$id',
      );
    } else {
      await _plugin.cancel(_eventDayBeforeId(id));
    }
  }

  Future<void> cancelEvent(int id) async {
    await _plugin.cancel(_eventAtId(id));
    await _plugin.cancel(_eventDayBeforeId(id));
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _ensureReadyAndPermitted(DateTime target) async {
    if (!_ready) await init();
    if (!_permissionAsked) await requestPermission();
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
          // fullScreenIntent shows a heads-up banner even on lock screen.
          fullScreenIntent: true,
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
