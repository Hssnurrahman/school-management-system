import 'package:flutter/material.dart';
import '../models/homework_model.dart';
import '../models/subject_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/shimmer_box.dart';

class HomeworkScreen extends StatefulWidget {
  final UserModel? teacher;
  const HomeworkScreen({super.key, this.teacher});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen>
    with SingleTickerProviderStateMixin {
  List<Homework> _assignments = [];
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimations = List.generate(
      10,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (i * 0.1).clamp(0, 0.8),
            (0.4 + i * 0.1).clamp(0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final allSubjects = await dbService.getSubjects();
    List<SubjectModel> subjects = allSubjects;
    if (widget.teacher != null) {
      final teacherSubjectNames = await dbService.getTeacherSubjects(widget.teacher!.id);
      if (teacherSubjectNames.isNotEmpty) {
        subjects = allSubjects.where((s) => teacherSubjectNames.contains(s.name)).toList();
      }
    }
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
    });
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    setState(() => _isLoading = true);
    try {
      final hw = await dbService.getHomework();
      if (!mounted) return;
      setState(() {
        _assignments = hw;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return const Color(0xFF0EA5E9);
      case 'history':
        return const Color(0xFFF59E0B);
      case 'physics':
        return const Color(0xFF3B82F6);
      case 'science':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF0284C7);
    }
  }

  bool _isUrgent(DateTime dueDate) =>
      dueDate.difference(DateTime.now()).inDays <= 1;

  void _showAddHomeworkSheet() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final descController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));
    String? selectedClass;

    final classes = await dbService.getClasses();

    if (!mounted) return;
    showAppBottomSheet(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheet) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 20),
              const Text(
                'Add Assignment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: subjectController.text.isEmpty ? null : subjectController.text,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: Icon(Icons.book_rounded),
                    ),
                    items: _subjects
                        .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => subjectController.text = v ?? '',
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      prefixIcon: Icon(Icons.school_rounded),
                    ),
                    items: classes
                        .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setSheet(() => selectedClass = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  // Due date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setSheet(() => dueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF2563EB)),
                          const SizedBox(width: 12),
                          Text(
                            'Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final hw = Homework(
                          subject: subjectController.text,
                          title: titleController.text,
                          dueDate: dueDate,
                          description: descController.text,
                          className: selectedClass,
                        );
                        await dbService.insertHomework(hw);
                        if (context.mounted) Navigator.pop(context);
                        await _loadHomework();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                    child: const Text('Add Assignment'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ).whenComplete(() {
          titleController.dispose();
          subjectController.dispose();
          descController.dispose();
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pending = _assignments.where((a) => !a.isCompleted).length;
    final completed = _assignments.where((a) => a.isCompleted).length;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Homework',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                  ),
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
                              Text(
                                '${_assignments.length} Assignments',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _StatPill(
                              value: '$pending',
                              label: 'Pending',
                              color: const Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 8),
                            _StatPill(
                              value: '$completed',
                              label: 'Done',
                              color: const Color(0xFF34D399),
                            ),
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
            const ShimmerListSkeleton(asSliver: true)
          else if (_assignments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No assignments yet',
                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + Add Task to create one',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _assignments[index];
                  return FadeTransition(
                    opacity: _fadeAnimations[index % 10],
                    child: _HomeworkCard(
                      homework: item,
                      isDark: isDark,
                      subjectColor: _subjectColor(item.subject),
                      isUrgent: _isUrgent(item.dueDate),
                      onTap: () => _showDetails(context, item),
                    ),
                  );
                }, childCount: _assignments.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHomeworkSheet,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Homework homework) {
    final color = _subjectColor(homework.subject);
    showAppBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.assignment_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homework.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        homework.subject,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              homework.description,
              style: const TextStyle(
                height: 1.6,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  'Due: ${homework.dueDate.day}/${homework.dueDate.month}/${homework.dueDate.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () async {
                final updated = homework.copyWith(
                  isCompleted: !homework.isCompleted,
                );
                await dbService.updateHomework(updated);
                if (context.mounted) Navigator.pop(context);
                if (mounted) await _loadHomework();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: homework.isCompleted
                    ? const Color(0xFF64748B)
                    : color,
              ),
              child: Text(
                homework.isCompleted ? 'Mark as Pending' : 'Mark as Completed',
              ),
            ),
          ],
        ),
      );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final Homework homework;
  final bool isDark;
  final Color subjectColor;
  final bool isUrgent;
  final VoidCallback onTap;

  const _HomeworkCard({
    required this.homework,
    required this.isDark,
    required this.subjectColor,
    required this.isUrgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141E30) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: homework.isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : isUrgent
                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                : isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFE8EDF5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: subjectColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                homework.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.pending_actions_rounded,
                color: homework.isCompleted
                    ? const Color(0xFF10B981)
                    : subjectColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    homework.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      decoration: homework.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: homework.isCompleted
                          ? (isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: subjectColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          homework.subject,
                          style: TextStyle(
                            color: subjectColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (homework.className != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            homework.className!,
                            style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700, fontSize: 10),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        'Due ${homework.dueDate.day}/${homework.dueDate.month}',
                        style: TextStyle(
                          color: isUrgent && !homework.isCompleted
                              ? const Color(0xFFEF4444)
                              : isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isUrgent && !homework.isCompleted) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: Color(0xFFEF4444),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
