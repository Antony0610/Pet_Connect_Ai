import 'dart:async';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/features/realtime/data/models/direct_message_model.dart';
import 'package:petconnect_ai/features/realtime/data/models/user_notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RealtimeRemoteDataSource {
  Future<List<DirectMessageModel>> getDirectMessages(
    String currentUserId,
    String otherUserId,
  );

  Future<DirectMessageModel> sendDirectMessage(DirectMessageModel model);

  Stream<DirectMessageModel> subscribeToDirectMessages(
    String currentUserId,
    String otherUserId,
  );

  Future<List<UserNotificationModel>> getUserNotifications(String userId);

  Stream<UserNotificationModel> subscribeToNotifications(String userId);

  Future<void> markNotificationRead(String notificationId);

  Future<int> markAllNotificationsRead();
}

class RealtimeRemoteDataSourceImpl implements RealtimeRemoteDataSource {
  const RealtimeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<DirectMessageModel>> getDirectMessages(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final response = await _client
          .from('direct_messages')
          .select()
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)',
          )
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (json) => DirectMessageModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch direct messages: $e');
    }
  }

  @override
  Future<DirectMessageModel> sendDirectMessage(DirectMessageModel model) async {
    try {
      final response = await _client
          .from('direct_messages')
          .insert(model.toJson())
          .select()
          .single();

      return DirectMessageModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to send direct message: $e');
    }
  }

  @override
  Stream<DirectMessageModel> subscribeToDirectMessages(
    String currentUserId,
    String otherUserId,
  ) {
    final controller = StreamController<DirectMessageModel>.broadcast();

    final channel = _client
        .channel('public:direct_messages:$currentUserId:$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final senderId = newRecord['sender_id'] as String?;
            final receiverId = newRecord['receiver_id'] as String?;

            if ((senderId == currentUserId && receiverId == otherUserId) ||
                (senderId == otherUserId && receiverId == currentUserId)) {
              controller.add(DirectMessageModel.fromJson(newRecord));
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<UserNotificationModel>> getUserNotifications(
    String userId,
  ) async {
    try {
      final response = await _client
          .from('user_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      return (response as List)
          .map(
            (json) =>
                UserNotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch user notifications: $e');
    }
  }

  @override
  Stream<UserNotificationModel> subscribeToNotifications(String userId) {
    final controller = StreamController<UserNotificationModel>.broadcast();

    final channel = _client
        .channel('public:user_notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            controller.add(UserNotificationModel.fromJson(payload.newRecord));
          },
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<int> markAllNotificationsRead() async {
    try {
      final response = await _client.rpc<int>('mark_all_notifications_read');
      return response;
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to mark all notifications as read: $e');
    }
  }
}
