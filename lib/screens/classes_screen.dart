import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/database_service.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen>
    with SingleTickerProviderStateMixin {
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnimations = List.generate(10, (i) => Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Interval(i * 0.05, 0.4 + i * 0.05, curve: Curves.easeOutCubic)),
    ));
    _fadeAnimations = List.generate(10, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Interval(i * 0.05, 0.3 + i * 0.05, curve: Curves.easeOut)),
    ));
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final classes = await dbService.getClasses();
    setState(() {
      _classes = classes;
      _isLoading = false;
    });
    _animationController.forward(from: 0);
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
    final countController = TextEditingController();
    final roomController = TextEditingController();
    final subjectController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                const Text('New Academic Class', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Class Name', prefixIcon: Icon(Icons.class_outlined)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: teacherController, decoration: const InputDecoration(labelText: 'Teacher Name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: subjectController, decoration: const InputDecoration(labelText: 'Default Subject', prefixIcon: Icon(Icons.book_outlined))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: countController, decoration: const InputDecoration(labelText: 'Max Students', prefixIcon: Icon(Icons.people_outline)), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: roomController, decoration: const InputDecoration(labelText: 'Room No.', prefixIcon: Icon(Icons.room_outlined)))),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final cls = ClassModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        teacherName: teacherController.text,
                        studentCount: int.tryParse(countController.text) ?? 0,
                        roomNumber: roomController.text,
                        subject: subjectController.text.isEmpty ? null : subjectController.text,
                      );
                      await dbService.insertClass(cls);
                      if (context.mounted) Navigator.pop(context);
                      await _loadClasses();
                    }
                  },
                  child: const Text('Create Class'),
                ),
                const SizedBox(height: 24),
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
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Classes', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF059669), Color(0xFF10B981)])),
                child: Center(child: Icon(Icons.school_rounded, color: Colors.white.withOpacity(0.12), size: 120)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF059669), Color(0xFF10B981)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.school_rounded, color: Colors.white, size: 24)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_classes.length} Active Classes', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('${_classes.fold(0, (sum, c) => sum + c.studentCount)} total students', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
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
                        child: _ClassCard(classData: classData, isDark: isDark, onDelete: () => _deleteClass(classData)),
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

  void _deleteClass(ClassModel cls) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class?'),
        content: Text('Remove ${cls.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await dbService.deleteClass(cls.id);
              if (context.mounted) Navigator.pop(context);
              await _loadClasses();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassModel classData;
  final bool isDark;
  final VoidCallback onDelete;

  const _ClassCard({required this.classData, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2))), child: const Icon(Icons.school_rounded, color: Color(0xFF10B981), size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(classData.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(classData.roomNumber, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('${classData.studentCount} Students', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 12))),
                    const SizedBox(height: 8),
                    GestureDetector(onTap: onDelete, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.person_outline, size: 18, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text(classData.teacherName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
                if (classData.subject != null)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(classData.subject!, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w700, fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
