import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/features/veterinarian/data/datasources/vet_remote_datasource.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/appointment_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/consultation_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/patient_queue_item_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/pharmacy_item_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/prescription_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/vet_clinic_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/repositories/vet_repository_impl.dart';

class MockVetRemoteDataSource extends Mock implements VetRemoteDataSource {}

void main() {
  late MockVetRemoteDataSource mockRemote;
  late VetRepositoryImpl repository;

  final now = DateTime(2026, 8, 12);
  final tClinic = VetClinicModel(
    id: 'clinic-1',
    name: 'Paws Clinic',
    ownerId: 'user-1',
    createdAt: now,
    updatedAt: now,
  );
  final tAppointment = AppointmentModel(
    id: 'apt-1',
    petId: 'pet-1',
    clinicId: 'clinic-1',
    veterinarianId: 'vet-1',
    appointmentDate: now,
    reason: 'Checkup',
    createdAt: now,
    updatedAt: now,
  );
  final tConsultation = ConsultationModel(
    id: 'c-1',
    appointmentId: 'apt-1',
    petId: 'pet-1',
    veterinarianId: 'vet-1',
    assessment: 'Healthy',
    consultationDate: now,
    createdAt: now,
    updatedAt: now,
  );
  final tPrescription = PrescriptionModel(
    id: 'rx-1',
    consultationId: 'c-1',
    rxNumber: 'RX-100',
    medicationName: 'Apoquel',
    dosage: '16mg',
    frequency: 'QD',
    duration: '10 days',
    createdAt: now,
  );
  final tPharmacy = PharmacyItemModel(
    id: 'item-1',
    clinicId: 'clinic-1',
    itemName: 'Apoquel',
    sku: 'SKU-1',
    createdAt: now,
    updatedAt: now,
  );
  final tQueue = PatientQueueItemModel(
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
    mockRemote = MockVetRemoteDataSource();
    repository = VetRepositoryImpl(mockRemote);
  });

  group('VetRepositoryImpl Unit Tests', () {
    test('getVetClinics returns Right(List<VetClinic>) on success', () async {
      when(() => mockRemote.getVetClinics()).thenAnswer((_) async => [tClinic]);

      final result = await repository.getVetClinics();
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (clinics) => expect(clinics, [tClinic]),
      );
      verify(() => mockRemote.getVetClinics()).called(1);
    });

    test('getVetClinics returns Left(ServerFailure) on exception', () async {
      when(() => mockRemote.getVetClinics())
          .thenThrow(const ServerException('Database failure'));

      final result = await repository.getVetClinics();
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should be left'),
      );
    });

    test('getAppointments returns Right(List<Appointment>) on success', () async {
      when(() => mockRemote.getAppointments(vetId: 'vet-1', clinicId: null))
          .thenAnswer((_) async => [tAppointment]);

      final result = await repository.getAppointments(vetId: 'vet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (list) => expect(list, [tAppointment]),
      );
    });

    test('getPatientQueue returns Right(List<PatientQueueItem>) on success', () async {
      when(() => mockRemote.getPatientQueue(clinicId: 'clinic-1', vetId: null))
          .thenAnswer((_) async => [tQueue]);

      final result = await repository.getPatientQueue(clinicId: 'clinic-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (queue) => expect(queue, [tQueue]),
      );
    });

    test('getConsultationByAppointment returns Right(Consultation?) on success', () async {
      when(() => mockRemote.getConsultationByAppointment('apt-1'))
          .thenAnswer((_) async => tConsultation);

      final result = await repository.getConsultationByAppointment('apt-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (consultation) => expect(consultation, tConsultation),
      );
    });

    test('getPrescriptions returns Right(List<Prescription>) on success', () async {
      when(() => mockRemote.getPrescriptions('c-1'))
          .thenAnswer((_) async => [tPrescription]);

      final result = await repository.getPrescriptions('c-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (list) => expect(list, [tPrescription]),
      );
    });

    test('getPharmacyInventory returns Right(List<PharmacyItem>) on success', () async {
      when(() => mockRemote.getPharmacyInventory('clinic-1'))
          .thenAnswer((_) async => [tPharmacy]);

      final result = await repository.getPharmacyInventory('clinic-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (items) => expect(items, [tPharmacy]),
      );
    });
  });
}
