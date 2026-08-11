import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Volunteer Settings Screen (Stitch ID: `cb0ff4734475425f8f06127a1fa6b7eb`).
///
/// Account and field operation preferences screen. Manages active availability days,
/// alert radius slider (10 km), location beacon sharing, and notification channels.
class VolunteerSettingsScreen extends StatefulWidget {
  const VolunteerSettingsScreen({super.key});

  @override
  State<VolunteerSettingsScreen> createState() =>
      _VolunteerSettingsScreenState();
}

class _VolunteerSettingsScreenState extends State<VolunteerSettingsScreen> {
  double _radiusKm = 10.0;
  bool _isLocationSharing = true;
  bool _isPushNotifications = true;
  bool _isSmsAlerts = true;

  final Map<String, bool> _activeDays = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': false,
    'Sun': false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Settings'),
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
                // ── Availability & Radius Card ──────────────────────
                _buildAvailabilityRadiusCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Notification Preferences Card ────────────────────
                _buildNotificationCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Privacy & Security Card ─────────────────────────
                _buildPrivacyCard(theme, colorScheme),

                AppSpacing.vGapXl,

                // ── Save Preferences Button ─────────────────────────
                AppButton(
                  text: 'Save Settings & Preferences',
                  icon: Icons.save,
                  isFullWidth: true,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Volunteer settings saved!'),
                      ),
                    );
                  },
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  height: 48,
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityRadiusCard(
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
              Icon(Icons.schedule, color: colorScheme.primary, size: 22),
              AppSpacing.hGapSm,
              Text(
                'Availability Days & Alert Radius',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,

          // Day Selection Pills
          Text(
            'Active Dispatch Days',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapSm,
          Wrap(
            spacing: 8,
            children: _activeDays.keys.map((day) {
              final active = _activeDays[day]!;
              return FilterChip(
                label: Text(day),
                selected: active,
                onSelected: (val) => setState(() => _activeDays[day] = val),
                selectedColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: active ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: active
                      ? AppTypography.bold
                      : AppTypography.regular,
                ),
              );
            }).toList(),
          ),

          AppSpacing.vGapLg,

          // Radius Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Alert Radius',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${_radiusKm.toInt()} km',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _radiusKm,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            activeColor: colorScheme.primary,
            onChanged: (val) => setState(() => _radiusKm = val),
          ),

          AppSpacing.vGapSm,

          // Location Beacon Switch
          SwitchListTile(
            title: const Text('Live GPS Beacon Location Sharing'),
            subtitle: const Text(
              'Required for receiving real-time field dispatch',
            ),
            value: _isLocationSharing,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isLocationSharing = val),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
              AppSpacing.hGapSm,
              Text(
                'Notification Preferences',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Urgent rescue alerts & sighting broadcasts'),
            value: _isPushNotifications,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isPushNotifications = val),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('SMS Emergency Alerts'),
            subtitle: const Text('Direct SMS dispatch for critical alerts'),
            value: _isSmsAlerts,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isSmsAlerts = val),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: colorScheme.primary, size: 22),
              AppSpacing.hGapSm,
              Text(
                'Privacy & Sector Visibility',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            'Your phone number and exact home address are kept private. Only your first name, verified responder tier, and sector location are shown on the active responder roster.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
