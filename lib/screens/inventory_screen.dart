import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  List<InventoryItem> _items = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimations = List.generate(10, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Interval((i * 0.1).clamp(0, 0.9), (0.4 + i * 0.1).clamp(0, 1.0), curve: Curves.easeOut)),
    ));
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final items = await dbService.getInventory();
      if (!mounted) return;
      setState(() {
        _items = items;
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
    super.dispose();
  }

  void _showAddItemSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    InventoryStatus selectedStatus = InventoryStatus.inStock;

    showAppBottomSheet(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 24),
              const Text('Add Inventory Item', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name', prefixIcon: Icon(Icons.inventory_2_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.numbers_rounded)), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit', prefixIcon: Icon(Icons.ad_units_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<InventoryStatus>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.info_outline_rounded)),
                items: InventoryStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                onChanged: (v) => setSheetState(() => selectedStatus = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final item = InventoryItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      category: categoryController.text,
                      quantity: int.tryParse(quantityController.text) ?? 0,
                      unit: unitController.text,
                      status: selectedStatus,
                    );
                    await dbService.insertInventoryItem(item);
                    if (context.mounted) Navigator.pop(context);
                    await _loadInventory();
                  }
                },
                child: const Text('Add to Inventory'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2563EB), Color(0xFF0284C7)])),
                child: Center(child: Icon(Icons.inventory_2_rounded, color: Colors.white.withValues(alpha: 0.12), size: 120)),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildSummaryCards(isDark)),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _items[index];
                    return FadeTransition(
                      opacity: _fadeAnimations[index % 10],
                      child: _InventoryCard(item: item, isDark: isDark, onDelete: () => _deleteItem(item)),
                    );
                  },
                  childCount: _items.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemSheet,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Item'),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _SummaryBox(label: 'Total', value: '${_items.length}', color: Colors.blue, isDark: isDark),
          const SizedBox(width: 12),
          _SummaryBox(label: 'Low', value: '${_items.where((e) => e.status == InventoryStatus.lowStock).length}', color: Colors.orange, isDark: isDark),
          const SizedBox(width: 12),
          _SummaryBox(label: 'Out', value: '${_items.where((e) => e.status == InventoryStatus.outOfStock).length}', color: Colors.red, isDark: isDark),
        ],
      ),
    );
  }

  void _deleteItem(InventoryItem item) {
    showConfirmDeleteDialog(
      context: context,
      title: 'Delete Item?',
      message: 'Remove "${item.name}" from inventory?',
      onConfirm: () async {
        await dbService.deleteInventoryItem(item.id);
        await _loadInventory();
      },
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryBox({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final bool isDark;
  final VoidCallback onDelete;

  const _InventoryCard({required this.item, required this.isDark, required this.onDelete});

  Color _getStatusColor() {
    switch (item.status) {
      case InventoryStatus.inStock: return Colors.green;
      case InventoryStatus.lowStock: return Colors.orange;
      case InventoryStatus.outOfStock: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF2563EB), size: 22)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(item.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.quantity} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withValues(alpha: 0.2))),
                  child: Text(item.status.name.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(onTap: onDelete, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16))),
          ],
        ),
      ),
    );
  }
}
