import 'package:equatable/equatable.dart';

/// Represents aggregate system security posture metrics for the Administrator Portal.
///
/// Calculated dynamically via `public.get_security_posture_summary()` in PostgreSQL.
/// Does not expose raw sensitive audit logs or private user tokens.
class SecurityPostureSummary extends Equatable {
  const SecurityPostureSummary({
    required this.postureRating,
    required this.totalAuditEvents24h,
    required this.criticalEvents24h,
    required this.warningEvents24h,
    required this.infoEvents24h,
    required this.totalAuditEventsAllTime,
    required this.activeAdministrators,
    required this.totalSystemUsers,
    required this.rlsTablesProtected,
    required this.totalPublicTables,
    required this.auditLogImmutability,
    required this.roleEscalationGuard,
    required this.petOwnerSpoofingGuard,
    required this.refreshedAt,
  });

  /// Overall posture rating: 'OPTIMAL', 'MONITORING', 'ELEVATED_RISK', 'CRITICAL'.
  final String postureRating;

  /// Audit events logged in the last 24 hours.
  final int totalAuditEvents24h;

  /// Critical severity audit events in the last 24 hours.
  final int criticalEvents24h;

  /// Warning severity audit events in the last 24 hours.
  final int warningEvents24h;

  /// Info severity audit events in the last 24 hours.
  final int infoEvents24h;

  /// Cumulative total audit trail count.
  final int totalAuditEventsAllTime;

  /// Count of active administrators in `public.profiles`.
  final int activeAdministrators;

  /// Total user profiles in `public.profiles`.
  final int totalSystemUsers;

  /// Number of public tables with RLS enabled.
  final int rlsTablesProtected;

  /// Total public schema tables.
  final int totalPublicTables;

  /// Immutability trigger status ('ENFORCED').
  final String auditLogImmutability;

  /// Role escalation prevention trigger status ('ENFORCED').
  final String roleEscalationGuard;

  /// Anti-spoofing trigger status ('ENFORCED').
  final String petOwnerSpoofingGuard;

  /// Snapshot generation timestamp.
  final DateTime refreshedAt;

  @override
  List<Object?> get props => [
    postureRating,
    totalAuditEvents24h,
    criticalEvents24h,
    warningEvents24h,
    infoEvents24h,
    totalAuditEventsAllTime,
    activeAdministrators,
    totalSystemUsers,
    rlsTablesProtected,
    totalPublicTables,
    auditLogImmutability,
    roleEscalationGuard,
    petOwnerSpoofingGuard,
    refreshedAt,
  ];
}
