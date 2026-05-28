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

// Blank gym plan — no days pre-set. User builds their own plan.
final GymPlan seedGymPlan = GymPlan(name: 'My plan', days: []);
