import 'package:flutter/material.dart';
import '../models/fee_model.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_bottom_sheet.dart';
import 'finance_summary_screen.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> with SingleTickerProviderStateMixin {
  List<Fee> _fees = [];
  bool _isLoading = true;
  String _selectedTab = 'All';
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimations = List.generate(10, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Interval((i * 0.06).clamp(0.0, 0.8), (0.4 + i * 0.06).clamp(0.0, 1.0), curve: Curves.easeOut)),
    ));
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() => _isLoading = true);
    try {
      final fees = await dbService.getFees();
      if (!mounted) return;
      setState(() {
        _fees = fees;
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

  List<Fee> get _filteredFees => _fees.where((f) {
    if (_selectedTab == 'Paid') return f.isPaid;
    if (_selectedTab == 'Pending') return !f.isPaid;
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPending = _fees.where((f) => !f.isPaid).fold(0.0, (sum, f) => sum + f.amount);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: Colors.white,
            centerTitle: true,
            title: const Text('Finance & Fees', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FinanceSummaryScreen(fees: _fees))),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Total Outstanding', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        FittedBox(child: Text('\$${totalPending.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1))),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildMiniStat('Collected', '\$${_fees.where((f) => f.isPaid).fold(0.0, (s, f) => s + f.amount).toStringAsFixed(0)}', const Color(0xFF34D399)),
                            const SizedBox(width: 10),
                            _buildMiniStat('Invoices', '${_fees.length}', const Color(0xFFFBBF24)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141E30) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
                ),
                child: Row(
                  children: ['All', 'Pending', 'Paid'].map((tab) {
                    final isSelected = _selectedTab == tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = tab),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(color: isSelected ? const Color(0xFF14B8A6) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                          child: Text(tab, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final fee = _filteredFees[index];
                    final animIdx = index < 10 ? index : 9;
                    return FadeTransition(
                      opacity: _fadeAnimations[animIdx],
                      child: _FeeCard(fee: fee, isDark: isDark, onPay: () => _showPaymentSheet(context, fee)),
                    );
                  },
                  childCount: _filteredFees.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFeeSheet,
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Invoice', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildMiniStat(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, Fee fee) {
    final refController = TextEditingController();
    showAppBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 20),
          const Text('Process Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFF14B8A6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.2))),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Color(0xFF14B8A6), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fee.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('\$${fee.amount}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF14B8A6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: refController, decoration: const InputDecoration(labelText: 'Reference Number', hintText: 'TXN123456', prefixIcon: Icon(Icons.confirmation_number_outlined))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final updated = fee.copyWith(isPaid: true);
                final messenger = ScaffoldMessenger.of(context);
                await dbService.updateFee(updated);
                if (!context.mounted) return;
                Navigator.pop(context);
                await _loadFees();
                if (mounted) {
                  messenger.showSnackBar(SnackBar(
                    content: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Payment marked as successful!')),
                    ]),
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6)),
              child: const Text('Confirm Payment'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
  }

  void _showAddFeeSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final studentController = TextEditingController();
    FeeCategory selectedCategory = FeeCategory.tuition;

    showAppBottomSheet(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            const Text('Create New Invoice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                TextField(controller: studentController, decoration: const InputDecoration(labelText: 'Student Name', prefixIcon: Icon(Icons.person_outline_rounded))),
                const SizedBox(height: 14),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Invoice Description', prefixIcon: Icon(Icons.description_outlined))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(flex: 2, child: TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.attach_money_rounded)), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<FeeCategory>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: FeeCategory.values.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.name.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (v) => setSheetState(() => selectedCategory = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      final fee = Fee(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        amount: double.tryParse(amountController.text) ?? 0.0,
                        dueDate: DateTime.now().add(const Duration(days: 30)),
                        isPaid: false,
                        category: selectedCategory,
                        studentName: studentController.text,
                      );
                      await dbService.insertFee(fee);
                      if (context.mounted) Navigator.pop(context);
                      await _loadFees();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6)),
                  child: const Text('Create Invoice'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
  }
}

class _FeeCard extends StatelessWidget {
  final Fee fee;
  final VoidCallback onPay;
  final bool isDark;

  const _FeeCard({required this.fee, required this.onPay, required this.isDark});

  IconData _getCategoryIcon() {
    switch (fee.category) {
      case FeeCategory.tuition: return Icons.school_rounded;
      case FeeCategory.library: return Icons.local_library_rounded;
      case FeeCategory.exam: return Icons.assignment_rounded;
      case FeeCategory.transport: return Icons.directions_bus_rounded;
      case FeeCategory.sports: return Icons.sports_basketball_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF14B8A6);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(_getCategoryIcon(), color: accentColor, size: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fee.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(fee.studentName ?? 'Unknown Student', style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${fee.amount}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: accentColor)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: fee.isPaid ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(fee.isPaid ? 'PAID' : 'PENDING', style: TextStyle(color: fee.isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8EDF5)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text('Due: ${fee.dueDate.day}/${fee.dueDate.month}/${fee.dueDate.year}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                ],
              ),
              if (!fee.isPaid)
                GestureDetector(
                  onTap: onPay,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10)), child: const Text('PAY NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                )
              else
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 5),
                    Text('Paid', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
