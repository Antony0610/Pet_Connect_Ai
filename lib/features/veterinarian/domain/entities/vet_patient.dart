import 'package:petconnect_ai/shared/domain/entity.dart';

/// Represents a clinical patient profile in the veterinarian registry.
class VetPatient extends Entity {
  const VetPatient({
    required this.id,
    required this.name,
    this.species = 'dog',
    this.breed,
    this.gender = 'unknown',
    this.dateOfBirth,
    this.ownerId,
    this.ownerName = 'Guardian',
    this.ownerPhone,
    this.ownerEmail,
    this.status = 'Stable',
    this.healthStatus = 'optimal',
    this.lastVisitDate,
    this.weightKg,
    this.microchipId,
    this.imageUrl,
    this.notes,
  });

  final String id;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? ownerId;
  final String ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String status;
  final String healthStatus;
  final DateTime? lastVisitDate;
  final double? weightKg;
  final String? microchipId;
  final String? imageUrl;
  final String? notes;

  String get breedLine {
    final b = (breed != null && breed!.isNotEmpty) ? breed : 'Unknown Breed';
    if (dateOfBirth == null) return b!;
    final now = DateTime.now();
    int ageYears = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      ageYears--;
    }
    if (ageYears <= 0) {
      final months =
          (now.year - dateOfBirth!.year) * 12 + now.month - dateOfBirth!.month;
      return '$b • ${months <= 0 ? 1 : months} mo';
    }
    return '$b • $ageYears yr${ageYears > 1 ? 's' : ''}';
  }

  VetPatient copyWith({
    String? id,
    String? name,
    String? species,
    String? breed,
    String? gender,
    DateTime? dateOfBirth,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    String? status,
    String? healthStatus,
    DateTime? lastVisitDate,
    double? weightKg,
    String? microchipId,
    String? imageUrl,
    String? notes,
  }) {
    return VetPatient(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      status: status ?? this.status,
      healthStatus: healthStatus ?? this.healthStatus,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      weightKg: weightKg ?? this.weightKg,
      microchipId: microchipId ?? this.microchipId,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        species,
        breed,
        gender,
        dateOfBirth,
        ownerId,
        ownerName,
        ownerPhone,
        ownerEmail,
        status,
        healthStatus,
        lastVisitDate,
        weightKg,
        microchipId,
        imageUrl,
        notes,
      ];
}
