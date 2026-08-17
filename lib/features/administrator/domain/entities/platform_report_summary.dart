import 'package:equatable/equatable.dart';

/// Immutable platform-wide report summary entity.
///
/// Represents the aggregate row returned from `vw_platform_reports`
/// (the security-invoker wrapper over `mv_platform_reports`).
///
/// Access is restricted to the `administrator` role at the database level.
/// No individual user PII is exposed — only platform-level aggregate counts.
class PlatformReportSummary extends Equatable {
  const PlatformReportSummary({
    required this.reportMonth,
    required this.totalUsers,
    required this.totalPetOwners,
    required this.totalVeterinarians,
    required this.totalRescuers,
    required this.totalAdministrators,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.totalAiConversations,
    required this.totalAiScans,
    required this.totalRescueMissions,
    required this.totalLostPetAlerts,
    required this.refreshedAt,
  });

  final DateTime reportMonth;
  final int totalUsers;
  final int totalPetOwners;
  final int totalVeterinarians;
  final int totalRescuers;
  final int totalAdministrators;
  final int totalAppointments;
  final int completedAppointments;
  final int totalAiConversations;
  final int totalAiScans;
  final int totalRescueMissions;
  final int totalLostPetAlerts;
  final DateTime refreshedAt;

  @override
  List<Object?> get props => [
    reportMonth,
    totalUsers,
    totalPetOwners,
    totalVeterinarians,
    totalRescuers,
    totalAdministrators,
    totalAppointments,
    completedAppointments,
    totalAiConversations,
    totalAiScans,
    totalRescueMissions,
    totalLostPetAlerts,
    refreshedAt,
  ];
}
