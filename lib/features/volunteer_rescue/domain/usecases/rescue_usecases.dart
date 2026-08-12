import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_sighting.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_mission.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/repositories/rescue_repository.dart';

class GetActiveLostPetAlerts {
  const GetActiveLostPetAlerts(this._repository);
  final RescueRepository _repository;
  ResultFuture<List<LostPetAlert>> call() =>
      _repository.getActiveLostPetAlerts();
}

class CreateLostPetAlert {
  const CreateLostPetAlert(this._repository);
  final RescueRepository _repository;
  ResultFuture<LostPetAlert> call(LostPetAlert alert) =>
      _repository.createLostPetAlert(alert);
}

class GetSightingsForAlert {
  const GetSightingsForAlert(this._repository);
  final RescueRepository _repository;
  ResultFuture<List<LostPetSighting>> call(String alertId) =>
      _repository.getSightingsForAlert(alertId);
}

class ReportSighting {
  const ReportSighting(this._repository);
  final RescueRepository _repository;
  ResultFuture<LostPetSighting> call(LostPetSighting sighting) =>
      _repository.reportSighting(sighting);
}

class GetRescueMissions {
  const GetRescueMissions(this._repository);
  final RescueRepository _repository;
  ResultFuture<List<RescueMission>> call({String? status}) =>
      _repository.getRescueMissions(status: status);
}

class CreateRescueMission {
  const CreateRescueMission(this._repository);
  final RescueRepository _repository;
  ResultFuture<RescueMission> call(RescueMission mission) =>
      _repository.createRescueMission(mission);
}

class UpdateMissionStatus {
  const UpdateMissionStatus(this._repository);
  final RescueRepository _repository;
  ResultFuture<RescueMission> call(String missionId, String status) =>
      _repository.updateMissionStatus(missionId, status);
}
