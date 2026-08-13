import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_activity_summary.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_gps_location.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/geofence.dart';

/// Clean Architecture Repository contract for Smart Collar Telemetry & Geofencing.
abstract class SmartCollarRepository {
  /// Fetch all registered collar devices for active user.
  ResultFuture<List<CollarDevice>> getRegisteredCollars();

  /// Fetch a single collar by ID.
  ResultFuture<CollarDevice> getCollarById(String collarId);

  /// Register a new collar device.
  ResultFuture<CollarDevice> registerCollar({
    required String deviceId,
    String? petId,
  });

  /// Toggle Lost Mode for collar.
  ResultFuture<CollarDevice> setLostMode({
    required String collarId,
    required bool isLostMode,
  });

  /// Fetch latest GPS location for collar.
  ResultFuture<CollarGpsLocation?> getLatestLocation(String collarId);

  /// Fetch GPS location history for collar.
  ResultFuture<List<CollarGpsLocation>> getLocationHistory(String collarId);

  /// Ingest raw/offline GPS telemetry point.
  ResultFuture<CollarGpsLocation> ingestTelemetry({
    required String collarId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    DateTime? gpsTimestamp,
    bool isOffline = false,
  });

  /// Fetch activity summaries for collar.
  ResultFuture<List<CollarActivitySummary>> getActivitySummaries(
    String collarId,
  );

  /// Fetch geofences for pet/user.
  ResultFuture<List<Geofence>> getGeofences();

  /// Create a new safety geofence zone.
  ResultFuture<Geofence> createGeofence({
    String? petId,
    required String name,
    required double centerLatitude,
    required double centerLongitude,
    double radiusMeters = 100.0,
  });

  /// Delete a geofence zone.
  ResultFuture<void> deleteGeofence(String geofenceId);

  /// Subscribe to live GPS telemetry stream via Realtime.
  Stream<CollarGpsLocation> subscribeToGpsLocations(String collarId);
}
