import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/database_service.dart';

class ManageUsersScreen extends StatefulWidget {
  final bool isTeacherView;
  const ManageUsersScreen({super.key, this.isTeacherView = false});

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
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _filters = widget.isTeacherView
        ? ['All', 'Student', 'Parent']
        : ['All', 'Admin', 'Teacher', 'Student', 'Parent'];

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnimations = List.generate(10, (i) => Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Interval(i * 0.05, 0.4 + i * 0.05, curve: Curves.easeOutCubic)),
    ));
    _fadeAnimations = List.generate(10, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Interval(i * 0.05, 0.3 + i * 0.05, curve: Curves.easeOut)),
    ));
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await dbService.getUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showUserForm({UserModel? user}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final phoneController = TextEditingController(text: user?.phone);
    final classController = TextEditingController(text: user?.className);
    final subjectController = TextEditingController(text: user?.subject);
    UserRole selectedRole = user?.role ?? UserRole.student;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
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
                  Text(user == null ? (widget.isTeacherView ? 'Add Student' : 'Add New User') : 'Update Details', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.alternate_email_rounded)), validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_iphone_rounded))),
                  const SizedBox(height: 16),
                  if (user == null)
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge_outlined)),
                      items: (widget.isTeacherView ? [UserRole.student, UserRole.parent] : UserRole.values).map((role) => DropdownMenuItem(value: role, child: Text(role.name.toUpperCase()))).toList(),
                      onChanged: (value) { if (value != null) setSheetState(() => selectedRole = value); },
                    ),
                  if (selectedRole == UserRole.student) ...[
                    const SizedBox(height: 16),
                    TextFormField(controller: classController, decoration: const InputDecoration(labelText: 'Class Name', prefixIcon: Icon(Icons.school_outlined))),
                  ],
                  if (selectedRole == UserRole.teacher && !widget.isTeacherView) ...[
                    const SizedBox(height: 16),
                    TextFormField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.menu_book_rounded))),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        if (user == null) {
                          final newUser = UserModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameController.text,
                            email: emailController.text,
                            role: selectedRole,
                            phone: phoneController.text,
                            className: selectedRole == UserRole.student ? classController.text : null,
                            subject: selectedRole == UserRole.teacher ? subjectController.text : null,
                          );
                          await dbService.insertUser(newUser);
                        } else {
                          final updated = user.copyWith(
                            name: nameController.text,
                            email: emailController.text,
                            phone: phoneController.text,
                            className: user.role == UserRole.student ? classController.text : null,
                            subject: user.role == UserRole.teacher ? subjectController.text : null,
                          );
                          await dbService.updateUser(updated);
                        }
                        if (context.mounted) Navigator.pop(context);
                        await _loadUsers();
                      }
                    },
                    child: Text(user == null ? 'Create Account' : 'Save Changes'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<UserModel> filteredUsers = _users.where((user) {
      if (widget.isTeacherView && user.role != UserRole.student && user.role != UserRole.parent) return false;
      final matchesFilter = _selectedFilter == 'All' || user.role.name.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) || user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.isTeacherView ? 'Students' : 'User Management', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])),
                child: Center(child: Icon(Icons.people_alt_rounded, color: Colors.white.withOpacity(0.12), size: 120)),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: Colors.white),
                onPressed: () => setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) { _searchController.clear(); _searchQuery = ''; }
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
                  decoration: const InputDecoration(hintText: 'Search users...', prefixIcon: Icon(Icons.search_rounded)),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4F46E5) : (isDark ? const Color(0xFF141E30) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5))),
                        ),
                        child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (filteredUsers.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.person_search_rounded, size: 48, color: const Color(0xFF6366F1).withOpacity(0.5))),
                    const SizedBox(height: 20),
                    Text('No users found', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = filteredUsers[index];
                    final animIdx = index < 10 ? index : 9;
                    return FadeTransition(
                      opacity: _fadeAnimations[animIdx],
                      child: SlideTransition(
                        position: _slideAnimations[animIdx],
                        child: _UserCard(
                          user: user,
                          onEdit: () => _showUserForm(user: user),
                          onDelete: () => _showDeleteConfirmation(user),
                        ),
                      ),
                    );
                  },
                  childCount: filteredUsers.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(widget.isTeacherView ? 'Add Student' : 'Add User'),
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to remove ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await dbService.deleteUser(user.id);
              if (context.mounted) Navigator.pop(context);
              await _loadUsers();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.onEdit, required this.onDelete});

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return const Color(0xFF6366F1);
      case UserRole.teacher: return const Color(0xFF10B981);
      case UserRole.student: return const Color(0xFFF59E0B);
      case UserRole.parent: return const Color(0xFFEC4899);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = _getRoleColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: roleColor.withOpacity(0.2))),
            child: Center(child: Text(user.name[0], style: TextStyle(color: roleColor, fontWeight: FontWeight.w900, fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(user.email, style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(user.role.name.toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 10)),
                    ),
                    if (user.className != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                        child: Text(user.className!, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_rounded, color: Color(0xFF4F46E5), size: 18)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
