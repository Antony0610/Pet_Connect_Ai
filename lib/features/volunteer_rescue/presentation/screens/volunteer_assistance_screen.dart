import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_mission_status_notifier.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Volunteer Assistance Screen.
///
/// Emergency field support and assistance protocols. Displays real-time recovery status,
/// active responder ETA, dispatch contact actions, and field safety protocols.
class VolunteerAssistanceScreen extends ConsumerWidget {
  const VolunteerAssistanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mission = ref.watch(activeRescueMissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Field Assistance'),
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
                // ── Active Recovery Response Card ────────────────────
                _buildActiveRecoveryCard(context, theme, colorScheme, mission),

                AppSpacing.vGapLg,

                // ── Dispatch Communication Actions ───────────────────
                _buildDispatchContactRow(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Field Recovery Timeline Stepper ──────────────────
                _buildRecoveryTimelineSection(theme, colorScheme, mission),

                AppSpacing.vGapLg,

                // ── Field Safety Guidelines & Hotline ────────────────
                _buildFieldSafetySection(theme, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRecoveryCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    ActiveRescueMission mission,
  ) {
    if (mission.isStandby) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.success),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Field Incident Standby',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    'No active emergency dispatches in your sector. Hotline and mutual aid frequencies monitored.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const AppChip(
              label: 'STANDBY',
              backgroundColor: AppColors.success,
              textColor: AppColors.white,
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_walk, color: colorScheme.primary),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Incident: ${mission.petName}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  '${mission.lastSeenLocation} • Status: ${mission.stage.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppChip(
            label: mission.stage.label.toUpperCase(),
            backgroundColor: AppColors.success,
            textColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchContactRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Call Dispatch Hotline',
            icon: Icons.call,
            onPressed: () => ExternalActions.callPhone('+919876543210'),
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Message Team Lead'),
            onPressed: () => context.push(RoutePaths.rescueCommunityMessages),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryTimelineSection(
    ThemeData theme,
    ColorScheme colorScheme,
    ActiveRescueMission mission,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incident Recovery Protocols',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildTimelineStep(
                theme,
                colorScheme,
                title: '1. Incident Triaged & Dispatched',
                subtitle: 'Automated GPS mesh and sighting logs verified',
                isDone: true,
              ),
              const Divider(height: 24),
              _buildTimelineStep(
                theme,
                colorScheme,
                title: '2. Responder Deployment',
                subtitle: 'Field units mobilize to perimeter coordinates',
                isDone: !mission.isStandby,
              ),
              const Divider(height: 24),
              _buildTimelineStep(
                theme,
                colorScheme,
                title: '3. Animal Securing & Telemetry Verification',
                subtitle: 'Smart Collar beacon scanning and humane containment',
                isDone: mission.stage.index >= 3,
              ),
              const Divider(height: 24),
              _buildTimelineStep(
                theme,
                colorScheme,
                title: '4. Clinic Handover & Resolution',
                subtitle: 'Veterinary intake and guardian reunification report',
                isDone: mission.stage.index >= 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required bool isDone,
  }) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? AppColors.success : colorScheme.onSurfaceVariant,
          size: 20,
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
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
      ],
    );
  }

  Widget _buildFieldSafetySection(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Safety & Escalation Rules',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• Never enter hazardous waterways or high-voltage transit corridors alone.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                '• For aggressive, injured, or trapped wildlife, request municipal animal control backup via EOC hotline.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                '• Keep your volunteer locator ping active while on scene for dispatcher safety monitoring.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
