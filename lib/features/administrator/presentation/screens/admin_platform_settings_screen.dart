import 'dart:convert';
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

/// Administrator Platform Settings Screen
///
/// Complete platform-wide configuration and policy governance hub.
/// Synchronized in real-time with the Supabase `platform_settings` table.
class AdminPlatformSettingsScreen extends ConsumerStatefulWidget {
  const AdminPlatformSettingsScreen({super.key});

  @override
  ConsumerState<AdminPlatformSettingsScreen> createState() =>
      _AdminPlatformSettingsScreenState();
}

class _AdminPlatformSettingsScreenState
    extends ConsumerState<AdminPlatformSettingsScreen> {
  bool _isSaving = false;

  // ── Core Operations State ────────────────────────────────────────────────
  bool? _isMaintenanceMode;
  String _maintenanceMessage = 'System under scheduled maintenance. Only authorized staff may log in.';
  bool? _isAutoBackups;
  int _backupRetentionDays = 30;
  bool? _isDebugTelemetry;
  String _telemetryLogLevel = 'INFO';

  // ── Emergency & AI Policies ──────────────────────────────────────────────
  double _broadcastRadiusKm = 25.0;
  double _aiMatchThreshold = 75.0;
  bool _aiTriageAutoEscalate = true;

  // ── Security & Authentication Governance ──────────────────────────────────
  bool _enforce2faForStaff = true;
  int _maxFailedLogins = 5;
  int _sessionTimeoutMinutes = 60;
  bool _allowGuestBrowse = true;

  // ── Communication & Dispatch Gateways ────────────────────────────────────
  bool _emergencySmsDispatch = true;
  bool _emailNotificationsEnabled = true;
  bool _pushNotificationsEnabled = true;

  // ── Veterinary & Telemedicine Policies ───────────────────────────────────
  int _telemedicineBufferMinutes = 10;
  bool _requirePrescriptionLicense = true;

  void _initLocalState(List<PlatformSetting> settings) {
    if (_isMaintenanceMode != null) return; // already initialized

    for (final setting in settings) {
      final val = setting.settingValue;
      switch (setting.settingKey) {
        case 'maintenance_mode':
          _isMaintenanceMode = (val['enabled'] as bool?) ?? false;
          _maintenanceMessage = (val['message'] as String?) ?? _maintenanceMessage;
          break;
        case 'auto_backups':
          _isAutoBackups = (val['enabled'] as bool?) ?? true;
          _backupRetentionDays = (val['retention_days'] as num?)?.toInt() ?? 30;
          break;
        case 'debug_telemetry':
          _isDebugTelemetry = (val['enabled'] as bool?) ?? false;
          _telemetryLogLevel = (val['log_level'] as String?) ?? 'INFO';
          break;
        case 'emergency_broadcast_radius':
          final radius = val['radius_km'];
          if (radius is num) _broadcastRadiusKm = radius.toDouble();
          break;
        case 'ai_match_threshold':
          final threshold = val['threshold_percent'];
          if (threshold is num) _aiMatchThreshold = threshold.toDouble();
          break;
        case 'ai_triage_policy':
          _aiTriageAutoEscalate = (val['auto_escalate'] as bool?) ?? true;
          break;
        case 'security_auth_policy':
          _enforce2faForStaff = (val['enforce_2fa_staff'] as bool?) ?? true;
          _maxFailedLogins = (val['max_failed_logins'] as num?)?.toInt() ?? 5;
          _sessionTimeoutMinutes = (val['session_timeout_minutes'] as num?)?.toInt() ?? 60;
          _allowGuestBrowse = (val['allow_guest_browse'] as bool?) ?? true;
          break;
        case 'communication_dispatch':
          _emergencySmsDispatch = (val['emergency_sms'] as bool?) ?? true;
          _emailNotificationsEnabled = (val['email_notifications'] as bool?) ?? true;
          _pushNotificationsEnabled = (val['push_broadcast'] as bool?) ?? true;
          break;
        case 'veterinary_telemed_policy':
          _telemedicineBufferMinutes = (val['buffer_minutes'] as num?)?.toInt() ?? 10;
          _requirePrescriptionLicense = (val['require_license_check'] as bool?) ?? true;
          break;
      }
    }

    _isMaintenanceMode ??= false;
    _isAutoBackups ??= true;
    _isDebugTelemetry ??= false;
  }

  void _openAddCustomKeyDialog() async {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController(text: '{"enabled": true, "note": "Dynamic parameter"}');

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
                hintText: 'e.g. stripe_webhook_secret_key',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'JSON Value Payload',
                hintText: '{"mode": "production", "rate": 2.5}',
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
            child: const Text('Save Key'),
          ),
        ],
      ),
    );

    if (added == true && keyCtrl.text.trim().isNotEmpty) {
      Map<String, dynamic> jsonValue;
      try {
        jsonValue = jsonDecode(valCtrl.text.trim()) as Map<String, dynamic>;
      } catch (_) {
        jsonValue = {'raw_value': valCtrl.text.trim()};
      }

      final repo = ref.read(adminRepositoryProvider);
      await repo.updatePlatformSettingByKey(
        keyCtrl.text.trim(),
        jsonValue,
      );
      ref.invalidate(adminPlatformSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setting "${keyCtrl.text.trim()}" created in Supabase!')),
        );
      }
    }
  }

  void _editKeyDialog(PlatformSetting setting) async {
    final valCtrl = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(setting.settingValue),
    );

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Key: ${setting.settingKey}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Key ID: ${setting.id}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valCtrl,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'JSON Configuration Value',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update Supabase Key'),
          ),
        ],
      ),
    );

    if (updated == true) {
      Map<String, dynamic> jsonValue;
      try {
        jsonValue = jsonDecode(valCtrl.text.trim()) as Map<String, dynamic>;
      } catch (_) {
        jsonValue = {'raw_value': valCtrl.text.trim()};
      }

      final repo = ref.read(adminRepositoryProvider);
      await repo.updatePlatformSettingByKey(setting.settingKey, jsonValue);
      ref.invalidate(adminPlatformSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Key "${setting.settingKey}" updated!')),
        );
      }
    }
  }

  Future<void> _seedRecommendedDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed Recommended Defaults'),
        content: const Text(
          'This will ensure all standard platform setting keys (maintenance, backups, AI policies, security, dispatch) exist in Supabase with standard production defaults.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Seed Defaults')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      final repo = ref.read(adminRepositoryProvider);

      await repo.updatePlatformSettingByKey('maintenance_mode', {
        'enabled': false,
        'message': 'System under scheduled maintenance. Only authorized staff may log in.',
      });
      await repo.updatePlatformSettingByKey('auto_backups', {
        'enabled': true,
        'frequency': 'daily',
        'retention_days': 30,
      });
      await repo.updatePlatformSettingByKey('debug_telemetry', {
        'enabled': false,
        'log_level': 'INFO',
      });
      await repo.updatePlatformSettingByKey('emergency_broadcast_radius', {
        'radius_km': 25.0,
      });
      await repo.updatePlatformSettingByKey('ai_match_threshold', {
        'threshold_percent': 75.0,
      });
      await repo.updatePlatformSettingByKey('ai_triage_policy', {
        'auto_escalate': true,
        'priority': 'URGENT',
      });
      await repo.updatePlatformSettingByKey('security_auth_policy', {
        'enforce_2fa_staff': true,
        'max_failed_logins': 5,
        'session_timeout_minutes': 60,
        'allow_guest_browse': true,
      });
      await repo.updatePlatformSettingByKey('communication_dispatch', {
        'emergency_sms': true,
        'email_notifications': true,
        'push_broadcast': true,
      });
      await repo.updatePlatformSettingByKey('veterinary_telemed_policy', {
        'buffer_minutes': 10,
        'require_license_check': true,
      });

      ref.invalidate(adminPlatformSettingsProvider);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All recommended platform default keys seeded successfully!'),
            backgroundColor: AppColors.success,
          ),
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
        'message': _maintenanceMessage,
        'updated_at': DateTime.now().toIso8601String(),
      });
      final res2 = await repo.updatePlatformSettingByKey('auto_backups', {
        'enabled': _isAutoBackups ?? true,
        'frequency': 'daily',
        'retention_days': _backupRetentionDays,
      });
      final res3 = await repo.updatePlatformSettingByKey('debug_telemetry', {
        'enabled': _isDebugTelemetry ?? false,
        'log_level': _telemetryLogLevel,
      });
      final res4 = await repo.updatePlatformSettingByKey('emergency_broadcast_radius', {
        'radius_km': _broadcastRadiusKm,
      });
      final res5 = await repo.updatePlatformSettingByKey('ai_match_threshold', {
        'threshold_percent': _aiMatchThreshold,
      });
      final res6 = await repo.updatePlatformSettingByKey('ai_triage_policy', {
        'auto_escalate': _aiTriageAutoEscalate,
      });
      final res7 = await repo.updatePlatformSettingByKey('security_auth_policy', {
        'enforce_2fa_staff': _enforce2faForStaff,
        'max_failed_logins': _maxFailedLogins,
        'session_timeout_minutes': _sessionTimeoutMinutes,
        'allow_guest_browse': _allowGuestBrowse,
      });
      final res8 = await repo.updatePlatformSettingByKey('communication_dispatch', {
        'emergency_sms': _emergencySmsDispatch,
        'email_notifications': _emailNotificationsEnabled,
        'push_broadcast': _pushNotificationsEnabled,
      });
      final res9 = await repo.updatePlatformSettingByKey('veterinary_telemed_policy', {
        'buffer_minutes': _telemedicineBufferMinutes,
        'require_license_check': _requirePrescriptionLicense,
      });

      if (res1.isLeft() || res2.isLeft() || res3.isLeft() || res4.isLeft() || res5.isLeft() ||
          res6.isLeft() || res7.isLeft() || res8.isLeft() || res9.isLeft()) {
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
        title: const Text('Platform Settings & Policy Governance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high_outlined),
            tooltip: 'Seed Recommended Defaults',
            onPressed: _seedRecommendedDefaults,
          ),
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

                    // ── System Operations & Maintenance ──────────────────
                    _buildMaintenanceCard(theme, colorScheme),

                    AppSpacing.vGapLg,

                    // ── Emergency & AI Policy Sliders ───────────────────
                    _buildPolicySlidersCard(theme, colorScheme),

                    AppSpacing.vGapLg,

                    // ── Security & Authentication Governance (NEW) ───────
                    _buildSecurityGovernanceCard(theme, colorScheme),

                    AppSpacing.vGapLg,

                    // ── Communication & Dispatch Gateways (NEW) ──────────
                    _buildCommunicationGatewaysCard(theme, colorScheme),

                    AppSpacing.vGapLg,

                    // ── Veterinary & Telemedicine Policies (NEW) ─────────
                    _buildVeterinaryPolicyCard(theme, colorScheme),

                    AppSpacing.vGapLg,

                    // ── Dynamic Key Catalog & Custom Inspector ──────────
                    _buildDynamicKeyCatalog(theme, colorScheme, settings),

                    AppSpacing.vGapXl,

                    // ── Save Global Settings Button ─────────────────────
                    AppButton(
                      text: _isSaving ? 'Saving Configurations to Database...' : 'Save Global Configurations',
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
              Icon(Icons.system_update_outlined, color: colorScheme.primary, size: 22),
              AppSpacing.hGapSm,
              Text(
                'System Info & Live Database Controls',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: AppTypography.bold),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text('Restrict portal access to emergency maintenance mode'),
            value: _isMaintenanceMode ?? false,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isMaintenanceMode = val),
            contentPadding: EdgeInsets.zero,
          ),
          if (_isMaintenanceMode == true) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: TextEditingController(text: _maintenanceMessage),
                decoration: const InputDecoration(
                  labelText: 'Maintenance Banner Message',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _maintenanceMessage = v,
              ),
            ),
          ],
          SwitchListTile(
            title: const Text('Automated Database Backups'),
            subtitle: Text('Daily PostgreSQL snapshot schedule • $_backupRetentionDays days retention'),
            value: _isAutoBackups ?? true,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isAutoBackups = val),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Verbose Telemetry Logging'),
            subtitle: Text('API gateway logging level: $_telemetryLogLevel'),
            value: _isDebugTelemetry ?? false,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _isDebugTelemetry = val;
                _telemetryLogLevel = val ? 'DEBUG' : 'INFO';
              });
            },
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
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: colorScheme.primary, size: 22),
              AppSpacing.hGapSm,
              Text(
                'Operational & AI Policy Thresholds',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
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
          SwitchListTile(
            title: const Text('AI Health Triage Auto-Escalation'),
            subtitle: const Text('Automatically flag critical symptoms directly into clinical vet emergency queue'),
            value: _aiTriageAutoEscalate,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _aiTriageAutoEscalate = val),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityGovernanceCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: colorScheme.primary, size: 22),
              AppSpacing.hGapSm,
              Text(
                'Security & Authentication Governance',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          SwitchListTile(
            title: const Text('Mandatory 2FA for Staff Accounts'),
            subtitle: const Text('Enforce two-factor verification on Veterinarian & Administrator logins'),
            value: _enforce2faForStaff,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _enforce2faForStaff = val),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Public Guest Map Browsing'),
            subtitle: const Text('Allow unauthenticated users to view lost pet broadcasts'),
            value: _allowGuestBrowse,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _allowGuestBrowse = val),
            contentPadding: EdgeInsets.zero,
          ),
          AppSpacing.vGapSm,
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _maxFailedLogins,
                  decoration: const InputDecoration(labelText: 'Lockout after failed attempts'),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 attempts')),
                    DropdownMenuItem(value: 5, child: Text('5 attempts (Default)')),
                    DropdownMenuItem(value: 10, child: Text('10 attempts')),
                  ],
                  onChanged: (v) => setState(() => _maxFailedLogins = v ?? 5),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _sessionTimeoutMinutes,
                  decoration: const InputDecoration(labelText: 'Session idle timeout'),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 minutes')),
                    DropdownMenuItem(value: 30, child: Text('30 minutes')),
                    DropdownMenuItem(value: 60, child: Text('60 minutes (Default)')),
                    DropdownMenuItem(value: 120, child: Text('120 minutes')),
                  ],
                  onChanged: (v) => setState(() => _sessionTimeoutMinutes = v ?? 60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationGatewaysCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_outlined, color: colorScheme.primary, size: 22),
              AppSpacing.hGapSm,
              Text(
                'Communication & Dispatch Gateways',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          SwitchListTile(
            title: const Text('Emergency SMS Dispatch Alerts'),
            subtitle: const Text('Send direct SMS alerts to on-duty volunteer rescuers'),
            value: _emergencySmsDispatch,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _emergencySmsDispatch = val),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Transactional Email System'),
            subtitle: const Text('Deliver email receipts, health records, and prescription summaries'),
            value: _emailNotificationsEnabled,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _emailNotificationsEnabled = val),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Firebase Cloud Messaging (FCM) Push'),
            subtitle: const Text('Live push notifications to iOS and Android active devices'),
            value: _pushNotificationsEnabled,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _pushNotificationsEnabled = val),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildVeterinaryPolicyCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_outlined, color: colorScheme.primary, size: 22),
              AppSpacing.hGapSm,
              Text(
                'Veterinary Telemedicine & Prescription Policy',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          SwitchListTile(
            title: const Text('Require Medical License Validation'),
            subtitle: const Text('Block e-prescriptions until veterinarian medical license is verified by admin'),
            value: _requirePrescriptionLicense,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _requirePrescriptionLicense = val),
            contentPadding: EdgeInsets.zero,
          ),
          AppSpacing.vGapSm,
          DropdownButtonFormField<int>(
            initialValue: _telemedicineBufferMinutes,
            decoration: const InputDecoration(labelText: 'Consultation Transition Buffer'),
            items: const [
              DropdownMenuItem(value: 5, child: Text('5 minutes transition buffer')),
              DropdownMenuItem(value: 10, child: Text('10 minutes (Recommended)')),
              DropdownMenuItem(value: 15, child: Text('15 minutes transition buffer')),
            ],
            onChanged: (v) => setState(() => _telemedicineBufferMinutes = v ?? 10),
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
                'All Configured Database Setting Keys (${settings.length})',
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
                  child: InkWell(
                    onTap: () => _editKeyDialog(s),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.key, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.settingKey,
                                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
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
                          Icon(Icons.edit_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
