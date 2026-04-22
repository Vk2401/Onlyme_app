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

  const TaskItem({
    required this.id,
    required this.title,
    required this.time,
    required this.cat,
    required this.icon,
    required this.color,
    required this.done,
    required this.streak,
  });

  TaskItem copyWith({bool? done, int? streak}) => TaskItem(
        id: id,
        title: title,
        time: time,
        cat: cat,
        icon: icon,
        color: color,
        done: done ?? this.done,
        streak: streak ?? this.streak,
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
      );
}
