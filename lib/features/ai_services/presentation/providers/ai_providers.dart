import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/ai_services/data/datasources/ai_remote_datasource.dart';
import 'package:petconnect_ai/features/ai_services/data/repositories/ai_repository_impl.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_chat_message.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_conversation.dart';
import 'package:petconnect_ai/features/ai_services/domain/repositories/ai_repository.dart';

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  return AiRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(
    ref.watch(aiRemoteDataSourceProvider),
    ref.watch(supabaseClientProvider),
  );
});

final aiConversationsProvider = FutureProvider<List<AiConversation>>((
  ref,
) async {
  final repo = ref.watch(aiRepositoryProvider);
  final result = await repo.getConversations();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversations) => conversations,
  );
});

final aiChatMessagesProvider =
    FutureProvider.family<List<AiChatMessage>, String>((
      ref,
      conversationId,
    ) async {
      final repo = ref.watch(aiRepositoryProvider);
      final result = await repo.getMessages(conversationId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (messages) => messages,
      );
    });
