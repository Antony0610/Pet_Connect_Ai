import 'package:equatable/equatable.dart';

/// Health passport timeline event entity.
class HealthTimelineEvent extends Equatable {
  const HealthTimelineEvent({
    required this.id,
    required this.petId,
    required this.eventDate,
    required this.category,
    required this.title,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  final String id;
  final String petId;
  final DateTime eventDate;
  final String category;
  final String title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        petId,
        eventDate,
        category,
        title,
        description,
        metadata,
        createdAt,
      ];
}
