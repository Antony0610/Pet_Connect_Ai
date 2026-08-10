import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Community Hub** (Light
/// Theme design authority, ID `6ef9f0e7`).
///
/// Serves as the primary entry point for the Pet Owner Community sub-feature.
/// Features a glass app bar, quick-nav feature grid, signature AI tip card,
/// trending discussions list, and nearby pet owners directory.
class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  static const double _maxContentWidth = 1200;

  EdgeInsets _horizontalMargin(double width) {
    if (width >= 1024) return const EdgeInsets.symmetric(horizontal: 40);
    if (width >= 600) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: AppSpacing.md);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
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
            icon: Icon(
              Icons.search,
              size: AppIconSizes.md,
              color: scheme.onSurfaceVariant,
            ),
            tooltip: 'Search Community',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Community Search coming in Phase 2'),
                ),
              );
            },
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

          return SingleChildScrollView(
            padding: margin.copyWith(
              top: AppSpacing.md,
              bottom: AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    // ── Header Banner ──────────────────────────────────
                    Text(
                      'Connect, share, and discover with pet lovers.',
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

                    // ── Trending Discussions ──────────────────────────
                    SectionHeader(
                      title: 'Trending Discussions',
                      actionLabel: 'View All',
                      onAction: () =>
                          context.goNamed(RouteNames.ownerCommunityDiscover),
                    ),
                    AppSpacing.vGapSm,
                    _buildTrendingDiscussions(context),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(RouteNames.ownerCommunityCreatePost),
        icon: const Icon(Icons.edit),
        label: const Text('Create Post'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
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
        crossAxisAlignment: CrossAlignment.start,
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
                "Today's AI Tip",
                style: context.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const Spacer(),
              const AiSourceChip(label: 'PetConnect Health AI'),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            'With the sudden drop in temperature expected this evening, remember to limit outdoor walks for short-haired breeds like Beagles and Boxers. Consider indoor enrichment activities tonight.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingDiscussions(BuildContext context) {
    final discussions = [
      _DiscussionItem(
        title: 'Best Grain-Free Alternatives?',
        subtitle:
            'Has anyone switched from standard kibble to fresh frozen meals?',
        commentCount: 42,
        author: 'Sarah M.',
      ),
      _DiscussionItem(
        title: 'Indoor Enrichment Ideas',
        subtitle:
            'My cat seems bored lately. What interactive puzzle toys do you recommend?',
        commentCount: 18,
        author: 'David R.',
      ),
    ];

    return Column(
      children: discussions.map((d) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            onTap: () => context.goNamed(RouteNames.ownerCommunityDiscover),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text(
                        d.title,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        d.subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapMd,
                Chip(
                  avatar: Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: context.colorScheme.primary,
                  ),
                  label: Text('${d.commentCount}'),
                  backgroundColor: context.colorScheme.primaryContainer
                      .withValues(alpha: 0.4),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNearbyOwnersList(BuildContext context) {
    final scheme = context.colorScheme;
    final owners = [
      _OwnerItem(
        name: 'Sarah & Bella',
        distance: '0.5 mi',
        breed: 'Golden Retriever',
      ),
      _OwnerItem(
        name: 'Mike & Rex',
        distance: '1.2 mi',
        breed: 'German Shepherd',
      ),
      _OwnerItem(
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
            width: 200,
            child: AppCard(
              onTap: () => context.goNamed(RouteNames.ownerCommunityLocal),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  UserAvatar(name: owner.name, radius: 20),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          owner.name,
                          style: context.textTheme.labelLarge?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          owner.breed,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: scheme.primary,
                            ),
                            Text(
                              owner.distance,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _DiscussionItem {
  const _DiscussionItem({
    required this.title,
    required this.subtitle,
    required this.commentCount,
    required this.author,
  });

  final String title;
  final String subtitle;
  final int commentCount;
  final String author;
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
