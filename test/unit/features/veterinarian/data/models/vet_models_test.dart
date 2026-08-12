import 'package:flutter_test/flutter_test.dart';

import 'package:petconnect_ai/features/veterinarian/data/models/appointment_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/consultation_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/patient_queue_item_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/pharmacy_item_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/prescription_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/vet_clinic_model.dart';

void main() {
  group('Vet Models DTO Unit Tests', () {
    test('VetClinicModel parses JSON correctly', () {
      final json = {
        'id': 'clinic-1',
        'name': 'Paws & Care Vet Clinic',
        'address': '123 Main St',
        'phone': '555-0192',
        'email': 'care@paws.com',
        'license_number': 'VET-8910',
        'owner_id': 'user-1',
        'created_at': '2026-08-12T10:00:00.000Z',
        'updated_at': '2026-08-12T10:00:00.000Z',
      };

      final model = VetClinicModel.fromJson(json);
      expect(model.id, 'clinic-1');
      expect(model.name, 'Paws & Care Vet Clinic');
      expect(model.toJson()['name'], 'Paws & Care Vet Clinic');
    });

    test('AppointmentModel parses JSON correctly', () {
      final json = {
        'id': 'apt-1',
        'pet_id': 'pet-1',
        'clinic_id': 'clinic-1',
        'veterinarian_id': 'vet-1',
        'appointment_date': '2026-08-15T09:00:00.000Z',
        'duration_minutes': 30,
        'reason': 'Annual Checkup',
        'status': 'Scheduled',
        'priority': 'ROUTINE',
        'notes': 'Bring vaccination record',
        'created_at': '2026-08-12T10:00:00.000Z',
        'updated_at': '2026-08-12T10:00:00.000Z',
      };

      final model = AppointmentModel.fromJson(json);
      expect(model.reason, 'Annual Checkup');
      expect(model.status, 'Scheduled');
      expect(model.toJson()['status'], 'Scheduled');
    });

    test('ConsultationModel parses JSON correctly', () {
      final json = {
        'id': 'c-1',
        'appointment_id': 'apt-1',
        'pet_id': 'pet-1',
        'veterinarian_id': 'vet-1',
        'subjective': 'Lethargy for 2 days',
        'objective': 'Temp 38.5C',
        'assessment': 'Mild gastroenteritis',
        'plan': 'Rest & fluids',
        'consultation_date': '2026-08-15T09:30:00.000Z',
        'created_at': '2026-08-15T09:30:00.000Z',
        'updated_at': '2026-08-15T09:30:00.000Z',
      };

      final model = ConsultationModel.fromJson(json);
      expect(model.assessment, 'Mild gastroenteritis');
      expect(model.toJson()['assessment'], 'Mild gastroenteritis');
    });

    test('PrescriptionModel parses JSON correctly', () {
      final json = {
        'id': 'rx-1',
        'consultation_id': 'c-1',
        'rx_number': 'RX-9824',
        'medication_name': 'Amoxicillin',
        'dosage': '250mg',
        'frequency': 'BID',
        'duration': '7 days',
        'instructions': 'Take with food',
        'status': 'Active',
        'created_at': '2026-08-15T09:35:00.000Z',
      };

      final model = PrescriptionModel.fromJson(json);
      expect(model.medicationName, 'Amoxicillin');
      expect(model.toJson()['medication_name'], 'Amoxicillin');
    });

    test('PharmacyItemModel parses JSON correctly', () {
      final json = {
        'id': 'item-1',
        'clinic_id': 'clinic-1',
        'item_name': 'Apoquel 16mg',
        'category': 'Pharmacy',
        'sku': 'PH-1024',
        'stock_quantity': 4,
        'unit': 'units',
        'status': 'Low Stock',
        'is_critical': true,
        'created_at': '2026-08-12T10:00:00.000Z',
        'updated_at': '2026-08-12T10:00:00.000Z',
      };

      final model = PharmacyItemModel.fromJson(json);
      expect(model.itemName, 'Apoquel 16mg');
      expect(model.isCritical, isTrue);
      expect(model.toJson()['item_name'], 'Apoquel 16mg');
    });

    test('PatientQueueItemModel parses JSON correctly', () {
      final json = {
        'queue_id': 'q-1',
        'appointment_id': 'apt-1',
        'pet_id': 'pet-1',
        'pet_name': 'Buster',
        'breed_age': 'Golden Retriever • 5y',
        'priority': 'HIGH',
        'reason': 'Allergic reaction',
        'appointment_date': '2026-08-15T09:00:00.000Z',
        'status': 'Waiting',
        'veterinarian_id': 'vet-1',
        'clinic_id': 'clinic-1',
        'owner_name': 'Sarah Jenkins',
        'created_at': '2026-08-15T08:30:00.000Z',
      };

      final model = PatientQueueItemModel.fromJson(json);
      expect(model.petName, 'Buster');
      expect(model.priority, 'HIGH');
      expect(model.toJson()['pet_name'], 'Buster');
    });
  });
}
