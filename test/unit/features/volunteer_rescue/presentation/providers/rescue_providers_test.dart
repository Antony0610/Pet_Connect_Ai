import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/repositories/rescue_repository.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';

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

  setUp(() {
    mockRepo = MockRescueRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [rescueRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('Rescue Providers Unit Tests', () {
    test('activeLostPetAlertsProvider loads active alerts', () async {
      when(
        () => mockRepo.getActiveLostPetAlerts(),
      ).thenAnswer((_) async => Right([tAlert]));

      final container = makeContainer();
      final alerts = await container.read(activeLostPetAlertsProvider.future);

      expect(alerts, [tAlert]);
      verify(() => mockRepo.getActiveLostPetAlerts()).called(1);
    });
  });
}
