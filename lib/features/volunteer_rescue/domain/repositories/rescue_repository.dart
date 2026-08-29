import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_sighting.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_mission.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_shelter.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/volunteer_responder.dart';

/// Repository interface for Volunteer & Rescue Portal operations.
abstract class RescueRepository {
  ResultFuture<List<LostPetAlert>> getActiveLostPetAlerts();
  ResultFuture<LostPetAlert> createLostPetAlert(LostPetAlert alert);

  ResultFuture<List<LostPetSighting>> getSightingsForAlert(String alertId);
  ResultFuture<LostPetSighting> reportSighting(LostPetSighting sighting);

  ResultFuture<List<RescueMission>> getRescueMissions({String? status});
  ResultFuture<RescueMission> createRescueMission(RescueMission mission);
  ResultFuture<RescueMission> updateMissionStatus(
    String missionId,
    String status,
  );

  // Shelters
  ResultFuture<List<RescueShelter>> getShelters();
  ResultFuture<RescueShelter> saveShelter(RescueShelter shelter);

  // Volunteers
  ResultFuture<List<VolunteerResponder>> getVolunteers();
  ResultFuture<VolunteerResponder> saveVolunteer(VolunteerResponder volunteer);
  ResultFuture<VolunteerResponder> toggleDutyStatus(String volunteerId, bool isOnDuty);
}
