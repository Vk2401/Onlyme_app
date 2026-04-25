class Snapshot {
  final int id;
  final String date;
  final String note;
  final int hue; // gradient fallback when no image
  final String? imagePath; // path to saved image in app internal storage

  const Snapshot({
    required this.id,
    required this.date,
    required this.note,
    required this.hue,
    this.imagePath,
  });

  Snapshot copyWith({String? note, int? hue, String? imagePath, bool clearImagePath = false}) =>
      Snapshot(
        id: id,
        date: date,
        note: note ?? this.note,
        hue: hue ?? this.hue,
        imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'note': note,
        'hue': hue,
        if (imagePath != null) 'imagePath': imagePath,
      };

  factory Snapshot.fromJson(Map<String, dynamic> j) => Snapshot(
        id: j['id'] as int,
        date: j['date'] as String,
        note: j['note'] as String,
        hue: j['hue'] as int,
        imagePath: j['imagePath'] as String?,
      );
}
