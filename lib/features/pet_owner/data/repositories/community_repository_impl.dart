import 'package:dartz/dartz.dart';
import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  CommunityRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;
  final List<CommunityPost> _localPosts = [];

  static final List<CommunityPost> _defaultStarterPosts = [
    CommunityPost(
      id: 'post-starter-1',
      userId: 'user-sample-1',
      category: 'Health',
      title: 'Summer Hydration Tips for Active Dogs',
      content: 'Always carry a collapsible water bowl on midday hikes! We add a few ice cubes and a dash of bone broth to encourage fluid intake after agility training.',
      imageUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800',
      location: 'Riverside Dog Park',
      tags: const ['DogCare', 'Hydration', 'SummerTips'],
      likesCount: 24,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      authorName: 'Sarah & Cooper',
      authorAvatarUrl: null,
    ),
    CommunityPost(
      id: 'post-starter-2',
      userId: 'user-sample-2',
      category: 'Photo/Video',
      title: 'First Beach Trip Milestone!',
      content: 'Luna conquered the waves today! It took a few treats and lots of encouragement, but she ended up sprinting along the shoreline with joy.',
      imageUrl: 'https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?w=800',
      location: 'Sunny Dunes Beach',
      tags: const ['GoldenRetriever', 'BeachDay', 'PuppyLife'],
      likesCount: 38,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      authorName: 'Marcus T.',
      authorAvatarUrl: null,
    ),
    CommunityPost(
      id: 'post-starter-3',
      userId: 'user-sample-3',
      category: 'Question',
      title: 'Best Harness for Pulling on Leash?',
      content: 'Looking for recommendations for front-clip no-pull harnesses that are gentle on shoulders. Any favorite durable brands for medium sized dogs?',
      imageUrl: null,
      location: 'North Suburbs',
      tags: const ['Training', 'Gear', 'Advice'],
      likesCount: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      authorName: 'Elena Chen',
      authorAvatarUrl: null,
    ),
  ];

  @override
  ResultFuture<List<CommunityPost>> getCommunityPosts({
    String? category,
    int limit = 30,
  }) async {
    try {
      var query = _supabase.from('community_posts').select('*');

      if (category != null && category != 'All' && category != 'All Topics') {
        query = query.eq('category', category);
      }

      final data = await query.order('created_at', ascending: false).limit(limit);
      final remotePosts = (data as List<dynamic>)
          .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
          .toList();

      // Merge any locally created posts that may not yet be in remote
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

      if (allPosts.isEmpty) {
        final filteredStarters = (category == null || category == 'All' || category == 'All Topics')
            ? _defaultStarterPosts
            : _defaultStarterPosts.where((p) => p.category == category).toList();
        return Right(filteredStarters);
      }

      return Right(allPosts);
    } catch (e) {
      // Return local and starter posts on offline / query issues
      final filtered = _localPosts.isNotEmpty
          ? _localPosts
          : _defaultStarterPosts;
      return Right(filtered);
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
            .select('*')
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
}
