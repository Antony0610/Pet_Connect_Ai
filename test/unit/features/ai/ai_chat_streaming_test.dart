import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/ai_services/data/models/ai_chat_message_model.dart';
import 'package:petconnect_ai/features/ai_services/data/models/ai_health_scan_model.dart';

void main() {
  group('AI Streaming & Multimodal Models Unit Tests', () {
    test('AiChatMessageModel serializes and deserializes correctly', () {
      final now = DateTime(2026, 1, 15);
      final json = {
        'id': 'msg-123',
        'conversation_id': 'conv-456',
        'sender_role': 'assistant',
        'message_text': 'Your dog is in optimal health. Continue daily 30-minute walks.',
        'metadata': {'model': 'gemini-2.0-flash', 'source': 'Omni-Intelligence'},
        'created_at': now.toIso8601String(),
      };

      final model = AiChatMessageModel.fromJson(json);

      expect(model.id, equals('msg-123'));
      expect(model.senderRole, equals('assistant'));
      expect(model.messageText, contains('optimal health'));
      expect(model.metadata['model'], equals('gemini-2.0-flash'));
    });

    test('AiHealthScanModel handles multimodal symptom findings', () {
      final now = DateTime(2026, 1, 15);
      final json = {
        'id': 'scan-789',
        'user_id': 'user-001',
        'pet_id': 'pet-001',
        'symptom_description': 'Red skin lesion on left flank with mild itching',
        'image_url': 'https://storage.petconnect.ai/scans/lesion.jpg',
        'analysis_summary': 'Visual inspection reveals superficial contact dermatitis.',
        'urgency_level': 'MODERATE',
        'recommendations': [
          'Fit soft protective cone to stop licking',
          'Clean area with chlorhexidine wipes',
          'Book vet exam if lesion spreads'
        ],
        'created_at': now.toIso8601String(),
      };

      final model = AiHealthScanModel.fromJson(json);

      expect(model.urgencyLevel, equals('MODERATE'));
      expect(model.recommendations.length, equals(3));
      expect(model.analysisSummary, contains('superficial contact dermatitis'));
      expect(model.recommendations.first, contains('cone'));
    });

    test('Multi-image byte encoding correctly yields valid base64 payload', () {
      final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      final base64String = base64Encode(sampleBytes);

      expect(base64String, isNotEmpty);
      final decoded = base64Decode(base64String);
      expect(decoded, equals(sampleBytes));
    });
  });
}
