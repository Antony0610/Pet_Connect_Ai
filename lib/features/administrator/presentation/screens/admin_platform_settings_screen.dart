import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Administrator Platform Settings Screen (Stitch ID: `dc36e9199b4540eea867b5c17e3b5d46`).
///
/// Global system configurations and administrative branding/policy settings.
/// Displays branding & asset management, localization preferences, privacy policies,
/// and maintenance mode toggles.
class AdminPlatformSettingsScreen extends StatefulWidget {
  const AdminPlatformSettingsScreen({super.key});

  @override
  State<AdminPlatformSettingsScreen> createState() =>
      _AdminPlatformSettingsScreenState();
}

class _AdminPlatformSettingsScreenState
    extends State<AdminPlatformSettingsScreen> {
  bool _isMaintenanceMode = false;
  bool _isAutoBackups = true;
  bool _isDebugTelemetry = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Settings & Configurations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
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
                      const SnackBar(content: Text('Opening Asset Manager...')),
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
                      'Default locale: en_US • 12 supported system languages.',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Localization...')),
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
                        content: Text('Opening Legal Policies...'),
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
                  text: 'Save Global Settings',
                  icon: Icons.save,
                  isFullWidth: true,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Platform settings saved!')),
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
                'System Info & Operational Controls',
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
              'Restrict portal access to emergency maintenance screen',
            ),
            value: _isMaintenanceMode,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isMaintenanceMode = val),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Automated Database Backups'),
            subtitle: const Text('Daily PostgreSQL automated snapshot'),
            value: _isAutoBackups,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isAutoBackups = val),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Verbose Telemetry Logging'),
            subtitle: const Text('Detailed API gateway request tracing'),
            value: _isDebugTelemetry,
            activeTrackColor: colorScheme.primary,
            onChanged: (val) => setState(() => _isDebugTelemetry = val),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
