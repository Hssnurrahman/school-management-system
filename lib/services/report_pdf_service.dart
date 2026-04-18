import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/attendance_model.dart';
import '../models/exam_model.dart';
import '../models/grade_model.dart';
import '../models/homework_model.dart';

class ReportPdfService {
  // ─── Color Palette ────────────────────────────────────────────────────────
  // Primary teal accent color for highlights
  static const _primary   = PdfColor.fromInt(0xFF0D9488);

  static const _primaryDark = PdfColor.fromInt(0xFF0F766E);
  
  // Semantic colors for grades/performance
  static const _success   = PdfColor.fromInt(0xFF10B981);
  static const _warning   = PdfColor.fromInt(0xFFF59E0B);
  static const _danger    = PdfColor.fromInt(0xFFEF4444);
  static const _info      = PdfColor.fromInt(0xFF3B82F6);
  
  // Neutral grayscale
  static const _white     = PdfColors.white;
  static const _gray50    = PdfColor.fromInt(0xFFF9FAFB);
  static const _gray100   = PdfColor.fromInt(0xFFF3F4F6);
  static const _gray200   = PdfColor.fromInt(0xFFE5E7EB);
  static const _gray300   = PdfColor.fromInt(0xFFD1D5DB);
  static const _gray400   = PdfColor.fromInt(0xFF9CA3AF);
  static const _gray500   = PdfColor.fromInt(0xFF6B7280);
  static const _gray600   = PdfColor.fromInt(0xFF4B5563);
  static const _gray700   = PdfColor.fromInt(0xFF374151);
  static const _gray800   = PdfColor.fromInt(0xFF1F2937);

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _monthName(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  static String _fullMonthName(int m) =>
      ['January','February','March','April','May','June','July','August','September','October','November','December'][m - 1];

  static String _computeGrade(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 33) return 'D';
    return 'F';
  }

  static PdfColor _gradeColor(String grade) {
    switch (grade) {
      case 'A+': return _success;
      case 'A':  return PdfColor.fromInt(0xFF34D399);
      case 'B+': return _info;
      case 'B':  return PdfColor.fromInt(0xFF60A5FA);
      case 'C':  return _warning;
      case 'D':  return PdfColor.fromInt(0xFFF97316);
      case 'F':  return _danger;
      default:   return _gray500;
    }
  }

  static String _gradeDescription(String grade) {
    switch (grade) {
      case 'A+': return 'Outstanding';
      case 'A':  return 'Excellent';
      case 'B+': return 'Very Good';
      case 'B':  return 'Good';
      case 'C':  return 'Satisfactory';
      case 'D':  return 'Needs Improvement';
      case 'F':  return 'Unsatisfactory';
      default:   return 'Not Graded';
    }
  }

  // ─── Discipline remarks ───────────────────────────────────────────────────
  static Map<String, String> _disciplineRemarks(double? avgPct) {
    if (avgPct == null) {
      return {
        'Class Discipline':       'No assessment data available.',
        'Student Behavior':       'No assessment data available.',
        'Cleanliness Standard':   'No assessment data available.',
        'Co-curricular Activity': 'No assessment data available.',
      };
    }
    if (avgPct >= 90) {
      return {
        'Class Discipline':       'Exemplary conduct. Consistently follows all class rules and sets a positive example for peers.',
        'Student Behavior':       'Outstanding behavior throughout the term. Respectful, cooperative, and highly self-disciplined.',
        'Cleanliness Standard':   'Maintains excellent personal and desk hygiene. Takes initiative to keep the classroom tidy.',
        'Co-curricular Activity': 'Actively participates and excels in extracurricular activities, demonstrating leadership and team spirit.',
      };
    }
    if (avgPct >= 80) {
      return {
        'Class Discipline':       'Very good discipline. Adheres to class rules consistently with minimal reminders.',
        'Student Behavior':       'Well-behaved and respectful. Demonstrates a positive attitude towards teachers and classmates.',
        'Cleanliness Standard':   'Keeps personal belongings and workspace clean. Contributes to a tidy classroom environment.',
        'Co-curricular Activity': 'Regularly participates in co-curricular activities and shows good enthusiasm and effort.',
      };
    }
    if (avgPct >= 70) {
      return {
        'Class Discipline':       'Good discipline overall. Generally follows class rules with occasional reminders needed.',
        'Student Behavior':       'Generally well-behaved. Shows respect and cooperates with peers and teachers most of the time.',
        'Cleanliness Standard':   'Maintains acceptable cleanliness. Occasionally needs reminders to keep the workspace organized.',
        'Co-curricular Activity': 'Participates in some co-curricular activities. Shows willingness to engage with encouragement.',
      };
    }
    if (avgPct >= 60) {
      return {
        'Class Discipline':       'Satisfactory discipline. Follows most class rules but needs periodic guidance to stay on track.',
        'Student Behavior':       'Behavior is satisfactory. Responds well to teacher guidance and shows improvement potential.',
        'Cleanliness Standard':   'Cleanliness is satisfactory but requires regular reminders to maintain standards.',
        'Co-curricular Activity': 'Participates in co-curricular activities when encouraged. Greater self-initiative is recommended.',
      };
    }
    if (avgPct >= 50) {
      return {
        'Class Discipline':       'Average discipline. Needs more consistent adherence to class rules and greater self-control.',
        'Student Behavior':       'Behavior requires improvement. Occasional disruptions noted; needs closer monitoring.',
        'Cleanliness Standard':   'Cleanliness needs improvement. Frequent reminders required to meet classroom standards.',
        'Co-curricular Activity': 'Limited participation in co-curricular activities. Student is encouraged to explore more interests.',
      };
    }
    if (avgPct >= 33) {
      return {
        'Class Discipline':       'Below average discipline. Struggles to follow class rules; consistent teacher intervention needed.',
        'Student Behavior':       'Behavior is below expectations. Regular counselling and parental involvement are recommended.',
        'Cleanliness Standard':   'Does not consistently meet cleanliness standards. Needs significant improvement and daily reminders.',
        'Co-curricular Activity': 'Rarely participates in co-curricular activities. Strong encouragement and support are advised.',
      };
    }
    return {
      'Class Discipline':       'Poor discipline observed. Immediate improvement is required; regular meetings with parents advised.',
      'Student Behavior':       'Behavior is unsatisfactory and disruptive. Urgent intervention and counselling are strongly recommended.',
      'Cleanliness Standard':   'Cleanliness standards are not being met. Requires immediate attention and consistent guidance.',
      'Co-curricular Activity': 'No participation in co-curricular activities. Parent and teacher collaboration needed to motivate student.',
    };
  }

