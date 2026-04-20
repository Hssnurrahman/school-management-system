enum InventoryStatus { inStock, lowStock, outOfStock }

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final InventoryStatus status;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'status': status.name,
      };

  static InventoryStatus _parseStatus(Object? raw) {
    if (raw == null) return InventoryStatus.inStock;
    final name = raw.toString();
    for (final s in InventoryStatus.values) {
      if (s.name == name) return s;
    }
    return InventoryStatus.inStock;
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: (json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unit: (json['unit'] ?? '') as String,
        status: _parseStatus(json['status']),
      );
}
