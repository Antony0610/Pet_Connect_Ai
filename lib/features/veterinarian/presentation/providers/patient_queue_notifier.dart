import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clinical triage stage for queued veterinary patients.
enum TriageStatus {
  waiting,
  inTriage,
  inConsultation,
  discharged;

  String get label {
    switch (this) {
      case TriageStatus.waiting:
        return 'Waiting Room';
      case TriageStatus.inTriage:
        return 'In Triage';
      case TriageStatus.inConsultation:
        return 'In Consultation';
      case TriageStatus.discharged:
        return 'Discharged';
    }
  }
}

/// Clinical urgency priority level.
enum TriagePriority {
  critical,
  urgent,
  routine;

  String get label {
    switch (this) {
      case TriagePriority.critical:
        return 'CRITICAL (P1)';
      case TriagePriority.urgent:
        return 'URGENT (P2)';
      case TriagePriority.routine:
        return 'ROUTINE (P3)';
    }
  }
}

/// Active patient queued in the clinic triage workflow.
class TriagePatientItem {
  const TriagePatientItem({
    required this.id,
    required this.name,
    required this.breedAge,
    required this.species,
    required this.priority,
    required this.reason,
    required this.waitTimeMinutes,
    required this.ownerName,
    required this.ownerPhone,
    required this.status,
    required this.appointmentId,
    this.temperatureC,
    this.heartRateBpm,
  });

  final String id;
  final String name;
  final String breedAge;
  final String species;
  final TriagePriority priority;
  final String reason;
  final int waitTimeMinutes;
  final String ownerName;
  final String ownerPhone;
  final TriageStatus status;
  final String appointmentId;
  final double? temperatureC;
  final int? heartRateBpm;

  TriagePatientItem copyWith({
    String? name,
    String? breedAge,
    String? species,
    TriagePriority? priority,
    String? reason,
    int? waitTimeMinutes,
    String? ownerName,
    String? ownerPhone,
    TriageStatus? status,
    String? appointmentId,
    double? temperatureC,
    int? heartRateBpm,
  }) {
    return TriagePatientItem(
      id: id,
      name: name ?? this.name,
      breedAge: breedAge ?? this.breedAge,
      species: species ?? this.species,
      priority: priority ?? this.priority,
      reason: reason ?? this.reason,
      waitTimeMinutes: waitTimeMinutes ?? this.waitTimeMinutes,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      status: status ?? this.status,
      appointmentId: appointmentId ?? this.appointmentId,
      temperatureC: temperatureC ?? this.temperatureC,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
    );
  }
}

/// State notifier managing live patient triage workflows, state transitions,
/// and queue re-ordering.
class PatientQueueNotifier extends StateNotifier<List<TriagePatientItem>> {
  PatientQueueNotifier() : super(_initialQueue);

  static final List<TriagePatientItem> _initialQueue = [
    const TriagePatientItem(
      id: 'p1',
      name: 'Buster',
      breedAge: 'Golden Retriever • 5y',
      species: 'Canine',
      priority: TriagePriority.critical,
      reason: 'Acute facial angioedema & anaphylaxis reaction.',
      waitTimeMinutes: 25,
      ownerName: 'Sarah Jenkins',
      ownerPhone: '+1 (555) 234-8901',
      status: TriageStatus.waiting,
      appointmentId: 'apt-001',
      temperatureC: 39.2,
      heartRateBpm: 128,
    ),
    const TriagePatientItem(
      id: 'p2',
      name: 'Luna',
      breedAge: 'Domestic Shorthair • 2y',
      species: 'Feline',
      priority: TriagePriority.urgent,
      reason: 'Non-weight bearing lameness on left forelimb.',
      waitTimeMinutes: 15,
      ownerName: 'Michael Chen',
      ownerPhone: '+1 (555) 345-9012',
      status: TriageStatus.inTriage,
      appointmentId: 'apt-002',
      temperatureC: 38.6,
      heartRateBpm: 160,
    ),
    const TriagePatientItem(
      id: 'p3',
      name: 'Winston',
      breedAge: 'Pug • 6mo',
      species: 'Canine',
      priority: TriagePriority.routine,
      reason: 'Annual core vaccination booster & wellness exam.',
      waitTimeMinutes: 5,
      ownerName: 'Emily Davis',
      ownerPhone: '+1 (555) 456-0123',
      status: TriageStatus.waiting,
      appointmentId: 'apt-003',
      temperatureC: 38.4,
      heartRateBpm: 94,
    ),
    const TriagePatientItem(
      id: 'p4',
      name: 'Oliver',
      breedAge: 'Maine Coon • 4y',
      species: 'Feline',
      priority: TriagePriority.critical,
      reason: 'Post-op laparoscopic telemetry anomaly.',
      waitTimeMinutes: 30,
      ownerName: 'Robert Wilson',
      ownerPhone: '+1 (555) 567-1234',
      status: TriageStatus.inConsultation,
      appointmentId: 'apt-004',
      temperatureC: 37.9,
      heartRateBpm: 142,
    ),
  ];

  /// Advances a patient to the next clinical stage.
  void advanceStatus(String patientId) {
    state = [
      for (final p in state)
        if (p.id == patientId)
          p.copyWith(
            status: _nextStatus(p.status),
          )
        else
          p,
    ];
  }

  /// Sets an explicit status for a patient.
  void setStatus(String patientId, TriageStatus newStatus) {
    state = [
      for (final p in state)
        if (p.id == patientId) p.copyWith(status: newStatus) else p,
    ];
  }

  /// Adds a newly checked-in patient to the clinic queue.
  void addPatient({
    required String name,
    required String breedAge,
    required String species,
    required TriagePriority priority,
    required String reason,
    required String ownerName,
    required String ownerPhone,
    double? temperatureC,
    int? heartRateBpm,
  }) {
    final newItem = TriagePatientItem(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      breedAge: breedAge,
      species: species,
      priority: priority,
      reason: reason,
      waitTimeMinutes: 1,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      status: TriageStatus.waiting,
      appointmentId: 'apt-${DateTime.now().millisecondsSinceEpoch}',
      temperatureC: temperatureC,
      heartRateBpm: heartRateBpm,
    );

    // Insert critical cases at the top of the queue
    if (priority == TriagePriority.critical) {
      state = [newItem, ...state];
    } else {
      state = [...state, newItem];
    }
  }

  /// Removes a patient from the queue.
  void removePatient(String patientId) {
    state = state.where((p) => p.id != patientId).toList();
  }

  static TriageStatus _nextStatus(TriageStatus current) {
    switch (current) {
      case TriageStatus.waiting:
        return TriageStatus.inTriage;
      case TriageStatus.inTriage:
        return TriageStatus.inConsultation;
      case TriageStatus.inConsultation:
        return TriageStatus.discharged;
      case TriageStatus.discharged:
        return TriageStatus.discharged;
    }
  }
}

/// Provider for the live patient triage queue.
final patientQueueStateProvider =
    StateNotifierProvider<PatientQueueNotifier, List<TriagePatientItem>>(
  (ref) => PatientQueueNotifier(),
);
