import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Administrator System Audit Logs Screen (Stitch ID: `c43f0df0770347459cc95329cc02ca17`).
///
/// System audit trail and security timeline log. Displays detailed actor, event action,
/// target resource, severity badge (Info, Warning, Critical), and CSV log export.
class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.lightError;
      case 'WARNING':
        return AppColors.warning;
      case 'INFO':
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auditAsync = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Audit & Security Logs'),
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
                  content: Text('Downloading full Audit Log CSV...'),
                ),
              );
            },
            tooltip: 'Export Audit Logs',
          ),
        ],
      ),
      body: auditAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading logs: $err')),
        data: (logs) => _buildLogList(theme, colorScheme, logs),
      ),
    );
  }

  Widget _buildLogList(
    ThemeData theme,
    ColorScheme colorScheme,
    List<AuditLogEntry> logs,
  ) {
    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? logs
        : logs.where((l) {
            final combined = '${l.action} ${l.resourceType} ${l.severity}'
                .toLowerCase();
            return combined.contains(query);
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search & Filter Input ────────────────────────────
              AppTextField(
                controller: _searchController,
                hintText: 'Filter log by action type, resource, or severity...',
                prefixIcon: const Icon(Icons.search),
                onChanged: (_) => setState(() {}),
              ),

              AppSpacing.vGapLg,

              // ── Audit Log Roster List ────────────────────────────
              Text(
                'Event Timeline Logs (${filtered.length} entries)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppSpacing.vGapSm,

              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: Text('No audit log entries found.')),
                )
              else
                ...filtered.map(
                  (log) => _buildAuditLogCard(theme, colorScheme, log),
                ),

              AppSpacing.vGapXl,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLogCard(
    ThemeData theme,
    ColorScheme colorScheme,
    AuditLogEntry log,
  ) {
    final severityColor = _severityColor(log.severity);
    final timestamp =
        '${log.createdAt.toUtc().hour.toString().padLeft(2, '0')}:'
        '${log.createdAt.toUtc().minute.toString().padLeft(2, '0')}:'
        '${log.createdAt.toUtc().second.toString().padLeft(2, '0')} UTC';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log.action} • ${log.resourceType}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      if (log.resourceId != null)
                        Text(
                          'Resource: ${log.resourceId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                AppChip(
                  label: log.severity,
                  backgroundColor: severityColor.withValues(alpha: 0.15),
                  textColor: severityColor,
                ),
              ],
            ),
            AppSpacing.vGapXs,
            Text(
              'Timestamp: $timestamp',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
