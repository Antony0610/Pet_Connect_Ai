import 'package:dartz/dartz.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/smart_collar/data/datasources/smart_collar_remote_datasource.dart';
import 'package:petconnect_ai/features/smart_collar/data/models/collar_gps_location_model.dart';
import 'package:petconnect_ai/features/smart_collar/data/models/geofence_model.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_activity_summary.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_gps_location.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/geofence.dart';
import 'package:petconnect_ai/features/smart_collar/domain/repositories/smart_collar_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SmartCollarRepositoryImpl implements SmartCollarRepository {
  const SmartCollarRepositoryImpl(this._remoteDataSource, this._client);

  final SmartCollarRemoteDataSource _remoteDataSource;
  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  ResultFuture<List<CollarDevice>> getRegisteredCollars() async {
    try {
      final uid = _currentUserId;
      if (uid == null) {
        return const Left(AuthFailure('User not authenticated'));
      }
      final models = await _remoteDataSource.getRegisteredCollars(uid);
      return Right(models);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<CollarDevice> getCollarById(String collarId) async {
    try {
      final model = await _remoteDataSource.getCollarById(collarId);
      return Right(model);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<CollarDevice> registerCollar({
    required String deviceId,
    String? petId,
  }) async {
    try {
      final uid = _currentUserId;
      if (uid == null) {
        return const Left(AuthFailure('User not authenticated'));
      }
      final model = await _remoteDataSource.registerCollar(
        ownerId: uid,
        deviceId: deviceId,
        petId: petId,
      );
      return Right(model);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<CollarDevice> setLostMode({
    required String collarId,
    required bool isLostMode,
  }) async {
    try {
      final model = await _remoteDataSource.setLostMode(
        collarId: collarId,
        isLostMode: isLostMode,
      );
      return Right(model);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<CollarGpsLocation?> getLatestLocation(String collarId) async {
    try {
      final model = await _remoteDataSource.getLatestLocation(collarId);
      return Right(model);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<List<CollarGpsLocation>> getLocationHistory(
    String collarId,
  ) async {
    try {
      final models = await _remoteDataSource.getLocationHistory(collarId);
      return Right(models);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<CollarGpsLocation> ingestTelemetry({
    required String collarId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    DateTime? gpsTimestamp,
    bool isOffline = false,
  }) async {
    try {
      final model = CollarGpsLocationModel(
        id: '',
        collarId: collarId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        speed: speed,
        gpsTimestamp: gpsTimestamp ?? DateTime.now().toUtc(),
        serverTimestamp: DateTime.now().toUtc(),
        isOfflineTelemetry: isOffline,
        createdAt: DateTime.now().toUtc(),
      );

      final result = await _remoteDataSource.ingestTelemetry(model);
      return Right(result);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<List<CollarActivitySummary>> getActivitySummaries(
    String collarId,
  ) async {
    try {
      final models = await _remoteDataSource.getActivitySummaries(collarId);
      return Right(models);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<List<Geofence>> getGeofences() async {
    try {
      final uid = _currentUserId;
      if (uid == null) {
        return const Left(AuthFailure('User not authenticated'));
      }
      final models = await _remoteDataSource.getGeofences(uid);
      return Right(models);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<Geofence> createGeofence({
    String? petId,
    required String name,
    required double centerLatitude,
    required double centerLongitude,
    double radiusMeters = 100.0,
  }) async {
    try {
      final uid = _currentUserId;
      if (uid == null) {
        return const Left(AuthFailure('User not authenticated'));
      }
      final model = GeofenceModel(
        id: '',
        petId: petId,
        ownerId: uid,
        name: name,
        centerLatitude: centerLatitude,
        centerLongitude: centerLongitude,
        radiusMeters: radiusMeters,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      final result = await _remoteDataSource.createGeofence(model);
      return Right(result);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<void> deleteGeofence(String geofenceId) async {
    try {
      await _remoteDataSource.deleteGeofence(geofenceId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  Stream<CollarGpsLocation> subscribeToGpsLocations(String collarId) {
    return _remoteDataSource.subscribeToGpsLocations(collarId);
  }
}
