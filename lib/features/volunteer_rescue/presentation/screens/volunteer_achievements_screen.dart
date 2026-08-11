import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Volunteer Achievements Screen (Stitch ID: `5958471735044f75a7e0b65d21d67a89`).
///
/// Gamification and badging milestones screen. Displays active hours, milestone
/// progress bar, unlocked badges, and service history level.
class VolunteerAchievementsScreen extends StatelessWidget {
  const VolunteerAchievementsScreen({super.key});

  final List<Map<String, dynamic>> _badges = const [
    {
      'title': 'Top Responder',
      'desc': 'Responded to 50+ urgent emergency calls',
      'icon': Icons.verified,
      'earned': true,
      'color': AppColors.success,
    },
    {
      'title': 'Community Pillar',
      'desc': 'Active field volunteer for over 1 year',
      'icon': Icons.groups,
      'earned': true,
      'color': AppColors.info,
    },
    {
      'title': '500 Hour Club',
      'desc': 'Logged 450 of 500 volunteer service hours',
      'icon': Icons.emoji_events,
      'earned': false,
      'color': AppColors.warning,
    },
    {
      'title': 'Night Patrol Lead',
      'desc': 'Completed 10 overnight emergency dispatches',
      'icon': Icons.nightlight_round,
      'earned': true,
      'color': AppColors.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Achievements & Badges'),
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
                // ── Milestone Level Header Progress ─────────────────
                _buildMilestoneProgressCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Service Stats Header ────────────────────────────
                _buildServiceStatsRow(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Earned Badges Grid ──────────────────────────────
                Text(
                  'Earned & Upcoming Badges',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,
                ..._badges.map((b) => _buildBadgeCard(theme, colorScheme, b)),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneProgressCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: colorScheme.primary, size: 28),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level 4 Rescue Lead',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      '50 hours to next milestone (Level 5 Command)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const AppChip(
                label: '450 / 500 HRS',
                backgroundColor: AppColors.success,
                textColor: AppColors.white,
              ),
            ],
          ),
          AppSpacing.vGapMd,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: 0.90,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHigh,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '2 Years',
            label: 'Years of Service',
            icon: Icons.military_tech,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '450 hrs',
            label: 'Hours Volunteered',
            icon: Icons.schedule,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '128',
            label: 'Successful Rescues',
            icon: Icons.pets,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
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

  Widget _buildBadgeCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> b,
  ) {
    final isEarned = b['earned'] as bool;
    final iconColor = b['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isEarned
                  ? iconColor.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHigh,
              child: Icon(
                b['icon'] as IconData,
                color: isEarned ? iconColor : colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['title'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    b['desc'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppChip(
              label: isEarned ? 'EARNED' : 'IN PROGRESS',
              backgroundColor: isEarned
                  ? AppColors.success.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHighest,
              textColor: isEarned ? AppColors.success : colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
