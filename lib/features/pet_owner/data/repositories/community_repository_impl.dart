import 'package:dartz/dartz.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post_comment.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  CommunityRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;
  final List<CommunityPost> _localPosts = [];
  final Map<String, List<CommunityPost>> _cachedRemotePosts = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  List<CommunityPost> _mergePosts(List<CommunityPost> remotePosts, String? category) {
    final allPosts = <CommunityPost>[];
    final seenIds = <String>{};

    for (final post in _localPosts) {
      if (category == null || category == 'All' || category == 'All Topics' || post.category == category) {
        allPosts.add(post);
        seenIds.add(post.id);
      }
    }

    for (final post in remotePosts) {
      if (!seenIds.contains(post.id)) {
        allPosts.add(post);
        seenIds.add(post.id);
      }
    }

    return allPosts;
  }

  @override
  ResultFuture<List<CommunityPost>> getCommunityPosts({
    String? category,
    int limit = 30,
  }) async {
    final cacheKey = category ?? 'All';
    final cached = _cachedRemotePosts[cacheKey];
    final lastTime = _cacheTimestamps[cacheKey];

    // If cache is fresh (< 2 minutes old), return immediately
    if (cached != null && lastTime != null && DateTime.now().difference(lastTime).inMinutes < 2) {
      return Right(_mergePosts(cached, category));
    }

    try {
      var query = _supabase
          .from('community_posts')
          .select('*, profiles(full_name, avatar_url, email)');

      if (category != null && category != 'All' && category != 'All Topics') {
        query = query.eq('category', category);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(const Duration(seconds: 4));

      final remotePosts = (data as List<dynamic>)
          .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
          .toList();

      _cachedRemotePosts[cacheKey] = remotePosts;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(_mergePosts(remotePosts, category));
    } catch (e) {
      // If network times out or fails, return cached posts or local drafts
      if (cached != null) {
        return Right(_mergePosts(cached, category));
      }
      return Right(_localPosts);
    }
  }

  @override
  ResultFuture<CommunityPost> createPost({
    required String userId,
    String? petId,
    required String category,
    required String title,
    required String content,
    String? imageUrl,
    String? location,
    List<String> tags = const [],
  }) async {
    try {
      final authUser = _supabase.auth.currentUser;
      final safeUserId = authUser?.id ?? 
          (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(userId) 
              ? userId 
              : '00000000-0000-0000-0000-000000000001');

      final newPost = CommunityPost(
        id: 'post-local-${DateTime.now().millisecondsSinceEpoch}',
        userId: safeUserId,
        petId: petId,
        category: category,
        title: title,
        content: content,
        imageUrl: imageUrl,
        location: location,
        tags: tags,
        likesCount: 0,
        createdAt: DateTime.now(),
        authorName: authUser?.userMetadata?['full_name'] as String? ?? 'Pet Owner',
      );

      // Prepend to local memory for instant zero-latency display
      _localPosts.insert(0, newPost);

      try {
        final payload = {
          'user_id': safeUserId,
          'pet_id': petId,
          'category': category,
          'title': title,
          'content': content,
          'image_url': imageUrl,
          'location': location,
          'tags': tags,
          'likes_count': 0,
        };

        final data = await _supabase
            .from('community_posts')
            .insert(payload)
            .select('*, profiles(full_name, avatar_url, email)')
            .single();

        final remotePost = CommunityPost.fromJson(data);
        // Replace temporary local post with confirmed remote post
        final idx = _localPosts.indexWhere((p) => p.id == newPost.id);
        if (idx != -1) {
          _localPosts[idx] = remotePost;
        }
        return Right(remotePost);
      } catch (_) {
        // Return local post if remote insert fails or is offline
        return Right(newPost);
      }
    } catch (e) {
      return Left(ServerFailure('Failed to create community post: $e'));
    }
  }

  @override
  ResultFuture<void> likePost(String postId) async {
    try {
      final idx = _localPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final p = _localPosts[idx];
        _localPosts[idx] = p.copyWith(likesCount: p.likesCount + 1);
      }
      try {
        await _supabase.rpc<void>('increment_post_likes', params: {'post_id': postId});
      } catch (_) {
        // Direct update fallback if RPC encounters network issue
        try {
          await _supabase.from('community_posts').update({
            'likes_count': ((_localPosts.where((p) => p.id == postId).firstOrNull?.likesCount) ?? 1)
          }).eq('id', postId);
        } catch (_) {}
      }

      // Send in-app & live notification to post creator
      try {
        final postData = await _supabase
            .from('community_posts')
            .select('user_id, title')
            .eq('id', postId)
            .maybeSingle();

        final currentUserId = _supabase.auth.currentUser?.id;
        final authUser = _supabase.auth.currentUser;
        final currentUserName = ((authUser?.userMetadata?['full_name'] as String?)?.trim().isNotEmpty == true)
            ? authUser!.userMetadata!['full_name'] as String
            : ((authUser?.email?.isNotEmpty == true)
                ? '@${authUser!.email!.split('@').first}'
                : 'Pet Companion');

        if (postData != null) {
          final postOwnerId = postData['user_id'] as String?;
          final postTitle = postData['title'] as String? ?? 'your post';

          if (postOwnerId != null && postOwnerId.isNotEmpty && postOwnerId != currentUserId) {
            await _supabase.from('user_notifications').insert({
              'user_id': postOwnerId,
              'title': 'New Like on your post! ❤️',
              'body': '$currentUserName loved your post "$postTitle"',
              'notification_type': 'community_like',
              'is_read': false,
              'payload': {'post_id': postId},
            });
          }
        }
      } catch (_) {}

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to like post: $e'));
    }
  }

  @override
  ResultFuture<CommunityPost> updatePost({
    required String postId,
    required String title,
    required String content,
    required String category,
    String? location,
    List<String> tags = const [],
  }) async {
    try {
      final idx = _localPosts.indexWhere((p) => p.id == postId);
      CommunityPost? updated;
      if (idx != -1) {
        final current = _localPosts[idx];
        final newPost = current.copyWith(
          title: title,
          content: content,
          category: category,
          location: location,
          tags: tags,
        );
        _localPosts[idx] = newPost;
        updated = newPost;
      }

      try {
        final data = await _supabase
            .from('community_posts')
            .update({
              'title': title,
              'content': content,
              'category': category,
              'location': location,
              'tags': tags,
            })
            .eq('id', postId)
            .select('*')
            .single();
        final remote = CommunityPost.fromJson(data);
        if (idx != -1) _localPosts[idx] = remote;
        return Right(remote);
      } catch (_) {
        if (updated != null) return Right(updated);
        throw Exception('Post not found');
      }
    } catch (e) {
      return Left(ServerFailure('Failed to update post: $e'));
    }
  }

  @override
  ResultFuture<void> deletePost(String postId) async {
    try {
      _localPosts.removeWhere((p) => p.id == postId);
      try {
        await _supabase.from('community_posts').delete().eq('id', postId);
      } catch (_) {}
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete post: $e'));
    }
  }

  final Map<String, List<CommunityPostComment>> _localCommentsByPost = {};

  @override
  ResultFuture<List<CommunityPostComment>> getPostComments(String postId) async {
    try {
      final data = await _supabase
          .from('community_post_comments')
          .select('*, profiles(full_name, avatar_url, email)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final comments = (data as List<dynamic>)
          .map((json) => CommunityPostComment.fromJson(json as Map<String, dynamic>))
          .toList();

      final topLevel = <CommunityPostComment>[];
      final repliesByParent = <String, List<CommunityPostComment>>{};

      for (final c in comments) {
        if (c.parentCommentId != null && c.parentCommentId!.isNotEmpty) {
          repliesByParent.putIfAbsent(c.parentCommentId!, () => []).add(c);
        } else {
          topLevel.add(c);
        }
      }

      final resolved = topLevel.map((parent) {
        final replies = repliesByParent[parent.id] ?? const <CommunityPostComment>[];
        return parent.copyWith(replies: replies);
      }).toList();

      _localCommentsByPost[postId] = resolved;
      return Right(resolved);
    } catch (e) {
      final cached = _localCommentsByPost[postId] ?? const [];
      return Right(cached);
    }
  }

  @override
  ResultFuture<CommunityPostComment> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final authUser = _supabase.auth.currentUser;
      final safeUserId = authUser?.id ??
          (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(userId)
              ? userId
              : '00000000-0000-0000-0000-000000000001');

      final newComment = CommunityPostComment(
        id: 'comment-local-${DateTime.now().millisecondsSinceEpoch}',
        postId: postId,
        userId: safeUserId,
        parentCommentId: parentCommentId,
        content: content,
        likesCount: 0,
        createdAt: DateTime.now(),
        authorName: authUser?.userMetadata?['full_name'] as String? ?? 'Pet Owner',
        authorAvatarUrl: authUser?.userMetadata?['avatar_url'] as String?,
      );

      try {
        final payload = {
          'post_id': postId,
          'user_id': safeUserId,
          'content': content,
          if (parentCommentId != null && parentCommentId.isNotEmpty) 'parent_comment_id': parentCommentId,
          'likes_count': 0,
        };

        final data = await _supabase
            .from('community_post_comments')
            .insert(payload)
            .select('*, profiles(full_name, avatar_url, email)')
            .single();

        final remoteComment = CommunityPostComment.fromJson(data);

        // Notify post creator & parent commenter
        try {
          final authorName = authUser?.userMetadata?['full_name'] as String? ?? 'Community Member';

          // 1. If this is a reply to another comment, notify the parent commenter
          if (parentCommentId != null && parentCommentId.isNotEmpty) {
            try {
              final parentComment = await _supabase
                  .from('community_post_comments')
                  .select('user_id, content')
                  .eq('id', parentCommentId)
                  .maybeSingle();

              if (parentComment != null) {
                final parentOwnerId = parentComment['user_id'] as String?;
                if (parentOwnerId != null && parentOwnerId.isNotEmpty && parentOwnerId != safeUserId) {
                  await _supabase.from('user_notifications').insert({
                    'user_id': parentOwnerId,
                    'title': 'New Reply to your comment! 💬',
                    'body': '$authorName replied: "$content"',
                    'notification_type': 'comment_reply',
                    'is_read': false,
                    'payload': {
                      'post_id': postId,
                      'comment_id': remoteComment.id,
                      'parent_comment_id': parentCommentId,
                      'action_type': 'comment_reply',
                    },
                  });
                }
              }
            } catch (_) {}
          }

          // 2. Notify post author
          final postData = await _supabase
              .from('community_posts')
              .select('user_id, title')
              .eq('id', postId)
              .maybeSingle();

          if (postData != null) {
            final postOwnerId = postData['user_id'] as String?;
            final postTitle = postData['title'] as String? ?? 'your post';

            if (postOwnerId != null && postOwnerId.isNotEmpty && postOwnerId != safeUserId) {
              await _supabase.from('user_notifications').insert({
                'user_id': postOwnerId,
                'title': 'New Comment on your post! 💬',
                'body': '$authorName commented on "$postTitle": "$content"',
                'notification_type': 'community_comment',
                'is_read': false,
                'payload': {
                  'post_id': postId,
                  'comment_id': remoteComment.id,
                  'action_type': 'post_comment',
                },
              });
            }
          }
        } catch (_) {}

        return Right(remoteComment);
      } catch (_) {
        return Right(newComment);
      }
    } catch (e) {
      return Left(ServerFailure('Failed to add comment: $e'));
    }
  }

  @override
  ResultFuture<void> likeComment(String commentId) async {
    try {
      try {
        final current = await _supabase
            .from('community_post_comments')
            .select('user_id, post_id, content, likes_count')
            .eq('id', commentId)
            .single();
        final count = (current['likes_count'] as num?)?.toInt() ?? 0;
        await _supabase
            .from('community_post_comments')
            .update({'likes_count': count + 1})
            .eq('id', commentId);

        // Send notification to comment creator
        final commentOwnerId = current['user_id'] as String?;
        final postId = current['post_id'] as String?;
        final commentSnippet = current['content'] as String? ?? 'your comment';
        final authUser = _supabase.auth.currentUser;
        final currentUserName = authUser?.userMetadata?['full_name'] as String? ?? 'Community Member';

        if (commentOwnerId != null && authUser != null && commentOwnerId != authUser.id) {
          await _supabase.from('user_notifications').insert({
            'user_id': commentOwnerId,
            'title': 'Someone liked your comment! ❤️',
            'body': '$currentUserName loved your comment "$commentSnippet"',
            'notification_type': 'comment_like',
            'is_read': false,
            'payload': {
              'post_id': postId,
              'comment_id': commentId,
              'action_type': 'comment_like',
            },
          });
        }
      } catch (_) {}
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to like comment: $e'));
    }
  }

  @override
  ResultFuture<void> deleteComment(String commentId) async {
    try {
      await _supabase.from('community_post_comments').delete().eq('id', commentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete comment: $e'));
    }
  }
}
