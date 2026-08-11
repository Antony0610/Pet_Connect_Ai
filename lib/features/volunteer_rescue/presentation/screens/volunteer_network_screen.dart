import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Volunteer Network Screen (Stitch ID: `01b3b0f7fa0b474f99f9e66465a85f42`).
///
/// Global distribution and operational team readiness dashboard. Displays active responder
/// stats, volunteer search & sector filters, and team roster cards.
class VolunteerNetworkScreen extends StatefulWidget {
  const VolunteerNetworkScreen({super.key});

  @override
  State<VolunteerNetworkScreen> createState() => _VolunteerNetworkScreenState();
}

class _VolunteerNetworkScreenState extends State<VolunteerNetworkScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _volunteers = [
    {
      'name': 'Sarah Jenkins',
      'role': 'Tier 3 Lead Responder',
      'sector': 'Sector 4 (North Ridge)',
      'status': 'On Duty',
      'statusColor': AppColors.success,
      'rescues': '128 Rescues',
      'skills': 'First Aid • K9 Handler',
    },
    {
      'name': 'Marcus Vance',
      'role': 'Tier 2 Responder',
      'sector': 'Sector 5 (Riverfront)',
      'status': 'In Transit',
      'statusColor': AppColors.warning,
      'rescues': '64 Rescues',
      'skills': 'Water Rescue • Transport',
    },
    {
      'name': 'Dr. Emily Watson',
      'role': 'Field Vet Consultant',
      'sector': 'Sector 4 (Mobile Unit)',
      'status': 'Available',
      'statusColor': AppColors.info,
      'rescues': '210 Rescues',
      'skills': 'Veterinary Triage • Surgery',
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
        title: const Text('Volunteer Network Roster'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rescue'),
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
                // ── Active Responder Stats Bar ──────────────────────
                _buildNetworkStatsRow(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Search & Sector Filter Input ────────────────────
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search volunteers by name, skill, or sector...',
                  prefixIcon: const Icon(Icons.search),
                ),

                AppSpacing.vGapLg,

                // ── Volunteer Roster Header ─────────────────────────
                Text(
                  'Active Sector Volunteers (1,248 Total)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),

                AppSpacing.vGapSm,

                // ── Volunteer Team Roster Cards ──────────────────────
                ..._volunteers.map(
                  (v) => _buildVolunteerCard(context, theme, colorScheme, v),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '1,248',
            label: 'Active Volunteers',
            icon: Icons.public,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '34 Units',
            label: 'Sectors Active',
            icon: Icons.hub_outlined,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '98.4%',
            label: 'Readiness Rate',
            icon: Icons.shield_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          AppSpacing.vGapXs,
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> v,
  ) {
    final statusColor = v['statusColor'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.person, color: colorScheme.primary, size: 24),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        v['name'] as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                  Text(
                    '${v['role']} • ${v['sector']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${v['rescues']} • Skills: ${v['skills']}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppChip(
                  label: v['status'] as String,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  textColor: statusColor,
                ),
                AppSpacing.vGapXs,
                IconButton(
                  icon: const Icon(Icons.chat_outlined, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Contacting ${v['name']}...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
