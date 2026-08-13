import 'package:flutter_test/flutter_test.dart';

import 'package:petconnect_ai/features/ai_services/data/models/ai_chat_message_model.dart';
import 'package:petconnect_ai/features/ai_services/data/models/ai_conversation_model.dart';
import 'package:petconnect_ai/features/ai_services/data/models/ai_health_scan_model.dart';

void main() {
  group('AI Models DTO Unit Tests', () {
    test('AiConversationModel parses JSON correctly', () {
      final json = {
        'id': 'conv-1',
        'user_id': 'user-1',
        'pet_id': 'pet-1',
        'title': 'Diet Advice',
        'created_at': '2026-08-13T10:00:00.000Z',
        'updated_at': '2026-08-13T10:00:00.000Z',
      };

      final model = AiConversationModel.fromJson(json);
      expect(model.id, 'conv-1');
      expect(model.userId, 'user-1');
      expect(model.petId, 'pet-1');
      expect(model.title, 'Diet Advice');
    });

    test('AiChatMessageModel parses JSON correctly', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_role': 'assistant',
        'message_text': 'Your dog is healthy.',
        'metadata': {'tokens': 45},
        'created_at': '2026-08-13T10:05:00.000Z',
      };

      final model = AiChatMessageModel.fromJson(json);
      expect(model.id, 'msg-1');
      expect(model.senderRole, 'assistant');
      expect(model.messageText, 'Your dog is healthy.');
      expect(model.metadata['tokens'], 45);
    });

    test('AiHealthScanModel parses JSON correctly', () {
      final json = {
        'id': 'scan-1',
        'user_id': 'user-1',
        'pet_id': 'pet-1',
        'symptom_description': 'Mild limping on left paw',
        'image_url': 'https://example.com/paw.jpg',
        'analysis_summary': 'Possible mild sprain.',
        'urgency_level': 'MODERATE',
        'recommendations': ['Rest for 24h', 'Schedule vet check if persistent'],
        'created_at': '2026-08-13T11:00:00.000Z',
      };

      final model = AiHealthScanModel.fromJson(json);
      expect(model.id, 'scan-1');
      expect(model.symptomDescription, 'Mild limping on left paw');
      expect(model.urgencyLevel, 'MODERATE');
      expect(model.recommendations.length, 2);
    });
  });
}
