import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/datasources/rescue_remote_datasource.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/lost_pet_alert_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/lost_pet_sighting_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/rescue_mission_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/repositories/rescue_repository_impl.dart';

class MockRescueRemoteDataSource extends Mock
    implements RescueRemoteDataSource {}

void main() {
  late MockRescueRemoteDataSource mockRemote;
  late RescueRepositoryImpl repository;

  final now = DateTime(2026, 8, 12);
  final tAlert = LostPetAlertModel(
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
  final tSighting = LostPetSightingModel(
    id: 'sighting-1',
    alertId: 'alert-1',
    reporterId: 'user-2',
    sightingLocation: 'Street',
    sightingTime: now,
    createdAt: now,
  );
  final tMission = RescueMissionModel(
    id: 'mission-1',
    alertId: 'alert-1',
    missionTitle: 'Search Operation',
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockRemote = MockRescueRemoteDataSource();
    repository = RescueRepositoryImpl(mockRemote);
  });

  group('RescueRepositoryImpl Unit Tests', () {
    test(
      'getActiveLostPetAlerts returns Right(List<LostPetAlert>) on success',
      () async {
        when(
          () => mockRemote.getActiveLostPetAlerts(),
        ).thenAnswer((_) async => [tAlert]);

        final result = await repository.getActiveLostPetAlerts();
        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('Should be right'),
          (list) => expect(list, [tAlert]),
        );
        verify(() => mockRemote.getActiveLostPetAlerts()).called(1);
      },
    );

    test(
      'getActiveLostPetAlerts returns Left(ServerFailure) on exception',
      () async {
        when(
          () => mockRemote.getActiveLostPetAlerts(),
        ).thenThrow(const ServerException('Database exception'));

        final result = await repository.getActiveLostPetAlerts();
        expect(result.isLeft(), isTrue);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should be left'),
        );
      },
    );

    test(
      'getSightingsForAlert returns Right(List<LostPetSighting>) on success',
      () async {
        when(
          () => mockRemote.getSightingsForAlert('alert-1'),
        ).thenAnswer((_) async => [tSighting]);

        final result = await repository.getSightingsForAlert('alert-1');
        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('Should be right'),
          (list) => expect(list, [tSighting]),
        );
      },
    );

    test(
      'getRescueMissions returns Right(List<RescueMission>) on success',
      () async {
        when(
          () => mockRemote.getRescueMissions(status: null),
        ).thenAnswer((_) async => [tMission]);

        final result = await repository.getRescueMissions();
        expect(result.isRight(), isTrue);
        result.fold(
          (l) => fail('Should be right'),
          (list) => expect(list, [tMission]),
        );
      },
    );
  });
}
