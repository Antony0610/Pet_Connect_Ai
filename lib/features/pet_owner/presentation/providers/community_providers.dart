import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/features/pet_owner/data/repositories/community_repository_impl.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/domain/repositories/community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final supabase = Supabase.instance.client;
  return CommunityRepositoryImpl(supabase);
});

final selectedCommunityCategoryProvider = StateProvider<String>((ref) => 'All Topics');

final communityPostsProvider =
    FutureProvider.family<List<CommunityPost>, String?>((ref, category) async {
  ref.keepAlive();
  final repo = ref.watch(communityRepositoryProvider);
  final result = await repo.getCommunityPosts(category: category);
  return result.fold(
    (failure) => <CommunityPost>[],
    (posts) => posts,
  );
});
