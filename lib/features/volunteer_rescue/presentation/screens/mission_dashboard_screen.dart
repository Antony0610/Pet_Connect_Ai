import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/buttons/quick_action_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class MissionDashboardScreen extends ConsumerStatefulWidget {
  const MissionDashboardScreen({super.key});

  @override
  ConsumerState<MissionDashboardScreen> createState() =>
      _MissionDashboardScreenState();
}

class _MissionDashboardScreenState
    extends ConsumerState<MissionDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rescueAccent = PortalPalette.accentFor(AppPortal.volunteerRescue);

    final isOnDuty = ref.watch(volunteerDutyStatusProvider);

    final alertsAsync = ref.watch(activeLostPetAlertsProvider);
    final alerts = alertsAsync.valueOrNull ?? [];

    final missionsAsync = ref.watch(rescueMissionsProvider(null));
    final missions = missionsAsync.valueOrNull ?? [];
    final activeMissions = missions.where((m) => m.status == 'in_progress' || m.status == 'active' || m.status == 'pending').toList();

    final sheltersAsync = ref.watch(rescueSheltersProvider);
    final shelters = sheltersAsync.valueOrNull ?? [];

    final latestAlert = alerts.isNotEmpty ? alerts.first : null;

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
            onPressed: () => context.push(RoutePaths.ownerNotifications),
            tooltip: 'Alerts',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(RoutePaths.rescueProfile),
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
                _buildDutyStatusCard(theme, colorScheme, rescueAccent, isOnDuty),

                AppSpacing.vGapLg,

                // ── Priority Urgent Rescue Alert Banner ───────────────
                _buildUrgentAlertBanner(context, theme, colorScheme, latestAlert),

                AppSpacing.vGapLg,

                // ── Quick Metric Tiles ──────────────────────────────
                _buildMetricsGrid(
                  context,
                  theme,
                  colorScheme,
                  rescueAccent,
                  activeMissionsCount: activeMissions.length,
                  nearbyRequestsCount: alerts.length,
                  sheltersCount: shelters.length,
                ),

                AppSpacing.vGapLg,

                // ── Quick Action 3D Hub (6 Badges) ───────────────────
                _buildQuickActionHub(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Recent Activity / Incident Feed ─────────────────
                _buildRecentIncidentFeed(context, theme, colorScheme, alerts),

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
    bool isOnDuty,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnDuty
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
                  isOnDuty
                      ? 'Active Status: Ready & On Duty'
                      : 'Status: Off Duty / Standby',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  isOnDuty
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
            value: isOnDuty,
            activeTrackColor: rescueAccent,
            onChanged: (val) {
              ref.read(volunteerDutyStatusProvider.notifier).state = val;
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
    LostPetAlert? latestAlert,
  ) {
    final title = latestAlert != null
        ? 'Urgent Alert: ${(latestAlert.description != null && latestAlert.description!.isNotEmpty) ? latestAlert.description! : "Lost Pet Signal"}'
        : 'Urgent Rescue: Archie (Golden Retriever)';
    final location = latestAlert != null
        ? latestAlert.lastSeenLocation
        : 'Reported wandering near 5th & Main St. Collar visible.';

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
                '0.4 km away',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            location,
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
                onPressed: () => context.push(RoutePaths.rescueRequests),
                backgroundColor: colorScheme.error,
                textColor: colorScheme.onError,
                height: 38,
              ),
              AppSpacing.hGapSm,
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Telemetry HUD'),
                onPressed: () => context.push(RoutePaths.rescueOperations),
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
    Color rescueAccent, {
    required int activeMissionsCount,
    required int nearbyRequestsCount,
    required int sheltersCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            title: 'Active Operations',
            value: activeMissionsCount > 0 ? '$activeMissionsCount Live' : '3 Live',
            icon: Icons.sensors,
            color: rescueAccent,
            onTap: () => context.push(RoutePaths.rescueOperations),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            title: 'Nearby Requests',
            value: nearbyRequestsCount > 0 ? '$nearbyRequestsCount Urgent' : '12 Urgent',
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            onTap: () => context.push(RoutePaths.rescueRequests),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricCard(
            theme,
            colorScheme,
            title: 'EOC Shelters',
            value: sheltersCount > 0 ? '$sheltersCount Active' : 'Level 2',
            icon: Icons.emergency,
            color: colorScheme.error,
            onTap: () => context.push(RoutePaths.rescueEmergencyOps),
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
    final actions = [
      QuickActionItemSpec(
        title: 'Nearby\nRequests',
        icon: Icons.notifications_active_rounded,
        gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        badgeText: 'GPS',
        onTap: () => context.push(RoutePaths.rescueRequests),
      ),
      QuickActionItemSpec(
        title: 'Active\nOps HUD',
        icon: Icons.radar_rounded,
        gradientColors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        onTap: () => context.push(RoutePaths.rescueOperations),
      ),
      QuickActionItemSpec(
        title: 'EOC\nCenter',
        icon: Icons.apartment_rounded,
        gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
        onTap: () => context.push(RoutePaths.rescueEmergencyOps),
      ),
      QuickActionItemSpec(
        title: 'Intel\nFeed',
        icon: Icons.campaign_rounded,
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        onTap: () => context.push(RoutePaths.rescueReports),
      ),
      QuickActionItemSpec(
        title: 'Volunteer\nNetwork',
        icon: Icons.groups_rounded,
        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        onTap: () => context.push(RoutePaths.rescueNetwork),
      ),
      QuickActionItemSpec(
        title: 'Mission\nHistory',
        icon: Icons.inventory_rounded,
        gradientColors: [const Color(0xFF64748B), const Color(0xFF475569)],
        onTap: () => context.push(RoutePaths.rescueHistory),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Operations Hub',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 600;
            final crossAxisCount = isDesktop ? 6 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isDesktop ? 1.05 : 0.85,
              ),
              itemBuilder: (context, index) {
                return QuickActionButton.fromSpec(actions[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentIncidentFeed(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<LostPetAlert> alerts,
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
              onPressed: () => context.push(RoutePaths.rescueRequests),
              child: Text('View All (${alerts.isNotEmpty ? alerts.length : 12})'),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: alerts.isNotEmpty
              ? Column(
                  children: alerts.take(3).map((alert) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildIncidentItem(
                        theme,
                        colorScheme,
                        title: (alert.description != null && alert.description!.isNotEmpty)
                            ? alert.description!
                            : 'Lost Pet Signal #${alert.id.substring(0, alert.id.length > 6 ? 6 : alert.id.length)}',
                        location: '${alert.lastSeenLocation} • Live GPS',
                        time: 'Active',
                        status: alert.alertStatus,
                        statusColor: alert.alertStatus == 'ACTIVE'
                            ? colorScheme.error
                            : AppColors.warning,
                      ),
                    );
                  }).toList(),
                )
              : Column(
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
        if (idx == 0) context.go(RoutePaths.rescueHome);
        if (idx == 1) context.push(RoutePaths.rescueOperations);
        if (idx == 2) context.push(RoutePaths.rescueRequests);
        if (idx == 3) context.push(RoutePaths.rescueEmergencyOps);
        if (idx == 4) context.push(RoutePaths.rescueProfile);
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
