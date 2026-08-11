import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Administrator User Management Screen (Stitch ID: `90f420782f0b4c42b1a4111777856fbd`,
/// Dark Reference: `76849ff817fc49f89f25233f3cc7c9ef`).
///
/// Central user directory and portal governance hub. Displays user role filters,
/// global user directory roster, active status chips, and account permission controls.
class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All';

  final List<Map<String, dynamic>> _users = [
    {
      'name': 'Sarah Connor',
      'email': 'sarah.c@example.com',
      'role': 'Pet Owner',
      'portal': 'Pet Owner Portal',
      'status': 'Active',
      'statusColor': AppColors.success,
      'joined': 'Jan 12, 2026',
    },
    {
      'name': 'Dr. Emily Watson',
      'email': 'dr.watson@petcarevet.com',
      'role': 'Veterinarian',
      'portal': 'Vet Portal',
      'status': 'Active',
      'statusColor': AppColors.success,
      'joined': 'Feb 04, 2026',
    },
    {
      'name': 'Alex Rivera',
      'email': 'alex.r@rescueops.org',
      'role': 'Rescue Lead',
      'portal': 'Volunteer Portal',
      'status': 'Active',
      'statusColor': AppColors.success,
      'joined': 'Mar 19, 2026',
    },
    {
      'name': 'Marcus Vance',
      'email': 'm.vance@flaggeduser.net',
      'role': 'Pet Owner',
      'portal': 'Pet Owner Portal',
      'status': 'Suspended',
      'statusColor': AppColors.lightError,
      'joined': 'Apr 01, 2026',
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
    final adminAccent = PortalPalette.accentFor(AppPortal.administrator);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: adminAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: adminAccent,
                size: 20,
              ),
            ),
            AppSpacing.hGapSm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PetConnect Admin',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  'User Management & Governance',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exporting user directory CSV...'),
                ),
              );
            },
            tooltip: 'Export Directory',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddUserDialog(context, theme, colorScheme),
            tooltip: 'New User',
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
                // ── Global User Stats Header ────────────────────────
                _buildUserStatsRow(theme, colorScheme, adminAccent),

                AppSpacing.vGapLg,

                // ── Search Bar & Role Filters ────────────────────────
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search by user name, email, or ID...',
                  prefixIcon: const Icon(Icons.search),
                ),

                AppSpacing.vGapMd,

                _buildRoleFilterChips(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Directory Header & User Roster Cards ─────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Global User Directory (45K Total)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      'Showing 4 accounts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                AppSpacing.vGapSm,

                ..._users.map(
                  (u) => _buildUserCard(context, theme, colorScheme, u),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, theme, colorScheme),
    );
  }

  Widget _buildUserStatsRow(
    ThemeData theme,
    ColorScheme colorScheme,
    Color adminAccent,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '45,210',
            label: 'Total Users',
            icon: Icons.group_outlined,
            color: adminAccent,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '1,204',
            label: 'Active Vets',
            icon: Icons.local_hospital_outlined,
            color: colorScheme.primary,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: '1,248',
            label: 'Rescuers',
            icon: Icons.shield_outlined,
            color: AppColors.success,
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
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
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

  Widget _buildRoleFilterChips(ThemeData theme, ColorScheme colorScheme) {
    final roles = ['All', 'Pet Owners', 'Veterinarians', 'Rescuers', 'Staff'];
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

  Widget _buildUserCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> u,
  ) {
    final statusColor = u['statusColor'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.person, color: colorScheme.primary),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        u['name'] as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${u['role']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${u['email']} • Joined ${u['joined']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppChip(
                  label: u['status'] as String,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  textColor: statusColor,
                ),
                AppSpacing.vGapXs,
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (action) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$action for ${u['name']}')),
                    );
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'Edit Role',
                      child: Text('Edit Role'),
                    ),
                    const PopupMenuItem(
                      value: 'Suspend Account',
                      child: Text('Suspend Account'),
                    ),
                    const PopupMenuItem(
                      value: 'Reset Password',
                      child: Text('Reset Password'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provision New User Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'John Doe',
              ),
            ),
            AppSpacing.vGapSm,
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'user@example.com',
              ),
            ),
            AppSpacing.vGapSm,
            DropdownButtonFormField<String>(
              initialValue: 'Pet Owner',
              decoration: const InputDecoration(labelText: 'Portal Role'),
              items: const [
                DropdownMenuItem(value: 'Pet Owner', child: Text('Pet Owner')),
                DropdownMenuItem(
                  value: 'Veterinarian',
                  child: Text('Veterinarian'),
                ),
                DropdownMenuItem(
                  value: 'Rescuer',
                  child: Text('Volunteer / Rescuer'),
                ),
                DropdownMenuItem(value: 'Admin', child: Text('Administrator')),
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
            text: 'Create Account',
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New user account provisioned!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (idx) {
        if (idx == 0) context.go('/admin');
        if (idx == 1) context.push('/admin/moderation');
        if (idx == 2) context.push('/admin/security');
        if (idx == 3) context.push('/admin/health');
        if (idx == 4) context.push('/admin/audit-logs');
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group),
          label: 'Users',
        ),
        NavigationDestination(
          icon: Icon(Icons.gavel_outlined),
          selectedIcon: Icon(Icons.gavel),
          label: 'Moderation',
        ),
        NavigationDestination(
          icon: Icon(Icons.security_outlined),
          selectedIcon: Icon(Icons.security),
          label: 'Security',
        ),
        NavigationDestination(
          icon: Icon(Icons.monitor_heart_outlined),
          selectedIcon: Icon(Icons.monitor_heart),
          label: 'Health',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Audit',
        ),
      ],
    );
  }
}
