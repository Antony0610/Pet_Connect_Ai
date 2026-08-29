import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/appointment_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/clinic_analytics_summary_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/consultation_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/patient_queue_item_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/pharmacy_item_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/prescription_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/treatment_plan_model.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/vet_clinic_model.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class VetRemoteDataSource {
  Future<List<VetClinicModel>> getVetClinics();
  Future<VetClinicModel> createVetClinic(VetClinicModel clinic);

  Future<List<AppointmentModel>> getAppointments({
    String? vetId,
    String? clinicId,
  });
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);
  Future<AppointmentModel> updateAppointmentStatus(
    String appointmentId,
    String status,
  );

  Future<List<PatientQueueItemModel>> getPatientQueue({
    String? clinicId,
    String? vetId,
  });

  Future<ConsultationModel?> getConsultationByAppointment(String appointmentId);
  Future<ConsultationModel> saveConsultation(ConsultationModel consultation);

  Future<List<PrescriptionModel>> getPrescriptions(String consultationId);
  Future<PrescriptionModel> createPrescription(PrescriptionModel prescription);

  Future<List<PharmacyItemModel>> getPharmacyInventory(String clinicId);

  // Treatment Plans
  Future<List<TreatmentPlanModel>> getTreatmentPlans(String petId);
  Future<TreatmentPlanModel> saveTreatmentPlan(TreatmentPlanModel plan);

  // Patients
  Future<List<VetPatient>> getPatients({String? clinicId});
  Future<VetPatient> registerPatient(VetPatient patient);

  // Phase 11 — Analytics
  Future<List<ClinicAnalyticsSummaryModel>> getClinicAnalytics(
    String clinicId,
  );
}

