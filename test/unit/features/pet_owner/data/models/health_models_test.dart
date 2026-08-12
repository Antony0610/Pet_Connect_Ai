import 'package:flutter_test/flutter_test.dart';

import 'package:petconnect_ai/features/pet_owner/data/models/health_record_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/health_timeline_event_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_weight_log_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/treatment_plan_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/vaccination_model.dart';

void main() {
  group('Health Models DTO Unit Tests', () {
    test('HealthRecordModel parses JSON correctly', () {
      final json = {
        'id': 'rec-1',
        'pet_id': 'pet-1',
        'record_date': '2026-08-10',
        'category': 'Surgery',
        'title': 'Dental Cleaning',
        'notes': 'All good',
        'diagnosis': 'Tartar build up',
        'treatment': 'Scale and polish',
        'veterinarian_name': 'Dr. Smith',
        'created_at': '2026-08-10T10:00:00.000Z',
        'updated_at': '2026-08-10T10:00:00.000Z',
      };

      final model = HealthRecordModel.fromJson(json);
      expect(model.id, 'rec-1');
      expect(model.category, 'Surgery');
      expect(model.title, 'Dental Cleaning');
      expect(model.toJson()['pet_id'], 'pet-1');
    });

    test('VaccinationModel parses JSON correctly', () {
      final json = {
        'id': 'vac-1',
        'pet_id': 'pet-1',
        'vaccine_name': 'Rabies',
        'administered_date': '2026-01-15',
        'next_due_date': '2027-01-15',
        'administered_by': 'Dr. Evans',
        'batch_number': 'B123',
        'certificate_url': 'https://cert.pdf',
        'notes': 'Annual booster',
        'is_completed': true,
        'created_at': '2026-01-15T10:00:00.000Z',
        'updated_at': '2026-01-15T10:00:00.000Z',
      };

      final model = VaccinationModel.fromJson(json);
      expect(model.vaccineName, 'Rabies');
      expect(model.isCompleted, isTrue);
      expect(model.toJson()['vaccine_name'], 'Rabies');
    });

    test('HealthTimelineEventModel parses JSON correctly', () {
      final json = {
        'id': 'evt-1',
        'pet_id': 'pet-1',
        'event_date': '2026-08-12T12:00:00.000Z',
        'category': 'Medical',
        'title': 'Routine Checkup',
        'description': 'Normal vitals',
        'metadata': {'status': 'healthy'},
        'created_at': '2026-08-12T12:00:00.000Z',
      };

      final model = HealthTimelineEventModel.fromJson(json);
      expect(model.title, 'Routine Checkup');
      expect(model.category, 'Medical');
      expect(model.toJson()['title'], 'Routine Checkup');
    });

    test('PetWeightLogModel parses JSON correctly', () {
      final json = {
        'id': 'w-1',
        'pet_id': 'pet-1',
        'recorded_at': '2026-08-01T08:00:00.000Z',
        'weight_kg': 14.5,
        'notes': 'Normal weight',
        'created_at': '2026-08-01T08:00:00.000Z',
      };

      final model = PetWeightLogModel.fromJson(json);
      expect(model.weightKg, 14.5);
      expect(model.toJson()['weight_kg'], 14.5);
    });

    test('TreatmentPlanModel parses JSON correctly', () {
      final json = {
        'id': 'tp-1',
        'pet_id': 'pet-1',
        'title': 'Knee Rehab',
        'category': 'Rehab',
        'target_date': '2026-10-30',
        'progress_percent': 65,
        'status': 'active',
        'notes': 'Daily exercise',
        'created_at': '2026-08-01T08:00:00.000Z',
        'updated_at': '2026-08-01T08:00:00.000Z',
      };

      final model = TreatmentPlanModel.fromJson(json);
      expect(model.title, 'Knee Rehab');
      expect(model.progressPercent, 65);
      expect(model.toJson()['progress_percent'], 65);
    });
  });
}
