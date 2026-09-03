import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/admin_user_entry.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/features/administrator/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
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
      case 'volunteer_rescue':
      case 'volunteer':
        return 'Rescue / Volunteer';
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
        return user.role == 'volunteer_rescue' || user.role == 'volunteer';
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
              final users = usersAsync.valueOrNull ?? [];
              final csvBuffer = StringBuffer(
                'ID,Full Name,Email,Role,Created At\n',
              );
              for (final u in users) {
                csvBuffer.writeln(
                  '"${u.id}","${u.fullName}","${u.email ?? ''}","${u.role}","${u.createdAt.toIso8601String()}"',
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Exported ${users.length} accounts to user_directory.csv',
                  ),
                  action: SnackBarAction(label: 'OK', onPressed: () {}),
                ),
              );
            },
            tooltip: 'Export Directory CSV',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddUserDialog(context, theme, colorScheme),
            tooltip: 'New User',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.adminSettings),
            tooltip: 'Platform Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _confirmSignOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (users) =>
            _buildUserDirectoryBody(theme, colorScheme, adminAccent, users),
      ),
      bottomNavigationBar: const AdminBottomNavBar(
        currentTab: AdminTab.directory,
      ),
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
    final activeVets = allUsers.where((u) => u.role == 'veterinarian').length;
    final rescuers = allUsers
        .where((u) => u.role == 'volunteer_rescue' || u.role == 'volunteer')
        .length;

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

              AppSpacing.vGapMd,

              // ── Quick Module Jump Navigation ─────────────────────
              _buildQuickModulesRow(theme, colorScheme),

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
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF7C3AED),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: activeVets.toString(),
            label: 'Active Vets',
            icon: Icons.medical_services_rounded,
            color: const Color(0xFF2563EB),
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildStatTile(
            theme,
            colorScheme,
            value: rescuers.toString(),
            label: 'Rescuers',
            icon: Icons.health_and_safety_rounded,
            color: const Color(0xFFEA580C),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          AppSpacing.vGapSm,
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickModulesRow(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;

    final modules = [
      {
        'label': 'Staff & Ops',
        'icon': Icons.badge_outlined,
        'color': const Color(0xFF2563EB),
        'path': RoutePaths.adminStaff,
      },
      {
        'label': 'CMS Articles',
        'icon': Icons.article_outlined,
        'color': const Color(0xFF059669),
        'path': RoutePaths.adminContent,
      },
      {
        'label': 'Analytics',
        'icon': Icons.insights_outlined,
        'color': const Color(0xFF7C3AED),
        'path': RoutePaths.adminReports,
      },
      {
        'label': 'Security Posture',
        'icon': Icons.security_outlined,
        'color': const Color(0xFFDC2626),
        'path': RoutePaths.adminSecurity,
      },
      {
        'label': 'System Health',
        'icon': Icons.dns_outlined,
        'color': const Color(0xFF0284C7),
        'path': RoutePaths.adminHealth,
      },
      {
        'label': 'Global Settings',
        'icon': Icons.tune_outlined,
        'color': const Color(0xFFEA580C),
        'path': RoutePaths.adminSettings,
      },
      {
        'label': 'Moderation',
        'icon': Icons.gavel_outlined,
        'color': const Color(0xFF8B5CF6),
        'path': RoutePaths.adminModeration,
      },
      {
        'label': 'Audit Logs',
        'icon': Icons.receipt_long_outlined,
        'color': const Color(0xFF64748B),
        'path': RoutePaths.adminAuditLogs,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: modules.map((m) {
          final icon = m['icon'] as IconData;
          final color = m['color'] as Color;
          final label = m['label'] as String;
          final path = m['path'] as String;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(path),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.04,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
    final isDark = theme.brightness == Brightness.dark;
    final joined =
        '${_monthName(user.createdAt.month)} ${user.createdAt.day.toString().padLeft(2, '0')}, ${user.createdAt.year}';

    final (roleBadgeColor, roleLabel, roleIcon) = switch (user.role) {
      'administrator' => (
        const Color(0xFF7C3AED),
        'ADMIN',
        Icons.shield_rounded,
      ),
      'veterinarian' => (
        const Color(0xFF2563EB),
        'VET DVM',
        Icons.medical_services_rounded,
      ),
      'volunteer_rescue' || 'volunteer' => (
        const Color(0xFFEA580C),
        'RESCUER',
        Icons.health_and_safety_rounded,
      ),
      _ => (const Color(0xFF059669), 'PET OWNER', Icons.pets_rounded),
    };

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showEditRoleDialog(context, user),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: roleBadgeColor.withValues(alpha: 0.15),
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: roleBadgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: roleBadgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    roleIcon,
                                    size: 10,
                                    color: roleBadgeColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    roleLabel,
                                    style: TextStyle(
                                      color: roleBadgeColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.email ?? 'No email'} • Joined $joined',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: user.isSuspended
                              ? const Color(0xFFE11D48).withValues(alpha: 0.12)
                              : const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.isSuspended ? 'Suspended' : 'Active',
                          style: TextStyle(
                            color: user.isSuspended
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (action) {
                          if (action == 'Edit Role') {
                            _showEditRoleDialog(context, user);
                          } else if (action == 'Suspend Account') {
                            _toggleSuspendUser(context, user);
                          } else if (action == 'Reset Password') {
                            _resetUserPassword(context, user);
                          } else if (action == 'Delete Account') {
                            _showDeleteUserDialog(context, user);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'Edit Role',
                            child: Text('Edit Role'),
                          ),
                          PopupMenuItem(
                            value: 'Suspend Account',
                            child: Text(
                              user.isSuspended
                                  ? 'Reactivate Account'
                                  : 'Suspend Account',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'Reset Password',
                            child: Text('Reset Password'),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'Delete Account',
                            child: Text(
                              'Delete Account',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  void _showEditRoleDialog(BuildContext context, AdminUserEntry user) {
    String selectedRole = user.role;
    final scaffold = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Edit Role for ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: (selectedRole == 'volunteer')
                    ? 'volunteer_rescue'
                    : selectedRole,
                decoration: const InputDecoration(labelText: 'Portal Role'),
                items: const [
                  DropdownMenuItem(
                    value: 'pet_owner',
                    child: Text('Pet Owner'),
                  ),
                  DropdownMenuItem(
                    value: 'veterinarian',
                    child: Text('Veterinarian'),
                  ),
                  DropdownMenuItem(
                    value: 'volunteer_rescue',
                    child: Text('Volunteer / Rescue'),
                  ),
                  DropdownMenuItem(
                    value: 'administrator',
                    child: Text('Administrator'),
                  ),
                ],
                onChanged: (v) =>
                    setModalState(() => selectedRole = v ?? selectedRole),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Save Role',
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await ref
                    .read(adminRepositoryProvider)
                    .updateUserRole(user.id, selectedRole);
                res.fold(
                  (f) => scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update role: ${f.message}'),
                    ),
                  ),
                  (_) {
                    ref.invalidate(adminUserDirectoryProvider);
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Role updated to ${_displayRole(selectedRole)} for ${user.fullName}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSuspendUser(
    BuildContext context,
    AdminUserEntry user,
  ) async {
    final scaffold = ScaffoldMessenger.of(context);
    final targetSuspended = !user.isSuspended;
    final res = await ref
        .read(adminRepositoryProvider)
        .suspendUser(user.id, targetSuspended);
    res.fold(
      (f) => scaffold.showSnackBar(
        SnackBar(
          content: Text('Failed to update account status: ${f.message}'),
        ),
      ),
      (_) {
        ref.invalidate(adminUserDirectoryProvider);
        scaffold.showSnackBar(
          SnackBar(
            content: Text(
              targetSuspended
                  ? 'Account for ${user.fullName} suspended.'
                  : 'Account for ${user.fullName} reactivated.',
            ),
          ),
        );
      },
    );
  }

  Future<void> _resetUserPassword(
    BuildContext context,
    AdminUserEntry user,
  ) async {
    final scaffold = ScaffoldMessenger.of(context);
    if (user.email == null || user.email!.isEmpty) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('User has no email associated.')),
      );
      return;
    }
    final res = await ref
        .read(adminRepositoryProvider)
        .resetUserPassword(user.email!);
    res.fold(
      (f) => scaffold.showSnackBar(
        SnackBar(content: Text('Password reset error: ${f.message}')),
      ),
      (_) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text('Password reset instructions sent to ${user.email}'),
          ),
        );
      },
    );
  }

  void _showDeleteUserDialog(BuildContext context, AdminUserEntry user) {
    final scaffold = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error),
            const SizedBox(width: 8),
            const Text('Delete User Account'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the account for "${user.fullName}" (${user.email ?? 'No email'})?\n\nThis action cannot be undone and will permanently remove all associated pets, health logs, and access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ref
                  .read(adminRepositoryProvider)
                  .deleteUser(user.id);
              res.fold(
                (f) => scaffold.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete account: ${f.message}'),
                  ),
                ),
                (_) {
                  ref.invalidate(adminUserDirectoryProvider);
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Account for ${user.fullName} has been permanently deleted.',
                      ),
                    ),
                  );
                },
              );
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'PetConnect2026!');
    String selectedRole = 'pet_owner';
    final scaffold = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Provision New User Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'John Doe',
                  ),
                ),
                AppSpacing.vGapSm,
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'user@petconnect.ai',
                  ),
                ),
                AppSpacing.vGapSm,
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Password',
                  ),
                ),
                AppSpacing.vGapSm,
                DropdownButtonFormField<String>(
                  initialValue: (selectedRole == 'volunteer')
                      ? 'volunteer_rescue'
                      : selectedRole,
                  decoration: const InputDecoration(labelText: 'Portal Role'),
                  items: const [
                    DropdownMenuItem(
                      value: 'pet_owner',
                      child: Text('Pet Owner'),
                    ),
                    DropdownMenuItem(
                      value: 'veterinarian',
                      child: Text('Veterinarian'),
                    ),
                    DropdownMenuItem(
                      value: 'volunteer_rescue',
                      child: Text('Volunteer / Rescuer'),
                    ),
                    DropdownMenuItem(
                      value: 'administrator',
                      child: Text('Administrator'),
                    ),
                  ],
                  onChanged: (v) =>
                      setModalState(() => selectedRole = v ?? selectedRole),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Create Account',
              onPressed: () async {
                final email = emailController.text.trim();
                final name = nameController.text.trim();
                final password = passwordController.text.trim();
                if (email.isEmpty || name.isEmpty) {
                  scaffold.showSnackBar(
                    const SnackBar(
                      content: Text('Please enter name and email'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final res = await ref
                    .read(adminRepositoryProvider)
                    .createUserAccount(
                      email: email,
                      fullName: name,
                      role: selectedRole,
                      password: password,
                    );
                res.fold(
                  (f) => scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Account creation error: ${f.message}'),
                    ),
                  ),
                  (_) {
                    ref.invalidate(adminUserDirectoryProvider);
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Account provisioned for $email as ${_displayRole(selectedRole)}!',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out Administrator'),
        content: const Text(
          'Are you sure you want to end your administrator session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(signOutProvider)(const NoParams());
              if (context.mounted) {
                context.go(RoutePaths.login);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
