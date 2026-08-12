import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/veterinarian/domain/entities/appointment.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/consultation.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/patient_queue_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/pharmacy_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/prescription.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_clinic.dart';
import 'package:petconnect_ai/features/veterinarian/domain/repositories/vet_repository.dart';
import 'package:petconnect_ai/features/veterinarian/domain/usecases/vet_usecases.dart';

class MockVetRepository extends Mock implements VetRepository {}

void main() {
  late MockVetRepository mockRepo;

  final now = DateTime(2026, 8, 12);
  final tClinic = VetClinic(
    id: 'clinic-1',
    name: 'Paws Clinic',
    ownerId: 'user-1',
    createdAt: now,
    updatedAt: now,
  );
  final tAppointment = Appointment(
    id: 'apt-1',
    petId: 'pet-1',
    clinicId: 'clinic-1',
    veterinarianId: 'vet-1',
    appointmentDate: now,
    reason: 'Checkup',
    createdAt: now,
    updatedAt: now,
  );
  final tConsultation = Consultation(
    id: 'c-1',
    appointmentId: 'apt-1',
    petId: 'pet-1',
    veterinarianId: 'vet-1',
    assessment: 'Healthy',
    consultationDate: now,
    createdAt: now,
    updatedAt: now,
  );
  final tPrescription = Prescription(
    id: 'rx-1',
    consultationId: 'c-1',
    rxNumber: 'RX-100',
    medicationName: 'Apoquel',
    dosage: '16mg',
    frequency: 'QD',
    duration: '10 days',
    createdAt: now,
  );
  final tPharmacy = PharmacyItem(
    id: 'item-1',
    clinicId: 'clinic-1',
    itemName: 'Apoquel',
    sku: 'SKU-1',
    createdAt: now,
    updatedAt: now,
  );
  final tQueue = PatientQueueItem(
    queueId: 'q-1',
    appointmentId: 'apt-1',
    petId: 'pet-1',
    petName: 'Buster',
    breedAge: 'Dog • 3y',
    priority: 'HIGH',
    reason: 'Fever',
    appointmentDate: now,
    status: 'Waiting',
    veterinarianId: 'vet-1',
    clinicId: 'clinic-1',
    ownerName: 'Sarah',
    createdAt: now,
  );

  setUp(() {
    mockRepo = MockVetRepository();
  });

  group('Vet UseCases Unit Tests', () {
    test('GetVetClinics delegates to repository', () async {
      when(() => mockRepo.getVetClinics()).thenAnswer((_) async => Right([tClinic]));

      final useCase = GetVetClinics(mockRepo);
      final result = await useCase();
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('Should be right'), (clinics) => expect(clinics, [tClinic]));
      verify(() => mockRepo.getVetClinics()).called(1);
    });

    test('GetAppointments delegates to repository', () async {
      when(() => mockRepo.getAppointments(vetId: 'vet-1', clinicId: null))
          .thenAnswer((_) async => Right([tAppointment]));

      final useCase = GetAppointments(mockRepo);
      final result = await useCase(vetId: 'vet-1');
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('Should be right'), (list) => expect(list, [tAppointment]));
    });

    test('GetPatientQueue delegates to repository', () async {
      when(() => mockRepo.getPatientQueue(clinicId: 'clinic-1', vetId: null))
          .thenAnswer((_) async => Right([tQueue]));

      final useCase = GetPatientQueue(mockRepo);
      final result = await useCase(clinicId: 'clinic-1');
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('Should be right'), (queue) => expect(queue, [tQueue]));
    });

    test('GetConsultationByAppointment delegates to repository', () async {
      when(() => mockRepo.getConsultationByAppointment('apt-1'))
          .thenAnswer((_) async => Right(tConsultation));

      final useCase = GetConsultationByAppointment(mockRepo);
      final result = await useCase('apt-1');
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('Should be right'), (c) => expect(c, tConsultation));
    });

    test('GetPrescriptions delegates to repository', () async {
      when(() => mockRepo.getPrescriptions('c-1'))
          .thenAnswer((_) async => Right([tPrescription]));

      final useCase = GetPrescriptions(mockRepo);
      final result = await useCase('c-1');
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('Should be right'), (list) => expect(list, [tPrescription]));
    });

    test('GetPharmacyInventory delegates to repository', () async {
      when(() => mockRepo.getPharmacyInventory('clinic-1'))
          .thenAnswer((_) async => Right([tPharmacy]));

      final useCase = GetPharmacyInventory(mockRepo);
      final result = await useCase('clinic-1');
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('Should be right'), (items) => expect(items, [tPharmacy]));
    });
  });
}
