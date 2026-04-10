import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'attendance_screen.dart';
import 'notice_board_screen.dart';
import 'grades_screen.dart';
import 'timetable_screen.dart';
import 'fees_screen.dart';
import 'manage_users_screen.dart';
import 'homework_screen.dart';
import 'all_services_screen.dart';
import 'settings_screen.dart';
import 'classes_screen.dart';
import 'marks_screen.dart';
import 'notifications_screen.dart';
import 'student_attendance_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimations = List.generate(
      10,
      (index) {
        double start = (index * 0.06).clamp(0.0, 0.8);
        double end = (start + 0.4).clamp(0.0, 1.0);
        return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _animationController, curve: Interval(start, end, curve: Curves.easeOut)),
        );
      },
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Administrator';
      case UserRole.teacher: return 'Teacher';
      case UserRole.student: return 'Student';
      case UserRole.parent: return 'Parent';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return const Color(0xFF6366F1);
      case UserRole.teacher: return const Color(0xFF10B981);
      case UserRole.student: return const Color(0xFFF59E0B);
      case UserRole.parent: return const Color(0xFFEC4899);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.user.role == UserRole.admin;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, isDark)),
          if (isAdmin)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimations[0],
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildAdminStats(isDark),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimations[1],
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _buildSectionHeader('Quick Access', onSeeAll: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AllServicesScreen(role: widget.user.role, user: widget.user),
                  ));
                }),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final items = _getFeaturesForRole(context, widget.user.role, isDark);
                  return FadeTransition(
                    opacity: _fadeAnimations[(index + 2).clamp(0, 9)],
                    child: items[index],
                  );
                },
                childCount: _getFeaturesForRole(context, widget.user.role, isDark).length,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisExtent: 110,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimations[6],
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _buildSectionHeader('Recent Updates'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimations[7],
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  children: [
                    _buildUpdateCard(
                      'Exam Schedule Released',
                      '2 mins ago',
                      'The final term examination schedule has been published.',
                      const Color(0xFF6366F1),
                      Icons.assignment_rounded,
                      isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildUpdateCard(
                      'Parent-Teacher Meeting',
                      '1 hour ago',
                      'Scheduled for this Saturday at 10 AM. Please confirm attendance.',
                      const Color(0xFF10B981),
                      Icons.groups_rounded,
                      isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildUpdateCard(
                      'Fee Payment Reminder',
                      '3 hours ago',
                      'Q2 tuition fee deadline is approaching on 20th Oct.',
                      const Color(0xFFF59E0B),
                      Icons.payments_rounded,
                      isDark,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    // ignore: unused_local_variable
    final roleColor = _roleColor(widget.user.role);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HeaderIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Text(
                              widget.user.name[0],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _HeaderIconButton(
                        icon: Icons.logout_rounded,
                        onTap: () async {
                          await authService.logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.user.name.split(' ').first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _roleLabel(widget.user.role),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminStats(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem('1,245', 'Students', Icons.school_rounded, const Color(0xFF6366F1), isDark),
          _buildDivider(isDark),
          _buildStatItem('128', 'Staff', Icons.supervisor_account_rounded, const Color(0xFF10B981), isDark),
          _buildDivider(isDark),
          _buildStatItem('\$54k', 'Revenue', Icons.payments_rounded, const Color(0xFFF59E0B), isDark),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 48,
      color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE8EDF5),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUpdateCard(String title, String time, String desc, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getFeaturesForRole(BuildContext context, UserRole role, bool isDark) {
    switch (role) {
      case UserRole.admin:
        return [
          _QuickAction(label: 'Users', icon: Icons.people_alt_rounded, color: const Color(0xFF6366F1), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen()))),
          _QuickAction(label: 'Classes', icon: Icons.school_rounded, color: const Color(0xFF10B981), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassesScreen()))),
          _QuickAction(label: 'Finance', icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF14B8A6), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()))),
          _QuickAction(label: 'Notices', icon: Icons.campaign_rounded, color: const Color(0xFFF59E0B), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeBoardScreen()))),
        ];
      case UserRole.teacher:
        return [
          _QuickAction(label: 'Attendance', icon: Icons.how_to_reg_rounded, color: const Color(0xFF6366F1), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()))),
          _QuickAction(label: 'Students', icon: Icons.people_alt_rounded, color: const Color(0xFF8B5CF6), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen(isTeacherView: true)))),
          _QuickAction(label: 'Marks', icon: Icons.grade_rounded, color: const Color(0xFFF59E0B), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarksScreen()))),
          _QuickAction(label: 'Timetable', icon: Icons.event_note_rounded, color: const Color(0xFFEC4899), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TimetableScreen(className: widget.user.className)))),
        ];
      default:
        // student / parent
        final studentId = widget.user.id;
        final className = widget.user.className;
        return [
          _QuickAction(label: 'Attendance', icon: Icons.calendar_today_rounded, color: const Color(0xFF6366F1), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentAttendanceScreen(studentId: studentId, studentName: widget.user.name)))),
          _QuickAction(label: 'Grades', icon: Icons.assessment_rounded, color: const Color(0xFF10B981), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GradesScreen(studentId: studentId)))),
          _QuickAction(label: 'Timetable', icon: Icons.schedule_rounded, color: const Color(0xFFF59E0B), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TimetableScreen(className: className)))),
          _QuickAction(label: 'Homework', icon: Icons.assignment_rounded, color: const Color(0xFFEC4899), isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeworkScreen()))),
        ];
    }
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141E30) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
