import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/subject_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/shimmer_box.dart';

class ExamScreen extends StatefulWidget {
  final UserModel teacher;
  const ExamScreen({super.key, required this.teacher});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen>
    with TickerProviderStateMixin {
  List<Exam> _allExams = [];
  List<ClassModel> _allClasses = [];
  List<SubjectModel> _subjects = [];
  List<String> _teacherClasses = [];
  bool _isLoading = true;

  // "All" tab + one tab per assigned class
  late TabController _tabController;
  // Which class tab is active — null means "All"
  String? _activeClass;

  // Filters
  String? _filterSubject; // null = all subjects
  String _filterPeriod = 'All'; // 'All' | 'This Week' | 'This Month'
  String? _filterTitle;  // null = all titles; matches exam title keyword
  String _filterStatus = 'All'; // 'All' | 'Upcoming' | 'Completed'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // placeholder
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _isLoading = true);

    try {
      final classes = await dbService.getClasses();
      final teacherClassNames =
          await dbService.getTeacherClasses(widget.teacher.id);
      final effectiveClasses = teacherClassNames.isNotEmpty
          ? teacherClassNames
          : (widget.teacher.className != null
              ? [widget.teacher.className!]
              : <String>[]);

      final allSubjects = await dbService.getSubjects();
      final teacherSubjectNames =
          await dbService.getTeacherSubjects(widget.teacher.id);
      final filteredSubjects = teacherSubjectNames.isNotEmpty
          ? allSubjects.where((s) => teacherSubjectNames.contains(s.name)).toList()
          : allSubjects;

      final exams = effectiveClasses.isNotEmpty
          ? await dbService.getExamsForClasses(effectiveClasses)
          : await dbService.getExams();

      final tabCount = effectiveClasses.length + 1;
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this)
        ..addListener(() {
          if (_tabController.indexIsChanging) return;
          final idx = _tabController.index;
          final newClass = idx == 0 ? null : effectiveClasses[idx - 1];
          setState(() {
            _activeClass = newClass;
            if (_filterSubject != null) {
              final subjectsInNewClass = _allExams
                  .where((e) => newClass == null || e.className == newClass)
                  .map((e) => e.subject)
                  .toSet();
              if (!subjectsInNewClass.contains(_filterSubject)) {
                _filterSubject = null;
              }
            }
          });
        });

      if (!mounted) return;
      setState(() {
        _allClasses = classes;
        _teacherClasses = effectiveClasses;
        _subjects = filteredSubjects;
        _allExams = exams;
        _activeClass = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load exams: $e');
    }
  }

  Future<void> _load() async {
    final exams = _teacherClasses.isNotEmpty
        ? await dbService.getExamsForClasses(_teacherClasses)
        : await dbService.getExams();
    if (!mounted) return;
    setState(() => _allExams = exams);
  }

