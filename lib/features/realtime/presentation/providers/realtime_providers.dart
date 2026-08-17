import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/realtime/data/datasources/realtime_remote_datasource.dart';
import 'package:petconnect_ai/features/realtime/data/repositories/realtime_repository_impl.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/direct_message.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/user_notification.dart';
import 'package:petconnect_ai/features/realtime/domain/repositories/realtime_repository.dart';
import 'package:petconnect_ai/features/realtime/domain/usecases/realtime_usecases.dart';

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

// Use cases
final getDirectMessagesUseCaseProvider = Provider<GetDirectMessages>((ref) {
  return GetDirectMessages(ref.watch(realtimeRepositoryProvider));
});

final sendDirectMessageUseCaseProvider = Provider<SendDirectMessage>((ref) {
  return SendDirectMessage(ref.watch(realtimeRepositoryProvider));
});

final getUserNotificationsUseCaseProvider = Provider<GetUserNotifications>((
  ref,
) {
  return GetUserNotifications(ref.watch(realtimeRepositoryProvider));
});

final markNotificationReadUseCaseProvider = Provider<MarkNotificationRead>((
  ref,
) {
  return MarkNotificationRead(ref.watch(realtimeRepositoryProvider));
});

final markAllNotificationsReadUseCaseProvider =
    Provider<MarkAllNotificationsRead>((ref) {
      return MarkAllNotificationsRead(ref.watch(realtimeRepositoryProvider));
    });

// Direct Messages Providers
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

// User Notifications Providers
final userNotificationsProvider =
    AsyncNotifierProvider<UserNotificationsNotifier, List<UserNotification>>(
      UserNotificationsNotifier.new,
    );

class UserNotificationsNotifier extends AsyncNotifier<List<UserNotification>> {
  @override
  Future<List<UserNotification>> build() async {
    final repo = ref.watch(realtimeRepositoryProvider);
    final result = await repo.getUserNotifications();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (notifications) => notifications,
    );
  }

  Future<void> refreshNotifications() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(realtimeRepositoryProvider);
      final result = await repo.getUserNotifications();
      return result.fold(
        (failure) => throw Exception(failure.message),
        (notifications) => notifications,
      );
    });
  }

  void addLiveNotification(UserNotification notification) {
    state.whenData((currentList) {
      if (!currentList.any((n) => n.id == notification.id)) {
        state = AsyncValue.data([notification, ...currentList]);
      }
    });
  }

  Future<void> markRead(String notificationId) async {
    final repo = ref.read(realtimeRepositoryProvider);
    await repo.markNotificationRead(notificationId);
    state.whenData((currentList) {
      final updated =
          currentList.map((n) {
            if (n.id == notificationId) {
              return UserNotification(
                id: n.id,
                userId: n.userId,
                title: n.title,
                body: n.body,
                notificationType: n.notificationType,
                isRead: true,
                payload: n.payload,
                createdAt: n.createdAt,
              );
            }
            return n;
          }).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<int> markAllRead() async {
    final repo = ref.read(realtimeRepositoryProvider);
    final result = await repo.markAllNotificationsRead();
    return result.fold((failure) => throw Exception(failure.message), (
      count,
    ) {
      state.whenData((currentList) {
        final updated =
            currentList.map((n) {
              return UserNotification(
                id: n.id,
                userId: n.userId,
                title: n.title,
                body: n.body,
                notificationType: n.notificationType,
                isRead: true,
                payload: n.payload,
                createdAt: n.createdAt,
              );
            }).toList();
        state = AsyncValue.data(updated);
      });
      return count;
    });
  }
}

final liveUserNotificationsStreamProvider = StreamProvider<UserNotification>((
  ref,
) {
  final repo = ref.watch(realtimeRepositoryProvider);
  return repo.subscribeToNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final asyncNotifications = ref.watch(userNotificationsProvider);
  return asyncNotifications.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
