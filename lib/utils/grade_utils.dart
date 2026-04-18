import 'package:flutter/material.dart';

class GradeUtils {
  GradeUtils._();

  static String fromPercentage(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 33) return 'D';
    return 'F';
  }

  static String fromMarks(double obtained, double total) {
    if (total == 0) return '-';
    return fromPercentage((obtained / total) * 100);
  }

  static Color colorForGrade(String grade) {
    switch (grade) {
      case 'A+':
        return const Color(0xFF10B981);
      case 'A':
        return const Color(0xFF34D399);
      case 'B+':
        return const Color(0xFF0EA5E9);
      case 'B':
        return const Color(0xFF0284C7);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFFEF4444);
    }
  }
}
