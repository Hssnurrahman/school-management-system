import 'package:flutter/material.dart';
import '../models/timetable_model.dart';
import '../models/subject_model.dart';
import '../utils/app_snackbar.dart';
import '../services/database_service.dart';
import '../widgets/app_bottom_sheet.dart';

class TimetableScreen extends StatefulWidget {
  final String?
  className; // null = show all (admin/teacher), set = filter by class
  const TimetableScreen({super.key, this.className});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TimetableEntry> _schedule = [];

  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final subjects = await dbService.getSubjects();
    setState(() {
      _subjects = subjects;
    });
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    try {
      final entries = await dbService.getTimetable(className: widget.className);
      if (!mounted) return;
      setState(() {
        _schedule = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final Map<String, Color> _subjectColors = {
    'Mathematics': const Color(0xFF0EA5E9),
    'Physics': const Color(0xFF3B82F6),
    'English': const Color(0xFF10B981),
    'Chemistry': const Color(0xFFEC4899),
    'Biology': const Color(0xFF14B8A6),
    'History': const Color(0xFFF59E0B),
    'Science': const Color(0xFF10B981),
  };

  Color _getSubjectColor(String subject) =>
      _subjectColors[subject] ?? const Color(0xFF0284C7);

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  void _showAddEntrySheet() {
    String selectedDay = 'Monday';
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 0);
    String? selectedSubject;
    final roomController = TextEditingController();
    String? timeError;

    showAppBottomSheet(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            const Text(
              'Add Timetable Entry',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  items: _days
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selectedDay = v!),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setSheetState(() {
                              startTime = picked;
                              timeError = _timeToMinutes(endTime) <= _timeToMinutes(startTime)
                                  ? 'End must be after start'
                                  : null;
                            });
                          }
                        },
                        child: _TimePickerTile(label: 'Start', time: _formatTime(startTime)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (picked != null) {
                            setSheetState(() {
                              endTime = picked;
                              timeError = _timeToMinutes(picked) <= _timeToMinutes(startTime)
                                  ? 'End must be after start'
                                  : null;
                            });
                          }
                        },
                        child: _TimePickerTile(label: 'End', time: _formatTime(endTime)),
                      ),
                    ),
                  ],
                ),
                if (timeError != null) ...[
                  const SizedBox(height: 6),
                  Text(timeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.book_rounded),
                  ),
                  items: _subjects
                      .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selectedSubject = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    prefixIcon: Icon(Icons.room_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedSubject == null) {
                      setSheetState(() {});
                      return;
                    }
                    if (_timeToMinutes(endTime) <= _timeToMinutes(startTime)) {
                      setSheetState(() => timeError = 'End must be after start');
                      return;
                    }
                    final entry = TimetableEntry(
                      day: selectedDay,
                      startTime: _formatTime(startTime),
                      endTime: _formatTime(endTime),
                      subject: selectedSubject!,
                      room: roomController.text.isEmpty ? 'TBD' : roomController.text,
                    );
                    await dbService.insertTimetableEntry(
                      entry,
                      className: widget.className ?? 'All',
                    );
                    if (context.mounted) Navigator.pop(context);
                    await _loadTimetable();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                  child: const Text('Add Entry'),
                ),
                const SizedBox(height: 8),
              ],
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
              title: const Text(
                'Timetable',
                style: TextStyle(
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
                    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.schedule_rounded,
                    color: Colors.white.withValues(alpha: 0.12),
                    size: 120,
                  ),
                ),
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
                  unselectedLabelColor: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFF94A3B8),
                  indicatorColor: const Color(0xFFD97706),
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
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
                children: _days
                    .map((day) => _buildDayList(day, isDark))
                    .toList(),
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
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 48,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No classes on $day',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
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

  const _TimetableCard({
    required this.entry,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
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
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.startTime.replaceAll(' AM', '').replaceAll(' PM', ''),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: 12,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    entry.endTime.replaceAll(' AM', '').replaceAll(' PM', ''),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.startTime.contains('AM') ? 'AM' : 'PM',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFE8EDF5),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.room,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '60m',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  const _TimePickerTile({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(time, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
