import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/class_model.dart';
import '../models/subject_model.dart';
import '../services/database_service.dart';
import 'dashboard_screen.dart';

class SetupScreen extends StatefulWidget {
  final UserModel user;
  const SetupScreen({super.key, required this.user});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get isOwner => widget.user.primaryRole == UserRole.owner;
  bool get isAdmin =>
      widget.user.primaryRole == UserRole.owner ||
      widget.user.primaryRole == UserRole.principal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: isAdmin
                    ? _buildAdminSetupPages()
                    : _buildTeacherSetupPages(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalPages = isOwner ? 4 : (isAdmin ? 3 : 2);
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: List.generate(totalPages, (index) {
              final isActive = index <= _currentPage;
              final isCompleted = index < _currentPage;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF0D9488)
                            : Colors.grey.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    if (index < totalPages - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index < _currentPage
                              ? const Color(0xFF0D9488)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            _getStepTitle(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    if (isOwner) {
      switch (_currentPage) {
        case 0: return 'Create School';
        case 1: return 'Add Classes';
        case 2: return 'Add Subjects';
        case 3: return 'Add Staff';
        default: return '';
      }
    } else if (isAdmin) {
      switch (_currentPage) {
        case 0: return 'Add Classes';
        case 1: return 'Add Subjects';
        case 2: return 'Add Staff';
        default: return '';
      }
    } else {
      switch (_currentPage) {
        case 0: return 'Your Classes';
        case 1: return 'Add Students';
        default: return '';
      }
    }
  }

  List<Widget> _buildAdminSetupPages() {
    if (isOwner) {
      return [
        _SchoolInfoPage(onContinue: _nextPage),
        _AdminClassesPage(onContinue: _nextPage),
        _AdminSubjectsPage(onContinue: _nextPage),
        _AdminStaffPage(onFinish: _finishSetup),
      ];
    }
    // Principal: skip school creation
    return [
      _AdminClassesPage(onContinue: _nextPage),
      _AdminSubjectsPage(onContinue: _nextPage),
      _AdminStaffPage(onFinish: _finishSetup),
    ];
  }

  List<Widget> _buildTeacherSetupPages() {
    return [
      _TeacherClassesPage(user: widget.user, onContinue: _nextPage),
      _TeacherStudentsPage(user: widget.user, onFinish: _finishSetup),
    ];
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finishSetup() async {
    await dbService.setSetting('setupComplete', 'true');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(user: widget.user),
        ),
      );
    }
  }
}

class _SchoolInfoPage extends StatefulWidget {
  final VoidCallback onContinue;
  const _SchoolInfoPage({required this.onContinue});

  @override
  State<_SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<_SchoolInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Your School',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your school details to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _schoolNameController,
              decoration: const InputDecoration(
                labelText: 'School Name',
                prefixIcon: Icon(Icons.school_rounded),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'School Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAndContinue,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await dbService.saveSchoolInfo({
          'name': _schoolNameController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        });
        widget.onContinue();
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

class _AdminClassesPage extends StatefulWidget {
  final VoidCallback onContinue;
  const _AdminClassesPage({required this.onContinue});

