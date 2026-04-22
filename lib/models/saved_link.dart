class SavedLink {
  final int id;
  final String title;
  final String url;
  final int createdAt;

  const SavedLink({
    required this.id,
    required this.title,
    required this.url,
    required this.createdAt,
  });

  SavedLink copyWith({String? title, String? url}) => SavedLink(
        id: id,
        title: title ?? this.title,
        url: url ?? this.url,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'createdAt': createdAt,
      };

  factory SavedLink.fromJson(Map<String, dynamic> j) => SavedLink(
        id: j['id'] as int,
        title: j['title'] as String,
        url: j['url'] as String,
        createdAt: j['createdAt'] as int,
      );
}
