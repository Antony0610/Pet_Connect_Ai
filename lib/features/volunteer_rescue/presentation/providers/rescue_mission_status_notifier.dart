import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The 5 operational stages of a live animal rescue mission.
enum RescueStage {
  dispatched,
  enRoute,
  onScene,
  petSecured,
  atClinic;

  String get label {
    switch (this) {
      case RescueStage.dispatched:
        return 'Dispatched';
      case RescueStage.enRoute:
        return 'En Route';
      case RescueStage.onScene:
        return 'On Scene / Searching';
      case RescueStage.petSecured:
        return 'Pet Secured & Stabilized';
      case RescueStage.atClinic:
        return 'Delivered to Clinic / Complete';
    }
  }

  int get stepIndex => index;
}

/// A volunteer responder actively deployed to an incident.
class RescueResponder {
  const RescueResponder({
    required this.name,
    required this.role,
    required this.distanceMeters,
    required this.status,
    required this.isLead,
    required this.phone,
  });

  final String name;
  final String role;
  final int distanceMeters;
  final String status;
  final bool isLead;
  final String phone;

  RescueResponder copyWith({
    String? name,
    String? role,
    int? distanceMeters,
    String? status,
    bool? isLead,
    String? phone,
  }) {
    return RescueResponder(
      name: name ?? this.name,
      role: role ?? this.role,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      status: status ?? this.status,
      isLead: isLead ?? this.isLead,
      phone: phone ?? this.phone,
    );
  }
}

/// An active rescue mission entity.
class ActiveRescueMission {
  const ActiveRescueMission({
    required this.id,
    required this.petName,
    required this.species,
    required this.breed,
    required this.lastSeenLocation,
    required this.latitude,
    required this.longitude,
    required this.stage,
    required this.sightingHeadline,
    required this.sightingDetail,
    required this.beaconDistanceMeters,
    required this.isBeaconActive,
    required this.responders,
    required this.createdAt,
  });

  final String id;
  final String petName;
  final String species;
  final String breed;
  final String lastSeenLocation;
  final double latitude;
  final double longitude;
  final RescueStage stage;
  final String sightingHeadline;
  final String sightingDetail;
  final int beaconDistanceMeters;
  final bool isBeaconActive;
  final List<RescueResponder> responders;
  final DateTime createdAt;

  ActiveRescueMission copyWith({
    String? petName,
    String? species,
    String? breed,
    String? lastSeenLocation,
    double? latitude,
    double? longitude,
    RescueStage? stage,
    String? sightingHeadline,
    String? sightingDetail,
    int? beaconDistanceMeters,
    bool? isBeaconActive,
    List<RescueResponder>? responders,
  }) {
    return ActiveRescueMission(
      id: id,
      petName: petName ?? this.petName,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      lastSeenLocation: lastSeenLocation ?? this.lastSeenLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      stage: stage ?? this.stage,
      sightingHeadline: sightingHeadline ?? this.sightingHeadline,
      sightingDetail: sightingDetail ?? this.sightingDetail,
      beaconDistanceMeters: beaconDistanceMeters ?? this.beaconDistanceMeters,
      isBeaconActive: isBeaconActive ?? this.isBeaconActive,
      responders: responders ?? this.responders,
      createdAt: createdAt,
    );
  }
}

/// State notifier managing live rescue mission progress, beacon telemetry,
/// and responder coordination.
class RescueMissionStatusNotifier extends StateNotifier<ActiveRescueMission> {
  RescueMissionStatusNotifier() : super(_initialMission);

  static final ActiveRescueMission _initialMission = ActiveRescueMission(
    id: 'mission-8841',
    petName: 'Luna',
    species: 'Feline',
    breed: 'Domestic Shorthair (Calico)',
    lastSeenLocation: 'Cubbon Park, North Perimeter Trail',
    latitude: 12.9716,
    longitude: 77.5946,
    stage: RescueStage.enRoute,
    sightingHeadline: 'Confirmed Civilian Visual Sighting',
    sightingDetail: 'Luna matched by civilian 3 mins ago near park trail head.',
    beaconDistanceMeters: 180,
    isBeaconActive: true,
    responders: const [
      RescueResponder(
        name: 'Alex Rivera (You)',
        role: 'Lead Responder • Sector 4',
        distanceMeters: 180,
        status: 'En Route',
        isLead: true,
        phone: '+1 (555) 789-0123',
      ),
      RescueResponder(
        name: 'Sarah Jenkins',
        role: 'Vet Tech & Field Medic',
        distanceMeters: 450,
        status: 'In Transit',
        isLead: false,
        phone: '+1 (555) 890-1234',
      ),
    ],
    createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
  );

  /// Advances the mission to the next operational stage.
  void advanceStage() {
    final nextIndex = (state.stage.index + 1).clamp(0, RescueStage.values.length - 1);
    state = state.copyWith(stage: RescueStage.values[nextIndex]);
  }

  /// Sets an explicit operational stage.
  void setStage(RescueStage newStage) {
    state = state.copyWith(stage: newStage);
  }

  /// Toggles emergency high-frequency collar beacon ping.
  void toggleCollarBeacon() {
    state = state.copyWith(isBeaconActive: !state.isBeaconActive);
  }

  /// Logs a newly reported civilian sighting.
  void addSighting(String headline, String detail) {
    state = state.copyWith(
      sightingHeadline: headline,
      sightingDetail: detail,
    );
  }

  /// Adds a volunteer responder to the active team.
  void addResponder(RescueResponder responder) {
    state = state.copyWith(
      responders: [...state.responders, responder],
    );
  }
}

/// Provider managing the active emergency rescue mission.
final activeRescueMissionProvider =
    StateNotifierProvider<RescueMissionStatusNotifier, ActiveRescueMission>(
  (ref) => RescueMissionStatusNotifier(),
);
