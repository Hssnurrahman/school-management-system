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

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        date: DateTime.parse(json['date']),
        author: json['author'],
      );
}