class VetRemoteDataSourceImpl implements VetRemoteDataSource {
  const VetRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<VetClinicModel>> getVetClinics() async {
    try {
      final response = await _client.from('vet_clinics').select();
      return (response as List)
          .map((json) => VetClinicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch clinics: $e');
    }
  }

  @override
  Future<VetClinicModel> createVetClinic(VetClinicModel clinic) async {
    try {
      final json = clinic.toJson()..remove('id');
      final response = await _client
          .from('vet_clinics')
          .insert(json)
          .select()
          .single();
      return VetClinicModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to create clinic: $e');
    }
  }

  @override
  Future<List<AppointmentModel>> getAppointments({
    String? vetId,
    String? clinicId,
  }) async {
    try {
      var query = _client.from('appointments').select();
      if (vetId != null) query = query.eq('veterinarian_id', vetId);
      if (clinicId != null) query = query.eq('clinic_id', clinicId);

      final response = await query.order('appointment_date', ascending: true);
      return (response as List)
          .map(
            (json) => AppointmentModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch appointments: $e');
    }
  }

  @override
  Future<AppointmentModel> createAppointment(
    AppointmentModel appointment,
  ) async {
    try {
      final json = appointment.toJson()..remove('id');
      final response = await _client
          .from('appointments')
          .insert(json)
          .select()
          .single();
      return AppointmentModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to create appointment: $e');
    }
  }

  @override
  Future<AppointmentModel> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      final response = await _client
          .from('appointments')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId)
          .select()
          .single();
      return AppointmentModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to update appointment status: $e');
    }
  }

  @override
  Future<List<PatientQueueItemModel>> getPatientQueue({
    String? clinicId,
    String? vetId,
  }) async {
    try {
      var query = _client.from('vw_patient_queue').select();
      if (clinicId != null) query = query.eq('clinic_id', clinicId);
      if (vetId != null) query = query.eq('veterinarian_id', vetId);

      final response = await query.order('created_at', ascending: true);
      return (response as List)
          .map(
            (json) =>
                PatientQueueItemModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch patient queue: $e');
    }
  }

  @override
  Future<ConsultationModel?> getConsultationByAppointment(
    String appointmentId,
  ) async {
    try {
      final response = await _client
          .from('consultations')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (response == null) return null;
      return ConsultationModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch consultation: $e');
    }
  }

  @override
  Future<ConsultationModel> saveConsultation(
    ConsultationModel consultation,
  ) async {
    try {
      final json = consultation.toJson()..remove('id');
      final response = await _client
          .from('consultations')
          .upsert(json, onConflict: 'appointment_id')
          .select()
          .single();
      return ConsultationModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to save consultation: $e');
    }
  }

  @override
  Future<List<PrescriptionModel>> getPrescriptions(
    String consultationId,
  ) async {
    try {
      final response = await _client
          .from('prescriptions')
          .select()
          .eq('consultation_id', consultationId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => PrescriptionModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch prescriptions: $e');
    }
  }

  @override
  Future<PrescriptionModel> createPrescription(
    PrescriptionModel prescription,
  ) async {
    try {
      final json = prescription.toJson()..remove('id');
      final response = await _client
          .from('prescriptions')
          .insert(json)
          .select()
          .single();
      return PrescriptionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to create prescription: $e');
    }
  }

  @override
  Future<List<PharmacyItemModel>> getPharmacyInventory(String clinicId) async {
    try {
      final response = await _client
          .from('pharmacy_inventory')
          .select()
          .eq('clinic_id', clinicId)
          .order('item_name', ascending: true);

      return (response as List)
          .map(
            (json) => PharmacyItemModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch pharmacy inventory: $e');
    }
  }

  // Treatment Plans
  @override
  Future<List<TreatmentPlanModel>> getTreatmentPlans(String petId) async {
    try {
      final response = await _client
          .from('treatment_plans')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => TreatmentPlanModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch treatment plans: $e');
    }
  }

  @override
  Future<TreatmentPlanModel> saveTreatmentPlan(TreatmentPlanModel plan) async {
    try {
      final json = plan.toJson();
      if (plan.id.isEmpty) {
        json.remove('id');
      }
      final response = await _client
          .from('treatment_plans')
          .upsert(json)
          .select()
          .single();
      return TreatmentPlanModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to save treatment plan: $e');
    }
  }

  // Patients
  @override
  Future<List<VetPatient>> getPatients({String? clinicId}) async {
    try {
      final response = await _client
          .from('pets')
          .select('*, profiles:owner_id(full_name, phone, email)')
          .order('name', ascending: true);

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        final owner = map['profiles'] as Map<String, dynamic>?;
        return VetPatient(
          id: map['id'] as String,
          name: map['name'] as String? ?? 'Unknown',
          species: map['species'] as String? ?? 'dog',
          breed: map['breed'] as String?,
          gender: map['gender'] as String? ?? 'unknown',
          dateOfBirth: map['date_of_birth'] != null
              ? DateTime.tryParse(map['date_of_birth'] as String)
              : null,
          ownerId: map['owner_id'] as String?,
          ownerName: owner?['full_name'] as String? ?? 'Guardian',
          ownerPhone: owner?['phone'] as String?,
          ownerEmail: owner?['email'] as String?,
          status: 'Stable',
          healthStatus: map['health_status'] as String? ?? 'optimal',
          weightKg: (map['weight_kg'] as num?)?.toDouble(),
          microchipId: map['microchip_id'] as String?,
          imageUrl: map['image_url'] as String?,
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch patients: $e');
    }
  }

  @override
  Future<VetPatient> registerPatient(VetPatient patient) async {
    try {
      final json = {
        'name': patient.name,
        'species': patient.species,
        'breed': patient.breed,
        'gender': patient.gender,
        if (patient.dateOfBirth != null)
          'date_of_birth': patient.dateOfBirth!.toIso8601String().split('T').first,
        if (patient.ownerId != null) 'owner_id': patient.ownerId,
        'health_status': patient.healthStatus,
        if (patient.weightKg != null) 'weight_kg': patient.weightKg,
        if (patient.microchipId != null) 'microchip_id': patient.microchipId,
      };

      final response = await _client
          .from('pets')
          .insert(json)
          .select('*, profiles:owner_id(full_name, phone, email)')
          .single();

      final map = response;
      final owner = map['profiles'] as Map<String, dynamic>?;
      return VetPatient(
        id: map['id'] as String,
        name: map['name'] as String? ?? 'Unknown',
        species: map['species'] as String? ?? 'dog',
        breed: map['breed'] as String?,
        gender: map['gender'] as String? ?? 'unknown',
        dateOfBirth: map['date_of_birth'] != null
            ? DateTime.tryParse(map['date_of_birth'] as String)
            : null,
        ownerId: map['owner_id'] as String?,
        ownerName: owner?['full_name'] as String? ?? 'Guardian',
        ownerPhone: owner?['phone'] as String?,
        ownerEmail: owner?['email'] as String?,
        status: 'Stable',
        healthStatus: map['health_status'] as String? ?? 'optimal',
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        microchipId: map['microchip_id'] as String?,
        imageUrl: map['image_url'] as String?,
      );
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to register patient: $e');
    }
  }

  // Phase 11 — Analytics
  @override
  Future<List<ClinicAnalyticsSummaryModel>> getClinicAnalytics(
    String clinicId,
  ) async {
    try {
      // Reads from vw_clinic_analytics (security_invoker wrapper).
      // The view enforces that the caller owns or is staff of this clinic.
      final response = await _client
          .from('vw_clinic_analytics')
          .select()
          .eq('clinic_id', clinicId)
          .order('report_month', ascending: false);

      return (response as List)
          .map(
            (json) => ClinicAnalyticsSummaryModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        e.message,
        statusCode: int.tryParse(e.code ?? '500'),
      );
    } catch (e) {
      throw ServerException('Failed to fetch clinic analytics: $e');
    }
  }
}
