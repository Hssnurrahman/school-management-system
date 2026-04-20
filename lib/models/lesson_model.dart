class Lesson {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final String teacherName;
  final DateTime date;
  final String? attachmentUrl;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.className,
    required this.teacherName,
    required this.date,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subject': subject,
        'className': className,
        'teacherName': teacherName,
        'date': date.toIso8601String(),
        'attachmentUrl': attachmentUrl,
      };

  static DateTime _parseDate(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: (json['id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        subject: (json['subject'] ?? '') as String,
        className: (json['className'] ?? '') as String,
        teacherName: (json['teacherName'] ?? '') as String,
        date: _parseDate(json['date']),
        attachmentUrl: json['attachmentUrl'] as String?,
      );
}
