import 'package:flutter_test/flutter_test.dart';

import 'package:petconnect_ai/features/administrator/data/models/admin_user_entry_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/audit_log_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/platform_setting_model.dart';

void main() {
  group('Admin Models DTO Unit Tests', () {
    test('AuditLogModel parses JSON correctly', () {
      final json = {
        'id': 'log-1',
        'actor_id': 'admin-1',
        'action': 'USER_ROLE_UPDATED',
        'resource_type': 'profiles',
        'resource_id': 'user-42',
        'severity': 'INFO',
        'metadata': {'old_role': 'pet_owner', 'new_role': 'veterinarian'},
        'created_at': '2026-08-12T14:22:01.000Z',
      };

      final model = AuditLogModel.fromJson(json);
      expect(model.id, 'log-1');
      expect(model.actorId, 'admin-1');
      expect(model.action, 'USER_ROLE_UPDATED');
      expect(model.resourceType, 'profiles');
      expect(model.resourceId, 'user-42');
      expect(model.severity, 'INFO');
      expect(model.metadata['old_role'], 'pet_owner');
      expect(model.createdAt.year, 2026);
    });

    test('AuditLogModel toJson produces correct output', () {
      final model = AuditLogModel(
        id: 'log-1',
        actorId: 'admin-1',
        action: 'USER_SUSPENDED',
        resourceType: 'profiles',
        resourceId: 'user-99',
        severity: 'WARNING',
        metadata: const {'reason': 'spam'},
        createdAt: DateTime.utc(2026, 8, 12),
      );

      final json = model.toJson();
      expect(json['actor_id'], 'admin-1');
      expect(json['action'], 'USER_SUSPENDED');
      expect(json['resource_type'], 'profiles');
      expect(json['severity'], 'WARNING');
      // id and created_at should NOT be in toJson (server-generated)
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
    });

    test('AuditLogModel defaults severity to INFO when null in JSON', () {
      final json = {
        'id': 'log-2',
        'actor_id': 'admin-2',
        'action': 'PAGE_VIEWED',
        'resource_type': 'dashboard',
        'severity': null,
        'created_at': '2026-08-12T10:00:00.000Z',
      };

      final model = AuditLogModel.fromJson(json);
      expect(model.severity, 'INFO');
    });

    test('PlatformSettingModel parses JSON correctly', () {
      final json = {
        'id': 'setting-1',
        'setting_key': 'maintenance_mode',
        'setting_value': {'enabled': false},
        'description': 'Toggle platform maintenance mode',
        'updated_by': 'admin-1',
        'created_at': '2026-08-01T00:00:00.000Z',
        'updated_at': '2026-08-12T14:00:00.000Z',
      };

      final model = PlatformSettingModel.fromJson(json);
      expect(model.id, 'setting-1');
      expect(model.settingKey, 'maintenance_mode');
      expect(model.settingValue['enabled'], false);
      expect(model.description, 'Toggle platform maintenance mode');
      expect(model.updatedBy, 'admin-1');
    });

    test('PlatformSettingModel toJson produces correct output', () {
      final model = PlatformSettingModel(
        id: 'setting-1',
        settingKey: 'app_version',
        settingValue: const {'current': '2.1.0'},
        description: 'Current app version',
        updatedBy: 'admin-1',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 8),
      );

      final json = model.toJson();
      expect(json['setting_key'], 'app_version');
      expect(
        (json['setting_value'] as Map<String, dynamic>)['current'],
        '2.1.0',
      );
      expect(json['description'], 'Current app version');
    });

    test('AdminUserEntryModel parses JSON correctly', () {
      final json = {
        'id': 'user-1',
        'full_name': 'Sarah Connor',
        'email': 'sarah@example.com',
        'role': 'administrator',
        'avatar_url': 'https://example.com/avatar.jpg',
        'created_at': '2026-01-12T00:00:00.000Z',
        'updated_at': '2026-08-12T00:00:00.000Z',
      };

      final model = AdminUserEntryModel.fromJson(json);
      expect(model.id, 'user-1');
      expect(model.fullName, 'Sarah Connor');
      expect(model.email, 'sarah@example.com');
      expect(model.role, 'administrator');
      expect(model.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('AdminUserEntryModel defaults when fields null', () {
      final json = {
        'id': 'user-2',
        'full_name': null,
        'email': null,
        'role': null,
        'avatar_url': null,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };

      final model = AdminUserEntryModel.fromJson(json);
      expect(model.fullName, 'Unknown');
      expect(model.email, isNull);
      expect(model.role, 'pet_owner');
      expect(model.avatarUrl, isNull);
    });
  });
}
