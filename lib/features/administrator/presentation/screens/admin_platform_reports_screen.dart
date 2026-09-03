import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_report_summary.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/states/error_view.dart';

/// **Administrator Platform Reports** — `/admin/reports` (Phase 11).
///
/// Reads live data from `vw_platform_reports` via [adminPlatformReportsProvider].
/// The backend enforces that only the `administrator` role can access this view.
///
/// All KPI values are real database counts — no hardcoded values.
class AdminPlatformReportsScreen extends ConsumerStatefulWidget {
  const AdminPlatformReportsScreen({super.key});

  @override
  ConsumerState<AdminPlatformReportsScreen> createState() =>
      _AdminPlatformReportsScreenState();
}

class _AdminPlatformReportsScreenState
    extends ConsumerState<AdminPlatformReportsScreen> {
  void _exportReportCsv(PlatformReportSummary? summary) {
    if (summary == null) return;
    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('      PETCONNECT AI PLATFORM ANALYTICS REPORT       ');
    buffer.writeln('====================================================');
    buffer.writeln('Export Timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Report Month: ${summary.reportMonth.toIso8601String()}');
    buffer.writeln('Total Registered Users: ${summary.totalUsers}');
    buffer.writeln('Active Pet Owners: ${summary.totalPetOwners}');
    buffer.writeln('Licensed Veterinarians: ${summary.totalVeterinarians}');
    buffer.writeln('Field Rescuers: ${summary.totalRescuers}');
    buffer.writeln('System Administrators: ${summary.totalAdministrators}');
    buffer.writeln('Appointments Booked: ${summary.totalAppointments}');
    buffer.writeln('Completed Consultations: ${summary.completedAppointments}');
    buffer.writeln('AI Triage Conversations: ${summary.totalAiConversations}');
    buffer.writeln('AI Health Scans: ${summary.totalAiScans}');
    buffer.writeln(
      'Rescue Missions Dispatched: ${summary.totalRescueMissions}',
    );
    buffer.writeln('Missing Pet Alerts: ${summary.totalLostPetAlerts}');
    buffer.writeln('Refreshed At: ${summary.refreshedAt.toIso8601String()}');
    buffer.writeln('====================================================');

    ExternalActions.shareText(
      buffer.toString(),
      subject: 'PetConnect AI Platform Analytics Report',
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(adminPlatformReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Platform Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(adminPlatformReportsProvider),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _exportReportCsv(reportsAsync.valueOrNull),
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'Could not load platform analytics.',
          onRetry: () => ref.invalidate(adminPlatformReportsProvider),
        ),
        data: (summary) {
          if (summary == null) {
            return const Center(
              child: Text(
                'No platform data available.\nRun "Refresh" to populate analytics.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return _ReportsBody(summary: summary);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.summary});

  final PlatformReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary Header ────────────────────────────────────────────
              _buildSummaryCard(theme, colorScheme),

              AppSpacing.vGapLg,

              // ── User Growth KPI Grid ──────────────────────────────────────
              Text(
                'User Growth',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppSpacing.vGapSm,
              _buildUserKpiGrid(theme, colorScheme),

              AppSpacing.vGapLg,

              // ── Platform Activity KPI Grid ────────────────────────────────
              Text(
                'Platform Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppSpacing.vGapSm,
              _buildActivityKpiGrid(theme, colorScheme),

              AppSpacing.vGapLg,

              // ── Detailed Report Categories ────────────────────────────────
              Text(
                'Ecosystem Analytics Reports',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppSpacing.vGapSm,

              _buildReportTile(
                context,
                theme,
                colorScheme,
                icon: Icons.group_outlined,
                title: 'User Growth & Retention',
                desc: 'Active pet owners, vets, rescuers, and administrators',
                stats: _formatCount(summary.totalUsers),
                trend: '${summary.totalPetOwners} pet owners',
                color: AppColors.info,
              ),
              _buildReportTile(
                context,
                theme,
                colorScheme,
                icon: Icons.psychology_outlined,
                title: 'AI Diagnostic Performance',
                desc: 'AI chat sessions and multimodal health scan volume',
                stats: _formatCount(summary.totalAiScans),
                trend: '${_formatCount(summary.totalAiConversations)} chats',
                color: AppColors.success,
              ),
              _buildReportTile(
                context,
                theme,
                colorScheme,
                icon: Icons.local_hospital_outlined,
                title: 'Veterinary Consultation Volume',
                desc: 'Completed appointments out of total scheduled',
                stats: '${summary.completedAppointments} completed',
                trend: '${summary.totalAppointments} total',
                color: AppColors.warning,
              ),
              _buildReportTile(
                context,
                theme,
                colorScheme,
                icon: Icons.shield_outlined,
                title: 'Emergency Dispatch & Rescue',
                desc: 'Rescue missions dispatched and active lost-pet alerts',
                stats: '${summary.totalRescueMissions} missions',
                trend: '${summary.totalLostPetAlerts} alerts',
                color: AppColors.lightError,
              ),

              AppSpacing.vGapXl,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF7C3AED,
            ).withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.3 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Ecosystem Performance Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Refreshed ${_formatDate(summary.refreshedAt)}',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Platform-wide aggregate metrics as of ${_formatMonth(summary.reportMonth)}.',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildUserKpiGrid(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            theme: theme,
            colorScheme: colorScheme,
            value: _formatCount(summary.totalUsers),
            label: 'Total Users',
            trend: '${summary.totalPetOwners} owners',
            trendColor: const Color(0xFF7C3AED),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _KpiCard(
            theme: theme,
            colorScheme: colorScheme,
            value: _formatCount(summary.totalVeterinarians),
            label: 'Veterinarians',
            trend: '${summary.totalRescuers} rescuers',
            trendColor: const Color(0xFF2563EB),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _KpiCard(
            theme: theme,
            colorScheme: colorScheme,
            value: _formatCount(summary.totalAdministrators),
            label: 'Admins',
            trend: '${summary.totalRescuers} rescuers',
            trendColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityKpiGrid(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            theme: theme,
            colorScheme: colorScheme,
            value: _formatCount(summary.totalAppointments),
            label: 'Appointments',
            trend: '${summary.completedAppointments} completed',
            trendColor: const Color(0xFF0284C7),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _KpiCard(
            theme: theme,
            colorScheme: colorScheme,
            value: _formatCount(summary.totalAiScans),
            label: 'AI Scans',
            trend: '${summary.totalAiConversations} triage',
            trendColor: const Color(0xFF059669),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _KpiCard(
            theme: theme,
            colorScheme: colorScheme,
            value: _formatCount(summary.totalRescueMissions),
            label: 'Rescues',
            trend: '${summary.totalLostPetAlerts} alerts',
            trendColor: const Color(0xFFEA580C),
          ),
        ),
      ],
    );
  }

  Widget _buildReportTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String desc,
    required String stats,
    required String trend,
    required Color color,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
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
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stats,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _formatMonth(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ---------------------------------------------------------------------------

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.theme,
    required this.colorScheme,
    required this.value,
    required this.label,
    required this.trend,
    required this.trendColor,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final String value;
  final String label;
  final String trend;
  final Color trendColor;

  @override
  Widget build(BuildContext context) {
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
          color: trendColor.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: trendColor,
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
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trend,
              style: TextStyle(
                color: trendColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
