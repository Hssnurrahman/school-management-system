import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/attendance_model.dart';
import '../models/exam_model.dart';
import '../models/grade_model.dart';
import '../models/homework_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/report_pdf_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/legend_item.dart';
import '../widgets/shimmer_box.dart';
import 'student_attendance_screen.dart';

enum _ReportSort { nameAZ, averageHigh, attendanceHigh }

/// Teacher / admin: class-wide academic reports. Students see only their own row.
class StudentReportsScreen extends StatefulWidget {
  final String className;
  final UserModel? user;

  const StudentReportsScreen({super.key, required this.className, this.user});

  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> {
  List<_StudentInfo> _students = [];
  List<String> _classOptions = [];
  Map<String, int> _classCounts = const {};
  int _totalStudents = 0;
  String? _classFilter;
  String _search = '';
  _ReportSort _sort = _ReportSort.averageHigh;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _classFilter = widget.className.isEmpty ? null : widget.className;
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    final allStudents = await dbService.getUsers();
    final allAttendance = await dbService.getAllAttendance();
    final allExamResults = await dbService.getAllExamResults();

    final userId = widget.user?.id ?? '';
    final role =
        authService.effectiveRole ?? widget.user?.primaryRole ?? UserRole.principal;
    final allowedClasses = await dbService.getClassesForUser(userId, role);

    _classOptions = List<String>.from(allowedClasses)..sort();

    final counts = <String, int>{};
    var total = 0;
    for (final u in allStudents) {
      if (u.primaryRole != UserRole.student) continue;
      if (allowedClasses.isNotEmpty &&
          (u.className == null || !allowedClasses.contains(u.className))) {
        continue;
      }
      if (widget.user?.primaryRole == UserRole.student &&
          u.id != widget.user!.id) {
        continue;
      }
      total++;
      final cls = u.className;
      if (cls != null) counts[cls] = (counts[cls] ?? 0) + 1;
    }
    _classCounts = counts;
    _totalStudents = total;

    final studentMap = <String, _StudentInfo>{};

    for (final u in allStudents) {
      if (u.primaryRole != UserRole.student) continue;
      if (_classFilter != null &&
          _classFilter!.isNotEmpty &&
          u.className != _classFilter) {
        continue;
      }
      if (allowedClasses.isNotEmpty &&
          (u.className == null || !allowedClasses.contains(u.className))) {
        continue;
      }
      if (widget.user?.primaryRole == UserRole.student &&
          u.id != widget.user!.id) {
        continue;
      }
      studentMap[u.id] = _StudentInfo(
        id: u.id,
        name: u.name,
        className: u.className,
      );
    }

    for (final a in allAttendance) {
      final s = studentMap[a.studentId];
      if (s == null) continue;
      s.totalDays++;
      if (a.isPresent) s.presentDays++; // late counts as present
      if (a.isLate) s.lateDays++;
    }

    for (final r in allExamResults) {
      final s = studentMap[r.studentId];
      if (s == null) continue;
      s.examResultRows++;
      if (r.marksObtained != null) {
        s.examsGraded++;
        s._percentages.add((r.marksObtained! / r.totalMarks) * 100);
      }
    }

    for (final s in studentMap.values) {
      if (s._percentages.isNotEmpty) {
        s.avgPercentage =
            s._percentages.reduce((a, b) => a + b) / s._percentages.length;
      }
      s.subjectsWithMarks = s._percentages.length;
    }

    var list = studentMap.values.toList();
    _applySort(list);

    if (!mounted) return;
    setState(() {
      _students = list;
      _isLoading = false;
    });
  }

  void _applySort(List<_StudentInfo> list) {
    switch (_sort) {
      case _ReportSort.nameAZ:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case _ReportSort.averageHigh:
        list.sort((a, b) {
          final av = a.avgPercentage ?? -1;
          final bv = b.avgPercentage ?? -1;
          return bv.compareTo(av);
        });
        break;
      case _ReportSort.attendanceHigh:
        list.sort((a, b) {
          final ar = a.totalDays > 0 ? a.presentDays / a.totalDays : -1.0;
          final br = b.totalDays > 0 ? b.presentDays / b.totalDays : -1.0;
          return br.compareTo(ar);
        });
        break;
    }
  }

