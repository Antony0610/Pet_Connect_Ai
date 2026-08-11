import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Administrator System Audit Logs Screen (Stitch ID: `c43f0df0770347459cc95329cc02ca17`).
///
/// System audit trail and security timeline log. Displays detailed actor, event action,
/// target resource, severity badge (Info, Warning, Critical), and CSV log export.
class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _logs = [
    {
      'time': '14:22:01 UTC',
      'actor': 'Admin (Sarah C.)',
      'action': 'USER_ROLE_UPDATED',
      'details': 'Updated Dr. Watson role to Senior Vet Examiner',
      'severity': 'INFO',
      'severityColor': AppColors.info,
    },
    {
      'time': '13:58:14 UTC',
      'actor': 'System Sentinel',
      'action': 'POST_AUTO_MODERATED',
      'details': 'Flagged duplicate sighting post from User #1048',
      'severity': 'WARNING',
      'severityColor': AppColors.warning,
    },
    {
      'time': '11:15:30 UTC',
      'actor': 'Admin (Alex R.)',
      'action': 'EMERGENCY_DISPATCH_OVERRIDE',
      'details': 'Manually reassigned Pine Ridge search mission',
      'severity': 'INFO',
      'severityColor': AppColors.info,
    },
    {
      'time': '09:04:12 UTC',
      'actor': 'Security Guard',
      'action': 'FAILED_LOGIN_SPIKE',
      'details':
          'Blocked 5 invalid authentication attempts from IP 192.168.1.104',
      'severity': 'CRITICAL',
      'severityColor': AppColors.lightError,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      body: SingleChildScrollView(
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
                  hintText:
                      'Filter log by actor, action type, or event keyword...',
                  prefixIcon: const Icon(Icons.search),
                ),

                AppSpacing.vGapLg,

                // ── Audit Log Roster List ────────────────────────────
                Text(
                  'Event Timeline Logs (24 Hours)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,

                ..._logs.map(
                  (log) => _buildAuditLogCard(theme, colorScheme, log),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLogCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> log,
  ) {
    final severityColor = log['severityColor'] as Color;

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
                        '${log['action']} • ${log['actor']}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Text(
                        log['details'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppChip(
                  label: log['severity'] as String,
                  backgroundColor: severityColor.withValues(alpha: 0.15),
                  textColor: severityColor,
                ),
              ],
            ),
            AppSpacing.vGapXs,
            Text(
              'Timestamp: ${log['time']}',
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
