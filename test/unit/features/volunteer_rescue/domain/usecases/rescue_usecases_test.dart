import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_sighting.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_mission.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/repositories/rescue_repository.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/usecases/rescue_usecases.dart';

class MockRescueRepository extends Mock implements RescueRepository {}

void main() {
  late MockRescueRepository mockRepo;

  final now = DateTime(2026, 8, 12);
  final tAlert = LostPetAlert(
    id: 'alert-1',
    petId: 'pet-1',
    ownerId: 'owner-1',
    lastSeenLocation: 'Park',
    latitude: 40.0,
    longitude: -73.0,
    lastSeenTime: now,
    createdAt: now,
    updatedAt: now,
  );
  final tSighting = LostPetSighting(
    id: 'sighting-1',
    alertId: 'alert-1',
    reporterId: 'user-2',
    sightingLocation: 'Street',
    sightingTime: now,
    createdAt: now,
  );
  final tMission = RescueMission(
    id: 'mission-1',
    alertId: 'alert-1',
    missionTitle: 'Search Operation',
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockRepo = MockRescueRepository();
  });

  group('Rescue UseCases Unit Tests', () {
    test('GetActiveLostPetAlerts delegates to repository', () async {
      when(
        () => mockRepo.getActiveLostPetAlerts(),
      ).thenAnswer((_) async => Right([tAlert]));

      final useCase = GetActiveLostPetAlerts(mockRepo);
      final result = await useCase();
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be right'),
        (list) => expect(list, [tAlert]),
      );
      verify(() => mockRepo.getActiveLostPetAlerts()).called(1);
    });

    test('GetSightingsForAlert delegates to repository', () async {
      when(
        () => mockRepo.getSightingsForAlert('alert-1'),
      ).thenAnswer((_) async => Right([tSighting]));

      final useCase = GetSightingsForAlert(mockRepo);
      final result = await useCase('alert-1');
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be right'),
        (list) => expect(list, [tSighting]),
      );
    });

    test('GetRescueMissions delegates to repository', () async {
      when(
        () => mockRepo.getRescueMissions(status: null),
      ).thenAnswer((_) async => Right([tMission]));

      final useCase = GetRescueMissions(mockRepo);
      final result = await useCase();
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be right'),
        (list) => expect(list, [tMission]),
      );
    });
  });
}
