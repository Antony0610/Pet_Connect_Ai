import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Community Search**
/// (Light Theme design authority, ID `815fd160`).
///
/// Provides search discovery for community posts, groups, events, members,
/// recent searches, and trending tags.
class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  static const double _maxContentWidth = 1000;
  final _searchController = TextEditingController();

  final List<String> _recentSearches = const [
    'Golden Retriever meetups',
    'Local vet recommendations',
    'Puppy training basics',
  ];

  final List<String> _trendingTags = const [
    '#AdoptionDrive2024',
    '#PetHealth',
    '#DogParks',
    '#CatBehavior',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Community Search',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // ── Subtitle & Search Input ────────────────────────
                Text(
                  'Find posts, groups, events, and people in the community.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search posts, topics, members...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchController.clear());
                          },
                        )
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
                AppSpacing.vGapLg,

                // ── Quick Category Tiles ───────────────────────────
                Row(
                  children: [
                    _buildCategoryTile(
                      context,
                      title: 'Groups',
                      icon: Icons.groups,
                      color: scheme.primaryContainer,
                      onColor: scheme.onPrimaryContainer,
                      onTap: () =>
                          context.goNamed(RouteNames.ownerCommunityLocal),
                    ),
                    AppSpacing.hGapSm,
                    _buildCategoryTile(
                      context,
                      title: 'Events',
                      icon: Icons.event,
                      color: scheme.secondaryContainer,
                      onColor: scheme.onSecondaryContainer,
                      onTap: () =>
                          context.goNamed(RouteNames.ownerCommunityEvents),
                    ),
                    AppSpacing.hGapSm,
                    _buildCategoryTile(
                      context,
                      title: 'Articles',
                      icon: Icons.article_outlined,
                      color: scheme.tertiaryContainer,
                      onColor: scheme.onTertiaryContainer,
                      onTap: () =>
                          context.goNamed(RouteNames.ownerCommunityDiscover),
                    ),
                    AppSpacing.hGapSm,
                    _buildCategoryTile(
                      context,
                      title: 'Volunteers',
                      icon: Icons.volunteer_activism_outlined,
                      color: scheme.errorContainer,
                      onColor: scheme.onErrorContainer,
                      onTap: () =>
                          context.goNamed(RouteNames.ownerCommunityLostFound),
                    ),
                  ],
                ),
                AppSpacing.vGapXl,

                // ── Recent Searches ───────────────────────────────
                const SectionHeader(title: 'Recent Searches'),
                AppSpacing.vGapSm,
                ..._recentSearches.map(
                  (search) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.history,
                      color: scheme.onSurfaceVariant,
                    ),
                    title: Text(search),
                    trailing: Icon(
                      Icons.north_west,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      _searchController.text = search;
                      setState(() {});
                    },
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Trending Tags ─────────────────────────────────
                const SectionHeader(title: 'Trending Topics'),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  children: _trendingTags.map((tag) {
                    return ActionChip(
                      avatar: Icon(Icons.tag, size: 14, color: scheme.primary),
                      label: Text(tag),
                      backgroundColor: scheme.surfaceContainerHigh,
                      onPressed: () {
                        _searchController.text = tag;
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color onColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: AppCard(
        backgroundColor: color,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: onColor, size: AppIconSizes.md),
            AppSpacing.vGapXs,
            Text(
              title,
              style: context.textTheme.labelMedium?.copyWith(
                color: onColor,
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
