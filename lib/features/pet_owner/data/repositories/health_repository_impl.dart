import 'package:dartz/dartz.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/data/datasources/health_remote_datasource.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/health_record_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/pet_weight_log_model.dart';
import 'package:petconnect_ai/features/pet_owner/data/models/vaccination_model.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_timeline_event.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/treatment_plan.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  const HealthRepositoryImpl(this._remote);

  final HealthRemoteDataSource _remote;

  @override
  ResultFuture<List<HealthRecord>> getHealthRecords(String petId) async {
    try {
      final records = await _remote.getHealthRecords(petId);
      return Right(records);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<HealthRecord> createHealthRecord(HealthRecord record) async {
    try {
      final model = HealthRecordModel(
        id: record.id,
        petId: record.petId,
        recordDate: record.recordDate,
        category: record.category,
        title: record.title,
        notes: record.notes,
        diagnosis: record.diagnosis,
        treatment: record.treatment,
        veterinarianName: record.veterinarianName,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
      );
      final created = await _remote.createHealthRecord(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<Vaccination>> getVaccinations(String petId) async {
    try {
      final vaccinations = await _remote.getVaccinations(petId);
      return Right(vaccinations);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<Vaccination> createVaccination(Vaccination vaccination) async {
    try {
      final model = VaccinationModel(
        id: vaccination.id,
        petId: vaccination.petId,
        vaccineName: vaccination.vaccineName,
        administeredDate: vaccination.administeredDate,
        nextDueDate: vaccination.nextDueDate,
        administeredBy: vaccination.administeredBy,
        batchNumber: vaccination.batchNumber,
        certificateUrl: vaccination.certificateUrl,
        notes: vaccination.notes,
        isCompleted: vaccination.isCompleted,
        createdAt: vaccination.createdAt,
        updatedAt: vaccination.updatedAt,
      );
      final created = await _remote.createVaccination(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<HealthTimelineEvent>> getTimelineEvents(
    String petId,
  ) async {
    try {
      final events = await _remote.getTimelineEvents(petId);
      return Right(events);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<PetWeightLog>> getWeightLogs(String petId) async {
    try {
      final logs = await _remote.getWeightLogs(petId);
      return Right(logs);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<PetWeightLog> addWeightLog(PetWeightLog weightLog) async {
    try {
      final model = PetWeightLogModel(
        id: weightLog.id,
        petId: weightLog.petId,
        recordedAt: weightLog.recordedAt,
        weightKg: weightLog.weightKg,
        notes: weightLog.notes,
        createdAt: weightLog.createdAt,
      );
      final created = await _remote.addWeightLog(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<TreatmentPlan>> getTreatmentPlans(String petId) async {
    try {
      final plans = await _remote.getTreatmentPlans(petId);
      return Right(plans);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }
}
