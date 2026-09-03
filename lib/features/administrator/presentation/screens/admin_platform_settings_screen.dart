import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_setting.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/features/administrator/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/states/error_view.dart';

/// Administrator Platform Settings Screen
///
/// Sleek Telegram flat-list styled platform configuration and policy governance hub.
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
  String _maintenanceMessage =
      'System under scheduled maintenance. Only authorized staff may log in.';
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
          _maintenanceMessage =
              (val['message'] as String?) ?? _maintenanceMessage;
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
          _sessionTimeoutMinutes =
              (val['session_timeout_minutes'] as num?)?.toInt() ?? 60;
          _allowGuestBrowse = (val['allow_guest_browse'] as bool?) ?? true;
          break;
        case 'communication_dispatch':
          _emergencySmsDispatch = (val['emergency_sms'] as bool?) ?? true;
          _emailNotificationsEnabled =
              (val['email_notifications'] as bool?) ?? true;
          _pushNotificationsEnabled = (val['push_broadcast'] as bool?) ?? true;
          break;
        case 'veterinary_telemed_policy':
          _telemedicineBufferMinutes =
              (val['buffer_minutes'] as num?)?.toInt() ?? 10;
          _requirePrescriptionLicense =
              (val['require_license_check'] as bool?) ?? true;
          break;
      }
    }

    _isMaintenanceMode ??= false;
    _isAutoBackups ??= true;
    _isDebugTelemetry ??= false;
  }

  void _openAddCustomKeyDialog() async {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController(
      text: '{"enabled": true, "note": "Dynamic parameter"}',
    );

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Platform Setting Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'Setting Key (e.g. max_search_radius)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'JSON Value',
                border: OutlineInputBorder(),
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
            child: const Text('Create in Supabase'),
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
      await repo.updatePlatformSettingByKey(keyCtrl.text.trim(), jsonValue);
      ref.invalidate(adminPlatformSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Setting "${keyCtrl.text.trim()}" created in Supabase!',
            ),
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Seed Defaults'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      final repo = ref.read(adminRepositoryProvider);

      await repo.updatePlatformSettingByKey('maintenance_mode', {
        'enabled': false,
        'message':
            'System under scheduled maintenance. Only authorized staff may log in.',
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
            content: Text(
              'All recommended platform default keys seeded successfully!',
            ),
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
      await repo.updatePlatformSettingByKey('maintenance_mode', {
        'enabled': _isMaintenanceMode ?? false,
        'message': _maintenanceMessage,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await repo.updatePlatformSettingByKey('auto_backups', {
        'enabled': _isAutoBackups ?? true,
        'frequency': 'daily',
        'retention_days': _backupRetentionDays,
      });
      await repo.updatePlatformSettingByKey('debug_telemetry', {
        'enabled': _isDebugTelemetry ?? false,
        'log_level': _telemetryLogLevel,
      });
      await repo.updatePlatformSettingByKey('emergency_broadcast_radius', {
        'radius_km': _broadcastRadiusKm,
      });
      await repo.updatePlatformSettingByKey('ai_match_threshold', {
        'threshold_percent': _aiMatchThreshold,
      });
      await repo.updatePlatformSettingByKey('ai_triage_policy', {
        'auto_escalate': _aiTriageAutoEscalate,
      });
      await repo.updatePlatformSettingByKey('security_auth_policy', {
        'enforce_2fa_staff': _enforce2faForStaff,
        'max_failed_logins': _maxFailedLogins,
        'session_timeout_minutes': _sessionTimeoutMinutes,
        'allow_guest_browse': _allowGuestBrowse,
      });
      await repo.updatePlatformSettingByKey('communication_dispatch', {
        'emergency_sms': _emergencySmsDispatch,
        'email_notifications': _emailNotificationsEnabled,
        'push_broadcast': _pushNotificationsEnabled,
      });
      await repo.updatePlatformSettingByKey('veterinary_telemed_policy', {
        'buffer_minutes': _telemedicineBufferMinutes,
        'require_license_check': _requirePrescriptionLicense,
      });

      ref.invalidate(adminPlatformSettingsProvider);
      scaffold.showSnackBar(
        const SnackBar(
          content: Text(
            'Global platform settings updated & synchronized to Supabase!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
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
        title: const Text('Platform Governance & Settings'),
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Active Database Keys Counter ────────────────────
                    _buildSettingsOverviewBanner(
                      theme,
                      colorScheme,
                      settings.length,
                    ),

                    AppSpacing.vGapMd,

                    // ── Core Operations & Maintenance ──────────────────
                    _buildSectionHeader(
                      'CORE PLATFORM & OPERATIONS',
                      colorScheme,
                    ),
                    _buildOperationsGroup(context, colorScheme),

                    AppSpacing.vGapMd,

                    // ── Emergency & AI Policies ────────────────────────
                    _buildSectionHeader(
                      'EMERGENCY DISPATCH & AI POLICIES',
                      colorScheme,
                    ),
                    _buildAiPoliciesGroup(context, colorScheme),

                    AppSpacing.vGapMd,

                    // ── Security & Access Control ──────────────────────
                    _buildSectionHeader(
                      'SECURITY & ACCESS CONTROL',
                      colorScheme,
                    ),
                    _buildSecurityGroup(context, colorScheme),

                    AppSpacing.vGapMd,

                    // ── Communication & Relays ────────────────────────
                    _buildSectionHeader(
                      'DISPATCH COMMUNICATION RELAYS',
                      colorScheme,
                    ),
                    _buildCommunicationGroup(context, colorScheme),

                    AppSpacing.vGapMd,

                    // ── Veterinary Governance ──────────────────────────
                    _buildSectionHeader(
                      'VETERINARY & TELEMEDICINE GOVERNANCE',
                      colorScheme,
                    ),
                    _buildVeterinaryGroup(context, colorScheme),

                    AppSpacing.vGapMd,

                    // ── Dynamic Key Catalog & Custom Inspector ──────────
                    _buildSectionHeader(
                      'DATABASE SCHEMA INSPECTOR (${settings.length} KEYS)',
                      colorScheme,
                    ),
                    _buildDynamicKeyCatalogGroup(
                      context,
                      colorScheme,
                      settings,
                    ),

                    AppSpacing.vGapLg,

                    // ── Save Global Settings Button ─────────────────────
                    AppButton(
                      text: _isSaving
                          ? 'Synchronizing to Supabase...'
                          : 'Save Global Configurations',
                      icon: Icons.save,
                      isLoading: _isSaving,
                      isFullWidth: true,
                      onPressed: _isSaving ? null : _saveSettings,
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      height: 50,
                    ),

                    AppSpacing.vGapMd,

                    // ── Sign Out Button ────────────────────────────────
                    OutlinedButton.icon(
                      icon: Icon(Icons.logout, color: colorScheme.error),
                      label: Text(
                        'Sign Out of Administrator Portal',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                          color: colorScheme.error.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                              'Sign out of Administrator Portal?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  'Sign Out',
                                  style: TextStyle(color: colorScheme.error),
                                ),
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
      bottomNavigationBar: const AdminBottomNavBar(
        currentTab: AdminTab.settings,
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSettingsOverviewBanner(
    ThemeData theme,
    ColorScheme colorScheme,
    int keysCount,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Supabase Platform Schema',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$keysCount platform keys actively synchronized with backend PostgreSQL database.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const AppChip(
            label: 'SYNCED',
            backgroundColor: AppColors.success,
            textColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsGroup(BuildContext context, ColorScheme colorScheme) {
    return _GroupCard(
      children: [
        _SettingsSwitchTile(
          icon: Icons.construction,
          iconColor: const Color(0xFFE11D48),
          title: 'Maintenance Mode',
          subtitle:
              'Restrict citizen and practitioner access during migrations',
          value: _isMaintenanceMode ?? false,
          onChanged: (val) => setState(() => _isMaintenanceMode = val),
        ),
        if (_isMaintenanceMode == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: TextEditingController(text: _maintenanceMessage),
              decoration: const InputDecoration(
                labelText: 'Citizen Maintenance Banner Message',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _maintenanceMessage = v,
            ),
          ),
        const Divider(height: 1, indent: 64),
        _SettingsSwitchTile(
          icon: Icons.backup_outlined,
          iconColor: const Color(0xFF2563EB),
          title: 'Automated Database Backups',
          subtitle:
              'Daily snapshot schedule • $_backupRetentionDays days retention',
          value: _isAutoBackups ?? true,
          onChanged: (val) => setState(() => _isAutoBackups = val),
        ),
        const Divider(height: 1, indent: 64),
        _SettingsSwitchTile(
          icon: Icons.developer_mode,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Verbose Telemetry Logging',
          subtitle: 'Gateway diagnostics level: $_telemetryLogLevel',
          value: _isDebugTelemetry ?? false,
          onChanged: (val) {
            setState(() {
              _isDebugTelemetry = val;
              _telemetryLogLevel = val ? 'DEBUG' : 'INFO';
            });
          },
        ),
      ],
    );
  }

  Widget _buildAiPoliciesGroup(BuildContext context, ColorScheme colorScheme) {
    return _GroupCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.radar,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Broadcast Radius',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Maximum alert fanout: ${_broadcastRadiusKm.toStringAsFixed(0)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
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
            ],
          ),
        ),
        const Divider(height: 1, indent: 64),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Visual Sighting Match Threshold',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Confidence gate: ${_aiMatchThreshold.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Slider(
                value: _aiMatchThreshold,
                min: 50.0,
                max: 95.0,
                divisions: 9,
                label: '${_aiMatchThreshold.toStringAsFixed(0)}%',
                onChanged: (val) => setState(() => _aiMatchThreshold = val),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 64),
        _SettingsSwitchTile(
          icon: Icons.emergency_share,
          iconColor: const Color(0xFFDC2626),
          title: 'AI Triage Auto-Escalation',
          subtitle:
              'Dispatch high-confidence sightings to rescue units immediately',
          value: _aiTriageAutoEscalate,
          onChanged: (val) => setState(() => _aiTriageAutoEscalate = val),
        ),
      ],
    );
  }

  Widget _buildSecurityGroup(BuildContext context, ColorScheme colorScheme) {
    return _GroupCard(
      children: [
        _SettingsSwitchTile(
          icon: Icons.shield,
          iconColor: const Color(0xFF16A34A),
          title: 'Mandatory 2FA for Staff Accounts',
          subtitle:
              'Enforce two-factor verification on Veterinarian & Admin logins',
          value: _enforce2faForStaff,
          onChanged: (val) => setState(() => _enforce2faForStaff = val),
        ),
        const Divider(height: 1, indent: 64),
        _SettingsSwitchTile(
          icon: Icons.travel_explore,
          iconColor: const Color(0xFF0284C7),
          title: 'Public Guest Map Browsing',
          subtitle: 'Allow unauthenticated users to view lost pet broadcasts',
          value: _allowGuestBrowse,
          onChanged: (val) => setState(() => _allowGuestBrowse = val),
        ),
        const Divider(height: 1, indent: 64),
        _SettingsTile(
          icon: Icons.lock_clock,
          iconColor: const Color(0xFF7C3AED),
          title: 'Max Failed Login Lockout',
          subtitle:
              'Lockout account after $_maxFailedLogins consecutive failures',
          onTap: () async {
            final val = await showDialog<int>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: const Text('Failed Login Attempts'),
                children: [3, 5, 10]
                    .map(
                      (v) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, v),
                        child: Text('$v attempts ${v == 5 ? '(Default)' : ''}'),
                      ),
                    )
                    .toList(),
              ),
            );
            if (val != null) setState(() => _maxFailedLogins = val);
          },
        ),
        const Divider(height: 1, indent: 64),
        _SettingsTile(
          icon: Icons.timer,
          iconColor: const Color(0xFFEA580C),
          title: 'Staff Session Timeout',
          subtitle:
              'Automatic logout after $_sessionTimeoutMinutes minutes inactivity',
          onTap: () async {
            final val = await showDialog<int>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: const Text('Session Inactivity Timeout'),
                children: [15, 30, 60, 120]
                    .map(
                      (v) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, v),
                        child: Text('$v minutes ${v == 60 ? '(Default)' : ''}'),
                      ),
                    )
                    .toList(),
              ),
            );
            if (val != null) setState(() => _sessionTimeoutMinutes = val);
          },
        ),
      ],
    );
  }

  Widget _buildCommunicationGroup(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return _GroupCard(
      children: [
        _SettingsSwitchTile(
          icon: Icons.sms_outlined,
          iconColor: const Color(0xFF059669),
          title: 'Emergency SMS Dispatch Gateway',
          subtitle: 'Deliver direct SMS alerts to on-duty field responders',
          value: _emergencySmsDispatch,
          onChanged: (val) => setState(() => _emergencySmsDispatch = val),
        ),
        const Divider(height: 1, indent: 64),
        _SettingsSwitchTile(
          icon: Icons.mail_outline,
          iconColor: const Color(0xFF4F46E5),
          title: 'Transactional Email Relays',
          subtitle:
              'Deliver consultation confirmations, receipts, and e-prescriptions',
          value: _emailNotificationsEnabled,
          onChanged: (val) => setState(() => _emailNotificationsEnabled = val),
        ),
        const Divider(height: 1, indent: 64),
        _SettingsSwitchTile(
          icon: Icons.notifications_active_outlined,
          iconColor: const Color(0xFFD97706),
          title: 'FCM Push Notifications',
          subtitle:
              'Live broadcast alerts to iOS and Android companion devices',
          value: _pushNotificationsEnabled,
          onChanged: (val) => setState(() => _pushNotificationsEnabled = val),
        ),
      ],
    );
  }

  Widget _buildVeterinaryGroup(BuildContext context, ColorScheme colorScheme) {
    return _GroupCard(
      children: [
        _SettingsSwitchTile(
          icon: Icons.verified_user_outlined,
          iconColor: const Color(0xFF0284C7),
          title: 'Require Medical License Validation',
          subtitle:
              'Block e-prescriptions until practitioner license is accredited',
          value: _requirePrescriptionLicense,
          onChanged: (val) => setState(() => _requirePrescriptionLicense = val),
        ),
        const Divider(height: 1, indent: 64),
        _SettingsTile(
          icon: Icons.more_time,
          iconColor: const Color(0xFF6366F1),
          title: 'Telemedicine Buffer Interval',
          subtitle:
              '$_telemedicineBufferMinutes minutes buffer between consultations',
          onTap: () async {
            final val = await showDialog<int>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: const Text('Consultation Buffer Duration'),
                children: [5, 10, 15]
                    .map(
                      (v) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, v),
                        child: Text(
                          '$v minutes transition buffer ${v == 10 ? '(Default)' : ''}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
            if (val != null) setState(() => _telemedicineBufferMinutes = val);
          },
        ),
      ],
    );
  }

  Widget _buildDynamicKeyCatalogGroup(
    BuildContext context,
    ColorScheme colorScheme,
    List<PlatformSetting> settings,
  ) {
    return _GroupCard(
      children: [
        if (settings.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('No platform keys found in database.')),
          )
        else
          ...settings.map(
            (s) => Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.key, color: Colors.white, size: 18),
                  ),
                  title: Text(
                    s.settingKey,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    s.settingValue.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onTap: () => _editKeyDialog(s),
                ),
                if (s != settings.last) const Divider(height: 1, indent: 64),
              ],
            ),
          ),
      ],
    );
  }
}

/// Telegram-style card container with subtle shadow and border radius.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

/// Telegram-style list item tile with solid colored squircle and white icon.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 13))
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

/// Telegram-style switch tile with solid colored squircle and white icon.
class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      value: value,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }
}
