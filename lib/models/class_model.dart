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
    id: (json['id'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    teacherName: (json['teacherName'] ?? '') as String,
    studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
    roomNumber: (json['roomNumber'] ?? '') as String,
  );

  ClassModel copyWith({
    String? id,
    String? name,
    String? teacherName,
    int? studentCount,
    String? roomNumber,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherName: teacherName ?? this.teacherName,
      studentCount: studentCount ?? this.studentCount,
      roomNumber: roomNumber ?? this.roomNumber,
    );
  }
}
