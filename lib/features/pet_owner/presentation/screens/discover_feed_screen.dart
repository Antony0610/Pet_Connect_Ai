import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/community_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/community_photo_viewer.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// The **Discover Feed** screen.
///
/// Provides topic exploration, full-screen interactive photo viewer,
/// grid vs feed toggle, AI-verified health guides, and live community feed.
class DiscoverFeedScreen extends ConsumerStatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  ConsumerState<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends ConsumerState<DiscoverFeedScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedTopic = 'All Topics';
  bool _isGridView = false;

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
            icon: Icon(
              _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              color: scheme.primary,
            ),
            tooltip: _isGridView ? 'Feed View' : 'Explore Grid',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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

                  // ── Live Community Posts (Feed or Grid) ────────────
                  if (_isGridView)
                    _buildGridView(context, postsAsync)
                  else
                    _buildFeedView(context, postsAsync),
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

  Widget _buildFeedView(
    BuildContext context,
    AsyncValue<List<CommunityPost>> postsAsync,
  ) {
    final scheme = context.colorScheme;

    return postsAsync.when(
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
          return _buildEmptyState(context);
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
    );
  }

  Widget _buildGridView(
    BuildContext context,
    AsyncValue<List<CommunityPost>> postsAsync,
  ) {
    final scheme = context.colorScheme;

    return postsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Text('Unable to load explore grid: $e', style: TextStyle(color: scheme.error)),
      ),
      data: (posts) {
        final photoPosts = posts.where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty).toList();

        if (photoPosts.isEmpty) {
          return _buildEmptyState(context);
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photoPosts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final post = photoPosts[index];
            return GestureDetector(
              onTap: () => showCommunityPhotoViewer(context, post),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _DiscoverMediaImage(imageUrl: post.imageUrl!, height: double.infinity),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded, size: 11, color: Colors.redAccent),
                          const SizedBox(width: 3),
                          Text(
                            '${post.likesCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = context.colorScheme;
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
}

class _DiscoverPostCard extends ConsumerStatefulWidget {
  const _DiscoverPostCard({required this.post});

  final CommunityPost post;

  @override
  ConsumerState<_DiscoverPostCard> createState() => _DiscoverPostCardState();
}

class _DiscoverPostCardState extends ConsumerState<_DiscoverPostCard>
    with SingleTickerProviderStateMixin {
  late CommunityPost _post;
  bool _isLiked = false;
  bool _showHeartAnimation = false;

  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _post = widget.post;

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartAnimController, curve: Curves.easeOutBack));

    _heartOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartAnimController);
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleDoubleTapLike() async {
    await HapticFeedback.heavyImpact();
    setState(() {
      _showHeartAnimation = true;
      if (!_isLiked) {
        _isLiked = true;
        _post = _post.copyWith(likesCount: _post.likesCount + 1);
      }
    });

    unawaited(
      _heartAnimController.forward(from: 0.0).then((_) {
        if (mounted) setState(() => _showHeartAnimation = false);
      }),
    );

    await ref.read(communityRepositoryProvider).likePost(_post.id);
    ref.invalidate(communityPostsProvider);
  }

  Future<void> _handleToggleLike() async {
    await HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
      _post = _post.copyWith(
        likesCount: _isLiked ? _post.likesCount + 1 : (_post.likesCount > 0 ? _post.likesCount - 1 : 0),
      );
    });
    await ref.read(communityRepositoryProvider).likePost(_post.id);
    ref.invalidate(communityPostsProvider);
  }

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
                  backgroundImage: (_post.authorAvatarUrl != null && _post.authorAvatarUrl!.isNotEmpty)
                      ? NetworkImage(_post.authorAvatarUrl!)
                      : null,
                  child: (_post.authorAvatarUrl == null || _post.authorAvatarUrl!.isEmpty)
                      ? Text(
                          (_post.authorName != null && _post.authorName!.isNotEmpty)
                              ? _post.authorName![0].toUpperCase()
                              : 'P',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                      : null,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _post.authorName ?? 'Pet Owner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_post.category} • ${_timeAgo(_post.createdAt)}',
                        style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (_post.location != null && _post.location!.isNotEmpty) ...[
                  Icon(Icons.location_on, size: 14, color: scheme.primary),
                  const SizedBox(width: 2),
                  Text(_post.location!, style: context.textTheme.bodySmall?.copyWith(color: scheme.primary)),
                ],
              ],
            ),
            AppSpacing.vGapMd,
            if (_post.title.isNotEmpty) ...[
              Text(
                _post.title,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapXs,
            ],
            Text(
              _post.content,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
            ),
            if (_post.imageUrl != null && _post.imageUrl!.isNotEmpty) ...[
              AppSpacing.vGapMd,
              ClipRRect(
                borderRadius: AppRadius.brCard,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => showCommunityPhotoViewer(context, _post),
                      onDoubleTap: _handleDoubleTapLike,
                      child: _DiscoverMediaImage(imageUrl: _post.imageUrl!, height: 210),
                    ),

                    if (_showHeartAnimation)
                      AnimatedBuilder(
                        animation: _heartAnimController,
                        builder: (context, _) {
                          return Opacity(
                            opacity: _heartOpacityAnimation.value,
                            child: Transform.scale(
                              scale: _heartScaleAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.35),
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.redAccent,
                                  size: 72,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: AppRadius.brPill,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 3),
                            Text(
                              'View Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            AppSpacing.vGapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_post.tags.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: _post.tags
                          .map((t) => Text('#$t', style: TextStyle(color: scheme.primary, fontSize: 12)))
                          .toList(),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                InkWell(
                  onTap: _handleToggleLike,
                  borderRadius: AppRadius.brPill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isLiked || _post.likesCount > 0
                          ? scheme.errorContainer.withValues(alpha: 0.20)
                          : scheme.surfaceContainerHigh,
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLiked || _post.likesCount > 0
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 15,
                          color: _isLiked || _post.likesCount > 0 ? scheme.error : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_post.likesCount}',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isLiked || _post.likesCount > 0 ? scheme.error : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

class _DiscoverMediaImage extends StatelessWidget {
  const _DiscoverMediaImage({required this.imageUrl, required this.height});

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return _errorPlaceholder(scheme);
      }
    } else if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final path = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(path),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorPlaceholder(scheme),
      );
    } else {
      return Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            color: scheme.surfaceContainerLow,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (_, __, ___) => _errorPlaceholder(scheme),
      );
    }
  }

  Widget _errorPlaceholder(ColorScheme scheme) {
    return Container(
      height: height,
      color: scheme.surfaceContainerLow,
      child: Center(
        child: Icon(Icons.broken_image_rounded, color: scheme.onSurfaceVariant, size: 32),
      ),
    );
  }
}
