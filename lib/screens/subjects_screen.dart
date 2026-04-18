import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen>
    with SingleTickerProviderStateMixin {
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  static const List<String> _colorOptions = [
    'FF6366F1', 'FF8B5CF6', 'FF10B981', 'FFF59E0B',
    'FFEF4444', 'FF3B82F6', 'FFEC4899', 'FF14B8A6',
    'FF0EA5E9', 'FFF97316',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimations = List.generate(
      20,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (i * 0.06).clamp(0.0, 0.8),
            (0.3 + i * 0.06).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    _loadSubjects();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await dbService.getSubjects();
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  Color _hexToColor(String hex) => Color(int.parse(hex, radix: 16));

  void _showAddSubjectSheet() {
    final nameController = TextEditingController();
    String selectedColor = _colorOptions[0];

    showAppBottomSheet(
      context: context,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            const Text(
              'New Subject',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'e.g., Mathematics',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose Color',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colorOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final hex = _colorOptions[i];
                    final isSelected = selectedColor == hex;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedColor = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hexToColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        _hexToColor(hex).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    if (_subjects
                        .any((s) => s.name.toLowerCase() == name.toLowerCase())) {
                      showInfoSnackBar(context, 'Subject already exists.');
                      return;
                    }
                    final subject = SubjectModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      colorHex: selectedColor,
                    );
                    await dbService.insertSubject(subject);
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadSubjects();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Subject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _confirmDelete(SubjectModel subject) async {
    await showConfirmDeleteDialog(
      context: context,
      title: 'Delete Subject',
      message: 'Remove "${subject.name}" from subjects? This cannot be undone.',
      onConfirm: () async {
        await dbService.deleteSubject(subject.id);
        await _loadSubjects();
      },
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
            pinned: true,
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
              title: Text(
                '${_subjects.length} Subjects',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 20),
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
                    child: Icon(Icons.menu_book_rounded, color: Colors.white.withValues(alpha: 0.08), size: 130),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_subjects.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 52,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No subjects yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to add your first subject',
                      style: TextStyle(color: Colors.grey),
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
                  final subject = _subjects[index];
                  final color = _hexToColor(subject.colorHex);
                  final anim = _fadeAnimations[index % 20];

                  return FadeTransition(
                    opacity: anim,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF141E30)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFE8EDF5),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 6),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: color,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          subject.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Subject',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _confirmDelete(subject),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: _subjects.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubjectSheet,
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Subject',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
