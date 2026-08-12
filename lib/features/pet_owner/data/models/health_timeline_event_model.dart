import 'package:petconnect_ai/features/pet_owner/domain/entities/health_timeline_event.dart';

class HealthTimelineEventModel extends HealthTimelineEvent {
  const HealthTimelineEventModel({
    required super.id,
    required super.petId,
    required super.eventDate,
    required super.category,
    required super.title,
    super.description,
    super.metadata,
    required super.createdAt,
  });

  factory HealthTimelineEventModel.fromJson(Map<String, dynamic> json) {
    return HealthTimelineEventModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      category: (json['category'] as String?) ?? 'Medical',
      title: json['title'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'event_date': eventDate.toIso8601String(),
      'category': category,
      'title': title,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
