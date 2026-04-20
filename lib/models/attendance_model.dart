class Attendance {
  final String studentId;
  final String studentName;
  final DateTime date;
  final bool isPresent;
  final bool isLate;

  Attendance({
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.isPresent,
    this.isLate = false,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'date': date.toIso8601String(),
        'isPresent': isPresent ? 1 : 0,
        'isLate': isLate ? 1 : 0,
      };

  static DateTime _parseDate(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        studentId: (json['studentId'] ?? '') as String,
        studentName: (json['studentName'] ?? '') as String,
        date: _parseDate(json['date']),
        isPresent: json['isPresent'] == 1 || json['isPresent'] == true,
        isLate: json['isLate'] == 1 || json['isLate'] == true,
      );
}
