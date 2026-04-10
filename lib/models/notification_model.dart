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

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        timestamp: DateTime.parse(json['timestamp']),
        type: NotificationType.values.firstWhere((e) => e.name == json['type']),
        isRead: json['isRead'] == 1 || json['isRead'] == true,
      );
}