  List<Exam> get _visibleExams {
    final now = DateTime.now();
    return _allExams.where((e) {
      // Class filter
      if (_activeClass != null && e.className != _activeClass) return false;
      // Subject filter
      if (_filterSubject != null && e.subject != _filterSubject) return false;
      // Title keyword filter
      if (_filterTitle != null &&
          !e.title.toLowerCase().contains(_filterTitle!.toLowerCase())) {
        return false;
      }
      // Status filter
      if (_filterStatus == 'Upcoming' && !e.endDateTime.isAfter(now)) return false;
      if (_filterStatus == 'Completed' && e.endDateTime.isAfter(now)) return false;
      // Period filter
      if (_filterPeriod == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        if (e.date.isBefore(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)) ||
            e.date.isAfter(DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59))) {
          return false;
        }
      } else if (_filterPeriod == 'This Month') {
        if (e.date.year != now.year || e.date.month != now.month) return false;
      }
      return true;
    }).toList();
  }

  /// Unique subjects across all exams for the active class tab
  List<String> get _availableSubjects {
    final base = _activeClass == null
        ? _allExams
        : _allExams.where((e) => e.className == _activeClass);
    return base.map((e) => e.subject).toSet().toList()..sort();
  }

  List<Exam> get _upcoming => _visibleExams
      .where((e) => e.endDateTime.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<Exam> get _past => _visibleExams
      .where((e) => !e.endDateTime.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  // Per-class quick stats
  Map<String, int> get _examCountByClass {
    final counts = <String, int>{};
    for (final cls in _teacherClasses) {
      counts[cls] = _allExams.where((e) => e.className == cls).length;
    }
    return counts;
  }

  Widget _buildExamCardSkeleton(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
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
              children: const [
                ShimmerBox(width: 160, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 110, height: 10),
                SizedBox(height: 8),
                ShimmerBox(width: 70, height: 20, borderRadius: 999),
              ],
            ),
          ),
          const ShimmerBox(width: 24, height: 24, borderRadius: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          title: const Text(
            'Exams',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: 6,
          itemBuilder: (_, i) => _buildExamCardSkeleton(isDark),
        ),
      );
    }

    final tabs = <Widget>[
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('All'),
            const SizedBox(width: 4),
            _CountBadge(count: _allExams.length),
          ],
        ),
      ),
      for (final cls in _teacherClasses)
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cls, overflow: TextOverflow.ellipsis),
              const SizedBox(width: 4),
              _CountBadge(count: _examCountByClass[cls] ?? 0),
            ],
          ),
        ),
    ];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            title: const Text(
              'Exams',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            actions: [
              // Filter button with active-filter badge
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: Colors.white),
                      tooltip: 'Filter',
                      onPressed: _openFilterSheet,
                    ),
                    if (_filterSubject != null || _filterPeriod != 'All' || _filterTitle != null || _filterStatus != 'All')
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Class filter strip
                  SizedBox(
                    height: 42,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      tabAlignment: TabAlignment.start,
                      tabs: tabs,
                    ),
                  ),
                  // Upcoming / Past sub-row
                  _UpcomingPastRow(
                    upcomingCount: _upcoming.length,
                    pastCount: _past.length,
                  ),
                ],
              ),
            ),
          ),
        ],
        body: _ExamTabContent(
          upcoming: _upcoming,
          past: _past,
          isDark: isDark,
          onTap: _openResults,
          onEdit: (e) => _showForm(exam: e),
          onDelete: _delete,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Exam',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  void _delete(Exam exam) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Delete "${exam.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await dbService.deleteExam(exam.id);
              if (context.mounted) nav.pop();
              _load();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet() {
    // Local copies so the sheet can preview before applying
    String tempPeriod = _filterPeriod;
    String? tempSubject = _filterSubject;
    String? tempTitle = _filterTitle;
    String tempStatus = _filterStatus;

    // Predefined title keywords teachers commonly use
    const titleKeywords = [
      'Weekly',
      'Monthly',
      'Chapter',
      'Unit',
      'Mid-Term',
      'Final',
      'Quiz',
      'Revision',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final subjects = _availableSubjects;
          final activeCount = (tempPeriod != 'All' ? 1 : 0) +
              (tempSubject != null ? 1 : 0) +
              (tempTitle != null ? 1 : 0) +
              (tempStatus != 'All' ? 1 : 0);

          final screenHeight = MediaQuery.of(context).size.height;
          return SizedBox(
            height: screenHeight * 0.8,
            child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              top: 20,
              left: 24,
              right: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header row
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: Color(0xFF2563EB), size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Filter Exams',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      if (activeCount > 0)
                        TextButton(
                          onPressed: () {
                            setSheet(() {
                              tempPeriod = 'All';
                              tempSubject = null;
                              tempTitle = null;
                              tempStatus = 'All';
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.close_rounded, size: 14),
                              const SizedBox(width: 4),
                              Text('Clear ($activeCount)',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Exam Type (title keyword) ────────────────────────
                  _SheetSectionLabel(
                      icon: Icons.label_rounded, label: 'Exam Type'),
                  const SizedBox(height: 4),
                  Text(
                    'Filter by keyword found in the exam title',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: titleKeywords.map((kw) {
                      final isSelected = tempTitle == kw;
                      return GestureDetector(
                        onTap: () => setSheet(
                          () => tempTitle = isSelected ? null : kw,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF2563EB).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _titleKeywordIcon(kw),
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                kw,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // ── Status ──────────────────────────────────────────
                  const SizedBox(height: 24),
                  _SheetSectionLabel(
                      icon: Icons.filter_list_rounded, label: 'Status'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statusTile(
                        icon: Icons.select_all_rounded,
                        label: 'All',
                        color: const Color(0xFF2563EB),
                        selected: tempStatus == 'All',
                        onTap: () => setSheet(() => tempStatus = 'All'),
                      ),
                      const SizedBox(width: 10),
                      _statusTile(
                        icon: Icons.upcoming_rounded,
                        label: 'Upcoming',
                        color: const Color(0xFF10B981),
                        selected: tempStatus == 'Upcoming',
                        onTap: () =>
                            setSheet(() => tempStatus = 'Upcoming'),
                      ),
                      const SizedBox(width: 10),
                      _statusTile(
                        icon: Icons.check_circle_rounded,
                        label: 'Completed',
                        color: const Color(0xFF64748B),
                        selected: tempStatus == 'Completed',
                        onTap: () =>
                            setSheet(() => tempStatus = 'Completed'),
                      ),
                    ],
                  ),

                  // ── Time Period ──────────────────────────────────────
                  const SizedBox(height: 24),
                  _SheetSectionLabel(
                      icon: Icons.schedule_rounded, label: 'Time Period'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChipTile(
                        ctx,
                        icon: Icons.all_inclusive_rounded,
                        label: 'All Time',
                        subtitle: 'No date restriction',
                        selected: tempPeriod == 'All',
                        onTap: () => setSheet(() => tempPeriod = 'All'),
                      ),
                      _filterChipTile(
                        ctx,
                        icon: Icons.view_week_rounded,
                        label: 'This Week',
                        subtitle: 'Mon – Sun',
                        selected: tempPeriod == 'This Week',
                        onTap: () =>
                            setSheet(() => tempPeriod = 'This Week'),
                      ),
                      _filterChipTile(
                        ctx,
                        icon: Icons.calendar_month_rounded,
                        label: 'This Month',
                        subtitle: _currentMonthLabel(),
                        selected: tempPeriod == 'This Month',
                        onTap: () =>
                            setSheet(() => tempPeriod = 'This Month'),
                      ),
                    ],
                  ),

                  // ── Subject ─────────────────────────────────────────
                  if (subjects.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SheetSectionLabel(
                        icon: Icons.menu_book_rounded, label: 'Subject'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _subjectChip(
                          ctx,
                          label: 'All Subjects',
                          selected: tempSubject == null,
                          onTap: () => setSheet(() => tempSubject = null),
                        ),
                        ...subjects.map(
                          (s) => _subjectChip(
                            ctx,
                            label: s,
                            selected: tempSubject == s,
                            onTap: () => setSheet(() =>
                                tempSubject = tempSubject == s ? null : s),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filterPeriod = tempPeriod;
                          _filterSubject = tempSubject;
                          _filterTitle = tempTitle;
                          _filterStatus = tempStatus;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        activeCount == 0
                            ? 'Show All Exams'
                            : 'Apply $activeCount Filter${activeCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
        },
      ),
    );
  }

  Widget _statusTile({
    required IconData icon,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22, color: selected ? Colors.white : color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _titleKeywordIcon(String kw) {
    switch (kw) {
      case 'Weekly':
        return Icons.view_week_rounded;
      case 'Monthly':
        return Icons.calendar_month_rounded;
      case 'Chapter':
        return Icons.bookmark_rounded;
      case 'Unit':
        return Icons.layers_rounded;
      case 'Mid-Term':
        return Icons.av_timer_rounded;
      case 'Final':
        return Icons.flag_rounded;
      case 'Quiz':
        return Icons.quiz_rounded;
      case 'Revision':
        return Icons.refresh_rounded;
      default:
        return Icons.label_rounded;
    }
  }

  /// Large selectable tile for period options
  Widget _filterChipTile(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: (MediaQuery.of(context).size.width - 64) / 3,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : const Color(0xFF2563EB).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color:
                    selected ? Colors.white : const Color(0xFF2563EB)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white70
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pill chip for subjects
  Widget _subjectChip(
    BuildContext ctx, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : const Color(0xFF2563EB).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
                selected ? Colors.white : const Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }

  String _currentMonthLabel() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[DateTime.now().month - 1];
  }

  void _openResults(Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExamResultsScreen(exam: exam)),
    );
  }

  void _showForm({Exam? exam}) {
    final titleCtrl = TextEditingController(text: exam?.title);
    String selectedSubject =
        exam?.subject ?? widget.teacher.subject ?? (_subjects.isNotEmpty ? _subjects.first.name : '');
    String selectedClass =
        exam?.className ?? _activeClass ?? _teacherClasses.firstOrNull ?? '';
    final marksCtrl = TextEditingController(
      text: exam?.totalMarks.toString() ?? '100',
    );
    final descCtrl = TextEditingController(text: exam?.description);
    DateTime selectedDate =
        exam?.date ?? DateTime.now().add(const Duration(days: 1));
    String startTime = exam?.startTime ?? '09:00 AM';
    String endTime = exam?.endTime ?? '11:00 AM';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    exam == null ? 'Schedule Exam' : 'Edit Exam',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Exam Title',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedSubject.isEmpty ? null : selectedSubject,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            prefixIcon: Icon(Icons.menu_book_rounded),
                          ),
                          items: _subjects
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.name,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheet(() => selectedSubject = v ?? ''),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedClass.isEmpty ? null : selectedClass,
                          decoration: const InputDecoration(
                            labelText: 'Class',
                            prefixIcon: Icon(Icons.school_rounded),
                          ),
                          items: (_teacherClasses.isNotEmpty
                                  ? _allClasses
                                      .where((c) =>
                                          _teacherClasses.contains(c.name))
                                      .toList()
                                  : _allClasses)
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.name,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheet(() => selectedClass = v ?? ''),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: marksCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Marks',
                      prefixIcon: Icon(Icons.grade_rounded),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null) return 'Enter valid number';
                      if (n <= 0) return 'Must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setSheet(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _timePicker(
                          ctx,
                          'Start Time',
                          startTime,
                          (t) => setSheet(() => startTime = t),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timePicker(
                          ctx,
                          'End Time',
                          endTime,
                          (t) => setSheet(() => endTime = t),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final e = Exam(
                        id: exam?.id ??
                            DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                        title: titleCtrl.text.trim(),
                        subject: selectedSubject,
                        className: selectedClass,
                        date: selectedDate,
                        startTime: startTime,
                        endTime: endTime,
                        totalMarks: double.parse(marksCtrl.text),
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                      );
                      if (exam == null) {
                        await dbService.insertExam(e);
                      } else {
                        await dbService.updateExam(e);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      exam == null ? 'Schedule Exam' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      titleCtrl.dispose();
      marksCtrl.dispose();
      descCtrl.dispose();
    });
  }

  Widget _timePicker(
    BuildContext ctx,
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final parts = value.split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        if (parts[1] == 'PM' && hour != 12) hour += 12;
        if (parts[1] == 'AM' && hour == 12) hour = 0;

        final picked = await showTimePicker(
          context: ctx,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
        if (picked != null) {
          final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
          final m = picked.minute.toString().padLeft(2, '0');
          final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
          onChanged('$h:$m $period');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter sheet section label ───────────────────────────────────────────────

class _SheetSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SheetSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Small badge showing a count ─────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Upcoming / Past summary row ─────────────────────────────────────────────

class _UpcomingPastRow extends StatelessWidget {
  final int upcomingCount;
  final int pastCount;
  const _UpcomingPastRow(
      {required this.upcomingCount, required this.pastCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _pill(Icons.schedule_rounded, '$upcomingCount Upcoming',
              const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _pill(Icons.check_circle_outline_rounded, '$pastCount Completed',
              Colors.white54),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) => Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
}

// ─── Exam tab content (upcoming + past sections in one scroll) ────────────────

class _ExamTabContent extends StatelessWidget {
  final List<Exam> upcoming;
  final List<Exam> past;
  final bool isDark;
  final Function(Exam) onTap;
  final Function(Exam) onEdit;
  final Function(Exam) onDelete;

  const _ExamTabContent({
    required this.upcoming,
    required this.past,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (upcoming.isEmpty && past.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'No exams yet',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (upcoming.isNotEmpty) ...[
          _sectionHeader(Icons.schedule_rounded, 'Upcoming', const Color(0xFF10B981)),
          const SizedBox(height: 10),
          ...upcoming.map((e) => _ExamCard(
                exam: e,
                isDark: isDark,
                onTap: onTap,
                onEdit: onEdit,
                onDelete: onDelete,
              )),
          const SizedBox(height: 8),
        ],
        if (past.isNotEmpty) ...[
          _sectionHeader(Icons.check_circle_outline_rounded, 'Completed',
              const Color(0xFF64748B)),
          const SizedBox(height: 10),
          ...past.map((e) => _ExamCard(
                exam: e,
                isDark: isDark,
                onTap: onTap,
                onEdit: onEdit,
                onDelete: onDelete,
              )),
        ],
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String label, Color color) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
}

// ─── Exam Card ────────────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final bool isDark;
  final Function(Exam) onTap;
  final Function(Exam) onEdit;
  final Function(Exam) onDelete;

  const _ExamCard({
    required this.exam,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isUpcoming = exam.endDateTime.isAfter(now);
    final daysLeft = exam.date.difference(now).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: isUpcoming
                        ? const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF0D9488)],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${exam.date.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1,
                        ),
                      ),
                      Text(
                        _monthShort(exam.date.month),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              exam.subject,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          // Class chip — highlighted for quick scanning
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exam.className,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _chip(
                            Icons.access_time_rounded,
                            '${exam.startTime} - ${exam.endTime}',
                            const Color(0xFF0EA5E9),
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            Icons.grade_rounded,
                            '${exam.totalMarks.toInt()} marks',
                            const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isUpcoming)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: daysLeft <= 3
                              ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                              : const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          daysLeft == 0
                              ? 'Today'
                              : daysLeft == 1
                                  ? 'Tomorrow'
                                  : '$daysLeft days',
                          style: TextStyle(
                            color: daysLeft <= 3
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (isUpcoming) ...[
                          GestureDetector(
                            onTap: () => onEdit(exam),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Color(0xFF0D9488),
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        GestureDetector(
                          onTap: () => onDelete(exam),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isUpcoming)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => onTap(exam),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text(
                    'Enter / View Marks',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    backgroundColor:
                        const Color(0xFF2563EB).withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  String _monthShort(int month) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];
}

// ─── Exam Results Screen ──────────────────────────────────────────────────────

class ExamResultsScreen extends StatefulWidget {
  final Exam exam;
  const ExamResultsScreen({super.key, required this.exam});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  List<ExamResult> _results = [];
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      var results = await dbService.getExamResults(widget.exam.id);
      if (results.isEmpty) {
        final students =
            await dbService.getStudentsByClass(widget.exam.className);
        results = students
            .map(
              (s) => ExamResult(
                id: '${widget.exam.id}_${s.id}',
                examId: widget.exam.id,
                studentId: s.id,
                studentName: s.name,
                totalMarks: widget.exam.totalMarks,
              ),
            )
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load results: $e');
    }
  }

  Future<void> _save() async {
    try {
      await dbService.saveExamResults(_results);
      if (!mounted) return;
      setState(() => _isEditing = false);
      showSuccessSnackBar(context, 'Results saved');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to save results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passed =
        _results.where((r) => r.marksObtained != null && r.grade != 'F').length;
    final avg = _results.isEmpty
        ? 0.0
        : _results
                  .where((r) => r.marksObtained != null)
                  .fold(0.0, (s, r) => s + r.marksObtained!) /
              (_results
                  .where((r) => r.marksObtained != null)
                  .length
                  .clamp(1, 999));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exam.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              '${widget.exam.className} · ${widget.exam.subject}',
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Save',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          else if (!widget.exam.endDateTime.isAfter(DateTime.now()))
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Enter marks',
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Not yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.1),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              itemCount: 6,
              itemBuilder: (_, i) => _buildResultSkeleton(isDark),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('Total', '${_results.length}',
                          Icons.people_rounded),
                      _stat('Passed', '$passed',
                          Icons.check_circle_rounded),
                      _stat('Avg', avg.toStringAsFixed(1),
                          Icons.bar_chart_rounded),
                      _stat('Marks',
                          '${widget.exam.totalMarks.toInt()}',
                          Icons.grade_rounded),
                    ],
                  ),
                ),
                Expanded(
                  child: _results.isEmpty
                      ? const Center(
                          child: Text('No students found',
                              style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final r = _results[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF141E30)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFE8EDF5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        r.studentName[0],
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (!_isEditing &&
                                            r.marksObtained != null)
                                          Text(
                                            '${r.marksObtained!.toInt()} / ${r.totalMarks.toInt()}',
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFF64748B)
                                                  : const Color(0xFF94A3B8),
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (_isEditing)
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        initialValue:
                                            r.marksObtained?.toString() ?? '',
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText:
                                              '/ ${r.totalMarks.toInt()}',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                          isDense: true,
                                        ),
                                        onChanged: (v) {
                                          var val = double.tryParse(v);
                                          if (val != null) {
                                            if (val < 0) val = 0;
                                            if (val > r.totalMarks) {
                                              val = r.totalMarks;
                                            }
                                          }
                                          setState(
                                            () => _results[i] = ExamResult(
                                              id: r.id,
                                              examId: r.examId,
                                              studentId: r.studentId,
                                              studentName: r.studentName,
                                              totalMarks: r.totalMarks,
                                              marksObtained: val,
                                              remarks: r.remarks,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: r.gradeColor.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        r.grade,
                                        style: TextStyle(
                                          color: r.gradeColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      );

  Widget _buildResultSkeleton(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 40, height: 40, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 130, height: 13),
                SizedBox(height: 6),
                ShimmerBox(width: 70, height: 10),
              ],
            ),
          ),
          const ShimmerBox(width: 48, height: 16),
        ],
      ),
    );
  }
}
