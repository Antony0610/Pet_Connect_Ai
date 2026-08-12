import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/features/veterinarian/data/datasources/vet_remote_datasource.dart';
import 'package:petconnect_ai/features/veterinarian/data/repositories/vet_repository_impl.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/appointment.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/consultation.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/patient_queue_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/pharmacy_item.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/prescription.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_clinic.dart';
import 'package:petconnect_ai/features/veterinarian/domain/repositories/vet_repository.dart';

final vetRemoteDataSourceProvider = Provider<VetRemoteDataSource>((ref) {
  return VetRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final vetRepositoryProvider = Provider<VetRepository>((ref) {
  return VetRepositoryImpl(ref.watch(vetRemoteDataSourceProvider));
});

final vetClinicsProvider = FutureProvider<List<VetClinic>>((ref) async {
  final repo = ref.watch(vetRepositoryProvider);
  final result = await repo.getVetClinics();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (clinics) => clinics,
  );
});

final appointmentsProvider = FutureProvider.family<List<Appointment>, Map<String, String?>>((ref, params) async {
  final repo = ref.watch(vetRepositoryProvider);
  final result = await repo.getAppointments(
    vetId: params['vetId'],
    clinicId: params['clinicId'],
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (appointments) => appointments,
  );
});

final patientQueueProvider = FutureProvider.family<List<PatientQueueItem>, Map<String, String?>>((ref, params) async {
  final repo = ref.watch(vetRepositoryProvider);
  final result = await repo.getPatientQueue(
    clinicId: params['clinicId'],
    vetId: params['vetId'],
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (queue) => queue,
  );
});

final consultationProvider = FutureProvider.family<Consultation?, String>((ref, appointmentId) async {
  final repo = ref.watch(vetRepositoryProvider);
  final result = await repo.getConsultationByAppointment(appointmentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (consultation) => consultation,
  );
});

final prescriptionsProvider = FutureProvider.family<List<Prescription>, String>((ref, consultationId) async {
  final repo = ref.watch(vetRepositoryProvider);
  final result = await repo.getPrescriptions(consultationId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (prescriptions) => prescriptions,
  );
});

final pharmacyInventoryProvider = FutureProvider.family<List<PharmacyItem>, String>((ref, clinicId) async {
  final repo = ref.watch(vetRepositoryProvider);
  final result = await repo.getPharmacyInventory(clinicId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});
