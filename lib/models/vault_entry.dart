class VaultEntry {
  final int id;
  final String title;
  final String? username;
  final String password;
  final String? url;
  final String? note;
  final int createdAt;

  const VaultEntry({
    required this.id,
    required this.title,
    this.username,
    required this.password,
    this.url,
    this.note,
    required this.createdAt,
  });

  VaultEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? url,
    String? note,
    bool clearUsername = false,
    bool clearUrl = false,
    bool clearNote = false,
  }) =>
      VaultEntry(
        id: id,
        title: title ?? this.title,
        username: clearUsername ? null : (username ?? this.username),
        password: password ?? this.password,
        url: clearUrl ? null : (url ?? this.url),
        note: clearNote ? null : (note ?? this.note),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'username': username,
        'password': password,
        'url': url,
        'note': note,
        'createdAt': createdAt,
      };

  factory VaultEntry.fromJson(Map<String, dynamic> j) => VaultEntry(
        id: j['id'] as int,
        title: j['title'] as String,
        username: j['username'] as String?,
        password: j['password'] as String,
        url: j['url'] as String?,
        note: j['note'] as String?,
        createdAt: j['createdAt'] as int,
      );
}
