import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/platform_report_summary.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reportsAsync = ref.watch(adminPlatformReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Platform Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(adminPlatformReportsProvider),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming in Phase 14.'),
                ),
              );
            },
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
                desc:
                    'Active pet owners, vets, rescuers, and administrators',
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
                desc:
                    'AI chat sessions and multimodal health scan volume',
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
                desc:
                    'Completed appointments out of total scheduled',
                stats: '${summary.completedAppointments} completed',
                trend:
                    '${summary.totalAppointments} total',
                color: AppColors.warning,
              ),
              _buildReportTile(
                context,
                theme,
                colorScheme,
                icon: Icons.shield_outlined,
                title: 'Emergency Dispatch & Rescue',
                desc:
                    'Rescue missions dispatched and active lost-pet alerts',
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ecosystem Performance Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppChip(
                label:
                    'Refreshed ${_formatDate(summary.refreshedAt)}',
                backgroundColor:
                    AppColors.success.withValues(alpha: 0.12),
                textColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Platform-wide aggregate metrics as of ${_formatMonth(summary.reportMonth)}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
            trendColor: AppColors.success,
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
            trendColor: AppColors.info,
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
            value: _formatCount(summary.totalAiScans),
            label: 'AI Scans',
            trend: '${_formatCount(summary.totalAiConversations)} chats',
            trendColor: AppColors.success,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _KpiCard(
            theme: theme,
            colorScheme: colorScheme,
            value: _formatCount(summary.totalAppointments),
            label: 'Vet Consults',
            trend: '${summary.completedAppointments} done',
            trendColor: AppColors.info,
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
            trendColor: AppColors.warning,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
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
                    desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  trend,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ],
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          AppSpacing.vGapXs,
          AppChip(
            label: trend,
            backgroundColor: trendColor.withValues(alpha: 0.15),
            textColor: trendColor,
          ),
        ],
      ),
    );
  }
}
