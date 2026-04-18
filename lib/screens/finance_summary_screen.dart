import 'package:flutter/material.dart';
import '../models/fee_model.dart';

class FinanceSummaryScreen extends StatelessWidget {
  final List<Fee> fees;

  const FinanceSummaryScreen({super.key, required this.fees});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double totalPaid = fees.where((f) => f.isPaid).fold(0.0, (sum, f) => sum + f.amount);
    final double totalPending = fees.where((f) => !f.isPaid).fold(0.0, (sum, f) => sum + f.amount);
    final double totalRevenue = totalPaid + totalPending;

    // Category breakdown
    final Map<FeeCategory, double> categoryTotals = {};
    for (final fee in fees) {
      categoryTotals[fee.category] = (categoryTotals[fee.category] ?? 0) + fee.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(totalPaid, totalPending, totalRevenue, isDark),
            const SizedBox(height: 24),
            const Text('Revenue by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildCategoryList(categoryTotals, isDark),
            const SizedBox(height: 24),
            const Text('Collection Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildProgressBar(totalPaid, totalRevenue, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(double paid, double pending, double total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Collected', '\$${paid.toStringAsFixed(0)}', Colors.green),
              _buildStatItem('Pending', '\$${pending.toStringAsFixed(0)}', Colors.orange),
              _buildStatItem('Total', '\$${total.toStringAsFixed(0)}', Colors.indigo),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Total school revenue for the current term.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildCategoryList(Map<FeeCategory, double> categoryTotals, bool isDark) {
    final categoryMeta = {
      FeeCategory.tuition: {'icon': Icons.school, 'color': Colors.blue, 'label': 'Tuition'},
      FeeCategory.library: {'icon': Icons.book, 'color': Colors.teal, 'label': 'Library'},
      FeeCategory.transport: {'icon': Icons.directions_bus, 'color': Colors.orange, 'label': 'Transport'},
      FeeCategory.exam: {'icon': Icons.assignment, 'color': Colors.purple, 'label': 'Exams'},
      FeeCategory.sports: {'icon': Icons.sports, 'color': Colors.green, 'label': 'Sports'},
    };

    return Column(
      children: categoryMeta.entries.map((entry) {
        final amount = categoryTotals[entry.key] ?? 0.0;
        if (amount == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141E30) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (entry.value['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(entry.value['icon'] as IconData, color: entry.value['color'] as Color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(entry.value['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
              Text('\$${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: entry.value['color'] as Color, fontSize: 16)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar(double paid, double total, bool isDark) {
    final double progress = total > 0 ? (paid / total) : 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Collection Target', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.indigo.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${paid.toStringAsFixed(0)} collected', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              Text('\$${(total - paid).toStringAsFixed(0)} remaining', style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
