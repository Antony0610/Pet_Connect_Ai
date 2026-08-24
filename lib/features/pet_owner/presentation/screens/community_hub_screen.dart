import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/community_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_bottom_nav_bar.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_scaffold.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The Pet Owner **Community Hub** screen.
///
/// Features a quick-nav feature grid, signature AI tip card,
/// live community posts feed connected to Supabase, and nearby pet owners directory.
class CommunityHubScreen extends ConsumerWidget {
  const CommunityHubScreen({super.key});

  static const double _maxContentWidth = 1200;

  EdgeInsets _horizontalMargin(double width) {
    if (width >= 1024) return const EdgeInsets.symmetric(horizontal: 40);
    if (width >= 600) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: AppSpacing.md);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final postsAsync = ref.watch(communityPostsProvider(null));

    return OwnerScaffold(
      currentTab: OwnerTab.community,
      appBar: OwnerGlassAppBar(
        brandIcon: Icons.groups,
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
              Icons.refresh,
              size: AppIconSizes.md,
              color: scheme.onSurfaceVariant,
            ),
            tooltip: 'Refresh Feed',
            onPressed: () => ref.invalidate(communityPostsProvider),
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              size: AppIconSizes.md,
              color: scheme.onSurfaceVariant,
            ),
            tooltip: 'Search Community',
            onPressed: () => context.goNamed(RouteNames.ownerCommunitySearch),
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              size: AppIconSizes.md,
              color: scheme.onSurfaceVariant,
            ),
            tooltip: 'Notifications',
            onPressed: () => context.goNamed(RouteNames.ownerNotifications),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final margin = _horizontalMargin(constraints.maxWidth);

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(communityPostsProvider(null).future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: margin.copyWith(
                top: AppSpacing.md,
                bottom: AppSpacing.xxl * 2,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header Banner ──────────────────────────────────
                      Text(
                        'Connect, share photos, and discover with fellow pet lovers.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapLg,

                      // ── Quick Nav Actions Grid ─────────────────────────
                      _buildQuickNavGrid(context),
                      AppSpacing.vGapXl,

                      // ── Signature AI Tip Card ─────────────────────────
                      _buildAiTipCard(context),
                      AppSpacing.vGapXl,

                      // ── Recent Community Posts ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Community Feed',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                context.goNamed(RouteNames.ownerCommunityDiscover),
                            icon: const Icon(Icons.explore_outlined, size: 16),
                            label: const Text('Discover All'),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      _buildLiveCommunityPosts(context, ref, postsAsync),
                      AppSpacing.vGapXl,

                      // ── Nearby Pet Owners ──────────────────────────────
                      SectionHeader(
                        title: 'Nearby Pet Owners',
                        actionLabel: 'See Local',
                        onAction: () =>
                            context.goNamed(RouteNames.ownerCommunityLocal),
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

  Widget _buildQuickNavGrid(BuildContext context) {
    final scheme = context.colorScheme;

    final actions = [
      _NavActionData(
        title: 'Discover',
        icon: Icons.explore_outlined,
        color: scheme.primaryContainer,
        onColor: scheme.onPrimaryContainer,
        onTap: () => context.goNamed(RouteNames.ownerCommunityDiscover),
      ),
      _NavActionData(
        title: 'Create Post',
        icon: Icons.edit_square,
        color: scheme.secondaryContainer,
        onColor: scheme.onSecondaryContainer,
        onTap: () => context.goNamed(RouteNames.ownerCommunityCreatePost),
      ),
      _NavActionData(
        title: 'Local',
        icon: Icons.location_on_outlined,
        color: scheme.tertiaryContainer,
        onColor: scheme.onTertiaryContainer,
        onTap: () => context.goNamed(RouteNames.ownerCommunityLocal),
      ),
      _NavActionData(
        title: 'Lost & Found',
        icon: Icons.campaign_outlined,
        color: scheme.errorContainer,
        onColor: scheme.onErrorContainer,
        onTap: () => context.goNamed(RouteNames.ownerCommunityLostFound),
      ),
      _NavActionData(
        title: 'Adoption',
        icon: Icons.favorite_outline,
        color: scheme.primaryContainer.withValues(alpha: 0.7),
        onColor: scheme.onPrimaryContainer,
        onTap: () => context.goNamed(RouteNames.ownerCommunityAdoption),
      ),
      _NavActionData(
        title: 'Events',
        icon: Icons.event_outlined,
        color: scheme.secondaryContainer.withValues(alpha: 0.7),
        onColor: scheme.onSecondaryContainer,
        onTap: () => context.goNamed(RouteNames.ownerCommunityEvents),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return AppCard(
          backgroundColor: item.color,
          onTap: item.onTap,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.onColor, size: AppIconSizes.lg),
              AppSpacing.vGapXs,
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: context.textTheme.labelMedium?.copyWith(
                  color: item.onColor,
                  fontWeight: AppTypography.semiBold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiTipCard(BuildContext context) {
    final scheme = context.colorScheme;

    return AiGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: scheme.primary,
                size: AppIconSizes.md,
              ),
              AppSpacing.hGapSm,
              Text(
                'AI Community Insight',
                style: context.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            'Spring season alerts: 3 nearby pet owners reported high pollen irritations. Keep paw wipes ready after outdoor walks!',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
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
        child: Text('Unable to load feed: $e', style: TextStyle(color: scheme.error)),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Card(
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(Icons.forum_outlined, size: 48, color: scheme.primary),
                  AppSpacing.vGapMd,
                  Text(
                    'No Posts Yet',
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.vGapSm,
                  Text(
                    'Be the first to share a photo, health story, or question with the community!',
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  AppSpacing.vGapMd,
                  FilledButton.icon(
                    onPressed: () =>
                        context.goNamed(RouteNames.ownerCommunityCreatePost),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Create First Post'),
                  ),
                ],
              ),
            ),
          );
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

  Widget _buildNearbyOwnersList(BuildContext context) {
    final scheme = context.colorScheme;
    final owners = [
      const _OwnerItem(
        name: 'Sarah & Bella',
        distance: '0.5 mi',
        breed: 'Golden Retriever',
      ),
      const _OwnerItem(
        name: 'Mike & Rex',
        distance: '1.2 mi',
        breed: 'German Shepherd',
      ),
      const _OwnerItem(
        name: 'Alex & Garfield',
        distance: '1.8 mi',
        breed: 'Tabby Cat',
      ),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: owners.length,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          final owner = owners[index];
          return SizedBox(
            width: 140,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.secondaryContainer,
                    child: Text(
                      owner.name[0],
                      style: TextStyle(
                        color: scheme.onSecondaryContainer,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    owner.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    '${owner.breed} • ${owner.distance}',
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
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;
    final isAuthor = post.userId == currentUser?.id || post.id.startsWith('post-local-');

    return Card(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brSection,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPostDetails(context, ref, post, isAuthor),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Category chip, Location, and Date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Text(
                      post.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  if (post.location != null) ...[
                    AppSpacing.hGapSm,
                    Icon(Icons.location_on, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        post.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Text(
                    _timeAgo(post.createdAt),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
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
                        _showEditPostDialog(context, ref, post);
                      } else if (val == 'delete') {
                        _showDeletePostDialog(context, ref, post);
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
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Post', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.vGapSm,

              // Post Title
              Text(
                post.title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.vGapXs,

              // Post Content
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.35,
                ),
              ),

              // Attached Photo Preview
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                AppSpacing.vGapMd,
                ClipRRect(
                  borderRadius: AppRadius.brCard,
                  child: _PostMediaImage(imageUrl: post.imageUrl!, height: 200),
                ),
              ],

              // Footer: Tags & Likes
              AppSpacing.vGapSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (post.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: post.tags.map((t) {
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
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: post.likesCount > 0 ? scheme.error : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: post.likesCount > 0 ? scheme.error : scheme.onSurfaceVariant,
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

  void _openPostDetails(BuildContext context, WidgetRef ref, CommunityPost currentPost, bool isAuthor) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PostDetailSheet(post: currentPost, isAuthor: true),
    );
  }

  void _showEditPostDialog(BuildContext context, WidgetRef ref, CommunityPost currentPost) async {
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
      final updatedResult = await ref.read(communityRepositoryProvider).updatePost(
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

  void _showDeletePostDialog(BuildContext context, WidgetRef ref, CommunityPost currentPost) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
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

    if (confirm == true && context.mounted) {
      await ref.read(communityRepositoryProvider).deletePost(currentPost.id);
      ref.invalidate(communityPostsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted.')),
        );
      }
    }
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
        child: Icon(Icons.broken_image_rounded, color: scheme.onSurfaceVariant, size: 36),
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
  final List<String> _localComments = [
    'Great insight! Thanks for sharing.',
  ];

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _post = _post.copyWith(
        likesCount: _isLiked ? _post.likesCount + 1 : (_post.likesCount > 0 ? _post.likesCount - 1 : 0),
      );
    });
    await ref.read(communityRepositoryProvider).likePost(_post.id);
  }

  Future<void> _handleEdit() async {
    final titleCtrl = TextEditingController(text: _post.title);
    final contentCtrl = TextEditingController(text: _post.content);

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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final updatedResult = await ref.read(communityRepositoryProvider).updatePost(
        postId: _post.id,
        title: titleCtrl.text.trim(),
        content: contentCtrl.text.trim(),
        category: _post.category,
        location: _post.location,
        tags: _post.tags,
      );

      updatedResult.fold((_) {}, (up) {
        if (mounted) {
          setState(() => _post = up);
          ref.invalidate(communityPostsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully!')),
          );
        }
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(communityRepositoryProvider).deletePost(_post.id);
      ref.invalidate(communityPostsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted.')),
        );
      }
    }
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _localComments.add(text);
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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

            // Header Row: Author & Actions
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.person, color: scheme.primary, size: 22),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _post.authorName ?? 'Community Member',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${_post.category} • ${_post.location ?? "Local Community"}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.isAuthor) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Post',
                    onPressed: _handleEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    tooltip: 'Delete Post',
                    onPressed: _handleDelete,
                  ),
                ],
              ],
            ),
            AppSpacing.vGapLg,

            // Title & Content
            Text(
              _post.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapSm,
            Text(
              _post.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
            ),

            // Zoomable Image View
            if (_post.imageUrl != null && _post.imageUrl!.isNotEmpty) ...[
              AppSpacing.vGapLg,
              ClipRRect(
                borderRadius: AppRadius.brCard,
                child: InteractiveViewer(
                  maxScale: 3.5,
                  child: _PostMediaImage(imageUrl: _post.imageUrl!, height: 260),
                ),
              ),
            ],

            // Like / Action Bar
            AppSpacing.vGapLg,
            Row(
              children: [
                FilledButton.tonalIcon(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? scheme.error : scheme.onSurface,
                  ),
                  label: Text('${_post.likesCount} Likes'),
                  onPressed: _handleLike,
                ),
                AppSpacing.hGapMd,
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('${_localComments.length} Comments'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${_localComments.length} comments loaded below.'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),

            const Divider(height: 36),

            // Comments Section
            Text(
              'Comments (${_localComments.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            AppSpacing.vGapSm,
            for (final c in _localComments)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: AppRadius.brCard,
                  ),
                  child: Text(c, style: const TextStyle(fontSize: 13.5)),
                ),
              ),

            AppSpacing.vGapSm,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a helpful comment...',
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: const OutlineInputBorder(
                        borderRadius: AppRadius.brPill,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                AppSpacing.hGapSm,
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _addComment,
                ),
              ],
            ),
            AppSpacing.vGapXl,
          ],
        ),
      ),
    );
  }
}

class _NavActionData {
  const _NavActionData({
    required this.title,
    required this.icon,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;
}

class _OwnerItem {
  const _OwnerItem({
    required this.name,
    required this.distance,
    required this.breed,
  });

  final String name;
  final String distance;
  final String breed;
}
