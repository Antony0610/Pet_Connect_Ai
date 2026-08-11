import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Administrator Platform Reports Screen (Stitch ID: `e316a363c8d94e76916ab208963e0f91`).
///
/// Analytics and ecosystem metrics dashboard screen. Displays growth KPI cards,
/// AI inferencing usage metrics, consultation volume, and report export tools.
class AdminPlatformReportsScreen extends StatefulWidget {
  const AdminPlatformReportsScreen({super.key});

  @override
  State<AdminPlatformReportsScreen> createState() =>
      _AdminPlatformReportsScreenState();
}

class _AdminPlatformReportsScreenState
    extends State<AdminPlatformReportsScreen> {
  String _selectedTimeframe = 'Last 30 Days';

  final List<Map<String, dynamic>> _reportCategories = const [
    {
      'title': 'User Growth & Retention Report',
      'desc': 'Detailed breakdown of active pet owners, vets, and rescuers',
      'icon': Icons.group_outlined,
      'stats': '24.5k active',
      'trend': '+12%',
      'color': AppColors.info,
    },
    {
      'title': 'AI Diagnostic Performance Telemetry',
      'desc': 'Inference latency, accuracy confidence, and scan volume',
      'icon': Icons.psychology_outlined,
      'stats': '1.2M scans',
      'trend': '+24%',
      'color': AppColors.success,
    },
    {
      'title': 'Veterinary Consultation Revenue & Volume',
      'desc': 'Completed appointments, prescription counts, and payout logs',
      'icon': Icons.local_hospital_outlined,
      'stats': '8,940 consultations',
      'trend': '+8%',
      'color': AppColors.warning,
    },
    {
      'title': 'Emergency Dispatch Incident Logs',
      'desc': 'Active search ops, BLE beacon hits, and rescue response times',
      'icon': Icons.shield_outlined,
      'stats': '1,420 dispatches',
      'trend': '-5%',
      'color': AppColors.lightError,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Platform Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exporting Platform Analytics CSV...'),
                ),
              );
            },
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Timeframe Filter Header Card ────────────────────
                _buildTimeframeHeaderCard(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── KPI Growth Metrics Grid ──────────────────────────
                _buildKpiMetricsGrid(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Detailed Report Categories ──────────────────────
                Text(
                  'Ecosystem Analytics Reports',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,

                ..._reportCategories.map(
                  (rep) => _buildReportTile(context, theme, colorScheme, rep),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeHeaderCard(ThemeData theme, ColorScheme colorScheme) {
    final timeframes = [
      'Last 7 Days',
      'Last 30 Days',
      'Last 90 Days',
      'Year to Date',
    ];

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
              DropdownButton<String>(
                value: _selectedTimeframe,
                underline: const SizedBox(),
                items: timeframes.map((tf) {
                  return DropdownMenuItem(value: tf, child: Text(tf));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTimeframe = val);
                },
              ),
            ],
          ),
          Text(
            'Aggregated telemetry and usage growth for $_selectedTimeframe.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsGrid(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            theme,
            colorScheme,
            value: '24.5k',
            label: 'Total Users',
            trend: '+12%',
            trendColor: AppColors.success,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildKpiCard(
            theme,
            colorScheme,
            value: '1.2M',
            label: 'AI Inferences',
            trend: '+24%',
            trendColor: AppColors.success,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildKpiCard(
            theme,
            colorScheme,
            value: '8.9k',
            label: 'Vet Consults',
            trend: '+8%',
            trendColor: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String value,
    required String label,
    required String trend,
    required Color trendColor,
  }) {
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

  Widget _buildReportTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> rep,
  ) {
    final color = rep['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(rep['icon'] as IconData, color: color),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rep['title'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    rep['desc'] as String,
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
                  rep['stats'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  rep['trend'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
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
}
