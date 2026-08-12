import 'package:dartz/dartz.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/data/datasources/pet_remote_datasource.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_settings_model.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_settings.dart';
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
}
