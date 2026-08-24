import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/community_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// The **Discover Feed** screen.
///
/// Provides topic category exploration, featured AI-verified health guides,
/// user success stories, and live community feed cards from Supabase.
class DiscoverFeedScreen extends ConsumerStatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  ConsumerState<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends ConsumerState<DiscoverFeedScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedTopic = 'All Topics';

  final List<String> _topics = const [
    'All Topics',
    'Photo/Video',
    'Question',
    'Story',
    'Health',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final categoryFilter = _selectedTopic == 'All Topics' ? null : _selectedTopic;
    final postsAsync = ref.watch(communityPostsProvider(categoryFilter));

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Discover Community',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(communityPostsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(communityPostsProvider(categoryFilter).future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Topic Filter Chips ─────────────────────────────
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _topics.length,
                      separatorBuilder: (_, __) => AppSpacing.hGapSm,
                      itemBuilder: (context, index) {
                        final topic = _topics[index];
                        final isSelected = _selectedTopic == topic;
                        return ChoiceChip(
                          label: Text(topic),
                          selected: isSelected,
                          selectedColor: scheme.primary,
                          backgroundColor: scheme.surfaceContainerHigh,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurface,
                            fontWeight: AppTypography.semiBold,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedTopic = topic);
                          },
                        );
                      },
                    ),
                  ),
                  AppSpacing.vGapLg,

                  // ── Featured AI Verified Guide ─────────────────────
                  AiGradientBorderCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified, color: scheme.primary, size: 18),
                            AppSpacing.hGapXs,
                            Text(
                              'AI Verified',
                              style: context.textTheme.labelLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            Text(
                              ' • Clinical Guide',
                              style: context.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          'Hydration & Diet Guidelines for Active Pets',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        AppSpacing.vGapXs,
                        Text(
                          'Maintaining electrolyte balance and fresh water intake during warmer months protects renal health and prevents heat exhaustion.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vGapLg,

                  // ── Live Community Posts ───────────────────────────
                  postsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Text('Unable to load feed: $e', style: TextStyle(color: scheme.error)),
                    ),
                    data: (posts) {
                      if (posts.isEmpty) {
                        return Card(
                          color: scheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.forum_outlined, size: 40, color: scheme.primary),
                                  AppSpacing.vGapMd,
                                  Text(
                                    'No posts in this category yet',
                                    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  AppSpacing.vGapSm,
                                  Text(
                                    'Share your own stories or photos to start the conversation!',
                                    style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: posts.map((post) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _DiscoverPostCard(post: post),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.ownerCommunityCreatePost),
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('New Post'),
      ),
    );
  }
}

class _DiscoverPostCard extends StatelessWidget {
  const _DiscoverPostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Card(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brSection,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    (post.authorName ?? 'P')[0].toUpperCase(),
                    style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                  ),
                ),
                AppSpacing.hGapSm,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName ?? 'Pet Owner',
                      style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${post.category} • ${_timeAgo(post.createdAt)}',
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
                if (post.location != null) ...[
                  const Spacer(),
                  Icon(Icons.location_on, size: 14, color: scheme.primary),
                  Text(post.location!, style: context.textTheme.bodySmall?.copyWith(color: scheme.primary)),
                ],
              ],
            ),
            AppSpacing.vGapMd,
            Text(
              post.title,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapXs,
            Text(
              post.content,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
            ),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              AppSpacing.vGapMd,
              ClipRRect(
                borderRadius: AppRadius.brCard,
                child: Image.network(
                  post.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (post.tags.isNotEmpty) ...[
              AppSpacing.vGapSm,
              Wrap(
                spacing: 6,
                children: post.tags.map((t) => Text('#$t', style: TextStyle(color: scheme.primary, fontSize: 12))).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
