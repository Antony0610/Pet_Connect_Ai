import 'package:petconnect_ai/core/error/exceptions.dart' as core_exceptions;
import 'package:petconnect_ai/features/pet_owner/data/models/pet_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_settings_model.dart';
import 'package:petconnect_ai/shared/data/datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source contract for Pet management operations via Supabase.
abstract interface class PetRemoteDataSource implements RemoteDataSource {
  /// Fetches pets owned by the currently authenticated user.
  Future<List<PetModel>> getPets();

  /// Fetches a specific pet by [id] owned by the currently authenticated user.
  Future<PetModel?> getPetById(String id);

  /// Creates a new pet record.
  Future<PetModel> createPet(PetModel pet);

  /// Updates an existing pet record.
  Future<PetModel> updatePet(PetModel pet);

  /// Deletes a pet record by [id].
  Future<void> deletePet(String id);

  /// Reads pet settings for [petId].
  Future<PetSettingsModel?> getPetSettings(String petId);

  /// Saves pet settings for [petId].
  Future<void> updatePetSettings(PetSettingsModel settings);
}

class PetRemoteDataSourceImpl implements PetRemoteDataSource {
  const PetRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PetModel>> getPets() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const core_exceptions.AuthException(
          'User must be authenticated to fetch pets',
        );
      }

      final data = await _client
          .from('pets')
          .select()
          .eq('owner_id', user.id)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final list = (data as List<dynamic>)
          .map((item) => PetModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return list;
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } on PostgrestException catch (e) {
      throw core_exceptions.ServerException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.ServerException('Failed to fetch pets', cause: e);
    }
  }

  @override
  Future<PetModel?> getPetById(String id) async {
    try {
      final data = await _client
          .from('pets')
          .select()
          .eq('id', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (data == null) return null;
      return PetModel.fromJson(data);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } on PostgrestException catch (e) {
      throw core_exceptions.ServerException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.ServerException(
        'Failed to fetch pet details',
        cause: e,
      );
    }
  }

  @override
  Future<PetModel> createPet(PetModel pet) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const core_exceptions.AuthException(
          'User must be authenticated to create a pet',
        );
      }

      final payload = pet.toJson();
      payload['owner_id'] = user.id; // Force owner_id to match auth.uid()

      final response = await _client
          .from('pets')
          .insert(payload)
          .select()
          .single();
      return PetModel.fromJson(response);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } on PostgrestException catch (e) {
      throw core_exceptions.ServerException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.ServerException('Failed to create pet', cause: e);
    }
  }

  @override
  Future<PetModel> updatePet(PetModel pet) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const core_exceptions.AuthException(
          'User must be authenticated to update a pet',
        );
      }

      final payload = pet.toJson();
      payload['owner_id'] = user.id; // Prevent ownership spoofing
      payload['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('pets')
          .update(payload)
          .eq('id', pet.id)
          .eq('owner_id', user.id)
          .select()
          .single();
      return PetModel.fromJson(response);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } on PostgrestException catch (e) {
      throw core_exceptions.ServerException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.ServerException('Failed to update pet', cause: e);
    }
  }

  @override
  Future<void> deletePet(String id) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const core_exceptions.AuthException(
          'User must be authenticated to delete a pet',
        );
      }

      // Perform soft delete
      await _client
          .from('pets')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .eq('owner_id', user.id);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } on PostgrestException catch (e) {
      throw core_exceptions.ServerException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.ServerException('Failed to delete pet', cause: e);
    }
  }

  @override
  Future<PetSettingsModel?> getPetSettings(String petId) async {
    try {
      final data = await _client
          .from('pet_settings')
          .select()
          .eq('pet_id', petId)
          .maybeSingle();

      if (data == null) return null;
      return PetSettingsModel.fromJson(data);
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } on PostgrestException catch (e) {
      throw core_exceptions.ServerException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.ServerException(
        'Failed to fetch pet settings',
        cause: e,
      );
    }
  }

  @override
  Future<void> updatePetSettings(PetSettingsModel settings) async {
    try {
      await _client.from('pet_settings').upsert(settings.toJson());
    } on AuthException catch (e) {
      throw core_exceptions.AuthException(e.message, cause: e);
    } on PostgrestException catch (e) {
      throw core_exceptions.ServerException(e.message, cause: e);
    } catch (e) {
      throw core_exceptions.ServerException(
        'Failed to save pet settings',
        cause: e,
      );
    }
  }
}
