import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/ai_services/domain/entities/ai_chat_message.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_conversation.dart';
import 'package:petconnect_ai/features/ai_services/domain/repositories/ai_repository.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';

class MockAiRepository extends Mock implements AiRepository {}

void main() {
  late MockAiRepository mockRepo;

  final now = DateTime(2026, 8, 13);

  final tConv = AiConversation(
    id: 'conv-1',
    userId: 'user-1',
    title: 'Pet Care Chat',
    createdAt: now,
    updatedAt: now,
  );

  final tMsg = AiChatMessage(
    id: 'msg-1',
    conversationId: 'conv-1',
    senderRole: 'assistant',
    messageText: 'Hello! How can I help?',
    createdAt: now,
  );

  setUp(() {
    mockRepo = MockAiRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [aiRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('AI Services Providers Unit Tests', () {
    test('aiConversationsProvider loads conversations', () async {
      when(
        () => mockRepo.getConversations(),
      ).thenAnswer((_) async => Right([tConv]));

      final container = makeContainer();
      final list = await container.read(aiConversationsProvider.future);

      expect(list, [tConv]);
      verify(() => mockRepo.getConversations()).called(1);
    });

    test('aiChatMessagesProvider loads messages for conversation', () async {
      when(
        () => mockRepo.getMessages('conv-1'),
      ).thenAnswer((_) async => Right([tMsg]));

      final container = makeContainer();
      final msgs = await container.read(
        aiChatMessagesProvider('conv-1').future,
      );

      expect(msgs, [tMsg]);
      verify(() => mockRepo.getMessages('conv-1')).called(1);
    });
  });
}
