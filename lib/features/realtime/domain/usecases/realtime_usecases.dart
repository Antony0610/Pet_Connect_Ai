import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/direct_message.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/user_notification.dart';
import 'package:petconnect_ai/features/realtime/domain/repositories/realtime_repository.dart';

class GetDirectMessages {
  const GetDirectMessages(this._repository);
  final RealtimeRepository _repository;

  ResultFuture<List<DirectMessage>> call(String otherUserId) =>
      _repository.getDirectMessages(otherUserId);
}

class SendDirectMessage {
  const SendDirectMessage(this._repository);
  final RealtimeRepository _repository;

  ResultFuture<DirectMessage> call({
    required String receiverId,
    required String text,
  }) => _repository.sendDirectMessage(receiverId: receiverId, text: text);
}

class SubscribeToDirectMessages {
  const SubscribeToDirectMessages(this._repository);
  final RealtimeRepository _repository;

  Stream<DirectMessage> call(String otherUserId) =>
      _repository.subscribeToDirectMessages(otherUserId);
}

class GetUserNotifications {
  const GetUserNotifications(this._repository);
  final RealtimeRepository _repository;

  ResultFuture<List<UserNotification>> call() =>
      _repository.getUserNotifications();
}

class SubscribeToNotifications {
  const SubscribeToNotifications(this._repository);
  final RealtimeRepository _repository;

  Stream<UserNotification> call() => _repository.subscribeToNotifications();
}

class MarkNotificationRead {
  const MarkNotificationRead(this._repository);
  final RealtimeRepository _repository;

  ResultFuture<void> call(String notificationId) =>
      _repository.markNotificationRead(notificationId);
}

class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);
  final RealtimeRepository _repository;

  ResultFuture<int> call() => _repository.markAllNotificationsRead();
}
