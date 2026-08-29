import 'package:equatable/equatable.dart';

/// Entity representing a Community Event / Meetup.
class CommunityEvent extends Equatable {
  const CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.eventDate,
    this.latitude,
    this.longitude,
    required this.organizerId,
    required this.organizerName,
    this.organizerAvatar,
    this.imageUrl,
    this.attendeesCount = 0,
    this.isRegistered = false,
    this.isReminderSet = false,
  });

  final String id;
  final String title;
  final String description;
  final String category; // 'Nearby', 'Health', 'Workshops', 'Social'
  final String location;
  final DateTime eventDate;
  final double? latitude;
  final double? longitude;
  final String organizerId;
  final String organizerName;
  final String? organizerAvatar;
  final String? imageUrl;
  final int attendeesCount;
  final bool isRegistered;
  final bool isReminderSet;

  CommunityEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    DateTime? eventDate,
    double? latitude,
    double? longitude,
    String? organizerId,
    String? organizerName,
    String? organizerAvatar,
    String? imageUrl,
    int? attendeesCount,
    bool? isRegistered,
    bool? isReminderSet,
  }) {
    return CommunityEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerAvatar: organizerAvatar ?? this.organizerAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      isRegistered: isRegistered ?? this.isRegistered,
      isReminderSet: isReminderSet ?? this.isReminderSet,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        location,
        eventDate,
        latitude,
        longitude,
        organizerId,
        organizerName,
        organizerAvatar,
        imageUrl,
        attendeesCount,
        isRegistered,
        isReminderSet,
      ];
}
