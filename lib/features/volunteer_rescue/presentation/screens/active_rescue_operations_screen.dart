import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/widgets/smart_collar_real_map.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_mission_status_notifier.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/widgets/volunteer_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/buttons/portal_notification_badge_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// **Active Rescue Operations Screen** — `/rescue/active`.
///
/// Live mission command center featuring a 5-stage incident status stepper,
/// real-time BLE/GPS collar telemetry HUD, turn-by-turn navigation, acoustic
/// collar ping triggers, and active responder coordination.
class ActiveRescueOperationsScreen extends ConsumerWidget {
  const ActiveRescueOperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mission = ref.watch(activeRescueMissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mission #${mission.id.toUpperCase()}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rescue'),
        ),
        actions: [
          PortalNotificationBadgeButton(
            onPressed: () => context.push(RoutePaths.rescueNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.navigation_outlined),
            tooltip: 'Turn-by-Turn GPS Navigation',
            onPressed: () {
              ExternalActions.openMapDirections(
                latitude: mission.latitude,
                longitude: mission.longitude,
                label: 'Rescue Target: ${mission.petName}',
                context: context,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Mission Brief',
            onPressed: () {
              ExternalActions.shareText(
                '🚨 ACTIVE RESCUE MISSION #${mission.id.toUpperCase()}\n'
                'Target: ${mission.petName} (${mission.breed})\n'
                'Location: ${mission.lastSeenLocation}\n'
                'Status: ${mission.stage.label}\n'
                'Beacon Distance: ~${mission.beaconDistanceMeters}m\n'
                'Lead: ${mission.responders.first.name}',
                subject: '🚨 Active Rescue Mission: ${mission.petName}',
              );
            },
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
                // ── 5-Stage Mission Lifecycle Stepper HUD ───────────
                _buildLifecycleStepperCard(context, ref, mission),
                AppSpacing.vGapMd,

                // ── Live Sighting Alert Banner ───────────────────────
                _buildLiveSightingBanner(context, ref, theme, colorScheme, mission),
                AppSpacing.vGapMd,

                // ── Map Visual Container & Telemetry HUD Overlay ────
                _buildMapTelemetryHud(theme, colorScheme, mission),
                AppSpacing.vGapLg,

                // ── Responder Controls & Quick Action Grid ──────────
                _buildResponderActionGrid(context, ref, theme, colorScheme, mission),
                AppSpacing.vGapLg,

                // ── Active Responders Team Roster ───────────────────
                _buildActiveRespondersRoster(context, theme, colorScheme, mission),
                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const VolunteerBottomNavBar(currentTab: VolunteerTab.operations),
    );
  }

  Widget _buildLifecycleStepperCard(
    BuildContext context,
    WidgetRef ref,
    ActiveRescueMission mission,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_rounded, color: colorScheme.primary),
                  AppSpacing.hGapSm,
                  Text(
                    'Mission Lifecycle: ${mission.stage.label}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              if (mission.stage != RescueStage.atClinic)
                AppButton.filled(
                  label: 'Advance Stage',
                  icon: Icons.check,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(activeRescueMissionProvider.notifier).advanceStage();
                    context.showSnackbar('✓ Mission updated to next stage!');
                  },
                ),
            ],
          ),
          AppSpacing.vGapMd,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RescueStage.values.map((stage) {
                final isCurrent = mission.stage == stage;
                final isCompleted = mission.stage.index > stage.index;

                Color circleColor = Colors.grey.shade300;
                Color textColor = Colors.grey.shade600;
                IconData icon = Icons.circle_outlined;

                if (isCompleted) {
                  circleColor = Colors.green;
                  textColor = Colors.green.shade800;
                  icon = Icons.check_circle_rounded;
                } else if (isCurrent) {
                  circleColor = colorScheme.primary;
                  textColor = colorScheme.primary;
                  icon = Icons.radio_button_checked_rounded;
                }

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(activeRescueMissionProvider.notifier).setStage(stage);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(icon, color: circleColor, size: 18),
                        AppSpacing.hGapXs,
                        Text(
                          stage.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSightingBanner(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    ActiveRescueMission mission,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.visibility_rounded,
              color: colorScheme.error,
              size: 20,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.sightingHeadline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  mission.sightingDetail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showAddSightingDialog(context, ref),
            tooltip: 'Update Sighting',
          ),
        ],
      ),
    );
  }

  Widget _buildMapTelemetryHud(
    ThemeData theme,
    ColorScheme colorScheme,
    ActiveRescueMission mission,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              child: Stack(
                children: [
                  SmartCollarRealMap(
                    latitude: mission.latitude,
                    longitude: mission.longitude,
                    petName: mission.petName,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            size: 14,
                            color: mission.isBeaconActive ? Colors.greenAccent : Colors.grey,
                          ),
                          AppSpacing.hGapXs,
                          Text(
                            mission.isBeaconActive
                                ? 'BEACON ACTIVE • ~${mission.beaconDistanceMeters}m'
                                : 'BEACON STANDBY',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Coordinates', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      '${mission.latitude.toStringAsFixed(4)}°N, ${mission.longitude.toStringAsFixed(4)}°E',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Last Location', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      mission.lastSeenLocation,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponderActionGrid(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    ActiveRescueMission mission,
  ) {
    return Row(
      children: [
        Expanded(
          child: AppButton.outlined(
            label: mission.isBeaconActive ? 'Mute Beacon Ping' : 'Trigger Collar Ping',
            icon: Icons.volume_up_rounded,
            onPressed: () {
              HapticFeedback.heavyImpact();
              ref.read(activeRescueMissionProvider.notifier).toggleCollarBeacon();
              context.showSnackbar(
                mission.isBeaconActive
                    ? '🔇 Collar acoustic ping muted'
                    : '🔊 High-frequency acoustic locator ping broadcasted to collar!',
              );
            },
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: AppButton.filled(
            label: 'GPS Turn-by-Turn',
            icon: Icons.directions_car_rounded,
            onPressed: () {
              ExternalActions.openMapDirections(
                latitude: mission.latitude,
                longitude: mission.longitude,
                label: 'Rescue Target: ${mission.petName}',
                context: context,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRespondersRoster(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    ActiveRescueMission mission,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deployed Responders (${mission.responders.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.people_outline, size: 20),
            ],
          ),
          AppSpacing.vGapMd,
          for (var i = 0; i < mission.responders.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.lg),
            _buildResponderTile(context, colorScheme, mission.responders[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildResponderTile(
    BuildContext context,
    ColorScheme colorScheme,
    RescueResponder responder,
  ) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            responder.name.substring(0, 1),
            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    responder.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (responder.isLead) ...[
                    AppSpacing.hGapXs,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: const Text('LEAD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              Text(
                '${responder.role} • ${responder.distanceMeters}m away • ${responder.status}',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.phone, size: 16),
          onPressed: () => ExternalActions.callPhoneNumber(responder.phone),
          tooltip: 'Call Responder',
        ),
      ],
    );
  }

  void _showAddSightingDialog(BuildContext context, WidgetRef ref) {
    final headlineCtrl = TextEditingController(text: 'Confirmed Civilian Visual Sighting');
    final detailCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Verified Sighting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: headlineCtrl, labelText: 'Headline'),
            AppSpacing.vGapSm,
            AppTextField(controller: detailCtrl, labelText: 'Observation Details & Proximity', maxLines: 2),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          AppButton.filled(
            label: 'Post Alert',
            icon: Icons.check,
            onPressed: () {
              if (detailCtrl.text.trim().isEmpty) return;
              ref.read(activeRescueMissionProvider.notifier).addSighting(
                    headlineCtrl.text.trim(),
                    detailCtrl.text.trim(),
                  );
              Navigator.of(ctx).pop();
              context.showSnackbar('✓ Sighting broadcasted to all sector responders!');
            },
          ),
        ],
      ),
    );
  }
}
