import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/veterinarian/domain/entities/appointment.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/clinic_analytics_summary.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_clinic.dart';
import 'package:petconnect_ai/features/veterinarian/domain/repositories/vet_repository.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';

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

  setUp(() {
    mockRepo = MockVetRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [vetRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('Vet Providers Unit Tests', () {
    test('vetClinicsProvider loads list of clinics', () async {
      when(
        () => mockRepo.getVetClinics(),
      ).thenAnswer((_) async => Right([tClinic]));

      final container = makeContainer();
      final clinics = await container.read(vetClinicsProvider.future);

      expect(clinics, [tClinic]);
      verify(() => mockRepo.getVetClinics()).called(1);
    });

    test('appointmentsProvider loads appointments for vet', () async {
      when(
        () => mockRepo.getAppointments(vetId: 'vet-1', clinicId: null),
      ).thenAnswer((_) async => Right([tAppointment]));

      final container = makeContainer();
      final list = await container.read(
        appointmentsProvider({'vetId': 'vet-1', 'clinicId': null}).future,
      );

      expect(list, [tAppointment]);
      verify(
        () => mockRepo.getAppointments(vetId: 'vet-1', clinicId: null),
      ).called(1);
    });

    test('vetClinicAnalyticsProvider loads clinic analytics', () async {
      final tAnalytics = ClinicAnalyticsSummary(
        clinicId: 'clinic-1',
        clinicName: 'Paws Clinic',
        reportMonth: now,
        totalAppointments: 25,
        completedAppointments: 20,
        cancelledAppointments: 2,
        avgDurationMinutes: 15.0,
        totalConsultations: 18,
        totalPrescriptions: 12,
        totalVaccinations: 8,
        uniquePatients: 15,
        refreshedAt: now,
      );

      when(
        () => mockRepo.getClinicAnalytics('clinic-1'),
      ).thenAnswer((_) async => Right([tAnalytics]));

      final container = makeContainer();
      final rows = await container.read(
        vetClinicAnalyticsProvider('clinic-1').future,
      );

      expect(rows, [tAnalytics]);
      expect(rows.first.totalAppointments, 25);
      verify(() => mockRepo.getClinicAnalytics('clinic-1')).called(1);
    });
  });
}
