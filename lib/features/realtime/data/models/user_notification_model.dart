import 'package:petconnect_ai/features/realtime/domain/entities/user_notification.dart';

class UserNotificationModel extends UserNotification {
  const UserNotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    super.notificationType = 'SYSTEM',
    super.isRead = false,
    super.payload = const {},
    required super.createdAt,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      notificationType: (json['notification_type'] as String?) ?? 'SYSTEM',
      isRead: (json['is_read'] as bool?) ?? false,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      'notification_type': notificationType,
      'is_read': isRead,
      'payload': payload,
    };
  }
}
