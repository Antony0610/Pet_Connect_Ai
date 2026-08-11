import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Volunteer Assistance Screen (Stitch ID: `576f66e8cefa44b1ae41b77cfd1bb38a`).
///
/// Emergency field support and assistance protocols. Displays real-time recovery status,
/// active responder ETA, dispatch contact actions, and field protocols timeline.
class VolunteerAssistanceScreen extends StatelessWidget {
  const VolunteerAssistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                _buildActiveRecoveryCard(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Dispatch Communication Actions ───────────────────
                _buildDispatchContactRow(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Field Recovery Timeline Stepper ──────────────────
                _buildRecoveryTimelineSection(theme, colorScheme),

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
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'Active Recovery: Sarah is Responding',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      '0.2 miles away • Approaching from West • 2 mins ETA',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const AppChip(
                label: 'EN ROUTE',
                backgroundColor: AppColors.success,
                textColor: AppColors.white,
              ),
            ],
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling EOC Emergency Hotline...'),
                ),
              );
            },
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Message Team Lead'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Team Lead Chat...')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryTimelineSection(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incident Recovery Timeline',
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
                time: '12:42 PM',
                title: 'Civilian Sighting Verified',
                desc: 'Visual confirmed near Pine Ridge trailhead.',
                isDone: true,
              ),
              const Divider(height: 16),
              _buildTimelineStep(
                theme,
                colorScheme,
                time: '12:43 PM',
                title: 'Sarah Accepted Rescue Request',
                desc: 'Responder assigned and en route with equipment.',
                isDone: true,
              ),
              const Divider(height: 16),
              _buildTimelineStep(
                theme,
                colorScheme,
                time: '12:48 PM (ETA)',
                title: 'Arrival & Containment',
                desc: 'Approaching last known BLE beacon location.',
                isDone: false,
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
    required String time,
    required String title,
    required String desc,
    required bool isDone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              Text(
                desc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildFieldSafetySection(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: colorScheme.error, size: 22),
              AppSpacing.hGapSm,
              Text(
                'Emergency Safety Guidelines',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            '1. Maintain safe distance from startled animals.\n'
            '2. Always broadcast live GPS telemetry during active search.\n'
            '3. Contact EOC immediately if severe weather or hazard occurs.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
