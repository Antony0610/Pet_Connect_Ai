import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/realtime/data/datasources/realtime_remote_datasource.dart';
import 'package:petconnect_ai/features/realtime/data/repositories/realtime_repository_impl.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/direct_message.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/user_notification.dart';
import 'package:petconnect_ai/features/realtime/domain/repositories/realtime_repository.dart';

final realtimeRemoteDataSourceProvider = Provider<RealtimeRemoteDataSource>((
  ref,
) {
  return RealtimeRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final realtimeRepositoryProvider = Provider<RealtimeRepository>((ref) {
  return RealtimeRepositoryImpl(
    ref.watch(realtimeRemoteDataSourceProvider),
    ref.watch(supabaseClientProvider),
  );
});

final directMessagesProvider =
    FutureProvider.family<List<DirectMessage>, String>((
      ref,
      otherUserId,
    ) async {
      final repo = ref.watch(realtimeRepositoryProvider);
      final result = await repo.getDirectMessages(otherUserId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (messages) => messages,
      );
    });

final liveDirectMessagesStreamProvider =
    StreamProvider.family<DirectMessage, String>((ref, otherUserId) {
      final repo = ref.watch(realtimeRepositoryProvider);
      return repo.subscribeToDirectMessages(otherUserId);
    });

final userNotificationsProvider = FutureProvider<List<UserNotification>>((
  ref,
) async {
  final repo = ref.watch(realtimeRepositoryProvider);
  final result = await repo.getUserNotifications();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (notifications) => notifications,
  );
});

final liveUserNotificationsStreamProvider = StreamProvider<UserNotification>((
  ref,
) {
  final repo = ref.watch(realtimeRepositoryProvider);
  return repo.subscribeToNotifications();
});
