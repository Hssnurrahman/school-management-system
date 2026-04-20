import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/shimmer_box.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  List<Event> _events = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimations = List.generate(10, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Interval((i * 0.08).clamp(0, 0.8), (0.4 + i * 0.08).clamp(0, 1.0), curve: Curves.easeOut)),
    ));
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await dbService.getEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sports': return const Color(0xFF10B981);
      case 'academic': return const Color(0xFF3B82F6);
      case 'cultural': return const Color(0xFFF59E0B);
      default: return const Color(0xFF0284C7);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sports': return Icons.sports_rounded;
      case 'academic': return Icons.school_rounded;
      case 'cultural': return Icons.celebration_rounded;
      default: return Icons.event_rounded;
    }
  }

  void _showAddEventSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final categoryController = TextEditingController();

    showAppBottomSheet(
      context: context,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            const Text('Create New Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Event Title', prefixIcon: Icon(Icons.event_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true, prefixIcon: Icon(Icons.description_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category (Sports/Academic/Cultural)', prefixIcon: Icon(Icons.category_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final event = Event(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descController.text,
                    startDate: DateTime.now().add(const Duration(days: 1)),
                    location: locationController.text,
                    category: categoryController.text,
                  );
                  final nav = Navigator.of(context);
                  await dbService.insertEvent(event);
                  if (context.mounted) nav.pop();
                  await _loadEvents();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Publish Event'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      descController.dispose();
      locationController.dispose();
      categoryController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _events.where((e) =>
      e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Events', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2563EB), Color(0xFF0284C7)])),
                child: Center(child: Icon(Icons.event_rounded, color: Colors.white.withValues(alpha: 0.12), size: 120)),
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
                child: TextField(controller: _searchController, autofocus: true, decoration: const InputDecoration(hintText: 'Search events...', prefixIcon: Icon(Icons.search_rounded)), onChanged: (v) => setState(() => _searchQuery = v)),
              ),
            ),
          if (_isLoading)
            const ShimmerListSkeleton(asSliver: true)
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = filtered[index];
                    return FadeTransition(
                      opacity: _fadeAnimations[index % 10],
                      child: _EventCard(
                        event: event,
                        isDark: isDark,
                        categoryColor: _categoryColor(event.category),
                        categoryIcon: _categoryIcon(event.category),
                        onDelete: () async {
                          await dbService.deleteEvent(event.id);
                          if (mounted) await _loadEvents();
                        },
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventSheet,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Event', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final bool isDark;
  final VoidCallback onDelete;
  final Color categoryColor;
  final IconData categoryIcon;

  const _EventCard({required this.event, required this.isDark, required this.onDelete, required this.categoryColor, required this.categoryIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: categoryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(categoryIcon, color: categoryColor, size: 22)),
            title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 11, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text('${event.startDate.day}/${event.startDate.month} · ${event.location}', style: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
            trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: categoryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(event.category, style: TextStyle(color: categoryColor, fontWeight: FontWeight.w700, fontSize: 10))),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8EDF5)),
                    const SizedBox(height: 10),
                    Text(event.description, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.6, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)), SizedBox(width: 5), Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 12))]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
