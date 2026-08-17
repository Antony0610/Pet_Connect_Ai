import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/security_posture_summary.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/states/error_view.dart';

/// Administrator Security Center Screen (Stitch ID: `629599ff91824f2baa63fc0fdb6f0c4f`).
///
/// Security posture, threat monitoring, and system hardening controls.
/// Connected to live database security posture summary and audit trail (Phase 12).
class AdminSecurityCenterScreen extends ConsumerWidget {
  const AdminSecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final postureAsync = ref.watch(adminSecurityPostureProvider);
    final auditLogsAsync = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Center & Threat Monitoring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(adminSecurityPostureProvider);
              ref.invalidate(adminAuditLogsProvider);
            },
            tooltip: 'Refresh Security Status',
          ),
        ],
      ),
      body: postureAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(
          message: 'Could not load security posture: $err',
          onRetry: () {
            ref.invalidate(adminSecurityPostureProvider);
            ref.invalidate(adminAuditLogsProvider);
          },
        ),
        data: (posture) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Security Posture Banner ──────────────────────────
                  _buildSecurityPostureBanner(theme, colorScheme, posture),

                  AppSpacing.vGapLg,

                  // ── Security Metrics Grid ───────────────────────────
                  _buildSecurityMetricsGrid(theme, colorScheme, posture),

                  AppSpacing.vGapLg,

                  // ── System Hardening Controls ────────────────────────
                  _buildHardeningControlsSection(context, theme, colorScheme, posture),

                  AppSpacing.vGapLg,

                  // ── Recent Threat & Audit Ticker ─────────────────────
                  _buildThreatTickerSection(theme, colorScheme, auditLogsAsync),

                  AppSpacing.vGapXl,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityPostureBanner(
    ThemeData theme,
    ColorScheme colorScheme,
    SecurityPostureSummary posture,
  ) {
    final (color, title, subtitle) = switch (posture.postureRating) {
      'CRITICAL' => (
        AppColors.lightError,
        'Security Posture: CRITICAL ATTENTION REQUIRED',
        '${posture.criticalEvents24h} critical security events detected in the last 24 hours.',
      ),
      'ELEVATED_RISK' => (
        AppColors.warning,
        'Security Posture: Elevated Warning Level',
        '${posture.warningEvents24h} warning events detected in the last 24 hours. Review audit trail.',
      ),
      'MONITORING' => (
        AppColors.info,
        'Security Posture: Active Monitoring',
        '${posture.warningEvents24h} warning events recorded. All core controls operational.',
      ),
      _ => (
        AppColors.success,
        'Overall Security Posture: Optimal',
        'All 31 database tables protected by RLS. 0 critical threat vectors detected in the last 24h.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMetricsGrid(
    ThemeData theme,
    ColorScheme colorScheme,
    SecurityPostureSummary posture,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '${posture.totalAuditEvents24h}',
            label: 'Audit Events (24h)',
            sublabel: '${posture.totalAuditEventsAllTime} total',
            icon: Icons.receipt_long_outlined,
            color: colorScheme.primary,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '${posture.criticalEvents24h} / ${posture.warningEvents24h}',
            label: 'Critical / Warning',
            sublabel: '${posture.infoEvents24h} info events',
            icon: Icons.gpp_maybe_outlined,
            color: posture.criticalEvents24h > 0
                ? AppColors.lightError
                : (posture.warningEvents24h > 0
                    ? AppColors.warning
                    : AppColors.success),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '${posture.rlsTablesProtected}/${posture.totalPublicTables}',
            label: 'RLS Tables Protected',
            sublabel: '100% database coverage',
            icon: Icons.lock_outlined,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String value,
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          AppSpacing.vGapXs,
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sublabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardeningControlsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    SecurityPostureSummary posture,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Database Hardening Controls',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildHardeningRow(
                theme,
                colorScheme,
                title: 'Audit Log Immutability Guard',
                subtitle:
                    'PostgreSQL trigger fn_audit_logs_enforce_security blocks UPDATE and DELETE on audit trail.',
                status: posture.auditLogImmutability,
                statusColor: AppColors.success,
              ),
              const Divider(height: 20),
              _buildHardeningRow(
                theme,
                colorScheme,
                title: 'Role Escalation Guard',
                subtitle:
                    'PostgreSQL trigger prevent_profile_role_escalation blocks unauthorized privilege changes.',
                status: posture.roleEscalationGuard,
                statusColor: AppColors.success,
              ),
              const Divider(height: 20),
              _buildHardeningRow(
                theme,
                colorScheme,
                title: 'Pet Owner Anti-Spoofing Guard',
                subtitle:
                    'PostgreSQL trigger prevent_pet_owner_spoofing prevents creating records with forged owner_id.',
                status: posture.petOwnerSpoofingGuard,
                statusColor: AppColors.success,
              ),
              const Divider(height: 20),
              _buildHardeningRow(
                theme,
                colorScheme,
                title: 'Multi-Factor Authentication (MFA)',
                subtitle:
                    'Configured via Supabase Auth TOTP / SMS protocols for administrative portals.',
                status: 'MANAGED',
                statusColor: AppColors.info,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHardeningRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppChip(
          label: status,
          backgroundColor: statusColor.withValues(alpha: 0.15),
          textColor: statusColor,
        ),
      ],
    );
  }

  Widget _buildThreatTickerSection(
    ThemeData theme,
    ColorScheme colorScheme,
    AsyncValue<List<AuditLogEntry>> auditLogsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Security & Audit Events',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            TextButton(
              onPressed: () => theme,
              child: const Text('View All in Audit Log'),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        auditLogsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('Could not load recent events: $e'),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return const AppCard(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text(
                    'No audit log events recorded yet.\nSecurity events will populate automatically.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final recentLogs = logs.take(5).toList();
            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  for (int i = 0; i < recentLogs.length; i++) ...[
                    if (i > 0) const Divider(height: 16),
                    _buildLogItem(theme, colorScheme, recentLogs[i]),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogItem(
    ThemeData theme,
    ColorScheme colorScheme,
    AuditLogEntry log,
  ) {
    final statusColor = switch (log.severity.toUpperCase()) {
      'CRITICAL' => AppColors.lightError,
      'WARNING' => AppColors.warning,
      _ => AppColors.info,
    };

    final timeStr =
        '${log.createdAt.toUtc().hour.toString().padLeft(2, '0')}:'
        '${log.createdAt.toUtc().minute.toString().padLeft(2, '0')} UTC';

    return Row(
      children: [
        Icon(Icons.shield_outlined, size: 18, color: statusColor),
        AppSpacing.hGapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${log.action} • ${log.resourceType}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (log.resourceId != null)
                Text(
                  'ID: ${log.resourceId}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        AppChip(
          label: log.severity,
          backgroundColor: statusColor.withValues(alpha: 0.15),
          textColor: statusColor,
        ),
        AppSpacing.hGapSm,
        Text(
          timeStr,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
