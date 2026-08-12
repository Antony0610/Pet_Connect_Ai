import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/appointment.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/consultation.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/patient_queue_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/pharmacy_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/prescription.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_clinic.dart';
import 'package:petconnect_ai/features/veterinarian/domain/repositories/vet_repository.dart';

class GetVetClinics {
  const GetVetClinics(this._repository);
  final VetRepository _repository;
  ResultFuture<List<VetClinic>> call() => _repository.getVetClinics();
}

class CreateVetClinic {
  const CreateVetClinic(this._repository);
  final VetRepository _repository;
  ResultFuture<VetClinic> call(VetClinic clinic) =>
      _repository.createVetClinic(clinic);
}

class GetAppointments {
  const GetAppointments(this._repository);
  final VetRepository _repository;
  ResultFuture<List<Appointment>> call({String? vetId, String? clinicId}) =>
      _repository.getAppointments(vetId: vetId, clinicId: clinicId);
}

class CreateAppointment {
  const CreateAppointment(this._repository);
  final VetRepository _repository;
  ResultFuture<Appointment> call(Appointment appointment) =>
      _repository.createAppointment(appointment);
}

class GetPatientQueue {
  const GetPatientQueue(this._repository);
  final VetRepository _repository;
  ResultFuture<List<PatientQueueItem>> call({String? clinicId, String? vetId}) =>
      _repository.getPatientQueue(clinicId: clinicId, vetId: vetId);
}

class GetConsultationByAppointment {
  const GetConsultationByAppointment(this._repository);
  final VetRepository _repository;
  ResultFuture<Consultation?> call(String appointmentId) =>
      _repository.getConsultationByAppointment(appointmentId);
}

class SaveConsultation {
  const SaveConsultation(this._repository);
  final VetRepository _repository;
  ResultFuture<Consultation> call(Consultation consultation) =>
      _repository.saveConsultation(consultation);
}

class GetPrescriptions {
  const GetPrescriptions(this._repository);
  final VetRepository _repository;
  ResultFuture<List<Prescription>> call(String consultationId) =>
      _repository.getPrescriptions(consultationId);
}

class CreatePrescription {
  const CreatePrescription(this._repository);
  final VetRepository _repository;
  ResultFuture<Prescription> call(Prescription prescription) =>
      _repository.createPrescription(prescription);
}

class GetPharmacyInventory {
  const GetPharmacyInventory(this._repository);
  final VetRepository _repository;
  ResultFuture<List<PharmacyItem>> call(String clinicId) =>
      _repository.getPharmacyInventory(clinicId);
}
