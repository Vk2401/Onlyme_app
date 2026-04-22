class WeightEntry {
  final int timestamp;
  final double kg;
  final String dateStr;

  const WeightEntry({required this.timestamp, required this.kg, required this.dateStr});

  Map<String, dynamic> toJson() => {'ts': timestamp, 'kg': kg, 'date': dateStr};

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
        timestamp: j['ts'] as int,
        kg: (j['kg'] as num).toDouble(),
        dateStr: j['date'] as String,
      );
}
