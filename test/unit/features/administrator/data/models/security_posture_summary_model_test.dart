import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/administrator/data/models/security_posture_summary_model.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/security_posture_summary.dart';

void main() {
  final tModel = SecurityPostureSummaryModel(
    postureRating: 'OPTIMAL',
    totalAuditEvents24h: 14,
    criticalEvents24h: 0,
    warningEvents24h: 2,
    infoEvents24h: 12,
    totalAuditEventsAllTime: 120,
    activeAdministrators: 3,
    totalSystemUsers: 45,
    rlsTablesProtected: 31,
    totalPublicTables: 31,
    auditLogImmutability: 'ENFORCED',
    roleEscalationGuard: 'ENFORCED',
    petOwnerSpoofingGuard: 'ENFORCED',
    refreshedAt: DateTime.parse('2026-08-17T18:00:00.000Z'),
  );

  test('SecurityPostureSummaryModel is a subtype of SecurityPostureSummary entity', () {
    expect(tModel, isA<SecurityPostureSummary>());
  });

  test('fromJson deserializes complete JSON map correctly', () {
    final json = {
      'posture_rating': 'OPTIMAL',
      'total_audit_events_24h': 14,
      'critical_events_24h': 0,
      'warning_events_24h': 2,
      'info_events_24h': 12,
      'total_audit_events_all_time': 120,
      'active_administrators': 3,
      'total_system_users': 45,
      'rls_tables_protected': 31,
      'total_public_tables': 31,
      'audit_log_immutability': 'ENFORCED',
      'role_escalation_guard': 'ENFORCED',
      'pet_owner_spoofing_guard': 'ENFORCED',
      'refreshed_at': '2026-08-17T18:00:00.000Z',
    };

    final result = SecurityPostureSummaryModel.fromJson(json);

    expect(result.postureRating, 'OPTIMAL');
    expect(result.totalAuditEvents24h, 14);
    expect(result.criticalEvents24h, 0);
    expect(result.warningEvents24h, 2);
    expect(result.infoEvents24h, 12);
    expect(result.totalAuditEventsAllTime, 120);
    expect(result.activeAdministrators, 3);
    expect(result.totalSystemUsers, 45);
    expect(result.rlsTablesProtected, 31);
    expect(result.totalPublicTables, 31);
    expect(result.auditLogImmutability, 'ENFORCED');
    expect(result.roleEscalationGuard, 'ENFORCED');
    expect(result.petOwnerSpoofingGuard, 'ENFORCED');
  });

  test('toJson serializes model correctly', () {
    final json = tModel.toJson();

    expect(json['posture_rating'], 'OPTIMAL');
    expect(json['total_audit_events_24h'], 14);
    expect(json['critical_events_24h'], 0);
    expect(json['warning_events_24h'], 2);
    expect(json['rls_tables_protected'], 31);
  });
}
