class Note {
  final int id;
  final String title;
  final String body;
  final int createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  Note copyWith({String? title, String? body}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt,
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as int,
        title: j['title'] as String,
        body: j['body'] as String,
        createdAt: j['createdAt'] as int,
      );
}
