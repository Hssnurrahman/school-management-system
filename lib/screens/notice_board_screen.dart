import 'package:flutter/material.dart';
import '../models/notice_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/shimmer_box.dart';

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
    try {
      final notices = await dbService.getNotices();
      if (!mounted) return;
      setState(() {
        _notices = notices;
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

  void _showAddNoticeSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final authorController = TextEditingController();

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
                    final nav = Navigator.of(context);
                    await dbService.insertNotice(notice);
                    if (context.mounted) nav.pop();
                    await _loadNotices();
                  }
                },
                child: const Text('Broadcast Notice'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ).whenComplete(() {
        titleController.dispose();
        contentController.dispose();
        authorController.dispose();
      });
  }

  void _showDeleteConfirmation(Notice notice) {
    showConfirmDeleteDialog(
      context: context,
      title: 'Remove Notice?',
      message: 'This announcement will be permanently deleted.',
      onConfirm: () async {
        await dbService.deleteNotice(notice.id);
        await _loadNotices();
      },
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
            expandedHeight: 160,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 14),
              title: const Text('Notice Board', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF2563EB)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.campaign_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_notices.length} notice${_notices.length == 1 ? '' : 's'}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
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
            const ShimmerListSkeleton(asSliver: true)
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSearching ? Icons.search_off_rounded : Icons.campaign_outlined,
                        size: 48, color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isSearching ? 'No notices match your search' : 'No notices yet',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSearching ? 'Try a different keyword' : 'Tap "+ Post Notice" to broadcast one',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
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
        backgroundColor: const Color(0xFF0D9488),
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF0D9488);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.campaign_rounded, color: accentColor, size: 22),
                    ),
                    title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    subtitle: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 10,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(notice.date),
                          style: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.person_outline_rounded, size: 10,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            notice.author,
                            style: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8EDF5)),
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
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
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

