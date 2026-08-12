import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/lost_pet_alert_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/lost_pet_sighting_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/rescue_mission_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RescueRemoteDataSource {
  Future<List<LostPetAlertModel>> getActiveLostPetAlerts();
  Future<LostPetAlertModel> createLostPetAlert(LostPetAlertModel alert);

  Future<List<LostPetSightingModel>> getSightingsForAlert(String alertId);
  Future<LostPetSightingModel> reportSighting(LostPetSightingModel sighting);

  Future<List<RescueMissionModel>> getRescueMissions({String? status});
  Future<RescueMissionModel> createRescueMission(RescueMissionModel mission);
  Future<RescueMissionModel> updateMissionStatus(
    String missionId,
    String status,
  );
}

class RescueRemoteDataSourceImpl implements RescueRemoteDataSource {
  const RescueRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<LostPetAlertModel>> getActiveLostPetAlerts() async {
    try {
      final response = await _client
          .from('lost_pet_alerts')
          .select()
          .eq('alert_status', 'ACTIVE')
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => LostPetAlertModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch active alerts: $e');
    }
  }

  @override
  Future<LostPetAlertModel> createLostPetAlert(LostPetAlertModel alert) async {
    try {
      final json = alert.toJson()..remove('id');
      final response = await _client
          .from('lost_pet_alerts')
          .insert(json)
          .select()
          .single();
      return LostPetAlertModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to create alert: $e');
    }
  }

  @override
  Future<List<LostPetSightingModel>> getSightingsForAlert(
    String alertId,
  ) async {
    try {
      final response = await _client
          .from('lost_pet_sightings')
          .select()
          .eq('alert_id', alertId)
          .order('sighting_time', ascending: false);

      return (response as List)
          .map(
            (json) =>
                LostPetSightingModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch sightings: $e');
    }
  }

  @override
  Future<LostPetSightingModel> reportSighting(
    LostPetSightingModel sighting,
  ) async {
    try {
      final json = sighting.toJson()..remove('id');
      final response = await _client
          .from('lost_pet_sightings')
          .insert(json)
          .select()
          .single();
      return LostPetSightingModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to report sighting: $e');
    }
  }

  @override
  Future<List<RescueMissionModel>> getRescueMissions({String? status}) async {
    try {
      var query = _client.from('rescue_missions').select();
      if (status != null) query = query.eq('status', status);

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map(
            (json) => RescueMissionModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch missions: $e');
    }
  }

  @override
  Future<RescueMissionModel> createRescueMission(
    RescueMissionModel mission,
  ) async {
    try {
      final json = mission.toJson()..remove('id');
      final response = await _client
          .from('rescue_missions')
          .insert(json)
          .select()
          .single();
      return RescueMissionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to create mission: $e');
    }
  }

  @override
  Future<RescueMissionModel> updateMissionStatus(
    String missionId,
    String status,
  ) async {
    try {
      final response = await _client
          .from('rescue_missions')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', missionId)
          .select()
          .single();
      return RescueMissionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to update mission status: $e');
    }
  }
}
