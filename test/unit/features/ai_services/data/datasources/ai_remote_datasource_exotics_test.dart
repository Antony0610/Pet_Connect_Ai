import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/ai_services/data/datasources/ai_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  group('AI Remote Data Source - Exotic, Avian & Specialized Math Tests', () {
    late AiRemoteDataSourceImpl dataSource;

    setUp(() {
      dataSource = AiRemoteDataSourceImpl(_MockSupabaseClient());
    });

    test('1. Avian Teflon / PTFE toxic fume query returns critical bird alert', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv-1',
        prompt: 'Can I use a Teflon non-stick pan around my parrot?',
      );

      expect(msg.messageText, contains('CRITICAL AVIAN TOXICITY: PTFE / TEFLON FUMES'));
      expect(msg.messageText, contains('pulmonary edema'));
      expect(msg.messageText, contains('fresh, open outdoor air'));
    });

    test('2. Rabbit GI stasis query returns emergency lagomorph protocol', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv-2',
        prompt: 'My bunny has stopped eating and has had no poop for 14 hours, is it GI stasis?',
      );

      expect(msg.messageText, contains('CRITICAL EMERGENCY: RABBIT / SMALL PET GI STASIS'));
      expect(msg.messageText, contains('prokinetics'));
      expect(msg.messageText, contains('exotic veterinarian'));
    });

    test('3. Small pet general care returns Timothy hay and Vitamin C guidelines', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv-2b',
        prompt: 'What should I feed my pet bunny rabbit and guinea pig?',
      );

      expect(msg.messageText, contains('Small Mammal & Lagomorph Care Standards'));
      expect(msg.messageText, contains('Timothy'));
      expect(msg.messageText, contains('Vitamin C'));
    });

    test('3. Reptile UVB lighting and Metabolic Bone Disease guidance', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv-3',
        prompt: 'What UVB lighting and calcium do I need for a bearded dragon lizard?',
      );

      expect(msg.messageText, contains('Reptile Husbandry & Metabolic Health'));
      expect(msg.messageText, contains('UVB Lighting Essential'));
      expect(msg.messageText, contains('Metabolic Bone Disease'));
    });

    test('4. Equine colic emergency query returns acute horse protocol', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv-4',
        prompt: 'My horse is pawing at the ground and rolling repeatedly with colic signs',
      );

      expect(msg.messageText, contains('EQUINE EMERGENCY: ACUTE COLIC PROTOCOL'));
      expect(msg.messageText, contains('Remove all feed'));
      expect(msg.messageText, contains('equine veterinarian'));
    });

    test('5. Unit conversion kg to lbs calculates correctly', () async {
      final msg = await dataSource.invokeAiAssistant(
        conversationId: 'test-conv-5',
        prompt: 'Convert 15 kg to lbs',
      );

      expect(msg.messageText, contains('15.0 kg'));
      expect(msg.messageText, contains('33.07 lbs'));
    });
  });
}
