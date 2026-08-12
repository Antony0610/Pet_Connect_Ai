import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/appointment.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/consultation.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/patient_queue_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/pharmacy_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/prescription.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_clinic.dart';

/// Repository interface for Veterinarian Portal domain operations.
abstract class VetRepository {
  // Vet Clinics
  ResultFuture<List<VetClinic>> getVetClinics();
  ResultFuture<VetClinic> createVetClinic(VetClinic clinic);

  // Appointments
  ResultFuture<List<Appointment>> getAppointments({String? vetId, String? clinicId});
  ResultFuture<Appointment> createAppointment(Appointment appointment);
  ResultFuture<Appointment> updateAppointmentStatus(String appointmentId, String status);

  // Patient Queue
  ResultFuture<List<PatientQueueItem>> getPatientQueue({String? clinicId, String? vetId});

  // Consultations
  ResultFuture<Consultation?> getConsultationByAppointment(String appointmentId);
  ResultFuture<Consultation> saveConsultation(Consultation consultation);

  // Prescriptions
  ResultFuture<List<Prescription>> getPrescriptions(String consultationId);
  ResultFuture<Prescription> createPrescription(Prescription prescription);

  // Pharmacy Inventory
  ResultFuture<List<PharmacyItem>> getPharmacyInventory(String clinicId);
}
