class Attendance {
  final String studentId;
  final String studentName;
  final DateTime date;
  final bool isPresent;

  Attendance({
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.isPresent,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'date': date.toIso8601String(),
        'isPresent': isPresent ? 1 : 0,
      };

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        studentId: json['studentId'],
        studentName: json['studentName'],
        date: DateTime.parse(json['date']),
        isPresent: json['isPresent'] == 1 || json['isPresent'] == true,
      );
}
