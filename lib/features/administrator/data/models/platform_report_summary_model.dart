import 'package:petconnect_ai/features/administrator/domain/entities/platform_report_summary.dart';

/// DTO for `vw_platform_reports` rows returned from Supabase.
class PlatformReportSummaryModel extends PlatformReportSummary {
  const PlatformReportSummaryModel({
    required super.reportMonth,
    required super.totalUsers,
    required super.totalPetOwners,
    required super.totalVeterinarians,
    required super.totalRescuers,
    required super.totalAdministrators,
    required super.totalAppointments,
    required super.completedAppointments,
    required super.totalAiConversations,
    required super.totalAiScans,
    required super.totalRescueMissions,
    required super.totalLostPetAlerts,
    required super.refreshedAt,
  });

  factory PlatformReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return PlatformReportSummaryModel(
      reportMonth: json['report_month'] != null
          ? DateTime.tryParse(json['report_month'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      totalPetOwners: (json['total_pet_owners'] as num?)?.toInt() ?? 0,
      totalVeterinarians: (json['total_veterinarians'] as num?)?.toInt() ?? 0,
      totalRescuers: (json['total_rescuers'] as num?)?.toInt() ?? 0,
      totalAdministrators: (json['total_administrators'] as num?)?.toInt() ?? 0,
      totalAppointments: (json['total_appointments'] as num?)?.toInt() ?? 0,
      completedAppointments: (json['completed_appointments'] as num?)?.toInt() ?? 0,
      totalAiConversations: (json['total_ai_conversations'] as num?)?.toInt() ?? 0,
      totalAiScans: (json['total_ai_scans'] as num?)?.toInt() ?? 0,
      totalRescueMissions: (json['total_rescue_missions'] as num?)?.toInt() ?? 0,
      totalLostPetAlerts: (json['total_lost_pet_alerts'] as num?)?.toInt() ?? 0,
      refreshedAt: json['refreshed_at'] != null
          ? DateTime.tryParse(json['refreshed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_month': reportMonth.toIso8601String(),
      'total_users': totalUsers,
      'total_pet_owners': totalPetOwners,
      'total_veterinarians': totalVeterinarians,
      'total_rescuers': totalRescuers,
      'total_administrators': totalAdministrators,
      'total_appointments': totalAppointments,
      'completed_appointments': completedAppointments,
      'total_ai_conversations': totalAiConversations,
      'total_ai_scans': totalAiScans,
      'total_rescue_missions': totalRescueMissions,
      'total_lost_pet_alerts': totalLostPetAlerts,
      'refreshed_at': refreshedAt.toIso8601String(),
    };
  }
}
