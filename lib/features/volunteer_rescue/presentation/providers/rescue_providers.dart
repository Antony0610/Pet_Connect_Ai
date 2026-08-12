import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/datasources/rescue_remote_datasource.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/repositories/rescue_repository_impl.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_sighting.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_mission.dart';
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
