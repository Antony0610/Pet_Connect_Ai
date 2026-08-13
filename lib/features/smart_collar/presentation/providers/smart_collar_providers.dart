import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/smart_collar/data/datasources/smart_collar_remote_datasource.dart';
import 'package:petconnect_ai/features/smart_collar/data/repositories/smart_collar_repository_impl.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_activity_summary.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_gps_location.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/geofence.dart';
import 'package:petconnect_ai/features/smart_collar/domain/repositories/smart_collar_repository.dart';
import 'package:petconnect_ai/features/smart_collar/domain/usecases/smart_collar_usecases.dart';

/// Provider for [SmartCollarRemoteDataSource].
final smartCollarRemoteDataSourceProvider =
    Provider<SmartCollarRemoteDataSource>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return SmartCollarRemoteDataSourceImpl(client);
    });

/// Provider for [SmartCollarRepository].
final smartCollarRepositoryProvider = Provider<SmartCollarRepository>((ref) {
  final dataSource = ref.watch(smartCollarRemoteDataSourceProvider);
  final client = ref.watch(supabaseClientProvider);
  return SmartCollarRepositoryImpl(dataSource, client);
});

// ── Use Cases ─────────────────────────────────────────────────────────────

final getRegisteredCollarsUseCaseProvider = Provider<GetRegisteredCollars>((
  ref,
) {
  return GetRegisteredCollars(ref.watch(smartCollarRepositoryProvider));
});

final registerCollarUseCaseProvider = Provider<RegisterCollar>((ref) {
  return RegisterCollar(ref.watch(smartCollarRepositoryProvider));
});

final setLostModeUseCaseProvider = Provider<SetLostMode>((ref) {
  return SetLostMode(ref.watch(smartCollarRepositoryProvider));
});

final getLatestLocationUseCaseProvider = Provider<GetLatestLocation>((ref) {
  return GetLatestLocation(ref.watch(smartCollarRepositoryProvider));
});

final getLocationHistoryUseCaseProvider = Provider<GetLocationHistory>((ref) {
  return GetLocationHistory(ref.watch(smartCollarRepositoryProvider));
});

final ingestTelemetryUseCaseProvider = Provider<IngestTelemetry>((ref) {
  return IngestTelemetry(ref.watch(smartCollarRepositoryProvider));
});

final getGeofencesUseCaseProvider = Provider<GetGeofences>((ref) {
  return GetGeofences(ref.watch(smartCollarRepositoryProvider));
});

final createGeofenceUseCaseProvider = Provider<CreateGeofence>((ref) {
  return CreateGeofence(ref.watch(smartCollarRepositoryProvider));
});

// ── Async Value Providers ──────────────────────────────────────────────────

/// Provides list of registered smart collars for current user.
final registeredCollarsProvider = FutureProvider<List<CollarDevice>>((
  ref,
) async {
  final useCase = ref.watch(getRegisteredCollarsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (collars) => collars,
  );
});

/// Provides active safety geofence zones for current user.
final geofencesProvider = FutureProvider<List<Geofence>>((ref) async {
  final useCase = ref.watch(getGeofencesUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (geofences) => geofences,
  );
});

/// Family provider for fetching location history for a given collar.
final collarLocationHistoryProvider =
    FutureProvider.family<List<CollarGpsLocation>, String>((
      ref,
      collarId,
    ) async {
      final useCase = ref.watch(getLocationHistoryUseCaseProvider);
      final result = await useCase(collarId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (history) => history,
      );
    });

/// Family provider for fetching activity summaries for a given collar.
final collarActivitySummariesProvider =
    FutureProvider.family<List<CollarActivitySummary>, String>((
      ref,
      collarId,
    ) async {
      final repo = ref.watch(smartCollarRepositoryProvider);
      final result = await repo.getActivitySummaries(collarId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (summaries) => summaries,
      );
    });

/// Stream provider for live GPS telemetry for a collar.
final liveGpsLocationStreamProvider =
    StreamProvider.family<CollarGpsLocation, String>((ref, collarId) {
      final repo = ref.watch(smartCollarRepositoryProvider);
      return repo.subscribeToGpsLocations(collarId);
    });