  Widget _buildClassFilterChip({
    required String label,
    required IconData icon,
    required int count,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    const accent = Color(0xFF2563EB);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? accent
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_StudentInfo> get _visibleStudents {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _students;
    return _students
        .where((s) => s.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        color: const Color(0xFF0D9488),
        onRefresh: _loadStudents,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 118,
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.user?.primaryRole == UserRole.student
                      ? 'My report'
                      : 'Student reports',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<_ReportSort>(
                  icon: const Icon(Icons.sort_rounded, color: Colors.white),
                  tooltip: 'Sort',
                  onSelected: (v) {
                    setState(() {
                      _sort = v;
                      final copy = List<_StudentInfo>.from(_students);
                      _applySort(copy);
                      _students = copy;
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _ReportSort.averageHigh,
                      child: Text('Average score (high → low)'),
                    ),
                    PopupMenuItem(
                      value: _ReportSort.attendanceHigh,
                      child: Text('Attendance (high → low)'),
                    ),
                    PopupMenuItem(
                      value: _ReportSort.nameAZ,
                      child: Text('Name (A–Z)'),
                    ),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search students…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF141E30)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.user?.primaryRole != UserRole.student &&
                _classOptions.length > 1)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildClassFilterChip(
                          label: 'All classes',
                          icon: Icons.apps_rounded,
                          count: _totalStudents,
                          isSelected: _classFilter == null,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _classFilter = null);
                            _loadStudents();
                          },
                        ),
                      ),
                      ..._classOptions.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildClassFilterChip(
                            label: c,
                            icon: Icons.class_rounded,
                            count: _classCounts[c] ?? 0,
                            isSelected: _classFilter == c,
                            isDark: isDark,
                            onTap: () {
                              setState(() => _classFilter = c);
                              _loadStudents();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStudentReportSkeleton(isDark),
                    childCount: 6,
                  ),
                ),
              )
            else if (_visibleStudents.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assessment_outlined,
                        size: 64,
                        color: Colors.grey.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No students match',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final student = _visibleStudents[index];
                      return _StudentReportListCard(
                        student: student,
                        isDark: isDark,
                        onTap: () => _openDetail(student),
                      );
                    },
                    childCount: _visibleStudents.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDetail(_StudentInfo student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StudentReportDetailScreen(student: student),
      ),
    );
  }

  Widget _buildStudentReportSkeleton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141E30) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8EDF5),
          ),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 52, height: 52, borderRadius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 140, height: 14),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 80, height: 10),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: const [
                      ShimmerBox(width: 76, height: 22, borderRadius: 999),
                      ShimmerBox(width: 84, height: 22, borderRadius: 999),
                      ShimmerBox(width: 70, height: 22, borderRadius: 999),
                    ],
                  ),
                ],
              ),
            ),
            const ShimmerBox(width: 46, height: 16),
          ],
        ),
      ),
    );
  }
}

class _StudentInfo {
  final String id;
  final String name;
  final String? className;
  final List<double> _percentages = [];
  double? avgPercentage;
  int subjectsWithMarks = 0;
  int presentDays = 0;
  int lateDays = 0;
  int totalDays = 0;
  int examResultRows = 0;
  int examsGraded = 0;

  _StudentInfo({
    required this.id,
    required this.name,
    this.className,
  });

  double? get attendanceRate =>
      totalDays > 0 ? presentDays / totalDays : null;
}

class _StudentReportListCard extends StatelessWidget {
  final _StudentInfo student;
  final bool isDark;
  final VoidCallback onTap;

