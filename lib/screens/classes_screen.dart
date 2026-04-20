import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/shimmer_box.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen>
    with SingleTickerProviderStateMixin {
  List<ClassModel> _classes = [];
  Map<String, int> _studentCounts = {};
  Map<String, List<Map<String, dynamic>>> _teachersPerClass = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimations = List.generate(
      10,
      (i) => Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(i * 0.05, 0.4 + i * 0.05, curve: Curves.easeOutCubic),
        ),
      ),
    );
    _fadeAnimations = List.generate(
      10,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(i * 0.05, 0.3 + i * 0.05, curve: Curves.easeOut),
        ),
      ),
    );
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        dbService.getClasses(),
        dbService.getStudentCountPerClass(),
        dbService.getTeachersPerClass(),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = results[0] as List<ClassModel>;
        _studentCounts = results[1] as Map<String, int>;
        _teachersPerClass = results[2] as Map<String, List<Map<String, dynamic>>>;
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

  void _showAddClassSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final teacherController = TextEditingController();
    final roomController = TextEditingController();

    showAppBottomSheet(
      context: context,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 24),
            const Text('New Academic Class', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: teacherController,
              decoration: const InputDecoration(
                labelText: 'Teacher Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: 'Room No.',
                prefixIcon: Icon(Icons.room_outlined),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final cls = ClassModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    teacherName: teacherController.text,
                    studentCount: 0,
                    roomNumber: roomController.text,
                  );
                  final nav = Navigator.of(context);
                  await dbService.insertClass(cls);
                  if (context.mounted) nav.pop();
                  await _loadClasses();
                }
              },
              child: const Text('Create Class'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).whenComplete(() {
      nameController.dispose();
      teacherController.dispose();
      roomController.dispose();
    });
  }

  void _deleteClass(ClassModel cls) {
    showConfirmDeleteDialog(
      context: context,
      title: 'Delete Class?',
      message: 'Remove ${cls.name}?',
      onConfirm: () async {
        await dbService.deleteClass(cls.id);
        if (mounted) await _loadClasses();
      },
    );
  }

  Widget _buildClassSkeleton(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 52, height: 52, borderRadius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 120, height: 15, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 80, height: 11, borderRadius: 4),
                  ],
                ),
              ),
              const ShimmerBox(width: 90, height: 24, borderRadius: 999),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              ShimmerBox(width: 34, height: 34, borderRadius: 10),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        ShimmerBox(width: 60, height: 20, borderRadius: 999),
                        SizedBox(width: 5),
                        ShimmerBox(width: 72, height: 20, borderRadius: 999),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
              title: const Text(
                'Classes',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 20),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(Icons.school_rounded, color: Colors.white.withValues(alpha: 0.08), size: 130),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_classes.length} Active Classes',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${_studentCounts.values.fold(0, (sum, c) => sum + c)} total students',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildClassSkeleton(isDark),
                  childCount: 4,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final classData = _classes[index];
                    final animIdx = index < 10 ? index : 9;
                    return FadeTransition(
                      opacity: _fadeAnimations[animIdx],
                      child: SlideTransition(
                        position: _slideAnimations[animIdx],
                        child: _ClassCard(
                          classData: classData,
                          isDark: isDark,
                          studentCount: _studentCounts[classData.name] ?? 0,
                          teachers: _teachersPerClass[classData.name] ?? [],
                          onDelete: () => _deleteClass(classData),
                        ),
                      ),
                    );
                  },
                  childCount: _classes.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Class'),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classData,
    required this.isDark,
    required this.studentCount,
    required this.teachers,
    required this.onDelete,
  });

  final ClassModel classData;
  final bool isDark;
  final int studentCount;
  final List<Map<String, dynamic>> teachers;
  final VoidCallback onDelete;

  static const _accent = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.school_rounded, color: _accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(classData.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      if (classData.roomNumber.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.room_outlined,
                                size: 13,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              'Room ${classData.roomNumber}',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.groups_rounded,
                              size: 13, color: _accent),
                          const SizedBox(width: 5),
                          Text(
                            '$studentCount student${studentCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8EDF5),
          ),
          if (teachers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 15,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  const SizedBox(width: 8),
                  Text(
                    'No teachers assigned yet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded,
                          size: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        'TEACHERS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...teachers.map((t) => _TeacherRow(teacher: t, isDark: isDark)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherRow extends StatelessWidget {
  const _TeacherRow({required this.teacher, required this.isDark});

  final Map<String, dynamic> teacher;
  final bool isDark;

  static const List<Color> _subjectColors = [
    Color(0xFF0EA5E9), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEC4899), Color(0xFF3B82F6), Color(0xFF14B8A6),
    Color(0xFF0284C7), Color(0xFFEF4444),
  ];

  Color _colorFor(String subject) =>
      _subjectColors[subject.hashCode.abs() % _subjectColors.length];

  @override
  Widget build(BuildContext context) {
    final name = teacher['name'] as String;
    final subjects = (teacher['subjects'] as List).cast<String>();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (subjects.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: subjects.map((s) {
                      final c = _colorFor(s);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: c.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 12, color: c),
                            const SizedBox(width: 4),
                            Text(
                              s,
                              style: TextStyle(
                                color: c,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'No subjects assigned',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
