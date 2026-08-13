import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_chat_message.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_conversation.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_health_scan.dart';
import 'package:petconnect_ai/features/ai_services/domain/repositories/ai_repository.dart';

class GetAiConversations {
  const GetAiConversations(this._repository);
  final AiRepository _repository;

  ResultFuture<List<AiConversation>> call() => _repository.getConversations();
}

class CreateAiConversation {
  const CreateAiConversation(this._repository);
  final AiRepository _repository;

  ResultFuture<AiConversation> call({
    String? petId,
    String title = 'Pet Care Chat',
  }) => _repository.createConversation(petId: petId, title: title);
}

class GetAiMessages {
  const GetAiMessages(this._repository);
  final AiRepository _repository;

  ResultFuture<List<AiChatMessage>> call(String conversationId) =>
      _repository.getMessages(conversationId);
}

class SendAiChatMessage {
  const SendAiChatMessage(this._repository);
  final AiRepository _repository;

  ResultFuture<AiChatMessage> call({
    required String conversationId,
    required String prompt,
    String? petId,
  }) => _repository.sendChatMessage(
    conversationId: conversationId,
    prompt: prompt,
    petId: petId,
  );
}

class AnalyzeSymptoms {
  const AnalyzeSymptoms(this._repository);
  final AiRepository _repository;

  ResultFuture<AiHealthScan> call({
    String? petId,
    required String symptomDescription,
    String? imageUrl,
  }) => _repository.analyzeSymptoms(
    petId: petId,
    symptomDescription: symptomDescription,
    imageUrl: imageUrl,
  );
}

class GenerateHealthReport {
  const GenerateHealthReport(this._repository);
  final AiRepository _repository;

  ResultFuture<Map<String, dynamic>> call(String petId) =>
      _repository.generateHealthReport(petId);
}
