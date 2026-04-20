import 'package:flutter/material.dart';
import '../models/grade_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/shimmer_box.dart';

class GradesScreen extends StatefulWidget {
  final String studentId;
  const GradesScreen({super.key, required this.studentId});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  List<Grade> _grades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final grades = await dbService.getGradesForStudent(widget.studentId);
      if (!mounted) return;
      setState(() {
        _grades = grades;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  double _computeGpa() {
    if (_grades.isEmpty) return 0.0;
    double total = 0;
    for (final g in _grades) {
      final parts = g.score.split('/');
      if (parts.length == 2) {
        final score = double.tryParse(parts[0]) ?? 0;
        final max = double.tryParse(parts[1]) ?? 100;
        final pct = score / max;
        if (pct >= 0.9) { total += 4.0; }
        else if (pct >= 0.8) { total += 3.7; }
        else if (pct >= 0.7) { total += 3.3; }
        else if (pct >= 0.6) { total += 3.0; }
        else if (pct >= 0.5) { total += 2.0; }
        else { total += 0.0; }
      }
    }
    return total / _grades.length;
  }

  int _countGrade(String prefix) =>
      _grades.where((g) => g.grade.startsWith(prefix)).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gpa = _computeGpa();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Academic Results', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Overall GPA', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(gpa.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1)),
                              const Text('out of 4.0', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const ShimmerListSkeleton(asSliver: true)
          else if (_grades.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grade_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('No grades available yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    _buildStatCard('${_grades.length}', 'Subjects', const Color(0xFF0EA5E9), isDark),
                    const SizedBox(width: 10),
                    _buildStatCard('${_countGrade('A')}', 'A Grades', const Color(0xFF10B981), isDark),
                    const SizedBox(width: 10),
                    _buildStatCard('${_countGrade('B')}', 'B Grades', const Color(0xFF0284C7), isDark),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _GradeCard(grade: _grades[index], isDark: isDark),
                  childCount: _grades.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141E30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final Grade grade;
  final bool isDark;

  const _GradeCard({required this.grade, required this.isDark});

  Color _getGradeColor(String g) {
    if (g.startsWith('A')) return const Color(0xFF10B981);
    if (g.startsWith('B')) return const Color(0xFF3B82F6);
    if (g.startsWith('C')) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  double _getPercent() {
    final parts = grade.score.split('/');
    if (parts.length == 2) {
      final s = double.tryParse(parts[0]) ?? 0;
      final t = double.tryParse(parts[1]) ?? 100;
      return s / t;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final gradeColor = _getGradeColor(grade.grade);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: gradeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: gradeColor.withValues(alpha: 0.25))),
            child: Center(child: Text(grade.grade, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: gradeColor))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(grade.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(grade.remarks, style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: _getPercent(), backgroundColor: gradeColor.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(gradeColor), minHeight: 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(grade.score, style: TextStyle(color: gradeColor, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}
