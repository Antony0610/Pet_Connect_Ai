import 'package:dartz/dartz.dart';

import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/veterinarian/data/datasources/vet_remote_datasource.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/appointment_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/consultation_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/prescription_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/vet_clinic_model.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/appointment.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/consultation.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/patient_queue_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/pharmacy_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/prescription.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_clinic.dart';
import 'package:petconnect_ai/features/veterinarian/domain/repositories/vet_repository.dart';

class VetRepositoryImpl implements VetRepository {
  const VetRepositoryImpl(this._remote);

  final VetRemoteDataSource _remote;

  @override
  ResultFuture<List<VetClinic>> getVetClinics() async {
    try {
      final list = await _remote.getVetClinics();
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<VetClinic> createVetClinic(VetClinic clinic) async {
    try {
      final model = VetClinicModel(
        id: clinic.id,
        name: clinic.name,
        address: clinic.address,
        phone: clinic.phone,
        email: clinic.email,
        licenseNumber: clinic.licenseNumber,
        ownerId: clinic.ownerId,
        createdAt: clinic.createdAt,
        updatedAt: clinic.updatedAt,
      );
      final created = await _remote.createVetClinic(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<Appointment>> getAppointments({
    String? vetId,
    String? clinicId,
  }) async {
    try {
      final list = await _remote.getAppointments(
        vetId: vetId,
        clinicId: clinicId,
      );
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<Appointment> createAppointment(Appointment appointment) async {
    try {
      final model = AppointmentModel(
        id: appointment.id,
        petId: appointment.petId,
        clinicId: appointment.clinicId,
        veterinarianId: appointment.veterinarianId,
        appointmentDate: appointment.appointmentDate,
        durationMinutes: appointment.durationMinutes,
        reason: appointment.reason,
        status: appointment.status,
        priority: appointment.priority,
        notes: appointment.notes,
        createdAt: appointment.createdAt,
        updatedAt: appointment.updatedAt,
      );
      final created = await _remote.createAppointment(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<Appointment> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      final updated = await _remote.updateAppointmentStatus(
        appointmentId,
        status,
      );
      return Right(updated);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<PatientQueueItem>> getPatientQueue({
    String? clinicId,
    String? vetId,
  }) async {
    try {
      final queue = await _remote.getPatientQueue(
        clinicId: clinicId,
        vetId: vetId,
      );
      return Right(queue);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<Consultation?> getConsultationByAppointment(
    String appointmentId,
  ) async {
    try {
      final consultation = await _remote.getConsultationByAppointment(
        appointmentId,
      );
      return Right(consultation);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<Consultation> saveConsultation(Consultation consultation) async {
    try {
      final model = ConsultationModel(
        id: consultation.id,
        appointmentId: consultation.appointmentId,
        petId: consultation.petId,
        veterinarianId: consultation.veterinarianId,
        subjective: consultation.subjective,
        objective: consultation.objective,
        assessment: consultation.assessment,
        plan: consultation.plan,
        consultationDate: consultation.consultationDate,
        createdAt: consultation.createdAt,
        updatedAt: consultation.updatedAt,
      );
      final saved = await _remote.saveConsultation(model);
      return Right(saved);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<Prescription>> getPrescriptions(
    String consultationId,
  ) async {
    try {
      final list = await _remote.getPrescriptions(consultationId);
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<Prescription> createPrescription(
    Prescription prescription,
  ) async {
    try {
      final model = PrescriptionModel(
        id: prescription.id,
        consultationId: prescription.consultationId,
        rxNumber: prescription.rxNumber,
        medicationName: prescription.medicationName,
        dosage: prescription.dosage,
        frequency: prescription.frequency,
        duration: prescription.duration,
        instructions: prescription.instructions,
        status: prescription.status,
        createdAt: prescription.createdAt,
      );
      final created = await _remote.createPrescription(model);
      return Right(created);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<PharmacyItem>> getPharmacyInventory(String clinicId) async {
    try {
      final list = await _remote.getPharmacyInventory(clinicId);
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }
}
