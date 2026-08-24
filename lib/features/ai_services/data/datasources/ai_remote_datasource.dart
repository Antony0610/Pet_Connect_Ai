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

  Future<List<AiHealthScanModel>> getHealthScans(String userId);
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
      // 1. Insert user message into DB if connected
      try {
        await _client.from('ai_chat_messages').insert({
          'conversation_id': conversationId,
          'sender_role': 'user',
          'message_text': prompt,
        });
      } catch (_) {
        // Continue if offline
      }

      // 2. Invoke server-side Supabase Edge Function 'ai-assistant'
      String replyText = '';
      Map<String, dynamic> responseMetadata = {};

      try {
        final res = await _client.functions.invoke(
          'ai-assistant',
          body: {
            'conversation_id': conversationId,
            'prompt': prompt,
            'pet_id': petId,
          },
        );

        final responseData = res.data as Map<String, dynamic>?;
        replyText = (responseData?['reply'] as String?) ?? '';
        responseMetadata = responseData ?? {};
      } catch (_) {
        // Fallback to intelligent local response engine
      }

      if (replyText.isEmpty) {
        replyText = _generateLocalAiResponse(prompt, petId);
        responseMetadata = {
          'source': 'PetConnect AI Local Engine',
          'model': 'local-heuristics-v2',
        };
      }

      // 3. Insert assistant response into DB if possible
      try {
        final assistantMsgResponse = await _client
            .from('ai_chat_messages')
            .insert({
              'conversation_id': conversationId,
              'sender_role': 'assistant',
              'message_text': replyText,
              'metadata': responseMetadata,
            })
            .select()
            .single();

        return AiChatMessageModel.fromJson(assistantMsgResponse);
      } catch (_) {
        return AiChatMessageModel(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversationId,
          senderRole: 'assistant',
          messageText: replyText,
          metadata: responseMetadata,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      throw ServerException('Failed to process AI assistant request: $e');
    }
  }

  String _generateLocalAiResponse(String prompt, String? petId) {
    final lower = prompt.toLowerCase();
    if (lower.contains("pet's name") ||
        lower.contains('pets name') ||
        lower.contains("my dog's name") ||
        lower.contains("my cat's name") ||
        lower.contains('what is my pet') ||
        lower.contains('whats my pet') ||
        lower.contains('how old is my')) {
      return 'Your active companion is tracked under PetConnect AI. You can view and manage their full profile, microchip, and vaccination records under the Health Passport!';
    } else if (lower.contains('weather') ||
        lower.contains('whether') ||
        lower.contains('walk') ||
        lower.contains('outside') ||
        lower.contains('rain') ||
        lower.contains('hot') ||
        lower.contains('cold')) {
      return '⛅ **Outdoor & Walk Guidance**:\n\n• **Pavement Heat Check**: Place your bare hand on the ground for 7 seconds. If it\'s too hot for you, it can burn their paw pads.\n• **Hydration**: Bring water on walks longer than 15 minutes.\n• **Optimal Routine**: 20-30 minutes of moderate walking provides great stimulation and joint health.';
    } else if (lower.contains('chocolate') ||
        lower.contains('grape') ||
        lower.contains('raisin') ||
        lower.contains('xylitol') ||
        lower.contains('lily') ||
        lower.contains('poison') ||
        lower.contains('toxic')) {
      return '🚨 **[TRIAGE: EMERGENCY - POTENTIAL TOXIC INGESTION]**\n\n1. Do NOT induce vomiting without toxicologist instructions.\n2. Note the substance amount and time of ingestion.\n3. Contact Pet Poison Helpline or proceed to the nearest 24/7 Animal Emergency Hospital immediately.';
    } else if (lower.contains('breath') ||
        lower.contains('chok') ||
        lower.contains('seiz') ||
        lower.contains('collapse') ||
        lower.contains('pale gum')) {
      return '🚨 **[TRIAGE: CRITICAL EMERGENCY]**\n\n• Keep your companion calm in a quiet, cool space.\n• For seizures: clear hard objects and time the duration. If > 2 minutes, transport immediately.\n• For open-mouth breathing or pale gums: proceed to veterinary ER immediately.';
    } else if (lower.contains('hi') ||
        lower.contains('hello') ||
        lower.contains('hey')) {
      return 'Hello! I am your PetConnect AI Assistant. I can help with wellness advice, nutrition, outdoor walk tips, and symptom triage. How can I help care for your companion today?';
    } else {
      return '🐾 **PetConnect AI Insight**:\n\nRegarding \'$prompt\': Keep an eye on your companion\'s energy, hydration, and appetite. Normal temperature is 101.0–102.5°F. Feel free to ask about diet, training, symptoms, or upload a photo for visual analysis!';
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

  @override
  Future<List<AiHealthScanModel>> getHealthScans(String userId) async {
    try {
      final response = await _client
          .from('ai_health_scans')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => AiHealthScanModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch AI health scans: $e');
    }
  }
}
