import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/features/ai_services/data/models/ai_chat_message_model.dart';
import 'package:petconnect_ai/features/ai_services/data/models/ai_conversation_model.dart';
import 'package:petconnect_ai/features/ai_services/data/models/ai_health_scan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AiRemoteDataSource {
  Future<List<AiConversationModel>> getConversations(String userId);

  Future<AiConversationModel> createConversation({
    required String userId,
    String? petId,
    required String title,
  });

  Future<List<AiChatMessageModel>> getMessages(String conversationId);

  Future<AiChatMessageModel> invokeAiAssistant({
    required String conversationId,
    required String prompt,
    String? petId,
  });

  Future<AiHealthScanModel> invokeSymptomScan({
    required String userId,
    String? petId,
    required String symptomDescription,
    String? imageUrl,
  });

  Future<Map<String, dynamic>> invokeReportGenerator({required String petId});
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  const AiRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AiConversationModel>> getConversations(String userId) async {
    try {
      final response = await _client
          .from('ai_conversations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) =>
                AiConversationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch AI conversations: $e');
    }
  }

  @override
  Future<AiConversationModel> createConversation({
    required String userId,
    String? petId,
    required String title,
  }) async {
    try {
      final response = await _client
          .from('ai_conversations')
          .insert({'user_id': userId, 'pet_id': petId, 'title': title})
          .select()
          .single();

      return AiConversationModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to create AI conversation: $e');
    }
  }

  @override
  Future<List<AiChatMessageModel>> getMessages(String conversationId) async {
    try {
      final response = await _client
          .from('ai_chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (json) => AiChatMessageModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch AI messages: $e');
    }
  }

  @override
  Future<AiChatMessageModel> invokeAiAssistant({
    required String conversationId,
    required String prompt,
    String? petId,
  }) async {
    try {
      // 1. Insert user message into DB
      await _client.from('ai_chat_messages').insert({
        'conversation_id': conversationId,
        'sender_role': 'user',
        'message_text': prompt,
      });

      // 2. Invoke server-side Supabase Edge Function 'ai-assistant'
      // Edge Function calls Gemini API securely without exposing keys
      final res = await _client.functions.invoke(
        'ai-assistant',
        body: {
          'conversation_id': conversationId,
          'prompt': prompt,
          'pet_id': petId,
        },
      );

      final responseData = res.data as Map<String, dynamic>?;
      final replyText =
          (responseData?['reply'] as String?) ??
          'I am your PetConnect AI assistant. How can I help care for your pet today?';

      // 3. Insert assistant response into DB
      final assistantMsgResponse = await _client
          .from('ai_chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_role': 'assistant',
            'message_text': replyText,
            'metadata': responseData ?? {},
          })
          .select()
          .single();

      return AiChatMessageModel.fromJson(assistantMsgResponse);
    } on FunctionException catch (e) {
      throw ServerException('AI Assistant Edge Function error: ${e.reason}');
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to process AI assistant request: $e');
    }
  }

  @override
  Future<AiHealthScanModel> invokeSymptomScan({
    required String userId,
    String? petId,
    required String symptomDescription,
    String? imageUrl,
  }) async {
    try {
      // Invoke server-side Supabase Edge Function 'ai-symptom-scan'
      final res = await _client.functions.invoke(
        'ai-symptom-scan',
        body: {
          'symptom_description': symptomDescription,
          'image_url': imageUrl,
          'pet_id': petId,
        },
      );

      final data = res.data as Map<String, dynamic>?;
      final summary =
          (data?['analysis_summary'] as String?) ??
          'Symptom assessment complete. Monitor closely and consult a licensed veterinarian.';
      final urgency = (data?['urgency_level'] as String?) ?? 'ROUTINE';
      final recommendations =
          (data?['recommendations'] as List<dynamic>?) ?? [];

      final record = await _client
          .from('ai_health_scans')
          .insert({
            'user_id': userId,
            'pet_id': petId,
            'symptom_description': symptomDescription,
            'image_url': imageUrl,
            'analysis_summary': summary,
            'urgency_level': urgency,
            'recommendations': recommendations,
          })
          .select()
          .single();

      return AiHealthScanModel.fromJson(record);
    } catch (e) {
      throw ServerException('Failed to analyze symptoms via AI: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> invokeReportGenerator({
    required String petId,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'ai-report-generator',
        body: {'pet_id': petId},
      );
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw ServerException('Failed to generate AI health report: $e');
    }
  }
}
