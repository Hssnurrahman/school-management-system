import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/attendance_model.dart';
import '../models/exam_model.dart';
import '../models/grade_model.dart';
import '../models/homework_model.dart';

/// Black & White Student Report PDF Service
class ReportPdfService {
  // ─── Black & White Color Palette ────────────────────────────────────────────
  static const _black       = PdfColors.black;
  static const _white       = PdfColors.white;
  static const _gray200     = PdfColor.fromInt(0xFFEEEEEE);
  static const _gray300     = PdfColor.fromInt(0xFFE0E0E0);
  static const _gray400     = PdfColor.fromInt(0xFFBDBDBD);
  static const _gray600     = PdfColor.fromInt(0xFF757575);

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _computeGrade(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 33) return 'D';
    return 'F';
  }

  // ─── Grade-based teacher remarks ───────────────────────────────────────────
  static String _generateTeacherRemarks(double? avgPct) {
    if (avgPct == null) {
      return 'No assessment data available for evaluation.';
    }
    if (avgPct >= 90) {
      return 'Outstanding performance! The student demonstrates exceptional academic excellence, strong leadership qualities, and consistent dedication to studies. Keep up the excellent work!';
    }
    if (avgPct >= 80) {
      return 'Excellent performance! The student shows strong academic abilities, good discipline, and active participation. Minor refinements will lead to even greater achievements.';
    }
    if (avgPct >= 70) {
      return 'Good performance overall. The student is making steady progress with consistent effort. Focus on strengthening weaker areas to achieve higher grades.';
    }
    if (avgPct >= 60) {
      return 'Satisfactory performance. The student meets basic expectations but has room for improvement. Regular practice and increased focus will help achieve better results.';
    }
    if (avgPct >= 50) {
      return 'Average performance. The student needs to put in more effort and seek additional support where needed. Improvement is possible with dedicated study habits.';
    }
    if (avgPct >= 33) {
      return 'Below average performance. The student is struggling and requires immediate attention. Parent-teacher collaboration recommended to create an improvement plan.';
    }
    return 'Unsatisfactory performance. The student is facing significant academic challenges. Urgent intervention, counseling, and structured support plan needed.';
  }

  // ─── Discipline remarks based on performance ───────────────────────────────
  static Map<String, String> _disciplineRemarks(double? avgPct) {
    if (avgPct == null) {
      return {
        'Class Discipline': 'No assessment data available.',
        'Student Behavior': 'No assessment data available.',
        'Cleanliness Standard': 'No assessment data available.',
        'Co-curricular Activity': 'No assessment data available.',
      };
    }
    if (avgPct >= 90) {
      return {
        'Class Discipline': 'Exemplary conduct. Consistently follows all class rules.',
        'Student Behavior': 'Outstanding behavior. Respectful and self-disciplined.',
        'Cleanliness Standard': 'Maintains excellent personal and desk hygiene.',
        'Co-curricular Activity': 'Actively participates with leadership qualities.',
      };
    }
    if (avgPct >= 80) {
      return {
        'Class Discipline': 'Very good discipline. Adheres to rules consistently.',
        'Student Behavior': 'Well-behaved and respectful. Positive attitude.',
        'Cleanliness Standard': 'Keeps workspace clean and organized.',
        'Co-curricular Activity': 'Regularly participates with good enthusiasm.',
      };
    }
    if (avgPct >= 70) {
      return {
        'Class Discipline': 'Good discipline. Follows rules with occasional reminders.',
        'Student Behavior': 'Generally well-behaved and cooperative.',
        'Cleanliness Standard': 'Maintains acceptable cleanliness.',
        'Co-curricular Activity': 'Participates when encouraged.',
      };
    }
    if (avgPct >= 60) {
      return {
        'Class Discipline': 'Satisfactory discipline. Needs periodic guidance.',
        'Student Behavior': 'Satisfactory behavior. Shows improvement potential.',
        'Cleanliness Standard': 'Cleanliness is satisfactory.',
        'Co-curricular Activity': 'Limited participation. Needs encouragement.',
      };
    }
    if (avgPct >= 50) {
      return {
        'Class Discipline': 'Average discipline. Needs more consistent adherence.',
        'Student Behavior': 'Behavior requires improvement.',
        'Cleanliness Standard': 'Cleanliness needs improvement.',
        'Co-curricular Activity': 'Rarely participates. Encouragement needed.',
      };
    }
    return {
      'Class Discipline': 'Below average. Consistent intervention needed.',
      'Student Behavior': 'Below expectations. Counselling recommended.',
      'Cleanliness Standard': 'Does not meet standards. Needs attention.',
      'Co-curricular Activity': 'No participation. Parent collaboration needed.',
    };
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
    bool singlePage = true,
    double? classAverage,
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
    for (final r in gradedResults) {
      final subject = examsById[r.examId]?.subject ?? 'Unknown';
      subjectTotals.putIfAbsent(subject, () => []).add((r.marksObtained! / r.totalMarks) * 100);
    }
    final subjectAvg = subjectTotals.map(
      (s, vals) => MapEntry(s, vals.reduce((a, b) => a + b) / vals.length),
    );

    final passed = avgPct != null && avgPct >= 33;
    final disciplineData = _disciplineRemarks(avgPct);
    
    // Auto-generate teacher remarks if not provided
    final finalTeacherRemarks = teacherRemarks.isNotEmpty 
        ? teacherRemarks 
        : _generateTeacherRemarks(avgPct);

    if (singlePage) {
      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(16, 16, 16, 16),
          ),
          build: (context) => _buildSinglePage(
            studentName: studentName,
            className: className,
            schoolName: schoolName,
            generatedBy: generatedBy,
            generatedOn: _fmtDate(DateTime.now()),
            passed: passed,
            avgPct: avgPct,
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
            teacherRemarks: finalTeacherRemarks,
            classAverage: classAverage,
            disciplineData: disciplineData,
          ),
        ),
      );
    } else {
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(20, 0, 20, 24),
          ),
          header: (context) => _buildHeader(
            studentName: studentName,
            className: className,
            generatedBy: generatedBy,
            generatedOn: _fmtDate(DateTime.now()),
            schoolName: schoolName,
            avgPct: avgPct,
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            pw.SizedBox(height: 12),
            _buildOverviewCards(
              avgPct: avgPct,
              attPct: attPct,
              totalDays: totalDays,
              presentCount: presentCount,
              examCount: gradedResults.length,
              classAverage: classAverage,
            ),
            pw.SizedBox(height: 12),
            if (subjectAvg.isNotEmpty) ...[
              _sectionTitle('Subject Performance Analysis'),
              pw.SizedBox(height: 6),
              _subjectAnalysisSection(subjectAvg),
              pw.SizedBox(height: 12),
            ],
            _sectionTitle('Exam Results'),
            pw.SizedBox(height: 6),
            examResults.isEmpty
                ? _emptyNote('No exam results recorded.')
                : _examTable(examResults, examsById),
            pw.SizedBox(height: 12),
            _sectionTitle('Attendance Summary'),
            pw.SizedBox(height: 6),
            _attendanceSummary(presentCount, lateCount, absentCount, totalDays, attPct),
            pw.SizedBox(height: 12),
            if (grades.isNotEmpty) ...[
              _sectionTitle('Grade Records'),
              pw.SizedBox(height: 6),
              _gradeTable(grades),
              pw.SizedBox(height: 12),
            ],
            _sectionTitle('Discipline & Activities'),
            pw.SizedBox(height: 6),
            _disciplineSection(disciplineData, avgPct),
            pw.SizedBox(height: 12),
            _sectionTitle('Teacher Remarks'),
            pw.SizedBox(height: 6),
            _remarksBox(finalTeacherRemarks, generatedBy),
            pw.SizedBox(height: 12),
            _signatureLine(),
          ],
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'report_${studentName.replaceAll(' ', '_')}_${_fmtDate(DateTime.now())}.pdf',
    );
  }

  // ─── Single Page Layout ───────────────────────────────────────────────────
  static pw.Widget _buildSinglePage({
    required String studentName,
    required String? className,
    required String schoolName,
    required String generatedBy,
    required String generatedOn,
    required bool passed,
    required double? avgPct,
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
    required Map<String, String> disciplineData,
    double? classAverage,
  }) {
    final grade = avgPct != null ? _computeGrade(avgPct) : null;
    final sorted = subjectAvg.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── Header (Black Background, White Text) ────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _black,
            border: pw.Border.all(color: _black, width: 2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(right: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _white, width: 2),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _white),
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(schoolName.toUpperCase(),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: _white)),
                    pw.SizedBox(height: 2),
                    pw.Text(studentName,
                      style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: _white)),
                    pw.SizedBox(height: 2),
                    pw.Row(children: [
                      if (className != null && className.isNotEmpty) ...[
                        pw.Text('Class: $className', style: pw.TextStyle(fontSize: 10, color: _white)),
                        pw.SizedBox(width: 16),
                      ],
                      pw.Text('Date: $generatedOn', style: pw.TextStyle(fontSize: 10, color: _white)),
                    ]),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Show Grade in circle
                  if (grade != null)
                    pw.Container(
                      width: 42,
                      height: 42,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _white, width: 2),
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(grade,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _white)),
                      ),
                    ),
                  if (avgPct != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text('${avgPct.toStringAsFixed(1)}%',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _white)),
                  ],
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // ── Quick Stats (3 cards) ────────────────────────────────────────────
        pw.Row(
          children: [
            _statCard('Average', avgPct != null ? '${avgPct.toStringAsFixed(1)}%' : '—'),
            pw.SizedBox(width: 8),
            _statCard('Attendance', totalDays > 0 ? '${attPct.toStringAsFixed(0)}%' : '—'),
            pw.SizedBox(width: 8),
            _statCard('Exams', '$gradedCount'),
          ],
        ),
        pw.SizedBox(height: 10),

        // ── Two Column Layout (Subject + Discipline) ─────────────────────────
        pw.SizedBox(
          height: 180,
          child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Left: Subject Performance
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _black, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    _boxTitle('SUBJECT PERFORMANCE'),
                    pw.SizedBox(height: 8),
                    if (sorted.isEmpty)
                      pw.Text('No data available', style: pw.TextStyle(fontSize: 10))
                    else
                      ...sorted.take(4).map((entry) {
                        final name = entry.key;
                        final pct = entry.value.clamp(0.0, 100.0);
                        final g = _computeGrade(pct);
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(name, 
                                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                      overflow: pw.TextOverflow.clip,
                                      maxLines: 1),
                                  ),
                                  pw.Row(children: [
                                    pw.Text('${pct.toStringAsFixed(0)}%',
                                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                    pw.SizedBox(width: 6),
                                    pw.Container(
                                      width: 24,
                                      height: 16,
                                      decoration: pw.BoxDecoration(
                                        border: pw.Border.all(color: _black, width: 1),
                                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                                      ),
                                      alignment: pw.Alignment.center,
                                      child: pw.Text(g,
                                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                    ),
                                  ]),
                                ],
                              ),
                              pw.SizedBox(height: 3),
                              pw.Container(
                                height: 8,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: _gray400, width: 0.5),
                                  color: _gray200,
                                ),
                                child: pw.Row(
                                  children: [
                                    pw.Container(
                                      width: pct * 1.2,
                                      height: 8,
                                      decoration: const pw.BoxDecoration(color: _gray600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            // Right: Discipline & Activities
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _black, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _boxTitle('DISCIPLINE & ACTIVITIES'),
                    pw.SizedBox(height: 8),
                    ...disciplineData.entries.take(3).toList().asMap().entries.map((indexed) {
                      final i = indexed.key;
                      final e = indexed.value;
                      final isLast = i == disciplineData.entries.take(3).length - 1;
                      final rating = _ratingFromAvg(avgPct);
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        decoration: pw.BoxDecoration(
                          border: isLast
                              ? null
                              : pw.Border(bottom: pw.BorderSide(color: _gray200, width: 0.6)),
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 18,
                              height: 18,
                              margin: const pw.EdgeInsets.only(right: 8, top: 1),
                              decoration: pw.BoxDecoration(
                                color: _black,
                                shape: pw.BoxShape.circle,
                              ),
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                _disciplineIcon(e.key),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _white,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Text(e.key,
                                          style: pw.TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: pw.FontWeight.bold,
                                          )),
                                      ),
                                      _ratingDots(rating),
                                    ],
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(e.value,
                                    style: pw.TextStyle(fontSize: 8, color: _gray600),
                                    maxLines: 2,
                                    overflow: pw.TextOverflow.clip),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
        pw.SizedBox(height: 10),

        // ── Recent Exams (table layout) ─────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _black, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          padding: const pw.EdgeInsets.all(10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _boxTitle('RECENT EXAMS'),
              pw.SizedBox(height: 8),
              if (recentExams.isEmpty)
                pw.Text('No graded exams', style: pw.TextStyle(fontSize: 10))
              else
                pw.Table(
                  border: pw.TableBorder.all(color: _gray300, width: 0.5),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3.2),
                    1: pw.FlexColumnWidth(2.0),
                    2: pw.FlexColumnWidth(1.6),
                    3: pw.FlexColumnWidth(1.0),
                    4: pw.FlexColumnWidth(0.9),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _black),
                      children: [
                        _examCell('Exam', isHeader: true),
                        _examCell('Subject', isHeader: true),
                        _examCell('Marks', isHeader: true, align: pw.TextAlign.center),
                        _examCell('%', isHeader: true, align: pw.TextAlign.center),
                        _examCell('Grade', isHeader: true, align: pw.TextAlign.center),
                      ],
                    ),
                    ...recentExams.take(3).map((r) {
                      final exam = examsById[r.examId];
                      final pct = (r.marksObtained! / r.totalMarks * 100);
                      return pw.TableRow(
                        children: [
                          _examCell(exam?.title ?? 'Exam', bold: true),
                          _examCell(exam?.subject ?? '—', muted: true),
                          _examCell(
                            '${r.marksObtained!.toStringAsFixed(0)}/${r.totalMarks.toStringAsFixed(0)}',
                            align: pw.TextAlign.center,
                          ),
                          _examCell('${pct.toStringAsFixed(0)}%',
                            align: pw.TextAlign.center, bold: true),
                          _examCell(r.grade,
                            align: pw.TextAlign.center, bold: true),
                        ],
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // ── Attendance Strip (Black Background, White Text) ──────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _black,
            border: pw.Border.all(color: _black, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: pw.Row(children: [
            _whiteBoxTitle('ATTENDANCE'),
            pw.SizedBox(width: 16),
            _whiteAttendanceBadge('P', presentCount),
            pw.SizedBox(width: 12),
            _whiteAttendanceBadge('L', lateCount),
            pw.SizedBox(width: 12),
            _whiteAttendanceBadge('A', absentCount),
            pw.SizedBox(width: 12),
            _whiteAttendanceBadge('T', totalDays),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _white, width: 1.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text('${attPct.toStringAsFixed(1)}%',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _white)),
            ),
          ]),
        ),
        pw.SizedBox(height: 10),

        // ── Remarks & Signature (Aligned) ───────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Teacher Remarks
            pw.Expanded(
              flex: 6,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _black, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _boxTitle('TEACHER REMARKS'),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      teacherRemarks,
                      style: pw.TextStyle(fontSize: 9, height: 1.3),
                    ),
                    pw.SizedBox(height: 8),
                    // Removed em-dash, using cleaner format
                    pw.Text('Teacher: $generatedBy', 
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            // Signatures
            pw.Expanded(
              flex: 4,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _black, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _boxTitle('SIGNATURES'),
                    pw.SizedBox(height: 10),
                    pw.Container(height: 1.5, color: _black),
                    pw.SizedBox(height: 4),
                    pw.Text('Class Teacher', style: pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 12),
                    pw.Container(height: 1.5, color: _black),
                    pw.SizedBox(height: 4),
                    pw.Text('Principal', style: pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Multi-Page Layout ────────────────────────────────────────────────────
  static pw.Widget _buildHeader({
    required String studentName,
    required String? className,
    required String generatedBy,
    required String generatedOn,
    required String schoolName,
    double? avgPct,
  }) {
    final grade = avgPct != null ? _computeGrade(avgPct) : null;
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _black,
      ),
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(schoolName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _white)),
                pw.SizedBox(height: 2),
                pw.Text('Student Progress Report', style: pw.TextStyle(fontSize: 11, color: _white)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(studentName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _white)),
              if (className != null) pw.Text('Class: $className', style: pw.TextStyle(fontSize: 10, color: _white)),
              pw.Text('Date: $generatedOn', style: pw.TextStyle(fontSize: 10, color: _white)),
              if (grade != null && avgPct != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('${avgPct.toStringAsFixed(1)}% ($grade)',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _white)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _black, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by Schoolify', style: pw.TextStyle(fontSize: 9)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildOverviewCards({
    required double? avgPct,
    required double attPct,
    required int totalDays,
    required int presentCount,
    required int examCount,
    double? classAverage,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _black,
        border: pw.Border.all(color: _black, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Performance Overview', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _white)),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _whiteOverviewCard('Average Score', avgPct != null ? '${avgPct.toStringAsFixed(1)}%' : '—', avgPct != null ? _computeGrade(avgPct) : null),
              pw.SizedBox(width: 10),
              _whiteOverviewCard('Attendance', totalDays > 0 ? '${attPct.toStringAsFixed(1)}%' : '—', null),
              pw.SizedBox(width: 10),
              _whiteOverviewCard('Exams Taken', examCount > 0 ? '$examCount' : '—', null),
            ],
          ),
          if (classAverage != null && avgPct != null) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _white, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Class Average: ${classAverage.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 11, color: _white)),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    avgPct > classAverage 
                      ? '(Above average)' 
                      : avgPct < classAverage 
                        ? '(Below average)' 
                        : '(At average)',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _subjectAnalysisSection(Map<String, double> subjectAvg) {
    final sorted = subjectAvg.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: sorted.map((entry) {
        final name = entry.key;
        final pct = entry.value;
        final g = _computeGrade(pct);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 3, child: pw.Text(name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  height: 12,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _gray400, width: 1),
                    color: _gray200,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(width: pct * 1.8, height: 12, decoration: const pw.BoxDecoration(color: _gray600)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text('${pct.toStringAsFixed(0)}%', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 8),
              pw.Container(
                width: 32,
                height: 20,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _black, width: 1.5)),
                alignment: pw.Alignment.center,
                child: pw.Text(g, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _examTable(List<ExamResult> results, Map<String, Exam> examsById) {
    return pw.Table(
      border: pw.TableBorder.all(color: _black, width: 1),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _black),
          children: ['Exam', 'Subject', 'Marks', 'Total', '%', 'Grade'].map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(h, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _white)),
          )).toList(),
        ),
        ...results.where((r) => r.marksObtained != null).map((r) {
          final exam = examsById[r.examId];
          final pct = (r.marksObtained! / r.totalMarks * 100);
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(exam?.title ?? 'Exam', style: pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(exam?.subject ?? '', style: pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(r.marksObtained!.toStringAsFixed(0), style: pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(r.totalMarks.toStringAsFixed(0), style: pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${pct.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(r.grade, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _attendanceSummary(int present, int late, int absent, int total, double pct) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _black,
        border: pw.Border.all(color: _black, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _whiteAttendanceItem('Present', present),
          _whiteAttendanceItem('Late', late),
          _whiteAttendanceItem('Absent', absent),
          _whiteAttendanceItem('Total', total),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _white, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text('${pct.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _white)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _disciplineSection(Map<String, String> data, double? avgPct) {
    final grade = avgPct != null ? _computeGrade(avgPct) : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (grade != null)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _black, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text('Overall Grade: $grade', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
        ...data.entries.map((e) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 50,
                  decoration: const pw.BoxDecoration(color: _black),
                  margin: const pw.EdgeInsets.only(right: 10),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(e.key, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text(e.value, style: pw.TextStyle(fontSize: 10, color: _gray600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _gradeTable(List<Grade> grades) {
    return pw.Table(
      border: pw.TableBorder.all(color: _black, width: 1),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _black),
          children: ['Subject', 'Grade', 'Remarks'].map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(h, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _white)),
          )).toList(),
        ),
        ...grades.map((g) => pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(g.subject, style: pw.TextStyle(fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(g.grade, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(g.remarks, style: pw.TextStyle(fontSize: 10))),
          ],
        )),
      ],
    );
  }

  static pw.Widget _remarksBox(String remarks, String generatedBy) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _black, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(remarks, style: pw.TextStyle(fontSize: 11, height: 1.3)),
          pw.SizedBox(height: 10),
          // Removed em-dash, using "Teacher:" prefix
          pw.Text('Teacher: $generatedBy', 
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _signatureLine() {
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(height: 2, color: _black),
            pw.SizedBox(height: 4),
            pw.Text('Class Teacher Signature', style: pw.TextStyle(fontSize: 10)),
          ],
        )),
        pw.SizedBox(width: 40),
        pw.Expanded(child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(height: 2, color: _black),
            pw.SizedBox(height: 4),
            pw.Text('Principal Signature', style: pw.TextStyle(fontSize: 10)),
          ],
        )),
      ],
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────────────────
  static pw.Widget _statCard(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _black, width: 1.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: pw.Column(
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _boxTitle(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5));
  }

  static String _disciplineIcon(String key) {
    final k = key.toLowerCase();
    if (k.contains('discipline')) return 'D';
    if (k.contains('behavior')) return 'B';
    if (k.contains('clean')) return 'C';
    if (k.contains('curricular') || k.contains('activity')) return 'A';
    return '*';
  }

  static int _ratingFromAvg(double? avgPct) {
    if (avgPct == null) return 0;
    if (avgPct >= 90) return 5;
    if (avgPct >= 80) return 4;
    if (avgPct >= 65) return 3;
    if (avgPct >= 50) return 2;
    if (avgPct >= 33) return 1;
    return 0;
  }

  static pw.Widget _ratingDots(int rating) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return pw.Container(
          width: 7,
          height: 7,
          margin: const pw.EdgeInsets.only(left: 2),
          decoration: pw.BoxDecoration(
            color: filled ? _black : _white,
            border: pw.Border.all(color: _black, width: 0.8),
            shape: pw.BoxShape.circle,
          ),
        );
      }),
    );
  }

  static pw.Widget _examCell(
    String text, {
    bool isHeader = false,
    bool bold = false,
    bool muted = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 9.5,
          fontWeight: (isHeader || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? _white : (muted ? _gray600 : _black),
          letterSpacing: isHeader ? 0.3 : 0,
        ),
      ),
    );
  }

  static pw.Widget _whiteBoxTitle(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5, color: _white));
  }

  static pw.Widget _whiteAttendanceBadge(String label, int count) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 24,
          height: 24,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _white, width: 1.5),
            shape: pw.BoxShape.circle,
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _white)),
        ),
        pw.SizedBox(width: 4),
        pw.Text('$count', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _white)),
      ],
    );
  }

  static pw.Widget _whiteOverviewCard(String label, String value, String? badge) {
    return pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _white, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _white)),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _white)),
                if (badge != null) ...[
                  pw.SizedBox(width: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _white, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(badge, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _white)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _whiteAttendanceItem(String label, int value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _white)),
        pw.SizedBox(height: 6),
        pw.Text('$value', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _white)),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold));
  }

  static pw.Widget _emptyNote(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(14),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
    );
  }
}
