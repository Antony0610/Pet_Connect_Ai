import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';

void main() {
  group('HealthPassportExporter Domain Entity Tests', () {
    test('Pet and related health entities construct properly for export', () {
      final now = DateTime(2026, 1, 15);

      const pet = Pet(
        id: 'pet-001',
        ownerId: 'user-001',
        name: 'Max',
        species: 'dog',
        breed: 'Golden Retriever',
        weightKg: 28.5,
        microchipId: '985141002349812',
        healthStatus: 'optimal',
      );

      const owner = UserProfile(
        id: 'user-001',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        role: AppPortal.petOwner,
      );

      final vaccination = Vaccination(
        id: 'vac-001',
        petId: 'pet-001',
        vaccineName: 'Rabies 3-Year Booster',
        administeredDate: now,
        nextDueDate: DateTime(2029, 1, 15),
        administeredBy: 'Metropolitan Veterinary Hospital',
        createdAt: now,
        updatedAt: now,
      );

      final healthRecord = HealthRecord(
        id: 'rec-001',
        petId: 'pet-001',
        title: 'Annual Comprehensive Wellness Exam',
        category: 'wellness',
        recordDate: now,
        diagnosis: 'Healthy adult canine in optimal condition',
        notes: 'Heart, lungs, teeth in great shape.',
        createdAt: now,
        updatedAt: now,
      );

      final weightLog = PetWeightLog(
        id: 'wt-001',
        petId: 'pet-001',
        weightKg: 28.5,
        recordedAt: now,
        notes: 'Optimal growth',
        createdAt: now,
      );

      expect(pet.name, equals('Max'));
      expect(owner.fullName, equals('Jane Doe'));
      expect(vaccination.vaccineName, contains('Rabies'));
      expect(healthRecord.category, equals('wellness'));
      expect(weightLog.weightKg, equals(28.5));
    });
  });
}
