import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post_comment.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/community_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/community_photo_viewer.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_bottom_nav_bar.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_scaffold.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The Pet Owner **Community Hub** screen.
///
/// Features full-screen interactive photo viewing with pinch-zoom,
/// double-tap heart animations, 3-column explore photo grid toggle, quick emoji reactions,
/// and live community feed.
class CommunityHubScreen extends ConsumerStatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  ConsumerState<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends ConsumerState<CommunityHubScreen> {
  static const double _maxContentWidth = 1200;

  bool _isGridView = false;

  EdgeInsets _horizontalMargin(double width) {
    if (width >= 1024) return const EdgeInsets.symmetric(horizontal: 40);
    if (width >= 600) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: AppSpacing.md);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final postsAsync = ref.watch(communityPostsProvider(null));

    return OwnerScaffold(
      currentTab: OwnerTab.community,
      appBar: OwnerGlassAppBar(
        brandIcon: Icons.groups_rounded,
        title: Text(
          'Community Hub',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded),
            tooltip: 'Create Post',
            color: scheme.primary,
            onPressed: () => context.push(RoutePaths.ownerCommunityCreatePost),
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              size: AppIconSizes.md,
              color: scheme.primary,
            ),
            tooltip: _isGridView ? 'Feed View' : 'Explore Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              size: AppIconSizes.md,
              color: scheme.primary,
            ),
            tooltip: 'Community Settings',
            onPressed: () => context.push(RoutePaths.ownerCommunitySettings),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: AppIconSizes.md,
              color: scheme.onSurfaceVariant,
            ),
            tooltip: 'Refresh Feed',
            onPressed: () => ref.invalidate(communityPostsProvider),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final margin = _horizontalMargin(constraints.maxWidth);
          final topPad = context.viewPadding.top + kToolbarHeight + AppSpacing.md;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(communityPostsProvider(null).future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: margin.copyWith(
                top: topPad,
                bottom: AppSpacing.xxl * 2,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Quick Nav Actions Bar (3x2 Balanced 3D Grid) ───
                      _buildQuickNavGrid(context),
                      AppSpacing.vGapLg,

                      // ── Feed Header & View Switcher ───────────────────
                      _buildFeedHeaderBar(context),
                      AppSpacing.vGapSm,

                      // ── Feed / Grid Posts ──────────────────────────────
                      if (_isGridView)
                        _buildPhotoGridView(context, postsAsync)
                      else
                        _buildLiveCommunityPosts(context, ref, postsAsync),
                      AppSpacing.vGapLg,

                      // ── Nearby Pet Owners ──────────────────────────────
                      SectionHeader(
                        title: 'Nearby Pet Companions',
                        actionLabel: 'See Local',
                        onAction: () =>
                            context.push(RoutePaths.ownerCommunityLocal),
                      ),
                      AppSpacing.vGapSm,
                      _buildNearbyOwnersList(context),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedHeaderBar(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isGridView ? 'Explore Photos' : 'Community Feed',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.view_agenda_rounded,
                color: !_isGridView ? scheme.primary : scheme.onSurfaceVariant,
                size: 20,
              ),
              tooltip: 'Feed View',
              onPressed: () => setState(() => _isGridView = false),
            ),
            IconButton(
              icon: Icon(
                Icons.grid_view_rounded,
                color: _isGridView ? scheme.primary : scheme.onSurfaceVariant,
                size: 20,
              ),
              tooltip: 'Grid Explore View',
              onPressed: () => setState(() => _isGridView = true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickNavGrid(BuildContext context) {
    final actions = [
      QuickActionItemSpec(
        title: 'Discover',
        icon: Icons.explore_rounded,
        gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        onTap: () => context.push(RoutePaths.ownerCommunityDiscover),
      ),
      QuickActionItemSpec(
        title: 'Create Post',
        icon: Icons.add_photo_alternate_rounded,
        gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
        onTap: () => context.push(RoutePaths.ownerCommunityCreatePost),
      ),
      QuickActionItemSpec(
        title: 'Local Radar',
        icon: Icons.near_me_rounded,
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0E7490)],
        onTap: () => context.push(RoutePaths.ownerCommunityLocal),
      ),
      QuickActionItemSpec(
        title: 'Lost & Found',
        icon: Icons.campaign_rounded,
        gradientColors: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
        badgeText: 'SOS',
        isDanger: true,
        onTap: () => context.push(RoutePaths.ownerCommunityLostFound),
      ),
      QuickActionItemSpec(
        title: 'Adopt a Pet',
        icon: Icons.favorite_rounded,
        gradientColors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
        onTap: () => context.push(RoutePaths.ownerCommunityAdoption),
      ),
      QuickActionItemSpec(
        title: 'Events',
        icon: Icons.event_available_rounded,
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        onTap: () => context.push(RoutePaths.ownerCommunityEvents),
      ),
    ];

    return QuickActionsGridContainer(
      items: actions,
      crossAxisCount: 3,
      tabletCrossAxisCount: 6,
      containerSize: 52,
      iconSize: 26,
    );
  }

  Widget _buildLiveCommunityPosts(
    BuildContext context,
    WidgetRef ref,
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
        child: Text('Unable to load feed: $e',
            style: TextStyle(color: scheme.error)),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: posts.map((post) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PostCard(post: post),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPhotoGridView(
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
        child: Text('Unable to load explore grid: $e',
            style: TextStyle(color: scheme.error)),
      ),
      data: (posts) {
        final photoPosts = posts
            .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
            .toList();

        if (photoPosts.isEmpty) {
          return Card(
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined,
                        size: 48, color: scheme.primary),
                    AppSpacing.vGapMd,
                    Text(
                      'No Photos in this Category',
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    AppSpacing.vGapSm,
                    Text(
                      'Share your pet\'s daily adventures to populate the explore gallery!',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photoPosts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final post = photoPosts[index];
            return GestureDetector(
              onTap: () => showCommunityPhotoViewer(context, post),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PostMediaImage(imageUrl: post.imageUrl!, height: double.infinity),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded,
                              size: 11, color: Colors.redAccent),
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
        child: Column(
          children: [
            Icon(Icons.forum_outlined, size: 48, color: scheme.primary),
            AppSpacing.vGapMd,
            Text(
              'No Posts Found',
              style: context.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapSm,
            Text(
              'Be the first to share a photo, health story, or question with the community!',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            AppSpacing.vGapMd,
            FilledButton.icon(
              onPressed: () =>
                  context.push(RoutePaths.ownerCommunityCreatePost),
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
              label: const Text('Create First Post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyOwnersList(BuildContext context) {
    final scheme = context.colorScheme;
    final petsAsync = ref.watch(petsProvider);

    return petsAsync.when(
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (pets) {
        if (pets.isEmpty) {
          return InkWell(
            onTap: () => context.push(RoutePaths.ownerCommunityLocal),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.location_city_rounded,
                        size: 18, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore Local Pet Companions',
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Find playmates & connect with nearby owners in your area',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: scheme.primary),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final pet = pets[index];
              return InkWell(
                onTap: () => context.push(RoutePaths.ownerCommunityLocal),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 130,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage: (pet.imageUrl != null && pet.imageUrl!.isNotEmpty)
                            ? NetworkImage(pet.imageUrl!)
                            : null,
                        child: (pet.imageUrl == null || pet.imageUrl!.isEmpty)
                            ? Text(
                                pet.name.isNotEmpty ? pet.name[0].toUpperCase() : 'P',
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${pet.species} • Nearby',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard>
    with SingleTickerProviderStateMixin {
  late CommunityPost _post;
  bool _isLiked = false;
  bool _isBookmarked = false;
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
    ]).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.easeOutBack),
    );

    _heartOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartAnimController);
  }

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _post = widget.post;
    }
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
        likesCount: _isLiked
            ? _post.likesCount + 1
            : (_post.likesCount > 0 ? _post.likesCount - 1 : 0),
      );
    });
    await ref.read(communityRepositoryProvider).likePost(_post.id);
    ref.invalidate(communityPostsProvider);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;
    final isAuthor =
        _post.userId == currentUser?.id || _post.id.startsWith('post-local-');

    return Card(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brSection,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPostDetails(context, ref, _post, isAuthor),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Info Header: Avatar, Name, Time, Category
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage: (_post.authorAvatarUrl != null &&
                            _post.authorAvatarUrl!.isNotEmpty)
                        ? NetworkImage(_post.authorAvatarUrl!)
                        : null,
                    child: (_post.authorAvatarUrl == null ||
                            _post.authorAvatarUrl!.isEmpty)
                        ? Text(
                            (_post.authorName != null &&
                                    _post.authorName!.isNotEmpty)
                                ? _post.authorName![0].toUpperCase()
                                : 'P',
                            style: TextStyle(
                              color: scheme.onPrimaryContainer,
                              fontWeight: AppTypography.bold,
                              fontSize: 14,
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
                          _post.authorName ?? 'Community Member',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: AppTypography.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _timeAgo(_post.createdAt),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            if (_post.location != null &&
                                _post.location!.isNotEmpty) ...[
                              Text(' • ',
                                  style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11)),
                              Icon(Icons.location_on,
                                  size: 12, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  _post.location!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Text(
                      _post.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  if (isAuthor) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showEditPostDialog(context, ref, _post);
                        } else if (val == 'delete') {
                          _showDeletePostDialog(context, ref, _post);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Post'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Post',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              AppSpacing.vGapSm,

              // Post Title
              if (_post.title.isNotEmpty) ...[
                Text(
                  _post.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.vGapXs,
              ],

              // Post Content
              Text(
                _post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.35,
                ),
              ),

              // Attached Photo with Instagram double-tap heart & tap to expand
              if (_post.imageUrl != null && _post.imageUrl!.isNotEmpty) ...[
                AppSpacing.vGapMd,
                ClipRRect(
                  borderRadius: AppRadius.brCard,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            showCommunityPhotoViewer(context, _post),
                        onDoubleTap: _handleDoubleTapLike,
                        child: Hero(
                          tag: 'post-photo-${_post.id}',
                          child: _PostMediaImage(
                              imageUrl: _post.imageUrl!, height: 230),
                        ),
                      ),

                      // Heart Animation on double tap
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
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // Tap to expand indicator badge
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: AppRadius.brPill,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen_rounded,
                                  color: Colors.white, size: 14),
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

              // Footer: Tags, Like, Comment, Bookmark, Share
              AppSpacing.vGapSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_post.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: _post.tags.map((t) {
                          return Text(
                            '#$t',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Like button
                      InkWell(
                        onTap: _handleToggleLike,
                        borderRadius: AppRadius.brPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isLiked || _post.likesCount > 0
                                ? scheme.errorContainer.withValues(alpha: 0.20)
                                : scheme.surfaceContainerHigh,
                            borderRadius: AppRadius.brPill,
                            border: Border.all(
                              color: _isLiked || _post.likesCount > 0
                                  ? scheme.error.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiked || _post.likesCount > 0
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                                color: _isLiked || _post.likesCount > 0
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_post.likesCount}',
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _isLiked || _post.likesCount > 0
                                      ? scheme.error
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Comment Button
                      InkWell(
                        onTap: () => _openPostDetails(
                            context, ref, _post, isAuthor),
                        borderRadius: AppRadius.brPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: AppRadius.brPill,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Bookmark Button
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isBookmarked = !_isBookmarked);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isBookmarked
                                  ? 'Saved to bookmarks'
                                  : 'Removed from bookmarks'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: AppRadius.brPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isBookmarked
                                ? scheme.primaryContainer.withValues(alpha: 0.3)
                                : scheme.surfaceContainerHigh,
                            borderRadius: AppRadius.brPill,
                          ),
                          child: Icon(
                            _isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 16,
                            color: _isBookmarked
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Share Button
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  'Check out "${_post.title}" on PetConnect AI: ${_post.content}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Post link copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: AppRadius.brPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: AppRadius.brPill,
                          ),
                          child: const Icon(Icons.share_outlined, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPostDetails(BuildContext context, WidgetRef ref,
      CommunityPost currentPost, bool isAuthor) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _PostDetailSheet(post: currentPost, isAuthor: isAuthor),
    );
  }

  void _showEditPostDialog(
      BuildContext context, WidgetRef ref, CommunityPost currentPost) async {
    final titleCtrl = TextEditingController(text: currentPost.title);
    final contentCtrl = TextEditingController(text: currentPost.content);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Community Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      final updatedResult =
          await ref.read(communityRepositoryProvider).updatePost(
                postId: currentPost.id,
                title: titleCtrl.text.trim(),
                content: contentCtrl.text.trim(),
                category: currentPost.category,
                location: currentPost.location,
                tags: currentPost.tags,
              );

      updatedResult.fold((_) {}, (_) {
        ref.invalidate(communityPostsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully!')),
          );
        }
      });
    }
  }

  void _showDeletePostDialog(
      BuildContext context, WidgetRef ref, CommunityPost currentPost) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(communityRepositoryProvider).deletePost(currentPost.id);
      ref.invalidate(communityPostsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted.')),
        );
      }
    }
  }
}

class _PostMediaImage extends StatelessWidget {
  const _PostMediaImage({required this.imageUrl, required this.height});

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str =
            commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
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
            child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
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
        child: Icon(Icons.broken_image_rounded,
            color: scheme.onSurfaceVariant, size: 36),
      ),
    );
  }
}

class _PostDetailSheet extends ConsumerStatefulWidget {
  const _PostDetailSheet({required this.post, required this.isAuthor});

  final CommunityPost post;
  final bool isAuthor;

  @override
  ConsumerState<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends ConsumerState<_PostDetailSheet> {
  late CommunityPost _post;
  bool _isLiked = false;
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();

  bool _isLoadingComments = true;
  List<CommunityPostComment> _comments = [];
  CommunityPostComment? _replyingToComment;

  final List<String> _quickEmojis = const ['🐾', '❤️', '🐶', '🐱', '🔥', '😍', '👏'];

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final res = await ref.read(communityRepositoryProvider).getPostComments(_post.id);
    if (!mounted) return;
    res.fold(
      (_) => setState(() => _isLoadingComments = false),
      (comments) => setState(() {
        _comments = comments;
        _isLoadingComments = false;
      }),
    );
  }

  Future<void> _handleLike() async {
    await HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
      _post = _post.copyWith(
        likesCount: _isLiked
            ? _post.likesCount + 1
            : (_post.likesCount > 0 ? _post.likesCount - 1 : 0),
      );
    });
    await ref.read(communityRepositoryProvider).likePost(_post.id);
    ref.invalidate(communityPostsProvider);
  }

  Future<void> _addComment([String? textToAdd]) async {
    final text = textToAdd ?? _commentController.text.trim();
    if (text.isEmpty) return;
    await HapticFeedback.lightImpact();

    final authUser = ref.read(supabaseClientProvider).auth.currentUser;
    final userId = authUser?.id ?? '00000000-0000-0000-0000-000000000001';
    final parentId = _replyingToComment?.id;

    if (textToAdd == null) _commentController.clear();
    setState(() => _replyingToComment = null);

    final res = await ref.read(communityRepositoryProvider).addComment(
      postId: _post.id,
      userId: userId,
      content: text,
      parentCommentId: parentId,
    );

    res.fold((_) {}, (newComment) {
      if (!mounted) return;
      _loadComments();
    });
  }

  Future<void> _handleLikeComment(CommunityPostComment comment) async {
    await HapticFeedback.selectionClick();
    setState(() {
      _comments = _comments.map((c) {
        if (c.id == comment.id) {
          return c.copyWith(likesCount: c.likesCount + 1);
        }
        final updatedReplies = c.replies.map((r) {
          if (r.id == comment.id) {
            return r.copyWith(likesCount: r.likesCount + 1);
          }
          return r;
        }).toList();
        return c.copyWith(replies: updatedReplies);
      }).toList();
    });

    await ref.read(communityRepositoryProvider).likeComment(comment.id);
  }

  void _startReply(CommunityPostComment comment) {
    HapticFeedback.lightImpact();
    setState(() {
      _replyingToComment = comment;
    });
    _commentFocusNode.requestFocus();
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  int get _totalCommentsCount {
    int total = _comments.length;
    for (final c in _comments) {
      total += c.replies.length;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView(
          controller: scrollCtrl,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: AppRadius.brPill,
                ),
              ),
            ),
            AppSpacing.vGapMd,

            // Header Row: Author & Category
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: (_post.authorAvatarUrl != null &&
                          _post.authorAvatarUrl!.isNotEmpty)
                      ? NetworkImage(_post.authorAvatarUrl!)
                      : null,
                  child: (_post.authorAvatarUrl == null ||
                          _post.authorAvatarUrl!.isEmpty)
                      ? Text(
                          (_post.authorName != null &&
                                  _post.authorName!.isNotEmpty)
                              ? _post.authorName![0].toUpperCase()
                              : 'P',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: AppTypography.bold,
                            fontSize: 15,
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
                        _post.authorName ?? 'Community Member',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${_post.category} • ${_post.location ?? "Local Community"}',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    _post.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapLg,

            // Title & Content
            if (_post.title.isNotEmpty) ...[
              Text(
                _post.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapSm,
            ],
            Text(
              _post.content,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.45),
            ),

            // Tap photo for full screen viewer
            if (_post.imageUrl != null && _post.imageUrl!.isNotEmpty) ...[
              AppSpacing.vGapLg,
              GestureDetector(
                onTap: () => showCommunityPhotoViewer(context, _post),
                child: ClipRRect(
                  borderRadius: AppRadius.brCard,
                  child: Stack(
                    children: [
                      _PostMediaImage(imageUrl: _post.imageUrl!, height: 260),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: AppRadius.brPill,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 3),
                              Text(
                                'Tap to Expand & Zoom',
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
              ),
            ],

            // Like / Action Bar
            AppSpacing.vGapLg,
            Row(
              children: [
                FilledButton.tonalIcon(
                  icon: Icon(
                    _isLiked || _post.likesCount > 0
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isLiked || _post.likesCount > 0
                        ? scheme.error
                        : scheme.onSurface,
                  ),
                  label: Text('${_post.likesCount} Likes'),
                  onPressed: _handleLike,
                ),
                AppSpacing.hGapMd,
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('$_totalCommentsCount Comments'),
                  onPressed: () {
                    scrollCtrl.animateTo(
                      scrollCtrl.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ],
            ),

            const Divider(height: 32),

            // Quick Emoji Reaction Bar
            Text(
              'Quick Reactions',
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _quickEmojis.map((emoji) {
                return InkWell(
                  onTap: () => _addComment(emoji),
                  borderRadius: AppRadius.brPill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Comments Section
            Text(
              'Comments ($_totalCommentsCount)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            AppSpacing.vGapSm,

            if (_isLoadingComments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No comments yet. Be the first to share your thoughts!',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              )
            else
              for (final c in _comments) ...[
                _buildCommentTile(c, scheme, isReply: false),
                for (final reply in c.replies)
                  _buildCommentTile(reply, scheme, isReply: true),
              ],

            AppSpacing.vGapSm,

            // Replying banner
            if (_replyingToComment != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.reply_rounded, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Replying to @${_replyingToComment?.authorName ?? "Pet Companion"}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _replyingToComment = null),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: _replyingToComment != null
                          ? 'Write a reply...'
                          : 'Add a helpful comment...',
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: const OutlineInputBorder(
                        borderRadius: AppRadius.brPill,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                AppSpacing.hGapSm,
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: () => _addComment(),
                ),
              ],
            ),
            AppSpacing.vGapXl,
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(CommunityPostComment c, ColorScheme scheme, {bool isReply = false}) {
    return Container(
      margin: EdgeInsets.only(
        left: isReply ? 28 : 0,
        bottom: 8,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isReply
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.45)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: isReply
            ? Border(left: BorderSide(color: scheme.primary.withValues(alpha: 0.5), width: 3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isReply ? 10 : 12,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: (c.authorAvatarUrl != null && c.authorAvatarUrl!.isNotEmpty)
                    ? NetworkImage(c.authorAvatarUrl!)
                    : null,
                child: (c.authorAvatarUrl == null || c.authorAvatarUrl!.isEmpty)
                    ? Text(
                        c.authorName.isNotEmpty
                            ? c.authorName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: isReply ? 9 : 11,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.authorName.isNotEmpty
                            ? c.authorName
                            : 'Pet Companion',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isReply ? 12 : 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatRelativeTime(c.createdAt),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.content,
            style: TextStyle(
              fontSize: isReply ? 12.5 : 13.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              InkWell(
                onTap: () => _handleLikeComment(c),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.likesCount > 0 ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 13,
                        color: c.likesCount > 0 ? scheme.error : scheme.onSurfaceVariant,
                      ),
                      if (c.likesCount > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          '${c.likesCount}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!isReply) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _startReply(c),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Reply',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
