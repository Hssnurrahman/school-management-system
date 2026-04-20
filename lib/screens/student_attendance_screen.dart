import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/circular_rate.dart';
import '../widgets/legend_item.dart';
import '../widgets/shimmer_box.dart';

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

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with TickerProviderStateMixin {
  List<Attendance> _records = [];
  bool _isLoading = true;

  // Which month keys are expanded (e.g. "2024-03")
  final Set<String> _expanded = {};

  late AnimationController _chartController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final records = await dbService.getAttendanceForStudent(widget.studentId);
      records.sort((a, b) => b.date.compareTo(a.date));

      final expanded = <String>{};
      if (records.isNotEmpty) {
        final d = records.first.date;
        expanded.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
      }

      if (!mounted) return;
      setState(() {
        _records = records;
        _expanded.clear();
        _expanded.addAll(expanded);
        _isLoading = false;
      });
      _chartController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  // ─── Overall stats ────────────────────────────────────────────────────────

  int get _presentCount => _records.where((r) => r.isPresent && !r.isLate).length;
  int get _lateCount    => _records.where((r) => r.isLate).length;
  int get _absentCount  => _records.where((r) => !r.isPresent).length;
  double get _attendancePct =>
      _records.isEmpty ? 0 : ((_presentCount + _lateCount) / _records.length) * 100;

  // ─── Calendar heatmap data ────────────────────────────────────────────────

  /// Get last 6 months of data for heatmap
  List<HeatmapMonth> get _heatmapData {
    final now = DateTime.now();
    final months = <HeatmapMonth>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final days = <HeatmapDay>[];

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(month.year, month.month, day);
        final record = _records.firstWhere(
          (r) => r.date.year == date.year && r.date.month == date.month && r.date.day == date.day,
          orElse: () => Attendance(
            studentId: '',
            studentName: '',
            date: date,
            isPresent: false,
            isLate: false,
          ),
        );
        days.add(HeatmapDay(
          date: date,
          isPresent: record.studentId.isNotEmpty && record.isPresent && !record.isLate,
          isLate: record.studentId.isNotEmpty && record.isLate,
          isAbsent: record.studentId.isNotEmpty && !record.isPresent,
          noRecord: record.studentId.isEmpty,
        ));
      }

      months.add(HeatmapMonth(
        year: month.year,
        month: month.month,
        days: days,
      ));
    }

    return months;
  }

  // ─── Group records by month ───────────────────────────────────────────────

  /// Returns list of (monthKey, monthLabel, records) sorted newest first.
  List<({String key, String label, List<Attendance> records})> get _byMonth {
    final map = <String, List<Attendance>>{};
    for (final r in _records) {
      final key = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
      (map[key] ??= []).add(r);
    }
    final months = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return months.map((key) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final label = '${_monthName(month)} $year';
      final recs = map[key]!;
      recs.sort((a, b) => b.date.compareTo(a.date));
      return (key: key, label: label, records: recs);
    }).toList();
  }

  String _monthName(int m) => const [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ][m];

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final months = _byMonth;
    final heatmapMonths = _heatmapData;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            title: Text(
              widget.studentName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 17,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _HeaderBackground(
                studentName: widget.studentName,
                presentCount: _presentCount,
                lateCount: _lateCount,
                absentCount: _absentCount,
                totalCount: _records.length,
                pct: _attendancePct,
                animation: _chartAnimation,
              ),
            ),
          ),

          // ── Loading / empty ───────────────────────────────────────────────
          if (_isLoading)
            const ShimmerListSkeleton(asSliver: true)
          else if (_records.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('No attendance records yet',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else ...[

            // ── Calendar Heatmap ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: _CalendarHeatmap(
                  months: heatmapMonths,
                  isDark: isDark,
                ),
              ),
            ),

            // ── Overall progress card ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: _OverallCard(
                  presentCount: _presentCount,
                  lateCount: _lateCount,
                  absentCount: _absentCount,
                  pct: _attendancePct,
                  isDark: isDark,
                ),
              ),
            ),

            // ── Recent Activity Header ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Month groups ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final m = months[index];
                    final isOpen = _expanded.contains(m.key);
                    return _MonthGroup(
                      monthKey: m.key,
                      monthLabel: m.label,
                      records: m.records,
                      isExpanded: isOpen,
                      isDark: isDark,
                      onToggle: () => setState(() {
                        if (isOpen) {
                          _expanded.remove(m.key);
                        } else {
                          _expanded.add(m.key);
                        }
                      }),
                    );
                  },
                  childCount: months.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }
}

