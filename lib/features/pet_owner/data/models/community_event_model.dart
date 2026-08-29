import 'package:petconnect_ai/features/pet_owner/domain/entities/community_event.dart';

/// Data model for CommunityEvent mapping to Supabase tables.
class CommunityEventModel extends CommunityEvent {
  const CommunityEventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.location,
    required super.eventDate,
    super.latitude,
    super.longitude,
    required super.organizerId,
    required super.organizerName,
    super.organizerAvatar,
    super.imageUrl,
    super.attendeesCount = 0,
    super.isRegistered = false,
    super.isReminderSet = false,
  });

  factory CommunityEventModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final registeredUsers = (json['registered_user_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final isReg = currentUserId != null && registeredUsers.contains(currentUserId);

    return CommunityEventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Nearby',
      location: json['location'] as String? ?? '',
      eventDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      organizerId: json['organizer_id'] as String? ?? '',
      organizerName: json['organizer_name'] as String? ?? 'Community Host',
      organizerAvatar: json['organizer_avatar'] as String?,
      imageUrl: json['image_url'] as String?,
      attendeesCount: json['attendees_count'] as int? ?? registeredUsers.length,
      isRegistered: isReg,
      isReminderSet: json['is_reminder_set'] as bool? ?? false,
    );
  }

  factory CommunityEventModel.fromEntity(CommunityEvent entity) {
    return CommunityEventModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      location: entity.location,
      eventDate: entity.eventDate,
      latitude: entity.latitude,
      longitude: entity.longitude,
      organizerId: entity.organizerId,
      organizerName: entity.organizerName,
      organizerAvatar: entity.organizerAvatar,
      imageUrl: entity.imageUrl,
      attendeesCount: entity.attendeesCount,
      isRegistered: entity.isRegistered,
      isReminderSet: entity.isReminderSet,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'event_date': eventDate.toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'organizer_id': organizerId,
      'organizer_name': organizerName,
      if (organizerAvatar != null) 'organizer_avatar': organizerAvatar,
      if (imageUrl != null) 'image_url': imageUrl,
      'attendees_count': attendeesCount,
    };
  }
}
