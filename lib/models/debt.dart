enum DebtType { iOwe, theyOwe }

class Debt {
  final int id;
  final String person;
  final DebtType type;
  final int total;
  final int paid;
  final String due;
  final String note;
  final bool settled;

  const Debt({
    required this.id,
    required this.person,
    required this.type,
    required this.total,
    required this.paid,
    required this.due,
    required this.note,
    this.settled = false,
  });

  int get remain => total - paid;
  double get pct => total == 0 ? 0 : paid / total;

  Debt copyWith({int? paid, bool? settled}) => Debt(
        id: id,
        person: person,
        type: type,
        total: total,
        paid: paid ?? this.paid,
        due: due,
        note: note,
        settled: settled ?? this.settled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'person': person,
        'type': type == DebtType.iOwe ? 'i_owe' : 'they_owe',
        'total': total,
        'paid': paid,
        'due': due,
        'note': note,
        'settled': settled,
      };

  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
        id: j['id'] as int,
        person: j['person'] as String,
        type: j['type'] == 'i_owe' ? DebtType.iOwe : DebtType.theyOwe,
        total: j['total'] as int,
        paid: j['paid'] as int,
        due: j['due'] as String,
        note: j['note'] as String,
        settled: j['settled'] as bool? ?? false,
      );
}
