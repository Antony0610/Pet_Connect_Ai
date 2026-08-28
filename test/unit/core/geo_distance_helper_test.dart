import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/utils/geo_distance_helper.dart';

void main() {
  group('GeoDistanceHelper Unit Tests', () {
    test('distanceBetweenMeters calculates accurate distance between coordinates', () {
      // Coordinates approx 1.0 km apart
      const startLat = 12.9716;
      const startLng = 77.5946;
      const endLat = 12.9806;
      const endLng = 77.5946;

      final distanceM = GeoDistanceHelper.distanceBetweenMeters(
        startLatitude: startLat,
        startLongitude: startLng,
        endLatitude: endLat,
        endLongitude: endLng,
      );

      expect(distanceM, greaterThan(990));
      expect(distanceM, lessThan(1010));
    });

    test('isWithinRadius accurately evaluates boundaries', () {
      const centerLat = 12.9716;
      const centerLng = 77.5946;

      // Point within 500m
      const nearLat = 12.9730;
      const nearLng = 77.5946;

      // Point far away (~5km)
      const farLat = 13.0100;
      const farLng = 77.5946;

      expect(
        GeoDistanceHelper.isWithinRadius(
          centerLatitude: centerLat,
          centerLongitude: centerLng,
          targetLatitude: nearLat,
          targetLongitude: nearLng,
          radiusMeters: 500,
        ),
        isTrue,
      );

      expect(
        GeoDistanceHelper.isWithinRadius(
          centerLatitude: centerLat,
          centerLongitude: centerLng,
          targetLatitude: farLat,
          targetLongitude: farLng,
          radiusMeters: 500,
        ),
        isFalse,
      );
    });

    test('formatDistanceWithEta formats meter and km distances appropriately', () {
      const startLat = 12.9716;
      const startLng = 77.5946;

      // Short walking distance (~200m)
      const shortLat = 12.9730;
      const shortLng = 77.5946;
      final shortLabel = GeoDistanceHelper.formatDistanceWithEta(
        startLatitude: startLat,
        startLongitude: startLng,
        endLatitude: shortLat,
        endLongitude: shortLng,
      );

      expect(shortLabel, contains('m away'));
      expect(shortLabel, contains('walk'));

      // Longer driving distance (~5km)
      const longLat = 13.0150;
      const longLng = 77.5946;
      final longLabel = GeoDistanceHelper.formatDistanceWithEta(
        startLatitude: startLat,
        startLongitude: startLng,
        endLatitude: longLat,
        endLongitude: longLng,
      );

      expect(longLabel, contains('km away'));
      expect(longLabel, contains('drive'));
    });
  });
}
