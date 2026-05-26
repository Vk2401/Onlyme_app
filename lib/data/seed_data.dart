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

// No pre-seeded snapshot categories — user creates their own.
const Map<String, List<Snapshot>> seedSnapshots = {};

// Blank 7-day weekly plan. Days are empty; user adds exercises and labels.
final GymPlan seedGymPlan = GymPlan(
  name: 'My plan',
  days: [
    GymDay(id: 1, short: 'Mon', label: 'Monday',    done: false, exercises: []),
    GymDay(id: 2, short: 'Tue', label: 'Tuesday',   done: false, exercises: []),
    GymDay(id: 3, short: 'Wed', label: 'Wednesday', done: false, exercises: []),
    GymDay(id: 4, short: 'Thu', label: 'Thursday',  done: false, exercises: []),
    GymDay(id: 5, short: 'Fri', label: 'Friday',    done: false, exercises: []),
    GymDay(id: 6, short: 'Sat', label: 'Saturday',  done: false, exercises: []),
    GymDay(id: 7, short: 'Sun', label: 'Sunday',    done: false, isRest: true, exercises: []),
  ],
);
