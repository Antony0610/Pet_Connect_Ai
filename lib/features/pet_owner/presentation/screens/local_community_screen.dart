import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/community_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The **Local Community** screen connecting pet owners with local activity,
/// community posts, and verified local network directory.
class LocalCommunityScreen extends ConsumerStatefulWidget {
  const LocalCommunityScreen({super.key});

  @override
  ConsumerState<LocalCommunityScreen> createState() => _LocalCommunityScreenState();
}

class _LocalCommunityScreenState extends ConsumerState<LocalCommunityScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedCategory = 'All';

  final List<_LocalCategory> _categories = const [
    _LocalCategory('All', Icons.grid_view),
    _LocalCategory('Health', Icons.health_and_safety_outlined),
    _LocalCategory('Photo/Video', Icons.photo_camera_outlined),
    _LocalCategory('Question', Icons.help_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final selectedPet = ref.watch(selectedPetProvider);

    final postsCategoryArg = _selectedCategory == 'All' ? null : _selectedCategory;
    final postsAsync = ref.watch(communityPostsProvider(postsCategoryArg));

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Local Community',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Post',
            onPressed: () => _showCreatePostSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communityPostsProvider);
        },
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
                  // ── Hero Banner ──────────────────────────────────
                  AppCard(
                    backgroundColor: scheme.primaryContainer.withValues(
                      alpha: isDark ? 0.35 : 0.50,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Local Pet Community',
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                              AppSpacing.vGapXs,
                              Text(
                                'Connect with nearby pet owners, share advice, and explore local pet activities.',
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.hGapMd,
                        AppButton.filled(
                          onPressed: () => _showCreatePostSheet(context),
                          size: AppButtonSize.small,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 14),
                              SizedBox(width: 4),
                              Text('Share Post'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vGapLg,

                  // ── Category Filters ──────────────────────────────
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => AppSpacing.hGapSm,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat.label;
                        return ChoiceChip(
                          avatar: Icon(
                            cat.icon,
                            size: 16,
                            color: isSelected ? scheme.onPrimary : scheme.primary,
                          ),
                          label: Text(cat.label),
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
                            if (selected) {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedCategory = cat.label);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  AppSpacing.vGapLg,

                  // ── AI Community Recommendation ───────────────────
                  AiGradientBorderCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs + 2),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: scheme.primary,
                            size: 20,
                          ),
                        ),
                        AppSpacing.hGapSm,
                        Expanded(
                          child: Text(
                            selectedPet != null
                                ? 'AI Community Recommendation for ${selectedPet.name}: Local owners frequently share ${selectedPet.species == 'cat' ? 'feline enrichment & indoor wellness tips' : 'dog-friendly trail updates & leash training strategies'}.'
                                : 'AI Community Recommendation: Explore local pet tips, nutrition discussions, and verified neighborhood veterinary contacts below.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vGapLg,

                  // ── Recent Community Feed ─────────────────────────
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
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Post'),
                        onPressed: () => _showCreatePostSheet(context),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  postsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, __) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 36, color: scheme.error),
                            AppSpacing.vGapSm,
                            const Text('Unable to load community posts.'),
                            TextButton(
                              onPressed: () => ref.invalidate(communityPostsProvider),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (posts) {
                      if (posts.isEmpty) {
                        return AppCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.forum_outlined,
                                  size: 40,
                                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                AppSpacing.vGapSm,
                                Text(
                                  'No posts found in this category',
                                  style: context.textTheme.titleMedium?.copyWith(
                                    fontWeight: AppTypography.semiBold,
                                  ),
                                ),
                                AppSpacing.vGapXs,
                                Text(
                                  'Be the first to share an update or question with your local community!',
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                AppSpacing.vGapMd,
                                AppButton.filled(
                                  onPressed: () => _showCreatePostSheet(context),
                                  size: AppButtonSize.small,
                                  child: const Text('Create First Post'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (final post in posts) ...[
                            _buildPostCard(context, post),
                            AppSpacing.vGapSm,
                          ],
                        ],
                      );
                    },
                  ),
                  AppSpacing.vGapLg,

                  // ── Verified Local Directory ──────────────────────
                  const SectionHeader(
                    title: 'Verified Local Directory',
                    actionLabel: 'Browse All',
                  ),
                  AppSpacing.vGapSm,
                  _buildNetworkTile(
                    context,
                    name: 'Dr. Sarah Jenkins, DVM',
                    role: 'Veterinary Specialist',
                    location: 'City Pet Hospital • 1.2 mi',
                    icon: Icons.local_hospital,
                    isVerified: true,
                  ),
                  AppSpacing.vGapXs,
                  _buildNetworkTile(
                    context,
                    name: 'Marcus Chen',
                    role: 'Certified Rescue Volunteer',
                    location: 'Local Shelter Network • 2.5 mi',
                    icon: Icons.volunteer_activism,
                    isVerified: true,
                  ),
                  AppSpacing.vGapXs,
                  _buildNetworkTile(
                    context,
                    name: 'Elena Rodriguez',
                    role: 'Community Pet Parent',
                    location: 'Oak Park District • 0.8 mi',
                    icon: Icons.person_pin_circle_outlined,
                    isVerified: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, CommunityPost post) {
    final scheme = context.colorScheme;
    final formattedDate = DateFormat('MMM d • h:mm a').format(post.createdAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: post.authorName ?? 'Pet Owner',
                imageUrl: post.authorAvatarUrl,
                radius: 18,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName ?? 'Community Member',
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  post.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            post.title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            post.content,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            AppSpacing.vGapSm,
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                post.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          AppSpacing.vGapSm,
          Row(
            children: [
              if (post.location != null && post.location!.isNotEmpty) ...[
                Icon(Icons.place_outlined, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 3),
                Text(
                  post.location!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.favorite_border_rounded, size: 18),
                tooltip: 'Like Post',
                onPressed: () async {
                  await HapticFeedback.lightImpact();
                  await ref.read(communityRepositoryProvider).likePost(post.id);
                  ref.invalidate(communityPostsProvider);
                },
              ),
              Text(
                '${post.likesCount}',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTile(
    BuildContext context, {
    required String name,
    required String role,
    required String location,
    required IconData icon,
    required bool isVerified,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: UserAvatar(name: name, radius: 20),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            if (isVerified) ...[
              AppSpacing.hGapXs,
              Icon(Icons.verified, size: 16, color: scheme.primary),
            ],
          ],
        ),
        subtitle: Text(
          '$role • $location',
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(Icons.chat_bubble_outline_rounded, color: scheme.primary, size: 20),
        onTap: () async {
          await HapticFeedback.lightImpact();
          if (!context.mounted) return;
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  UserAvatar(name: name, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(location, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 10),
                  const Text('Verified companion in your local community radius.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: const Text('Start Chat'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(RoutePaths.ownerAiChat);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreatePostSheet(BuildContext context) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'Health';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Community Post',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              AppSpacing.vGapMd,
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Health', child: Text('Health & Wellness')),
                  DropdownMenuItem(value: 'Photo/Video', child: Text('Photo / Video')),
                  DropdownMenuItem(value: 'Question', child: Text('Question / Advice')),
                ],
                onChanged: (val) {
                  if (val != null) setSheetState(() => category = val);
                },
              ),
              AppSpacing.vGapSm,
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Great park for leash training...',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.vGapSm,
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Share details, tips, or questions...',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.vGapMd,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isEmpty || content.isEmpty) return;

                    Navigator.pop(ctx);
                    await HapticFeedback.lightImpact();

                    final repo = ref.read(communityRepositoryProvider);
                    final authUser = ref.read(supabaseClientProvider).auth.currentUser;
                    await repo.createPost(
                      userId: authUser?.id ?? '00000000-0000-0000-0000-000000000001',
                      category: category,
                      title: title,
                      content: content,
                    );

                    ref.invalidate(communityPostsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post published to local community!')),
                      );
                    }
                  },
                  child: const Text('Publish Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalCategory {
  const _LocalCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}
