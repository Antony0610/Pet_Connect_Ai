import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/ai_services/data/datasources/ai_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Dummy SupabaseClient for offline verification of the AI reasoning engine
class _MockSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  group('AI Features & Clinical Veterinary Intelligence Verification Tests', () {
    late AiRemoteDataSourceImpl dataSource;

    setUp(() {
      dataSource = AiRemoteDataSourceImpl(_MockSupabaseClient());
    });

    test('1. Multi-Pet Inventory query handles registered companions check', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'Which are my pets and what are their names?',
      );

      expect(msg.messageText, isNotEmpty);
      expect(msg.messageText.contains('registered') || msg.messageText.contains('Add Pet'), isTrue);
    });

    test('2. Outdoor and Weather walk safety query returns 7-second asphalt check', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'Is the weather good to take my dog for a walk outside?',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('7-Second Pavement Check'));
      expect(msg.messageText, contains('paw pads'));
      expect(msg.messageText, contains('Hydration Protocol'));
    });

    test('3. Gastrointestinal vomiting & diarrhea returns bland diet and clinical triage', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'My pet is vomiting and has diarrhea since morning',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('Clinical Assessment: Gastrointestinal Upset'));
      expect(msg.messageText, contains('Bland Diet Protocol'));
      expect(msg.messageText, contains('boiled boneless chicken breast'));
    });

    test('4. Toxic ingestion of chocolate/grapes triggers Emergency Triage Protocol', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'My dog ate dark chocolate from the table',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('[TRIAGE: EMERGENCY - POTENTIAL TOXIC INGESTION]'));
      expect(msg.messageText, contains('Do NOT induce vomiting'));
      expect(msg.messageText, contains('Pet Poison Helpline'));
    });

    test('5. Critical respiratory distress or seizures triggers Life-Support measures', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'My pet is having a seizure and having trouble breathing',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('[TRIAGE: CRITICAL LIFE-SUPPORT EMERGENCY]'));
      expect(msg.messageText, contains('Seizure Protocol'));
      expect(msg.messageText, contains('Heimlich maneuver'));
    });

    test('6. Diet and Nutrition query returns WSAVA compliant feeding guidelines', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'What is the best healthy food and treats for my dog?',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('WSAVA Nutrition Guidelines'));
      expect(msg.messageText, contains('10% Calorie Rule'));
      expect(msg.messageText, contains('Safe Healthy Treats'));
    });

    test('7. Skin rash and itching returns dermatological assessment and allergy care', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'My dog has a red skin rash and is scratching constantly',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('Dermatological & Parasite Assessment'));
      expect(msg.messageText, contains('Flea allergy dermatitis'));
      expect(msg.messageText, contains('Elizabethan'));
    });

    test('8. Eye and ear infections return ophthalmic & otic assessment', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'There is yellow discharge coming from my cat eyes and ears',
        petId: 'pet-2',
      );

      expect(msg.messageText, contains('Ophthalmic & Otic Assessment'));
      expect(msg.messageText, contains('Otitis Externa'));
    });

    test('9. Behavioral anxiety and potty training returns positive reinforcement steps', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'How to fix separation anxiety and barking when left alone?',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('Behavioral & Positive Reinforcement Guidance'));
      expect(msg.messageText, contains('Separation Anxiety'));
      expect(msg.messageText, contains('lick mats'));
    });

    test('10. Vaccines and Health Passport query returns core & lifestyle protocols', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'Which vaccines and deworming does my puppy need?',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('Preventative Health & Vaccine Protocol'));
      expect(msg.messageText, contains('Core Vaccines'));
      expect(msg.messageText, contains('DHPP'));
    });

    test('11. Senior mobility and arthritis query returns palliative care guidelines', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'My older senior dog has arthritis and is limping on stairs',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('Senior Companion & Mobility Care'));
      expect(msg.messageText, contains('Joint Support'));
      expect(msg.messageText, contains('Omega-3 EPA/DHA'));
    });

    test('12. Open-ended conversational query returns clinical guidance without rigid templates', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv',
        prompt: 'Can you give me daily care tips for my golden retriever?',
        petId: 'pet-1',
      );

      expect(msg.messageText, contains('PetConnect AI Clinical Care Guidance'));
      expect(msg.messageText, contains('101.0–102.5°F'));
    });
  });
}
