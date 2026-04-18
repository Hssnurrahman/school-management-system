import 'package:flutter/material.dart';
import '../utils/grade_utils.dart';

class Exam {
  final String id;
  final String title;
  final String subject;
  final String className;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double totalMarks;
  final String? description;

  Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalMarks,
    this.description,
  });

  DateTime get endDateTime {
    try {
      final parts = endTime.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final bool isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return DateTime(date.year, date.month, date.day, 23, 59);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'className': className,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'totalMarks': totalMarks,
        'description': description,
      };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'],
        title: json['title'],
        subject: json['subject'],
        className: json['className'],
        date: DateTime.parse(json['date']),
        startTime: json['startTime'],
        endTime: json['endTime'],
        totalMarks: (json['totalMarks'] as num).toDouble(),
        description: json['description'],
      );
}

class ExamResult {
  final String id;
  final String examId;
  final String studentId;
  final String studentName;
  final double? marksObtained;
  final double totalMarks;
  final String? remarks;

  ExamResult({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.studentName,
    this.marksObtained,
    required this.totalMarks,
    this.remarks,
  });

  String get grade {
    if (marksObtained == null) return '-';
    return GradeUtils.fromMarks(marksObtained!, totalMarks);
  }

  Color get gradeColor => GradeUtils.colorForGrade(grade);

  Map<String, dynamic> toJson() => {
        'id': id,
        'examId': examId,
        'studentId': studentId,
        'studentName': studentName,
        'marksObtained': marksObtained,
        'totalMarks': totalMarks,
        'remarks': remarks,
      };

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        id: json['id'],
        examId: json['examId'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        marksObtained: json['marksObtained'] != null
            ? (json['marksObtained'] as num).toDouble()
            : null,
        totalMarks: (json['totalMarks'] as num).toDouble(),
        remarks: json['remarks'],
      );
}
