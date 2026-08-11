import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Administrator Staff Management Screen (Stitch ID: `81818ce77fcd4db4874895ddf4938ae7`).
///
/// Staff roster, veterinary operations personnel, and dispatch staff management.
/// Displays shift availability status, qualifications, role credentials, and staff actions.
class AdminStaffManagementScreen extends StatefulWidget {
  const AdminStaffManagementScreen({super.key});

  @override
  State<AdminStaffManagementScreen> createState() =>
      _AdminStaffManagementScreenState();
}

class _AdminStaffManagementScreenState
    extends State<AdminStaffManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All';

  final List<Map<String, dynamic>> _staff = [
    {
      'name': 'Dr. Emily Chen',
      'title': 'Doctor of Veterinary Medicine (DVM)',
      'department': 'General Practice & Surgery',
      'shift': 'Today\'s Shift: 08:00 - 16:00',
      'status': 'Available',
      'statusColor': AppColors.success,
    },
    {
      'name': 'Dr. Marcus Vance',
      'title': 'Veterinary Surgeon (DVM, DACVS)',
      'department': 'Emergency Surgery & Orthopedics',
      'shift': 'Today\'s Shift: On Call',
      'status': 'On Call',
      'statusColor': AppColors.warning,
    },
    {
      'name': 'Sarah Jenkins',
      'title': 'Senior Dispatch Officer',
      'department': 'Emergency Operations Center',
      'shift': 'Today\'s Shift: 16:00 - 00:00',
      'status': 'Off Shift',
      'statusColor': AppColors.info,
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
        title: const Text('VetOps & Administrative Staff'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddStaffDialog(context, theme, colorScheme),
            tooltip: 'Add Staff Member',
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
                // ── Search & Role Filters ────────────────────────────
                AppTextField(
                  controller: _searchController,
                  hintText:
                      'Search staff by name, credential, or department...',
                  prefixIcon: const Icon(Icons.search),
                ),

                AppSpacing.vGapMd,

                _buildRoleFilterChips(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Staff Roster List Header ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Staff Roster (48 Personnel)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Staff'),
                      onPressed: () =>
                          _showAddStaffDialog(context, theme, colorScheme),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,

                ..._staff.map(
                  (member) =>
                      _buildStaffCard(context, theme, colorScheme, member),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleFilterChips(ThemeData theme, ColorScheme colorScheme) {
    final roles = ['All', 'DVM Vets', 'Surgeons', 'Dispatch Leads', 'Support'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: roles.map((r) {
          final isSelected = _selectedRole == r;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: r,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedRole = r),
              backgroundColor: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              textColor: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStaffCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> member,
  ) {
    final statusColor = member['statusColor'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.badge_outlined, color: colorScheme.primary),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member['name'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    '${member['title']} • ${member['department']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    member['shift'] as String,
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
                  label: member['status'] as String,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  textColor: statusColor,
                ),
                AppSpacing.vGapXs,
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_calendar_outlined, size: 14),
                  label: const Text('Manage Shift'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Managing shift for ${member['name']}'),
                      ),
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

  void _showAddStaffDialog(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Staff Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Full Name & Title',
                hintText: 'Dr. Jane Smith, DVM',
              ),
            ),
            AppSpacing.vGapSm,
            const TextField(
              decoration: InputDecoration(
                labelText: 'Department / Role',
                hintText: 'Surgery & Critical Care',
              ),
            ),
            AppSpacing.vGapSm,
            DropdownButtonFormField<String>(
              initialValue: 'Available',
              decoration: const InputDecoration(
                labelText: 'Shift Availability',
              ),
              items: const [
                DropdownMenuItem(value: 'Available', child: Text('Available')),
                DropdownMenuItem(value: 'On Call', child: Text('On Call')),
                DropdownMenuItem(value: 'Off Shift', child: Text('Off Shift')),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Save Staff Member',
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Staff member added to roster!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
