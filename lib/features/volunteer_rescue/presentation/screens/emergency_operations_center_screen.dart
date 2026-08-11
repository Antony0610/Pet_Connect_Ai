import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Emergency Operations Center Screen (Stitch ID: `9d9ba29256fe4506893784a7aaa325df`).
///
/// Multi-agency disaster command and field coordination dashboard. Displays high-level
/// emergency alerts, shelter capacity gauges, broadcast tickers, and unit allocation.
class EmergencyOperationsCenterScreen extends StatelessWidget {
  const EmergencyOperationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Operations Center (EOC)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rescue'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency broadcast ticker updated'),
                ),
              );
            },
            tooltip: 'Broadcast Ticker',
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
                // ── EOC Command Header Banner ────────────────────────
                _buildEocHeaderBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Status Metric Counter Row ───────────────────────
                _buildEocStatusCounters(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Active Escalated Incident Control ───────────────
                _buildEscalatedIncidentsSection(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Shelter Capacity & Resource Allocation ──────────
                _buildShelterCapacitySection(theme, colorScheme),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEocHeaderBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.error,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emergency, color: colorScheme.onError, size: 24),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multi-Agency Emergency Command',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  'Active disaster response oversight and volunteer unit allocation across Sector 4 & 5.',
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

  Widget _buildEocStatusCounters(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildCounterTile(
            theme,
            colorScheme,
            count: '3 Active',
            label: 'Critical Escalate',
            color: colorScheme.error,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildCounterTile(
            theme,
            colorScheme,
            count: '8 Units',
            label: 'Deployed Units',
            color: AppColors.warning,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildCounterTile(
            theme,
            colorScheme,
            count: '94% Cap',
            label: 'Shelter Capacity',
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCounterTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String count,
    required String label,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalatedIncidentsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escalated Multi-Unit Incidents',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildEscalatedItem(
                context,
                theme,
                colorScheme,
                title: 'Buddy - Golden Retriever (High Risk Storm Drain)',
                location: 'Riverfront Park, North Trail',
                time: 'Lost 4h ago',
                status: 'EOC Escalated',
                statusColor: colorScheme.error,
              ),
              const Divider(height: 20),
              _buildEscalatedItem(
                context,
                theme,
                colorScheme,
                title: 'River Wildfire Sector Evacuation',
                location: 'Pine Ridge Zone B',
                time: 'Alert active 1h ago',
                status: 'Evacuation Alert',
                statusColor: AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEscalatedItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String location,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.warning, color: statusColor, size: 20),
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
                '$location • $time',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppButton(
          text: 'Manage Unit',
          onPressed: () => context.push('/rescue/operations'),
          height: 34,
        ),
      ],
    );
  }

  Widget _buildShelterCapacitySection(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Shelter Capacity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildShelterProgressRow(
                theme,
                colorScheme,
                name: 'Central Humane Rescue Hub',
                used: 42,
                total: 45,
                percentage: 0.93,
              ),
              const SizedBox(height: 12),
              _buildShelterProgressRow(
                theme,
                colorScheme,
                name: 'North County Temporary Evac Site',
                used: 18,
                total: 30,
                percentage: 0.60,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShelterProgressRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String name,
    required int used,
    required int total,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '$used / $total Kennels',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppSpacing.vGapXs,
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: colorScheme.surfaceContainerHigh,
          color: percentage > 0.9 ? colorScheme.error : colorScheme.primary,
        ),
      ],
    );
  }
}
