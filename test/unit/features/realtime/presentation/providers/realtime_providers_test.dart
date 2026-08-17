import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/realtime/domain/entities/direct_message.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/user_notification.dart';
import 'package:petconnect_ai/features/realtime/domain/repositories/realtime_repository.dart';
import 'package:petconnect_ai/features/realtime/presentation/providers/realtime_providers.dart';

class MockRealtimeRepository extends Mock implements RealtimeRepository {}

void main() {
  late MockRealtimeRepository mockRepo;

  final now = DateTime(2026, 8, 13);

  final tMessage = DirectMessage(
    id: 'msg-1',
    senderId: 'user-1',
    receiverId: 'user-2',
    messageText: 'Hello!',
    createdAt: now,
  );

  final tNotification = UserNotification(
    id: 'notif-1',
    userId: 'user-1',
    title: 'Reminder',
    body: 'Vaccination due tomorrow',
    createdAt: now,
  );

  final tNotification2 = UserNotification(
    id: 'notif-2',
    userId: 'user-1',
    title: 'Sighting',
    body: 'Pet spotted nearby',
    isRead: false,
    createdAt: now,
  );

  setUp(() {
    mockRepo = MockRealtimeRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [realtimeRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('Realtime Providers Unit Tests', () {
    test('directMessagesProvider loads past messages', () async {
      when(
        () => mockRepo.getDirectMessages('user-2'),
      ).thenAnswer((_) async => Right([tMessage]));

      final container = makeContainer();
      final messages = await container.read(
        directMessagesProvider('user-2').future,
      );

      expect(messages, [tMessage]);
      verify(() => mockRepo.getDirectMessages('user-2')).called(1);
    });

    test('userNotificationsProvider loads notifications and computes unread count', () async {
      when(
        () => mockRepo.getUserNotifications(),
      ).thenAnswer((_) async => Right([tNotification, tNotification2]));

      final container = makeContainer();
      final notifs = await container.read(userNotificationsProvider.future);

      expect(notifs.length, 2);
      verify(() => mockRepo.getUserNotifications()).called(1);

      final unreadCount = container.read(unreadNotificationsCountProvider);
      expect(unreadCount, 2);
    });

    test('UserNotificationsNotifier markAllRead updates state and unread count', () async {
      when(
        () => mockRepo.getUserNotifications(),
      ).thenAnswer((_) async => Right([tNotification, tNotification2]));
      when(
        () => mockRepo.markAllNotificationsRead(),
      ).thenAnswer((_) async => const Right(2));

      final container = makeContainer();
      await container.read(userNotificationsProvider.future);

      final count = await container
          .read(userNotificationsProvider.notifier)
          .markAllRead();

      expect(count, 2);
      final unreadCount = container.read(unreadNotificationsCountProvider);
      expect(unreadCount, 0);
    });

    test('UserNotificationsNotifier addLiveNotification prepends without duplicating', () async {
      when(
        () => mockRepo.getUserNotifications(),
      ).thenAnswer((_) async => Right([tNotification]));

      final container = makeContainer();
      await container.read(userNotificationsProvider.future);

      container
          .read(userNotificationsProvider.notifier)
          .addLiveNotification(tNotification2);

      final notifs = container.read(userNotificationsProvider).value;
      expect(notifs?.length, 2);
      expect(notifs?.first.id, 'notif-2');
    });

    test('liveUserNotificationsStreamProvider emits live stream', () async {
      when(
        () => mockRepo.subscribeToNotifications(),
      ).thenAnswer((_) => Stream.value(tNotification));

      final container = makeContainer();
      final value = await container.read(
        liveUserNotificationsStreamProvider.future,
      );

      expect(value, tNotification);
      verify(() => mockRepo.subscribeToNotifications()).called(1);
    });
  });
}
