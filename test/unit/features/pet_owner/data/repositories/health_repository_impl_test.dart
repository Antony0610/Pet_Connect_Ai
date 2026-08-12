import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/features/pet_owner/data/datasources/health_remote_datasource.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/health_record_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/health_timeline_event_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_weight_log_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/treatment_plan_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/vaccination_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/repositories/health_repository_impl.dart';

class MockHealthRemoteDataSource extends Mock implements HealthRemoteDataSource {}

void main() {
  late MockHealthRemoteDataSource mockRemote;
  late HealthRepositoryImpl repository;

  final now = DateTime(2026, 8, 12);
  final tRecord = HealthRecordModel(
    id: 'rec-1',
    petId: 'pet-1',
    recordDate: now,
    category: 'Checkup',
    title: 'Annual Checkup',
    createdAt: now,
    updatedAt: now,
  );
  final tVaccination = VaccinationModel(
    id: 'vac-1',
    petId: 'pet-1',
    vaccineName: 'Rabies',
    administeredDate: now,
    createdAt: now,
    updatedAt: now,
  );
  final tEvent = HealthTimelineEventModel(
    id: 'evt-1',
    petId: 'pet-1',
    eventDate: now,
    category: 'Medical',
    title: 'Checkup',
    createdAt: now,
  );
  final tWeight = PetWeightLogModel(
    id: 'w-1',
    petId: 'pet-1',
    recordedAt: now,
    weightKg: 12.5,
    createdAt: now,
  );
  final tPlan = TreatmentPlanModel(
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
    mockRemote = MockHealthRemoteDataSource();
    repository = HealthRepositoryImpl(mockRemote);
  });

  group('HealthRepositoryImpl Unit Tests', () {
    test('getHealthRecords returns Right(List<HealthRecord>) on success', () async {
      when(() => mockRemote.getHealthRecords('pet-1'))
          .thenAnswer((_) async => [tRecord]);

      final result = await repository.getHealthRecords('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (records) => expect(records, [tRecord]),
      );
      verify(() => mockRemote.getHealthRecords('pet-1')).called(1);
    });

    test('getHealthRecords returns Left(ServerFailure) on exception', () async {
      when(() => mockRemote.getHealthRecords('pet-1'))
          .thenThrow(const ServerException('Database error'));

      final result = await repository.getHealthRecords('pet-1');
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should be left'),
      );
    });

    test('getVaccinations returns Right(List<Vaccination>) on success', () async {
      when(() => mockRemote.getVaccinations('pet-1'))
          .thenAnswer((_) async => [tVaccination]);

      final result = await repository.getVaccinations('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (list) => expect(list, [tVaccination]),
      );
    });

    test('getTimelineEvents returns Right(List<HealthTimelineEvent>) on success', () async {
      when(() => mockRemote.getTimelineEvents('pet-1'))
          .thenAnswer((_) async => [tEvent]);

      final result = await repository.getTimelineEvents('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (events) => expect(events, [tEvent]),
      );
    });

    test('getWeightLogs returns Right(List<PetWeightLog>) on success', () async {
      when(() => mockRemote.getWeightLogs('pet-1'))
          .thenAnswer((_) async => [tWeight]);

      final result = await repository.getWeightLogs('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (logs) => expect(logs, [tWeight]),
      );
    });

    test('getTreatmentPlans returns Right(List<TreatmentPlan>) on success', () async {
      when(() => mockRemote.getTreatmentPlans('pet-1'))
          .thenAnswer((_) async => [tPlan]);

      final result = await repository.getTreatmentPlans('pet-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should be right'),
        (plans) => expect(plans, [tPlan]),
      );
    });
  });
}
