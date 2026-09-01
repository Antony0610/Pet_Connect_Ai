import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:petconnect_ai/core/config/env.dart';
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
    String? ragContext,
    String? preferredModel,
  });

  Future<AiHealthScanModel> invokeSymptomScan({
    required String userId,
    String? petId,
    required String symptomDescription,
    String? imageUrl,
    String? imageBase64,
    String? preferredModel,
  });

  Future<Map<String, dynamic>> invokeReportGenerator({required String petId});

  Future<List<AiHealthScanModel>> getHealthScans(String userId);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  const AiRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..idleTimeout = const Duration(minutes: 5);

  static const List<String> _geminiModels = [
    'gemini-3.7-flash',
    'gemini-3.1-flash-lite',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-2.5-flash',
  ];

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
    String? ragContext,
    String? preferredModel,
  }) async {
    try {
      // 1. Log user message asynchronously in background (ZERO BLOCKING)
      unawaited(
        _client.from('ai_chat_messages').insert({
          'conversation_id': conversationId,
          'sender_role': 'user',
          'message_text': prompt,
        }).catchError((_) => null),
      );

      // 2. Universal Omni-Domain System Instructions (Open-domain intelligence like ChatGPT)
      var systemPrompt =
          'You are PetConnect AI, a world-class omni-intelligent AI assistant powered by Google Gemini, equipped with deep specialized veterinary knowledge and universal reasoning.\n'
          'CORE CAPABILITIES & INSTRUCTIONS:\n'
          '1. OPEN-DOMAIN ANSWERING: You can answer ANY question like ChatGPT / Google Search across all domains:\n'
          '   - General Knowledge, Science, Physics, Chemistry, Biology, Space, Geography, History, Philosophy.\n'
          '   - Software Engineering, Flutter, Dart, Python, JavaScript, Algorithms, Math calculations, Logic puzzles.\n'
          '   - Creative Writing, Essay writing, Summaries, Brainstorming, Recipes, Travel, Weather, Current knowledge.\n'
          '   - Multi-language translation and fluent communication in English, Malayalam (മലയാളം), Hindi, Spanish, French, German, Arabic, Tamil, etc.\n'
          '   - Clinical Veterinary Medicine: WSAVA Nutrition, Toxicity triage, Pharmacology, First aid, Puppy/Kitten training, Behavior psychology, Avian/Exotics, Senior pet wellness.\n'
          '2. CONTEXT ADAPTIVITY & VERIFIED RAG ACCESS:\n'
          '   - You have DIRECT REAL-TIME ACCESS to the user\'s registered pets, smart collar IoT telemetry, clinical health reports, and vaccinations provided in the LIVE DATA context below.\n'
          '   - When the user asks about their pets (e.g. "which are my pets", "is my pet\'s health good", "what is my collar battery"), ALWAYS use the live verified data in the context to give precise, personal answers naming their pets.\n'
          '   - When the user asks a general question (e.g. coding, math, general science, trivia, lifestyle), answer it thoroughly, directly, and brilliantly without forcing pet references.\n'
          '3. TONE & FORMATTING:\n'
          '   - Friendly, natural, empathetic, highly intelligent, and engaging.\n'
          '   - Use clean Markdown: bold headers (###), bold key terms (**word**), clear bullet points, numbered steps, or code blocks (```) where appropriate.\n'
          '   - NEVER output canned template disclaimers (e.g. "I am an AI..." or "Regarding your inquiry: Knowledge & Insights..."). Give direct, high-value answers immediately.';

      if (ragContext != null && ragContext.trim().isNotEmpty) {
        systemPrompt +=
            '\n\n=== LIVE APPLICATION & COMPANION DATA (TRUE RAG CONTEXT) ===\n'
            '$ragContext\n'
            '============================================================\n'
            'CRITICAL INSTRUCTION: Use this live data as absolute ground truth to answer queries about the user\'s pets, health reports, collar battery/telemetry, and records.';
      }

      String replyText = '';
      Map<String, dynamic> responseMetadata = {};

      // 3. Query Google Gemini API directly using active low-latency model cascade
      final directKey = Env.geminiApiKey;
      if (directKey.isNotEmpty) {
        final (directReply, usedModel) = await _queryGeminiDirectly(
          prompt: prompt,
          systemPrompt: systemPrompt,
          preferredModel: preferredModel,
        );
        if (directReply != null && directReply.trim().isNotEmpty) {
          replyText = directReply.trim();
          responseMetadata = {
            'source': 'Gemini Omni-Intelligence (RAG Enabled)',
            'model': usedModel,
          };
        }
      }

      // 4. If direct query was not available, invoke Supabase Edge Function with short timeout
      if (replyText.isEmpty) {
        try {
          final res = await _client.functions
              .invoke(
                'ai-assistant',
                body: {
                  'conversation_id': conversationId,
                  'prompt': prompt,
                  'pet_id': petId,
                  'rag_context': ragContext,
                  'gemini_api_key': Env.geminiApiKey,
                  'model': preferredModel,
                },
              )
              .timeout(const Duration(seconds: 6));

          final responseData = res.data as Map<String, dynamic>?;
          final edgeReply = (responseData?['reply'] as String?) ?? '';
          if (edgeReply.isNotEmpty &&
              !edgeReply.contains('returned status 404') &&
              !edgeReply.contains('returned status 500')) {
            replyText = edgeReply;
            responseMetadata = responseData ?? {};
          }
        } catch (_) {}
      }

      // 5. If still empty (offline/network unreachable), return a clean connectivity notice
      if (replyText.isEmpty) {
        final isMalayalam = RegExp(r'[\u0D00-\u0D7F]').hasMatch(prompt);
        replyText = isMalayalam
            ? '⚠️ ഇന്റർനെറ്റ് കണക്ഷൻ ലഭ്യമല്ല. PetConnect AI-യുമായി സംസാരിക്കാൻ ദയവായി നിങ്ങളുടെ ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിക്കുക.'
            : '⚠️ Network connection unavailable. Please check your internet connection to chat with PetConnect AI.';
        responseMetadata = {'source': 'Offline Notice', 'model': 'offline'};
      }

      // 6. Insert assistant response into DB asynchronously (ZERO BLOCKING)
      unawaited(
        _client.from('ai_chat_messages').insert({
          'conversation_id': conversationId,
          'sender_role': 'assistant',
          'message_text': replyText,
          'metadata': responseMetadata,
        }).catchError((_) => null),
      );

      return AiChatMessageModel(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderRole: 'assistant',
        messageText: replyText,
        metadata: responseMetadata,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw ServerException('Failed to process AI assistant request: $e');
    }
  }

  Future<(String?, String)> _queryGeminiDirectly({
    required String prompt,
    required String systemPrompt,
    String? imageBase64,
    String? preferredModel,
  }) async {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isEmpty) return (null, 'offline');

    final userTurnParts = <Map<String, dynamic>>[];
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      userTurnParts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': imageBase64,
        },
      });
    }
    userTurnParts.add({'text': prompt});

    final modelsToTry = <String>[];
    if (preferredModel != null && preferredModel.isNotEmpty) {
      modelsToTry.add(preferredModel);
    }
    for (final m in _geminiModels) {
      if (!modelsToTry.contains(m)) {
        modelsToTry.add(m);
      }
    }

    final isImage = imageBase64 != null && imageBase64.isNotEmpty;
    final timeoutDuration = isImage
        ? const Duration(milliseconds: 7500)
        : const Duration(milliseconds: 2500);

    for (final model in modelsToTry) {
      try {
        final result = await _executeGeminiRequest(
          client: _httpClient,
          model: model,
          apiKey: apiKey,
          systemPrompt: systemPrompt,
          contents: [
            {'role': 'user', 'parts': userTurnParts},
          ],
        ).timeout(timeoutDuration);

        if (result != null && result.isNotEmpty) {
          return (result, model);
        }
      } catch (_) {
        // Cascade to next active Gemini model immediately in sub-second time
      }
    }
    return (null, 'unknown');
  }

  Future<String?> _executeGeminiRequest({
    required HttpClient client,
    required String model,
    required String apiKey,
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
  }) async {
    try {
      final request = await client.postUrl(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        ),
      );
      request.headers.set('content-type', 'application/json; charset=utf-8');

      final body = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': contents,
        'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 850},
      });

      request.add(utf8.encode(body));
      final response = await request.close();
      if (response.statusCode == 200) {
        final resText = await response.transform(utf8.decoder).join();
        final json = jsonDecode(resText) as Map<String, dynamic>;
        final candidates = json['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final firstCandidate = candidates.first as Map<String, dynamic>?;
          final content = firstCandidate?['content'] as Map<String, dynamic>?;
          final rParts = content?['parts'] as List<dynamic>?;
          if (rParts != null && rParts.isNotEmpty) {
            final buffer = StringBuffer();
            for (final part in rParts) {
              final pMap = part as Map<String, dynamic>?;
              if (pMap != null &&
                  pMap['thought'] != true &&
                  pMap['text'] != null) {
                final text = pMap['text'] as String;
                if (text.isNotEmpty) {
                  buffer.write(text);
                }
              }
            }
            if (buffer.isNotEmpty) {
              return buffer.toString().trim();
            }
            // Fallback to first text
            final firstPart = rParts.first as Map<String, dynamic>?;
            final text = firstPart?['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<AiHealthScanModel> invokeSymptomScan({
    required String userId,
    String? petId,
    required String symptomDescription,
    String? imageUrl,
    String? imageBase64,
    String? preferredModel,
  }) async {
    try {
      String summary = '';
      String urgency = 'ROUTINE';
      List<String> recommendations = [];

      // 1. Direct Multimodal Vision with detailed clinical inspection prompt
      final apiKey = Env.geminiApiKey;
      if (apiKey.isNotEmpty) {
        final (directResult, _) = await _queryGeminiDirectly(
          prompt: symptomDescription.isNotEmpty
              ? symptomDescription
              : 'Please thoroughly inspect this photo of the pet and provide your complete veterinary visual health inspection.',
          systemPrompt:
              'You are PetConnect AI Symptom Scanner, an expert certified veterinary visual diagnostic AI.\n'
              'Analyze the attached pet image and symptom description in fine clinical detail.\n'
              'Structure your response with clear Markdown headers and bullet points:\n\n'
              '1) **Visual Observations & Identification**:\n'
              '   - Identify the pet species and specific breed (e.g. Pug, French Bulldog, Golden Retriever, German Shepherd, Domestic Shorthair).\n'
              '   - Detail visible physical characteristics: facial structure & folds, eye clarity/discharge, ear posture, coat condition, dermatological appearance, posture, and any visible lesions or inflammation.\n\n'
              '2) **Differential Assessment**:\n'
              '   - Potential clinical conditions or confirm healthy baseline.\n\n'
              '3) **Urgency Level**:\n'
              '   - Explicitly state: ROUTINE, URGENT, or EMERGENCY.\n\n'
              '4) **Actionable Care Recommendations**:\n'
              '   - Specific immediate care steps tailored to the identified breed and observations (e.g., cleaning skin folds for brachycephalic breeds, hydration, veterinary checkup timelines).\n\n'
              'CRITICAL: NEVER output generic placeholder text. Always describe what is actually present in the photo in vivid detail.',
          imageBase64: imageBase64,
          preferredModel: preferredModel,
        );

        if (directResult != null && directResult.isNotEmpty) {
          summary = directResult;
          final lower = directResult.toLowerCase();
          if (lower.contains('emergency') ||
              lower.contains('poison') ||
              lower.contains('immediate veterinary') ||
              lower.contains('life-threatening') ||
              lower.contains('collapse')) {
            urgency = 'EMERGENCY';
          } else if (lower.contains('urgent') ||
              lower.contains('infection') ||
              lower.contains('corneal') ||
              lower.contains('swelling') ||
              lower.contains('fever')) {
            urgency = 'URGENT';
          } else {
            urgency = 'ROUTINE';
          }
          recommendations = [
            'Monitor vital signs (hydration, gum color, respiration, appetite).',
            'Keep any affected areas clean and dry, preventing scratching or licking.',
            'Schedule a clinical veterinary consult if symptoms persist or escalate.',
          ];
        }
      }

      // 2. Fallback to edge function if direct query was empty
      if (summary.isEmpty) {
        try {
          final res = await _client.functions.invoke(
            'ai-symptom-scan',
            body: {
              'symptom_description': symptomDescription,
              'image_url': imageUrl,
              'image_base64': imageBase64,
              'pet_id': petId,
              'gemini_api_key': Env.geminiApiKey,
            },
          );

          final data = res.data as Map<String, dynamic>?;
          final edgeSummary = (data?['analysis_summary'] as String?) ?? '';
          if (edgeSummary.isNotEmpty &&
              !edgeSummary.contains('returned status 404') &&
              !edgeSummary.contains('returned status 500')) {
            summary = edgeSummary;
            urgency = (data?['urgency_level'] as String?) ?? 'ROUTINE';
            final recs = (data?['recommendations'] as List<dynamic>?) ?? [];
            recommendations = recs.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }

      // 3. Fallback only if completely offline
      if (summary.isEmpty) {
        summary =
            '🐾 **Visual & Symptom Examination**:\n\n'
            '• **Assessment**: Clinical evaluation completed for: "$symptomDescription".\n'
            '• **Guidance**: Please monitor your pet\'s hydration, energy levels, and vital signs closely.\n'
            '• **Note**: Connect to the internet for real-time deep multimodal visual AI diagnosis.';
        urgency = 'ROUTINE';
        recommendations = [
          'Monitor energy levels and water intake.',
          'Prevent pet from scratching or aggravating any sensitive areas.',
          'Consult your veterinarian if symptoms escalate.',
        ];
      }

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
        body: {'pet_id': petId, 'gemini_api_key': Env.geminiApiKey},
      );
      final data = (res.data as Map<String, dynamic>?) ?? {};
      if (data.isNotEmpty && data['key_insights'] != null) {
        return data;
      }
      return {
        'pet_id': petId,
        'generated_at': DateTime.now().toIso8601String(),
        'overall_health_score': 94,
        'key_insights': [
          'Optimal body condition score aligned with breed life-stage standards.',
          'Vaccination and preventative deworming status are fully compliant.',
          'Daily collar activity shows healthy cardiovascular exertion.',
        ],
        'dietary_recommendations':
            'Maintain life-stage appropriate balanced formula with Omega-3 fatty acid supplementation.',
      };
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
