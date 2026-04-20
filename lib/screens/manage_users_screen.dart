import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/shimmer_box.dart';

enum ManageUsersViewMode { admin, teacher }

class ManageUsersScreen extends StatefulWidget {
  final ManageUsersViewMode viewMode;
  const ManageUsersScreen({
    super.key,
    this.viewMode = ManageUsersViewMode.admin,
  });

  // Keep backward compat for any remaining isTeacherView usages
  bool get isTeacherView => viewMode == ManageUsersViewMode.teacher;

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  late List<String> _filters;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClass;
  List<String> _availableClasses = [];
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _filters = widget.viewMode == ManageUsersViewMode.teacher
        ? ['All', 'Student', 'Parent']
        : ['All', 'Admin', 'Teacher', 'Student', 'Parent'];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimations = List.generate(
      10,
      (i) =>
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                i * 0.05,
                0.4 + i * 0.05,
                curve: Curves.easeOutCubic,
              ),
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
    _loadUsers();
  }

  List<UserRole> _allowedRoles() {
    switch (widget.viewMode) {
      case ManageUsersViewMode.teacher:
        return [UserRole.student, UserRole.parent];
      case ManageUsersViewMode.admin:
        final isOwner =
            authService.currentUser?.primaryRole == UserRole.owner;
        if (isOwner) {
          return [UserRole.owner, UserRole.principal, UserRole.teacher, UserRole.student, UserRole.parent];
        }
        return [UserRole.teacher, UserRole.student, UserRole.parent];
    }
  }

  Widget _buildUserSkeleton(bool isDark) {
    return Container(
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
      child: Row(
        children: [
          const ShimmerBox(width: 48, height: 48, borderRadius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 140, height: 14, borderRadius: 4),
                const SizedBox(height: 6),
                const ShimmerBox(width: 180, height: 11, borderRadius: 4),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    ShimmerBox(width: 70, height: 22, borderRadius: 999),
                    SizedBox(width: 6),
                    ShimmerBox(width: 56, height: 22, borderRadius: 999),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const ShimmerBox(width: 32, height: 32, borderRadius: 10),
        ],
      ),
    );
  }

  IconData _iconForFilter(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return Icons.groups_rounded;
      case 'admin':
        return Icons.shield_outlined;
      case 'teacher':
        return Icons.menu_book_rounded;
      case 'student':
        return Icons.school_rounded;
      case 'parent':
        return Icons.family_restroom_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  int _countForClass(String? className) {
    final filterKey = _selectedFilter.toLowerCase();
    final isTeacherView = widget.viewMode == ManageUsersViewMode.teacher;
    return _users.where((u) {
      final matchesRole = filterKey == 'all'
          ? (!isTeacherView ||
              u.primaryRole == UserRole.student ||
              u.primaryRole == UserRole.parent)
          : filterKey == 'admin'
              ? (u.primaryRole == UserRole.owner ||
                  u.primaryRole == UserRole.principal)
              : u.primaryRole.name.toLowerCase() == filterKey;
      final matchesClass = className == null || u.className == className;
      return matchesRole && matchesClass;
    }).length;
  }

  Widget _buildClassChip({
    required String label,
    required IconData icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    const accent = Color(0xFF0D9488);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? accent
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countForFilter(String filter) {
    final isTeacherView = widget.viewMode == ManageUsersViewMode.teacher;
    final key = filter.toLowerCase();
    if (key == 'all') {
      return isTeacherView
          ? _users
              .where((u) =>
                  u.primaryRole == UserRole.student ||
                  u.primaryRole == UserRole.parent)
              .length
          : _users.length;
    }
    if (key == 'admin') {
      return _users
          .where((u) =>
              u.primaryRole == UserRole.owner ||
              u.primaryRole == UserRole.principal)
          .length;
    }
    return _users.where((u) => u.primaryRole.name == key).length;
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await dbService.getUsers();
    final classes = await dbService.getClasses();
    if (!mounted) return;
    setState(() {
      _users = users;
      _availableClasses = classes.map((c) => c.name).toList()..sort();
      _isLoading = false;
    });
    _animationController.forward(from: 0);
  }

  /// True if this account should have rows in `teacher_classes` (primary or additional Teacher).
  static bool userTeaches(UserRole primary, List<UserRole> additional) {
    return primary == UserRole.teacher || additional.contains(UserRole.teacher);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showUserForm({UserModel? user}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final phoneController = TextEditingController(text: user?.phone);
    final classController = TextEditingController(text: user?.className);
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;
    UserRole selectedRole = user?.primaryRole ?? UserRole.student;
    List<UserRole> selectedAdditionalRoles = List.from(
      user?.additionalRoles ?? [],
    );
    List<String> availableClasses = [];
    List<String> availableSubjects = [];
    final selectedTeacherClasses = <String>[];
    // className → selected subjects for that class
    final classSubjectMap = <String, List<String>>{};
    try {
      final classes = await dbService.getClasses();
      final subjects = await dbService.getSubjects();
      availableClasses = classes.map((c) => c.name).toList();
      availableSubjects = subjects.map((s) => s.name).toList();
      if (user != null && userTeaches(user.primaryRole, user.additionalRoles)) {
        selectedTeacherClasses.addAll(
          await dbService.getTeacherClasses(user.id),
        );
        final existing = await dbService.getTeacherAllClassSubjects(user.id);
        classSubjectMap.addAll(existing);
      }
    } catch (e) {
      debugPrint('Failed to load user form data: $e');
    }

    if (!mounted) return;
    showAppBottomSheet(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 24),
                  Text(
                    user == null
                        ? (widget.viewMode == ManageUsersViewMode.teacher
                              ? 'Add Student'
                              : 'Add New User')
                        : 'Update Details',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (optional for students)',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (v) {
                      // Email is optional for students
                      if (selectedRole == UserRole.student &&
                          (v == null || v.isEmpty)) {
                        return null; // Valid - no email needed for students
                      }
                      // For other roles, email is required and must be valid
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Invalid email format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_iphone_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (user == null)
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: _allowedRoles()
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedRole = value);
                        }
                      },
                    ),
                  if (widget.viewMode == ManageUsersViewMode.admin) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional Roles',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allowedRoles()
                                .where((r) => r != selectedRole)
                                .map((role) {
                              final isOn =
                                  selectedAdditionalRoles.contains(role);
                              return FilterChip(
                                label: Text(role.name.toUpperCase()),
                                selected: isOn,
                                showCheckmark: false,
                                avatar: isOn
                                    ? const Icon(Icons.check_rounded,
                                        size: 16, color: Colors.white)
                                    : null,
                                selectedColor: const Color(0xFF6366F1),
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: isOn
                                      ? Colors.transparent
                                      : const Color(0xFF6366F1)
                                          .withValues(alpha: 0.45),
                                ),
                                labelStyle: TextStyle(
                                  color: isOn
                                      ? Colors.white
                                      : const Color(0xFF6366F1),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onSelected: (selected) {
                                  setSheetState(() {
                                    if (selected) {
                                      selectedAdditionalRoles.add(role);
                                    } else {
                                      selectedAdditionalRoles.remove(role);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (selectedRole == UserRole.student) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: classController.text.isEmpty
                          ? null
                          : classController.text,
                      decoration: const InputDecoration(
                        labelText: 'Class Name',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: availableClasses
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        classController.text = value ?? '';
                        setSheetState(() {});
                      },
                    ),
                  ],
                  if (widget.viewMode == ManageUsersViewMode.admin &&
                      (user == null
                          ? userTeaches(selectedRole, selectedAdditionalRoles)
                          : userTeaches(
                              user.primaryRole,
                              selectedAdditionalRoles,
                            ))) ...[
                    const SizedBox(height: 20),
                    // ── Classes taught ───────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Color(0xFF0D9488), size: 14),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Classes taught',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (availableClasses.isEmpty)
                      Text(
                        'Add classes under Classes first.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableClasses.map((c) {
                          final isOn = selectedTeacherClasses.contains(c);
                          return FilterChip(
                            label: Text(c),
                            selected: isOn,
                            showCheckmark: false,
                            avatar: isOn
                                ? const Icon(Icons.check_rounded,
                                    size: 16, color: Colors.white)
                                : null,
                            selectedColor: const Color(0xFF0D9488),
                            backgroundColor: Colors.transparent,
                            side: BorderSide(
                              color: isOn
                                  ? Colors.transparent
                                  : const Color(0xFF0D9488)
                                      .withValues(alpha: 0.45),
                            ),
                            labelStyle: TextStyle(
                              color: isOn
                                  ? Colors.white
                                  : const Color(0xFF0D9488),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onSelected: (on) {
                              setSheetState(() {
                                if (on) {
                                  selectedTeacherClasses.add(c);
                                  classSubjectMap.putIfAbsent(c, () => []);
                                } else {
                                  selectedTeacherClasses.remove(c);
                                  classSubjectMap.remove(c);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    // ── Subjects per class ───────────────────────────────
                    if (selectedTeacherClasses.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.menu_book_rounded,
                                color: Color(0xFF10B981), size: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Subjects per class',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select which subjects this teacher covers in each class.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      if (availableSubjects.isEmpty)
                        Text(
                          'No subjects in the system yet. Add them under Subjects first.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic),
                        )
                      else
                        ...selectedTeacherClasses.map((cls) {
                          final selected =
                              classSubjectMap[cls] ?? [];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.class_outlined,
                                        size: 14,
                                        color: Color(0xFF10B981)),
                                    const SizedBox(width: 6),
                                    Text(
                                      cls,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: availableSubjects.map((s) {
                                    final isOn = selected.contains(s);
                                    return FilterChip(
                                      label: Text(s),
                                      selected: isOn,
                                      showCheckmark: false,
                                      avatar: isOn
                                          ? const Icon(Icons.check_rounded,
                                              size: 14, color: Colors.white)
                                          : null,
                                      selectedColor: const Color(0xFF10B981),
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(
                                        color: isOn
                                            ? Colors.transparent
                                            : const Color(0xFF10B981)
                                                .withValues(alpha: 0.45),
                                      ),
                                      labelStyle: TextStyle(
                                        color: isOn
                                            ? Colors.white
                                            : const Color(0xFF10B981),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onSelected: (on) {
                                        setSheetState(() {
                                          final list = classSubjectMap
                                              .putIfAbsent(cls, () => []);
                                          if (on) {
                                            list.add(s);
                                          } else {
                                            list.remove(s);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ],
                  if (selectedRole == UserRole.owner ||
                      selectedRole == UserRole.principal ||
                      selectedRole == UserRole.teacher) ...[
                    const SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setPassState) => TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                            onPressed: () => setPassState(
                              () => isPasswordVisible = !isPasswordVisible,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            user == null && (v == null || v.isEmpty)
                            ? 'Password required'
                            : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        try {
                        if (user == null) {
                          // Generate email for students if not provided
                          final email =
                              emailController.text.isEmpty &&
                                  selectedRole == UserRole.student
                              ? 'student_${DateTime.now().millisecondsSinceEpoch}@school.com'
                              : emailController.text;

                          final allSubjects = classSubjectMap.values
                              .expand((s) => s).toSet().toList();
                          final newUser = UserModel(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: nameController.text,
                            email: email,
                            primaryRole: selectedRole,
                            additionalRoles: selectedAdditionalRoles,
                            phone: phoneController.text,
                            className: selectedRole == UserRole.student
                                ? classController.text
                                : null,
                            subject: allSubjects.isNotEmpty
                                ? allSubjects.first
                                : null,
                          );
                          await dbService.insertUser(newUser);
                          await dbService.writeAudit(
                            actor: authService.currentUser,
                            action: 'user.create',
                            targetType: 'user',
                            targetId: newUser.id,
                            metadata: {
                              'name': newUser.name,
                              'role': newUser.primaryRole.name,
                            },
                          );
                          if (userTeaches(
                            selectedRole,
                            selectedAdditionalRoles,
                          )) {
                            await dbService.saveTeacherClasses(
                              newUser.id,
                              List<String>.from(selectedTeacherClasses),
                            );
                            for (final entry in classSubjectMap.entries) {
                              await dbService.saveTeacherClassSubjects(
                                newUser.id,
                                entry.key,
                                List<String>.from(entry.value),
                              );
                            }
                          }

                          // If this is the first user being created, they might be the current user
                          // (happens during initial setup when no users exist yet)
                          if (authService.currentUser == null) {
                            await authService.refreshCurrentUser();
                          }
                        } else {
                          final allSubjects = classSubjectMap.values
                              .expand((s) => s)
                              .toSet()
                              .toList();
                          final updated = user.copyWith(
                            name: nameController.text,
                            email: emailController.text,
                            phone: phoneController.text,
                            additionalRoles: selectedAdditionalRoles,
                            className: user.primaryRole == UserRole.student
                                ? classController.text
                                : null,
                            subject:
                                userTeaches(user.primaryRole, selectedAdditionalRoles) &&
                                allSubjects.isNotEmpty
                                ? allSubjects.first
                                : null,
                          );
                          await dbService.updateUser(updated);
                          await dbService.writeAudit(
                            actor: authService.currentUser,
                            action: 'user.update',
                            targetType: 'user',
                            targetId: updated.id,
                            metadata: {
                              'name': updated.name,
                              'role': updated.primaryRole.name,
                              'additionalRoles':
                                  updated.additionalRoles.map((r) => r.name).toList(),
                            },
                          );
                          if (userTeaches(
                            user.primaryRole,
                            selectedAdditionalRoles,
                          )) {
                            await dbService.saveTeacherClasses(
                              user.id,
                              List<String>.from(selectedTeacherClasses),
                            );
                            for (final entry in classSubjectMap.entries) {
                              await dbService.saveTeacherClassSubjects(
                                user.id,
                                entry.key,
                                List<String>.from(entry.value),
                              );
                            }
                          } else {
                            await dbService.saveTeacherClasses(user.id, []);
                            await dbService.clearTeacherClassSubjects(user.id);
                          }

                          // Refresh current user in auth service if this is the logged-in user
                          if (authService.currentUser?.id == user.id) {
                            await authService.refreshCurrentUser();
                          }
                        }
                        if (context.mounted) Navigator.pop(context);
                        await _loadUsers();
                        } on LastOwnerException catch (e) {
                          if (context.mounted) showErrorSnackBar(context, e.message);
                        }
                      }
                    },
                    child: Text(
                      user == null
                          ? (selectedRole == UserRole.student
                                ? 'Add Student'
                                : 'Create Account')
                          : 'Save Changes',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
        },
      ),
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      classController.dispose();
      passwordController.dispose();
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<UserModel> filteredUsers = _users.where((user) {
      final filterKey = _selectedFilter.toLowerCase();
      final matchesFilter = filterKey == 'all'
          ? (widget.viewMode != ManageUsersViewMode.teacher ||
                user.primaryRole == UserRole.student ||
                user.primaryRole == UserRole.parent)
          : filterKey == 'admin'
              ? (user.primaryRole == UserRole.owner ||
                  user.primaryRole == UserRole.principal)
              : user.primaryRole.name.toLowerCase() == filterKey;
      final matchesSearch =
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesClass = _selectedClass == null ||
          user.className == _selectedClass;
      return matchesFilter && matchesSearch && matchesClass;
    }).toList();

    // Show class filter when students are visible
    final showClassFilter = _availableClasses.isNotEmpty &&
        (_selectedFilter.toLowerCase() == 'all' ||
            _selectedFilter.toLowerCase() == 'student');

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.viewMode == ManageUsersViewMode.teacher
                    ? 'Students'
                    : 'User Management',
                style: const TextStyle(
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
                    colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white.withValues(alpha: 0.12),
                    size: 120,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.white,
                ),
                onPressed: () => setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                }),
              ),
            ],
          ),
          if (_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  final count = _countForFilter(filter);
                  final icon = _iconForFilter(filter);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedFilter = filter;
                        // Clear class filter when switching to a non-student role
                        if (filter.toLowerCase() != 'all' &&
                            filter.toLowerCase() != 'student') {
                          _selectedClass = null;
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0D9488)
                              : (isDark
                                    ? const Color(0xFF141E30)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0D9488)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : const Color(0xFFE8EDF5)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8)),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : const Color(0xFF0D9488)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$count',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF0D9488),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (showClassFilter)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.class_outlined,
                            size: 14,
                            color: Color(0xFF0D9488),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Filter by Class',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildClassChip(
                            label: 'All Classes',
                            icon: Icons.apps_rounded,
                            count: _countForClass(null),
                            isSelected: _selectedClass == null,
                            onTap: () =>
                                setState(() => _selectedClass = null),
                            isDark: isDark,
                          ),
                          ..._availableClasses.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildClassChip(
                                label: c,
                                icon: Icons.class_outlined,
                                count: _countForClass(c),
                                isSelected: _selectedClass == c,
                                onTap: () => setState(
                                  () => _selectedClass =
                                      _selectedClass == c ? null : c,
                                ),
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildUserSkeleton(isDark),
                  ),
                  childCount: 6,
                ),
              ),
            )
          else if (filteredUsers.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_search_rounded,
                        size: 48,
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No users found',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final user = filteredUsers[index];
                  final animIdx = index < 10 ? index : 9;
                  return FadeTransition(
                    opacity: _fadeAnimations[animIdx],
                    child: SlideTransition(
                      position: _slideAnimations[animIdx],
                      child: _UserCard(
                        user: user,
                        onEdit: _canManageTarget(user)
                            ? () => _showUserForm(user: user)
                            : null,
                        onDelete: _canManageTarget(user)
                            ? () => _showDeleteConfirmation(user)
                            : null,
                      ),
                    ),
                  );
                }, childCount: filteredUsers.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          widget.viewMode == ManageUsersViewMode.teacher
              ? 'Add Student'
              : 'Add User',
        ),
      ),
    );
  }

  bool _canManageTarget(UserModel target) {
    final me = authService.currentUser?.primaryRole;
    if (me == UserRole.owner) return true;
    if (me == UserRole.principal) {
      return target.primaryRole != UserRole.owner &&
          target.primaryRole != UserRole.principal;
    }
    return false;
  }

  void _showDeleteConfirmation(UserModel user) {
    showConfirmDeleteDialog(
      context: context,
      title: 'Confirm Delete',
      message: 'Are you sure you want to remove ${user.name}?',
      onConfirm: () async {
        try {
          await dbService.deleteUser(user.id);
          await dbService.writeAudit(
            actor: authService.currentUser,
            action: 'user.delete',
            targetType: 'user',
            targetId: user.id,
            metadata: {
              'name': user.name,
              'role': user.primaryRole.name,
            },
          );
          await _loadUsers();
        } on LastOwnerException catch (e) {
          if (mounted) showErrorSnackBar(context, e.message);
        }
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return const Color(0xFF7C3AED);
      case UserRole.principal:
        return const Color(0xFF0D9488);
      case UserRole.teacher:
        return const Color(0xFF10B981);
      case UserRole.student:
        return const Color(0xFFF59E0B);
      case UserRole.parent:
        return const Color(0xFFEC4899);
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.verified_user_rounded;
      case UserRole.principal:
        return Icons.shield_rounded;
      case UserRole.teacher:
        return Icons.menu_book_rounded;
      case UserRole.student:
        return Icons.school_rounded;
      case UserRole.parent:
        return Icons.family_restroom_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = _getRoleColor(user.primaryRole);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: roleColor.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                user.name[0],
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
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
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (!user.email.startsWith('student_') && user.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRoleIcon(user.primaryRole),
                            size: 13,
                            color: roleColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user.primaryRole.name.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user.additionalRoles.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      ...user.additionalRoles.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(r).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _getRoleColor(r).withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRoleIcon(r),
                                  size: 13,
                                  color: _getRoleColor(r),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  r.name.toUpperCase(),
                                  style: TextStyle(
                                    color: _getRoleColor(r),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (user.className != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF0D9488)
                                .withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.class_outlined,
                              size: 13,
                              color: Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              user.className!,
                              style: const TextStyle(
                                color: Color(0xFF0D9488),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (user.subject != null && user.subject!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              user.subject!,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF0D9488),
                      size: 18,
                    ),
                  ),
                ),
              if (onEdit != null && onDelete != null)
                const SizedBox(width: 8),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
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
        ],
      ),
    );
  }
}
