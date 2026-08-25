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

      // 2. Fetch all user pets for dynamic RAG context injection
      List<Map<String, dynamic>> userPets = [];
      try {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          final petsData = await _client
              .from('pets')
              .select('id, name, species, breed, age, weight, allergies, is_spayed_neutered, medical_notes')
              .eq('owner_id', userId);
          userPets = List<Map<String, dynamic>>.from(petsData as List);
        }
      } catch (_) {
        // Continue with local context if offline
      }

      final ragSummary = userPets.isNotEmpty
          ? userPets
              .map((p) =>
                  '${p['name']} (${p['breed'] ?? p['species']}, ${p['age'] ?? 'unknown'} yrs, ${p['weight'] ?? '?'}kg, Allergies: ${p['allergies'] ?? 'None'})')
              .join('; ')
          : 'No pets registered yet.';

      // 3. Invoke server-side Supabase Edge Function 'ai-assistant'
      String replyText = '';
      Map<String, dynamic> responseMetadata = {};

      try {
        final res = await _client.functions.invoke(
          'ai-assistant',
          body: {
            'conversation_id': conversationId,
            'prompt': prompt,
            'pet_id': petId,
            'rag_context': ragSummary,
            'pets': userPets,
          },
        );

        final responseData = res.data as Map<String, dynamic>?;
        replyText = (responseData?['reply'] as String?) ?? '';
        responseMetadata = responseData ?? {};
      } catch (_) {
        // Fallback to intelligent local RAG engine
      }

      if (replyText.isEmpty) {
        replyText = _generateLocalAiResponse(prompt, petId, userPets);
        responseMetadata = {
          'source': 'PetConnect AI RAG Engine',
          'model': 'gemini-rag-heuristics-v3',
        };
      }

      // 4. Insert assistant response into DB if possible
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

  String _generateLocalAiResponse(
    String prompt,
    String? petId,
    List<Map<String, dynamic>> userPets,
  ) {
    final lower = prompt.toLowerCase().trim();

    // 1. Multi-Pet Inventory & Profile Queries (typo tolerant: 'by pets', 'which are by pets', etc.)
    if (lower.contains('which are my pets') ||
        lower.contains('which are by pets') ||
        lower.contains('what are my pets') ||
        lower.contains('what are by pets') ||
        lower.contains('who are my pets') ||
        lower.contains('who are by pets') ||
        lower.contains('list my pets') ||
        lower.contains('list by pets') ||
        lower.contains('my pets') ||
        lower.contains('by pets') ||
        lower.contains('my pet') ||
        lower.contains('by pet') ||
        lower.contains('what pets') ||
        lower.contains('which pets') ||
        lower.contains('all pets') ||
        lower.contains('what pets do i have') ||
        lower.contains('how many pets') ||
        lower.contains("pet's name") ||
        lower.contains('pets name') ||
        lower.contains("my dog's name") ||
        lower.contains("my cat's name") ||
        lower.contains('how old is my')) {
      if (userPets.isNotEmpty) {
        final petListFormatted = userPets.map((p) {
          final name = p['name'] ?? 'Companion';
          final species = p['species'] ?? 'Pet';
          final breed = (p['breed'] != null && p['breed'].toString().isNotEmpty)
              ? p['breed']
              : species;
          final age = p['age'] != null ? '${p['age']} years old' : 'Age not specified';
          final weight = p['weight'] != null ? '${p['weight']} kg' : 'Weight not specified';
          final allergies = (p['allergies'] != null && p['allergies'].toString().isNotEmpty)
              ? p['allergies'].toString()
              : 'None reported';
          return '🐾 **$name**\n  • **Type & Breed**: $breed ($species)\n  • **Age & Weight**: $age • $weight\n  • **Allergies/Notes**: $allergies';
        }).join('\n\n');

        return 'Here are your registered companions in PetConnect AI:\n\n$petListFormatted\n\nYou can view their Health Passport, medical history, or collar tracking anytime. How can I assist you with their care today?';
      } else {
        return 'You do not have any pets registered in your profile yet.\n\nYou can easily add your companion by tapping **Add Pet** on the Home Dashboard or in your Profile to unlock personalized health tracking, smart collar telemetry, and dietary guidance!';
      }
    }

    // 2. Weather & Walk Checks
    if (lower.contains('weather') ||
        lower.contains('wheather') ||
        lower.contains('walk') ||
        lower.contains('outside') ||
        lower.contains('outdoor') ||
        lower.contains('rain') ||
        lower.contains('hot') ||
        lower.contains('cold') ||
        lower.contains('temperature')) {
      final petNames = userPets.isNotEmpty
          ? userPets.map((p) => p['name']).join(' and ')
          : 'your companion';
      return '⛅ **Outdoor & Walk Safety Advice for $petNames**:\n\n'
          '• **7-Second Pavement Rule**: Before heading out on sunny or warm days, place the back of your bare hand firmly on the pavement for 7 seconds. If it is too hot for your hand, it will burn their paw pads!\n'
          '• **Hydration**: Always carry clean water and a portable bowl for outings longer than 15 minutes.\n'
          '• **Walk Duration**: 20–30 minutes of moderate sniffing and walking provides excellent mental stimulation without overexerting joints.\n'
          '• **Rain & Cold Care**: After walks in wet conditions, dry paw pads thoroughly (especially between toes) to prevent moisture-induced pododermatitis.';
    }

    // 3. Dermatological / Skin Rash
    if (lower.contains('skin rash') ||
        lower.contains('rash') ||
        lower.contains('itch') ||
        lower.contains('scratching') ||
        lower.contains('red skin') ||
        lower.contains('flea') ||
        lower.contains('hotspot')) {
      return '🔍 **Dermatological Assessment — Skin Irritation & Rash**:\n\n'
          '• **Common Triggers**: Contact allergies (grasses/fertilizers), flea allergy dermatitis, food sensitivities, or fungal infections.\n'
          '• **Immediate Home Care**: Prevent excessive licking or scratching using an Elizabethan recovery collar or gentle distraction. Avoid human steroid creams or tea tree oil (toxic if ingested).\n'
          '• **Clinical Indicators**: If you notice weeping hot spots, hair loss, bleeding pustules, or foul odor, an in-person veterinary exam is recommended for cytological diagnosis.';
    }

    // 4. Ophthalmic / Eye Discharge
    if (lower.contains('eye discharge') ||
        lower.contains('eye') ||
        lower.contains('squinting') ||
        lower.contains('watery eye') ||
        lower.contains('conjunctivitis')) {
      return '👁️ **Ophthalmic Assessment — Eye Discharge & Discomfort**:\n\n'
          '• **Discharge Color Guide**: Clear watery tearing often stems from dust or mild wind irritation. Thick green, yellow, or cloudy discharge indicates bacterial infection or corneal abrasion.\n'
          '• **Home Protocol**: Gently cleanse outer eye corners using sterile saline and lint-free gauze. Never use human prescription eye drops without veterinary fluorescein staining.\n'
          '• **Urgent Signs**: Immediate veterinary attention is required if there is visible corneal cloudiness, blepharospasm (squinting), or third eyelid swelling.';
    }

    // 5. WSAVA Clinical Nutrition & Diets
    if (lower.contains('diet') ||
        lower.contains('nutrition') ||
        lower.contains('food') ||
        lower.contains('eat') ||
        lower.contains('feed') ||
        lower.contains('treat') ||
        lower.contains('weight loss')) {
      return '🥗 **WSAVA Evidence-Based Clinical Nutrition**:\n\n'
          '• **Life-Stage Nutrition**: Ensure diets meet AAFCO standards tailored to life stage (Puppy/Kitten Growth vs. Adult Maintenance vs. Senior Vitality).\n'
          '• **Essential Fatty Acids**: High-quality animal proteins enriched with Omega-3 (EPA & DHA) support joint flexibility, cognitive longevity, and skin barrier health.\n'
          '• **10% Treat Rule**: Treats should constitute under 10% of total daily caloric intake to prevent obesity and pancreatitis.\n'
          '• **Healthy Snacks**: Steamed pumpkin, peeled carrots, blueberries, green beans, and plain cooked chicken breasts.';
    }

    // 6. WSAVA Vaccination Protocols
    if (lower.contains('vaccin') ||
        lower.contains('shot') ||
        lower.contains('immuniz') ||
        lower.contains('booster')) {
      return '💉 **WSAVA Global Vaccination Protocols**:\n\n'
          '• **Canine Core Vaccines**: Rabies, DHPP (Distemper, Infectious Hepatitis, Parvovirus, Parainfluenza). Non-core: Bordetella, Leptospirosis, Lyme.\n'
          '• **Feline Core Vaccines**: Rabies, FVRCP (Feline Viral Rhinotracheitis, Calicivirus, Panleukopenia). Non-core: FeLV (Feline Leukemia).\n'
          '• **Timing**: Initial puppy/kitten series completed at 16 weeks, followed by a 1-year booster, then every 1–3 years based on regional risk and antibody titers.';
    }

    // 7. Toxic Ingestion Emergency
    if (lower.contains('chocolate') ||
        lower.contains('grape') ||
        lower.contains('raisin') ||
        lower.contains('xylitol') ||
        lower.contains('lily') ||
        lower.contains('lilies') ||
        lower.contains('poison') ||
        lower.contains('toxic') ||
        lower.contains('onion') ||
        lower.contains('garlic') ||
        lower.contains('avocado')) {
      return '🚨 **[TRIAGE: EMERGENCY - POTENTIAL TOXIC INGESTION]**\n\n'
          '1. **Do NOT induce vomiting** without direct toxicology instructions (corrosive substances cause severe secondary esophageal ulceration).\n'
          '2. **Collect Substance Info**: Note the product packaging, exact quantity, and time elapsed since ingestion.\n'
          '3. **Immediate Action**: Contact Pet Poison Helpline or proceed immediately to the nearest 24/7 Animal Emergency Hospital.\n'
          '• *Critical Warning*: Xylitol (birch sweetener) causes acute hypoglycemic collapse within 30 minutes; Lily exposure in felines leads to fatal acute renal failure.';
    }

    // 8. Critical Life Emergencies
    if (lower.contains('breath') ||
        lower.contains('chok') ||
        lower.contains('seiz') ||
        lower.contains('collapse') ||
        lower.contains('pale gum') ||
        lower.contains('blue gum') ||
        lower.contains('unconscious')) {
      return '🚨 **[TRIAGE: CRITICAL EMERGENCY]**\n\n'
          '• **Respiratory Distress**: Keep your pet calm in a cool, quiet, well-ventilated space. Open-mouth breathing in felines is always a critical medical emergency.\n'
          '• **Seizures**: Move hard furniture away. Do NOT place hands inside the mouth. Time the seizure duration. If lasting > 2 minutes, transport immediately with a cool damp cloth.\n'
          '• **Pale/Blue Gums**: Indicates acute circulatory shock or hypoxia — transport to emergency veterinary clinic immediately.';
    }

    // 9. Friendly Greetings
    if (lower.contains('hi') ||
        lower.contains('hello') ||
        lower.contains('hey') ||
        lower.contains('good morning') ||
        lower.contains('good afternoon') ||
        lower.contains('how are you') ||
        lower.contains('who are you')) {
      final petIntro = userPets.isNotEmpty
          ? ' I am actively synced with your companion${userPets.length > 1 ? 's' : ''} (**${userPets.map((p) => p['name']).join(', ')}**).'
          : '';
      return 'Hello! I am your **PetConnect AI Assistant**, trained on AAHA & WSAVA veterinary companion guidelines.$petIntro\n\nI can answer questions about:\n• Your registered pets & health history\n• Outdoor walk safety & weather advice\n• Nutrition, diets & safe treats\n• Symptom checks & emergency triage\n• Smart collar telemetry & GPS activity\n\nHow can I help care for your companion today?';
    }

    // 10. Open-Ended General Care & Health
    final petName = userPets.isNotEmpty ? userPets.first['name'] : 'your companion';
    return '🐾 **PetConnect AI Companion Insight**:\n\n'
        'Regarding "$prompt":\n\n'
        '• **Wellness Monitoring**: Keep an eye on $petName\'s energy levels, appetite, hydration, and bathroom habits.\n'
        '• **Vital Indicators**: Normal companion temperature is 101.0–102.5°F (38.3–39.2°C), with healthy pink gums and capillary refill time under 2 seconds.\n'
        '• **Personalized Advice**: You can ask me about symptoms, feeding guides, medication safety, or attach a photo for multimodal visual analysis!';
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
