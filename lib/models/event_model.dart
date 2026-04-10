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

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        startDate: DateTime.parse(json['startDate']),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        location: json['location'],
        category: json['category'],
        isAllDay: json['isAllDay'] == 1 || json['isAllDay'] == true,
      );
}
