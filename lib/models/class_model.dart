class ClassModel {
  final String id;
  final String name;
  final String teacherName;
  final int studentCount;
  final String roomNumber;
  final String? subject;

  ClassModel({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.studentCount,
    required this.roomNumber,
    this.subject,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teacherName': teacherName,
        'studentCount': studentCount,
        'roomNumber': roomNumber,
        'subject': subject,
      };

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
        id: json['id'],
        name: json['name'],
        teacherName: json['teacherName'],
        studentCount: json['studentCount'],
        roomNumber: json['roomNumber'],
        subject: json['subject'],
      );
}
