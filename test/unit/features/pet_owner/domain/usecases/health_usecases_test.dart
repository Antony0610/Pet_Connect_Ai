import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_timeline_event.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/treatment_plan.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/health_repository.dart';
import 'package:petconnect_ai/features/pet_owner/domain/usecases/health_usecases.dart';

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
  final tEvent = HealthTimelineEvent(
    id: 'evt-1',
    petId: 'pet-1',
    eventDate: now,
    category: 'Medical',
    title: 'Checkup',
    createdAt: now,
  );
  final tWeight = PetWeightLog(
    id: 'w-1',
    petId: 'pet-1',
    recordedAt: now,
    weightKg: 12.5,
    createdAt: now,
  );
  final tPlan = TreatmentPlan(
    id: 'tp-1',
    petId: 'pet-1',
    title: 'Rehab',
    category: 'Rehab',
    progressPercent: 50,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockRepo = MockHealthRepository();
  });

  group('Health UseCases Unit Tests', () {
    test('GetHealthRecords delegates to repository', () async {
      when(
        () => mockRepo.getHealthRecords('pet-1'),
      ).thenAnswer((_) async => Right([tRecord]));

      final useCase = GetHealthRecords(mockRepo);
      final result = await useCase('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be right'),
        (records) => expect(records, [tRecord]),
      );
      verify(() => mockRepo.getHealthRecords('pet-1')).called(1);
    });

    test('GetVaccinations delegates to repository', () async {
      when(
        () => mockRepo.getVaccinations('pet-1'),
      ).thenAnswer((_) async => Right([tVaccination]));

      final useCase = GetVaccinations(mockRepo);
      final result = await useCase('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be right'),
        (list) => expect(list, [tVaccination]),
      );
    });

    test('GetHealthTimelineEvents delegates to repository', () async {
      when(
        () => mockRepo.getTimelineEvents('pet-1'),
      ).thenAnswer((_) async => Right([tEvent]));

      final useCase = GetHealthTimelineEvents(mockRepo);
      final result = await useCase('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be right'),
        (events) => expect(events, [tEvent]),
      );
    });

    test('GetPetWeightLogs delegates to repository', () async {
      when(
        () => mockRepo.getWeightLogs('pet-1'),
      ).thenAnswer((_) async => Right([tWeight]));

      final useCase = GetPetWeightLogs(mockRepo);
      final result = await useCase('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be right'),
        (logs) => expect(logs, [tWeight]),
      );
    });

    test('GetTreatmentPlans delegates to repository', () async {
      when(
        () => mockRepo.getTreatmentPlans('pet-1'),
      ).thenAnswer((_) async => Right([tPlan]));

      final useCase = GetTreatmentPlans(mockRepo);
      final result = await useCase('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be right'),
        (plans) => expect(plans, [tPlan]),
      );
    });
  });
}
