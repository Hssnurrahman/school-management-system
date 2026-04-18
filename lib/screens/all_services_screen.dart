import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
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
  final UserModel? user; // needed for student/parent to pass id and className

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
            gradient: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
            category: 'Management',
            onTap: () => _nav(context, const ManageUsersScreen()),
          ),
          ServiceItem(
            label: 'Classes',
            icon: Icons.school_rounded,
            gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
            category: 'Management',
            onTap: () => _nav(context, const ClassesScreen()),
          ),
          ServiceItem(
            label: 'Finance',
            icon: Icons.payments_rounded,
            gradient: [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)],
            category: 'Management',
            onTap: () => _nav(context, const FeesScreen()),
          ),
          ServiceItem(
            label: 'Notices',
            icon: Icons.campaign_rounded,
            gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
            category: 'Communication',
            onTap: () => _nav(context, const NoticeBoardScreen()),
          ),
          ServiceItem(
            label: 'Events',
            icon: Icons.event_rounded,
            gradient: [const Color(0xFFEC4899), const Color(0xFFF472B6)],
            category: 'Communication',
            onTap: () => _nav(context, const EventsScreen()),
          ),
          ServiceItem(
            label: 'Inventory',
            icon: Icons.inventory_2_rounded,
            gradient: [const Color(0xFF0284C7), const Color(0xFFC084FC)],
            category: 'Operations',
            onTap: () => _nav(context, const InventoryScreen()),
          ),
          ServiceItem(
            label: 'Transport',
            icon: Icons.directions_bus_rounded,
            gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)],
            category: 'Operations',
            onTap: () => _nav(context, const TransportScreen()),
          ),
          ServiceItem(
            label: 'Library',
            icon: Icons.local_library_rounded,
            gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
            category: 'Operations',
            onTap: () => _nav(context, const LibraryScreen()),
          ),
          ServiceItem(
            label: 'Reports',
            icon: Icons.assessment_rounded,
            gradient: [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
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
            gradient: [const Color(0xFF64748B), const Color(0xFF94A3B8)],
            category: 'General',
            onTap: () => _nav(context, const SettingsScreen()),
          ),
        ];
      case UserRole.teacher:
        return [
          ServiceItem(
            label: 'Attendance',
            icon: Icons.how_to_reg_rounded,
            gradient: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
            category: 'Daily',
            onTap: () => _nav(context, AttendanceScreen(user: widget.user)),
          ),
          ServiceItem(
            label: 'Students',
            icon: Icons.people_alt_rounded,
            gradient: [const Color(0xFF0284C7), const Color(0xFF60A5FA)],
            category: 'Management',
            onTap: () => _nav(
              context,
              const ManageUsersScreen(viewMode: ManageUsersViewMode.teacher),
            ),
          ),
          ServiceItem(
            label: 'Classes',
            icon: Icons.school_rounded,
            gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
            category: 'Management',
            onTap: () => _nav(context, const ClassesScreen()),
          ),
          ServiceItem(
            label: 'Reports',
            icon: Icons.assessment_rounded,
            gradient: [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
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
            gradient: [const Color(0xFFEC4899), Color(0xFFF472B6)],
            category: 'Academic',
            onTap: () => _nav(
              context,
              TimetableScreen(className: widget.user?.className),
            ),
          ),
          ServiceItem(
            label: 'Exams',
            icon: Icons.assignment_rounded,
            gradient: [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
            category: 'Academic',
            onTap: () => _nav(context, ExamScreen(teacher: widget.user!)),
          ),
          ServiceItem(
            label: 'Lessons',
            icon: Icons.book_rounded,
            gradient: [const Color(0xFF14B8A6), Color(0xFF2DD4BF)],
            category: 'Academic',
            onTap: () => _nav(context, const LessonsScreen()),
          ),
          ServiceItem(
            label: 'Library',
            icon: Icons.local_library_rounded,
            gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
            category: 'Operations',
            onTap: () => _nav(context, const LibraryScreen()),
          ),
          ServiceItem(
            label: 'Transport',
            icon: Icons.directions_bus_rounded,
            gradient: [const Color(0xFFEF4444), Color(0xFFF87171)],
            category: 'Operations',
            onTap: () => _nav(context, const TransportScreen()),
          ),
          ServiceItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            gradient: [const Color(0xFF64748B), const Color(0xFF94A3B8)],
            category: 'General',
            onTap: () => _nav(context, const SettingsScreen()),
          ),
        ];
      default:
        return [
          ServiceItem(
            label: 'Report card',
            icon: Icons.description_rounded,
            gradient: [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
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
            gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
            category: 'Academic',
            onTap: () =>
                _nav(context, GradesScreen(studentId: widget.user?.id ?? '')),
          ),
          ServiceItem(
            label: 'Time',
            icon: Icons.schedule_rounded,
            gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
            category: 'Academic',
            onTap: () => _nav(
              context,
              TimetableScreen(className: widget.user?.className),
            ),
          ),
          ServiceItem(
            label: 'Task',
            icon: Icons.assignment_rounded,
            gradient: [const Color(0xFFEC4899), const Color(0xFFF472B6)],
            category: 'Academic',
            onTap: () => _nav(context, HomeworkScreen(teacher: widget.user)),
          ),
          ServiceItem(
            label: 'Attendance',
            icon: Icons.calendar_today_rounded,
            gradient: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
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
            gradient: [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)],
            category: 'Operations',
            onTap: () => _nav(context, const LibraryScreen()),
          ),
          ServiceItem(
            label: 'Fees',
            icon: Icons.monetization_on_rounded,
            gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)],
            category: 'Operations',
            onTap: () => _nav(context, const FeesScreen()),
          ),
          ServiceItem(
            label: 'Transport',
            icon: Icons.directions_bus_rounded,
            gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
            category: 'Operations',
            onTap: () => _nav(context, const TransportScreen()),
          ),
          ServiceItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            gradient: [const Color(0xFF64748B), const Color(0xFF94A3B8)],
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
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
              title: const Text(
                'All Services',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 20),
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
                    child: Icon(Icons.apps_rounded, color: Color(0x14FFFFFF), size: 130),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ),
          if (filteredServices.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 80,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No matching services',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (var category in categories) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.2,
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
                      .map(
                        (service) =>
                            _ServiceCard(service: service, isDark: isDark),
                      )
                      .toList(),
                ),
              ),
            ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: service.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141E30) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFE8EDF5),
            ),
            boxShadow: [
              BoxShadow(
                color: service.gradient[0].withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: service.gradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: service.gradient[0].withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(service.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  service.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: -0.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
