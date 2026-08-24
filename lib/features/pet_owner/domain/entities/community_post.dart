import 'package:equatable/equatable.dart';

/// Clean Architecture Entity representing a community post created by a pet owner.
class CommunityPost extends Equatable {
  const CommunityPost({
    required this.id,
    required this.userId,
    this.petId,
    required this.category,
    required this.title,
    required this.content,
    this.imageUrl,
    this.location,
    this.tags = const [],
    this.likesCount = 0,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  final String id;
  final String userId;
  final String? petId;
  final String category;
  final String title;
  final String content;
  final String? imageUrl;
  final String? location;
  final List<String> tags;
  final int likesCount;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;

    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      petId: json['pet_id'] as String?,
      category: json['category'] as String? ?? 'General',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      authorName: profiles?['full_name'] as String?,
      authorAvatarUrl: profiles?['avatar_url'] as String?,
    );
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? petId,
    String? category,
    String? title,
    String? content,
    String? imageUrl,
    String? location,
    List<String>? tags,
    int? likesCount,
    DateTime? createdAt,
    String? authorName,
    String? authorAvatarUrl,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pet_id': petId,
      'category': category,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'location': location,
      'tags': tags,
      'likes_count': likesCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        petId,
        category,
        title,
        content,
        imageUrl,
        location,
        tags,
        likesCount,
        createdAt,
      ];
}
