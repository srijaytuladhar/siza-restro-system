enum NotificationType {
  ORDER_ACCEPTED,
  FOOD_PREPARING,
  FOOD_READY,
  ORDER_SERVED,
}

class NotificationModel {
  final int id;
  final int bookingId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.bookingId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      bookingId: json['bookingId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: _parseType(json['type'] as String?),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static NotificationType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'ORDER_ACCEPTED':
        return NotificationType.ORDER_ACCEPTED;
      case 'FOOD_PREPARING':
        return NotificationType.FOOD_PREPARING;
      case 'FOOD_READY':
        return NotificationType.FOOD_READY;
      case 'ORDER_SERVED':
        return NotificationType.ORDER_SERVED;
      default:
        return NotificationType.ORDER_ACCEPTED;
    }
  }
}
