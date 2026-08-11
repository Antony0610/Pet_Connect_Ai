import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Mission Accepted Screen (Stitch ID: `3c411ed9eb984aa1add0fa2ba798b73a`).
///
/// Response confirmation and pre-mission launch checklist screen. Displays owner
/// notification status, equipment check, and GPS tracking navigation launcher.
class MissionAcceptedScreen extends StatelessWidget {
  const MissionAcceptedScreen({super.key, this.missionId = 'm1'});

  final String missionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Assigned'),
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
                // ── Assignment Success Banner ───────────────────────
                _buildAssignedBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Pre-Mission Readiness Checklist ─────────────────
                _buildPreMissionChecklist(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Primary Navigation & Complete Action Buttons ────
                _buildActionButtons(context, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mission Assigned Successfully!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  "Luna's owner has been notified and is awaiting your arrival.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreMissionChecklist(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pre-Mission Readiness Checklist',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildChecklistItem(
                context,
                theme,
                colorScheme,
                title: 'Contact Owner',
                subtitle: 'Confirm ETA (approx. 8 mins) and location details.',
                icon: Icons.call,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling Sarah Connor...')),
                  );
                },
              ),
              const Divider(height: 20),
              _buildChecklistItem(
                context,
                theme,
                colorScheme,
                title: 'Equipment & Leash Check',
                subtitle:
                    'Ensure standard rescue kit, treats, and slip leash are ready.',
                icon: Icons.inventory_2_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Equipment verified ready')),
                  );
                },
              ),
              const Divider(height: 20),
              _buildChecklistItem(
                context,
                theme,
                colorScheme,
                title: 'Start Live GPS Navigation',
                subtitle: 'Activate telemetry beacon for sector volunteers.',
                icon: Icons.navigation_outlined,
                onTap: () => context.push('/rescue/operations'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
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

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        AppButton(
          text: 'Start Navigation Map HUD',
          icon: Icons.map,
          isFullWidth: true,
          onPressed: () => context.push('/rescue/operations'),
          backgroundColor: colorScheme.primary,
          textColor: colorScheme.onPrimary,
          height: 46,
        ),
        AppSpacing.vGapSm,
        OutlinedButton.icon(
          icon: const Icon(Icons.task_alt),
          label: const Text('Complete Mission & Report'),
          onPressed: () =>
              context.push('/rescue/missions/$missionId/completed'),
        ),
      ],
    );
  }
}
