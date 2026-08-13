import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/direct_message.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/user_notification.dart';

/// Clean Architecture Repository contract for Supabase Realtime & Messaging.
abstract class RealtimeRepository {
  /// Fetch past direct messages between active user and [otherUserId].
  ResultFuture<List<DirectMessage>> getDirectMessages(String otherUserId);

  /// Send a direct message to [receiverId].
  ResultFuture<DirectMessage> sendDirectMessage({
    required String receiverId,
    required String text,
  });

  /// Subscribe to live 1-to-1 messages with [otherUserId].
  Stream<DirectMessage> subscribeToDirectMessages(String otherUserId);

  /// Fetch user notifications.
  ResultFuture<List<UserNotification>> getUserNotifications();

  /// Subscribe to live user notifications.
  Stream<UserNotification> subscribeToNotifications();

  /// Mark notification as read.
  ResultFuture<void> markNotificationRead(String notificationId);
}
