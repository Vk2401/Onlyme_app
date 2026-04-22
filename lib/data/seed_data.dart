import '../models/task.dart';
import '../models/debt.dart';
import '../models/event.dart';
import '../models/gym.dart';
import '../models/snapshot.dart';
import '../models/weight_entry.dart';

// Empty defaults — users create their own data on first launch.
const List<TaskItem> seedTasks = [];
const List<Debt> seedDebts = [];
const List<PlannedEvent> seedEvents = [];
const List<WeightEntry> seedWeightLogs = [];

const Map<String, List<Snapshot>> seedSnapshots = {
  'hair': [],
  'body': [],
  'skin': [],
};

final GymPlan seedGymPlan = GymPlan(
  name: 'My plan',
  days: [
    GymDay(id: 1, short: 'M', label: 'Push', done: false, exercises: []),
    GymDay(id: 2, short: 'T', label: 'Pull', done: false, exercises: []),
    GymDay(id: 3, short: 'W', label: 'Legs', done: false, exercises: []),
    GymDay(id: 4, short: 'T', label: 'Rest', done: false, exercises: []),
    GymDay(id: 5, short: 'F', label: 'Push', done: false, exercises: []),
    GymDay(id: 6, short: 'S', label: 'Pull', done: false, exercises: []),
    GymDay(id: 7, short: 'S', label: 'Rest', done: false, exercises: []),
  ],
);
