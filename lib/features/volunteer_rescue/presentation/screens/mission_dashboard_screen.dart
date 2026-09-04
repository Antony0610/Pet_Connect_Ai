import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/widgets/volunteer_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/buttons/portal_notification_badge_button.dart';
import 'package:petconnect_ai/shared/widgets/buttons/quick_action_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

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
    final activeMissions = missions
        .where(
          (m) =>
              m.status == 'in_progress' ||
              m.status == 'active' ||
              m.status == 'pending',
        )
        .toList();

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
          PortalNotificationBadgeButton(
            onPressed: () => context.push(RoutePaths.rescueNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Messages',
            onPressed: () => context.push(RoutePaths.rescueCommunityMessages),
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
                _buildDutyStatusCard(
                  theme,
                  colorScheme,
                  rescueAccent,
                  isOnDuty,
                ),

                AppSpacing.vGapLg,

                // ── Priority Urgent Rescue Alert Banner ───────────────
                _buildUrgentAlertBanner(
                  context,
                  theme,
                  colorScheme,
                  latestAlert,
                ),

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
      bottomNavigationBar: const VolunteerBottomNavBar(
        currentTab: VolunteerTab.dashboard,
      ),
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
    if (latestAlert == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perimeter Status: All Sectors Clear',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No active high-priority emergency distress signals in your sector.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Telemetry',
              onPressed: () => ref.invalidate(activeLostPetAlertsProvider),
            ),
          ],
        ),
      );
    }

    final title =
        (latestAlert.description != null && latestAlert.description!.isNotEmpty)
        ? latestAlert.description!
        : 'Emergency Signal #${latestAlert.id.substring(0, latestAlert.id.length > 6 ? 6 : latestAlert.id.length)}';
    final location = latestAlert.lastSeenLocation;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CRITICAL PRIORITY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onError,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.sensors_rounded,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live Beacon Signal',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                      color: colorScheme.error,
                    ),
                  ),
                ],
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
                icon: Icons.directions_run_rounded,
                onPressed: () => context.push(RoutePaths.rescueRequests),
                backgroundColor: colorScheme.error,
                textColor: colorScheme.onError,
                height: 38,
              ),
              AppSpacing.hGapSm,
              OutlinedButton.icon(
                icon: const Icon(Icons.map_rounded, size: 18),
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
            value: activeMissionsCount > 0
                ? '$activeMissionsCount Live'
                : 'Standby',
            icon: Icons.sensors_rounded,
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
            value: nearbyRequestsCount > 0
                ? '$nearbyRequestsCount Urgent'
                : '0 Active',
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
            value: sheltersCount > 0 ? '$sheltersCount Active' : 'Ready',
            icon: Icons.emergency_rounded,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
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
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                return QuickActionButton.fromSpec(
                  actions[index],
                  containerSize: 38,
                  iconSize: 20,
                );
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
              child: Text('View All (${alerts.length})'),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: alerts.isNotEmpty
              ? Column(
                  children: alerts.take(3).map((alert) {
                    final isResolved =
                        alert.alertStatus.toLowerCase() == 'resolved';
                    final statusColor = isResolved
                        ? AppColors.success
                        : colorScheme.error;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildIncidentItem(
                        theme,
                        colorScheme,
                        title:
                            (alert.description != null &&
                                alert.description!.isNotEmpty)
                            ? alert.description!
                            : 'Lost Pet Signal #${alert.id.substring(0, alert.id.length > 6 ? 6 : alert.id.length)}',
                        location: '${alert.lastSeenLocation} • Live GPS',
                        time: 'Active Alert',
                        status: alert.alertStatus,
                        statusColor: statusColor,
                      ),
                    );
                  }).toList(),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            size: 26,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Active Incidents in Sector',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All distress alerts are resolved or pending dispatch. Check surrounding zones for requests.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.radar_rounded, size: 16),
                          label: const Text('View All Requests'),
                          onPressed: () =>
                              context.push(RoutePaths.rescueRequests),
                        ),
                      ],
                    ),
                  ),
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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.pets_rounded, color: Colors.white, size: 20),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
}
