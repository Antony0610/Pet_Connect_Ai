import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Saved Content**
/// (Light Theme design authority, ID `cb353721`).
///
/// Enables pet owners to view, manage, filter, and organize bookmarked articles,
/// lost pet alerts, community discussions, and saved adoption profiles.
class SavedContentScreen extends StatefulWidget {
  const SavedContentScreen({super.key});

  @override
  State<SavedContentScreen> createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends State<SavedContentScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedTab = 'Recent';

  final List<String> _tabs = const ['Recent', 'By Category', 'Collections'];

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
          'Saved Content',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Filter Tabs Row ────────────────────────────────
                Row(
                  children: _tabs.map((tab) {
                    final isSelected = _selectedTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(tab),
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
                          if (selected) setState(() => _selectedTab = tab);
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── Saved Item 1: Knowledge Article ────────────────
                AppCard(
                  onTap: () =>
                      context.goNamed(RouteNames.ownerCommunityDiscover),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            color: scheme.primary,
                            size: 18,
                          ),
                          AppSpacing.hGapXs,
                          Text(
                            'Knowledge Article',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.bookmark, color: scheme.primary),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      Text(
                        'Ultimate Guide to Puppy Socialization in 2024',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Discover the most effective, science-backed methods for introducing your new puppy to the world, ensuring they grow into confident, well-adjusted adult dogs.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'Saved 2 days ago',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapSm,

                // ── Saved Item 2: Lost Pet Alert ───────────────────
                AppCard(
                  backgroundColor: scheme.errorContainer.withValues(alpha: 0.2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.campaign, color: scheme.error, size: 18),
                          AppSpacing.hGapXs,
                          Text(
                            'Lost Pet Alert',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: scheme.error,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.bookmark, color: scheme.error),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      Text(
                        "Missing: 'Snowball'",
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Text(
                        'White Bichon Frise, female, 3 years old. Last seen near Maple Park. Wearing red collar with tags.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      AppButton.filled(
                        onPressed: () =>
                            context.goNamed(RouteNames.ownerCommunitySightings),
                        size: AppButtonSize.small,
                        child: const Text('View Details & Report'),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapSm,

                // ── Saved Item 3: Community Recipe Post ────────────
                AppCard(
                  onTap: () =>
                      context.goNamed(RouteNames.ownerCommunityDiscover),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(name: 'Alex Johnson', radius: 14),
                          AppSpacing.hGapSm,
                          Text(
                            "Alex Johnson in 'Diet & Nutrition'",
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.bookmark, color: scheme.primary),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      Text(
                        'Homemade Treats Recipe that actually works!',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        "I've been struggling to find treats that don't upset Buster's stomach. Tried this new sweet potato and oat recipe and it's a game changer.",
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapSm,

                // ── Saved Item 4: Adoption Profile ─────────────────
                AppCard(
                  onTap: () =>
                      context.goNamed(RouteNames.ownerCommunityAdoption),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.pets, color: scheme.onPrimaryContainer),
                    ),
                    title: const Text('Bella (Saved Adoption Profile)'),
                    subtitle: const Text(
                      '2 yrs • Female • City Rescue Shelter',
                    ),
                    trailing: AppButton.outlined(
                      onPressed: () =>
                          context.goNamed(RouteNames.ownerCommunityAdoption),
                      size: AppButtonSize.small,
                      child: const Text('View'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
