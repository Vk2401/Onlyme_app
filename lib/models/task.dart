import 'package:flutter/material.dart';

class TaskItem {
  final int id;
  final String title;
  final String time;
  final String cat;
  final String icon;
  final Color color;
  final bool done;
  final int streak;
  final DateTime? scheduledAt;
  final bool isAlarm;

  const TaskItem({
    required this.id,
    required this.title,
    required this.time,
    required this.cat,
    required this.icon,
    required this.color,
    required this.done,
    required this.streak,
    this.scheduledAt,
    this.isAlarm = false,
  });

  TaskItem copyWith({
    String? title,
    String? time,
    String? cat,
    String? icon,
    Color? color,
    bool? done,
    int? streak,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    bool? isAlarm,
  }) =>
      TaskItem(
        id: id,
        title: title ?? this.title,
        time: time ?? this.time,
        cat: cat ?? this.cat,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        done: done ?? this.done,
        streak: streak ?? this.streak,
        scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
        isAlarm: isAlarm ?? this.isAlarm,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'cat': cat,
        'icon': icon,
        'color': color.value,
        'done': done,
        'streak': streak,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'isAlarm': isAlarm,
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'] as int,
        title: j['title'] as String,
        time: j['time'] as String,
        cat: j['cat'] as String,
        icon: j['icon'] as String,
        color: Color(j['color'] as int),
        done: j['done'] as bool,
        streak: j['streak'] as int,
        scheduledAt: (j['scheduledAt'] as String?) != null
            ? DateTime.tryParse(j['scheduledAt'] as String)
            : null,
        isAlarm: j['isAlarm'] as bool? ?? false,
      );
}
