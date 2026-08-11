import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Active Rescue Operations Screen (Stitch ID: `0330434ea8c7495e8ec2eb0d83f64b0b`).
///
/// Live mission control and real-time telemetry HUD. Displays live tracking map,
/// collar beacon telemetry (200m signal distance), sighting updates, and responder controls.
class ActiveRescueOperationsScreen extends StatefulWidget {
  const ActiveRescueOperationsScreen({super.key});

  @override
  State<ActiveRescueOperationsScreen> createState() =>
      _ActiveRescueOperationsScreenState();
}

class _ActiveRescueOperationsScreenState
    extends State<ActiveRescueOperationsScreen> {
  bool _isPingActive = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Rescue Operations HUD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rescue'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Telemetry signal refreshed')),
              );
            },
            tooltip: 'Refresh Telemetry',
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
                // ── Live Sighting Alert Banner ───────────────────────
                _buildLiveSightingBanner(theme, colorScheme),

                AppSpacing.vGapMd,

                // ── Map Visual Container & Telemetry HUD Overlay ────
                _buildMapTelemetryHud(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Responder Controls & Quick Action Grid ──────────
                _buildResponderActionGrid(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Active Responders Team Roster ───────────────────
                _buildActiveRespondersRoster(theme, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveSightingBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.sensors, color: colorScheme.primary, size: 24),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirmed Civilian Visual Sighting',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'Luna matched by civilian 3 mins ago near Pine Ridge trail head.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const AppChip(
            label: 'LIVE',
            backgroundColor: AppColors.success,
            textColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildMapTelemetryHud(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          // Map Visual Backdrop Grid Pattern
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                AppSpacing.vGapSm,
                Text(
                  'Interactive Field Navigation Map',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'GPS Coordinates: 37.7749° N, 122.4194° W',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Target Pin Overlay
          Positioned(
            left: 120,
            top: 90,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.error.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 16),
            ),
          ),

          // User Pin Overlay
          Positioned(
            right: 140,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          // Telemetry HUD Card
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(Icons.radar, color: colorScheme.primary),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Luna is 200m away',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        Text(
                          'Collar Battery: 84% • Beacon Signal: Strong (BLE/GPS)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    text: _isPingActive ? 'Pinging...' : 'Ping Collar',
                    icon: Icons.volume_up,
                    onPressed: () {
                      setState(() => _isPingActive = !_isPingActive);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isPingActive
                                ? 'Emitting audible collar chime signal'
                                : 'Collar chime stopped',
                          ),
                        ),
                      );
                    },
                    height: 36,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponderActionGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Responder Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapMd,
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Mark Sighting',
                icon: Icons.pin_drop,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Visual sighting logged')),
                  );
                },
                backgroundColor: colorScheme.primary,
                textColor: colorScheme.onPrimary,
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('Request Backup'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup request sent to nearby volunteers'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveRespondersRoster(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Team Roster (3 En Route)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildResponderItem(
                theme,
                colorScheme,
                name: 'Alex Rivera (You)',
                role: 'Lead Responder • Sector 4',
                distance: '200m away',
                status: 'En Route',
                isLead: true,
              ),
              const Divider(height: 16),
              _buildResponderItem(
                theme,
                colorScheme,
                name: 'Sarah Jenkins',
                role: 'Vet Tech • Sector 4',
                distance: '650m away',
                status: 'In Transit',
                isLead: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponderItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String name,
    required String role,
    required String distance,
    required String status,
    required bool isLead,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: isLead
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          child: Icon(
            isLead ? Icons.person_pin : Icons.person,
            color: isLead ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              Text(
                '$role • $distance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppChip(
          label: status,
          backgroundColor: isLead
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest,
          textColor: isLead ? colorScheme.primary : colorScheme.onSurface,
        ),
      ],
    );
  }
}
