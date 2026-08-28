import 'package:equatable/equatable.dart';

/// Clean Architecture Entity representing a comment or reply on a community post.
class CommunityPostComment extends Equatable {
  const CommunityPostComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentCommentId,
    required this.content,
    this.likesCount = 0,
    this.isLikedByMe = false,
    required this.createdAt,
    this.authorName = 'Pet Companion',
    this.authorAvatarUrl,
    this.replies = const [],
  });

  final String id;
  final String postId;
  final String userId;
  final String? parentCommentId;
  final String content;
  final int likesCount;
  final bool isLikedByMe;
  final DateTime createdAt;
  final String authorName;
  final String? authorAvatarUrl;
  final List<CommunityPostComment> replies;

  CommunityPostComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? parentCommentId,
    String? content,
    int? likesCount,
    bool? isLikedByMe,
    DateTime? createdAt,
    String? authorName,
    String? authorAvatarUrl,
    List<CommunityPostComment>? replies,
  }) {
    return CommunityPostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      replies: replies ?? this.replies,
    );
  }

  factory CommunityPostComment.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    final rawName = profiles?['full_name'] as String?;
    final rawEmail = profiles?['email'] as String?;
    final resolvedAuthorName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : (rawEmail != null && rawEmail.contains('@')
            ? rawEmail.split('@').first
            : null);

    return CommunityPostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      content: json['content'] as String? ?? '',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLikedByMe: false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      authorName: resolvedAuthorName ?? (json['author_name'] as String?) ?? 'Pet Owner',
      authorAvatarUrl: profiles?['avatar_url'] as String? ?? json['author_avatar_url'] as String?,
      replies: const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'user_id': userId,
        'parent_comment_id': parentCommentId,
        'content': content,
        'likes_count': likesCount,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        postId,
        userId,
        parentCommentId,
        content,
        likesCount,
        isLikedByMe,
        createdAt,
        authorName,
        authorAvatarUrl,
        replies,
      ];
}
