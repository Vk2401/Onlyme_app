import 'package:flutter/material.dart';

class EventItem {
  final int id;
  final String label;
  final int est;
  final int actual;
  final bool done;

  const EventItem({
    required this.id,
    required this.label,
    required this.est,
    required this.actual,
    required this.done,
  });

  EventItem copyWith({String? label, int? est, int? actual, bool? done}) =>
      EventItem(
        id: id,
        label: label ?? this.label,
        est: est ?? this.est,
        actual: actual ?? this.actual,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'est': est,
        'actual': actual,
        'done': done,
      };

  factory EventItem.fromJson(Map<String, dynamic> j) => EventItem(
        id: j['id'] as int,
        label: j['label'] as String,
        est: j['est'] as int,
        actual: j['actual'] as int,
        done: j['done'] as bool,
      );
}

class PlannedEvent {
  final int id;
  final String title;
  final String date;
  final int daysAway;
  final String icon;
  final Color color;
  final List<EventItem> items;
  final DateTime? scheduledAt;
  final bool isAlarm;

  const PlannedEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.daysAway,
    required this.icon,
    required this.color,
    required this.items,
    this.scheduledAt,
    this.isAlarm = false,
  });

  PlannedEvent copyWith({
    String? title,
    String? date,
    int? daysAway,
    String? icon,
    Color? color,
    List<EventItem>? items,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    bool? isAlarm,
  }) =>
      PlannedEvent(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        daysAway: daysAway ?? this.daysAway,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        items: items ?? this.items,
        scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
        isAlarm: isAlarm ?? this.isAlarm,
      );

  int get totalEst => items.fold(0, (s, i) => s + i.est);
  int get totalActual => items.fold(0, (s, i) => s + i.actual);
  int get doneCount => items.where((i) => i.done).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'daysAway': daysAway,
        'icon': icon,
        'color': color.value,
        'items': items.map((e) => e.toJson()).toList(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'isAlarm': isAlarm,
      };

  factory PlannedEvent.fromJson(Map<String, dynamic> j) => PlannedEvent(
        id: j['id'] as int,
        title: j['title'] as String,
        date: j['date'] as String,
        daysAway: j['daysAway'] as int,
        icon: j['icon'] as String,
        color: Color(j['color'] as int),
        items: (j['items'] as List)
            .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        scheduledAt: (j['scheduledAt'] as String?) != null
            ? DateTime.tryParse(j['scheduledAt'] as String)
            : null,
        isAlarm: j['isAlarm'] as bool? ?? false,
      );
}
