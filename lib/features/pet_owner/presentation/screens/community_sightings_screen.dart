import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Community Sightings**
/// (Light Theme design authority, ID `45c1a15c`).
///
/// Displays community sighting reports, AI-driven probability clusters, and
/// location coordinates for missing pets.
class CommunitySightingsScreen extends StatefulWidget {
  const CommunitySightingsScreen({super.key});

  @override
  State<CommunitySightingsScreen> createState() =>
      _CommunitySightingsScreenState();
}

class _CommunitySightingsScreenState extends State<CommunitySightingsScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedFilter = 'Nearby';

  final List<String> _filters = const ['Nearby', 'Recent', 'Verified'];

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
          'Community Sightings',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.emergency_share, color: scheme.error),
            tooltip: 'Emergency Alert',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency broadcast active')),
              );
            },
          ),
        ],
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
                // ── Banner Description ──────────────────────────────
                Text(
                  "Recent reports matching 'Buddy's' description in your area. AI analysis suggests a high probability cluster near Pine St.",
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapMd,

                // ── Filter Chips Row ────────────────────────────────
                Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(filter),
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
                          if (selected)
                            setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Cluster Match Banner ────────────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: scheme.primary,
                            size: AppIconSizes.md,
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'AI High Probability Cluster',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          const AiConfidenceBadge(percentage: 92),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'Pine St. Intersection',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Reported by Sarah J. • 15 mins ago • 0.4 miles away',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: scheme.primary),
                          AppSpacing.hGapXs,
                          Text(
                            'Verified Sighting',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          AppButton.filled(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Opening Pine St. Sighting Map...',
                                  ),
                                ),
                              );
                            },
                            size: AppButtonSize.small,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map, size: 14),
                                SizedBox(width: 4),
                                Text('View on Map'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Sightings Feed List ────────────────────────────
                const SectionHeader(title: 'Recent Sighting Reports'),
                AppSpacing.vGapSm,
                _buildSightingCard(
                  context,
                  title: 'Oak Park North Entrance',
                  reporter: 'Reported by Mike T.',
                  timeAgo: '2 hours ago',
                  distance: '1.2 miles away',
                  confidence: 68,
                ),
                AppSpacing.vGapSm,
                _buildSightingCard(
                  context,
                  title: 'Elm St. cul-de-sac',
                  reporter: 'Reported anonymously',
                  timeAgo: '5 hours ago',
                  distance: '2.5 miles away',
                  confidence: 45,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report Sighting form opening...')),
          );
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Report Sighting'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }

  Widget _buildSightingCard(
    BuildContext context, {
    required String title,
    required String reporter,
    required String timeAgo,
    required String distance,
    required int confidence,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: scheme.primary, size: 20),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              AiConfidenceBadge(percentage: confidence),
            ],
          ),
          AppSpacing.vGapXs,
          Text(
            '$reporter • $timeAgo • $distance',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapMd,
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.outlined(
              onPressed: () {},
              size: AppButtonSize.small,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 14),
                  SizedBox(width: 4),
                  Text('View on Map'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
