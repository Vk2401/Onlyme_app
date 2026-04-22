class Snapshot {
  final int id;
  final String date;
  final String note;
  final int hue;

  const Snapshot({required this.id, required this.date, required this.note, required this.hue});

  Map<String, dynamic> toJson() => {'id': id, 'date': date, 'note': note, 'hue': hue};

  factory Snapshot.fromJson(Map<String, dynamic> j) => Snapshot(
        id: j['id'] as int,
        date: j['date'] as String,
        note: j['note'] as String,
        hue: j['hue'] as int,
      );
}
