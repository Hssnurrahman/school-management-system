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

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        quantity: json['quantity'],
        unit: json['unit'],
        status: InventoryStatus.values.firstWhere((e) => e.name == json['status']),
      );
}
