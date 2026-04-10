import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/database_service.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List<Lesson> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    final lessons = await dbService.getLessons();
    setState(() {
      _lessons = lessons;
      _isLoading = false;
    });
  }

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': return const Color(0xFF6366F1);
      case 'science': return const Color(0xFF10B981);
      case 'history': return const Color(0xFFF59E0B);
      default: return const Color(0xFF3B82F6);
    }
  }

  void _addLesson() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final subjectController = TextEditingController();
    final classController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 20, left: 24, right: 24),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.25), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('New Lesson', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Lesson Title', prefixIcon: Icon(Icons.title_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 14),
                TextFormField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true, prefixIcon: Icon(Icons.description_rounded))),
                const SizedBox(height: 14),
                TextFormField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.book_rounded))),
                const SizedBox(height: 14),
                TextFormField(controller: classController, decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.school_rounded))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final lesson = Lesson(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        description: descController.text,
                        subject: subjectController.text.isEmpty ? 'General' : subjectController.text,
                        className: classController.text.isEmpty ? 'All Classes' : classController.text,
                        teacherName: 'Current Teacher',
                        date: DateTime.now().toIso8601String().split('T')[0],
                      );
                      await dbService.insertLesson(lesson);
                      if (context.mounted) Navigator.pop(context);
                      await _loadLessons();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6)),
                  child: const Text('Add Lesson'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
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
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Lesson Planner', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D9488), Color(0xFF14B8A6)])),
                child: Center(child: Icon(Icons.menu_book_rounded, color: Colors.white.withOpacity(0.12), size: 120)),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _LessonCard(lesson: _lessons[index], isDark: isDark, color: _subjectColor(_lessons[index].subject), onDelete: () => _deleteLesson(_lessons[index])),
                  childCount: _lessons.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addLesson,
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Lesson', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _deleteLesson(Lesson lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson?'),
        content: Text('Remove "${lesson.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await dbService.deleteLesson(lesson.id);
              if (context.mounted) Navigator.pop(context);
              await _loadLessons();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isDark;
  final Color color;
  final VoidCallback onDelete;

  const _LessonCard({required this.lesson, required this.isDark, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.menu_book_rounded, color: color, size: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(lesson.subject, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10))),
                      const SizedBox(width: 6),
                      Text(lesson.className, style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  ],
                ),
              ),
              GestureDetector(onTap: onDelete, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16))),
            ],
          ),
          const SizedBox(height: 12),
          Text(lesson.description, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.5, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8EDF5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(Icons.person_outline_rounded, size: 14, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)), const SizedBox(width: 4), Text(lesson.teacherName, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontWeight: FontWeight.w500))]),
              Row(children: [Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)), const SizedBox(width: 4), Text(lesson.date, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontWeight: FontWeight.w500))]),
            ],
          ),
        ],
      ),
    );
  }
}
