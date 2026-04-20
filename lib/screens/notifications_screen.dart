import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/shimmer_box.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await dbService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.approval: return Icons.rule_rounded;
      case NotificationType.stock: return Icons.inventory_2_rounded;
      case NotificationType.finance: return Icons.payments_rounded;
      case NotificationType.message: return Icons.chat_bubble_rounded;
      case NotificationType.system: return Icons.settings_suggest_rounded;
    }
  }

  Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.approval: return const Color(0xFF3B82F6);
      case NotificationType.stock: return const Color(0xFFF59E0B);
      case NotificationType.finance: return const Color(0xFF10B981);
      case NotificationType.message: return const Color(0xFF0284C7);
      case NotificationType.system: return const Color(0xFF64748B);
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)])),
                child: Center(child: Icon(Icons.notifications_rounded, color: Colors.white.withValues(alpha: 0.12), size: 120)),
              ),
            ),
            actions: [
              if (unread > 0)
                TextButton(
                  onPressed: () async {
                    await dbService.markAllNotificationsRead();
                    await _loadNotifications();
                  },
                  child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
            ],
          ),
          if (unread > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2))),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text('$unread unread notification${unread > 1 ? 's' : ''}', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
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
                    final item = _notifications[index];
                    return _NotificationCard(
                      notification: item,
                      icon: _getIcon(item.type),
                      color: _getColor(item.type),
                      isDark: isDark,
                      timeLabel: _formatTime(item.timestamp),
                      onTap: () async {
                        await dbService.markNotificationRead(item.id);
                        await _loadNotifications();
                      },
                    );
                  },
                  childCount: _notifications.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String timeLabel;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.icon, required this.color, required this.isDark, required this.timeLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? (isDark ? const Color(0xFF141E30) : Colors.white) : (isDark ? color.withValues(alpha: 0.08) : color.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: notification.isRead ? (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)) : color.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800, fontSize: 14))),
                    if (!notification.isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 4),
                  Text(notification.description, style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(timeLabel, style: TextStyle(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
