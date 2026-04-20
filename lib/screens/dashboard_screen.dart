import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/modern_card.dart';
import '../widgets/shimmer_box.dart';
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

import 'notifications_screen.dart';
import 'student_attendance_screen.dart';
import 'student_reports_screen.dart';
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
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
    _loadStats();
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
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
        return AppColors.primaryPurple;
      case UserRole.principal:
        return AppColors.primaryTeal;
      case UserRole.teacher:
        return AppColors.accentEmerald;
      case UserRole.student:
        return AppColors.accentAmber;
      case UserRole.parent:
        return AppColors.accentPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final sessionRole =
            authService.effectiveRole ?? widget.user.primaryRole;
        final bool isAdmin = sessionRole == UserRole.owner ||
            sessionRole == UserRole.principal;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: SlideUpFade(
                  child: _buildHeader(context, isDark, sessionRole),
                ),
              ),
              
              // Admin Stats
              if (isAdmin)
                SliverToBoxAdapter(
                  child: SlideUpFade(
                    delay: const Duration(milliseconds: 100),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildAdminStats(isDark),
                    ),
                  ),
                ),
              
              // Quick Access Header
              SliverToBoxAdapter(
                child: SlideUpFade(
                  delay: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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
              
              // Quick Access Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final items = _getFeaturesForRole(context, sessionRole);
                      return SlideUpFade(
                        delay: Duration(milliseconds: 200 + (index * 50)),
                        child: items[index],
                      );
                    },
                    childCount: _getFeaturesForRole(context, sessionRole).length,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 170,
                    mainAxisExtent: 120,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              ),
              
              // Recent Updates Header
              SliverToBoxAdapter(
                child: SlideUpFade(
                  delay: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: _buildSectionHeader('Recent Updates'),
                  ),
                ),
              ),
              
              // Recent Updates List
              SliverToBoxAdapter(
                child: SlideUpFade(
                  delay: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _recentActivity.isEmpty
                        ? _buildEmptyState(isDark)
                        : Column(
                            children: [
                              ..._recentActivity.asMap().entries.map((e) {
                                final item = e.value;
                                final type = item['type'] as String;
                                final color = switch (type) {
                                  'notice' => AppColors.accentCyan,
                                  'event' => AppColors.accentEmerald,
                                  'exam' => AppColors.primaryBlue,
                                  'homework' => AppColors.accentAmber,
                                  _ => AppColors.lightTextMuted,
                                };
                                final icon = switch (type) {
                                  'notice' => Icons.campaign_rounded,
                                  'event' => Icons.event_rounded,
                                  'exam' => Icons.assignment_rounded,
                                  'homework' => Icons.book_rounded,
                                  _ => Icons.info_rounded,
                                };
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              // Top row with actions
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
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: Text(
                              widget.user.name[0],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
              const SizedBox(height: 24),
              
              // Greeting and info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.name.split(' ').first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
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
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _roleColor(sessionRole),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _roleLabel(sessionRole),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getFormattedDate(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
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
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 36, height: 36, borderRadius: 10),
                ShimmerBox(width: 60, height: 22, borderRadius: 6),
                ShimmerBox(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ),
        )),
      );
    }

    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: _studentCount.toString(),
            label: 'Students',
            icon: Icons.school_rounded,
            color: AppColors.accentCyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            value: _staffCount.toString(),
            label: 'Staff',
            icon: Icons.people_alt_rounded,
            color: AppColors.accentEmerald,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            value: '\$${_totalRevenue.toStringAsFixed(0)}',
            label: 'Revenue',
            icon: Icons.payments_rounded,
            color: AppColors.accentAmber,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.primaryTeal,
                  ),
                ],
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
    return ModernCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
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
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.lightTextSecondary,
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
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.06) 
              : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 40,
              color: AppColors.primaryTeal.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add exams, notices, or events to see updates here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getFeaturesForRole(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.owner:
        return [
          FeatureCard(
            label: 'Users',
            icon: Icons.people_alt_rounded,
            color: AppColors.accentCyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
            ),
          ),
          FeatureCard(
            label: 'Classes',
            icon: Icons.school_rounded,
            color: AppColors.accentEmerald,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassesScreen()),
            ),
          ),
          FeatureCard(
            label: 'Finance',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.primaryTeal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeesScreen()),
            ),
          ),
          FeatureCard(
            label: 'Notices',
            icon: Icons.campaign_rounded,
            color: AppColors.accentAmber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoticeBoardScreen()),
            ),
          ),
          FeatureCard(
            label: 'Reports',
            icon: Icons.assessment_rounded,
            color: AppColors.accentPink,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentReportsScreen(
                  className: '',
                  user: widget.user,
                ),
              ),
            ),
          ),
        ];
      case UserRole.principal:
        return [
          FeatureCard(
            label: 'Users',
            icon: Icons.people_alt_rounded,
            color: AppColors.accentCyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
            ),
          ),
          FeatureCard(
            label: 'Classes',
            icon: Icons.school_rounded,
            color: AppColors.accentEmerald,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassesScreen()),
            ),
          ),
          FeatureCard(
            label: 'Finance',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.primaryTeal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeesScreen()),
            ),
          ),
          FeatureCard(
            label: 'Notices',
            icon: Icons.campaign_rounded,
            color: AppColors.accentAmber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoticeBoardScreen()),
            ),
          ),
          FeatureCard(
            label: 'Subjects',
            icon: Icons.menu_book_rounded,
            color: AppColors.accentPink,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubjectsScreen()),
            ),
          ),
        ];
      case UserRole.teacher:
        return [
          FeatureCard(
            label: 'Attendance',
            icon: Icons.how_to_reg_rounded,
            color: AppColors.accentCyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttendanceScreen(user: widget.user),
              ),
            ),
          ),
          FeatureCard(
            label: 'Students',
            icon: Icons.people_alt_rounded,
            color: AppColors.primaryBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageUsersScreen(
                  viewMode: ManageUsersViewMode.teacher,
                ),
              ),
            ),
          ),
          FeatureCard(
            label: 'Classes',
            icon: Icons.school_rounded,
            color: AppColors.accentEmerald,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassesScreen()),
            ),
          ),
          FeatureCard(
            label: 'Exams',
            icon: Icons.assignment_rounded,
            color: AppColors.primaryBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExamScreen(teacher: widget.user),
              ),
            ),
          ),
          FeatureCard(
            label: 'Homework',
            icon: Icons.book_rounded,
            color: AppColors.accentAmber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HomeworkScreen(teacher: widget.user),
              ),
            ),
          ),
          FeatureCard(
            label: 'Schedule',
            icon: Icons.event_note_rounded,
            color: AppColors.accentPink,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimetableScreen(
                  className: widget.user.className,
                ),
              ),
            ),
          ),
        ];
      default:
        final studentId = widget.user.id;
        final className = widget.user.className;
        return [
          FeatureCard(
            label: 'Attendance',
            icon: Icons.calendar_today_rounded,
            color: AppColors.accentCyan,
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
          FeatureCard(
            label: 'Grades',
            icon: Icons.assessment_rounded,
            color: AppColors.accentEmerald,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GradesScreen(studentId: studentId),
              ),
            ),
          ),
          FeatureCard(
            label: 'Timetable',
            icon: Icons.schedule_rounded,
            color: AppColors.accentAmber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimetableScreen(className: className),
              ),
            ),
          ),
          FeatureCard(
            label: 'Homework',
            icon: Icons.assignment_rounded,
            color: AppColors.accentPink,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HomeworkScreen(teacher: widget.user),
              ),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
