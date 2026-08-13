import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_gps_location.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/geofence.dart';

/// Network operator / SIM status for cellular collars.
enum CellularNetworkState { connected, searching, simMissing, disconnected }

/// Evaluates hardware status, heartbeats, geofence breaches, and cellular telemetry.
abstract class SmartCollarHealthService {
  /// Evaluates if a collar is considered offline based on [lastSeenAt] and [offlineTimeout].
  bool isDeviceOffline(
    DateTime lastSeenAt, {
    Duration offlineTimeout = const Duration(minutes: 15),
  });

  /// Evaluates whether a GPS location point breaches a safety geofence zone boundary.
  bool checkGeofenceBreach(CollarGpsLocation location, Geofence geofence);

  /// Evaluates GPS fix quality and flags stale locations.
  bool isGpsFixStale(
    DateTime gpsTimestamp, {
    Duration maxStaleDuration = const Duration(minutes: 10),
  });
}

class SmartCollarHealthServiceImpl implements SmartCollarHealthService {
  const SmartCollarHealthServiceImpl();

  @override
  bool isDeviceOffline(
    DateTime lastSeenAt, {
    Duration offlineTimeout = const Duration(minutes: 15),
  }) {
    return DateTime.now().toUtc().difference(lastSeenAt.toUtc()) >
        offlineTimeout;
  }

  @override
  bool checkGeofenceBreach(CollarGpsLocation location, Geofence geofence) {
    if (!geofence.isActive) return false;

    // Simple Euclidean approximation for short distance geofence radius check (1 deg lat ~= 111,000m)
    final dLat = (location.latitude - geofence.centerLatitude) * 111000.0;
    final dLng =
        (location.longitude - geofence.centerLongitude) *
        111000.0 *
        0.8; // Approx cos(latitude)
    final distanceMeters = (dLat * dLat + dLng * dLng) > 0
        ? (dLat * dLat + dLng * dLng)
        : 0.0;

    return (distanceMeters) > (geofence.radiusMeters * geofence.radiusMeters);
  }

  @override
  bool isGpsFixStale(
    DateTime gpsTimestamp, {
    Duration maxStaleDuration = const Duration(minutes: 10),
  }) {
    return DateTime.now().toUtc().difference(gpsTimestamp.toUtc()) >
        maxStaleDuration;
  }
}