  const _StudentReportListCard({
    required this.student,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = student.name.isNotEmpty ? student.name[0].toUpperCase() : '?';
    final att = student.attendanceRate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE8EDF5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF0D9488),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (student.className != null &&
                          student.className!.isNotEmpty)
                        Text(
                          student.className!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MiniStat(
                            icon: Icons.event_available_rounded,
                            color: const Color(0xFF10B981),
                            label: att != null
                                ? '${(att * 100).round()}% att.'
                                : 'No attendance',
                          ),
                          _MiniStat(
                            icon: Icons.assignment_turned_in_rounded,
                            color: const Color(0xFF2563EB),
                            label: student.examResultRows == 0
                                ? 'No exams'
                                : '${student.examsGraded}/${student.examResultRows} exams',
                          ),
                          _MiniStat(
                            icon: Icons.menu_book_rounded,
                            color: const Color(0xFF0EA5E9),
                            label:
                                '${student.subjectsWithMarks} subject${student.subjectsWithMarks == 1 ? '' : 's'}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (student.avgPercentage != null)
                      Text(
                        '${student.avgPercentage!.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      )
                    else
                      Text(
                        '—',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      'Avg. score',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentReportDetailScreen extends StatefulWidget {
  final _StudentInfo student;

  const _StudentReportDetailScreen({required this.student});

  @override
  State<_StudentReportDetailScreen> createState() =>
      _StudentReportDetailScreenState();
}

class _StudentReportDetailScreenState extends State<_StudentReportDetailScreen> {
  List<ExamResult> _examResults = [];
  Map<String, Exam> _examsById = {};
  List<Attendance> _attendance = [];
  List<Grade> _grades = [];
  List<Homework> _homework = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final id = widget.student.id;

      final exams = await dbService.getExams();
      final examResults = await dbService.getExamResultsForStudent(id);
      final attendance = await dbService.getAttendanceForStudent(id);
      final grades = await dbService.getGradesForStudent(id);
      final homework = await dbService.getHomework();

      final examMap = {for (final e in exams) e.id: e};
      examResults.sort((a, b) {
        final da = examMap[a.examId]?.date ?? DateTime(1970);
        final db_ = examMap[b.examId]?.date ?? DateTime(1970);
        return db_.compareTo(da);
      });

      if (!mounted) return;
      setState(() {
        _examResults = examResults;
        _examsById = examMap;
        _attendance = attendance;
        _grades = grades;
        _homework = homework.take(8).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load report: $e');
    }
  }

  double? _averageMarkPercentage() {
    final vals = [
      ..._examResults
          .where((r) => r.marksObtained != null)
          .map((r) => (r.marksObtained! / r.totalMarks) * 100),
    ];
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  Color? _colorForScore(double? pct) {
    if (pct == null) return null;
    if (pct >= 80) return const Color(0xFF16A34A);
    if (pct >= 60) return const Color(0xFFD97706);
    if (pct >= 40) return const Color(0xFFF97316);
    return const Color(0xFFDC2626);
  }

  Color? _colorForAttendance(double? rate) {
    if (rate == null) return null;
    final pct = rate * 100;
    if (pct >= 90) return const Color(0xFF16A34A);
    if (pct >= 75) return const Color(0xFFD97706);
    if (pct >= 60) return const Color(0xFFF97316);
    return const Color(0xFFDC2626);
  }

  String _reportSummaryText() {
    final sb = StringBuffer();
    final s = widget.student;
    sb.writeln('Student report — ${s.name}');
    if (s.className != null && s.className!.isNotEmpty) {
      sb.writeln('Class: ${s.className}');
    }
    final att = s.attendanceRate;
    if (att != null) {
      sb.writeln(
        'Attendance: ${s.presentDays}/${s.totalDays} days (${(att * 100).toStringAsFixed(0)}%)',
      );
    }
    final avg = _averageMarkPercentage();
    if (avg != null) {
      sb.writeln('Average subject score: ${avg.toStringAsFixed(1)}%');
    }
    sb.writeln('— Exam results —');
    if (_examResults.isEmpty) {
      sb.writeln('None recorded');
    } else {
      for (final r in _examResults) {
        final ex = _examsById[r.examId];
        final title = ex?.title ?? 'Exam';
        final line = r.marksObtained != null
            ? '${r.marksObtained!.toStringAsFixed(0)} / ${r.totalMarks.toStringAsFixed(0)} (${r.grade})'
            : 'Pending';
        sb.writeln('$title: $line');
      }
    }
    return sb.toString();
  }

  Future<void> _copyReport() async {
    await Clipboard.setData(ClipboardData(text: _reportSummaryText()));
    if (mounted) {
      showSuccessSnackBar(context, 'Report copied to clipboard');
    }
  }

  Future<void> _exportPdf() async {
    if (_isGeneratingPdf) return;

    // Show modern bottom sheet for PDF generation
    final remarksController = TextEditingController();
    bool singlePage = true; // Default to single page (summary)

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
          
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFF0D9488),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Generate Report',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.student.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Report Format Selection
                  Text(
                    'Select Report Format',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Format Options
                  Row(
                    children: [
                      // Summary Option
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDlg(() => singlePage = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: singlePage
                                  ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                                  : isDark
                                      ? const Color(0xFF334155)
                                      : Colors.grey.shade50,
                              border: Border.all(
                                color: singlePage
                                    ? const Color(0xFF0D9488)
                                    : isDark
                                        ? const Color(0xFF475569)
                                        : Colors.grey.shade200,
                                width: singlePage ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: singlePage
                                        ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                                        : isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.summarize_rounded,
                                    color: singlePage
                                        ? const Color(0xFF0D9488)
                                        : Colors.grey.shade400,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: singlePage
                                        ? const Color(0xFF0D9488)
                                        : isDark
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '1 page\nQuick overview',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Full Report Option
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDlg(() => singlePage = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: !singlePage
                                  ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                                  : isDark
                                      ? const Color(0xFF334155)
                                      : Colors.grey.shade50,
                              border: Border.all(
                                color: !singlePage
                                    ? const Color(0xFF2563EB)
                                    : isDark
                                        ? const Color(0xFF475569)
                                        : Colors.grey.shade200,
                                width: !singlePage ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: !singlePage
                                        ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                                        : isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.description_rounded,
                                    color: !singlePage
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey.shade400,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Detailed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: !singlePage
                                        ? const Color(0xFF2563EB)
                                        : isDark
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Multi-page\nComplete report',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Teacher Remarks
                  Text(
                    'Teacher Remarks (Optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: remarksController,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a personalized comment about the student\'s progress...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0D9488),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: const Text(
                        'Generate PDF',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: singlePage
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      remarksController.dispose();
    });

    if (confirmed != true || !mounted) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final generatedBy = authService.currentUser?.name ?? 'School Admin';
      final schoolInfo  = await dbService.getSchoolInfo();
      final schoolName  = schoolInfo['name']?.isNotEmpty == true
          ? schoolInfo['name']!
          : 'Schoolify';
      
      // Calculate class average for comparison
      double? classAverage;
      if (widget.student.className != null && widget.student.className!.isNotEmpty) {
        final allExamResults = await dbService.getAllExamResults();
        final allStudents = await dbService.getUsers();
        final classStudentIds = allStudents
            .where((u) => u.className == widget.student.className && u.primaryRole == UserRole.student)
            .map((u) => u.id)
            .toSet();
        
        final classPercentages = <double>[];
        for (final r in allExamResults) {
          if (classStudentIds.contains(r.studentId) && r.marksObtained != null) {
            classPercentages.add((r.marksObtained! / r.totalMarks) * 100);
          }
        }
        
        if (classPercentages.isNotEmpty) {
          classAverage = classPercentages.reduce((a, b) => a + b) / classPercentages.length;
        }
      }
      
      await ReportPdfService.generateAndShare(
        studentName: widget.student.name,
        className: widget.student.className,
        attendance: _attendance,
        examResults: _examResults,
        examsById: _examsById,
        grades: _grades,
        homework: _homework,
        generatedBy: generatedBy,
        schoolName: schoolName,
        teacherRemarks: remarksController.text.trim(),
        singlePage: singlePage,
        classAverage: classAverage,
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to generate PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avgPct = _averageMarkPercentage();
    final s = widget.student;
    final attRate = s.attendanceRate;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          s.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        actions: [
          if (_isGeneratingPdf)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export PDF',
              onPressed: _isLoading ? null : _exportPdf,
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy report',
            onPressed: _isLoading ? null : _copyReport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const ShimmerListSkeleton()
          : RefreshIndicator(
              color: const Color(0xFF0D9488),
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF0EA5E9)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _DetailStat(
                                  label: 'Avg %',
                                  value: avgPct != null
                                      ? '${avgPct.toStringAsFixed(1)}%'
                                      : '—',
                                  icon: Icons.percent_rounded,
                                  statusColor: _colorForScore(avgPct),
                                ),
                                _DetailStat(
                                  label: 'Attendance',
                                  value: attRate != null
                                      ? '${(attRate * 100).round()}%'
                                      : '—',
                                  icon: Icons.event_available_rounded,
                                  statusColor: _colorForAttendance(attRate),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${s.presentDays - s.lateDays} present · ${s.lateDays} late · ${s.totalDays - s.presentDays} absent · ${s.totalDays} total',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _sectionTitle('Attendance overview'),
                  SliverToBoxAdapter(
                    child: _AttendanceOverviewCard(
                      present: s.presentDays - s.lateDays,
                      late: s.lateDays,
                      absent: s.totalDays - s.presentDays,
                      recent: _attendance.take(12).toList(),
                      isDark: isDark,
                      onViewAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentAttendanceScreen(
                            studentId: s.id,
                            studentName: s.name,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _sectionTitle('Exam results'),
                  if (_examResults.isEmpty)
                    _emptySliver('No exam results for this student', isDark)
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _ExamResultRow(
                            result: _examResults[i],
                            exam: _examsById[_examResults[i].examId],
                            isDark: isDark,
                          ),
                          childCount: _examResults.length,
                        ),
                      ),
                    ),
                  _sectionTitle('Grade records'),
                  if (_grades.isEmpty)
                    _emptySliver('No grade book entries', isDark)
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _GradeRow(
                            grade: _grades[i],
                            isDark: isDark,
                          ),
                          childCount: _grades.length,
                        ),
                      ),
                    ),
                  _sectionTitle('Recent homework'),
                  if (_homework.isEmpty)
                    _emptySliver('No homework items', isDark)
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _HomeworkRow(
                            hw: _homework[i],
                            isDark: isDark,
                          ),
                          childCount: _homework.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _emptySliver(String msg, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141E30) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE8EDF5),
            ),
          ),
          child: Center(
            child: Text(
              msg,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? statusColor;

  const _DetailStat({
    required this.label,
    required this.value,
    required this.icon,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 19,
      ),
    );
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        if (statusColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor!.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
            ),
            child: valueText,
          )
        else
          valueText,
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AttendanceOverviewCard extends StatelessWidget {
  final int present;
  final int late;
  final int absent;
  final List<Attendance> recent;
  final bool isDark;
  final VoidCallback? onViewAll;

  const _AttendanceOverviewCard({
    required this.present,
    required this.late,
    required this.absent,
    required this.recent,
    required this.isDark,
    this.onViewAll,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = present + late + absent;
    final ratio = total > 0 ? (present + late) / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141E30) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE8EDF5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total > 0 ? ratio : 0,
                    minHeight: 10,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(child: LegendItem(useCircle: true,
                      color: const Color(0xFF10B981),
                      label: 'Present',
                      value: '$present',
                    )),
                    const SizedBox(width: 12),
                    Flexible(child: LegendItem(useCircle: true,
                      color: const Color(0xFFF59E0B),
                      label: 'Late',
                      value: '$late',
                    )),
                    const SizedBox(width: 12),
                    Flexible(child: LegendItem(useCircle: true,
                      color: const Color(0xFFEF4444),
                      label: 'Absent',
                      value: '$absent',
                    )),
                  ],
                ),
              ],
            ),
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent sessions',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...recent.map(
              (a) {
                final isLate = a.isLate;
                final isPresent = a.isPresent && !isLate;
                final color = isPresent
                    ? const Color(0xFF10B981)
                    : isLate
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444);
                final icon = isPresent
                    ? Icons.check_circle_rounded
                    : isLate
                        ? Icons.schedule_rounded
                        : Icons.cancel_rounded;
                final label = isPresent ? 'Present' : isLate ? 'Late' : 'Absent';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fmt(a.date),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else if (onViewAll != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'View attendance history',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF0D9488),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExamResultRow extends StatelessWidget {
  final ExamResult result;
  final Exam? exam;
  final bool isDark;

  const _ExamResultRow({
    required this.result,
    required this.exam,
    required this.isDark,
  });

  String _dateLine() {
    final d = result.marksUpdatedAt;
    if (d == null) return '';
    final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return 'Marks entered: $date';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141E30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8EDF5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam?.title ?? 'Exam',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (exam != null) exam!.subject,
                      if (_dateLine().isNotEmpty) _dateLine(),
                    ].join(' · '),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.marksObtained != null
                        ? '${result.marksObtained!.toStringAsFixed(0)} / ${result.totalMarks.toStringAsFixed(0)}'
                        : 'Pending',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (result.remarks != null && result.remarks!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        result.remarks!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: result.gradeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.grade,
                style: TextStyle(
                  color: result.gradeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  final Grade grade;
  final bool isDark;

  const _GradeRow({required this.grade, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141E30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8EDF5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score: ${grade.score}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  if (grade.remarks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        grade.remarks,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                grade.grade,
                style: const TextStyle(
                  color: Color(0xFF0EA5E9),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkRow extends StatelessWidget {
  final Homework hw;
  final bool isDark;

  const _HomeworkRow({required this.hw, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final d = hw.dueDate;
    final due =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141E30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8EDF5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hw.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              color: hw.isCompleted
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hw.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hw.subject} · Due $due',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
