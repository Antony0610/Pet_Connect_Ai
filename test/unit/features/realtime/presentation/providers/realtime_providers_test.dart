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

    test('userNotificationsProvider loads notifications', () async {
      when(
        () => mockRepo.getUserNotifications(),
      ).thenAnswer((_) async => Right([tNotification]));

      final container = makeContainer();
      final notifs = await container.read(userNotificationsProvider.future);

      expect(notifs, [tNotification]);
      verify(() => mockRepo.getUserNotifications()).called(1);
    });

    test('liveUserNotificationsStreamProvider emits live stream', () async {
      when(
        () => mockRepo.subscribeToNotifications(),
      ).thenAnswer((_) => Stream.value(tNotification));

      final container = makeContainer();
      final value =
          await container.read(liveUserNotificationsStreamProvider.future);

      expect(value, tNotification);
      verify(() => mockRepo.subscribeToNotifications()).called(1);
    });
  });
}
