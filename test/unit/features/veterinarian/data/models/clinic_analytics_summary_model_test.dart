import 'package:flutter_test/flutter_test.dart';

import 'package:petconnect_ai/features/veterinarian/data/models/clinic_analytics_summary_model.dart';
import 'package:petconnect_ai/features/administrator/data/models/platform_report_summary_model.dart';

void main() {
  group('Phase 11 Analytics Model Tests', () {
    // ── ClinicAnalyticsSummaryModel ─────────────────────────────────────────

    group('ClinicAnalyticsSummaryModel', () {
      final tJson = <String, dynamic>{
        'clinic_id': 'clinic-1',
        'clinic_name': 'Paws & Care Vet Clinic',
        'report_month': '2026-08-01',
        'total_appointments': 42,
        'completed_appointments': 36,
        'cancelled_appointments': 4,
        'avg_duration_minutes': 22.5,
        'total_consultations': 30,
        'total_prescriptions': 18,
        'total_vaccinations': 12,
        'unique_patients': 25,
        'refreshed_at': '2026-08-14T10:00:00.000Z',
      };

      test('fromJson parses all fields correctly', () {
        final model = ClinicAnalyticsSummaryModel.fromJson(tJson);

        expect(model.clinicId, 'clinic-1');
        expect(model.clinicName, 'Paws & Care Vet Clinic');
        expect(model.reportMonth, DateTime.parse('2026-08-01'));
        expect(model.totalAppointments, 42);
        expect(model.completedAppointments, 36);
        expect(model.cancelledAppointments, 4);
        expect(model.avgDurationMinutes, 22.5);
        expect(model.totalConsultations, 30);
        expect(model.totalPrescriptions, 18);
        expect(model.totalVaccinations, 12);
        expect(model.uniquePatients, 25);
        expect(model.refreshedAt, DateTime.parse('2026-08-14T10:00:00.000Z'));
      });

      test('toJson serializes all fields correctly', () {
        final model = ClinicAnalyticsSummaryModel.fromJson(tJson);
        final json = model.toJson();

        expect(json['clinic_id'], 'clinic-1');
        expect(json['clinic_name'], 'Paws & Care Vet Clinic');
        expect(json['total_appointments'], 42);
        expect(json['completed_appointments'], 36);
        expect(json['cancelled_appointments'], 4);
        expect(json['avg_duration_minutes'], 22.5);
        expect(json['total_consultations'], 30);
        expect(json['total_prescriptions'], 18);
        expect(json['total_vaccinations'], 12);
        expect(json['unique_patients'], 25);
      });

      test('fromJson round-trips through toJson without data loss', () {
        final original = ClinicAnalyticsSummaryModel.fromJson(tJson);
        final json2 = original.toJson();
        // Restore from toJson output (add back refreshed_at and report_month)
        final restored = ClinicAnalyticsSummaryModel.fromJson({
          ...json2,
          'report_month': tJson['report_month'],
          'refreshed_at': tJson['refreshed_at'],
        });

        expect(restored, original);
      });

      test('fromJson handles integer avg_duration_minutes', () {
        final json = {...tJson, 'avg_duration_minutes': 20};
        final model = ClinicAnalyticsSummaryModel.fromJson(json);
        expect(model.avgDurationMinutes, 20.0);
      });

      test('fromJson handles null avg_duration_minutes as 0.0', () {
        final json = {...tJson, 'avg_duration_minutes': null};
        final model = ClinicAnalyticsSummaryModel.fromJson(json);
        expect(model.avgDurationMinutes, 0.0);
      });
    });

    // ── PlatformReportSummaryModel ──────────────────────────────────────────

    group('PlatformReportSummaryModel', () {
      final tJson = <String, dynamic>{
        'report_month': '2026-08-01',
        'total_users': 500,
        'total_pet_owners': 380,
        'total_veterinarians': 75,
        'total_rescuers': 40,
        'total_administrators': 5,
        'total_appointments': 890,
        'completed_appointments': 820,
        'total_ai_conversations': 1200,
        'total_ai_scans': 450,
        'total_rescue_missions': 30,
        'total_lost_pet_alerts': 15,
        'refreshed_at': '2026-08-14T12:00:00.000Z',
      };

      test('fromJson parses all fields correctly', () {
        final model = PlatformReportSummaryModel.fromJson(tJson);

        expect(model.reportMonth, DateTime.parse('2026-08-01'));
        expect(model.totalUsers, 500);
        expect(model.totalPetOwners, 380);
        expect(model.totalVeterinarians, 75);
        expect(model.totalRescuers, 40);
        expect(model.totalAdministrators, 5);
        expect(model.totalAppointments, 890);
        expect(model.completedAppointments, 820);
        expect(model.totalAiConversations, 1200);
        expect(model.totalAiScans, 450);
        expect(model.totalRescueMissions, 30);
        expect(model.totalLostPetAlerts, 15);
        expect(model.refreshedAt, DateTime.parse('2026-08-14T12:00:00.000Z'));
      });

      test('toJson serializes all fields correctly', () {
        final model = PlatformReportSummaryModel.fromJson(tJson);
        final json = model.toJson();

        expect(json['total_users'], 500);
        expect(json['total_pet_owners'], 380);
        expect(json['total_veterinarians'], 75);
        expect(json['total_rescuers'], 40);
        expect(json['total_administrators'], 5);
        expect(json['total_appointments'], 890);
        expect(json['completed_appointments'], 820);
        expect(json['total_ai_conversations'], 1200);
        expect(json['total_ai_scans'], 450);
        expect(json['total_rescue_missions'], 30);
        expect(json['total_lost_pet_alerts'], 15);
      });

      test('fromJson round-trips through toJson without data loss', () {
        final original = PlatformReportSummaryModel.fromJson(tJson);
        final json2 = original.toJson();
        final restored = PlatformReportSummaryModel.fromJson({
          ...json2,
          'report_month': tJson['report_month'],
          'refreshed_at': tJson['refreshed_at'],
        });

        expect(restored, original);
      });

      test('fromJson handles large integer values', () {
        final json = {...tJson, 'total_ai_scans': 1200000};
        final model = PlatformReportSummaryModel.fromJson(json);
        expect(model.totalAiScans, 1200000);
      });
    });
  });
}
