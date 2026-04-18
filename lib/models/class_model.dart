class ClassModel {
  final String id;
  final String name;
  final String teacherName;
  final int studentCount;
  final String roomNumber;

  ClassModel({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.studentCount,
    required this.roomNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'teacherName': teacherName,
    'studentCount': studentCount,
    'roomNumber': roomNumber,
  };

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
    id: json['id'],
    name: json['name'],
    teacherName: json['teacherName'],
    studentCount: json['studentCount'],
    roomNumber: json['roomNumber'],
  );
}
