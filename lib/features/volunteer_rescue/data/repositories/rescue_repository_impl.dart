import 'package:dartz/dartz.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/datasources/rescue_remote_datasource.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/lost_pet_alert_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/lost_pet_sighting_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/data/models/rescue_mission_model.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_sighting.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_mission.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/repositories/rescue_repository.dart';

class RescueRepositoryImpl implements RescueRepository {
  const RescueRepositoryImpl(this._remote);

  final RescueRemoteDataSource _remote;

  @override
  ResultFuture<List<LostPetAlert>> getActiveLostPetAlerts() async {
    try {
      final list = await _remote.getActiveLostPetAlerts();
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<LostPetAlert> createLostPetAlert(LostPetAlert alert) async {
    try {
      final model = LostPetAlertModel(
        id: alert.id,
        petId: alert.petId,
        ownerId: alert.ownerId,
        alertStatus: alert.alertStatus,
        lastSeenLocation: alert.lastSeenLocation,
        latitude: alert.latitude,
        longitude: alert.longitude,
        lastSeenTime: alert.lastSeenTime,
        description: alert.description,
        contactPhone: alert.contactPhone,
        rewardAmount: alert.rewardAmount,
        createdAt: alert.createdAt,
        updatedAt: alert.updatedAt,
      );
      final created = await _remote.createLostPetAlert(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<LostPetSighting>> getSightingsForAlert(
    String alertId,
  ) async {
    try {
      final list = await _remote.getSightingsForAlert(alertId);
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<LostPetSighting> reportSighting(LostPetSighting sighting) async {
    try {
      final model = LostPetSightingModel(
        id: sighting.id,
        alertId: sighting.alertId,
        reporterId: sighting.reporterId,
        sightingLocation: sighting.sightingLocation,
        latitude: sighting.latitude,
        longitude: sighting.longitude,
        sightingTime: sighting.sightingTime,
        photoUrl: sighting.photoUrl,
        notes: sighting.notes,
        status: sighting.status,
        createdAt: sighting.createdAt,
      );
      final created = await _remote.reportSighting(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<RescueMission>> getRescueMissions({String? status}) async {
    try {
      final list = await _remote.getRescueMissions(status: status);
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<RescueMission> createRescueMission(RescueMission mission) async {
    try {
      final model = RescueMissionModel(
        id: mission.id,
        alertId: mission.alertId,
        leadVolunteerId: mission.leadVolunteerId,
        missionTitle: mission.missionTitle,
        priority: mission.priority,
        status: mission.status,
        searchRadiusMeters: mission.searchRadiusMeters,
        notes: mission.notes,
        startedAt: mission.startedAt,
        completedAt: mission.completedAt,
        createdAt: mission.createdAt,
        updatedAt: mission.updatedAt,
      );
      final created = await _remote.createRescueMission(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<RescueMission> updateMissionStatus(
    String missionId,
    String status,
  ) async {
    try {
      final updated = await _remote.updateMissionStatus(missionId, status);
      return Right(updated);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }
}
