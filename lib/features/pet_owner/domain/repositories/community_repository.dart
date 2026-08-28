import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post_comment.dart';

/// Clean Architecture Repository contract for Community Posts & Comments.
abstract class CommunityRepository {
  /// Fetch recent community posts ordered by creation date descending.
  ResultFuture<List<CommunityPost>> getCommunityPosts({String? category, int limit = 30});

  /// Create a new community post.
  ResultFuture<CommunityPost> createPost({
    required String userId,
    String? petId,
    required String category,
    required String title,
    required String content,
    String? imageUrl,
    String? location,
    List<String> tags = const [],
  });

  /// Toggle like on a community post.
  ResultFuture<void> likePost(String postId);

  /// Update an existing community post.
  ResultFuture<CommunityPost> updatePost({
    required String postId,
    required String title,
    required String content,
    required String category,
    String? location,
    List<String> tags = const [],
  });

  /// Delete a community post.
  ResultFuture<void> deletePost(String postId);

  /// Fetch all comments and replies for a specific post.
  ResultFuture<List<CommunityPostComment>> getPostComments(String postId);

  /// Add a comment or reply to a post.
  ResultFuture<CommunityPostComment> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  });

  /// Like a comment.
  ResultFuture<void> likeComment(String commentId);

  /// Delete a comment.
  ResultFuture<void> deleteComment(String commentId);
}

