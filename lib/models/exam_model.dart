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
    final parsed = _parseTime(endTime);
    if (parsed == null) {
      throw FormatException('Invalid time format: $endTime');
    }
    return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
  }

  DateTime get startDateTime {
    final parsed = _parseTime(startTime);
    if (parsed == null) {
      throw FormatException('Invalid time format: $startTime');
    }
    return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
  }

  ({int hour, int minute})? _parseTime(String time) {
    try {
      final trimmed = time.trim();
      final parts = trimmed.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      
      if (parts.length > 1) {
        final ampm = parts[1].toUpperCase();
        if (ampm == 'PM' && hour != 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
      }
      
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }
      return (hour: hour, minute: minute);
    } catch (_) {
      return null;
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

  static DateTime _parseDate(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: (json['id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        subject: (json['subject'] ?? '') as String,
        className: (json['className'] ?? '') as String,
        date: _parseDate(json['date']),
        startTime: (json['startTime'] ?? '') as String,
        endTime: (json['endTime'] ?? '') as String,
        totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String?,
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
        id: (json['id'] ?? '') as String,
        examId: (json['examId'] ?? '') as String,
        studentId: (json['studentId'] ?? '') as String,
        studentName: (json['studentName'] ?? '') as String,
        marksObtained: (json['marksObtained'] as num?)?.toDouble(),
        totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0.0,
        remarks: json['remarks'] as String?,
      );
}
