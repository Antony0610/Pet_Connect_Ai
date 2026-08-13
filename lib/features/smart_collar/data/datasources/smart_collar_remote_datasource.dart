import 'dart:async';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/features/smart_collar/data/models/collar_activity_summary_model.dart';
import 'package:petconnect_ai/features/smart_collar/data/models/collar_device_model.dart';
import 'package:petconnect_ai/features/smart_collar/data/models/collar_gps_location_model.dart';
import 'package:petconnect_ai/features/smart_collar/data/models/geofence_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SmartCollarRemoteDataSource {
  Future<List<CollarDeviceModel>> getRegisteredCollars(String ownerId);

  Future<CollarDeviceModel> getCollarById(String collarId);

  Future<CollarDeviceModel> registerCollar({
    required String ownerId,
    required String deviceId,
    String? petId,
  });

  Future<CollarDeviceModel> setLostMode({
    required String collarId,
    required bool isLostMode,
  });

  Future<CollarGpsLocationModel?> getLatestLocation(String collarId);

  Future<List<CollarGpsLocationModel>> getLocationHistory(String collarId);

  Future<CollarGpsLocationModel> ingestTelemetry(CollarGpsLocationModel model);

  Future<List<CollarActivitySummaryModel>> getActivitySummaries(
    String collarId,
  );

  Future<List<GeofenceModel>> getGeofences(String ownerId);

  Future<GeofenceModel> createGeofence(GeofenceModel model);

  Future<void> deleteGeofence(String geofenceId);

  Stream<CollarGpsLocationModel> subscribeToGpsLocations(String collarId);
}

class SmartCollarRemoteDataSourceImpl implements SmartCollarRemoteDataSource {
  const SmartCollarRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CollarDeviceModel>> getRegisteredCollars(String ownerId) async {
    try {
      final response = await _client
          .from('smart_collars')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => CollarDeviceModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch registered collars: $e');
    }
  }

  @override
  Future<CollarDeviceModel> getCollarById(String collarId) async {
    try {
      final response = await _client
          .from('smart_collars')
          .select()
          .eq('id', collarId)
          .single();

      return CollarDeviceModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch collar by ID: $e');
    }
  }

  @override
  Future<CollarDeviceModel> registerCollar({
    required String ownerId,
    required String deviceId,
    String? petId,
  }) async {
    try {
      final response = await _client
          .from('smart_collars')
          .insert({'owner_id': ownerId, 'device_id': deviceId, 'pet_id': petId})
          .select()
          .single();

      return CollarDeviceModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to register smart collar: $e');
    }
  }

  @override
  Future<CollarDeviceModel> setLostMode({
    required String collarId,
    required bool isLostMode,
  }) async {
    try {
      final response = await _client
          .from('smart_collars')
          .update({'is_lost_mode': isLostMode})
          .eq('id', collarId)
          .select()
          .single();

      return CollarDeviceModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to set Lost Mode on collar: $e');
    }
  }

  @override
  Future<CollarGpsLocationModel?> getLatestLocation(String collarId) async {
    try {
      final response = await _client
          .from('collar_gps_locations')
          .select()
          .eq('collar_id', collarId)
          .order('gps_timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return CollarGpsLocationModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch latest collar location: $e');
    }
  }

  @override
  Future<List<CollarGpsLocationModel>> getLocationHistory(
    String collarId,
  ) async {
    try {
      final response = await _client
          .from('collar_gps_locations')
          .select()
          .eq('collar_id', collarId)
          .order('gps_timestamp', ascending: false)
          .limit(100);

      return (response as List)
          .map(
            (json) =>
                CollarGpsLocationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch location history: $e');
    }
  }

  @override
  Future<CollarGpsLocationModel> ingestTelemetry(
    CollarGpsLocationModel model,
  ) async {
    try {
      final response = await _client
          .from('collar_gps_locations')
          .insert(model.toJson())
          .select()
          .single();

      // Update last_seen_at on smart_collars
      await _client
          .from('smart_collars')
          .update({'last_seen_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', model.collarId);

      return CollarGpsLocationModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to ingest telemetry: $e');
    }
  }

  @override
  Future<List<CollarActivitySummaryModel>> getActivitySummaries(
    String collarId,
  ) async {
    try {
      final response = await _client
          .from('collar_activity_summaries')
          .select()
          .eq('collar_id', collarId)
          .order('activity_date', ascending: false);

      return (response as List)
          .map(
            (json) => CollarActivitySummaryModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch activity summaries: $e');
    }
  }

  @override
  Future<List<GeofenceModel>> getGeofences(String ownerId) async {
    try {
      final response = await _client
          .from('geofences')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GeofenceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch geofences: $e');
    }
  }

  @override
  Future<GeofenceModel> createGeofence(GeofenceModel model) async {
    try {
      final response = await _client
          .from('geofences')
          .insert(model.toJson())
          .select()
          .single();

      return GeofenceModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to create geofence: $e');
    }
  }

  @override
  Future<void> deleteGeofence(String geofenceId) async {
    try {
      await _client.from('geofences').delete().eq('id', geofenceId);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to delete geofence: $e');
    }
  }

  @override
  Stream<CollarGpsLocationModel> subscribeToGpsLocations(String collarId) {
    final controller = StreamController<CollarGpsLocationModel>.broadcast();

    final channel = _client
        .channel('public:collar_gps_locations:$collarId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'collar_gps_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'collar_id',
            value: collarId,
          ),
          callback: (payload) {
            controller.add(CollarGpsLocationModel.fromJson(payload.newRecord));
          },
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
