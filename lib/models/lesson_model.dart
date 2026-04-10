class Lesson {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final String teacherName;
  final String date;
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
        'date': date,
        'attachmentUrl': attachmentUrl,
      };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        subject: json['subject'],
        className: json['className'],
        teacherName: json['teacherName'],
        date: json['date'],
        attachmentUrl: json['attachmentUrl'],
      );
}
