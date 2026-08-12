import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/health_repository.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';

class MockHealthRepository extends Mock implements HealthRepository {}

void main() {
  late MockHealthRepository mockRepo;

  final now = DateTime(2026, 8, 12);
  final tRecord = HealthRecord(
    id: 'rec-1',
    petId: 'pet-1',
    recordDate: now,
    category: 'Checkup',
    title: 'Routine Checkup',
    createdAt: now,
    updatedAt: now,
  );
  final tVaccination = Vaccination(
    id: 'vac-1',
    petId: 'pet-1',
    vaccineName: 'Rabies',
    administeredDate: now,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockRepo = MockHealthRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [healthRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('Health Providers Unit Tests', () {
    test('healthRecordsProvider loads health records for a pet', () async {
      when(
        () => mockRepo.getHealthRecords('pet-1'),
      ).thenAnswer((_) async => Right([tRecord]));

      final container = makeContainer();
      final records = await container.read(
        healthRecordsProvider('pet-1').future,
      );

      expect(records, [tRecord]);
      verify(() => mockRepo.getHealthRecords('pet-1')).called(1);
    });

    test('vaccinationsProvider loads vaccinations for a pet', () async {
      when(
        () => mockRepo.getVaccinations('pet-1'),
      ).thenAnswer((_) async => Right([tVaccination]));

      final container = makeContainer();
      final list = await container.read(vaccinationsProvider('pet-1').future);

      expect(list, [tVaccination]);
      verify(() => mockRepo.getVaccinations('pet-1')).called(1);
    });
  });
}
