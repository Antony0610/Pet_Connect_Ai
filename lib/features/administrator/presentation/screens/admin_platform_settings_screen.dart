import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
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
/// Telegram flat-list styled platform configuration and policy governance hub.
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Sign out of Administrator Portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(signOutProvider)(const NoParams());
      if (mounted) context.go(RoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final settingsAsync = ref.watch(adminPlatformSettingsProvider);

    final bottomPad = context.viewPadding.bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Platform Governance & Settings',
          style: text.titleLarge?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
          ),
        ),
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
            padding: EdgeInsets.fromLTRB(
              0,
              AppSpacing.sm,
              0,
              bottomPad,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Active Database Keys Counter Banner ───────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildSettingsOverviewBanner(
                        context,
                        scheme,
                        settings.length,
                      ),
                    ),
                    _buildSectionDivider(scheme),

                    // ── 1. Core Platform & Operations ──────────────────
                    _buildTelegramSectionHeader('Core Platform & Operations', scheme),
                    _buildTelegramSwitchTile(
                      icon: Icons.construction_rounded,
                      iconBgColor: const Color(0xFFE11D48),
                      title: 'Maintenance Mode',
                      subtitle: 'Restrict citizen and practitioner access during migrations',
                      value: _isMaintenanceMode ?? false,
                      onChanged: (val) => setState(() => _isMaintenanceMode = val),
                    ),
                    if (_isMaintenanceMode == true)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                    _buildTelegramSwitchTile(
                      icon: Icons.backup_rounded,
                      iconBgColor: const Color(0xFF2563EB),
                      title: 'Automated Database Backups',
                      subtitle: 'Daily snapshot schedule • $_backupRetentionDays days retention',
                      value: _isAutoBackups ?? true,
                      onChanged: (val) => setState(() => _isAutoBackups = val),
                    ),
                    _buildTelegramSwitchTile(
                      icon: Icons.developer_mode_rounded,
                      iconBgColor: const Color(0xFF8B5CF6),
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
                    _buildSectionDivider(scheme),

                    // ── 2. Emergency Dispatch & AI Policies ───────────
                    _buildTelegramSectionHeader('Emergency Dispatch & AI Policies', scheme),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                child: const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emergency Broadcast Radius',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Maximum alert fanout: ${_broadcastRadiusKm.toStringAsFixed(0)} km',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_broadcastRadiusKm.toStringAsFixed(0)} km',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Slider.adaptive(
                            value: _broadcastRadiusKm,
                            min: 5.0,
                            max: 100.0,
                            divisions: 19,
                            activeColor: scheme.primary,
                            label: '${_broadcastRadiusKm.toStringAsFixed(0)} km',
                            onChanged: (val) => setState(() => _broadcastRadiusKm = val),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Visual Sighting Match Threshold',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Confidence gate: ${_aiMatchThreshold.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_aiMatchThreshold.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Slider.adaptive(
                            value: _aiMatchThreshold,
                            min: 50.0,
                            max: 95.0,
                            divisions: 9,
                            activeColor: scheme.primary,
                            label: '${_aiMatchThreshold.toStringAsFixed(0)}%',
                            onChanged: (val) => setState(() => _aiMatchThreshold = val),
                          ),
                        ],
                      ),
                    ),
                    _buildTelegramSwitchTile(
                      icon: Icons.emergency_share_rounded,
                      iconBgColor: const Color(0xFFDC2626),
                      title: 'AI Triage Auto-Escalation',
                      subtitle: 'Dispatch high-confidence sightings to rescue units immediately',
                      value: _aiTriageAutoEscalate,
                      onChanged: (val) => setState(() => _aiTriageAutoEscalate = val),
                    ),
                    _buildSectionDivider(scheme),

                    // ── 3. Security & Access Control ──────────────────
                    _buildTelegramSectionHeader('Security & Access Control', scheme),
                    _buildTelegramSwitchTile(
                      icon: Icons.shield_rounded,
                      iconBgColor: const Color(0xFF16A34A),
                      title: 'Mandatory 2FA for Staff Accounts',
                      subtitle: 'Enforce two-factor verification on Veterinarian & Admin logins',
                      value: _enforce2faForStaff,
                      onChanged: (val) => setState(() => _enforce2faForStaff = val),
                    ),
                    _buildTelegramSwitchTile(
                      icon: Icons.travel_explore_rounded,
                      iconBgColor: const Color(0xFF0284C7),
                      title: 'Public Guest Map Browsing',
                      subtitle: 'Allow unauthenticated users to view lost pet broadcasts',
                      value: _allowGuestBrowse,
                      onChanged: (val) => setState(() => _allowGuestBrowse = val),
                    ),
                    _buildTelegramTile(
                      icon: Icons.lock_clock_rounded,
                      iconBgColor: const Color(0xFF7C3AED),
                      title: 'Max Failed Login Lockout',
                      subtitle: 'Lockout account after $_maxFailedLogins consecutive failures',
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
                    _buildTelegramTile(
                      icon: Icons.timer_rounded,
                      iconBgColor: const Color(0xFFEA580C),
                      title: 'Staff Session Timeout',
                      subtitle: 'Automatic logout after $_sessionTimeoutMinutes minutes inactivity',
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
                    _buildSectionDivider(scheme),

                    // ── 4. Dispatch Communication Relays ──────────────
                    _buildTelegramSectionHeader('Dispatch Communication Relays', scheme),
                    _buildTelegramSwitchTile(
                      icon: Icons.sms_rounded,
                      iconBgColor: const Color(0xFF059669),
                      title: 'Emergency SMS Dispatch Gateway',
                      subtitle: 'Deliver direct SMS alerts to on-duty field responders',
                      value: _emergencySmsDispatch,
                      onChanged: (val) => setState(() => _emergencySmsDispatch = val),
                    ),
                    _buildTelegramSwitchTile(
                      icon: Icons.mail_rounded,
                      iconBgColor: const Color(0xFF4F46E5),
                      title: 'Transactional Email Relays',
                      subtitle: 'Deliver consultation confirmations, receipts, and e-prescriptions',
                      value: _emailNotificationsEnabled,
                      onChanged: (val) => setState(() => _emailNotificationsEnabled = val),
                    ),
                    _buildTelegramSwitchTile(
                      icon: Icons.notifications_active_rounded,
                      iconBgColor: const Color(0xFFD97706),
                      title: 'FCM Push Notifications',
                      subtitle: 'Live broadcast alerts to companion mobile apps',
                      value: _pushNotificationsEnabled,
                      onChanged: (val) => setState(() => _pushNotificationsEnabled = val),
                    ),
                    _buildSectionDivider(scheme),

                    // ── 5. Veterinary & Telemedicine Governance ────────
                    _buildTelegramSectionHeader('Veterinary & Telemedicine Governance', scheme),
                    _buildTelegramSwitchTile(
                      icon: Icons.verified_user_rounded,
                      iconBgColor: const Color(0xFF0284C7),
                      title: 'Require Medical License Validation',
                      subtitle: 'Block e-prescriptions until practitioner license is accredited',
                      value: _requirePrescriptionLicense,
                      onChanged: (val) => setState(() => _requirePrescriptionLicense = val),
                    ),
                    _buildTelegramTile(
                      icon: Icons.more_time_rounded,
                      iconBgColor: const Color(0xFF6366F1),
                      title: 'Telemedicine Buffer Interval',
                      subtitle: '$_telemedicineBufferMinutes minutes buffer between consultations',
                      onTap: () async {
                        final val = await showDialog<int>(
                          context: context,
                          builder: (ctx) => SimpleDialog(
                            title: const Text('Consultation Buffer Duration'),
                            children: [5, 10, 15]
                                .map(
                                  (v) => SimpleDialogOption(
                                    onPressed: () => Navigator.pop(ctx, v),
                                    child: Text('$v minutes transition buffer ${v == 10 ? '(Default)' : ''}'),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                        if (val != null) setState(() => _telemedicineBufferMinutes = val);
                      },
                    ),
                    _buildSectionDivider(scheme),

                    // ── 6. Database Schema Inspector ──────────────────
                    _buildTelegramSectionHeader(
                      'Database Schema Inspector (${settings.length} Keys)',
                      scheme,
                    ),
                    if (settings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No platform keys found in database.')),
                      )
                    else
                      ...settings.map(
                        (s) => _buildTelegramTile(
                          icon: Icons.key_rounded,
                          iconBgColor: scheme.primary,
                          title: s.settingKey,
                          subtitle: s.settingValue.toString(),
                          trailingWidget: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onTap: () => _editKeyDialog(s),
                        ),
                      ),
                    _buildSectionDivider(scheme),

                    // ── 7. Global Actions ─────────────────────────────
                    _buildTelegramSectionHeader('Governance Actions', scheme),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: AppButton(
                        text: _isSaving
                            ? 'Synchronizing to Supabase...'
                            : 'Save Global Configurations',
                        icon: Icons.save_rounded,
                        isLoading: _isSaving,
                        isFullWidth: true,
                        onPressed: _isSaving ? null : _saveSettings,
                        backgroundColor: scheme.primary,
                        textColor: scheme.onPrimary,
                        height: 50,
                      ),
                    ),
                    _buildTelegramTile(
                      icon: Icons.logout_rounded,
                      iconBgColor: const Color(0xFFEF4444),
                      title: 'Sign Out of Administrator Portal',
                      subtitle: 'Safely disconnect executive session',
                      isDestructive: true,
                      onTap: _signOut,
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

  Widget _buildSettingsOverviewBanner(
    BuildContext context,
    ColorScheme scheme,
    int keysCount,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$keysCount platform keys actively synchronized with backend PostgreSQL database.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

  Widget _buildTelegramSectionHeader(String title, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTelegramTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailingWidget,
    bool isDestructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? const Color(0xFFEF4444) : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramSwitchTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: scheme.primary,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: scheme.outlineVariant.withValues(alpha: 0.25),
      ),
    );
  }
}
