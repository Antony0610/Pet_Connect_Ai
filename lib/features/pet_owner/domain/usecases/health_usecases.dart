import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_timeline_event.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/treatment_plan.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/health_repository.dart';

class GetHealthRecords {
  const GetHealthRecords(this._repository);
  final HealthRepository _repository;
  ResultFuture<List<HealthRecord>> call(String petId) =>
      _repository.getHealthRecords(petId);
}

class CreateHealthRecord {
  const CreateHealthRecord(this._repository);
  final HealthRepository _repository;
  ResultFuture<HealthRecord> call(HealthRecord record) =>
      _repository.createHealthRecord(record);
}

class GetVaccinations {
  const GetVaccinations(this._repository);
  final HealthRepository _repository;
  ResultFuture<List<Vaccination>> call(String petId) =>
      _repository.getVaccinations(petId);
}

class CreateVaccination {
  const CreateVaccination(this._repository);
  final HealthRepository _repository;
  ResultFuture<Vaccination> call(Vaccination vaccination) =>
      _repository.createVaccination(vaccination);
}

class GetHealthTimelineEvents {
  const GetHealthTimelineEvents(this._repository);
  final HealthRepository _repository;
  ResultFuture<List<HealthTimelineEvent>> call(String petId) =>
      _repository.getTimelineEvents(petId);
}

class GetPetWeightLogs {
  const GetPetWeightLogs(this._repository);
  final HealthRepository _repository;
  ResultFuture<List<PetWeightLog>> call(String petId) =>
      _repository.getWeightLogs(petId);
}

class AddPetWeightLog {
  const AddPetWeightLog(this._repository);
  final HealthRepository _repository;
  ResultFuture<PetWeightLog> call(PetWeightLog weightLog) =>
      _repository.addWeightLog(weightLog);
}

class GetTreatmentPlans {
  const GetTreatmentPlans(this._repository);
  final HealthRepository _repository;
  ResultFuture<List<TreatmentPlan>> call(String petId) =>
      _repository.getTreatmentPlans(petId);
}
