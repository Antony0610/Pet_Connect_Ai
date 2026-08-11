import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Rescue Community Reports Screen (Stitch ID: `28457e088c8c44b78b72258d0666fde9`).
///
/// Civilian sighting and field intelligence feed. Displays crowd-sourced pet sightings,
/// location verification status, reporter tier badges, and dispatch buttons.
class RescueCommunityReportsScreen extends StatefulWidget {
  const RescueCommunityReportsScreen({super.key});

  @override
  State<RescueCommunityReportsScreen> createState() =>
      _RescueCommunityReportsScreenState();
}

class _RescueCommunityReportsScreenState
    extends State<RescueCommunityReportsScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _reports = [
    {
      'reporter': 'Civic Reporter • Mark T.',
      'time': '5 mins ago',
      'pet': 'Luna (Siberian Husky)',
      'location': 'Spotted running near Pine Ridge Trailhead',
      'verified': true,
      'notes':
          'Matching silver coat and blue collar. Headed east toward riverbed.',
    },
    {
      'reporter': 'Civic Reporter • Elena R.',
      'time': '25 mins ago',
      'pet': 'Buddy (Golden Retriever)',
      'location': 'Near 5th & Main St Coffee Shop',
      'verified': false,
      'notes':
          'Wearing collar, sitting near outdoor tables. Skittish when approached.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Sighting Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rescue'),
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
                // ── Lead Responder Info Badge ───────────────────────
                _buildLeadResponderCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Sighting Report Feed Tabs ────────────────────────
                Row(
                  children: [
                    _buildTabChoice(
                      theme,
                      colorScheme,
                      index: 0,
                      label: 'Reported Sightings',
                    ),
                    AppSpacing.hGapSm,
                    _buildTabChoice(
                      theme,
                      colorScheme,
                      index: 1,
                      label: 'Past Rescues',
                    ),
                  ],
                ),

                AppSpacing.vGapMd,

                // ── Sighting Cards Feed ─────────────────────────────
                ..._reports.map(
                  (rpt) => _buildSightingCard(context, theme, colorScheme, rpt),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadResponderCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.verified_user, color: colorScheme.primary),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Rescue Lead Sarah',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified, size: 16, color: colorScheme.primary),
                  ],
                ),
                Text(
                  'Tier 3 Lead Responder • 128 Successful Rescues',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChoice(
    ThemeData theme,
    ColorScheme colorScheme, {
    required int index,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTab = index),
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? AppTypography.bold : AppTypography.regular,
      ),
    );
  }

  Widget _buildSightingCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> rpt,
  ) {
    final isVerified = rpt['verified'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  child: Icon(Icons.person_pin, color: colorScheme.primary),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rpt['reporter'] as String,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        rpt['pet'] as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                AppChip(
                  label: isVerified ? 'Verified' : 'Unverified',
                  backgroundColor: isVerified
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  textColor: isVerified ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    rpt['location'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapXs,
            Text(
              rpt['notes'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share Alert'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sighting link copied')),
                    );
                  },
                ),
                AppSpacing.hGapSm,
                AppButton(
                  text: 'Dispatch Unit',
                  icon: Icons.directions_run,
                  onPressed: () => context.push('/rescue/operations'),
                  height: 36,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
