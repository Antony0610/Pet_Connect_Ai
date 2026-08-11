import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Mission Details Screen (Stitch ID: `fa93767d86604d7f886359d445ae5904`).
///
/// Comprehensive emergency incident detail view. Displays pet profile metrics,
/// priority badge, owner contact card, last seen telemetry, and dispatch action buttons.
class MissionDetailsScreen extends StatelessWidget {
  const MissionDetailsScreen({super.key, this.missionId = 'm1'});

  final String missionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mission dispatch link copied')),
              );
            },
            tooltip: 'Share Mission',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pet Profile Header Banner ────────────────────────
                _buildPetProfileHeader(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Metric Tiles Row ────────────────────────────────
                _buildMetricsRow(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Verified Owner Contact Card ──────────────────────
                _buildOwnerContactCard(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Sighting Telemetry & Field Notes ────────────────
                _buildIncidentTelemetryCard(theme, colorScheme),

                AppSpacing.vGapXl,

                // ── Dispatch CTA Action Button ──────────────────────
                _buildDispatchAction(context, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.pets, size: 32, color: colorScheme.primary),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Luna',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    const AppChip(
                      label: 'HIGH PRIORITY',
                      backgroundColor: AppColors.lightError,
                      textColor: AppColors.white,
                    ),
                  ],
                ),
                Text(
                  'Siberian Husky • Female • 3 years old',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Silver & White coat, blue eyes • Wearing red collar with tag',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: '0.8 Miles',
            label: 'Distance Away',
            icon: Icons.near_me,
            color: colorScheme.primary,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: '15m ago',
            label: 'Last Sighting',
            icon: Icons.schedule,
            color: AppColors.warning,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            title: '3 En Route',
            label: 'Active Responders',
            icon: Icons.group,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          AppSpacing.vGapXs,
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerContactCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.surfaceContainerHigh,
                child: Icon(Icons.person, color: colorScheme.primary),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sarah Connor',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      'Verified Owner • Distraught',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call, color: AppColors.success),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling Sarah Connor...')),
                  );
                },
                tooltip: 'Call Owner',
              ),
              IconButton(
                icon: Icon(Icons.chat, color: colorScheme.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Owner Chat...')),
                  );
                },
                tooltip: 'Message Owner',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTelemetryCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: colorScheme.primary, size: 20),
              AppSpacing.hGapSm,
              Text(
                'Last Known Coordinates & Field Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            'Pine Ridge Trailhead, Sector 4 (37.7749° N, 122.4194° W)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Luna bolted after loud construction noise near the trailhead. Friendly with humans, but spooked by sudden movements. Collar emits low-power BLE beacon.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchAction(BuildContext context, ColorScheme colorScheme) {
    return AppButton(
      text: 'Accept & Begin Mission',
      icon: Icons.check_circle,
      isFullWidth: true,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission Accepted! Navigating...')),
        );
        context.push('/rescue/missions/$missionId/accepted');
      },
      backgroundColor: colorScheme.primary,
      textColor: colorScheme.onPrimary,
      height: 48,
    );
  }
}
