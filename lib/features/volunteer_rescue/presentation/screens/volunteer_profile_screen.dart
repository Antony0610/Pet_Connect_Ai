import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Volunteer Profile Screen (Stitch ID: `0e2764c02d7e47a882bcff2157b0b1a9`).
///
/// Primary responder profile overview. Displays volunteer badge, verification ID,
/// service metrics, skill badges, and navigation to achievements and settings.
class VolunteerProfileScreen extends StatelessWidget {
  const VolunteerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Responder Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rescue'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/rescue/settings'),
            tooltip: 'Volunteer Settings',
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
                // ── Profile Header Card ──────────────────────────────
                _buildProfileHeaderCard(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Service Impact Metrics ───────────────────────────
                _buildMetricsGrid(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Verification & Skill Badges ─────────────────────
                _buildSkillsSection(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Navigation Action List ──────────────────────────
                _buildNavigationList(context, theme, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.person, size: 36, color: colorScheme.primary),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sarah Lead',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified, size: 18, color: colorScheme.primary),
                  ],
                ),
                Text(
                  'ID: PC-VOL-128 • Level 4 (Rescue Lead)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapXs,
                const AppChip(
                  label: 'ON DUTY • SECTOR 4',
                  backgroundColor: AppColors.success,
                  textColor: AppColors.white,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile edit mode opened')),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            value: '128',
            label: 'Rescues',
            icon: Icons.shield_outlined,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            value: '450h',
            label: 'Volunteered',
            icon: Icons.schedule_outlined,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            value: '12m',
            label: 'Avg Response',
            icon: Icons.timer_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
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

  Widget _buildSkillsSection(ThemeData theme, ColorScheme colorScheme) {
    final skills = [
      'First Aid Certified',
      'K9 Handler',
      'Water Rescue',
      'Disaster Relief',
      'Triage Lead',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verified Skills & Badges',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map(
                (s) => AppChip(
                  label: s,
                  backgroundColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  textColor: colorScheme.primary,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        _buildNavTile(
          context,
          theme,
          colorScheme,
          title: 'Achievements & Milestones',
          subtitle: 'Track badging progress and service history',
          icon: Icons.emoji_events_outlined,
          onTap: () => context.push('/rescue/achievements'),
        ),
        AppSpacing.vGapSm,
        _buildNavTile(
          context,
          theme,
          colorScheme,
          title: 'Field Assistance & Support',
          subtitle: 'Emergency protocols and dispatch hotline',
          icon: Icons.help_outline,
          onTap: () => context.push('/rescue/assistance'),
        ),
        AppSpacing.vGapSm,
        _buildNavTile(
          context,
          theme,
          colorScheme,
          title: 'Pet Sharing & Foster Permissions',
          subtitle: 'Manage co-owner and temporary foster access',
          icon: Icons.share_outlined,
          onTap: () => context.push('/rescue/sharing'),
        ),
        AppSpacing.vGapSm,
        _buildNavTile(
          context,
          theme,
          colorScheme,
          title: 'Volunteer Preferences & Radius',
          subtitle: 'Configure availability days and alert radius',
          icon: Icons.tune_outlined,
          onTap: () => context.push('/rescue/settings'),
        ),
        AppSpacing.vGapLg,
        AppButton(
          text: 'Switch Portal / Role',
          icon: Icons.swap_horiz,
          isFullWidth: true,
          onPressed: () => context.go('/role-selection'),
          backgroundColor: colorScheme.surfaceContainerHigh,
          textColor: colorScheme.onSurface,
        ),
      ],
    );
  }

  Widget _buildNavTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
