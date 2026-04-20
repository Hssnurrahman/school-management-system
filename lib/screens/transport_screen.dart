import 'package:flutter/material.dart';
import '../models/transport_route.dart';
import '../services/database_service.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../utils/app_snackbar.dart';
import '../widgets/shimmer_box.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  List<TransportRoute> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final routes = await dbService.getRoutes();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  void _showAddRouteSheet() {
    final formKey = GlobalKey<FormState>();
    final routeNameController = TextEditingController();
    final driverNameController = TextEditingController();
    final driverPhoneController = TextEditingController();
    final vehicleController = TextEditingController();
    final stopsController = TextEditingController();

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
            const Text('Add Transport Route', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextFormField(controller: routeNameController, decoration: const InputDecoration(labelText: 'Route Name', prefixIcon: Icon(Icons.route_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: driverNameController, decoration: const InputDecoration(labelText: 'Driver Name', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: driverPhoneController, decoration: const InputDecoration(labelText: 'Driver Phone', prefixIcon: Icon(Icons.phone_rounded))),
            const SizedBox(height: 14),
            TextFormField(controller: vehicleController, decoration: const InputDecoration(labelText: 'Vehicle Number', prefixIcon: Icon(Icons.directions_bus_rounded))),
            const SizedBox(height: 14),
            TextFormField(controller: stopsController, decoration: const InputDecoration(labelText: 'Stops (comma separated)', prefixIcon: Icon(Icons.location_on_rounded)), maxLines: 2),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final stops = stopsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  if (stops.isEmpty) stops.add('School');
                  final route = TransportRoute(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    routeName: routeNameController.text,
                    driverName: driverNameController.text,
                    driverPhone: driverPhoneController.text.isEmpty ? 'N/A' : driverPhoneController.text,
                    vehicleNumber: vehicleController.text.isEmpty ? 'N/A' : vehicleController.text,
                    stops: stops,
                  );
                  final nav = Navigator.of(context);
                  await dbService.insertRoute(route);
                  if (context.mounted) nav.pop();
                  await _loadRoutes();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text('Add Route'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).whenComplete(() {
      routeNameController.dispose();
      driverNameController.dispose();
      driverPhoneController.dispose();
      vehicleController.dispose();
      stopsController.dispose();
    });
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
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Transport', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFDC2626), Color(0xFFEF4444)])),
                child: Center(child: Icon(Icons.directions_bus_rounded, color: Colors.white.withValues(alpha: 0.12), size: 120)),
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
                  (context, index) => _RouteCard(route: _routes[index], isDark: isDark, onDelete: () => _deleteRoute(_routes[index])),
                  childCount: _routes.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRouteSheet,
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Route', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _deleteRoute(TransportRoute route) {
    showConfirmDeleteDialog(
      context: context,
      title: 'Delete Route?',
      message: 'Remove "${route.routeName}"?',
      onConfirm: () async {
        await dbService.deleteRoute(route.id);
        if (mounted) await _loadRoutes();
      },
    );
  }
}

class _RouteCard extends StatelessWidget {
  final TransportRoute route;
  final bool isDark;
  final VoidCallback onDelete;

  const _RouteCard({required this.route, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isMaintenance = route.status == 'Maintenance';
    final statusColor = isMaintenance ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

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
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.directions_bus_rounded, color: Color(0xFFEF4444), size: 22)),
            title: Text(route.routeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(route.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 10))),
              const SizedBox(width: 8),
              Text(route.vehicleNumber, style: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8EDF5)),
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.person_rounded, label: 'Driver', value: route.driverName, isDark: isDark),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.phone_rounded, label: 'Contact', value: route.driverPhone, isDark: isDark),
                    const SizedBox(height: 14),
                    Text('Route Stops', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    ...route.stops.asMap().entries.map((entry) {
                      final isLast = entry.key == route.stops.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: isLast ? const Color(0xFFEF4444) : const Color(0xFFEF4444).withValues(alpha: 0.4), shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Text(entry.value, style: TextStyle(fontWeight: isLast ? FontWeight.w700 : FontWeight.w500, color: isLast ? null : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)), fontSize: 13)),
                        ]),
                      );
                    }),
                    const SizedBox(height: 12),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]);
  }
}
