import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
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

/// The **Community Hub** screen for all portals (Pet Owner, Vet, Volunteer/Rescue).
///
/// Features full-screen interactive photo viewing with pinch-zoom,
/// double-tap heart animations, 3-column explore photo grid toggle, quick emoji reactions,
/// live in-feed follow buttons, and role-adaptive community experience.
class CommunityHubScreen extends ConsumerStatefulWidget {
  const CommunityHubScreen({
    super.key,
    this.portalRole = AppPortal.petOwner,
    this.initialPostId,
    this.initialCommentId,
  });

  final AppPortal portalRole;
  final String? initialPostId;
  final String? initialCommentId;

  @override
  ConsumerState<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends ConsumerState<CommunityHubScreen> {
  static const double _maxContentWidth = 1200;

  bool _isGridView = false;
  bool _hasHandledInitialDeepLink = false;

  void _checkInitialDeepLink(List<CommunityPost> posts) {
    if (_hasHandledInitialDeepLink) return;
    if (widget.initialPostId == null || widget.initialPostId!.isEmpty) return;

    final matchingPost =
        posts.where((p) => p.id == widget.initialPostId).firstOrNull;
    if (matchingPost != null) {
      _hasHandledInitialDeepLink = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentUserId =
            ref.read(supabaseClientProvider).auth.currentUser?.id;
        final isAuthor = matchingPost.userId == currentUserId;
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _PostDetailSheet(
            post: matchingPost,
            isAuthor: isAuthor,
            highlightCommentId: widget.initialCommentId,
          ),
        );
      });
    }
  }

  EdgeInsets _horizontalMargin(double width) {
    if (width >= 1024) return const EdgeInsets.symmetric(horizontal: 40);
    if (width >= 600) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: AppSpacing.md);
  }

  String get _messagesRoute {
    switch (widget.portalRole) {
      case AppPortal.veterinarian:
        return RoutePaths.vetCommunityMessages;
      case AppPortal.volunteerRescue:
        return RoutePaths.rescueCommunityMessages;
      case AppPortal.petOwner:
      default:
        return RoutePaths.ownerCommunityMessages;
    }
  }

  String get _portalTitle {
    switch (widget.portalRole) {
      case AppPortal.veterinarian:
        return 'Vet Community & Clinical Hub';
      case AppPortal.volunteerRescue:
        return 'RescueOps Community Network';
      case AppPortal.petOwner:
      default:
        return 'Community Hub';
    }
  }

  Color _getPortalAccent(ColorScheme scheme) {
    switch (widget.portalRole) {
      case AppPortal.veterinarian:
        return PortalPalette.accentFor(AppPortal.veterinarian);
      case AppPortal.volunteerRescue:
        return PortalPalette.accentFor(AppPortal.volunteerRescue);
      case AppPortal.petOwner:
      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final portalAccent = _getPortalAccent(scheme);
    final postsAsync = ref.watch(communityPostsProvider(null));
    postsAsync.whenData((posts) => _checkInitialDeepLink(posts));

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final margin = _horizontalMargin(constraints.maxWidth);
        final topPad = widget.portalRole == AppPortal.petOwner
            ? context.viewPadding.top + kToolbarHeight + AppSpacing.xl
            : AppSpacing.md;

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
                      title: widget.portalRole == AppPortal.veterinarian
                          ? 'Nearby Patients & Pet Owners'
                          : widget.portalRole == AppPortal.volunteerRescue
                              ? 'Nearby Rescue Responders & Shelters'
                              : 'Nearby Pet Companions',
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
    );

    if (widget.portalRole == AppPortal.petOwner) {
      return OwnerScaffold(
        currentTab: OwnerTab.community,
        appBar: OwnerGlassAppBar(
          brandIcon: Icons.groups_rounded,
          title: Text(
            _portalTitle,
            style: context.textTheme.headlineSmall?.copyWith(
              color: portalAccent,
              fontWeight: AppTypography.bold,
              letterSpacing: -0.25,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: 'Direct Messages',
              color: portalAccent,
              onPressed: () => context.push(_messagesRoute),
            ),
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              tooltip: 'Followers & Activity',
              color: portalAccent,
              onPressed: () => _openFollowActivitySheet(context),
            ),
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
                size: AppIconSizes.md,
                color: portalAccent,
              ),
              tooltip: _isGridView ? 'Feed View' : 'Explore Grid View',
              onPressed: () => setState(() => _isGridView = !_isGridView),
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
        body: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.groups_rounded, color: portalAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              _portalTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Direct Messages',
            color: portalAccent,
            onPressed: () => context.push(_messagesRoute),
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Followers & Activity',
            color: portalAccent,
            onPressed: () => _openFollowActivitySheet(context),
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              size: AppIconSizes.md,
              color: portalAccent,
            ),
            tooltip: _isGridView ? 'Feed View' : 'Explore Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
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
      body: content,
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
        title: 'Create Post',
        icon: Icons.add_photo_alternate_rounded,
        gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
        onTap: () => context.push(RoutePaths.ownerCommunityCreatePost),
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
        title: 'Adopt Pet',
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
      crossAxisCount: 4,
      tabletCrossAxisCount: 4,
      containerSize: 46,
      iconSize: 22,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
    );
  }

  void _openFollowActivitySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _FollowActivitySheet(),
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
                  GestureDetector(
                    onTap: () => showPublicUserProfile(
                      context,
                      _post.userId,
                      _post.authorName ?? 'Community Member',
                      _post.authorAvatarUrl,
                      _post.location,
                    ),
                    child: CircleAvatar(
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
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => showPublicUserProfile(
                            context,
                            _post.userId,
                            _post.authorName ?? 'Community Member',
                            _post.authorAvatarUrl,
                            _post.location,
                          ),
                          child: Text(
                            _post.authorName ?? 'Community Member',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: AppTypography.bold,
                              color: scheme.onSurface,
                            ),
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
                  if (!isAuthor) ...[
                    const SizedBox(width: 4),
                    _FeedFollowButton(
                      authorId: _post.userId,
                      authorName: _post.authorName,
                    ),
                  ],
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
  const _PostDetailSheet({
    required this.post,
    required this.isAuthor,
    this.highlightCommentId,
  });

  final CommunityPost post;
  final bool isAuthor;
  final String? highlightCommentId;

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

  Future<void> _confirmDeleteComment(CommunityPostComment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment?'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final res = await ref.read(communityRepositoryProvider).deleteComment(comment.id);
      res.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete comment: ${failure.message}')),
        ),
        (_) {
          setState(() {
            _comments.removeWhere((c) => c.id == comment.id);
            for (final parent in _comments) {
              parent.replies.removeWhere((r) => r.id == comment.id);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Comment deleted')),
          );
        },
      );
    }
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
                GestureDetector(
                  onTap: () => showPublicUserProfile(
                    context,
                    _post.userId,
                    _post.authorName ?? 'Community Member',
                    _post.authorAvatarUrl,
                    _post.location,
                  ),
                  child: CircleAvatar(
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
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => showPublicUserProfile(
                          context,
                          _post.userId,
                          _post.authorName ?? 'Community Member',
                          _post.authorAvatarUrl,
                          _post.location,
                        ),
                        child: Text(
                          _post.authorName ?? 'Community Member',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
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
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final isCommentAuthor = c.userId == currentUserId;
    final isPostAuthor = widget.isAuthor;
    final isHighlighted = widget.highlightCommentId != null && widget.highlightCommentId == c.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: EdgeInsets.only(
        left: isReply ? 28 : 0,
        bottom: 8,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? scheme.primaryContainer.withValues(alpha: 0.65)
            : (isReply
                ? scheme.surfaceContainerHigh.withValues(alpha: 0.45)
                : scheme.surfaceContainerLow),
        borderRadius: BorderRadius.circular(14),
        border: isHighlighted
            ? Border.all(color: Colors.amber, width: 2.2)
            : (isReply
                ? Border(left: BorderSide(color: scheme.primary.withValues(alpha: 0.5), width: 3))
                : null),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => showPublicUserProfile(
                  context,
                  c.userId,
                  c.authorName,
                  c.authorAvatarUrl,
                  null,
                ),
                child: CircleAvatar(
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
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => showPublicUserProfile(
                          context,
                          c.userId,
                          c.authorName,
                          c.authorAvatarUrl,
                          null,
                        ),
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
              if (isCommentAuthor || isPostAuthor)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  tooltip: 'Delete Comment',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDeleteComment(c),
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

/// ── Public User Profile Bottom Sheet ──────────────────────────────────────────
void showPublicUserProfile(
  BuildContext context,
  String? userId,
  String authorName, [
  String? avatarUrl,
  String? location,
]) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PublicUserProfileSheet(
      userId: userId,
      authorName: authorName,
      avatarUrl: avatarUrl,
      location: location,
    ),
  );
}

class _PublicUserProfileSheet extends ConsumerStatefulWidget {
  const _PublicUserProfileSheet({
    required this.userId,
    required this.authorName,
    this.avatarUrl,
    this.location,
  });

  final String? userId;
  final String authorName;
  final String? avatarUrl;
  final String? location;

  @override
  ConsumerState<_PublicUserProfileSheet> createState() => _PublicUserProfileSheetState();
}

class _PublicUserProfileSheetState extends ConsumerState<_PublicUserProfileSheet> {
  bool _isFollowing = false;
  bool _loading = true;
  int _postCount = 0;
  int _petCount = 0;
  List<String> _petNames = [];
  String? _realCity;
  String? _realBio;
  String? _realFullName;
  String? _realAvatarUrl;
  String? _realRole;

  @override
  void initState() {
    super.initState();
    _fetchRealUserData();
  }

  Future<void> _fetchRealUserData() async {
    final client = ref.read(supabaseClientProvider);
    final targetId = widget.userId;

    if (targetId == null || targetId.isEmpty) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      // 1. Fetch user profile from Supabase
      final profileRes = await client
          .from('profiles')
          .select('full_name, bio, city, avatar_url, created_at, role')
          .eq('id', targetId)
          .maybeSingle();

      if (profileRes != null) {
        _realFullName = profileRes['full_name'] as String?;
        _realBio = profileRes['bio'] as String?;
        _realCity = profileRes['city'] as String?;
        _realAvatarUrl = profileRes['avatar_url'] as String?;
        _realRole = profileRes['role'] as String?;
      }

      // 2. Query real post count
      final postsRes = await client
          .from('community_posts')
          .select('id')
          .eq('user_id', targetId);
      _postCount = (postsRes as List).length;

      // 3. Query real registered pets
      final petsRes = await client
          .from('pets')
          .select('name, species, breed')
          .eq('owner_id', targetId);
      final petList = (petsRes as List).cast<Map<String, dynamic>>();
      _petCount = petList.length;
      _petNames = petList.map((p) => (p['name'] as String?) ?? 'Pet').toList();

      // 4. Check real follow state from user preferences or Supabase
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId != null) {
        final followCheck = await client
            .from('user_follows')
            .select('id')
            .eq('follower_id', currentUserId)
            .eq('following_id', targetId)
            .maybeSingle()
            .catchError((_) => null);
        if (followCheck != null) {
          _isFollowing = true;
        }
      }
    } catch (_) {
      // Fallback gracefully without breaking UI
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    final targetId = widget.userId;

    setState(() {
      _isFollowing = !_isFollowing;
    });

    await HapticFeedback.mediumImpact();

    if (currentUserId != null && targetId != null && targetId.isNotEmpty) {
      try {
        if (_isFollowing) {
          await client.from('user_follows').insert({
            'follower_id': currentUserId,
            'following_id': targetId,
          }).catchError((_) => null);

          final myProfile = ref.read(currentUserProfileProvider).valueOrNull;
          final myName = myProfile?.fullName ?? 'A community member';
          await client.from('user_notifications').insert({
            'user_id': targetId,
            'title': 'New Follower 🐾',
            'body': '$myName started following your pet profile.',
            'notification_type': 'social',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          }).catchError((_) => null);
        } else {
          await client
              .from('user_follows')
              .delete()
              .eq('follower_id', currentUserId)
              .eq('following_id', targetId)
              .catchError((_) => null);
        }
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            _isFollowing
                ? '✓ Now following ${_realFullName ?? widget.authorName}!'
                : 'Unfollowed ${_realFullName ?? widget.authorName}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayName = _realFullName ?? widget.authorName;
    final displayAvatar = _realAvatarUrl ?? widget.avatarUrl;
    final displayLocation = _realCity ?? widget.location ?? 'Kerala, India';
    final handle = '@${displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (_loading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: scheme.primary,
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Profile Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [scheme.primary, const Color(0xFF10B981)],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage: (displayAvatar != null && displayAvatar.isNotEmpty)
                            ? NetworkImage(displayAvatar)
                            : null,
                        child: (displayAvatar == null || displayAvatar.isEmpty)
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.verified_rounded,
                                  size: 18, color: scheme.primary),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            handle,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _realRole == 'veterinarian'
                                      ? Icons.medical_services_rounded
                                      : _realRole == 'volunteer_rescue'
                                          ? Icons.shield_rounded
                                          : Icons.pets_rounded,
                                  size: 12,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _realRole == 'veterinarian'
                                      ? '🩺 Licensed Veterinarian'
                                      : _realRole == 'volunteer_rescue'
                                          ? '🚑 Rescue Responder'
                                          : _petCount > 0
                                              ? 'Parent of ${_petNames.take(2).join(', ')}'
                                              : 'Verified Pet Parent',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Real Stats: Posts, Pets, City Location
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat(
                        'Posts',
                        '$_postCount',
                        Icons.dynamic_feed_rounded,
                        scheme.primary,
                      ),
                      _buildProfileStat(
                        'Pets',
                        '$_petCount',
                        Icons.pets_rounded,
                        const Color(0xFFF59E0B),
                      ),
                      _buildProfileStat(
                        'Location',
                        displayLocation,
                        Icons.location_on_rounded,
                        const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Real Actions: Follow & Message
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: _isFollowing
                            ? FilledButton.styleFrom(
                                backgroundColor: scheme.surfaceContainerHighest,
                                foregroundColor: scheme.onSurface,
                              )
                            : null,
                        onPressed: _toggleFollow,
                        icon: Icon(
                          _isFollowing
                              ? Icons.check_circle_rounded
                              : Icons.person_add_rounded,
                          size: 18,
                        ),
                        label: Text(_isFollowing ? 'Following' : 'Follow'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (widget.userId != null && widget.userId!.isNotEmpty) {
                            context.push('${RoutePaths.ownerCommunityMessages}?otherUserId=${widget.userId}');
                          } else {
                            context.push(RoutePaths.ownerCommunityMessages);
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Message'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Bio Section
                const Text(
                  'About Pet Parent',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  (_realBio != null && _realBio!.isNotEmpty)
                      ? _realBio!
                      : 'Dedicated pet parent in the PetConnect community. Passionate about animal wellness and rescue operations.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildProfileStat(String label, String value, IconData icon, Color color) {
  return Column(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
    ],
  );
}

/// Follow Activity and Requests Modal Sheet
class _FollowActivitySheet extends ConsumerStatefulWidget {
  const _FollowActivitySheet();

  @override
  ConsumerState<_FollowActivitySheet> createState() => _FollowActivitySheetState();
}

class _FollowActivitySheetState extends ConsumerState<_FollowActivitySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFollowData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFollowData() async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;

    if (currentUserId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      // 1. Fetch followers (people following current user)
      final followersRes = await client
          .from('user_follows')
          .select('id, follower_id, following_id, created_at')
          .eq('following_id', currentUserId);

      // 2. Fetch following (people current user follows)
      final followingRes = await client
          .from('user_follows')
          .select('id, follower_id, following_id, created_at')
          .eq('follower_id', currentUserId);

      final rawFollowers = (followersRes as List<dynamic>).cast<Map<String, dynamic>>();
      final rawFollowing = (followingRes as List<dynamic>).cast<Map<String, dynamic>>();

      final allUserIds = <String>{};
      for (final f in rawFollowers) {
        final id = f['follower_id'] as String?;
        if (id != null) allUserIds.add(id);
      }
      for (final f in rawFollowing) {
        final id = f['following_id'] as String?;
        if (id != null) allUserIds.add(id);
      }

      final profilesMap = <String, Map<String, dynamic>>{};
      if (allUserIds.isNotEmpty) {
        final pRes = await client
            .from('profiles')
            .select('id, full_name, avatar_url, city, role')
            .inFilter('id', allUserIds.toList());

        for (final p in (pRes as List<dynamic>)) {
          final pMap = p as Map<String, dynamic>;
          profilesMap[pMap['id'] as String] = pMap;
        }
      }

      final parsedFollowers = rawFollowers.map((f) {
        return {
          ...f,
          'profiles': profilesMap[f['follower_id']] ?? {
            'id': f['follower_id'],
            'full_name': 'Community Member',
            'city': 'Kerala',
          },
        };
      }).toList();

      final parsedFollowing = rawFollowing.map((f) {
        return {
          ...f,
          'profiles': profilesMap[f['following_id']] ?? {
            'id': f['following_id'],
            'full_name': 'Community Member',
            'city': 'Kerala',
          },
        };
      }).toList();

      if (mounted) {
        setState(() {
          _followers = parsedFollowers;
          _following = parsedFollowing;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unfollowUser(String? targetId, String name) async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null || targetId == null) return;

    await HapticFeedback.mediumImpact();

    setState(() {
      _following.removeWhere((f) => f['following_id'] == targetId);
    });

    try {
      await client
          .from('user_follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetId);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Unfollowed $name'),
        ),
      );
    }
  }

  Future<void> _followUser(String? targetId, String name) async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null || targetId == null) return;

    await HapticFeedback.mediumImpact();

    try {
      await client.from('user_follows').insert({
        'follower_id': currentUserId,
        'following_id': targetId,
      });

      final followingRes = await client
          .from('user_follows')
          .select('id, follower_id, following_id, created_at')
          .eq('follower_id', currentUserId);
      final rawFollowing = (followingRes as List<dynamic>).cast<Map<String, dynamic>>();

      final pRes = await client
          .from('profiles')
          .select('id, full_name, avatar_url, city, role')
          .eq('id', targetId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _following = rawFollowing.map((f) {
            return {
              ...f,
              'profiles': f['following_id'] == targetId ? pRes : null,
            };
          }).toList();
        });
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('✓ Now following $name!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.people_alt_rounded, color: scheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Followers & Community Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          TabBar(
            controller: _tabController,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            tabs: [
              Tab(text: 'Followers (${_followers.length})'),
              Tab(text: 'Following (${_following.length})'),
            ],
          ),

          if (_loading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: scheme.primary,
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_followers, isFollowerTab: true),
                _buildUserList(_following, isFollowerTab: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> items, {required bool isFollowerTab}) {
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty && !_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search_rounded, size: 48, color: scheme.outline),
              const SizedBox(height: 12),
              Text(
                isFollowerTab ? 'No followers yet' : 'You are not following anyone yet',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                isFollowerTab
                    ? 'Engage in the community feed to connect with fellow pet parents!'
                    : 'Discover pet owners nearby and tap Follow on their posts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final item = items[i];
        final profile = item['profiles'] as Map<String, dynamic>?;
        final name = profile?['full_name'] as String? ?? 'Pet Parent';
        final city = profile?['city'] as String? ?? 'Community Member';
        final avatar = profile?['avatar_url'] as String?;
        final targetId = (isFollowerTab ? item['follower_id'] : item['following_id']) as String?;
        final isFollowingThisUser = _following.any((f) => f['following_id'] == targetId);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
            child: (avatar == null || avatar.isEmpty)
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'P')
                : null,
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(city, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFollowerTab) ...[
                OutlinedButton(
                  onPressed: () => _unfollowUser(targetId, name),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: const Text('Unfollow', style: TextStyle(fontSize: 12)),
                ),
              ] else ...[
                if (isFollowingThisUser)
                  FilledButton.tonal(
                    onPressed: () => _unfollowUser(targetId, name),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text('Following', style: TextStyle(fontSize: 12)),
                  )
                else
                  FilledButton(
                    onPressed: () => _followUser(targetId, name),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text('+ Follow', style: TextStyle(fontSize: 12)),
                  ),
              ],
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                tooltip: 'Direct Message',
                onPressed: () {
                  Navigator.pop(context);
                  if (targetId != null && targetId.isNotEmpty) {
                    context.push('${RoutePaths.ownerCommunityMessages}?otherUserId=$targetId');
                  } else {
                    context.push(RoutePaths.ownerCommunityMessages);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// In-Feed Live Follow Button for Community Post Headers
class _FeedFollowButton extends ConsumerStatefulWidget {
  const _FeedFollowButton({
    required this.authorId,
    required this.authorName,
  });

  final String? authorId;
  final String? authorName;

  @override
  ConsumerState<_FeedFollowButton> createState() => _FeedFollowButtonState();
}

class _FeedFollowButtonState extends ConsumerState<_FeedFollowButton> {
  bool _isFollowing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowState();
  }

  Future<void> _checkFollowState() async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    final targetId = widget.authorId;

    if (currentUserId == null || targetId == null || targetId == currentUserId || targetId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final res = await client
          .from('user_follows')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', targetId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isFollowing = res != null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    final targetId = widget.authorId;

    if (currentUserId == null || targetId == null || targetId.isEmpty || targetId == currentUserId) return;

    await HapticFeedback.mediumImpact();

    setState(() {
      _isFollowing = !_isFollowing;
    });

    try {
      if (_isFollowing) {
        await client.from('user_follows').insert({
          'follower_id': currentUserId,
          'following_id': targetId,
        });
      } else {
        await client
            .from('user_follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', targetId);
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            _isFollowing
                ? '✓ Following ${widget.authorName ?? 'user'}'
                : 'Unfollowed ${widget.authorName ?? 'user'}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    final targetId = widget.authorId;

    if (targetId == null || targetId.isEmpty || targetId == currentUserId || _loading) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: InkWell(
        onTap: _toggleFollow,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: _isFollowing
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.7)
                : scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFollowing
                  ? scheme.outlineVariant.withValues(alpha: 0.4)
                  : scheme.primary.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isFollowing ? Icons.check : Icons.add_rounded,
                size: 11,
                color: _isFollowing ? scheme.onSurfaceVariant : scheme.primary,
              ),
              const SizedBox(width: 3),
              Text(
                _isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: _isFollowing ? scheme.onSurfaceVariant : scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
