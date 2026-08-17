import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_setting.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/states/error_view.dart';

/// Administrator Platform Settings Screen (Stitch ID: `dc36e9199b4540eea867b5c17e3b5d46`).
///
/// Global system configurations and administrative policy settings.
/// Connected to live `public.platform_settings` table via `adminPlatformSettingsProvider` (Phase 12).
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
      }
    }

    _isMaintenanceMode ??= false;
    _isAutoBackups ??= true;
    _isDebugTelemetry ??= false;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final repo = ref.read(adminRepositoryProvider);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      final res1 = await repo.updatePlatformSettingByKey('maintenance_mode', {
        'enabled': _isMaintenanceMode ?? false,
        'message': 'System under maintenance',
      });
      final res2 = await repo.updatePlatformSettingByKey('auto_backups', {
        'enabled': _isAutoBackups ?? true,
        'frequency': 'daily',
      });
      final res3 = await repo.updatePlatformSettingByKey('debug_telemetry', {
        'enabled': _isDebugTelemetry ?? false,
        'log_level': (_isDebugTelemetry ?? false) ? 'DEBUG' : 'INFO',
      });

      if (res1.isLeft() || res2.isLeft() || res3.isLeft()) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Failed to update one or more settings in Supabase.'),
            backgroundColor: AppColors.lightError,
          ),
        );
      } else {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Platform settings saved successfully to Supabase.'),
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
          onPressed: () => context.go('/admin'),
        ),
        actions: [
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
                    // ── Branding & Assets Section ────────────────────────
                    _buildSettingsSectionCard(
                      theme,
                      colorScheme,
                      icon: Icons.branding_watermark_outlined,
                      title: 'Branding & Visual Assets',
                      subtitle:
                          'Manage global app logo, theme palettes, and banner assets.',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Asset Manager: Live configured assets active.'),
                          ),
                        );
                      },
                    ),

                    AppSpacing.vGapLg,

                    // ── Localization & Language ─────────────────────────
                    _buildSettingsSectionCard(
                      theme,
                      colorScheme,
                      icon: Icons.translate_outlined,
                      title: 'Localization & Languages',
                      subtitle:
                          'Default locale: en_US • English, Spanish, French, German supported.',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Localization: Default en_US active.'),
                          ),
                        );
                      },
                    ),

                    AppSpacing.vGapLg,

                    // ── Privacy & Legal Compliance ───────────────────────
                    _buildSettingsSectionCard(
                      theme,
                      colorScheme,
                      icon: Icons.policy_outlined,
                      title: 'Privacy & Legal Compliance',
                      subtitle:
                          'Manage EULA, HIPAA/Vet Compliance, and Data Governance.',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Legal Compliance: Standard EULA enforced.'),
                          ),
                        );
                      },
                    ),

                    AppSpacing.vGapLg,

                    // ── System Operations & Maintenance Switches ─────────
                    _buildMaintenanceCard(theme, colorScheme),

                    AppSpacing.vGapXl,

                    // ── Save Global Settings Button ─────────────────────
                    AppButton(
                      text: _isSaving ? 'Saving...' : 'Save Global Settings',
                      icon: Icons.save,
                      isLoading: _isSaving,
                      isFullWidth: true,
                      onPressed: _isSaving ? null : _saveSettings,
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      height: 48,
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

  Widget _buildSettingsSectionCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(icon, color: colorScheme.primary),
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
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
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
}
