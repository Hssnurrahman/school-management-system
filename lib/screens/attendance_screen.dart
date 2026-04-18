import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/filter_chip_button.dart';
import '../widgets/header_stat_card.dart';
import '../widgets/search_bar_field.dart';

class AttendanceScreen extends StatefulWidget {
  final UserModel? user;
  const AttendanceScreen({super.key, this.user});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  List<Attendance> _students = [];
  List<Attendance> _allStudents = [];
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  List<String> _availableClasses = [];
  String? _selectedClass;
  Map<String, String> _studentClasses = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<DateTime> _datesWithRecords = {};

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  // Status colors
  static const _presentColor = Color(0xFF10B981);
  static const _lateColor = Color(0xFFF59E0B);
  static const _absentColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimations = List.generate(
      30,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.03).clamp(0, 0.7),
            (0.3 + index * 0.03).clamp(0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    _weekStart = _getWeekStart(_selectedDate);
    _loadAttendance();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final records = await dbService.getAttendanceForDate(_selectedDate);
      List<Attendance> students;
      if (records.isEmpty) {
        students = await dbService.getAllStudentsForAttendance(_selectedDate);
      } else {
        students = records;
      }
      final allUsers = await dbService.getUsers();

      final userRole = widget.user?.primaryRole;
      final userId = widget.user?.id ?? '';
      final allowedClasses = await dbService.getClassesForUser(
        userId,
        userRole ?? UserRole.principal,
      );

      final classes = allUsers
          .where((u) => u.className != null && u.className!.isNotEmpty)
          .map((u) => u.className!)
          .toSet()
          .where((c) => allowedClasses.isEmpty || allowedClasses.contains(c))
          .toList();
      final studentClassMap = <String, String>{};
      for (final u in allUsers) {
        if (u.className != null && u.className!.isNotEmpty) {
          studentClassMap[u.id] = u.className!;
        }
      }

      // Load dates with records for the current week
      final datesWithRecords = <DateTime>{};
      for (int i = 0; i < 7; i++) {
        final date = _weekStart.add(Duration(days: i));
        final dayRecords = await dbService.getAttendanceForDate(date);
        if (dayRecords.isNotEmpty) {
          datesWithRecords.add(DateTime(date.year, date.month, date.day));
        }
      }

      if (!mounted) return;
      setState(() {
        _allStudents = students;
        _availableClasses = classes..sort();
        _studentClasses = studentClassMap;
        _datesWithRecords = datesWithRecords;
        _applyFilters();
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  void _applyFilters() {
    var filtered = _allStudents;

    // Apply class filter
    if (_selectedClass != null && _selectedClass!.isNotEmpty) {
      filtered = filtered
          .where((a) => _studentClasses[a.studentId] == _selectedClass)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((a) => a.studentName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    _students = filtered;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _selectDate(DateTime date) async {
    if (!await _confirmDiscard()) return;
    setState(() {
      _selectedDate = date;
      _weekStart = _getWeekStart(date);
      _hasUnsavedChanges = false;
    });
    _loadAttendance();
  }

  void _selectClass(String? className) async {
    if (_hasUnsavedChanges && _selectedClass != className) {
      if (!await _confirmDiscard()) return;
    }
    setState(() {
      _selectedClass = _selectedClass == className ? null : className;
      _hasUnsavedChanges = false;
    });
    _applyFilters();
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _selectedDate = _weekStart.add(Duration(days: _selectedDate.weekday - 1));
    });
    _loadAttendance();
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _selectedDate = _weekStart.add(Duration(days: _selectedDate.weekday - 1));
    });
    _loadAttendance();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) return true;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('You have unsaved attendance. Discard changes?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _toggleAttendance(int index) {
    setState(() {
      _hasUnsavedChanges = true;
      final s = _students[index];
      // Cycle: Present → Late → Absent → Present
      late bool newPresent;
      late bool newLate;
      if (s.isPresent && !s.isLate) {
        newPresent = true;
        newLate = true;
      } else if (s.isPresent && s.isLate) {
        newPresent = false;
        newLate = false;
      } else {
        newPresent = true;
        newLate = false;
      }
      _students[index] = Attendance(
        studentId: s.studentId,
        studentName: s.studentName,
        date: s.date,
        isPresent: newPresent,
        isLate: newLate,
      );
    });
  }

  void _markAllPresent() {
    setState(() {
      _hasUnsavedChanges = true;
      for (int i = 0; i < _students.length; i++) {
        final s = _students[i];
        _students[i] = Attendance(
          studentId: s.studentId,
          studentName: s.studentName,
          date: s.date,
          isPresent: true,
          isLate: false,
        );
      }
    });
    _showBulkActionSnackbar('All marked present');
  }

  void _markAllAbsent() {
    setState(() {
      _hasUnsavedChanges = true;
      for (int i = 0; i < _students.length; i++) {
        final s = _students[i];
        _students[i] = Attendance(
          studentId: s.studentId,
          studentName: s.studentName,
          date: s.date,
          isPresent: false,
          isLate: false,
        );
      }
    });
    _showBulkActionSnackbar('All marked absent');
  }

  void _markAllLate() {
    setState(() {
      _hasUnsavedChanges = true;
      for (int i = 0; i < _students.length; i++) {
        final s = _students[i];
        _students[i] = Attendance(
          studentId: s.studentId,
          studentName: s.studentName,
          date: s.date,
          isPresent: true,
          isLate: true,
        );
      }
    });
    _showBulkActionSnackbar('All marked late');
  }

  void _showBulkActionSnackbar(String message) {
    showInfoSnackBar(context, message);
  }

  Future<void> _saveAttendance() async {
    await dbService.saveAttendance(_students);
    final presentCount = _students.where((s) => s.isPresent && !s.isLate).length;
    final lateCount = _students.where((s) => s.isLate).length;
    if (mounted) {
      _hasUnsavedChanges = false;
      showSuccessSnackBar(context, 'Saved: $presentCount present · $lateCount late · ${_students.length - presentCount - lateCount} absent');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _students.where((s) => s.isPresent && !s.isLate).length;
    final lateCount = _students.where((s) => s.isLate).length;
    final absentCount = _students.length - presentCount - lateCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _hasUnsavedChanges) {
          final nav = Navigator.of(context);
          final discard = await _confirmDiscard();
          if (discard && mounted) {
            nav.pop();
          }
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              stretch: true,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              title: const Text(
                'Attendance',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: _saveAttendance,
                    icon: const Icon(
                      Icons.save_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Date label
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Week Navigation
                        _buildWeekNavigator(),
                        const SizedBox(height: 8),
                        // Stats Row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: HeaderStatCard(
                                  value: '$presentCount',
                                  label: 'Present',
                                  color: _presentColor,
                                  icon: Icons.check_circle_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: HeaderStatCard(
                                  value: '$lateCount',
                                  label: 'Late',
                                  color: _lateColor,
                                  icon: Icons.schedule_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: HeaderStatCard(
                                  value: '$absentCount',
                                  label: 'Absent',
                                  color: _absentColor,
                                  icon: Icons.cancel_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
              // ── Date Picker Strip ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildDateStrip(),
              ),

              // ── Search Bar ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: SearchBarField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    hint: 'Search students...',
                  ),
                ),
              ),

              // ── Class Filter Chips ────────────────────────────────────────
              if (_availableClasses.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChipButton(
                            label: 'All',
                            isSelected: _selectedClass == null,
                            onTap: () => _selectClass(null),
                          ),
                          ..._availableClasses.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChipButton(
                                label: c,
                                isSelected: _selectedClass == c,
                                onTap: () => _selectClass(c),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Bulk Actions ──────────────────────────────────────────────
              if (_students.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: _BulkActionsBar(
                      onMarkAllPresent: _markAllPresent,
                      onMarkAllAbsent: _markAllAbsent,
                      onMarkAllLate: _markAllLate,
                    ),
                  ),
                ),

              // ── Student List ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: _students.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No students found'
                                    : 'No students match "$_searchQuery"',
                                style: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final student = _students[index];
                          final animIdx = index < 30 ? index : 29;
                          return FadeTransition(
                            opacity: _fadeAnimations[animIdx],
                            child: _AttendanceCard(
                              student: student,
                              isDark: isDark,
                              onToggle: () => _toggleAttendance(index),
                              studentClass: _studentClasses[student.studentId],
                            ),
                          );
                        }, childCount: _students.length),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousWeek,
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: Text(
              _formatMonthYear(_weekStart),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _nextWeek,
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = _weekStart.add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;
          final isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;
          final hasRecords = _datesWithRecords.contains(
            DateTime(date.year, date.month, date.day),
          );
          final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];

          return _DateStripItem(
            dayName: dayName,
            date: date.day.toString(),
            isSelected: isSelected,
            isToday: isToday,
            hasRecords: hasRecords,
            onTap: () => _selectDate(date),
          );
        }),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _DateStripItem extends StatelessWidget {
  final String dayName;
  final String date;
  final bool isSelected;
  final bool isToday;
  final bool hasRecords;
  final VoidCallback onTap;

  const _DateStripItem({
    required this.dayName,
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasRecords,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2563EB) : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E40AF) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected
                    ? (hasRecords ? const Color(0xFF10B981) : Colors.transparent)
                    : (hasRecords ? Colors.white70 : Colors.transparent),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkActionsBar extends StatelessWidget {
  final VoidCallback onMarkAllPresent;
  final VoidCallback onMarkAllAbsent;
  final VoidCallback onMarkAllLate;

  const _BulkActionsBar({
    required this.onMarkAllPresent,
    required this.onMarkAllAbsent,
    required this.onMarkAllLate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Mark',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  label: 'All Present',
                  color: const Color(0xFF10B981),
                  onTap: onMarkAllPresent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  label: 'All Late',
                  color: const Color(0xFFF59E0B),
                  onTap: onMarkAllLate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  label: 'All Absent',
                  color: const Color(0xFFEF4444),
                  onTap: onMarkAllAbsent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatefulWidget {
  final Attendance student;
  final bool isDark;
  final VoidCallback onToggle;
  final String? studentClass;

  const _AttendanceCard({
    required this.student,
    required this.isDark,
    required this.onToggle,
    this.studentClass,
  });

  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_AttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.isPresent != widget.student.isPresent ||
        oldWidget.student.isLate != widget.student.isLate) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLate = widget.student.isLate;
    final isPresent = widget.student.isPresent && !isLate;

    final Color statusColor = isPresent
        ? const Color(0xFF10B981)
        : isLate
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final IconData statusIcon = isPresent
        ? Icons.check_rounded
        : isLate
            ? Icons.schedule_rounded
            : Icons.close_rounded;

    final String statusLabel = isPresent
        ? 'Present'
        : isLate
            ? 'Late'
            : 'Absent';

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.student.studentName.isNotEmpty
                        ? widget.student.studentName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'ID: ${widget.student.studentId}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (widget.studentClass != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.studentClass!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0D9488),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status Button
              GestureDetector(
                onTap: widget.onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isPresent
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          )
                        : isLate
                            ? const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
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
      ),
    );
  }
}