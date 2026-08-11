import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Global Search Screen (Stitch ID: `6bd651abf98f4c039e2898e7357603a6`).
///
/// Ecosystem-wide search engine screen. Searches across pets, medical records,
/// AI insights, lost pet sightings, community articles, and vet clinics.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _recentSearches = [
    'Golden Retriever nutrition plan',
    'Pine Ridge lost cat sighting',
    'Oakridge Veterinary Clinic hours',
    'Flea & Tick preventative dosage',
  ];

  final List<Map<String, dynamic>> _searchResults = [
    {
      'title': 'Nutritional Needs for Senior Cats',
      'category': 'Care Guide',
      'icon': Icons.menu_book,
      'snippet': 'Comprehensive guide on senior feline diet and hydration...',
      'color': AppColors.info,
    },
    {
      'title': 'Oakridge Veterinary Clinic',
      'category': 'Vet Clinic',
      'icon': Icons.local_hospital,
      'snippet': 'Dr. Emily Watson • 123 Wellness Way • Open Now',
      'color': AppColors.success,
    },
    {
      'title': 'AI Symptom Diagnostic: Itchy Ears',
      'category': 'AI Insight',
      'icon': Icons.psychology,
      'snippet': 'Potential ear mite infection or food sensitivity alert...',
      'color': AppColors.warning,
    },
    {
      'title': 'Lost Golden Retriever: Max',
      'category': 'Lost Pet Sighting',
      'icon': Icons.location_on,
      'snippet': 'Last seen near Pine Ridge trailhead at 12:40 PM...',
      'color': AppColors.lightError,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Ecosystem Search'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search Input Bar ────────────────────────────────
                AppTextField(
                  controller: _searchController,
                  hintText:
                      'Search pets, clinics, AI insights, or community posts...',
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

                // ── Category Filter Chips ────────────────────────────
                _buildCategoryChips(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Recent Searches Section ──────────────────────────
                if (_searchController.text.isEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Searches',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _recentSearches.clear());
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentSearches.map((s) {
                      return ActionChip(
                        avatar: const Icon(Icons.history, size: 16),
                        label: Text(s),
                        onPressed: () {
                          setState(() => _searchController.text = s);
                        },
                      );
                    }).toList(),
                  ),
                  AppSpacing.vGapLg,
                ],

                // ── Search Results List ─────────────────────────────
                Text(
                  _searchController.text.isEmpty
                      ? 'Recommended Results'
                      : 'Search Results for "${_searchController.text}"',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,

                ..._searchResults.map(
                  (res) => _buildResultCard(context, theme, colorScheme, res),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, ColorScheme colorScheme) {
    final categories = [
      'All',
      'Community',
      'Knowledge',
      'Lost Pets',
      'Events',
      'AI Insights',
      'Vet Clinics',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((c) {
          final isSelected = _selectedCategory == c;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: c,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedCategory = c),
              backgroundColor: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              textColor: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> res,
  ) {
    final categoryColor = res['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: categoryColor.withValues(alpha: 0.15),
              child: Icon(res['icon'] as IconData, color: categoryColor),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          res['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      AppChip(
                        label: res['category'] as String,
                        backgroundColor: categoryColor.withValues(alpha: 0.15),
                        textColor: categoryColor,
                      ),
                    ],
                  ),
                  Text(
                    res['snippet'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
