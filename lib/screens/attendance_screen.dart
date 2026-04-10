import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/database_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  List<Attendance> _students = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimations = List.generate(
      10,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval((index * 0.06).clamp(0, 0.8), (0.4 + index * 0.06).clamp(0, 1.0), curve: Curves.easeOut),
        ),
      ),
    );
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    final records = await dbService.getAttendanceForDate(_selectedDate);
    setState(() {
      _students = records;
      _isLoading = false;
    });
    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAttendance(int index) {
    setState(() {
      final s = _students[index];
      _students[index] = Attendance(
        studentId: s.studentId,
        studentName: s.studentName,
        date: s.date,
        isPresent: !s.isPresent,
      );
    });
  }

  Future<void> _saveAttendance() async {
    await dbService.saveAttendance(_students);
    final presentCount = _students.where((s) => s.isPresent).length;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Saved: $presentCount/${_students.length} present'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _students.where((s) => s.isPresent).length;
    final absentCount = _students.length - presentCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _saveAttendance,
                  icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                  label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Grade 10-A',
                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _StatPill(value: '$presentCount', label: 'Present', color: const Color(0xFF34D399)),
                            const SizedBox(width: 8),
                            _StatPill(value: '$absentCount', label: 'Absent', color: const Color(0xFFFCA5A5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final student = _students[index];
                    final animIdx = index < 10 ? index : 9;
                    return FadeTransition(
                      opacity: _fadeAnimations[animIdx],
                      child: _AttendanceCard(
                        student: student,
                        isDark: isDark,
                        onToggle: () => _toggleAttendance(index),
                      ),
                    );
                  },
                  childCount: _students.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatPill({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Attendance student;
  final bool isDark;
  final VoidCallback onToggle;

  const _AttendanceCard({required this.student, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isPresent = student.isPresent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPresent
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFFEF4444).withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  student.studentName[0],
                  style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.studentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(
                    'ID: ${student.studentId}',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isPresent
                      ? const Color(0xFF10B981).withOpacity(0.12)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPresent
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPresent ? Icons.check_rounded : Icons.close_rounded,
                      size: 14,
                      color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isPresent ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
