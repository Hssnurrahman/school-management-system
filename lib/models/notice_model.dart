class Notice {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String author;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
        'author': author,
      };

  static DateTime _parseDate(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: (json['id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        content: (json['content'] ?? '') as String,
        date: _parseDate(json['date']),
        author: (json['author'] ?? '') as String,
      );
}