  static pw.Widget _disciplineSection(double? avgPct) {
    final remarks = _disciplineRemarks(avgPct);
    final grade   = avgPct != null ? _computeGrade(avgPct) : null;
    final keys    = remarks.keys.toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (grade != null) ...[
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: pw.BoxDecoration(
                color: _gradeColor(grade),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                'Overall Grade: $grade',
                style: pw.TextStyle(color: _white, fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
        ],
        ...List.generate(keys.length, (i) {
          final title  = keys[i];
          final detail = remarks[title]!;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: _white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: _gray200, width: 0.8),
                boxShadow: [
                  pw.BoxShadow(
                    color: _gray100,
                    blurRadius: 2,
                    offset: const PdfPoint(0, 1),
                  ),
                ],
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left colored strip
                  pw.Container(
                    width: 4,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      color: _primary,
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(8),
                        bottomLeft: pw.Radius.circular(8),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            title,
                            style: pw.TextStyle(
                              color: _gray800,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            detail,
                            style: const pw.TextStyle(color: _gray600, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Public entry point ───────────────────────────────────────────────────
  static Future<void> generateAndShare({
    required String studentName,
    required String? className,
    required List<Attendance> attendance,
    required List<ExamResult> examResults,
    required Map<String, Exam> examsById,
    required List<Grade> grades,
    required List<Homework> homework,
    required String generatedBy,
    String schoolName = 'Schoolify',
    String teacherRemarks = '',
    bool singlePage = false,
    double? classAverage, // Optional class average for comparison
  }) async {
    final doc = pw.Document(
      title: 'Student Report — $studentName',
      author: generatedBy,
    );

    // ── Derived stats ──────────────────────────────────────────────────────
    final presentCount = attendance.where((a) => a.isPresent && !a.isLate).length;
    final lateCount    = attendance.where((a) => a.isLate).length;
    final absentCount  = attendance.where((a) => !a.isPresent).length;
    final totalDays    = attendance.length;
    final attPct       = totalDays > 0 ? (presentCount + lateCount) / totalDays * 100 : 0.0;

    final gradedResults = examResults.where((r) => r.marksObtained != null).toList();
    final percentages   = gradedResults.map((r) => (r.marksObtained! / r.totalMarks) * 100).toList();
    final avgPct        = percentages.isEmpty ? null : percentages.reduce((a, b) => a + b) / percentages.length;
    
    // Subject-wise analysis
    final subjectTotals = <String, List<double>>{};
    final subjectExamCounts = <String, int>{};
    for (final r in gradedResults) {
      final subject = examsById[r.examId]?.subject ?? 'Unknown';
      subjectTotals.putIfAbsent(subject, () => []).add((r.marksObtained! / r.totalMarks) * 100);
      subjectExamCounts[subject] = (subjectExamCounts[subject] ?? 0) + 1;
    }
    final subjectAvg = subjectTotals.map(
      (s, vals) => MapEntry(s, vals.reduce((a, b) => a + b) / vals.length),
    );

    // Calculate GPA
    final gpa = _calculateGPA(percentages);

    final passed = avgPct != null && avgPct >= 33;

    if (singlePage) {
      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: _gray50),
            ),
          ),
          build: (context) => _buildSinglePage(
            studentName: studentName,
            className: className,
            schoolName: schoolName,
            generatedBy: generatedBy,
            generatedOn: _fmtDate(DateTime.now()),
            passed: passed,
            avgPct: avgPct,
            gpa: gpa,
            attPct: attPct,
            presentCount: presentCount,
            lateCount: lateCount,
            absentCount: absentCount,
            totalDays: totalDays,
            examCount: examResults.length,
            gradedCount: gradedResults.length,
            subjectAvg: subjectAvg,
            recentExams: gradedResults.take(5).toList(),
            examsById: examsById,
            teacherRemarks: teacherRemarks,
            classAverage: classAverage,
          ),
        ),
      );
    } else {
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: _gray50),
            ),
          ),
          header: (context) => _buildHeader(
            studentName: studentName,
            className: className,
            generatedBy: generatedBy,
            generatedOn: _fmtDate(DateTime.now()),
            schoolName: schoolName,
            passed: avgPct == null ? null : passed,
            avgPct: avgPct,
            attPct: attPct,
            gpa: gpa,
          ),
          footer: (context) => _buildFooter(context, schoolName),
          build: (context) => [
            pw.SizedBox(height: 12),

            // ── Performance Overview Cards ───────────────────────────────
            _buildOverviewCards(
              avgPct: avgPct,
              gpa: gpa,
              attPct: attPct,
              totalDays: totalDays,
              presentCount: presentCount,
              examCount: gradedResults.length,
              classAverage: classAverage,
            ),
            pw.SizedBox(height: 18),

            // ── Subject performance ──────────────────────────────────────
            if (subjectAvg.isNotEmpty) ...[
              _sectionTitle('Subject Performance Analysis'),
              pw.SizedBox(height: 10),
              _subjectAnalysisSection(subjectAvg),
              pw.SizedBox(height: 18),
            ],

            // ── Exam results ─────────────────────────────────────────────
            _sectionTitle('Exam Results'),
            pw.SizedBox(height: 10),
            examResults.isEmpty
                ? _emptyNote('No exam results recorded.')
                : _examTable(examResults, examsById),
            pw.SizedBox(height: 18),

            // ── Attendance patterns ──────────────────────────────────────
            _sectionTitle('Attendance Patterns'),
            pw.SizedBox(height: 10),
            attendance.isEmpty
                ? _emptyNote('No attendance records found.')
                : _attendancePatternsSection(attendance),
            pw.SizedBox(height: 18),

            // ── Attendance calendar ──────────────────────────────────────
            _sectionTitle('Monthly Attendance Calendar'),
            pw.SizedBox(height: 10),
            attendance.isEmpty
                ? _emptyNote('No attendance records found.')
                : _attendanceCalendar(attendance),
            pw.SizedBox(height: 18),

            // ── Grade records ────────────────────────────────────────────
            if (grades.isNotEmpty) ...[
              _sectionTitle('Grade Records'),
              pw.SizedBox(height: 10),
              _gradeTable(grades),
              pw.SizedBox(height: 18),
            ],

            // ── Homework ─────────────────────────────────────────────────
            if (homework.isNotEmpty) ...[
              _sectionTitle('Homework Assignments'),
              pw.SizedBox(height: 10),
              _homeworkTable(homework),
              pw.SizedBox(height: 18),
            ],

            // ── Discipline & Activities ──────────────────────────────────
            _sectionTitle('Discipline & Activities'),
            pw.SizedBox(height: 10),
            _disciplineSection(avgPct),
            pw.SizedBox(height: 18),

            // ── Teacher remarks ──────────────────────────────────────────
            _sectionTitle('Teacher Remarks'),
            pw.SizedBox(height: 10),
            _remarksBox(teacherRemarks, generatedBy),
            pw.SizedBox(height: 18),

            // ── Signature ────────────────────────────────────────────────
            _signatureLine(),
            pw.SizedBox(height: 18),

            // ── Grade scale ───────────────────────────────────────────────
            _sectionTitle('Grade Scale Reference'),
            pw.SizedBox(height: 10),
            _gradeLegend(),
          ],
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'report_${studentName.replaceAll(' ', '_')}_${_fmtDate(DateTime.now())}.pdf',
    );
  }

  static double _calculateGPA(List<double> percentages) {
    if (percentages.isEmpty) return 0.0;
    double total = 0;
    for (final pct in percentages) {
      final p = pct / 100;
      if (p >= 0.9) {
        total += 4.0;
      } else if (p >= 0.8) {
        total += 3.7;
      } else if (p >= 0.7) {
        total += 3.3;
      } else if (p >= 0.6) {
        total += 3.0;
      } else if (p >= 0.5) {
        total += 2.0;
      } else if (p >= 0.33) {
        total += 1.0;
      } else {
        total += 0.0;
      }
    }
    return total / percentages.length;
  }

  // ─── Overview Cards Widget ────────────────────────────────────────────────
  static pw.Widget _buildOverviewCards({
    required double? avgPct,
    required double gpa,
    required double attPct,
    required int totalDays,
    required int presentCount,
    required int examCount,
    double? classAverage,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: _gray200, width: 0.8),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Performance Overview',
            style: pw.TextStyle(
              color: _gray800,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _overviewCard(
                'Average Score',
                avgPct != null ? '${avgPct.toStringAsFixed(1)}%' : '—',
                avgPct != null ? _computeGrade(avgPct) : null,
                _info,
              ),
              pw.SizedBox(width: 10),
              _overviewCard(
                'GPA',
                gpa > 0 ? gpa.toStringAsFixed(2) : '—',
                null,
                _primary,
              ),
              pw.SizedBox(width: 10),
              _overviewCard(
                'Attendance',
                totalDays > 0 ? '${attPct.toStringAsFixed(1)}%' : '—',
                null,
                _success,
              ),
              pw.SizedBox(width: 10),
              _overviewCard(
                'Exams Taken',
                examCount > 0 ? '$examCount' : '—',
                null,
                _warning,
              ),
            ],
          ),
          if (classAverage != null && avgPct != null) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _gray100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Class Average: ',
                    style: pw.TextStyle(color: _gray600, fontSize: 11),
                  ),
                  pw.Text(
                    '${classAverage.toStringAsFixed(1)}%',
                    style: pw.TextStyle(
                      color: _gray800,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    avgPct > classAverage 
                      ? '(+${(avgPct - classAverage).toStringAsFixed(1)}% above average)'
                      : avgPct < classAverage
                        ? '(${(avgPct - classAverage).toStringAsFixed(1)}% below average)'
                        : '(At class average)',
                    style: pw.TextStyle(
                      color: avgPct > classAverage 
                        ? _success 
                        : avgPct < classAverage 
                          ? _warning 
                          : _gray500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _overviewCard(String label, String value, String? badge, PdfColor accentColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _gray50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: _gray200, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(color: _gray500, fontSize: 9),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    color: _gray800,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (badge != null) ...[
                  pw.SizedBox(width: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: _gradeColor(badge),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      badge,
                      style: pw.TextStyle(
                        color: _white,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Subject Analysis Section ─────────────────────────────────────────────
  static pw.Widget _subjectAnalysisSection(Map<String, double> subjectAvg) {
    final sorted = subjectAvg.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final bestSubject = sorted.isNotEmpty ? sorted.first : null;
    final weakestSubject = sorted.isNotEmpty ? sorted.last : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Summary row
        if (sorted.length > 1)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0x1A14B8A6),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: const PdfColor.fromInt(0x4D0D9488), width: 0.8),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Strongest Subject',
                        style: const pw.TextStyle(color: _gray500, fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        bestSubject?.key ?? '—',
                        style: pw.TextStyle(
                          color: _success,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        bestSubject != null ? '${bestSubject.value.toStringAsFixed(1)}%' : '',
                        style: const pw.TextStyle(color: _gray600, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.Container(width: 1, height: 40, color: _gray300),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Needs Improvement',
                          style: const pw.TextStyle(color: _gray500, fontSize: 9),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          weakestSubject?.key ?? '—',
                          style: pw.TextStyle(
                            color: _warning,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          weakestSubject != null ? '${weakestSubject.value.toStringAsFixed(1)}%' : '',
                          style: const pw.TextStyle(color: _gray600, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Subject bars
        _subjectBars(subjectAvg),
      ],
    );
  }

  // ─── Attendance Patterns Section ──────────────────────────────────────────
  static pw.Widget _attendancePatternsSection(List<Attendance> records) {
    final byMonth = <String, List<Attendance>>{};
    for (final a in records) {
      final key = '${a.date.year}-${a.date.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(a);
    }
    
    final monthlyStats = byMonth.entries.map((e) {
      final recs = e.value;
      final present = recs.where((a) => a.isPresent && !a.isLate).length;
      final late = recs.where((a) => a.isLate).length;
      final absent = recs.where((a) => !a.isPresent).length;
      final total = recs.length;
      final pct = total > 0 ? ((present + late) / total * 100) : 0.0;
      
      final parts = e.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      return _MonthStat(
        year: year,
        month: month,
        present: present,
        late: late,
        absent: absent,
        total: total,
        percentage: pct,
      );
    }).toList();
    
    monthlyStats.sort((a, b) => 
      '${a.year}-${a.month.toString().padLeft(2, '0')}'.compareTo('${b.year}-${b.month.toString().padLeft(2, '0')}'));

    // Find best and worst months
    final bestMonth = monthlyStats.isNotEmpty 
      ? monthlyStats.reduce((a, b) => a.percentage > b.percentage ? a : b)
      : null;
    final worstMonth = monthlyStats.isNotEmpty && monthlyStats.length > 1
      ? monthlyStats.reduce((a, b) => a.percentage < b.percentage ? a : b)
      : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Monthly trend bars
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _white,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: _gray200, width: 0.8),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Monthly Attendance Trend',
                style: pw.TextStyle(
                  color: _gray700,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              if (monthlyStats.isEmpty)
                pw.Text('No data available', style: const pw.TextStyle(color: _gray500, fontSize: 10))
              else
                ...monthlyStats.map((stat) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${_fullMonthName(stat.month)} ${stat.year}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _gray700,
                              ),
                            ),
                            pw.Text(
                              '${stat.percentage.toStringAsFixed(0)}% (${stat.present + stat.late}/${stat.total} days)',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: stat.percentage >= 90 
                                  ? _success 
                                  : stat.percentage >= 75 
                                    ? _warning 
                                    : _danger,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.LayoutBuilder(builder: (ctx, constraints) {
                          final maxW = constraints?.maxWidth ?? 200.0;
                          final barW = (maxW * stat.percentage / 100).clamp(0.0, maxW);
                          return pw.Stack(children: [
                            pw.Container(
                              height: 8,
                              decoration: const pw.BoxDecoration(
                                color: _gray200,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                              ),
                            ),
                            pw.Container(
                              width: barW,
                              height: 8,
                              decoration: pw.BoxDecoration(
                                color: stat.percentage >= 90 
                                  ? _success 
                                  : stat.percentage >= 75 
                                    ? _warning 
                                    : _danger,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                              ),
                            ),
                          ]);
                        }),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        
        pw.SizedBox(height: 12),
        
        // Best/Worst month summary
        if (bestMonth != null)
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0x1A10B981),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: const PdfColor.fromInt(0x4D10B981), width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Best Month',
                        style: const pw.TextStyle(color: _gray500, fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _fullMonthName(bestMonth.month),
                        style: pw.TextStyle(
                          color: _success,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${bestMonth.percentage.toStringAsFixed(0)}% attendance',
                        style: const pw.TextStyle(color: _gray600, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
              if (worstMonth != null && worstMonth != bestMonth) ...[
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0x1AF59E0B),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: const PdfColor.fromInt(0x4DF59E0B), width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Needs Attention',
                          style: const pw.TextStyle(color: _gray500, fontSize: 9),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          _fullMonthName(worstMonth.month),
                          style: pw.TextStyle(
                            color: _warning,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '${worstMonth.percentage.toStringAsFixed(0)}% attendance',
                          style: const pw.TextStyle(color: _gray600, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  // ─── Single-page compact layout ──────────────────────────────────────────
  static pw.Widget _buildSinglePage({
    required String studentName,
    required String? className,
    required String schoolName,
    required String generatedBy,
    required String generatedOn,
    required bool passed,
    required double? avgPct,
    required double gpa,
    required double attPct,
    required int presentCount,
    required int lateCount,
    required int absentCount,
    required int totalDays,
    required int examCount,
    required int gradedCount,
    required Map<String, double> subjectAvg,
    required List<ExamResult> recentExams,
    required Map<String, Exam> examsById,
    required String teacherRemarks,
    double? classAverage,
  }) {
    final grade = avgPct != null ? _computeGrade(avgPct) : null;
    final sorted = subjectAvg.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Header with gradient styling ────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            gradient: const pw.LinearGradient(
              colors: [_primary, _primaryDark],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            boxShadow: [
              pw.BoxShadow(
                color: const PdfColor.fromInt(0x4D0D9488),
                blurRadius: 8,
                offset: const PdfPoint(0, 3),
              ),
            ],
          ),
          padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Avatar
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(right: 14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0x33FFFFFF),
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: const PdfColor.fromInt(0x66FFFFFF), width: 2),
                ),
                child: pw.Center(
                  child: pw.Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                    style: pw.TextStyle(color: _white, fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(schoolName.toUpperCase(),
                      style: pw.TextStyle(color: const PdfColor.fromInt(0xE6FFFFFF), fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1.4)),
                    pw.SizedBox(height: 2),
                    pw.Text(studentName,
                      style: pw.TextStyle(color: _white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      if (className != null && className.isNotEmpty) ...[
                        _headerPill('Class: $className'),
                        pw.SizedBox(width: 5),
                      ],
                      _headerPill('Date: $generatedOn'),
                    ]),
                  ],
                ),
              ),
              // Pass/Fail + Grade
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (avgPct != null)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: _white,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
                      ),
                      child: pw.Text(
                        passed ? 'PASS' : 'FAIL',
                        style: pw.TextStyle(
                          color: passed ? _success : _danger, 
                          fontSize: 11, 
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  if (grade != null) ...[
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: 42, height: 42,
                      decoration: pw.BoxDecoration(
                        color: _gradeColor(grade),
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: _white, width: 2),
                      ),
                      child: pw.Center(
                        child: pw.Text(grade,
                          style: pw.TextStyle(color: _white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // ── Quick Stats Cards ───────────────────────────────────────────────
        pw.Row(
          children: [
            _quickStatCard('GPA', gpa > 0 ? gpa.toStringAsFixed(2) : '—', _primary),
            pw.SizedBox(width: 8),
            _quickStatCard('Avg %', avgPct != null ? '${avgPct.toStringAsFixed(1)}%' : '—', _info),
            pw.SizedBox(width: 8),
            _quickStatCard('Attendance', totalDays > 0 ? '${attPct.toStringAsFixed(0)}%' : '—', _success),
            pw.SizedBox(width: 8),
            _quickStatCard('Exams', '$gradedCount', _warning),
          ],
        ),
        pw.SizedBox(height: 12),

        // ── Body: subject bars + recent exams ─────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: _white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: _gray200, width: 0.8),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _miniSectionLabel('SUBJECT PERFORMANCE'),
                    pw.SizedBox(height: 10),
                    if (sorted.isEmpty)
                      pw.Text('No data', style: const pw.TextStyle(color: _gray500, fontSize: 11))
                    else
                      ...sorted.map((entry) {
                        final name  = entry.key;
                        final pct   = entry.value.clamp(0.0, 100.0);
                        final g     = _computeGrade(pct);
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gray800)),
                                  pw.Row(children: [
                                    pw.Text('${pct.toStringAsFixed(0)}%',
                                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gray700)),
                                    pw.SizedBox(width: 4),
                                    pw.Container(
                                      width: 20, height: 14,
                                      decoration: pw.BoxDecoration(
                                        color: _gradeColor(g),
                                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                                      ),
                                      alignment: pw.Alignment.center,
                                      child: pw.Text(g,
                                        style: pw.TextStyle(color: _white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                    ),
                                  ]),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              pw.LayoutBuilder(builder: (ctx, constraints) {
                                final maxW = constraints?.maxWidth ?? 150.0;
                                final barW = (maxW * pct / 100).clamp(0.0, maxW);
                                return pw.Stack(children: [
                                  pw.Container(height: 6,
                                    decoration: const pw.BoxDecoration(color: _gray200,
                                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)))),
                                  pw.Container(width: barW, height: 6,
                                    decoration: pw.BoxDecoration(
                                      color: _gradeColor(g),
                                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)))),
                                ]);
                              }),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              flex: 5,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: _white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: _gray200, width: 0.8),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _miniSectionLabel('RECENT EXAM RESULTS'),
                    pw.SizedBox(height: 10),
                    if (recentExams.isEmpty)
                      pw.Text('No graded exams', style: const pw.TextStyle(color: _gray500, fontSize: 11))
                    else
                      ...recentExams.map((r) {
                        final exam  = examsById[r.examId];
                        final pct   = (r.marksObtained! / r.totalMarks * 100);
                        final g     = r.grade;
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(children: [
                            pw.Expanded(child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(exam?.title ?? 'Exam',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gray800),
                                  maxLines: 1),
                                pw.Text(exam?.subject ?? '',
                                  style: const pw.TextStyle(fontSize: 9, color: _gray500)),
                              ],
                            )),
                            pw.SizedBox(width: 6),
                            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                              pw.Text('${pct.toStringAsFixed(0)}%',
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gray700)),
                              pw.Container(
                                width: 22, height: 14,
                                decoration: pw.BoxDecoration(
                                  color: _gradeColor(g),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
                                alignment: pw.Alignment.center,
                                child: pw.Text(g,
                                  style: pw.TextStyle(color: _white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              ),
                            ]),
                          ]),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),

        // ── Attendance strip ───────────────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _white,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(color: _gray200, width: 0.8),
          ),
          padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: pw.Row(children: [
            _miniSectionLabel('ATTENDANCE'),
            pw.SizedBox(width: 14),
            _attDot('P', presentCount, _success),
            pw.SizedBox(width: 10),
            _attDot('L', lateCount, _warning),
            pw.SizedBox(width: 10),
            _attDot('A', absentCount, _danger),
            pw.SizedBox(width: 10),
            _attDot('T', totalDays, _gray600),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: pw.BoxDecoration(
                color: attPct >= 90 ? _success : attPct >= 75 ? _warning : _danger,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                '${attPct.toStringAsFixed(1)}%',
                style: pw.TextStyle(color: _white, fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ]),
        ),
        pw.SizedBox(height: 10),

        // ── Discipline & Activities ────────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _white,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(color: _gray200, width: 0.8),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _miniSectionLabel('DISCIPLINE & ACTIVITIES'),
              pw.SizedBox(height: 8),
              _compactDisciplineSection(avgPct),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // ── Remarks + signature ────────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 6,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: _white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: _gray200, width: 0.8),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _miniSectionLabel('TEACHER REMARKS'),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      teacherRemarks.isNotEmpty ? teacherRemarks : 'No remarks provided.',
                      style: pw.TextStyle(
                        fontSize: 10, 
                        color: teacherRemarks.isNotEmpty ? _gray700 : _gray500,
                        lineSpacing: 3,
                        fontStyle: teacherRemarks.isEmpty ? pw.FontStyle.italic : pw.FontStyle.normal),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('— $generatedBy',
                      style: pw.TextStyle(fontSize: 10, color: _gray600, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              flex: 4,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: _white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: _gray200, width: 0.8),
                ),
                padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _miniSectionLabel('SIGNATURES'),
                    pw.SizedBox(height: 8),
                    _compactSigSlot('Class Teacher'),
                    pw.SizedBox(height: 8),
                    _compactSigSlot('Principal'),
                    pw.SizedBox(height: 8),
                    _compactSigSlot('Date'),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Footer ────────────────────────────────────────────────────────
        pw.Spacer(),
        pw.Container(height: 1, color: _gray300),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(schoolName,
              style: pw.TextStyle(color: _gray700, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('Confidential — For internal use only',
              style: const pw.TextStyle(color: _gray500, fontSize: 9)),
            pw.Text('Page 1 / 1',
              style: pw.TextStyle(color: _gray500, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _quickStatCard(String label, String value, PdfColor accentColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: _white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: _gray200, width: 0.8),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                color: accentColor,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: const pw.TextStyle(color: _gray500, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _compactDisciplineSection(double? avgPct) {
    final grade = avgPct != null ? _computeGrade(avgPct) : null;
    final remarks = _disciplineRemarks(avgPct);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (grade != null)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _gradeColor(grade),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'Overall Grade: $grade - ${_gradeDescription(grade)}',
              style: pw.TextStyle(color: _white, fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        pw.Wrap(
          spacing: 8,
          runSpacing: 6,
          children: remarks.entries.map((e) {
            return pw.Container(
              width: 160,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: _gray50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: _gray200, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    e.key,
                    style: pw.TextStyle(
                      color: _gray700,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    e.value,
                    style: const pw.TextStyle(color: _gray500, fontSize: 7),
                    maxLines: 2,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _miniSectionLabel(String text) {
    return pw.Row(children: [
      pw.Container(
        width: 3, height: 12,
        margin: const pw.EdgeInsets.only(right: 6),
        decoration: const pw.BoxDecoration(
          color: _primary,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
      ),
      pw.Text(text,
        style: pw.TextStyle(color: _gray800, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
    ]);
  }

  static pw.Widget _attDot(String label, int count, PdfColor color) {
    return pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
      pw.Container(
        width: 24, height: 24,
        decoration: pw.BoxDecoration(
          color: PdfColor(color.red, color.green, color.blue, 0.15),
          shape: pw.BoxShape.circle,
        ),
        child: pw.Center(
          child: pw.Text('$count',
            style: pw.TextStyle(color: color, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
      ),
      pw.SizedBox(width: 4),
      pw.Text(label, style: pw.TextStyle(color: _gray500, fontSize: 10, fontWeight: pw.FontWeight.bold)),
    ]);
  }

  static pw.Widget _compactSigSlot(String label) {
    return pw.Row(children: [
      pw.Expanded(child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 20,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _gray300, width: 1)))),
          pw.SizedBox(height: 2),
          pw.Text(label,
            style: pw.TextStyle(color: _gray500, fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      )),
    ]);
  }

  // ─── Header (multi-page) ─────────────────────────────────────────────────
  static pw.Widget _buildHeader({
    required String studentName,
    required String? className,
    required String generatedBy,
    required String generatedOn,
    required String schoolName,
    required bool? passed,
    required double? avgPct,
    required double attPct,
    required double gpa,
  }) {
    final grade = avgPct != null ? _computeGrade(avgPct) : null;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [_primary, _primaryDark],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Avatar
            pw.Container(
              width: 50,
              height: 50,
              margin: const pw.EdgeInsets.only(right: 14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0x33FFFFFF),
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: const PdfColor.fromInt(0x66FFFFFF), width: 2),
              ),
              child: pw.Center(
                child: pw.Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                  style: pw.TextStyle(color: _white, fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            // Name + meta
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(schoolName.toUpperCase(),
                    style: pw.TextStyle(color: const PdfColor.fromInt(0xE6FFFFFF), fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.6)),
                  pw.SizedBox(height: 2),
                  pw.Text(studentName,
                    style: pw.TextStyle(color: _white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    if (className != null && className.isNotEmpty) ...[
                      _headerPill('Class: $className'),
                      pw.SizedBox(width: 6),
                    ],
                    _headerPill('Generated: $generatedOn'),
                  ]),
                ],
              ),
            ),
            // Pass/Fail + grade circle
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (passed != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: _white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                    ),
                    child: pw.Text(
                      passed ? 'PASS' : 'FAIL',
                      style: pw.TextStyle(
                        color: passed ? _success : _danger, 
                        fontSize: 11, 
                        fontWeight: pw.FontWeight.bold, 
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                if (grade != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: 46, height: 46,
                    decoration: pw.BoxDecoration(
                      color: _gradeColor(grade),
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: _white, width: 2),
                    ),
                    child: pw.Center(
                      child: pw.Text(grade,
                        style: pw.TextStyle(color: _white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _headerPill(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0x26FFFFFF),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Text(text, style: pw.TextStyle(color: const PdfColor.fromInt(0xF2FFFFFF), fontSize: 10)),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Context context, String schoolName) {
    return pw.Column(
      children: [
        pw.Container(
          height: 1,
          margin: const pw.EdgeInsets.only(bottom: 6),
          color: _gray300,
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(schoolName,
              style: pw.TextStyle(color: _gray700, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('Confidential — For internal use only',
              style: const pw.TextStyle(color: _gray500, fontSize: 10)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: _gray100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: _gray300, width: 0.8),
              ),
              child: pw.Text(
                'Page ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(color: _gray700, fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Section title ────────────────────────────────────────────────────────
  static pw.Widget _sectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 20,
          decoration: const pw.BoxDecoration(
            color: _primary,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            color: _gray800,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  static pw.Widget _emptyNote(String msg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _gray100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _gray300, width: 0.8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4, 
            height: 32,
            decoration: const pw.BoxDecoration(
              color: _gray400,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(msg, style: const pw.TextStyle(color: _gray600, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Subject performance bars ─────────────────────────────────────────────
  static pw.Widget _subjectBars(Map<String, double> subjectAvg) {
    final sorted = subjectAvg.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _gray200, width: 0.8),
      ),
      padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: pw.Column(
        children: sorted.asMap().entries.map((entry) {
          final name  = entry.value.key;
          final pct   = entry.value.value.clamp(0.0, 100.0);
          final grade = _computeGrade(pct);

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(name,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _gray800)),
                    pw.Row(children: [
                      pw.Text('${pct.toStringAsFixed(1)}%',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _gray700)),
                      pw.SizedBox(width: 8),
                      pw.Container(
                        width: 28, height: 18,
                        decoration: pw.BoxDecoration(
                          color: _gradeColor(grade),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(grade,
                          style: pw.TextStyle(color: _white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ]),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.LayoutBuilder(builder: (ctx, constraints) {
                  final maxW = constraints?.maxWidth ?? 300.0;
                  final barW = (maxW * pct / 100).clamp(0.0, maxW);
                  return pw.Stack(children: [
                    pw.Container(height: 10,
                      decoration: const pw.BoxDecoration(
                        color: _gray200,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                    ),
                    pw.Container(width: barW, height: 10,
                      decoration: pw.BoxDecoration(
                        color: _gradeColor(grade),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                    ),
                  ]);
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Exam results table ───────────────────────────────────────────────────
  static pw.Widget _examTable(List<ExamResult> results, Map<String, Exam> examsById) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _gray300, width: 0.8),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(
          inside: pw.BorderSide(color: _gray200, width: 0.5),
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.2),
          1: pw.FlexColumnWidth(1.3),
          2: pw.FlexColumnWidth(1.3),
          3: pw.FlexColumnWidth(0.9),
          4: pw.FlexColumnWidth(0.9),
          5: pw.FlexColumnWidth(0.9),
          6: pw.FlexColumnWidth(0.8),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _primary),
            children: [
              _th('Exam Title'), _th('Subject'), _th('Date'),
              _th('Marks'), _th('Total'), _th('%'), _th('Grade'),
            ],
          ),
          ...results.asMap().entries.map((e) {
            final i     = e.key;
            final r     = e.value;
            final exam  = examsById[r.examId];
            final pct   = r.marksObtained != null ? (r.marksObtained! / r.totalMarks * 100) : null;
            final grade = r.marksObtained != null ? r.grade : '-';
            final bg    = i.isEven ? _white : _gray50;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _td(exam?.title ?? 'Exam', bold: true),
                _tdSub(exam?.subject ?? '-'),
                _tdSub(exam != null ? '${_monthName(exam.date.month)} ${exam.date.day}' : '-'),
                _tdCenter(r.marksObtained?.toStringAsFixed(0) ?? '—'),
                _tdCenter(r.totalMarks.toStringAsFixed(0)),
                _tdCenter(pct != null ? '${pct.toStringAsFixed(1)}%' : '—'),
                _tdGrade(grade),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Attendance calendar ──────────────────────────────────────────────────
  static pw.Widget _attendanceCalendar(List<Attendance> records) {
    final byMonth = <String, List<Attendance>>{};
    for (final a in records) {
      final key = '${a.date.year}-${a.date.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(a);
    }
    final sortedKeys = byMonth.keys.toList()..sort();
    const weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    final monthWidgets = sortedKeys.map((key) {
      final parts       = key.split('-');
      final year        = int.parse(parts[0]);
      final month       = int.parse(parts[1]);
      final recs        = byMonth[key]!;
      final recMap      = {for (final a in recs) a.date.day: a};
      final firstDay    = DateTime(year, month, 1).weekday;
      final daysInMonth = DateTime(year, month + 1, 0).day;

      final pCount = recs.where((a) => a.isPresent && !a.isLate).length;
      final lCount = recs.where((a) => a.isLate).length;
      final aCount = recs.where((a) => !a.isPresent).length;

      final cells = <pw.Widget>[];
      for (final d in weekDays) {
        cells.add(pw.Center(
          child: pw.Text(d,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gray700)),
        ));
      }
      for (int i = 1; i < firstDay; i++) { cells.add(pw.SizedBox()); }
      for (int day = 1; day <= daysInMonth; day++) {
        final att = recMap[day];
        if (att == null) {
          cells.add(pw.Center(
            child: pw.Text('$day', style: const pw.TextStyle(fontSize: 10, color: _gray300)),
          ));
        } else {
          final isLate    = att.isLate;
          final isPresent = att.isPresent && !isLate;
          if (isPresent) {
            cells.add(pw.Center(
              child: pw.Container(
                width: 18, height: 18,
                decoration: const pw.BoxDecoration(color: _success, shape: pw.BoxShape.circle),
                child: pw.Center(
                  child: pw.Text('$day',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _white)),
                ),
              ),
            ));
          } else if (isLate) {
            cells.add(pw.Center(
              child: pw.Container(
                width: 18, height: 18,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: _warning, width: 2),
                ),
                child: pw.Center(
                  child: pw.Text('$day',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _warning)),
                ),
              ),
            ));
          } else {
            cells.add(pw.Center(
              child: pw.Container(
                width: 18, height: 18,
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0x26EF4444),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Center(
                  child: pw.Text('$day',
                    style: pw.TextStyle(fontSize: 9, color: _danger, fontWeight: pw.FontWeight.bold)),
                ),
              ),
            ));
          }
        }
      }

      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          decoration: pw.BoxDecoration(
            color: _white,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(color: _gray200, width: 0.8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Month header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: _primary,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(10),
                    topRight: pw.Radius.circular(10),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${_fullMonthName(month)} $year',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _white)),
                    pw.Text('P:$pCount  L:$lCount  A:$aCount',
                      style: const pw.TextStyle(fontSize: 10, color: _white)),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.GridView(crossAxisCount: 7, childAspectRatio: 1, children: cells),
              ),
            ],
          ),
        ),
      );
    }).toList();

    final rows = <pw.Widget>[];
    for (int i = 0; i < monthWidgets.length; i += 3) {
      final chunk = monthWidgets.sublist(i, (i + 3).clamp(0, monthWidgets.length));
      while (chunk.length < 3) { chunk.add(pw.Expanded(child: pw.SizedBox())); }
      rows.add(pw.Row(children: chunk));
      if (i + 3 < monthWidgets.length) rows.add(pw.SizedBox(height: 10));
    }

    // Legend
    rows.add(pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _gray200, width: 0.8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          _calLegendItem('Present', color: _success),
          pw.SizedBox(width: 24),
          _calLegendItem('Late', color: _warning, outlined: true),
          pw.SizedBox(width: 24),
          _calLegendItem('Absent', color: _danger),
        ],
      ),
    ));

    return pw.Column(children: rows);
  }

  static pw.Widget _calLegendItem(String label, {required PdfColor color, bool outlined = false}) {
    return pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
      pw.Container(
        width: 14, height: 14,
        decoration: pw.BoxDecoration(
          color: outlined ? null : color,
          shape: pw.BoxShape.circle,
          border: outlined ? pw.Border.all(color: color, width: 2) : null,
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _gray700, fontWeight: pw.FontWeight.bold)),
    ]);
  }

  // ─── Grade records table ──────────────────────────────────────────────────
  static pw.Widget _gradeTable(List<Grade> grades) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _gray300, width: 0.8),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(
          inside: pw.BorderSide(color: _gray200, width: 0.5),
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(1),
          2: pw.FlexColumnWidth(1),
          3: pw.FlexColumnWidth(3),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _primary),
            children: [_th('Subject'), _th('Score'), _th('Grade'), _th('Remarks')],
          ),
          ...grades.asMap().entries.map((e) {
            final bg = e.key.isEven ? _white : _gray50;
            final g  = e.value;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _td(g.subject, bold: true),
                _tdCenter(g.score),
                _tdGrade(g.grade),
                _tdSub(g.remarks.isEmpty ? '—' : g.remarks),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Homework table ───────────────────────────────────────────────────────
  static pw.Widget _homeworkTable(List<Homework> homework) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _gray300, width: 0.8),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(
          inside: pw.BorderSide(color: _gray200, width: 0.5),
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.5),
          1: pw.FlexColumnWidth(1.5),
          2: pw.FlexColumnWidth(1.5),
          3: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _primary),
            children: [_th('Title'), _th('Subject'), _th('Due Date'), _th('Status')],
          ),
          ...homework.asMap().entries.map((e) {
            final hw = e.value;
            final bg = e.key.isEven ? _white : _gray50;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _td(hw.title, bold: true),
                _tdSub(hw.subject),
                _tdSub('${_monthName(hw.dueDate.month)} ${hw.dueDate.day}, ${hw.dueDate.year}'),
                _tdStatus(hw.isCompleted ? 'Done' : 'Pending', hw.isCompleted),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Teacher remarks ──────────────────────────────────────────────────────
  static pw.Widget _remarksBox(String remarks, String teacherName) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _gray200, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const pw.BoxDecoration(
              color: _gray100,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                topRight: pw.Radius.circular(10),
              ),
            ),
            child: pw.Row(children: [
              pw.Container(
                width: 3, 
                height: 14, 
                margin: const pw.EdgeInsets.only(right: 8),
                decoration: const pw.BoxDecoration(
                  color: _primary,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
              pw.Text('Remarks by $teacherName',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _gray800)),
            ]),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: pw.Text(
              remarks.isNotEmpty ? remarks : 'No remarks provided.',
              style: pw.TextStyle(
                fontSize: 11,
                color: remarks.isNotEmpty ? _gray800 : _gray600,
                lineSpacing: 4,
                fontStyle: remarks.isEmpty ? pw.FontStyle.italic : pw.FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Signature line ───────────────────────────────────────────────────────
  static pw.Widget _signatureLine() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _gray200, width: 0.8),
      ),
      padding: const pw.EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: pw.Row(children: [
        _signatureSlot('Class Teacher'),
        pw.SizedBox(width: 16),
        _signatureSlot('Principal'),
        pw.SizedBox(width: 16),
        _signatureSlot('Parent / Guardian'),
        pw.SizedBox(width: 16),
        _signatureSlot('Date'),
      ]),
    );
  }

  static pw.Widget _signatureSlot(String label) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 32,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _gray400, width: 1.2)))),
          pw.SizedBox(height: 4),
          pw.Text(label,
            style: pw.TextStyle(color: _gray600, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── Grade scale legend ───────────────────────────────────────────────────
  static pw.Widget _gradeLegend() {
    final items = [
      ('A+', '>= 90%', 'Outstanding'),
      ('A', '>= 80%', 'Excellent'),
      ('B+', '>= 70%', 'Very Good'),
      ('B', '>= 60%', 'Good'),
      ('C', '>= 50%', 'Satisfactory'),
      ('D', '>= 33%', 'Needs Improvement'),
      ('F', '< 33%', 'Unsatisfactory'),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _white,
        border: pw.Border.all(color: _gray200, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Wrap(
        spacing: 12,
        runSpacing: 10,
        children: items.map((item) {
          final (grade, range, desc) = item;
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _gray50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: _gray300, width: 0.8),
            ),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  width: 28, height: 22,
                  decoration: pw.BoxDecoration(
                    color: _gradeColor(grade),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(grade,
                    style: pw.TextStyle(color: _white, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(width: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(range,
                      style: pw.TextStyle(fontSize: 11, color: _gray700, fontWeight: pw.FontWeight.bold)),
                    pw.Text(desc,
                      style: const pw.TextStyle(fontSize: 9, color: _gray500)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Table cell helpers ───────────────────────────────────────────────────
  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(text,
        style: pw.TextStyle(color: _white, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 0.3)),
    );
  }

  static pw.Widget _td(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
        style: pw.TextStyle(fontSize: 11, color: _gray800,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  static pw.Widget _tdSub(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10, color: _gray600)),
    );
  }

  static pw.Widget _tdCenter(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 11, color: _gray800, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tdGrade(String grade) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: grade == '-' ? _gray100 : _gradeColor(grade),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: pw.Text(grade,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: grade == '-' ? _gray700 : _white,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          )),
      ),
    );
  }

  static pw.Widget _tdStatus(String text, bool done) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: done ? _success : _gray200,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: done ? _white : _gray700,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          )),
      ),
    );
  }
}

// Helper class for monthly attendance stats
class _MonthStat {
  final int year;
  final int month;
  final int present;
  final int late;
  final int absent;
  final int total;
  final double percentage;

  _MonthStat({
    required this.year,
    required this.month,
    required this.present,
    required this.late,
    required this.absent,
    required this.total,
    required this.percentage,
  });
}
