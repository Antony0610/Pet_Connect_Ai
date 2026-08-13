import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_chat_message.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_conversation.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_health_scan.dart';

/// Clean Architecture Repository contract for AI Edge Functions & Services.
abstract class AiRepository {
  /// Start a new AI conversation session or get existing ones.
  ResultFuture<List<AiConversation>> getConversations();

  /// Create a new conversation session.
  ResultFuture<AiConversation> createConversation({
    String? petId,
    String title = 'Pet Care Chat',
  });

  /// Fetch chat messages for a conversation.
  ResultFuture<List<AiChatMessage>> getMessages(String conversationId);

  /// Send prompt to `ai-assistant` Edge Function & return assistant response.
  ResultFuture<AiChatMessage> sendChatMessage({
    required String conversationId,
    required String prompt,
    String? petId,
  });

  /// Invoke `ai-symptom-scan` Edge Function for visual/textual symptom scan.
  ResultFuture<AiHealthScan> analyzeSymptoms({
    String? petId,
    required String symptomDescription,
    String? imageUrl,
  });

  /// Invoke `ai-report-generator` Edge Function for pet health summary report.
  ResultFuture<Map<String, dynamic>> generateHealthReport(String petId);
}
