import 'package:petconnect_ai/features/veterinarian/domain/entities/clinic_analytics_summary.dart';

/// DTO for `vw_clinic_analytics` rows returned from Supabase.
class ClinicAnalyticsSummaryModel extends ClinicAnalyticsSummary {
  const ClinicAnalyticsSummaryModel({
    required super.clinicId,
    required super.clinicName,
    required super.reportMonth,
    required super.totalAppointments,
    required super.completedAppointments,
    required super.cancelledAppointments,
    required super.avgDurationMinutes,
    required super.totalConsultations,
    required super.totalPrescriptions,
    required super.totalVaccinations,
    required super.uniquePatients,
    required super.refreshedAt,
  });

  factory ClinicAnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    return ClinicAnalyticsSummaryModel(
      clinicId: json['clinic_id'] as String,
      clinicName: json['clinic_name'] as String,
      reportMonth: DateTime.parse(json['report_month'] as String),
      totalAppointments: (json['total_appointments'] as num).toInt(),
      completedAppointments: (json['completed_appointments'] as num).toInt(),
      cancelledAppointments: (json['cancelled_appointments'] as num).toInt(),
      avgDurationMinutes:
          (json['avg_duration_minutes'] as num?)?.toDouble() ?? 0.0,
      totalConsultations: (json['total_consultations'] as num).toInt(),
      totalPrescriptions: (json['total_prescriptions'] as num).toInt(),
      totalVaccinations: (json['total_vaccinations'] as num).toInt(),
      uniquePatients: (json['unique_patients'] as num).toInt(),
      refreshedAt: DateTime.parse(json['refreshed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_id': clinicId,
      'clinic_name': clinicName,
      'report_month': reportMonth.toIso8601String(),
      'total_appointments': totalAppointments,
      'completed_appointments': completedAppointments,
      'cancelled_appointments': cancelledAppointments,
      'avg_duration_minutes': avgDurationMinutes,
      'total_consultations': totalConsultations,
      'total_prescriptions': totalPrescriptions,
      'total_vaccinations': totalVaccinations,
      'unique_patients': uniquePatients,
      'refreshed_at': refreshedAt.toIso8601String(),
    };
  }
}
