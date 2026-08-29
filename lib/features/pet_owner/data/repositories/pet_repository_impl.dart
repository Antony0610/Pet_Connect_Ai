import 'package:dartz/dartz.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/data/datasources/pet_remote_datasource.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_settings_model.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_event.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_share.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/pet_repository.dart';

/// Supabase-backed implementation of [PetRepository].
class PetRepositoryImpl implements PetRepository {
  const PetRepositoryImpl(this._remote);

  final PetRemoteDataSource _remote;

  @override
  ResultFuture<List<Pet>> getPets() async {
    try {
      final models = await _remote.getPets();
      return Right(models.map((m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<Pet?> getPetById(String id) async {
    try {
      final model = await _remote.getPetById(id);
      return Right(model?.toEntity());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<Pet> createPet(Pet pet) async {
    try {
      final model = await _remote.createPet(PetModel.fromEntity(pet));
      return Right(model.toEntity());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<Pet> updatePet(Pet pet) async {
    try {
      final model = await _remote.updatePet(PetModel.fromEntity(pet));
      return Right(model.toEntity());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid deletePet(String id) async {
    try {
      await _remote.deletePet(id);
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<PetSettings?> getPetSettings(String petId) async {
    try {
      final model = await _remote.getPetSettings(petId);
      return Right(model?.toEntity());
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid updatePetSettings(PetSettings settings) async {
    try {
      await _remote.updatePetSettings(PetSettingsModel.fromEntity(settings));
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<Map<String, dynamic>> activateLostMode({
    required String petId,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String description,
  }) async {
    try {
      final res = await _remote.activateLostMode(
        petId: petId,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        description: description,
      );
      return Right(res);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid resolveLostMode(String petId) async {
    try {
      await _remote.resolveLostMode(petId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<Map<String, dynamic>?> getActiveLostAlert(String petId) async {
    try {
      final res = await _remote.getActiveLostAlert(petId);
      return Right(res);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<List<Map<String, dynamic>>> getCommunitySightings({String? petId}) async {
    try {
      final res = await _remote.getCommunitySightings(petId: petId);
      return Right(res);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<Map<String, dynamic>> submitSighting({
    required String petId,
    required double latitude,
    required double longitude,
    required String locationName,
    required String note,
    String? photoUrl,
  }) async {
    try {
      final res = await _remote.submitSighting(
        petId: petId,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        note: note,
        photoUrl: photoUrl,
      );
      return Right(res);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<List<PetShare>> getPetShares(String petId) async {
    try {
      final res = await _remote.getPetShares(petId);
      return Right(res);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<PetShare> inviteCaregiver({
    required String petId,
    required String email,
    required String role,
    required String permissionLevel,
  }) async {
    try {
      final res = await _remote.inviteCaregiver(
        petId: petId,
        email: email,
        role: role,
        permissionLevel: permissionLevel,
      );
      return Right(res);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultVoid revokeCaregiver(String shareId) async {
    try {
      await _remote.revokeCaregiver(shareId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<List<CommunityEvent>> getCommunityEvents({String? category}) async {
    try {
      final res = await _remote.getCommunityEvents(category: category);
      return Right(res);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }

  @override
  ResultFuture<bool> toggleEventRegistration(String eventId) async {
    try {
      final res = await _remote.toggleEventRegistration(eventId);
      return Right(res);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromUnknown(e));
    }
  }
}
