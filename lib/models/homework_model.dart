class Homework {
  final String id;
  final String subject;
  final String title;
  final DateTime dueDate;
  final String description;
  final bool isCompleted;
  final String? className;

  Homework({
    String? id,
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.description,
    this.isCompleted = false,
    this.className,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Homework copyWith({
    String? id,
    String? subject,
    String? title,
    DateTime? dueDate,
    String? description,
    bool? isCompleted,
    String? className,
  }) =>
      Homework(
        id: id ?? this.id,
        subject: subject ?? this.subject,
        title: title ?? this.title,
        dueDate: dueDate ?? this.dueDate,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        className: className ?? this.className,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'description': description,
        'isCompleted': isCompleted ? 1 : 0,
        'className': className,
      };

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
        id: json['id'],
        subject: json['subject'],
        title: json['title'],
        dueDate: DateTime.parse(json['dueDate']),
        description: json['description'],
        isCompleted: json['isCompleted'] == 1 || json['isCompleted'] == true,
        className: json['className'],
      );
}
