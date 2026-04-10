import 'package:flutter/material.dart';
import '../models/timetable_model.dart';
import '../services/database_service.dart';

class TimetableScreen extends StatefulWidget {
  final String? className; // null = show all (admin/teacher), set = filter by class
  const TimetableScreen({super.key, this.className});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TimetableEntry> _schedule = [];
  bool _isLoading = true;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  final Map<String, Color> _subjectColors = {
    'Mathematics': const Color(0xFF6366F1),
    'Physics': const Color(0xFF3B82F6),
    'English': const Color(0xFF10B981),
    'Chemistry': const Color(0xFFEC4899),
    'Biology': const Color(0xFF14B8A6),
    'History': const Color(0xFFF59E0B),
    'Science': const Color(0xFF10B981),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    final entries = await dbService.getTimetable(className: widget.className);
    setState(() {
      _schedule = entries;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getSubjectColor(String subject) =>
      _subjectColors[subject] ?? const Color(0xFF8B5CF6);

  void _showAddEntrySheet() {
    final formKey = GlobalKey<FormState>();
    String selectedDay = 'Monday';
    final startController = TextEditingController(text: '08:00 AM');
    final endController = TextEditingController(text: '09:00 AM');
    final subjectController = TextEditingController();
    final roomController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 20, left: 24, right: 24),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.25), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('Add Timetable Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: const InputDecoration(labelText: 'Day', prefixIcon: Icon(Icons.calendar_today_rounded)),
                    items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setSheetState(() => selectedDay = v!),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: startController, decoration: const InputDecoration(labelText: 'Start Time', prefixIcon: Icon(Icons.access_time_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: endController, decoration: const InputDecoration(labelText: 'End Time', prefixIcon: Icon(Icons.access_time_filled_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.book_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                  const SizedBox(height: 14),
                  TextFormField(controller: roomController, decoration: const InputDecoration(labelText: 'Room', prefixIcon: Icon(Icons.room_rounded))),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final entry = TimetableEntry(
                          day: selectedDay,
                          startTime: startController.text,
                          endTime: endController.text,
                          subject: subjectController.text,
                          room: roomController.text.isEmpty ? 'TBD' : roomController.text,
                        );
                        await dbService.insertTimetableEntry(entry, className: widget.className ?? 'All');
                        if (context.mounted) Navigator.pop(context);
                        await _loadTimetable();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                    child: const Text('Add Entry'),
                  ),
                  const SizedBox(height: 8),
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

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: _showAddEntrySheet,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Timetable', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD97706), Color(0xFFF59E0B)])),
                child: Center(child: Icon(Icons.schedule_rounded, color: Colors.white.withOpacity(0.12), size: 120)),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: isDark ? const Color(0xFF0D1626) : Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFFD97706),
                  unselectedLabelColor: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  indicatorColor: const Color(0xFFD97706),
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: _days.map((day) => Tab(text: day)).toList(),
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: _days.map((day) => _buildDayList(day, isDark)).toList(),
              ),
      ),
    );
  }

  Widget _buildDayList(String day, bool isDark) {
    final entries = _schedule.where((e) => e.day == day).toList();
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.event_busy_rounded, size: 48, color: const Color(0xFFF59E0B).withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text('No classes on $day', style: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length,
      itemBuilder: (context, index) => _TimetableCard(
        entry: entries[index],
        isDark: isDark,
        color: _getSubjectColor(entries[index].subject),
      ),
    );
  }
}

class _TimetableCard extends StatelessWidget {
  final TimetableEntry entry;
  final bool isDark;
  final Color color;

  const _TimetableCard({required this.entry, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18))),
            ),
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(entry.startTime.replaceAll(' AM', '').replaceAll(' PM', ''), style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Icon(Icons.arrow_downward_rounded, size: 12, color: color.withOpacity(0.5))),
                  Text(entry.endTime.replaceAll(' AM', '').replaceAll(' PM', ''), style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(entry.startTime.contains('AM') ? 'AM' : 'PM', style: TextStyle(fontWeight: FontWeight.w600, color: color.withOpacity(0.6), fontSize: 10)),
                ],
              ),
            ),
            Container(width: 1, color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(entry.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.location_on_rounded, size: 14, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(entry.room, style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('60m', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
