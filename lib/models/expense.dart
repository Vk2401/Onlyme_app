class Expense {
  final int id;
  final int amount;
  final String category;
  final String note;
  final String dateStr;
  final int timestamp;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.dateStr,
    required this.timestamp,
  });

  Expense copyWith({int? amount, String? category, String? note, String? dateStr}) => Expense(
    id: id,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    note: note ?? this.note,
    dateStr: dateStr ?? this.dateStr,
    timestamp: timestamp,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category,
    'note': note,
    'dateStr': dateStr,
    'timestamp': timestamp,
  };

  static Expense fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as int,
    amount: j['amount'] as int,
    category: j['category'] as String? ?? 'Other',
    note: j['note'] as String? ?? '',
    dateStr: j['dateStr'] as String? ?? '',
    timestamp: j['timestamp'] as int,
  );
}

const kExpenseCategories = [
  'Food', 'Transport', 'Shopping', 'Entertainment',
  'Health', 'Bills', 'Education', 'Other',
];
