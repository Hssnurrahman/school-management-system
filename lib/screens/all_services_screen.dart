import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/modern_app_bar.dart';

import 'attendance_screen.dart';
import 'notice_board_screen.dart';
import 'grades_screen.dart';
import 'timetable_screen.dart';
import 'fees_screen.dart';
import 'manage_users_screen.dart';
import 'homework_screen.dart';
import 'events_screen.dart';
import 'inventory_screen.dart';
import 'transport_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'classes_screen.dart';
import 'exam_screen.dart';
import 'lessons_screen.dart';
import 'student_attendance_screen.dart';
import 'student_reports_screen.dart';

class ServiceItem {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final String category;

  ServiceItem({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.category = 'General',
  });
}

class AllServicesScreen extends StatefulWidget {
  final UserRole role;
  final UserModel? user;

  const AllServicesScreen({super.key, required this.role, this.user});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceItem> _getServices() {
    switch (widget.role) {
      case UserRole.owner:
      case UserRole.principal:
        return [
          ServiceItem(
            label: 'Users',
            icon: Icons.people_alt_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
            category: 'Management',
            onTap: () => _nav(context, const ManageUsersScreen()),
          ),
          ServiceItem(
            label: 'Classes',
            icon: Icons.school_rounded,
            gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
            category: 'Management',
            onTap: () => _nav(context, const ClassesScreen()),
          ),
          ServiceItem(
            label: 'Finance',
            icon: Icons.payments_rounded,
            gradient: const [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
            category: 'Management',
            onTap: () => _nav(context, const FeesScreen()),
          ),
          ServiceItem(
            label: 'Notices',
            icon: Icons.campaign_rounded,
            gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            category: 'Communication',
            onTap: () => _nav(context, const NoticeBoardScreen()),
          ),
          ServiceItem(
            label: 'Events',
            icon: Icons.event_rounded,
            gradient: const [Color(0xFFEC4899), Color(0xFFF472B6)],
            category: 'Communication',
            onTap: () => _nav(context, const EventsScreen()),
          ),
          ServiceItem(
            label: 'Inventory',
            icon: Icons.inventory_2_rounded,
            gradient: const [Color(0xFF0284C7), Color(0xFFC084FC)],
            category: 'Operations',
            onTap: () => _nav(context, const InventoryScreen()),
          ),
          ServiceItem(
            label: 'Transport',
            icon: Icons.directions_bus_rounded,
            gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
            category: 'Operations',
            onTap: () => _nav(context, const TransportScreen()),
          ),
          ServiceItem(
            label: 'Library',
            icon: Icons.local_library_rounded,
            gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            category: 'Operations',
            onTap: () => _nav(context, const LibraryScreen()),
          ),
          ServiceItem(
            label: 'Reports',
            icon: Icons.assessment_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
            category: 'Academic',
            onTap: () => _nav(
              context,
              StudentReportsScreen(
                className: '',
                user: widget.user,
              ),
            ),
          ),
          ServiceItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            gradient: const [Color(0xFF64748B), Color(0xFF94A3B8)],
            category: 'General',
            onTap: () => _nav(context, const SettingsScreen()),
          ),
        ];
      case UserRole.teacher:
        return [
          ServiceItem(
            label: 'Attendance',
            icon: Icons.how_to_reg_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
            category: 'Daily',
            onTap: () => _nav(context, AttendanceScreen(user: widget.user)),
          ),
          ServiceItem(
            label: 'Students',
            icon: Icons.people_alt_rounded,
            gradient: const [Color(0xFF0284C7), Color(0xFF60A5FA)],
            category: 'Management',
            onTap: () => _nav(
              context,
              const ManageUsersScreen(viewMode: ManageUsersViewMode.teacher),
            ),
          ),
          ServiceItem(
            label: 'Classes',
            icon: Icons.school_rounded,
            gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
            category: 'Management',
            onTap: () => _nav(context, const ClassesScreen()),
          ),
          ServiceItem(
            label: 'Reports',
            icon: Icons.assessment_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
            category: 'Academic',
            onTap: () => _nav(
              context,
              StudentReportsScreen(
                className: widget.user?.className ?? '',
                user: widget.user,
              ),
            ),
          ),
          ServiceItem(
            label: 'Schedule',
            icon: Icons.event_note_rounded,
            gradient: const [Color(0xFFEC4899), Color(0xFFF472B6)],
            category: 'Academic',
            onTap: () => _nav(
              context,
              TimetableScreen(className: widget.user?.className),
            ),
          ),
          ServiceItem(
            label: 'Exams',
            icon: Icons.assignment_rounded,
            gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            category: 'Academic',
            onTap: () => _nav(context, ExamScreen(teacher: widget.user!)),
          ),
          ServiceItem(
            label: 'Lessons',
            icon: Icons.book_rounded,
            gradient: const [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
            category: 'Academic',
            onTap: () => _nav(context, const LessonsScreen()),
          ),
          ServiceItem(
            label: 'Library',
            icon: Icons.local_library_rounded,
            gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            category: 'Operations',
            onTap: () => _nav(context, const LibraryScreen()),
          ),
          ServiceItem(
            label: 'Transport',
            icon: Icons.directions_bus_rounded,
            gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
            category: 'Operations',
            onTap: () => _nav(context, const TransportScreen()),
          ),
          ServiceItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            gradient: const [Color(0xFF64748B), Color(0xFF94A3B8)],
            category: 'General',
            onTap: () => _nav(context, const SettingsScreen()),
          ),
        ];
      default:
        return [
          ServiceItem(
            label: 'Report card',
            icon: Icons.description_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
            category: 'Academic',
            onTap: () => _nav(
              context,
              StudentReportsScreen(
                className: widget.user?.className ?? '',
                user: widget.user,
              ),
            ),
          ),
          ServiceItem(
            label: 'Result',
            icon: Icons.assessment_rounded,
            gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
            category: 'Academic',
            onTap: () =>
                _nav(context, GradesScreen(studentId: widget.user?.id ?? '')),
          ),
          ServiceItem(
            label: 'Time',
            icon: Icons.schedule_rounded,
            gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            category: 'Academic',
            onTap: () => _nav(
              context,
              TimetableScreen(className: widget.user?.className),
            ),
          ),
          ServiceItem(
            label: 'Task',
            icon: Icons.assignment_rounded,
            gradient: const [Color(0xFFEC4899), Color(0xFFF472B6)],
            category: 'Academic',
            onTap: () => _nav(context, HomeworkScreen(teacher: widget.user)),
          ),
          ServiceItem(
            label: 'Attendance',
            icon: Icons.calendar_today_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
            category: 'Academic',
            onTap: () => _nav(
              context,
              StudentAttendanceScreen(
                studentId: widget.user?.id ?? '',
                studentName: widget.user?.name ?? '',
              ),
            ),
          ),
          ServiceItem(
            label: 'Library',
            icon: Icons.local_library_rounded,
            gradient: const [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
            category: 'Operations',
            onTap: () => _nav(context, const LibraryScreen()),
          ),
          ServiceItem(
            label: 'Fees',
            icon: Icons.monetization_on_rounded,
            gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
            category: 'Operations',
            onTap: () => _nav(context, const FeesScreen()),
          ),
          ServiceItem(
            label: 'Transport',
            icon: Icons.directions_bus_rounded,
            gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            category: 'Operations',
            onTap: () => _nav(context, const TransportScreen()),
          ),
          ServiceItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            gradient: const [Color(0xFF64748B), Color(0xFF94A3B8)],
            category: 'General',
            onTap: () => _nav(context, const SettingsScreen()),
          ),
        ];
    }
  }

  void _nav(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allServices = _getServices();
    final filteredServices = allServices
        .where(
          (s) => s.label.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    final categories = filteredServices.map((s) => s.category).toSet().toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          ModernAppBar(
            title: 'All Services',
            expandedHeight: 160,
            backgroundIcon: Icons.apps_rounded,
          ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: SlideUpFade(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
          ),
          
          // Empty State
          if (filteredServices.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppColors.primaryTeal.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No matching services',
                      style: TextStyle(
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: TextStyle(
                        color: isDark 
                            ? AppColors.darkTextMuted 
                            : AppColors.lightTextMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Services by Category
            for (var category in categories) ...[
              SliverToBoxAdapter(
                child: SlideUpFade(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark 
                            ? AppColors.darkTextMuted 
                            : AppColors.lightTextMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: filteredServices
                      .where((s) => s.category == category)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) => SlideUpFade(
                            delay: Duration(milliseconds: entry.key * 50),
                            child: _ServiceCard(
                              service: entry.value,
                              isDark: isDark,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceItem service;
  final bool isDark;

  const _ServiceCard({required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: service.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.06) 
                : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.2) 
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: service.gradient,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: service.gradient[0].withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(service.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                service.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
