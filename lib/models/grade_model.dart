class Grade {
  final String subject;
  final String score;
  final String grade;
  final String remarks;

  Grade({
    required this.subject,
    required this.score,
    required this.grade,
    required this.remarks,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'score': score,
        'grade': grade,
        'remarks': remarks,
      };

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        subject: json['subject'],
        score: json['score'],
        grade: json['grade'],
        remarks: json['remarks'],
      );
}
