import 'package:dartz/dartz.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/realtime/data/datasources/realtime_remote_datasource.dart';
import 'package:petconnect_ai/features/realtime/data/models/direct_message_model.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/direct_message.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/user_notification.dart';
import 'package:petconnect_ai/features/realtime/domain/repositories/realtime_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeRepositoryImpl implements RealtimeRepository {
  const RealtimeRepositoryImpl(this._remote, this._client);

  final RealtimeRemoteDataSource _remote;
  final SupabaseClient _client;

  String get _currentUserId => _client.auth.currentUser?.id ?? '';

  @override
  ResultFuture<List<DirectMessage>> getDirectMessages(
    String otherUserId,
  ) async {
    try {
      final list = await _remote.getDirectMessages(_currentUserId, otherUserId);
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<DirectMessage> sendDirectMessage({
    required String receiverId,
    required String text,
  }) async {
    try {
      final model = DirectMessageModel(
        id: '',
        senderId: _currentUserId,
        receiverId: receiverId,
        messageText: text,
        createdAt: DateTime.now().toUtc(),
      );
      final sent = await _remote.sendDirectMessage(model);
      return Right(sent);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  Stream<DirectMessage> subscribeToDirectMessages(String otherUserId) {
    return _remote.subscribeToDirectMessages(_currentUserId, otherUserId);
  }

  @override
  ResultFuture<List<UserNotification>> getUserNotifications() async {
    try {
      final list = await _remote.getUserNotifications(_currentUserId);
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  Stream<UserNotification> subscribeToNotifications() {
    return _remote.subscribeToNotifications(_currentUserId);
  }

  @override
  ResultFuture<void> markNotificationRead(String notificationId) async {
    try {
      await _remote.markNotificationRead(notificationId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<int> markAllNotificationsRead() async {
    try {
      final count = await _remote.markAllNotificationsRead();
      return Right(count);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }
}
