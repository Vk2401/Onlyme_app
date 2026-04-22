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

  EventItem copyWith({bool? done, int? actual}) => EventItem(
        id: id,
        label: label,
        est: est,
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

  const PlannedEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.daysAway,
    required this.icon,
    required this.color,
    required this.items,
  });

  PlannedEvent copyWith({List<EventItem>? items}) => PlannedEvent(
        id: id,
        title: title,
        date: date,
        daysAway: daysAway,
        icon: icon,
        color: color,
        items: items ?? this.items,
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
      };

  factory PlannedEvent.fromJson(Map<String, dynamic> j) => PlannedEvent(
        id: j['id'] as int,
        title: j['title'] as String,
        date: j['date'] as String,
        daysAway: j['daysAway'] as int,
        icon: j['icon'] as String,
        color: Color(j['color'] as int),
        items: (j['items'] as List).map((e) => EventItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
