class MarkEntry {
  final String studentId;
  final String studentName;
  final String subject;
  double? marksObtained;
  final double totalMarks;
  String? grade;
  String? remarks;

  MarkEntry({
    required this.studentId,
    required this.studentName,
    required this.subject,
    this.marksObtained,
    this.totalMarks = 100.0,
    this.grade,
    this.remarks,
  });

  String calculateGrade() {
    if (marksObtained == null) return '-';
    double percentage = (marksObtained! / totalMarks) * 100;
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    return 'F';
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'subject': subject,
        'marksObtained': marksObtained,
        'totalMarks': totalMarks,
        'grade': grade,
        'remarks': remarks,
      };

  factory MarkEntry.fromJson(Map<String, dynamic> json) => MarkEntry(
        studentId: json['studentId'],
        studentName: json['studentName'],
        subject: json['subject'],
        marksObtained: json['marksObtained'] != null
            ? (json['marksObtained'] as num).toDouble()
            : null,
        totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 100.0,
        grade: json['grade'],
        remarks: json['remarks'],
      );
}
