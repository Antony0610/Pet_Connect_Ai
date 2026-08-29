import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_setting.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/states/error_view.dart';

class AdminPlatformSettingsScreen extends ConsumerStatefulWidget {
  const AdminPlatformSettingsScreen({super.key});

  @override
  ConsumerState<AdminPlatformSettingsScreen> createState() =>
      _AdminPlatformSettingsScreenState();
}

class _AdminPlatformSettingsScreenState
    extends ConsumerState<AdminPlatformSettingsScreen> {
  bool _isSaving = false;

  // Local mutable state initialized from remote settings
  bool? _isMaintenanceMode;
  bool? _isAutoBackups;
  bool? _isDebugTelemetry;
  double _broadcastRadiusKm = 25.0;
  double _aiMatchThreshold = 75.0;

  void _initLocalState(List<PlatformSetting> settings) {
    if (_isMaintenanceMode != null) return; // already initialized

    for (final setting in settings) {
      if (setting.settingKey == 'maintenance_mode') {
        _isMaintenanceMode =
            (setting.settingValue['enabled'] as bool?) ?? false;
      } else if (setting.settingKey == 'auto_backups') {
        _isAutoBackups = (setting.settingValue['enabled'] as bool?) ?? true;
      } else if (setting.settingKey == 'debug_telemetry') {
        _isDebugTelemetry =
            (setting.settingValue['enabled'] as bool?) ?? false;
      } else if (setting.settingKey == 'emergency_broadcast_radius') {
        final radius = setting.settingValue['radius_km'];
        if (radius is num) _broadcastRadiusKm = radius.toDouble();
      } else if (setting.settingKey == 'ai_match_threshold') {
        final threshold = setting.settingValue['threshold_percent'];
        if (threshold is num) _aiMatchThreshold = threshold.toDouble();
      }
    }

    _isMaintenanceMode ??= false;
    _isAutoBackups ??= true;
    _isDebugTelemetry ??= false;
  }

  void _openAddCustomKeyDialog() async {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController(text: '{"enabled": true}');

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Platform Setting Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'Setting Key Identifier',
                hintText: 'e.g. payment_gateway_mode',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'JSON Value',
                hintText: '{"mode": "live", "rate": 1.5}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Setting'),
          ),
        ],
      ),
    );

    if (added == true && keyCtrl.text.trim().isNotEmpty) {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updatePlatformSettingByKey(
        keyCtrl.text.trim(),
        {'raw_value': valCtrl.text.trim(), 'updated_at': DateTime.now().toIso8601String()},
      );
      ref.invalidate(adminPlatformSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setting "${keyCtrl.text.trim()}" saved to Supabase!')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final repo = ref.read(adminRepositoryProvider);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      final res1 = await repo.updatePlatformSettingByKey('maintenance_mode', {
        'enabled': _isMaintenanceMode ?? false,
        'message': 'System under scheduled maintenance. Only administrative personnel authorized.',
      });
      final res2 = await repo.updatePlatformSettingByKey('auto_backups', {
        'enabled': _isAutoBackups ?? true,
        'frequency': 'daily',
        'retention_days': 30,
      });
      final res3 = await repo.updatePlatformSettingByKey('debug_telemetry', {
        'enabled': _isDebugTelemetry ?? false,
        'log_level': (_isDebugTelemetry ?? false) ? 'DEBUG' : 'INFO',
      });
      final res4 = await repo.updatePlatformSettingByKey('emergency_broadcast_radius', {
        'radius_km': _broadcastRadiusKm,
      });
      final res5 = await repo.updatePlatformSettingByKey('ai_match_threshold', {
        'threshold_percent': _aiMatchThreshold,
      });

      if (res1.isLeft() || res2.isLeft() || res3.isLeft() || res4.isLeft() || res5.isLeft()) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Failed to update one or more settings in Supabase.'),
            backgroundColor: AppColors.lightError,
          ),
        );
      } else {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('All platform configurations saved successfully to Supabase!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(adminPlatformSettingsProvider);
      }
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Error saving platform settings: $e'),
          backgroundColor: AppColors.lightError,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsAsync = ref.watch(adminPlatformSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Settings & Configurations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Custom Key',
            onPressed: _openAddCustomKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              setState(() {
                _isMaintenanceMode = null;
                _isAutoBackups = null;
                _isDebugTelemetry = null;
              });
              ref.invalidate(adminPlatformSettingsProvider);
            },
            tooltip: 'Reload Settings',
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(
          message: 'Could not load platform settings: $err',
          onRetry: () => ref.invalidate(adminPlatformSettingsProvider),
        ),
        data: (settings) {
          _initLocalState(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Active Database Keys Counter ────────────────────
                    _buildSettingsOverviewBanner(theme, colorScheme, settings.length),

                    AppSpacing.vGapLg,

                    // ── System Operations & Maintenance Switches ─────────
                    _buildMaintenanceCard(theme, colorScheme),

                    AppSpacing.vGapLg,

                    // ── Emergency & AI Policy Sliders ───────────────────
                    _buildPolicySlidersCard(theme, colorScheme),

                    AppSpacing.vGapLg,

                    // ── Dynamic Key Catalog ────────────────────────────
                    _buildDynamicKeyCatalog(theme, colorScheme, settings),

                    AppSpacing.vGapXl,

                    // ── Save Global Settings Button ─────────────────────
                    AppButton(
                      text: _isSaving ? 'Saving to Database...' : 'Save Global Configurations',
                      icon: Icons.save,
                      isLoading: _isSaving,
                      isFullWidth: true,
                      onPressed: _isSaving ? null : _saveSettings,
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      height: 48,
                    ),

                    AppSpacing.vGapMd,

                    // ── Sign Out of Admin Portal ────────────────────────
                    OutlinedButton.icon(
                      icon: Icon(Icons.logout, color: colorScheme.error),
                      label: Text('Sign Out of Administrator Portal', style: TextStyle(color: colorScheme.error)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Sign out of Administrator Portal?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('Sign Out', style: TextStyle(color: colorScheme.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await ref.read(signOutProvider)(const NoParams());
                          if (context.mounted) context.go(RoutePaths.login);
                        }
                      },
                    ),

                    AppSpacing.vGapXl,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsOverviewBanner(ThemeData theme, ColorScheme colorScheme, int keysCount) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(Icons.tune, color: colorScheme.primary, size: 28),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Supabase Platform Schema',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$keysCount platform keys actively synchronized with backend PostgreSQL database.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          AppChip(
            label: 'SYNCED',
            backgroundColor: AppColors.success.withValues(alpha: 0.15),
            textColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.system_update_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
              AppSpacing.hGapSm,
              Text(
                'System Info & Live Database Controls',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text(
              'Restrict portal access to emergency maintenance mode',
            ),
            value: _isMaintenanceMode ?? false,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isMaintenanceMode = val),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Automated Database Backups'),
            subtitle: const Text('Daily PostgreSQL automated snapshot schedule'),
            value: _isAutoBackups ?? true,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isAutoBackups = val),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Verbose Telemetry Logging'),
            subtitle: const Text('Detailed API gateway request tracing'),
            value: _isDebugTelemetry ?? false,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isDebugTelemetry = val),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySlidersCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operational & AI Policy Thresholds',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.vGapMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Emergency Broadcast Radius Limit'),
              Text('${_broadcastRadiusKm.toStringAsFixed(0)} km', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _broadcastRadiusKm,
            min: 5.0,
            max: 100.0,
            divisions: 19,
            label: '${_broadcastRadiusKm.toStringAsFixed(0)} km',
            onChanged: (val) => setState(() => _broadcastRadiusKm = val),
          ),
          AppSpacing.vGapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI Sighting Match Confidence Threshold'),
              Text('${_aiMatchThreshold.toStringAsFixed(0)} %', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _aiMatchThreshold,
            min: 50.0,
            max: 95.0,
            divisions: 9,
            label: '${_aiMatchThreshold.toStringAsFixed(0)} %',
            onChanged: (val) => setState(() => _aiMatchThreshold = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicKeyCatalog(ThemeData theme, ColorScheme colorScheme, List<PlatformSetting> settings) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dynamic Platform Keys (${settings.length})',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: 'Add Key',
                onPressed: _openAddCustomKeyDialog,
              ),
            ],
          ),
          AppSpacing.vGapSm,
          if (settings.isEmpty)
            const Text('No custom platform keys found in database.')
          else
            ...settings.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.key, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.settingKey,
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Text(
                          s.settingValue.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
