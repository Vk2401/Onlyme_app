import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/debt.dart';
import '../models/event.dart';
import '../models/gym.dart';
import '../models/snapshot.dart';

final List<TaskItem> seedTasks = const [
  TaskItem(id: 1, title: 'Morning skincare', time: '07:30', cat: 'Skincare', icon: 'droplet', color: Color(0xFF60A5FA), done: true, streak: 42),
  TaskItem(id: 2, title: 'Gym — push day', time: '08:00', cat: 'Gym', icon: 'dumbbell', color: Color(0xFFF472B6), done: true, streak: 18),
  TaskItem(id: 3, title: 'Drink 3L water', time: 'all day', cat: 'Health', icon: 'droplet', color: Color(0xFF22D3EE), done: false, streak: 9),
  TaskItem(id: 4, title: 'Read 20 pages', time: '21:00', cat: 'Personal', icon: 'note', color: Color(0xFFA78BFA), done: false, streak: 12),
  TaskItem(id: 5, title: 'Call Amma', time: '19:30', cat: 'Family', icon: 'heart', color: Color(0xFFFB7185), done: false, streak: 0),
  TaskItem(id: 6, title: 'Night routine + retinol', time: '22:30', cat: 'Skincare', icon: 'droplet', color: Color(0xFF60A5FA), done: false, streak: 14),
  TaskItem(id: 7, title: 'Weekly finance review', time: '20:00', cat: 'Finance', icon: 'wallet', color: Color(0xFF34D399), done: false, streak: 3),
];

final List<Debt> seedDebts = const [
  Debt(id: 1, person: 'Arjun',     type: DebtType.theyOwe, total: 12000, paid: 4000, due: 'Jun 12', note: 'Goa trip split'),
  Debt(id: 2, person: 'HDFC Card', type: DebtType.iOwe,    total: 38500, paid: 12000, due: 'May 28', note: 'Laptop EMI'),
  Debt(id: 3, person: 'Priya',     type: DebtType.theyOwe, total: 2500,  paid: 0,    due: 'May 04', note: 'Concert tickets'),
  Debt(id: 4, person: 'Dad',       type: DebtType.iOwe,    total: 25000, paid: 25000, due: 'Apr 01', note: 'Emergency fund', settled: true),
];

final List<PlannedEvent> seedEvents = [
  PlannedEvent(
    id: 1, title: "Sister's wedding", date: 'Nov 14', daysAway: 207, icon: 'gift', color: const Color(0xFFFB7185),
    items: const [
      EventItem(id: 1, label: 'Tailored sherwani', est: 18000, actual: 16200, done: true),
      EventItem(id: 2, label: 'Photographer', est: 45000, actual: 45000, done: true),
      EventItem(id: 3, label: 'Hotel for relatives', est: 32000, actual: 0, done: false),
      EventItem(id: 4, label: 'Gift for Meera', est: 8000, actual: 0, done: false),
      EventItem(id: 5, label: 'Haircut + grooming', est: 2500, actual: 0, done: false),
    ],
  ),
  PlannedEvent(
    id: 2, title: 'Goa with the boys', date: 'Jun 22', daysAway: 62, icon: 'sparkle', color: const Color(0xFFFBBF24),
    items: const [
      EventItem(id: 1, label: 'Flight tickets', est: 8500, actual: 7200, done: true),
      EventItem(id: 2, label: 'Airbnb (4 nights)', est: 14000, actual: 13500, done: true),
      EventItem(id: 3, label: 'Scooter rental', est: 2400, actual: 0, done: false),
      EventItem(id: 4, label: 'Shack budget', est: 6000, actual: 0, done: false),
    ],
  ),
];

final GymPlan seedGymPlan = const GymPlan(
  name: 'Cutting · Week 3',
  days: [
    GymDay(id: 1, short: 'M', label: 'Push', done: true, exercises: []),
    GymDay(id: 2, short: 'T', label: 'Pull', done: true, exercises: []),
    GymDay(id: 3, short: 'W', label: 'Legs', today: true, done: false, exercises: [
      Exercise(name: 'Back squat', sets: 4, reps: '8', weight: '85 kg', done: false),
      Exercise(name: 'Romanian deadlift', sets: 3, reps: '10', weight: '70 kg', done: false),
      Exercise(name: 'Walking lunges', sets: 3, reps: '12/leg', weight: '16 kg', done: false),
      Exercise(name: 'Leg press', sets: 3, reps: '12', weight: '140 kg', done: false),
      Exercise(name: 'Calf raises', sets: 4, reps: '20', weight: '40 kg', done: false),
    ]),
    GymDay(id: 4, short: 'T', label: 'Rest', done: false, exercises: []),
    GymDay(id: 5, short: 'F', label: 'Push', done: false, exercises: []),
    GymDay(id: 6, short: 'S', label: 'Pull', done: false, exercises: []),
    GymDay(id: 7, short: 'S', label: 'Rest', done: false, exercises: []),
  ],
);

final Map<String, List<Snapshot>> seedSnaps = const {
  'hair': [
    Snapshot(id: 1, date: 'Apr 18', note: 'Fresh fade',    hue: 28),
    Snapshot(id: 2, date: 'Mar 24', note: 'Growing out',   hue: 22),
    Snapshot(id: 3, date: 'Feb 28', note: 'Mid-length',    hue: 36),
    Snapshot(id: 4, date: 'Jan 12', note: 'Year start',    hue: 15),
  ],
  'body': [
    Snapshot(id: 1, date: 'Apr 20', note: '78.2 kg', hue: 180),
    Snapshot(id: 2, date: 'Mar 20', note: '80.5 kg', hue: 200),
    Snapshot(id: 3, date: 'Feb 20', note: '82.1 kg', hue: 220),
  ],
  'skin': [
    Snapshot(id: 1, date: 'Apr 19', note: 'Cleared up', hue: 340),
    Snapshot(id: 2, date: 'Mar 30', note: 'Breakout',   hue: 0),
  ],
};
