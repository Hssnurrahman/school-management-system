enum NotificationType { approval, stock, finance, message, system }

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        description: description,
        timestamp: timestamp,
        type: type,
        isRead: isRead ?? this.isRead,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'isRead': isRead ? 1 : 0,
      };

  static DateTime _parseDate(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  static NotificationType _parseType(Object? raw) {
    if (raw == null) return NotificationType.system;
    final name = raw.toString();
    for (final t in NotificationType.values) {
      if (t.name == name) return t;
    }
    return NotificationType.system;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: (json['id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        timestamp: _parseDate(json['timestamp']),
        type: _parseType(json['type']),
        isRead: json['isRead'] == 1 || json['isRead'] == true,
      );
}
