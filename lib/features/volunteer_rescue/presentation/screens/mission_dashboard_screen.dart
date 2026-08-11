import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Mission Dashboard Screen (Stitch ID: `a720b48ac18f4cf9a1a7dd940a71708c`,
/// Dark Reference: `4f7fb5dc6cbc42f195d2592fd8132d6d` & `2ac8627e328a479b96a5326bd19126a3`).
///
/// The central hub for Volunteer & Rescue operations. Displays live emergency
/// dispatch alerts, active rescue metrics, quick action tiles, and recent activity.
class MissionDashboardScreen extends StatefulWidget {
  const MissionDashboardScreen({super.key});

  @override
  State<MissionDashboardScreen> createState() => _MissionDashboardScreenState();
}

class _MissionDashboardScreenState extends State<MissionDashboardScreen> {
  bool _isOnDuty = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rescueAccent = PortalPalette.accentFor(AppPortal.volunteerRescue);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: rescueAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined, color: rescueAccent, size: 20),
            ),
            AppSpacing.hGapSm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RescueOps Portal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  'Field Emergency Command',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/owner/notifications'),
            tooltip: 'Alerts',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/rescue/profile'),
            tooltip: 'Responder Profile',
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
                // ── Status Banner & Duty Toggle ─────────────────────
                _buildDutyStatusCard(theme, colorScheme, rescueAccent),

                AppSpacing.vGapLg,

                // ── Priority Urgent Rescue Alert Banner ───────────────
                _buildUrgentAlertBanner(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Quick Metric Tiles ──────────────────────────────
                _buildMetricsGrid(context, theme, colorScheme, rescueAccent),

                AppSpacing.vGapLg,

                // ── Active Operations & Dispatch Quick Links ─────────
                _buildQuickActionHub(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Recent Activity / Incident Feed ─────────────────
                _buildRecentIncidentFeed(context, theme, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, theme, colorScheme),
    );
  }

  Widget _buildDutyStatusCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Color rescueAccent,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isOnDuty
                  ? AppColors.success
                  : colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnDuty
                      ? 'Active Status: Ready & On Duty'
                      : 'Status: Off Duty / Standby',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  _isOnDuty
                      ? 'Broadcasting GPS beacon & receiving nearby dispatch alerts (3km radius).'
                      : 'Alert notifications paused. Toggle to resume field response.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOnDuty,
            activeTrackColor: rescueAccent,
            onChanged: (val) {
              setState(() => _isOnDuty = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val
                        ? 'Responder status set to ON DUTY'
                        : 'Responder status set to STANDBY',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentAlertBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppChip(
                label: 'CRITICAL PRIORITY',
                backgroundColor: colorScheme.error,
                textColor: colorScheme.onError,
              ),
              const Spacer(),
              Text(
                '0.4m away',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            'Urgent Rescue: Buddy (Golden Retriever)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Reported wandering near storm drains at 5th & Main St. Collar visible but skittish. Weather deteriorating in 15 mins.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              AppButton(
                text: 'Respond Now',
                icon: Icons.directions_run,
                onPressed: () => context.push('/rescue/requests'),
                backgroundColor: colorScheme.error,
                textColor: colorScheme.onError,
                height: 38,
              ),
              AppSpacing.hGapSm,
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('View Telemetry Map'),
                onPressed: () => context.push('/rescue/operations'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Color rescueAccent,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            title: 'Active Operations',
            value: '3 Live',
            icon: Icons.sensors,
            color: rescueAccent,
            onTap: () => context.push('/rescue/operations'),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            title: 'Nearby Requests',
            value: '12 Urgent',
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            onTap: () => context.push('/rescue/requests'),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            title: 'EOC Command',
            value: 'Level 2',
            icon: Icons.emergency,
            color: colorScheme.error,
            onTap: () => context.push('/rescue/eoc'),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionHub(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Dispatch & Field Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapMd,
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context,
                theme,
                colorScheme,
                title: 'Live Tracking Map',
                subtitle: 'Real-time telemetry HUD',
                icon: Icons.map,
                path: '/rescue/operations',
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: _buildActionTile(
                context,
                theme,
                colorScheme,
                title: 'Field Reports',
                subtitle: 'Civic sightings feed',
                icon: Icons.assignment_outlined,
                path: '/rescue/reports',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String path,
  }) {
    return AppCard(
      onTap: () => context.push(path),
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

  Widget _buildRecentIncidentFeed(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Incidents & Alerts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/rescue/requests'),
              child: const Text('View All (12)'),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildIncidentItem(
                theme,
                colorScheme,
                title: 'Luna - Siberian Husky (Spotted)',
                location: 'Pine Ridge Trail • 200m away',
                time: '3 mins ago',
                status: 'Sighting Verified',
                statusColor: AppColors.success,
              ),
              const Divider(height: 20),
              _buildIncidentItem(
                theme,
                colorScheme,
                title: 'Mittens - Tuxedo Cat',
                location: 'Market St & 8th • 1.8km away',
                time: '18 mins ago',
                status: 'Dispatch Pending',
                statusColor: AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String location,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHigh,
          child: Icon(Icons.pets, color: colorScheme.primary, size: 20),
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
                location,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppChip(
              label: status,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              textColor: statusColor,
            ),
            AppSpacing.vGapXs,
            Text(
              time,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (idx) {
        if (idx == 0) context.go('/rescue');
        if (idx == 1) context.push('/rescue/operations');
        if (idx == 2) context.push('/rescue/requests');
        if (idx == 3) context.push('/rescue/eoc');
        if (idx == 4) context.push('/rescue/profile');
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Operations',
        ),
        NavigationDestination(
          icon: Icon(Icons.warning_amber_outlined),
          selectedIcon: Icon(Icons.warning_amber_rounded),
          label: 'Requests',
        ),
        NavigationDestination(
          icon: Icon(Icons.emergency_outlined),
          selectedIcon: Icon(Icons.emergency),
          label: 'EOC',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
