import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Community Events**
/// (Light Theme design authority, ID `ebecca45`).
///
/// Displays local pet meetups, veterinary clinics, training workshops, and
/// AI-personalized event recommendations.
class CommunityEventsScreen extends StatefulWidget {
  const CommunityEventsScreen({super.key});

  @override
  State<CommunityEventsScreen> createState() => _CommunityEventsScreenState();
}

class _CommunityEventsScreenState extends State<CommunityEventsScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedCategory = 'Nearby';

  final List<String> _categories = const [
    'Nearby',
    'This Week',
    'Health',
    'Workshops',
  ];

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
          'Community Events',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'My Registered Events',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registered for 1 event')),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Subtitle ───────────────────────────────────────
                Text(
                  'Discover local meetups, workshops, and health clinics.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Category Filters ──────────────────────────────
                Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(cat),
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
                          if (selected) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Recommended Event Hero Card ────────────────
                AiGradientBorderCard(
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
                            'Recommended for Bella',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: const Text('Sat, 10:00 AM'),
                            backgroundColor: scheme.primaryContainer,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'Golden Retriever Weekend Romp',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Join other Golden Retriever owners for a morning of fetch, socialization, and tips on managing shedding. Great for Bella\'s high energy levels!',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        children: [
                          AppButton.filled(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Registered for Golden Retriever Romp!',
                                  ),
                                ),
                              );
                            },
                            size: AppButtonSize.small,
                            child: const Text('Register Now'),
                          ),
                          AppSpacing.hGapSm,
                          IconButton(
                            icon: const Icon(Icons.notifications_none),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Upcoming Events List ───────────────────────────
                const SectionHeader(title: 'Upcoming Local Events'),
                AppSpacing.vGapSm,
                _buildEventCard(
                  context,
                  dateBadge: 'OCT 15',
                  category: 'Clinic',
                  distance: '2.5 miles away',
                  title: 'Annual Fall Rabies Clinic',
                  description:
                      'Discounted rabies and bordetella vaccines for all registered community pets. Walk-ins welcome.',
                  price: '\$15 / Pet',
                ),
                AppSpacing.vGapSm,
                _buildEventCard(
                  context,
                  dateBadge: 'OCT 18',
                  category: 'Workshop',
                  distance: '5.0 miles away',
                  title: 'Basic Agility Intro',
                  description:
                      'A beginner-friendly introduction to dog agility courses. Boost confidence and burn energy.',
                  price: 'Free',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context, {
    required String dateBadge,
    required String category,
    required String distance,
    required String title,
    required String description,
    required String price,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                Text(
                  dateBadge.split(' ')[0],
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                  ),
                ),
                Text(
                  dateBadge.split(' ')[1],
                  style: context.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$category • $distance',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      price,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  description,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
