import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/database_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentAttendanceScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<Attendance> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    final records = await dbService.getAttendanceForStudent(widget.studentId);
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  int get _presentCount => _records.where((r) => r.isPresent).length;
  int get _absentCount => _records.where((r) => !r.isPresent).length;
  double get _attendancePct =>
      _records.isEmpty ? 0 : (_presentCount / _records.length) * 100;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('My Attendance', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(widget.studentName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatPill(value: '$_presentCount', label: 'Present', color: const Color(0xFF34D399)),
                            const SizedBox(width: 8),
                            _StatPill(value: '$_absentCount', label: 'Absent', color: const Color(0xFFFCA5A5)),
                            const SizedBox(width: 8),
                            _StatPill(value: '${_attendancePct.toStringAsFixed(0)}%', label: 'Rate', color: Colors.white),
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
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_records.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    const Text('No attendance records yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else ...[
            // Progress bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141E30) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Attendance Rate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('${_attendancePct.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _attendancePct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _attendancePct / 100,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(_attendancePct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _attendancePct >= 75 ? 'Good standing — keep it up!' : 'Below 75% — attendance needs improvement',
                        style: TextStyle(fontSize: 12, color: _attendancePct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final record = _records[index];
                    return _AttendanceRow(record: record, isDark: isDark);
                  },
                  childCount: _records.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
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
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final Attendance record;
  final bool isDark;

  const _AttendanceRow({required this.record, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPresent = record.isPresent;
    final color = isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final dateStr = '${record.date.day}/${record.date.month}/${record.date.year}';
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][record.date.weekday - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(isPresent ? Icons.check_rounded : Icons.close_rounded, color: color, size: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(weekday, style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(isPresent ? 'Present' : 'Absent', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
