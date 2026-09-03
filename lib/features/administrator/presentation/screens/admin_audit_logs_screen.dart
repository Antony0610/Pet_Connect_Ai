import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/audit_log_entry.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
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

  void _exportAuditCsv(List<AuditLogEntry> logs) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,TIMESTAMP,ACTION,RESOURCE_TYPE,SEVERITY,ACTOR_ID,RESOURCE_ID',
    );
    for (final l in logs) {
      buffer.writeln(
        '${l.id},${l.createdAt.toIso8601String()},${l.action},${l.resourceType},${l.severity},${l.actorId},${l.resourceId ?? ""}',
      );
    }

    ExternalActions.shareText(
      buffer.toString(),
      subject:
          'PetConnect AI System Audit Log Export (${DateTime.now().toIso8601String()})',
    );
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final logs = auditAsync.valueOrNull ?? [];
              _exportAuditCsv(logs);
            },
            tooltip: 'Export Audit Logs (CSV)',
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
    final isDark = theme.brightness == Brightness.dark;

    final (sevColor, sevBg, sevIcon) = switch (log.severity.toUpperCase()) {
      'CRITICAL' => (
        const Color(0xFFE11D48),
        const Color(0xFFE11D48).withValues(alpha: 0.12),
        Icons.error_outline_rounded,
      ),
      'WARNING' => (
        const Color(0xFFD97706),
        const Color(0xFFD97706).withValues(alpha: 0.12),
        Icons.warning_amber_rounded,
      ),
      _ => (
        const Color(0xFF2563EB),
        const Color(0xFF2563EB).withValues(alpha: 0.12),
        Icons.info_outline_rounded,
      ),
    };

    final ist = log.createdAt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final timestamp =
        '${ist.hour.toString().padLeft(2, '0')}:'
        '${ist.minute.toString().padLeft(2, '0')}:'
        '${ist.second.toString().padLeft(2, '0')} IST';

    final dateStr =
        '${ist.year}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: sevBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(sevIcon, color: sevColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          log.action,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.resourceType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (log.resourceId != null &&
                        log.resourceId!.isNotEmpty) ...[
                      Text(
                        'Resource ID: ${log.resourceId}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      '$dateStr • $timestamp',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sevBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.severity.toUpperCase(),
                  style: TextStyle(
                    color: sevColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
