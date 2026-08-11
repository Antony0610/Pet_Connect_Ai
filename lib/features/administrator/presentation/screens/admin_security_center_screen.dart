import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Administrator Security Center Screen (Stitch ID: `629599ff91824f2baa63fc0fdb6f0c4f`).
///
/// Security posture, threat monitoring, and system hardening controls. Displays MFA
/// compliance metrics, threat alerts, IP geofencing status, and session revocation actions.
class AdminSecurityCenterScreen extends StatelessWidget {
  const AdminSecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Center & Threat Monitoring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
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
                // ── Security Posture Banner ──────────────────────────
                _buildSecurityPostureBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Security Metrics Grid ───────────────────────────
                _buildSecurityMetricsGrid(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── System Hardening Controls ────────────────────────
                _buildHardeningControlsSection(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Recent Threat Audit Ticker ───────────────────────
                _buildThreatTickerSection(theme, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityPostureBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Security Posture: Optimal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'All system integrity checks nominal. 0 active critical threat vectors detected.',
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

  Widget _buildSecurityMetricsGrid(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '94%',
            label: 'MFA Compliance',
            icon: Icons.verified_user_outlined,
            color: AppColors.success,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '12',
            label: 'Failed Logins (24h)',
            icon: Icons.gpp_maybe_outlined,
            color: AppColors.warning,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: 'Active',
            label: 'IP Geofence Lock',
            icon: Icons.lock_outlined,
            color: colorScheme.primary,
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
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
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

  Widget _buildHardeningControlsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Hardening Controls',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildControlRow(
                context,
                theme,
                colorScheme,
                title: 'Enforce Global MFA Policy',
                subtitle:
                    'Require 2FA verification for all admin & vet accounts.',
                actionText: 'Enforce Now',
              ),
              const Divider(height: 20),
              _buildControlRow(
                context,
                theme,
                colorScheme,
                title: 'Revoke Active Sessions',
                subtitle: 'Emergency flush of active JWT token sessions.',
                actionText: 'Flush Sessions',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required String actionText,
  }) {
    return Row(
      children: [
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
        AppButton(
          text: actionText,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Action executed: $actionText')),
            );
          },
          height: 34,
        ),
      ],
    );
  }

  Widget _buildThreatTickerSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Security Audit Events',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildTickerItem(
                theme,
                colorScheme,
                time: '14:02 UTC',
                event: 'Admin Login: Sarah Connor (MFA Verified)',
                status: 'Passed',
                statusColor: AppColors.success,
              ),
              const Divider(height: 16),
              _buildTickerItem(
                theme,
                colorScheme,
                time: '11:45 UTC',
                event: 'Failed Password Attempt from IP 192.168.1.104',
                status: 'Flagged',
                statusColor: AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTickerItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String time,
    required String event,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Icon(Icons.shield_outlined, size: 18, color: statusColor),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            event,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppChip(
          label: status,
          backgroundColor: statusColor.withValues(alpha: 0.15),
          textColor: statusColor,
        ),
        AppSpacing.hGapSm,
        Text(
          time,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
