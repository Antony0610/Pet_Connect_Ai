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
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      action: json['action'] as String,
      resourceType: json['resource_type'] as String,
      resourceId: json['resource_id'] as String?,
      severity: (json['severity'] as String?) ?? 'INFO',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
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
