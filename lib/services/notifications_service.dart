import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications so the rest of the app never sees the
/// plugin directly. Responsibilities:
///   * one-time init (timezone DB + channel setup)
///   * schedule / cancel a single task notification
///   * schedule / cancel an event's two notifications (day-before + at-time)
///   * request OS permission lazily (on the first schedule that actually
///     needs it)
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _permissionAsked = false;

  // IDs are derived from domain id modulo 31-bit range so they fit Android
  // notification-id constraints. Tasks use the id as-is; events reserve two
  // slots (even = at-time, odd = day-before).
  static int _taskId(int domainId) => domainId & 0x7FFFFFFE;
  static int _eventAtId(int domainId) => domainId & 0x7FFFFFFE;
  static int _eventDayBeforeId(int domainId) => (domainId & 0x7FFFFFFE) | 1;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local));
    } catch (_) {
      // Fall back to UTC if we can't detect the device TZ — fires will be
      // offset from wall-clock but at least won't crash.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      // We handle the prompt lazily via requestPermission(), not here, so
      // the OS doesn't pop a dialog on app launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
    );
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
      // Exact-alarm permission is required on Android 12+ (API 31+). Best
      // effort — if the user denies, scheduled notifications fall back to
      // inexact delivery which can be delayed by up to ~15min.
      await android?.requestExactAlarmsPermission();
      return notifGranted;
    }
    return true;
  }

  Future<void> scheduleTask({
    required int id,
    required String title,
    String? body,
    required DateTime at,
  }) async {
    await _ensureReadyAndPermitted(at);
    if (at.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      _taskId(id),
      title,
      body ?? 'Task reminder',
      tz.TZDateTime.from(at, tz.local),
      _taskDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
  }) async {
    await _ensureReadyAndPermitted(at);
    final now = DateTime.now();

    // At-the-moment notification.
    if (at.isAfter(now)) {
      await _plugin.zonedSchedule(
        _eventAtId(id),
        title,
        body ?? 'Event starting',
        tz.TZDateTime.from(at, tz.local),
        _eventDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'event:$id',
      );
    } else {
      await _plugin.cancel(_eventAtId(id));
    }

    // Day-before reminder (skip if already within 24h).
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

  // ── internals ──────────────────────────────────────────────────────────

  Future<void> _ensureReadyAndPermitted(DateTime target) async {
    if (!_ready) await init();
    if (!_permissionAsked) await requestPermission();
  }

  NotificationDetails _taskDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'onlyme_tasks',
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
          'onlyme_events',
          'Event reminders',
          channelDescription: 'Reminders for planned events (day-before + at start)',
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
}
