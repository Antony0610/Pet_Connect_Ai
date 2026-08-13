import 'package:equatable/equatable.dart';

/// User notification domain entity.
class UserNotification extends Equatable {
  const UserNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.notificationType = 'SYSTEM',
    this.isRead = false,
    this.payload = const {},
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String notificationType;
  final bool isRead;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    body,
    notificationType,
    isRead,
    payload,
    createdAt,
  ];
}
