import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:petconnect_ai/features/smart_collar/data/models/collar_device_model.dart';
import 'package:petconnect_ai/features/smart_collar/data/models/collar_gps_location_model.dart';
import 'package:petconnect_ai/features/smart_collar/data/models/geofence_model.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_gps_location.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/geofence.dart';
import 'package:petconnect_ai/features/smart_collar/domain/repositories/smart_collar_repository.dart';
import 'package:petconnect_ai/features/smart_collar/domain/usecases/smart_collar_usecases.dart';

class MockSmartCollarRepository extends Mock implements SmartCollarRepository {}

void main() {
  late MockSmartCollarRepository mockRepo;
  final now = DateTime(2026, 8, 13);

  final tCollar = CollarDevice(
    id: 'collar-1',
    deviceId: 'SC-1001',
    ownerId: 'owner-1',
    batteryPercentage: 95,
    connectivityType: 'BLE',
    lastSeenAt: now,
    createdAt: now,
    updatedAt: now,
  );

  final tLocation = CollarGpsLocation(
    id: 'loc-1',
    collarId: 'collar-1',
    latitude: 37.7749,
    longitude: -122.4194,
    gpsTimestamp: now,
    serverTimestamp: now,
    createdAt: now,
  );

  final tGeofence = Geofence(
    id: 'geo-1',
    ownerId: 'owner-1',
    name: 'Home Zone',
    centerLatitude: 37.7749,
    centerLongitude: -122.4194,
    radiusMeters: 150.0,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockRepo = MockSmartCollarRepository();
  });

  group('Smart Collar Models Unit Tests', () {
    test('CollarDeviceModel parses JSON correctly', () {
      final json = {
        'id': 'collar-1',
        'device_id': 'SC-1001',
        'pet_id': 'pet-1',
        'owner_id': 'owner-1',
        'firmware_version': 'v1.2.0',
        'battery_percentage': 88,
        'connectivity_type': 'GSM_LTE',
        'signal_strength': 85,
        'is_lost_mode': true,
        'is_active': true,
        'last_seen_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = CollarDeviceModel.fromJson(json);
      expect(model.id, 'collar-1');
      expect(model.deviceId, 'SC-1001');
      expect(model.batteryPercentage, 88);
      expect(model.connectivityType, 'GSM_LTE');
      expect(model.isLostMode, isTrue);
    });

    test('CollarGpsLocationModel parses JSON correctly', () {
      final json = {
        'id': 'loc-1',
        'collar_id': 'collar-1',
        'pet_id': 'pet-1',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'accuracy': 5.0,
        'speed': 1.2,
        'gps_timestamp': now.toIso8601String(),
        'server_timestamp': now.toIso8601String(),
        'is_offline_telemetry': false,
        'created_at': now.toIso8601String(),
      };

      final model = CollarGpsLocationModel.fromJson(json);
      expect(model.latitude, 37.7749);
      expect(model.longitude, -122.4194);
      expect(model.accuracy, 5.0);
    });

    test('GeofenceModel parses JSON correctly', () {
      final json = {
        'id': 'geo-1',
        'owner_id': 'owner-1',
        'name': 'Park Zone',
        'center_latitude': 37.7749,
        'center_longitude': -122.4194,
        'radius_meters': 200.0,
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = GeofenceModel.fromJson(json);
      expect(model.name, 'Park Zone');
      expect(model.radiusMeters, 200.0);
    });
  });

  group('Smart Collar UseCases Unit Tests', () {
    test('GetRegisteredCollars delegates to repository', () async {
      final useCase = GetRegisteredCollars(mockRepo);
      when(
        () => mockRepo.getRegisteredCollars(),
      ).thenAnswer((_) async => Right([tCollar]));

      final result = await useCase();
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('should pass'), (r) => expect(r, [tCollar]));
    });

    test('SetLostMode delegates to repository', () async {
      final useCase = SetLostMode(mockRepo);
      when(
        () => mockRepo.setLostMode(collarId: 'collar-1', isLostMode: true),
      ).thenAnswer((_) async => Right(tCollar));

      final result = await useCase(collarId: 'collar-1', isLostMode: true);
      expect(result.isRight(), isTrue);
    });

    test('GetGeofences delegates to repository', () async {
      final useCase = GetGeofences(mockRepo);
      when(
        () => mockRepo.getGeofences(),
      ).thenAnswer((_) async => Right([tGeofence]));

      final result = await useCase();
      expect(result.isRight(), isTrue);
    });
  });
}
