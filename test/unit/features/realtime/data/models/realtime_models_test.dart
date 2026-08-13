import 'package:flutter_test/flutter_test.dart';

import 'package:petconnect_ai/features/realtime/data/models/direct_message_model.dart';
import 'package:petconnect_ai/features/realtime/data/models/user_notification_model.dart';

void main() {
  group('Realtime Models DTO Unit Tests', () {
    test('DirectMessageModel parses JSON correctly', () {
      final json = {
        'id': 'msg-1',
        'sender_id': 'user-1',
        'receiver_id': 'user-2',
        'message_text': 'Hello doctor!',
        'is_read': false,
        'created_at': '2026-08-13T10:00:00.000Z',
      };

      final model = DirectMessageModel.fromJson(json);
      expect(model.id, 'msg-1');
      expect(model.senderId, 'user-1');
      expect(model.receiverId, 'user-2');
      expect(model.messageText, 'Hello doctor!');
      expect(model.isRead, false);
      expect(model.createdAt.year, 2026);
    });

    test('DirectMessageModel toJson produces valid output', () {
      final model = DirectMessageModel(
        id: 'msg-1',
        senderId: 'user-1',
        receiverId: 'user-2',
        messageText: 'Checkup complete',
        isRead: true,
        createdAt: DateTime.utc(2026, 8, 13),
      );

      final json = model.toJson();
      expect(json['sender_id'], 'user-1');
      expect(json['receiver_id'], 'user-2');
      expect(json['message_text'], 'Checkup complete');
      expect(json['is_read'], true);
    });

    test('UserNotificationModel parses JSON correctly', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'user-1',
        'title': 'Emergency Alert',
        'body': 'Lost pet in your area',
        'notification_type': 'RESCUE_ALERT',
        'is_read': false,
        'payload': {'alert_id': 'alert-99'},
        'created_at': '2026-08-13T11:00:00.000Z',
      };

      final model = UserNotificationModel.fromJson(json);
      expect(model.id, 'notif-1');
      expect(model.title, 'Emergency Alert');
      expect(model.notificationType, 'RESCUE_ALERT');
      expect(model.payload['alert_id'], 'alert-99');
    });

    test('UserNotificationModel defaults when optional fields null', () {
      final json = {
        'id': 'notif-2',
        'user_id': 'user-1',
        'title': 'System Update',
        'body': 'Maintenance scheduled',
        'notification_type': null,
        'is_read': null,
        'payload': null,
        'created_at': '2026-08-13T11:00:00.000Z',
      };

      final model = UserNotificationModel.fromJson(json);
      expect(model.notificationType, 'SYSTEM');
      expect(model.isRead, false);
      expect(model.payload, const <String, dynamic>{});
    });
  });
}
