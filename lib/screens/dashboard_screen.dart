import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
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
import 'exam_screen.dart';
import 'student_reports_screen.dart';
import 'notifications_screen.dart';
import 'student_attendance_screen.dart';
import 'subjects_screen.dart';

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
  int _studentCount = 0;
  int _staffCount = 0;
  double _totalRevenue = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoadingStats = true;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimations = List.generate(10, (index) {
      double start = (index * 0.06).clamp(0.0, 0.8);
      double end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _animationController.forward();
    _loadStats();
    // Refresh relative timestamps every minute
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadStats() async {
    try {
      final users = await dbService.getUsers();
      final fees = await dbService.getFees();
      final activity = await dbService.getRecentActivity(limit: 5);

      int students = 0;
      int staff = 0;
      double revenue = 0;

      for (final user in users) {
        if (user.primaryRole == UserRole.student) {
          students++;
        } else if (user.primaryRole == UserRole.teacher ||
            user.primaryRole == UserRole.owner ||
            user.primaryRole == UserRole.principal) {
          staff++;
        }
      }

      for (final fee in fees) {
        if (fee.isPaid) {
          revenue += fee.amount;
        }
      }

      if (!mounted) return;
      setState(() {
        _studentCount = students;
        _staffCount = staff;
        _totalRevenue = revenue;
        _recentActivity = activity;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStats = false);
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[now.weekday - 1];
    return '$dayName, ${months[now.month - 1]} ${now.day}';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.principal:
        return 'Principal';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
    }
  }

  Color _roleColor(UserRole role) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final sessionRole =
            authService.effectiveRole ?? widget.user.primaryRole;
        final bool isAdmin = sessionRole == UserRole.owner ||
            sessionRole == UserRole.principal;

        return Scaffold(
          extendBody: true,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, isDark, sessionRole),
              ),
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
                    child: _buildSectionHeader(
                      'Quick Access',
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllServicesScreen(
                              role: sessionRole,
                              user: widget.user,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final items = _getFeaturesForRole(
                        context,
                        sessionRole,
                        isDark,
                      );
                      return FadeTransition(
                        opacity: _fadeAnimations[(index + 2).clamp(0, 9)],
                        child: items[index],
                      );
                    },
                    childCount: _getFeaturesForRole(
                      context,
                      sessionRole,
                      isDark,
                    ).length,
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
                    child: _recentActivity.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF141E30) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFE8EDF5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'No recent activity yet.\nAdd exams, notices, or events to see updates here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              ..._recentActivity.asMap().entries.map((e) {
                                final item = e.value;
                                final type = item['type'] as String;
                                final color = switch (type) {
                                  'notice'   => const Color(0xFF0EA5E9),
                                  'event'    => const Color(0xFF10B981),
                                  'exam'     => const Color(0xFF2563EB),
                                  'homework' => const Color(0xFFF59E0B),
                                  _          => const Color(0xFF64748B),
                                };
                                final icon = switch (type) {
                                  'notice'   => Icons.campaign_rounded,
                                  'event'    => Icons.event_rounded,
                                  'exam'     => Icons.assignment_rounded,
                                  'homework' => Icons.book_rounded,
                                  _          => Icons.info_rounded,
                                };
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildUpdateCard(
                                    item['title'] as String,
                                    _timeAgo(item['date'] as DateTime),
                                    item['subtitle'] as String? ?? '',
                                    color,
                                    icon,
                                    isDark,
                                  ),
                                );
                              }),
                              const SizedBox(height: 100),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, UserRole sessionRole) {
    final colorScheme = Theme.of(context).colorScheme;

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
            color: colorScheme.primary.withValues(alpha: 0.3),
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
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
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
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
                          _getGreeting(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _roleColor(sessionRole),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _roleLabel(sessionRole),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getFormattedDate(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
    if (_isLoadingStats) {
      return Row(
        children: List.generate(3, (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
            height: 110,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141E30) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFE8EDF5),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        )),
      );
    }

    return Row(
      children: [
        _buildStatCard(
          _studentCount.toString(),
          'Students',
          Icons.school_rounded,
          const Color(0xFF0EA5E9),
          isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          _staffCount.toString(),
          'Staff',
          Icons.supervisor_account_rounded,
          const Color(0xFF10B981),
          isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          '\$${_totalRevenue.toStringAsFixed(0)}',
          'Revenue',
          Icons.payments_rounded,
          const Color(0xFFF59E0B),
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141E30) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFE8EDF5),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: Color(0xFF0D9488),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUpdateCard(
    String title,
    String time,
    String desc,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _getFeaturesForRole(
    BuildContext context,
    UserRole role,
    bool isDark,
  ) {
    switch (role) {
      case UserRole.owner:
      case UserRole.principal:
        return [
          _QuickAction(
            label: 'Users',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF0EA5E9),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
            ),
          ),
          _QuickAction(
            label: 'Classes',
            icon: Icons.school_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassesScreen()),
            ),
          ),
          _QuickAction(
            label: 'Finance',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF14B8A6),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeesScreen()),
            ),
          ),
          _QuickAction(
            label: 'Notices',
            icon: Icons.campaign_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoticeBoardScreen()),
            ),
          ),
          _QuickAction(
            label: 'Subjects',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFFEC4899),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubjectsScreen()),
            ),
          ),
        ];
      case UserRole.teacher:
        return [
          _QuickAction(
            label: 'Attendance',
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF0EA5E9),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttendanceScreen(user: widget.user),
              ),
            ),
          ),
          _QuickAction(
            label: 'Students',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF0284C7),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageUsersScreen(
                  viewMode: ManageUsersViewMode.teacher,
                ),
              ),
            ),
          ),
          _QuickAction(
            label: 'Classes',
            icon: Icons.school_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassesScreen()),
            ),
          ),
          _QuickAction(
            label: 'Exams',
            icon: Icons.assignment_rounded,
            color: const Color(0xFF2563EB),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExamScreen(teacher: widget.user),
              ),
            ),
          ),
          _QuickAction(
            label: 'Homework',
            icon: Icons.book_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HomeworkScreen(teacher: widget.user),
              ),
            ),
          ),
          _QuickAction(
            label: 'Schedule',
            icon: Icons.event_note_rounded,
            color: const Color(0xFFEC4899),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimetableScreen(
                  className: widget.user.className,
                ),
              ),
            ),
          ),
          _QuickAction(
            label: 'Reports',
            icon: Icons.assessment_rounded,
            color: const Color(0xFF0EA5E9),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentReportsScreen(
                  className: widget.user.className ?? '',
                  user: widget.user,
                ),
              ),
            ),
          ),
          _QuickAction(
            label: 'Notices',
            icon: Icons.campaign_rounded,
            color: const Color(0xFF14B8A6),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoticeBoardScreen()),
            ),
          ),
          _QuickAction(
            label: 'Settings',
            icon: Icons.settings_rounded,
            color: const Color(0xFF64748B),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ];
      default:
        final studentId = widget.user.id;
        final className = widget.user.className;
        return [
          _QuickAction(
            label: 'Attendance',
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF0EA5E9),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentAttendanceScreen(
                  studentId: studentId,
                  studentName: widget.user.name,
                ),
              ),
            ),
          ),
          _QuickAction(
            label: 'Grades',
            icon: Icons.assessment_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GradesScreen(studentId: studentId),
              ),
            ),
          ),
          _QuickAction(
            label: 'Timetable',
            icon: Icons.schedule_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimetableScreen(className: className),
              ),
            ),
          ),
          _QuickAction(
            label: 'Homework',
            icon: Icons.assignment_rounded,
            color: const Color(0xFFEC4899),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HomeworkScreen(teacher: widget.user)),
            ),
          ),
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
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
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
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFE8EDF5),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Left color accent bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
