import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_box.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditEntry> _entries = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final entries = await dbService.getAuditLog(limit: 200);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load audit log: $e');
    }
  }

  List<AuditEntry> get _filtered {
    if (_filter == 'all') return _entries;
    return _entries.where((e) => e.action.startsWith(_filter)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in const [
                    ('all', 'All'),
                    ('fee', 'Fees'),
                    ('user', 'Users'),
                    ('settings', 'Settings'),
                  ]) ...[
                    _FilterChip(
                      label: f.$2,
                      selected: _filter == f.$1,
                      onTap: () => setState(() => _filter = f.$1),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const ShimmerListSkeleton()
                : _filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.history_rounded,
                        message: 'No audit entries',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _AuditCard(entry: _filtered[i], isDark: isDark),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryTeal
                : AppColors.primaryTeal.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primaryTeal,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final AuditEntry entry;
  final bool isDark;
  const _AuditCard({required this.entry, required this.isDark});

  (IconData, Color) _iconForAction() {
    if (entry.action.startsWith('fee')) {
      return (Icons.account_balance_wallet_rounded, AppColors.primaryTeal);
    }
    if (entry.action.startsWith('user')) {
      return (Icons.person_rounded, AppColors.accentCyan);
    }
    if (entry.action.startsWith('settings')) {
      return (Icons.settings_rounded, AppColors.accentAmber);
    }
    return (Icons.history_rounded, AppColors.accentPink);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconForAction();
    final ts = entry.timestamp;
    final when =
        '${AppDateUtils.formatMDY(ts)} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.actorName} (${entry.actorRole})',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (entry.metadata.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.metadata.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(' · '),
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            when,
            style: TextStyle(
              color:
                  isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
