class Exercise {
  final String name;
  final int sets;
  final String reps;
  final String weight;
  final bool done;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.done,
  });

  Exercise copyWith({String? name, int? sets, String? reps, String? weight, bool? done}) =>
      Exercise(
        name: name ?? this.name,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'done': done,
      };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        name: j['name'] as String,
        sets: j['sets'] as int,
        reps: j['reps'] as String,
        weight: j['weight'] as String,
        done: j['done'] as bool,
      );
}

class GymDay {
  final int id;
  final String short;
  final String label;
  final bool today;
  final bool done;
  final bool isRest;
  final List<Exercise> exercises;

  const GymDay({
    required this.id,
    required this.short,
    required this.label,
    this.today = false,
    required this.done,
    this.isRest = false,
    required this.exercises,
  });

  GymDay copyWith({String? label, List<Exercise>? exercises, bool? done, bool? isRest}) => GymDay(
        id: id,
        short: short,
        label: label ?? this.label,
        today: today,
        done: done ?? this.done,
        isRest: isRest ?? this.isRest,
        exercises: exercises ?? this.exercises,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'short': short,
        'label': label,
        'today': today,
        'done': done,
        'isRest': isRest,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory GymDay.fromJson(Map<String, dynamic> j) => GymDay(
        id: j['id'] as int,
        short: j['short'] as String,
        label: j['label'] as String,
        today: j['today'] as bool? ?? false,
        done: j['done'] as bool,
        // backward compat: old data with label='rest' auto-migrates to isRest=true
        isRest: j['isRest'] as bool? ?? (j['label'] as String).toLowerCase() == 'rest',
        exercises: (j['exercises'] as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GymPlan {
  final String name;
  final List<GymDay> days;

  const GymPlan({required this.name, required this.days});

  GymPlan copyWith({String? name, List<GymDay>? days}) =>
      GymPlan(name: name ?? this.name, days: days ?? this.days);

  Map<String, dynamic> toJson() => {
        'name': name,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory GymPlan.fromJson(Map<String, dynamic> j) => GymPlan(
        name: j['name'] as String,
        days: (j['days'] as List)
            .map((d) => GymDay.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}
