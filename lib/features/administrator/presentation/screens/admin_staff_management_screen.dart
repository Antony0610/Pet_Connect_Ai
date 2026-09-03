import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/administrator/domain/entities/staff_member.dart';
import 'package:petconnect_ai/features/administrator/presentation/providers/admin_providers.dart';
import 'package:petconnect_ai/features/administrator/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class AdminStaffManagementScreen extends ConsumerStatefulWidget {
  const AdminStaffManagementScreen({super.key});

  @override
  ConsumerState<AdminStaffManagementScreen> createState() =>
      _AdminStaffManagementScreenState();
}

class _AdminStaffManagementScreenState
    extends ConsumerState<AdminStaffManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All';

  List<StaffMember> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveStaff();
  }

  Future<void> _loadLiveStaff() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final res = await client
          .from('profiles')
          .select('id, full_name, role, city, phone_number, created_at')
          .inFilter('role', ['veterinarian', 'volunteer_rescue', 'administrator'])
          .order('created_at', ascending: false);

      final list = (res as List).cast<Map<String, dynamic>>().map((row) {
        final role = row['role'] as String? ?? 'staff';
        final roleTitle = switch (role) {
          'veterinarian' => 'Doctor of Veterinary Medicine (DVM)',
          'volunteer_rescue' => 'Rescue Specialist & Field Ops',
          'administrator' => 'System Administrator & EOC Lead',
          _ => 'Clinical Staff',
        };
        final dept = switch (role) {
          'veterinarian' => 'Veterinary Clinical Practice',
          'volunteer_rescue' => 'Emergency Rescue Network',
          'administrator' => 'Operations & Security Command',
          _ => 'General Practice',
        };

        return StaffMember(
          id: row['id'] as String? ?? 'st',
          name: (row['full_name'] as String?)?.isNotEmpty == true
              ? (role == 'veterinarian' && !(row['full_name'] as String).startsWith('Dr.')
                  ? 'Dr. ${row['full_name']}'
                  : row['full_name'] as String)
              : 'Staff Member',
          title: roleTitle,
          department: dept,
          shift: 'Shift: Active Duty',
          status: 'Available',
          phone: row['phone_number'] as String? ?? '+91 98450 12345',
          email: '${(row['full_name'] as String? ?? "staff").toLowerCase().replaceAll(" ", ".")}@petconnect.ai',
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _staffList = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddStaffDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final titleCtrl = TextEditingController(text: 'DVM Specialist');
    final deptCtrl = TextEditingController(text: 'Emergency & Critical Care');
    final shiftCtrl = TextEditingController(text: 'Shift: 08:00 - 16:00');
    final phoneCtrl = TextEditingController(text: '+91 98450 44556');
    String status = 'Available';

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Onboard Operations Staff Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name & Suffix',
                    hintText: 'e.g. Dr. Jane Smith, DVM',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title / Credentials',
                    hintText: 'e.g. Lead Surgeon (DVM, DACVS)',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Department / Unit',
                    hintText: 'e.g. Surgery & Critical Care',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shiftCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shift Schedule',
                    hintText: 'e.g. Today: 08:00 - 16:00',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Direct Phone',
                    hintText: '+91 98450 12345',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Current Availability Status',
                    prefixIcon: Icon(Icons.toggle_on),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(value: 'On Call', child: Text('On Call')),
                    DropdownMenuItem(
                      value: 'Off Shift',
                      child: Text('Off Shift'),
                    ),
                  ],
                  onChanged: (val) =>
                      setDlgState(() => status = val ?? 'Available'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Staff Member'),
            ),
          ],
        ),
      ),
    );

    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      final newMember = StaffMember(
        id: '',
        name: nameCtrl.text.trim(),
        title: titleCtrl.text.trim(),
        department: deptCtrl.text.trim(),
        shift: shiftCtrl.text.trim(),
        status: status,
        phone: phoneCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      final repo = ref.read(adminRepositoryProvider);
      final result = await repo.saveStaffMember(newMember);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to save staff member: ${failure.message}',
                ),
              ),
            );
          }
        },
        (_) {
          ref.invalidate(adminStaffMembersProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Staff member ${nameCtrl.text.trim()} onboarded!',
                ),
              ),
            );
          }
        },
      );
    }
  }

  void _manageShift(StaffMember member) async {
    String currentStatus = member.status;
    final shiftCtrl = TextEditingController(text: member.shift);

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Manage Shift: ${member.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: shiftCtrl,
                decoration: const InputDecoration(labelText: 'Shift Schedule'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: currentStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(
                    value: 'Available',
                    child: Text('Available'),
                  ),
                  DropdownMenuItem(value: 'On Call', child: Text('On Call')),
                  DropdownMenuItem(
                    value: 'Off Shift',
                    child: Text('Off Shift'),
                  ),
                ],
                onChanged: (val) =>
                    setDlgState(() => currentStatus = val ?? 'Available'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update Shift'),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      final updatedMember = member.copyWith(
        shift: shiftCtrl.text.trim(),
        status: currentStatus,
      );
      final repo = ref.read(adminRepositoryProvider);
      await repo.saveStaffMember(updatedMember);
      ref.invalidate(adminStaffMembersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shift updated for ${member.name}!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final staffAsync = ref.watch(adminStaffMembersProvider);
    final List<StaffMember> staffList =
        (staffAsync.valueOrNull != null && staffAsync.valueOrNull!.isNotEmpty)
            ? staffAsync.valueOrNull!
            : _staffList;

    final query = _searchController.text.toLowerCase();

    final List<StaffMember> filtered = staffList.where((StaffMember member) {
      final matchesQuery =
          query.isEmpty ||
          member.name.toLowerCase().contains(query) ||
          member.title.toLowerCase().contains(query) ||
          member.department.toLowerCase().contains(query);

      final matchesRole =
          _selectedRole == 'All' ||
          (_selectedRole == 'DVM Vets' && member.title.contains('DVM')) ||
          (_selectedRole == 'Surgeons' && member.title.contains('Surgeon')) ||
          (_selectedRole == 'Dispatch Leads' &&
              member.title.contains('Dispatch')) ||
          (_selectedRole == 'Support' &&
              !member.title.contains('DVM') &&
              !member.title.contains('Surgeon'));

      return matchesQuery && matchesRole;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('VetOps & Administrative Staff'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddStaffDialog(context),
            tooltip: 'Add Staff Member',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminStaffMembersProvider),
            tooltip: 'Refresh Roster',
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
                  onChanged: (_) => setState(() {}),
                ),

                AppSpacing.vGapMd,

                _buildRoleFilterChips(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Staff Roster List Header ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Staff Roster (${filtered.length} Personnel)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Staff'),
                      onPressed: () => _showAddStaffDialog(context),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,

                if (filtered.isEmpty && (staffAsync.isLoading || _isLoading))
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filtered.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No staff members found matching query.',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (StaffMember member) =>
                        _buildStaffCard(context, theme, colorScheme, member),
                  ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentTab: AdminTab.staff),
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
    StaffMember member,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    final (statusColor, statusBg) = switch (member.status) {
      'Available' => (
        const Color(0xFF059669),
        const Color(0xFF059669).withValues(alpha: 0.12),
      ),
      'On Call' => (
        const Color(0xFFD97706),
        const Color(0xFFD97706).withValues(alpha: 0.12),
      ),
      _ => (
        const Color(0xFF64748B),
        const Color(0xFF64748B).withValues(alpha: 0.12),
      ),
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
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.badge_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${member.title} • ${member.department}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.shift,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      member.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (member.phone != null && member.phone!.isNotEmpty) ...[
                        IconButton.filledTonal(
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          tooltip: 'Call Staff',
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                          ),
                          onPressed: () =>
                              ExternalActions.callPhoneNumber(member.phone!),
                        ),
                        const SizedBox(width: 6),
                      ],
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                        label: const Text(
                          'Shift',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: () => _manageShift(member),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