// ─── Calendar Heatmap ─────────────────────────────────────────────────────────

class HeatmapDay {
  final DateTime date;
  final bool isPresent;
  final bool isLate;
  final bool isAbsent;
  final bool noRecord;

  HeatmapDay({
    required this.date,
    required this.isPresent,
    required this.isLate,
    required this.isAbsent,
    required this.noRecord,
  });
}

class HeatmapMonth {
  final int year;
  final int month;
  final List<HeatmapDay> days;

  HeatmapMonth({
    required this.year,
    required this.month,
    required this.days,
  });

  String get name => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][month];
}

class _CalendarHeatmap extends StatefulWidget {
  final List<HeatmapMonth> months;
  final bool isDark;

  const _CalendarHeatmap({
    required this.months,
    required this.isDark,
  });

  @override
  State<_CalendarHeatmap> createState() => _CalendarHeatmapState();
}

class _CalendarHeatmapState extends State<_CalendarHeatmap> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Jump to the end (most recent month) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get isDark => widget.isDark;
  List<HeatmapMonth> get months => widget.months;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_month_rounded,
                size: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                '6-Month Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Heatmap grid
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: months.map((month) => _buildMonthColumn(month)).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                LegendItem(color: const Color(0xFF10B981).withValues(alpha: 0.2), label: 'Present'),
                const SizedBox(width: 12),
                LegendItem(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), label: 'Late'),
                const SizedBox(width: 12),
                LegendItem(color: const Color(0xFFEF4444).withValues(alpha: 0.2), label: 'Absent'),
                const SizedBox(width: 12),
                LegendItem(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, label: 'No record'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthColumn(HeatmapMonth month) {
    final weeks = <List<HeatmapDay?>>[];
    var currentWeek = <HeatmapDay?>[];

    // Add empty cells for days before the first of the month
    final firstDay = month.days.first.date.weekday % 7;
    for (int i = 0; i < firstDay; i++) {
      currentWeek.add(null);
    }

    for (final day in month.days) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // Add remaining cells
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          ...weeks.map((week) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: week.map((day) {
                if (day == null) {
                  return const SizedBox(width: 10, height: 10);
                }
                Color color;
                if (day.noRecord) {
                  color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200;
                } else if (day.isPresent) {
                  color = const Color(0xFF10B981).withValues(alpha: 0.7);
                } else if (day.isLate) {
                  color = const Color(0xFFF59E0B).withValues(alpha: 0.7);
                } else {
                  color = const Color(0xFFEF4444).withValues(alpha: 0.5);
                }

                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Overall summary card ─────────────────────────────────────────────────────

class _OverallCard extends StatelessWidget {
  final int presentCount, lateCount, absentCount;
  final double pct;
  final bool isDark;

  const _OverallCard({
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.pct,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = presentCount + lateCount + absentCount;
    final color = pct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Rate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar with segments
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (presentCount > 0)
                    Flexible(
                      flex: presentCount,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (lateCount > 0)
                    Flexible(
                      flex: lateCount,
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  if (absentCount > 0)
                    Flexible(
                      flex: absentCount,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(child: _Legend(color: const Color(0xFF10B981), label: 'Present', value: '$presentCount')),
              const SizedBox(width: 12),
              Flexible(child: _Legend(color: const Color(0xFFF59E0B), label: 'Late',    value: '$lateCount')),
              const SizedBox(width: 12),
              Flexible(child: _Legend(color: const Color(0xFFEF4444), label: 'Absent',  value: '$absentCount')),
              const Spacer(),
              Flexible(
                child: Text(
                  '$total days',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  pct >= 75 ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  pct >= 75 ? 'Good standing — keep it up!' : 'Below 75% — attendance needs improvement',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _Legend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$label: $value',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ─── Month group ──────────────────────────────────────────────────────────────

class _MonthGroup extends StatefulWidget {
  final String monthKey;
  final String monthLabel;
  final List<Attendance> records;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggle;

  const _MonthGroup({
    required this.monthKey,
    required this.monthLabel,
    required this.records,
    required this.isExpanded,
    required this.isDark,
    required this.onToggle,
  });

  @override
  State<_MonthGroup> createState() => _MonthGroupState();
}

class _MonthGroupState extends State<_MonthGroup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(_controller);
    if (widget.isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(_MonthGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = widget.records.where((r) => r.isPresent && !r.isLate).length;
    final late    = widget.records.where((r) => r.isLate).length;
    final absent  = widget.records.where((r) => !r.isPresent).length;
    final total   = widget.records.length;
    final pct     = total > 0 ? (present + late) / total * 100 : 0.0;
    final color   = pct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5),
          ),
        ),
        child: Column(
          children: [
            // ── Header (always visible) ───────────────────────────────────
            InkWell(
              onTap: widget.onToggle,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: widget.isExpanded ? Radius.zero : const Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    // Month rate circle
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
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
                            widget.monthLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$present present · $late late · $absent absent',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 4,
                              backgroundColor: color.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    RotationTransition(
                      turns: _iconRotation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable day list ───────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: widget.isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  Divider(
                    height: 1,
                    color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5),
                  ),
                  ...widget.records.asMap().entries.map((entry) => _DayRow(
                    record: entry.value,
                    isDark: widget.isDark,
                    index: entry.key,
                  )),
                  const SizedBox(height: 4),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Individual day row ───────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final Attendance record;
  final bool isDark;
  final int index;

  const _DayRow({required this.record, required this.isDark, required this.index});

  @override
  Widget build(BuildContext context) {
    final isLate    = record.isLate;
    final isPresent = record.isPresent && !isLate;
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
    final statusLabel = isPresent ? 'Present' : isLate ? 'Late' : 'Absent';

    final d = record.date;
    final dateStr = '${d.day.toString().padLeft(2, '0')} ${_shortMonth(d.month)} ${d.year}';
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: AnimationController(
            vsync: Navigator.of(context),
            duration: Duration(milliseconds: 150 + (index * 30).clamp(0, 300)),
          )..forward(),
          curve: Curves.easeOut,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortMonth(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}

// ─── Header background ────────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final String studentName;
  final int presentCount, lateCount, absentCount, totalCount;
  final double pct;
  final Animation<double> animation;

  const _HeaderBackground({
    required this.studentName,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.totalCount,
    required this.pct,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = pct >= 75 ? const Color(0xFF34D399) : const Color(0xFFFCA5A5);
    final statusLabel = pct >= 75 ? 'Good standing' : 'Needs improvement';
    final initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF3B82F6)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Top row: avatar + name block / ring
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Name + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '$totalCount sessions',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.55),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Circular rate ring
                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) => CircularRate(
                          pct: pct * animation.value,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stat chips
                  Row(
                    children: [
                      Expanded(
                        child: _MiniChip(
                          value: '$presentCount',
                          label: 'Present',
                          color: const Color(0xFF34D399),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniChip(
                          value: '$lateCount',
                          label: 'Late',
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniChip(
                          value: '$absentCount',
                          label: 'Absent',
                          color: const Color(0xFFFCA5A5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

