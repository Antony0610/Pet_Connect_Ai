import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/pet_owner/data/datasources/health_remote_datasource.dart';
import 'package:petconnect_ai/features/pet_owner/data/repositories/health_repository_impl.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_timeline_event.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/treatment_plan.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/health_repository.dart';

final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>((ref) {
  return HealthRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepositoryImpl(ref.watch(healthRemoteDataSourceProvider));
});

final healthRecordsProvider =
    FutureProvider.family<List<HealthRecord>, String>((ref, petId) async {
  final repo = ref.watch(healthRepositoryProvider);
  final result = await repo.getHealthRecords(petId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (records) => records,
  );
});

final vaccinationsProvider =
    FutureProvider.family<List<Vaccination>, String>((ref, petId) async {
  final repo = ref.watch(healthRepositoryProvider);
  final result = await repo.getVaccinations(petId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (vaccinations) => vaccinations,
  );
});

final healthTimelineEventsProvider =
    FutureProvider.family<List<HealthTimelineEvent>, String>((ref, petId) async {
  final repo = ref.watch(healthRepositoryProvider);
  final result = await repo.getTimelineEvents(petId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (events) => events,
  );
});

final petWeightLogsProvider =
    FutureProvider.family<List<PetWeightLog>, String>((ref, petId) async {
  final repo = ref.watch(healthRepositoryProvider);
  final result = await repo.getWeightLogs(petId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (logs) => logs,
  );
});

final treatmentPlansProvider =
    FutureProvider.family<List<TreatmentPlan>, String>((ref, petId) async {
  final repo = ref.watch(healthRepositoryProvider);
  final result = await repo.getTreatmentPlans(petId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (plans) => plans,
  );
});
