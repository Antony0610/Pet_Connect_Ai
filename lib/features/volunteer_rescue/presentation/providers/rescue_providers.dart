import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/datasources/rescue_remote_datasource.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/lost_pet_sighting_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/repositories/rescue_repository_impl.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_sighting.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_mission.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_shelter.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/volunteer_responder.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/repositories/rescue_repository.dart';

final rescueRemoteDataSourceProvider = Provider<RescueRemoteDataSource>((ref) {
  return RescueRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final rescueRepositoryProvider = Provider<RescueRepository>((ref) {
  return RescueRepositoryImpl(ref.watch(rescueRemoteDataSourceProvider));
});

final activeLostPetAlertsProvider = FutureProvider<List<LostPetAlert>>((
  ref,
) async {
  final repo = ref.watch(rescueRepositoryProvider);
  final result = await repo.getActiveLostPetAlerts();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (alerts) => alerts,
  );
});

final rescueMissionsProvider =
    FutureProvider.family<List<RescueMission>, String?>((ref, status) async {
      final repo = ref.watch(rescueRepositoryProvider);
      final result = await repo.getRescueMissions(status: status);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (missions) => missions,
      );
    });

final sightingsProvider = FutureProvider.family<List<LostPetSighting>, String>((
  ref,
  alertId,
) async {
  final repo = ref.watch(rescueRepositoryProvider);
  final result = await repo.getSightingsForAlert(alertId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (sightings) => sightings,
  );
});

final allCommunitySightingsProvider = FutureProvider<List<LostPetSighting>>((ref) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final response = await client
        .from('lost_pet_sightings')
        .select('*')
        .order('sighting_time', ascending: false)
        .limit(30);
    return (response as List).map((json) => LostPetSightingModel.fromJson(json as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

final rescueSheltersProvider = FutureProvider<List<RescueShelter>>((
  ref,
) async {
  final repo = ref.watch(rescueRepositoryProvider);
  final result = await repo.getShelters();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (shelters) => shelters,
  );
});

final volunteerRespondersProvider = FutureProvider<List<VolunteerResponder>>((
  ref,
) async {
  final repo = ref.watch(rescueRepositoryProvider);
  final result = await repo.getVolunteers();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (responders) => responders,
  );
});

/// Tracks current volunteer user's duty toggle state.
final volunteerDutyStatusProvider = StateProvider<bool>((ref) => true);

/// Real GPS Haversine Distance Calculation (in Kilometers)
double calculateDistanceKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const p = 0.017453292519943295; // Math.PI / 180
  final a = 0.5 -
      math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) *
          math.cos(lat2 * p) *
          (1 - math.cos((lon2 - lon1) * p)) /
          2;
  return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
}
