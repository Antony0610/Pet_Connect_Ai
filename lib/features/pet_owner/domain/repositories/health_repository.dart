import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_timeline_event.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/treatment_plan.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';

/// Repository interface for Pet Health Passport domain operations.
abstract class HealthRepository {
  // Medical Records
  ResultFuture<List<HealthRecord>> getHealthRecords(String petId);
  ResultFuture<HealthRecord> createHealthRecord(HealthRecord record);

  // Vaccinations
  ResultFuture<List<Vaccination>> getVaccinations(String petId);
  ResultFuture<Vaccination> createVaccination(Vaccination vaccination);

  // Timeline Events
  ResultFuture<List<HealthTimelineEvent>> getTimelineEvents(String petId);

  // Weight Logs
  ResultFuture<List<PetWeightLog>> getWeightLogs(String petId);
  ResultFuture<PetWeightLog> addWeightLog(PetWeightLog weightLog);

  // Treatment Plans
  ResultFuture<List<TreatmentPlan>> getTreatmentPlans(String petId);
}
