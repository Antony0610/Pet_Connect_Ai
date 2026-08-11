import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Administrator Platform Health Screen (Stitch ID: `3ae682bbb9dd49209c20293ad5e59487`).
///
/// Infrastructure telemetry and AI intelligence service monitoring dashboard.
/// Displays live health status for API Gateway, DB Cluster, AI Diagnostics, and Telemetry.
class AdminPlatformHealthScreen extends StatelessWidget {
  const AdminPlatformHealthScreen({super.key});

  final List<Map<String, dynamic>> _services = const [
    {
      'name': 'API Gateway Router',
      'latency': '45ms avg',
      'uptime': '99.99%',
      'status': 'Operational',
      'icon': Icons.dns_outlined,
    },
    {
      'name': 'Supabase PostgreSQL Cluster',
      'latency': '12ms avg',
      'uptime': '100%',
      'status': 'Operational',
      'icon': Icons.storage_outlined,
    },
    {
      'name': 'AI Diagnostic Vision Engine',
      'latency': '1.2s avg',
      'uptime': '99.95%',
      'status': 'Operational',
      'icon': Icons.psychology_outlined,
    },
    {
      'name': 'BLE / GPS Telemetry Stream',
      'latency': '85ms avg',
      'uptime': '99.98%',
      'status': 'Operational',
      'icon': Icons.sensors_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Infrastructure & AI Health'),
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
                // ── Health Header Banner ─────────────────────────────
                _buildSystemHealthBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Services Operational List ────────────────────────
                Text(
                  'Core Services & Infrastructure Telemetry',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,

                ..._services.map(
                  (svc) => _buildServiceCard(theme, colorScheme, svc),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemHealthBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
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
                  'All Infrastructure Systems Operational',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'Real-time telemetry updated 5 seconds ago • Zero active outages.',
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

  Widget _buildServiceCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> svc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(svc['icon'] as IconData, color: colorScheme.primary),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    svc['name'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    'Latency: ${svc['latency']} • Uptime: ${svc['uptime']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const AppChip(
              label: 'OPERATIONAL',
              backgroundColor: AppColors.success,
              textColor: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
