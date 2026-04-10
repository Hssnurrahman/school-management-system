import 'package:flutter/material.dart';
import '../models/notice_model.dart';
import '../services/database_service.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen>
    with SingleTickerProviderStateMixin {
  List<Notice> _notices = [];
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
    _fadeAnimations = List.generate(
      10,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval((index * 0.08).clamp(0, 0.8), (0.4 + index * 0.08).clamp(0, 1.0), curve: Curves.easeOut),
        ),
      ),
    );
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);
    final notices = await dbService.getNotices();
    setState(() {
      _notices = notices;
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

  void _showAddNoticeSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final authorController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheetContainer(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 20),
              const Text('Post New Notice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Notice Title', prefixIcon: Icon(Icons.title_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 14),
              TextFormField(controller: contentController, maxLines: 4, decoration: const InputDecoration(labelText: 'Content', alignLabelWithHint: true, prefixIcon: Icon(Icons.description_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 14),
              TextFormField(controller: authorController, decoration: const InputDecoration(labelText: 'Author / Department', prefixIcon: Icon(Icons.person_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final notice = Notice(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      content: contentController.text,
                      date: DateTime.now(),
                      author: authorController.text,
                    );
                    await dbService.insertNotice(notice);
                    if (context.mounted) Navigator.pop(context);
                    await _loadNotices();
                  }
                },
                child: const Text('Broadcast Notice'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Notice notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Notice?'),
        content: const Text('This announcement will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await dbService.deleteNotice(notice.id);
              if (context.mounted) Navigator.pop(context);
              await _loadNotices();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _notices.where((n) =>
      n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      n.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      n.author.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Notice Board', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.campaign_rounded, color: Colors.white.withOpacity(0.12), size: 120),
                ),
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
                  decoration: const InputDecoration(hintText: 'Search notices...', prefixIcon: Icon(Icons.search_rounded)),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notice = filtered[index];
                    return FadeTransition(
                      opacity: _fadeAnimations[index % 10],
                      child: _NoticeCard(
                        notice: notice,
                        isDark: isDark,
                        onDelete: () => _showDeleteConfirmation(notice),
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
        onPressed: _showAddNoticeSheet,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Post Notice', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final bool isDark;
  final VoidCallback onDelete;

  const _NoticeCard({required this.notice, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.campaign_rounded, color: Color(0xFF4F46E5), size: 22),
            ),
            title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: Text(
              '${notice.date.day}/${notice.date.month}/${notice.date.year} · ${notice.author}',
              style: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8EDF5)),
                    const SizedBox(height: 10),
                    Text(notice.content, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.6, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(icon: Icons.delete_outline_rounded, label: 'Delete', onTap: onDelete, isDestructive: true),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFEF4444) : Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final Widget child;
  const _BottomSheetContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 20, left: 24, right: 24),
      child: SingleChildScrollView(child: child),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.25),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
