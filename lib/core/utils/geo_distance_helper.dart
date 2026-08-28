import 'dart:math';

/// High-precision geographical calculations using the Haversine formula.
/// Used for volunteer rescue proximity, lost pet sightings, and geofence tracking.
class GeoDistanceHelper {
  const GeoDistanceHelper._();

  /// Earth radius in meters (WGS-84 mean radius).
  static const double _earthRadiusMeters = 6371000.0;

  /// Calculates the spherical distance in meters between two GPS coordinates.
  static double distanceBetweenMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final lat1Rad = startLatitude * pi / 180.0;
    final lat2Rad = endLatitude * pi / 180.0;
    final deltaLatRad = (endLatitude - startLatitude) * pi / 180.0;
    final deltaLonRad = (endLongitude - startLongitude) * pi / 180.0;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// Calculates the spherical distance in kilometers.
  static double distanceBetweenKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return distanceBetweenMeters(
          startLatitude: startLatitude,
          startLongitude: startLongitude,
          endLatitude: endLatitude,
          endLongitude: endLongitude,
        ) /
        1000.0;
  }

  /// Returns a clean, human-readable distance label with estimated transit time.
  static String formatDistanceWithEta({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final distanceM = distanceBetweenMeters(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
    );

    if (distanceM < 1000) {
      final meters = distanceM.round();
      final walkMin = max(1, (distanceM / 80).round()); // ~4.8 km/h walking speed
      return '$meters m away • ~$walkMin min walk';
    }

    final km = (distanceM / 1000.0).toStringAsFixed(1);
    final driveMin = max(2, (distanceM / 500).round()); // ~30 km/h urban driving
    return '$km km away • ~$driveMin min drive';
  }

  /// Checks if a given coordinate is within a circular geofence radius in meters.
  static bool isWithinRadius({
    required double centerLatitude,
    required double centerLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double radiusMeters,
  }) {
    final d = distanceBetweenMeters(
      startLatitude: centerLatitude,
      startLongitude: centerLongitude,
      endLatitude: targetLatitude,
      endLongitude: targetLongitude,
    );
    return d <= radiusMeters;
  }
}
