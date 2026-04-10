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
import 'marks_screen.dart';
import 'lessons_screen.dart';
import 'student_attendance_screen.dart';

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
      case UserRole.admin:
        return [
          ServiceItem(label: 'Users', icon: Icons.people_alt_rounded, gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], category: 'Management', onTap: () => _nav(context, const ManageUsersScreen())),
          ServiceItem(label: 'Classes', icon: Icons.school_rounded, gradient: [const Color(0xFF10B981), const Color(0xFF34D399)], category: 'Management', onTap: () => _nav(context, const ClassesScreen())),
          ServiceItem(label: 'Finance', icon: Icons.payments_rounded, gradient: [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)], category: 'Management', onTap: () => _nav(context, const FeesScreen())),
          ServiceItem(label: 'Notices', icon: Icons.campaign_rounded, gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], category: 'Communication', onTap: () => _nav(context, const NoticeBoardScreen())),
          ServiceItem(label: 'Events', icon: Icons.event_rounded, gradient: [const Color(0xFFEC4899), const Color(0xFFF472B6)], category: 'Communication', onTap: () => _nav(context, const EventsScreen())),
          ServiceItem(label: 'Inventory', icon: Icons.inventory_2_rounded, gradient: [const Color(0xFF8B5CF6), const Color(0xFFC084FC)], category: 'Operations', onTap: () => _nav(context, const InventoryScreen())),
          ServiceItem(label: 'Transport', icon: Icons.directions_bus_rounded, gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)], category: 'Operations', onTap: () => _nav(context, const TransportScreen())),
          ServiceItem(label: 'Library', icon: Icons.local_library_rounded, gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], category: 'Operations', onTap: () => _nav(context, const LibraryScreen())),
          ServiceItem(label: 'Settings', icon: Icons.settings_rounded, gradient: [const Color(0xFF64748B), const Color(0xFF94A3B8)], category: 'General', onTap: () => _nav(context, const SettingsScreen())),
        ];
      case UserRole.teacher:
        return [
          ServiceItem(label: 'Attendance', icon: Icons.how_to_reg_rounded, gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], category: 'Daily', onTap: () => _nav(context, const AttendanceScreen())),
          ServiceItem(label: 'Students', icon: Icons.people_alt_rounded, gradient: [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], category: 'Management', onTap: () => _nav(context, const ManageUsersScreen(isTeacherView: true))),
          ServiceItem(label: 'Classes', icon: Icons.school_rounded, gradient: [const Color(0xFF10B981), const Color(0xFF34D399)], category: 'Management', onTap: () => _nav(context, const ClassesScreen())),
          ServiceItem(label: 'Marks', icon: Icons.grade_rounded, gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], category: 'Academic', onTap: () => _nav(context, const MarksScreen())),
          ServiceItem(label: 'Schedule', icon: Icons.event_note_rounded, gradient: [const Color(0xFFEC4899), Color(0xFFF472B6)], category: 'Academic', onTap: () => _nav(context, TimetableScreen(className: widget.user?.className))),
          ServiceItem(label: 'Lessons', icon: Icons.book_rounded, gradient: [const Color(0xFF14B8A6), Color(0xFF2DD4BF)], category: 'Academic', onTap: () => _nav(context, const LessonsScreen())),
          ServiceItem(label: 'Library', icon: Icons.local_library_rounded, gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], category: 'Operations', onTap: () => _nav(context, const LibraryScreen())),
          ServiceItem(label: 'Transport', icon: Icons.directions_bus_rounded, gradient: [const Color(0xFFEF4444), Color(0xFFF87171)], category: 'Operations', onTap: () => _nav(context, const TransportScreen())),
          ServiceItem(label: 'Settings', icon: Icons.settings_rounded, gradient: [const Color(0xFF64748B), const Color(0xFF94A3B8)], category: 'General', onTap: () => _nav(context, const SettingsScreen())),
        ];
      default:
        return [
          ServiceItem(label: 'Result', icon: Icons.assessment_rounded, gradient: [const Color(0xFF10B981), const Color(0xFF34D399)], category: 'Academic', onTap: () => _nav(context, GradesScreen(studentId: widget.user?.id ?? ''))),
          ServiceItem(label: 'Time', icon: Icons.schedule_rounded, gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], category: 'Academic', onTap: () => _nav(context, TimetableScreen(className: widget.user?.className))),
          ServiceItem(label: 'Task', icon: Icons.assignment_rounded, gradient: [const Color(0xFFEC4899), const Color(0xFFF472B6)], category: 'Academic', onTap: () => _nav(context, const HomeworkScreen())),
          ServiceItem(label: 'Attendance', icon: Icons.calendar_today_rounded, gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], category: 'Academic', onTap: () => _nav(context, StudentAttendanceScreen(studentId: widget.user?.id ?? '', studentName: widget.user?.name ?? ''))),
          ServiceItem(label: 'Library', icon: Icons.local_library_rounded, gradient: [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)], category: 'Operations', onTap: () => _nav(context, const LibraryScreen())),
          ServiceItem(label: 'Fees', icon: Icons.monetization_on_rounded, gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)], category: 'Operations', onTap: () => _nav(context, const FeesScreen())),
          ServiceItem(label: 'Transport', icon: Icons.directions_bus_rounded, gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], category: 'Operations', onTap: () => _nav(context, const TransportScreen())),
          ServiceItem(label: 'Settings', icon: Icons.settings_rounded, gradient: [const Color(0xFF64748B), const Color(0xFF94A3B8)], category: 'General', onTap: () => _nav(context, const SettingsScreen())),
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
    final filteredServices = allServices.where((s) => s.label.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    final categories = filteredServices.map((s) => s.category).toSet().toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF4338CA),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('All Services', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4338CA), Color(0xFF4F46E5)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.apps_rounded, color: Color(0x1AFFFFFF), size: 120),
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
                    Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
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
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: filteredServices
                      .where((s) => s.category == category)
                      .map((service) => _ServiceCard(service: service, isDark: isDark))
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
    return Column(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: service.onTap,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: service.gradient,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: service.gradient[0].withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  service.icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          service.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
