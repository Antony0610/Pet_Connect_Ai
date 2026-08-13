import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_gps_location.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/geofence.dart';
import 'package:petconnect_ai/features/smart_collar/domain/repositories/smart_collar_repository.dart';

class GetRegisteredCollars {
  const GetRegisteredCollars(this._repository);
  final SmartCollarRepository _repository;

  ResultFuture<List<CollarDevice>> call() => _repository.getRegisteredCollars();
}

class RegisterCollar {
  const RegisterCollar(this._repository);
  final SmartCollarRepository _repository;

  ResultFuture<CollarDevice> call({required String deviceId, String? petId}) =>
      _repository.registerCollar(deviceId: deviceId, petId: petId);
}

class SetLostMode {
  const SetLostMode(this._repository);
  final SmartCollarRepository _repository;

  ResultFuture<CollarDevice> call({
    required String collarId,
    required bool isLostMode,
  }) => _repository.setLostMode(collarId: collarId, isLostMode: isLostMode);
}

class GetLatestLocation {
  const GetLatestLocation(this._repository);
  final SmartCollarRepository _repository;

  ResultFuture<CollarGpsLocation?> call(String collarId) =>
      _repository.getLatestLocation(collarId);
}

class GetLocationHistory {
  const GetLocationHistory(this._repository);
  final SmartCollarRepository _repository;

  ResultFuture<List<CollarGpsLocation>> call(String collarId) =>
      _repository.getLocationHistory(collarId);
}

class IngestTelemetry {
  const IngestTelemetry(this._repository);
  final SmartCollarRepository _repository;

  ResultFuture<CollarGpsLocation> call({
    required String collarId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    DateTime? gpsTimestamp,
    bool isOffline = false,
  }) => _repository.ingestTelemetry(
    collarId: collarId,
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    speed: speed,
    gpsTimestamp: gpsTimestamp,
    isOffline: isOffline,
  );
}

class GetGeofences {
  const GetGeofences(this._repository);
  final SmartCollarRepository _repository;

  ResultFuture<List<Geofence>> call() => _repository.getGeofences();
}

class CreateGeofence {
  const CreateGeofence(this._repository);
  final SmartCollarRepository _repository;

  ResultFuture<Geofence> call({
    String? petId,
    required String name,
    required double centerLatitude,
    required double centerLongitude,
    double radiusMeters = 100.0,
  }) => _repository.createGeofence(
    petId: petId,
    name: name,
    centerLatitude: centerLatitude,
    centerLongitude: centerLongitude,
    radiusMeters: radiusMeters,
  );
}
