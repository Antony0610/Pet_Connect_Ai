import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';

class AuditLogModel extends AuditLogEntry {
  const AuditLogModel({
    required super.id,
    required super.actorId,
    required super.action,
    required super.resourceType,
    super.resourceId,
    super.severity = 'INFO',
    super.metadata = const {},
    required super.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] as String?) ?? 'audit-${DateTime.now().millisecondsSinceEpoch}',
      actorId: (json['actor_id'] as String?) ?? 'system',
      action: (json['action'] as String?) ?? 'SYSTEM_EVENT',
      resourceType: (json['resource_type'] as String?) ?? 'system',
      resourceId: json['resource_id'] as String?,
      severity: (json['severity'] as String?) ?? 'INFO',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actor_id': actorId,
      'action': action,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'severity': severity,
      'metadata': metadata,
    };
  }
}
