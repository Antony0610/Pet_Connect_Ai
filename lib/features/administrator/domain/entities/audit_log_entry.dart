import 'package:equatable/equatable.dart';

/// Immutable system audit log entry entity.
class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.action,
    required this.resourceType,
    this.resourceId,
    this.severity = 'INFO',
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String actorId;
  final String action;
  final String resourceType;
  final String? resourceId;
  final String severity;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        actorId,
        action,
        resourceType,
        resourceId,
        severity,
        metadata,
        createdAt,
      ];
}
