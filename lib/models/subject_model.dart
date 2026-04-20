class SubjectModel {
  final String id;
  final String name;
  final String colorHex; // e.g. 'FF6366F1'

  SubjectModel({
    required this.id,
    required this.name,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorHex': colorHex,
  };

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
    id: (json['id'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    colorHex: (json['colorHex'] as String? ?? 'FF6366F1'),
  );
}
