import 'package:petconnect_ai/shared/domain/entity.dart';

/// Core Pet domain entity representing a record in the `pets` table.
class Pet extends Entity {
  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    this.species = 'dog',
    this.breed,
    this.gender = 'unknown',
    this.dateOfBirth,
    this.weightKg,
    this.microchipId,
    this.imageUrl,
    this.healthStatus = 'optimal',
    this.allergies = const [],
    this.chronicConditions = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? microchipId;
  final String? imageUrl;
  final String healthStatus;
  final List<String> allergies;
  final List<String> chronicConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Calculated age in years, or fallback.
  int get ageYears {
    if (dateOfBirth == null) return 2;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age > 0 ? age : 1;
  }

  /// Helper formatting breed & age string for UI display.
  String get breedLine {
    final b = (breed != null && breed!.isNotEmpty) ? breed : 'Unknown Breed';
    if (dateOfBirth == null) return b!;
    final now = DateTime.now();
    int ageYears = this.ageYears;
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

  Pet copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? species,
    String? breed,
    String? gender,
    DateTime? dateOfBirth,
    double? weightKg,
    String? microchipId,
    String? imageUrl,
    String? healthStatus,
    List<String>? allergies,
    List<String>? chronicConditions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weightKg: weightKg ?? this.weightKg,
      microchipId: microchipId ?? this.microchipId,
      imageUrl: imageUrl ?? this.imageUrl,
      healthStatus: healthStatus ?? this.healthStatus,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    species,
    breed,
    gender,
    dateOfBirth,
    weightKg,
    microchipId,
    imageUrl,
    healthStatus,
    allergies,
    chronicConditions,
    createdAt,
    updatedAt,
  ];
}
