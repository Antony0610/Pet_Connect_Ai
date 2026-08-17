import 'package:petconnect_ai/features/administrator/domain/entities/security_posture_summary.dart';

/// Data Transfer Object for [SecurityPostureSummary].
class SecurityPostureSummaryModel extends SecurityPostureSummary {
  const SecurityPostureSummaryModel({
    required super.postureRating,
    required super.totalAuditEvents24h,
    required super.criticalEvents24h,
    required super.warningEvents24h,
    required super.infoEvents24h,
    required super.totalAuditEventsAllTime,
    required super.activeAdministrators,
    required super.totalSystemUsers,
    required super.rlsTablesProtected,
    required super.totalPublicTables,
    required super.auditLogImmutability,
    required super.roleEscalationGuard,
    required super.petOwnerSpoofingGuard,
    required super.refreshedAt,
  });

  factory SecurityPostureSummaryModel.fromJson(Map<String, dynamic> json) {
    return SecurityPostureSummaryModel(
      postureRating: json['posture_rating'] as String? ?? 'OPTIMAL',
      totalAuditEvents24h: (json['total_audit_events_24h'] as num?)?.toInt() ?? 0,
      criticalEvents24h: (json['critical_events_24h'] as num?)?.toInt() ?? 0,
      warningEvents24h: (json['warning_events_24h'] as num?)?.toInt() ?? 0,
      infoEvents24h: (json['info_events_24h'] as num?)?.toInt() ?? 0,
      totalAuditEventsAllTime:
          (json['total_audit_events_all_time'] as num?)?.toInt() ?? 0,
      activeAdministrators: (json['active_administrators'] as num?)?.toInt() ?? 0,
      totalSystemUsers: (json['total_system_users'] as num?)?.toInt() ?? 0,
      rlsTablesProtected: (json['rls_tables_protected'] as num?)?.toInt() ?? 0,
      totalPublicTables: (json['total_public_tables'] as num?)?.toInt() ?? 0,
      auditLogImmutability:
          json['audit_log_immutability'] as String? ?? 'ENFORCED',
      roleEscalationGuard:
          json['role_escalation_guard'] as String? ?? 'ENFORCED',
      petOwnerSpoofingGuard:
          json['pet_owner_spoofing_guard'] as String? ?? 'ENFORCED',
      refreshedAt: json['refreshed_at'] != null
          ? DateTime.parse(json['refreshed_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posture_rating': postureRating,
      'total_audit_events_24h': totalAuditEvents24h,
      'critical_events_24h': criticalEvents24h,
      'warning_events_24h': warningEvents24h,
      'info_events_24h': infoEvents24h,
      'total_audit_events_all_time': totalAuditEventsAllTime,
      'active_administrators': activeAdministrators,
      'total_system_users': totalSystemUsers,
      'rls_tables_protected': rlsTablesProtected,
      'total_public_tables': totalPublicTables,
      'audit_log_immutability': auditLogImmutability,
      'role_escalation_guard': roleEscalationGuard,
      'pet_owner_spoofing_guard': petOwnerSpoofingGuard,
      'refreshed_at': refreshedAt.toIso8601String(),
    };
  }
}