  @override
  State<_AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<_AdminClassesPage> {
  final _classNameController = TextEditingController();
  final List<String> _classes = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add your classes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create the classes for your students',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _classNameController,
                  decoration: const InputDecoration(
                    labelText: 'Class Name',
                    hintText: 'e.g., Class 1-A',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _addClass,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _classes.isEmpty
                ? const Center(
                    child: Text(
                      'No classes added yet.\nEnter a class name above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _classes
                        .map(
                          (c) => Chip(
                            label: Text(
                              c,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFF0D9488),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                            onDeleted: () => setState(() => _classes.remove(c)),
                          ),
                        )
                        .toList(),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _classes.isEmpty || _isLoading
                  ? null
                  : _saveAndContinue,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  void _addClass() {
    final name = _classNameController.text.trim();
    if (name.isNotEmpty && !_classes.contains(name)) {
      setState(() {
        _classes.add(name);
        _classNameController.clear();
      });
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);
    try {
      for (final className in _classes) {
        final newClass = {
          'id': DateTime.now().millisecondsSinceEpoch.toString() + className,
          'name': className,
          'teacherName': '',
          'studentCount': 0,
          'roomNumber': '',
        };
        await dbService.insertClass(ClassModel.fromJson(newClass));
      }
      widget.onContinue();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _AdminStaffPage extends StatefulWidget {
  final VoidCallback onFinish;
  const _AdminStaffPage({required this.onFinish});

  @override
  State<_AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<_AdminStaffPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final List<Map<String, String>> _teachers = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Teachers',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Invite teachers to join your school',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Teacher Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
              prefixIcon: Icon(Icons.book_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addTeacher,
              icon: const Icon(Icons.add),
              label: const Text('Add Teacher'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _teachers.isEmpty
                ? const Center(
                    child: Text(
                      'No teachers added yet.\nYou can skip this step.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _teachers.length,
                    itemBuilder: (context, index) {
                      final t = _teachers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(t['name'] ?? ''),
                        subtitle: Text('${t['subject']} - ${t['email']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _teachers.removeAt(index)),
                        ),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _skipAndFinish,
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndFinish,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Finish'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addTeacher() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    if (name.isNotEmpty && email.isNotEmpty) {
      setState(() {
        _teachers.add({'name': name, 'email': email, 'subject': subject});
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
      });
    }
  }

  Future<void> _saveAndFinish() async {
    setState(() => _isLoading = true);
    try {
      for (final t in _teachers) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final user = UserModel(
          id: id,
          name: t['name']!,
          email: t['email']!,
          primaryRole: UserRole.teacher,
          subject: t['subject'],
        );
        await dbService.insertUser(user);
      }
      widget.onFinish();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skipAndFinish() {
    widget.onFinish();
  }
}

class _TeacherClassesPage extends StatefulWidget {
  final UserModel user;
  final VoidCallback onContinue;
  const _TeacherClassesPage({required this.user, required this.onContinue});

  @override
  State<_TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<_TeacherClassesPage> {
  final List<String> _selectedClasses = [];
  List<String> _availableClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final classes = await dbService.getClasses();
    setState(() {
      _availableClasses = classes.map((c) => c.name).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Classes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the classes you teach',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_availableClasses.isEmpty)
            const Center(
              child: Text(
                'No classes available yet.\nContact your admin to add classes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableClasses.map((c) {
                  final isSelected = _selectedClasses.contains(c);
                  return FilterChip(
                    label: Text(
                      c,
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D9488),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedClasses.add(c);
                        } else {
                          _selectedClasses.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedClasses.isEmpty
                  ? null
                  : () async {
                      await dbService.saveTeacherClasses(
                        widget.user.id,
                        _selectedClasses,
                      );
                      widget.onContinue();
                    },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherStudentsPage extends StatefulWidget {
  final UserModel user;
  final VoidCallback onFinish;
  const _TeacherStudentsPage({required this.user, required this.onFinish});

  @override
  State<_TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<_TeacherStudentsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final List<Map<String, String>> _students = [];
  bool _isLoading = false;
  List<String> _availableClasses = [];
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final classes = await dbService.getClasses();
    setState(() {
      _availableClasses = classes.map((c) => c.name).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Students',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add students to your classes (optional)',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Student Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          if (_availableClasses.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedClass,
              decoration: const InputDecoration(
                labelText: 'Class',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              items: _availableClasses
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedClass = value),
            ),
          if (_availableClasses.isNotEmpty) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addStudent,
              icon: const Icon(Icons.add),
              label: const Text('Add Student'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _students.isEmpty
                ? const Center(
                    child: Text(
                      'No students added yet.\nYou can skip this step.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(s['name'] ?? ''),
                        subtitle: Text(
                          [
                            s['email'],
                            s['class'],
                          ].where((e) => e?.isNotEmpty == true).join(' - '),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _students.removeAt(index)),
                        ),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _skipAndFinish,
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndFinish,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Finish'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addStudent() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _students.add({
          'name': name,
          'email': email,
          'class': _selectedClass ?? '',
        });
        _nameController.clear();
        _emailController.clear();
        _selectedClass = null;
      });
    }
  }

  Future<void> _saveAndFinish() async {
    setState(() => _isLoading = true);
    try {
      for (final s in _students) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final user = UserModel(
          id: id,
          name: s['name']!,
          email: s['email']!.isNotEmpty
              ? s['email']!
              : '${s['name']!.toLowerCase().replaceAll(' ', '.')}@school.com',
          primaryRole: UserRole.student,
          className: s['class']?.isNotEmpty == true ? s['class'] : null,
        );
        await dbService.insertUser(user);
      }
      await dbService.setSetting('teacherSetup_${widget.user.id}', 'true');
      widget.onFinish();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skipAndFinish() async {
    await dbService.setSetting('teacherSetup_${widget.user.id}', 'true');
    widget.onFinish();
  }
}

// ─── ADMIN SUBJECTS PAGE ──────────────────────────────────────────────────────

class _AdminSubjectsPage extends StatefulWidget {
  final VoidCallback onContinue;
  const _AdminSubjectsPage({required this.onContinue});

  @override
  State<_AdminSubjectsPage> createState() => _AdminSubjectsPageState();
}

class _AdminSubjectsPageState extends State<_AdminSubjectsPage> {
  final _subjectNameController = TextEditingController();
  final List<Map<String, String>> _subjects = [];
  bool _isLoading = false;

  static const List<String> _colorOptions = [
    'FF6366F1', 'FF8B5CF6', 'FF10B981', 'FFF59E0B',
    'FFEF4444', 'FF3B82F6', 'FFEC4899', 'FF14B8A6',
  ];
  String _selectedColor = 'FF6366F1';

  @override
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  void _addSubject() {
    final name = _subjectNameController.text.trim();
    if (name.isNotEmpty && !_subjects.any((s) => s['name'] == name)) {
      setState(() {
        _subjects.add({'name': name, 'colorHex': _selectedColor});
        _subjectNameController.clear();
      });
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);
    try {
      for (final s in _subjects) {
        await dbService.insertSubject(SubjectModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_${s['name']}',
          name: s['name']!,
          colorHex: s['colorHex']!,
        ));
      }
      widget.onContinue();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _hexToColor(String hex) =>
      Color(int.parse(hex, radix: 16));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Subjects',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add subjects taught in your school',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _subjectNameController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'e.g., Mathematics',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  onFieldSubmitted: (_) => _addSubject(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _addSubject,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Color picker row
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colorOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final hex = _colorOptions[i];
                final isSelected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(
                              color: _hexToColor(hex).withValues(alpha: 0.5),
                              blurRadius: 8,
                            )]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _subjects.isEmpty
                ? const Center(
                    child: Text(
                      'No subjects added yet.\nEnter a subject name above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subjects.map((s) {
                      final color = _hexToColor(s['colorHex']!);
                      return Chip(
                        label: Text(
                          s['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: color,
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                        onDeleted: () => setState(() => _subjects.remove(s)),
                      );
                    }).toList(),
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : widget.onContinue,
                  child: const Text('Skip'),
                ),
              ),
              if (_subjects.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
