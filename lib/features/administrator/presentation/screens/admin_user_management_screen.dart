import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/admin_user_entry.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// Administrator User Management Screen (Stitch ID: `90f420782f0b4c42b1a4111777856fbd`,
/// Dark Reference: `76849ff817fc49f89f25233f3cc7c9ef`).
///
/// Central user directory and portal governance hub. Displays user role filters,
/// global user directory roster, active status chips, and account permission controls.
class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends ConsumerState<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _displayRole(String role) {
    switch (role) {
      case 'administrator':
        return 'Administrator';
      case 'veterinarian':
        return 'Veterinarian';
      case 'volunteer':
        return 'Volunteer';
      case 'pet_owner':
      default:
        return 'Pet Owner';
    }
  }

  bool _matchesFilter(AdminUserEntry user) {
    if (_selectedRole == 'All') return true;
    switch (_selectedRole) {
      case 'Pet Owners':
        return user.role == 'pet_owner';
      case 'Veterinarians':
        return user.role == 'veterinarian';
      case 'Rescuers':
        return user.role == 'volunteer';
      case 'Staff':
        return user.role == 'administrator';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminAccent = PortalPalette.accentFor(AppPortal.administrator);
    final usersAsync = ref.watch(adminUserDirectoryProvider);

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
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (users) =>
            _buildUserDirectoryBody(theme, colorScheme, adminAccent, users),
      ),
      bottomNavigationBar: _buildBottomNav(context, theme, colorScheme),
    );
  }

  Widget _buildUserDirectoryBody(
    ThemeData theme,
    ColorScheme colorScheme,
    Color adminAccent,
    List<AdminUserEntry> allUsers,
  ) {
    final query = _searchController.text.toLowerCase();
    final filtered = allUsers.where((u) {
      if (!_matchesFilter(u)) return false;
      if (query.isEmpty) return true;
      final combined = '${u.fullName} ${u.email ?? ''} ${u.role}'.toLowerCase();
      return combined.contains(query);
    }).toList();

    // Compute live stats from actual data
    final totalUsers = allUsers.length;
    final activeVets =
        allUsers.where((u) => u.role == 'veterinarian').length;
    final rescuers = allUsers.where((u) => u.role == 'volunteer').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Global User Stats Header ────────────────────────
              _buildUserStatsRow(
                theme,
                colorScheme,
                adminAccent,
                totalUsers: totalUsers,
                activeVets: activeVets,
                rescuers: rescuers,
              ),

              AppSpacing.vGapLg,

              // ── Search Bar & Role Filters ────────────────────────
              AppTextField(
                controller: _searchController,
                hintText: 'Search by user name, email, or ID...',
                prefixIcon: const Icon(Icons.search),
                onChanged: (_) => setState(() {}),
              ),

              AppSpacing.vGapMd,

              _buildRoleFilterChips(theme, colorScheme),

              AppSpacing.vGapLg,

              // ── Directory Header & User Roster Cards ─────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Global User Directory ($totalUsers Total)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    'Showing ${filtered.length} accounts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              AppSpacing.vGapSm,

              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: Text('No users match the filter.')),
                )
              else
                ...filtered.map(
                  (u) => _buildUserCard(context, theme, colorScheme, u),
                ),

              AppSpacing.vGapXl,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserStatsRow(
    ThemeData theme,
    ColorScheme colorScheme,
    Color adminAccent, {
    required int totalUsers,
    required int activeVets,
    required int rescuers,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: totalUsers.toString(),
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
            value: activeVets.toString(),
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
            value: rescuers.toString(),
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
    AdminUserEntry user,
  ) {
    final joined =
        '${_monthName(user.createdAt.month)} ${user.createdAt.day.toString().padLeft(2, '0')}, ${user.createdAt.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Icon(Icons.person, color: colorScheme.primary)
                  : null,
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.fullName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${_displayRole(user.role)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${user.email ?? 'No email'} • Joined $joined',
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
                  label: 'Active',
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  textColor: AppColors.success,
                ),
                AppSpacing.vGapXs,
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (action) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$action for ${user.fullName}'),
                      ),
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

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
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
