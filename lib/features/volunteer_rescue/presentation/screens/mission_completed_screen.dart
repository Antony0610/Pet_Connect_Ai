import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Mission Completed Screen (Stitch ID: `97a26f78f6d4445795807aa4f188124f`).
///
/// Rescue debrief and reunion summary view. Displays duration metrics, distance covered,
/// owner gratitude quote, photo proof placeholder, and return to dashboard action.
class MissionCompletedScreen extends StatelessWidget {
  const MissionCompletedScreen({super.key, this.missionId = 'm1'});

  final String missionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Resolution'),
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
                // ── Rescue Successful Celebration Banner ───────────
                _buildSuccessCelebrationBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Mission Impact Metrics Row ──────────────────────
                _buildImpactMetricsRow(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Owner Gratitude Testimonial ──────────────────────
                _buildOwnerTestimonialCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Photo Proof & Reunion Report Action ─────────────
                _buildReunionPhotoUploadCard(context, theme, colorScheme),

                AppSpacing.vGapXl,

                // ── Return to Dashboard Button ──────────────────────
                AppButton(
                  text: 'Return to Mission Dashboard',
                  icon: Icons.dashboard,
                  isFullWidth: true,
                  onPressed: () => context.go('/rescue'),
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  height: 48,
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCelebrationBanner(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.success,
            child: Icon(Icons.pets, size: 36, color: Colors.white),
          ),
          AppSpacing.vGapMd,
          Text(
            'Rescue Successful!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: AppTypography.bold,
              color: AppColors.success,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Luna has been safely reunited with her family.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetricsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '42m',
            label: 'Duration',
            icon: Icons.timer_outlined,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '1.2 Miles',
            label: 'Covered',
            icon: Icons.route_outlined,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '4 Team',
            label: 'Volunteers',
            icon: Icons.group_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          AppSpacing.vGapXs,
          Text(
            value,
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

  Widget _buildOwnerTestimonialCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: colorScheme.primary, size: 24),
              AppSpacing.hGapSm,
              Text(
                'Owner Testimonial & Debrief Note',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            '"I can\'t thank the rescue team enough. Luna got spooked by construction noise and bolted. You all mobilized so quickly and found her before it got dark. True heroes!"',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGapSm,
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '- Sarah & Luna',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: AppTypography.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReunionPhotoUploadCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            color: colorScheme.primary,
            size: 28,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reunion Photo & Proof',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  'Upload photo for community field records.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reunion photo attached')),
              );
            },
            child: const Text('Attach'),
          ),
        ],
      ),
    );
  }
}
