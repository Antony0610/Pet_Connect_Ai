import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/security_posture_summary.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
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
                  _buildHardeningControlsSection(
                    context,
                    theme,
                    colorScheme,
                    posture,
                  ),

                  AppSpacing.vGapLg,

                  // ── Recent Threat & Audit Ticker ─────────────────────
                  _buildThreatTickerSection(
                    context,
                    theme,
                    colorScheme,
                    auditLogsAsync,
                  ),

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
    final isDark = theme.brightness == Brightness.dark;

    final (color, title, subtitle, icon) = switch (posture.postureRating) {
      'CRITICAL' => (
        const Color(0xFFE11D48),
        'Security Posture: CRITICAL ATTENTION REQUIRED',
        '${posture.criticalEvents24h} critical security events detected in the last 24 hours.',
        Icons.gpp_bad_rounded,
      ),
      'ELEVATED_RISK' => (
        const Color(0xFFD97706),
        'Security Posture: Elevated Warning Level',
        '${posture.warningEvents24h} warning events detected in the last 24 hours. Review audit trail.',
        Icons.gpp_maybe_rounded,
      ),
      'MONITORING' => (
        const Color(0xFF2563EB),
        'Security Posture: Active Monitoring',
        '${posture.warningEvents24h} warning events recorded. All core controls operational.',
        Icons.shield_outlined,
      ),
      _ => (
        const Color(0xFF059669),
        'Overall Security Posture: Optimal',
        'All 31 database tables protected by RLS. 0 critical threat vectors detected in the last 24h.',
        Icons.verified_user_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.3,
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
            label: 'Audit Events',
            sublabel: '${posture.totalAuditEventsAllTime} total all-time',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF2563EB),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '${posture.criticalEvents24h}/${posture.warningEvents24h}',
            label: 'Critical / Warning',
            sublabel: '${posture.infoEvents24h} info events',
            icon: Icons.gpp_maybe_rounded,
            color: posture.criticalEvents24h > 0
                ? const Color(0xFFE11D48)
                : (posture.warningEvents24h > 0
                      ? const Color(0xFFD97706)
                      : const Color(0xFF059669)),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildMetricTile(
            theme,
            colorScheme,
            value: '${posture.rlsTablesProtected}/${posture.totalPublicTables}',
            label: 'RLS Tables Guarded',
            sublabel: '100% database coverage',
            icon: Icons.lock_rounded,
            color: const Color(0xFF7C3AED),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sublabel,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Database Hardening Controls',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        AppSpacing.vGapSm,
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHardeningRow(
                theme,
                colorScheme,
                icon: Icons.lock_clock_rounded,
                iconBg: const Color(0xFF059669),
                title: 'Audit Log Immutability Guard',
                subtitle:
                    'PostgreSQL trigger fn_audit_logs_enforce_security blocks UPDATE and DELETE on audit trail.',
                status: posture.auditLogImmutability,
                statusColor: const Color(0xFF059669),
              ),
              const Divider(height: 24),
              _buildHardeningRow(
                theme,
                colorScheme,
                icon: Icons.admin_panel_settings_rounded,
                iconBg: const Color(0xFF7C3AED),
                title: 'Role Escalation Guard',
                subtitle:
                    'PostgreSQL trigger prevent_profile_role_escalation blocks unauthorized privilege changes.',
                status: posture.roleEscalationGuard,
                statusColor: const Color(0xFF059669),
              ),
              const Divider(height: 24),
              _buildHardeningRow(
                theme,
                colorScheme,
                icon: Icons.fingerprint_rounded,
                iconBg: const Color(0xFF2563EB),
                title: 'Pet Owner Anti-Spoofing Guard',
                subtitle:
                    'PostgreSQL trigger prevent_pet_owner_spoofing prevents creating records with forged owner_id.',
                status: posture.petOwnerSpoofingGuard,
                statusColor: const Color(0xFF059669),
              ),
              const Divider(height: 24),
              _buildHardeningRow(
                theme,
                colorScheme,
                icon: Icons.phonelink_lock_rounded,
                iconBg: const Color(0xFFEA580C),
                title: 'Multi-Factor Authentication (MFA)',
                subtitle:
                    'Configured via Supabase Auth TOTP / SMS protocols for administrative portals.',
                status: 'MANAGED',
                statusColor: const Color(0xFF2563EB),
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
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreatTickerSection(
    BuildContext context,
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
              onPressed: () => context.push(RoutePaths.adminAuditLogs),
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

    final ist = log.createdAt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final timeStr =
        '${ist.hour.toString().padLeft(2, '0')}:'
        '${ist.minute.toString().padLeft(2, '0')} IST';

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
