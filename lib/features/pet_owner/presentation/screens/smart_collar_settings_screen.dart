import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/collar_widgets.dart';
import 'package:petconnect_ai/features/smart_collar/domain/entities/collar_device.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Collar Settings** — `/owner/collar/settings`.
///
/// The device's identity card, a set of behaviour toggles (live tracking, LED,
/// sound, geofence alerts, battery saver), device management rows and a
/// destructive "unpair" action. Token-driven; one tree serves both themes.
class SmartCollarSettingsScreen extends ConsumerStatefulWidget {
  const SmartCollarSettingsScreen({super.key});

  @override
  ConsumerState<SmartCollarSettingsScreen> createState() =>
      _SmartCollarSettingsScreenState();
}

class _SmartCollarSettingsScreenState
    extends ConsumerState<SmartCollarSettingsScreen> {
  bool _liveTracking = true;
  bool _ledLight = true;
  bool _soundAlerts = true;
  bool _geofenceAlerts = true;
  bool _batterySaver = false;
  String _collarName = 'PetConnect Smart Collar';
  String _updateFrequency = 'Real-time (10s)';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final prefs = ref.read(sharedPreferencesProvider);
      setState(() {
        _liveTracking = prefs.getBool('collar_live_tracking') ?? true;
        _ledLight = prefs.getBool('collar_led_light') ?? true;
        _soundAlerts = prefs.getBool('collar_sound_alerts') ?? true;
        _geofenceAlerts = prefs.getBool('collar_geofence_alerts') ?? true;
        _batterySaver = prefs.getBool('collar_battery_saver') ?? false;
        _collarName = prefs.getString('collar_name_setting') ?? 'PetConnect Smart Collar';
        _updateFrequency = prefs.getString('collar_update_freq') ?? 'Real-time (10s)';
        _loaded = true;
      });
    }
  }

  void _savePref(String key, bool val) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(key, val);
  }

  void _openRenameDialog() async {
    final controller = TextEditingController(text: _collarName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename Collar'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Collar Name',
            hintText: 'e.g. Smart Collar v2',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && controller.text.trim().isNotEmpty) {
      final newName = controller.text.trim();
      setState(() => _collarName = newName);
      await ref.read(sharedPreferencesProvider).setString('collar_name_setting', newName);
      if (mounted) {
        context.showSnackbar('Collar renamed to $_collarName');
      }
    }
  }

  void _openFrequencyDialog() async {
    final options = [
      'Ultra Fast (5s)',
      'Real-time (10s)',
      'Balanced (30s)',
      'Eco Power (1m)',
      'Deep Sleep (5m)',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select GPS Frequency'),
        children: options.map((opt) {
          final isSelected = opt == _updateFrequency;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, opt),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? context.colorScheme.primary : context.colorScheme.outline,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(opt, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _updateFrequency = selected);
      await ref.read(sharedPreferencesProvider).setString('collar_update_freq', selected);
      if (mounted) {
        context.showSnackbar('Update frequency set to $selected');
      }
    }
  }

  void _openUnpairDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unpair Collar?'),
        content: const Text(
          'This will disconnect the smart collar from your account. You can re-pair it anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.showSnackbar('Collar unpaired successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final margin = _horizontalMargin(context.screenWidth);
    final collarsAsync = ref.watch(registeredCollarsProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: collarAppBar(context, title: 'Collar Settings'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                AppSpacing.md,
                margin,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DeviceCard(collarsAsync: collarsAsync),
                  AppSpacing.vGapLg,
                  const _SectionTitle('Preferences'),
                  AppSpacing.vGapSm,
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        _toggle(
                          icon: Icons.my_location_rounded,
                          title: 'Live tracking',
                          subtitle: 'Continuous GPS telemetry',
                          value: _liveTracking,
                          onChanged: (v) {
                            setState(() => _liveTracking = v);
                            _savePref('collar_live_tracking', v);
                          },
                        ),
                        _toggle(
                          icon: Icons.lightbulb_rounded,
                          title: 'LED night light',
                          subtitle: 'Collar glows in low light',
                          value: _ledLight,
                          onChanged: (v) {
                            setState(() => _ledLight = v);
                            _savePref('collar_led_light', v);
                          },
                        ),
                        _toggle(
                          icon: Icons.volume_up_rounded,
                          title: 'Sound alerts',
                          subtitle: 'Audible collar locator beacon',
                          value: _soundAlerts,
                          onChanged: (v) {
                            setState(() => _soundAlerts = v);
                            _savePref('collar_sound_alerts', v);
                          },
                        ),
                        _toggle(
                          icon: Icons.share_location_rounded,
                          title: 'Geofence alerts',
                          subtitle: 'Notify on safe-zone exit',
                          value: _geofenceAlerts,
                          onChanged: (v) {
                            setState(() => _geofenceAlerts = v);
                            _savePref('collar_geofence_alerts', v);
                          },
                        ),
                        _toggle(
                          icon: Icons.battery_saver_rounded,
                          title: 'Battery saver',
                          subtitle: 'Lower update frequency to extend battery',
                          value: _batterySaver,
                          onChanged: (v) {
                            setState(() => _batterySaver = v);
                            _savePref('collar_battery_saver', v);
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vGapLg,
                  const _SectionTitle('Device'),
                  AppSpacing.vGapSm,
                  AppCard(
                    child: Column(
                      children: [
                        _NavRow(
                          icon: Icons.drive_file_rename_outline_rounded,
                          title: 'Rename collar',
                          value: _collarName,
                          onTap: _openRenameDialog,
                        ),
                        _rowDivider(scheme),
                        _NavRow(
                          icon: Icons.update_rounded,
                          title: 'Update frequency',
                          value: _updateFrequency,
                          onTap: _openFrequencyDialog,
                        ),
                        _rowDivider(scheme),
                        _NavRow(
                          icon: Icons.wifi_rounded,
                          title: 'Connectivity',
                          value: 'LTE-M + BLE 5.2',
                          onTap: () =>
                              context.showSnackbar('Connected via LTE-M and Bluetooth Low Energy'),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vGapLg,
                  _DangerZone(onUnpair: _openUnpairDialog),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    final scheme = context.colorScheme;

    return Column(
      children: [
        SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icon, color: scheme.primary, size: AppIconSizes.md),
          title: Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (!isLast)
          Divider(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            height: 1,
          ),
      ],
    );
  }

  static Widget _rowDivider(ColorScheme scheme) => Divider(
    color: scheme.outlineVariant.withValues(alpha: 0.4),
    height: AppSpacing.lg,
  );

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

// __CONT_1__
/// A small section heading above a settings group.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.textTheme.titleMedium?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontWeight: AppTypography.semiBold,
      ),
    );
  }
}

/// The device identity card: collar avatar, model, serial and firmware.
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.collarsAsync});

  final AsyncValue<List<CollarDevice>> collarsAsync;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final deviceLabel = collarsAsync.maybeWhen(
      data: (collars) => collars.isNotEmpty
          ? 'Collar ID: ${collars.first.deviceId}'
          : 'PetConnect Collar Pro v2',
      orElse: () => 'PetConnect Collar Pro v2',
    );

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets_rounded,
              color: scheme.onPrimaryContainer,
              size: AppIconSizes.lg,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceLabel,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  'Hardware Standby Mode',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable device-management row: leading glyph, title, trailing value and
/// a chevron.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary, size: AppIconSizes.md),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
            Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.hGapXs,
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.outline,
              size: AppIconSizes.md,
            ),
          ],
        ),
      ),
    );
  }
}

/// The destructive footer: an "unpair collar" action framed in error tones.
class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onUnpair});

  final VoidCallback onUnpair;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      backgroundColor: scheme.errorContainer.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link_off_rounded,
                color: scheme.error,
                size: AppIconSizes.md,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Unpair collar',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: scheme.error,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapXs,
          Text(
            'Removes this collar from Buddy’s profile and stops all tracking. '
            'You can pair it again at any time.',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapMd,
          AppButton.outlined(
            label: 'Unpair Collar',
            icon: Icons.link_off_rounded,
            borderRadius: AppRadius.brPill,
            onPressed: onUnpair,
          ),
        ],
      ),
    );
  }
}
