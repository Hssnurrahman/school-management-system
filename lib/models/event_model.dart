class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String category;
  final bool isAllDay;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.location,
    required this.category,
    this.isAllDay = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'location': location,
        'category': category,
        'isAllDay': isAllDay ? 1 : 0,
      };

  static DateTime _parseDate(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  static DateTime? _parseDateOrNull(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: (json['id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        startDate: _parseDate(json['startDate']),
        endDate: _parseDateOrNull(json['endDate']),
        location: (json['location'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        isAllDay: json['isAllDay'] == 1 || json['isAllDay'] == true,
      );
}
