import 'package:equatable/equatable.dart';

/// Immutable clinic analytics summary entity.
///
/// Represents one calendar-month aggregate row returned from
/// `vw_clinic_analytics` (the security-invoker wrapper over
/// `mv_clinic_analytics`).
///
/// **No PII is stored here** — [clinicName] is the business name of the
/// clinic, not an individual's name.
///
/// The Flutter layer sums multiple monthly rows to satisfy user-selected
/// timeframes (Last 7 Days, Last 30 Days, Last 90 Days, YTD).
/// Because the view stores monthly granularity, "Last 7 Days" approximates
/// to the current month's row; boundaries are clearly surfaced in the UI.
class ClinicAnalyticsSummary extends Equatable {
  const ClinicAnalyticsSummary({
    required this.clinicId,
    required this.clinicName,
    required this.reportMonth,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.avgDurationMinutes,
    required this.totalConsultations,
    required this.totalPrescriptions,
    required this.totalVaccinations,
    required this.uniquePatients,
    required this.refreshedAt,
  });

  final String clinicId;
  final String clinicName;
  final DateTime reportMonth;
  final int totalAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final double avgDurationMinutes;
  final int totalConsultations;
  final int totalPrescriptions;
  final int totalVaccinations;
  final int uniquePatients;
  final DateTime refreshedAt;

  @override
  List<Object?> get props => [
    clinicId,
    clinicName,
    reportMonth,
    totalAppointments,
    completedAppointments,
    cancelledAppointments,
    avgDurationMinutes,
    totalConsultations,
    totalPrescriptions,
    totalVaccinations,
    uniquePatients,
    refreshedAt,
  ];
}
