import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/health_record_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/health_timeline_event_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_weight_log_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/treatment_plan_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/vaccination_model.dart';

abstract class HealthRemoteDataSource {
  Future<List<HealthRecordModel>> getHealthRecords(String petId);
  Future<HealthRecordModel> createHealthRecord(HealthRecordModel record);

  Future<List<VaccinationModel>> getVaccinations(String petId);
  Future<VaccinationModel> createVaccination(VaccinationModel vaccination);

  Future<List<HealthTimelineEventModel>> getTimelineEvents(String petId);

  Future<List<PetWeightLogModel>> getWeightLogs(String petId);
  Future<PetWeightLogModel> addWeightLog(PetWeightLogModel weightLog);

  Future<List<TreatmentPlanModel>> getTreatmentPlans(String petId);
}

class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  const HealthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<HealthRecordModel>> getHealthRecords(String petId) async {
    try {
      final response = await _client
          .from('health_records')
          .select()
          .eq('pet_id', petId)
          .order('record_date', ascending: false);

      return (response as List)
          .map((json) => HealthRecordModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? '500'));
    } catch (e) {
      throw ServerException('Failed to fetch health records: $e');
    }
  }

  @override
  Future<HealthRecordModel> createHealthRecord(HealthRecordModel record) async {
    try {
      final json = record.toJson()..remove('id');
      final response = await _client
          .from('health_records')
          .insert(json)
          .select()
          .single();

      return HealthRecordModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? '500'));
    } catch (e) {
      throw ServerException('Failed to create health record: $e');
    }
  }

  @override
  Future<List<VaccinationModel>> getVaccinations(String petId) async {
    try {
      final response = await _client
          .from('vaccinations')
          .select()
          .eq('pet_id', petId)
          .order('administered_date', ascending: false);

      return (response as List)
          .map((json) => VaccinationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? '500'));
    } catch (e) {
      throw ServerException('Failed to fetch vaccinations: $e');
    }
  }

  @override
  Future<VaccinationModel> createVaccination(VaccinationModel vaccination) async {
    try {
      final json = vaccination.toJson()..remove('id');
      final response = await _client
          .from('vaccinations')
          .insert(json)
          .select()
          .single();

      return VaccinationModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? '500'));
    } catch (e) {
      throw ServerException('Failed to create vaccination: $e');
    }
  }

  @override
  Future<List<HealthTimelineEventModel>> getTimelineEvents(String petId) async {
    try {
      final response = await _client
          .from('health_timeline_events')
          .select()
          .eq('pet_id', petId)
          .order('event_date', ascending: false);

      return (response as List)
          .map((json) => HealthTimelineEventModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? '500'));
    } catch (e) {
      throw ServerException('Failed to fetch timeline events: $e');
    }
  }

  @override
  Future<List<PetWeightLogModel>> getWeightLogs(String petId) async {
    try {
      final response = await _client
          .from('pet_weight_logs')
          .select()
          .eq('pet_id', petId)
          .order('recorded_at', ascending: true);

      return (response as List)
          .map((json) => PetWeightLogModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? '500'));
    } catch (e) {
      throw ServerException('Failed to fetch weight logs: $e');
    }
  }

  @override
  Future<PetWeightLogModel> addWeightLog(PetWeightLogModel weightLog) async {
    try {
      final json = weightLog.toJson()..remove('id');
      final response = await _client
          .from('pet_weight_logs')
          .insert(json)
          .select()
          .single();

      return PetWeightLogModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? '500'));
    } catch (e) {
      throw ServerException('Failed to add weight log: $e');
    }
  }

  @override
  Future<List<TreatmentPlanModel>> getTreatmentPlans(String petId) async {
    try {
      final response = await _client
          .from('treatment_plans')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TreatmentPlanModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? '500'));
    } catch (e) {
      throw ServerException('Failed to fetch treatment plans: $e');
    }
  }
}
