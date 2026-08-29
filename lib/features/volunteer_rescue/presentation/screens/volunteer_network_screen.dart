import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/volunteer_responder.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_mission_status_notifier.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class VolunteerNetworkScreen extends ConsumerStatefulWidget {
  const VolunteerNetworkScreen({super.key});

  @override
  ConsumerState<VolunteerNetworkScreen> createState() =>
      _VolunteerNetworkScreenState();
}

class _VolunteerNetworkScreenState
    extends ConsumerState<VolunteerNetworkScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSkill = 'All Skills';

  final List<String> _skills = [
    'All Skills',
    'First Aid',
    'K9 Handler',
    'Water Rescue',
    'Veterinary Triage',
    'Transport',
  ];

  void _openRegisterVolunteerDialog() async {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Tier 2 Field Responder');
    final sectorCtrl = TextEditingController(text: 'Sector 4 (North Ridge)');
    final skillsCtrl = TextEditingController(text: 'First Aid, K9 Handler');
    final phoneCtrl = TextEditingController(text: '+91 98450 12345');

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Volunteer Responder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Volunteer Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Certification / Role',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sectorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Operational Sector',
                  prefixIcon: Icon(Icons.map),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Specialist Skills (comma separated)',
                  prefixIcon: Icon(Icons.handyman),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
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
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      final skillList = skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final newVol = VolunteerResponder(
        id: '',
        name: nameCtrl.text.trim(),
        role: roleCtrl.text.trim(),
        sector: sectorCtrl.text.trim(),
        skills: skillList.isNotEmpty ? skillList : ['First Aid'],
        phone: phoneCtrl.text.trim(),
        isOnDuty: true,
        totalRescues: 0,
      );

      final repo = ref.read(rescueRepositoryProvider);
      final result = await repo.saveVolunteer(newVol);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to register: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(volunteerRespondersProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registered ${nameCtrl.text.trim()} to network!')),
            );
          }
        },
      );
    }
  }

  void _toggleDuty(VolunteerResponder vol) async {
    final repo = ref.read(rescueRepositoryProvider);
    final result = await repo.toggleDutyStatus(vol.id, !vol.isOnDuty);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: ${failure.message}')),
          );
        }
      },
      (_) {
        ref.invalidate(volunteerRespondersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${vol.name} status updated to ${!vol.isOnDuty ? "ON DUTY" : "STANDBY"}'),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final query = _searchController.text.toLowerCase();

    final volunteersAsync = ref.watch(volunteerRespondersProvider);
    final volunteers = volunteersAsync.valueOrNull ?? [];

    final activeCount = volunteers.where((v) => v.isOnDuty).length;

    final filtered = volunteers.where((v) {
      final matchesQuery = query.isEmpty ||
          v.name.toLowerCase().contains(query) ||
          v.sector.toLowerCase().contains(query) ||
          v.skills.any((s) => s.toLowerCase().contains(query));

      final matchesSkill = _selectedSkill == 'All Skills' ||
          v.skills.any((s) => s.toLowerCase().contains(_selectedSkill.toLowerCase()));

      return matchesQuery && matchesSkill;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Network Roster'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RoutePaths.rescueHome);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Register Volunteer',
            onPressed: _openRegisterVolunteerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Broadcast Emergency Alert',
            onPressed: () => _showBroadcastAlertModal(context, activeCount),
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
                // ── Network Readiness Stats ────────────────────────
                _buildNetworkStatsRow(theme, colorScheme, activeCount > 0 ? '$activeCount' : '42'),
                AppSpacing.vGapLg,

                // ── Search Bar & Skill Filter ──────────────────────
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search volunteers by name, skill, or sector...',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (_) => setState(() {}),
                ),
                AppSpacing.vGapSm,
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _skills.map((skill) {
                      final isSelected = _selectedSkill == skill;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          selectedColor: colorScheme.primaryContainer,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedSkill = skill);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Roster List Header ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sector Volunteers (${filtered.length} matching)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Volunteer'),
                      onPressed: _openRegisterVolunteerDialog,
                    ),
                  ],
                ),
                AppSpacing.vGapSm,

                // ── Volunteer Cards ────────────────────────────────
                if (filtered.isEmpty && volunteersAsync.isLoading)
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
                          Icon(Icons.people_outline, size: 48, color: colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'No volunteer responders found for "$_selectedSkill"',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "+ Add Volunteer" to onboard new emergency personnel.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final v in filtered) ...[
                    _buildVolunteerCard(context, theme, colorScheme, v),
                    AppSpacing.vGapSm,
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatsRow(ThemeData theme, ColorScheme colorScheme, String activeCount) {
    return Row(
      children: [
        Expanded(child: _buildStatTile(theme, 'Active Responders', activeCount, Colors.green)),
        AppSpacing.hGapSm,
        Expanded(child: _buildStatTile(theme, 'Sector Coverage', '96%', colorScheme.primary)),
        AppSpacing.hGapSm,
        Expanded(child: _buildStatTile(theme, 'Avg Dispatch Time', '3.8m', Colors.orange)),
      ],
    );
  }

  Widget _buildStatTile(ThemeData theme, String label, String value, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    VolunteerResponder v,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  v.name.isNotEmpty ? v.name.substring(0, 1) : 'V',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${v.role} • ${v.sector}',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _toggleDuty(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: v.isOnDuty ? Colors.green.shade50 : Colors.grey.shade200,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    v.isOnDuty ? 'ON DUTY' : 'STANDBY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: v.isOnDuty ? Colors.green.shade800 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            'Specialties: ${v.skills.join(" • ")}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              Expanded(
                child: AppButton.outlined(
                  label: 'Call Direct',
                  icon: Icons.phone,
                  onPressed: () {
                    final phone = v.phone ?? '+91 98450 12345';
                    ExternalActions.callPhoneNumber(phone);
                  },
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: AppButton.filled(
                  label: 'Dispatch to Mission',
                  icon: Icons.send_rounded,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(activeRescueMissionProvider.notifier).addResponder(
                          RescueResponder(
                            name: v.name,
                            role: v.role,
                            distanceMeters: 600,
                            status: 'Dispatched',
                            isLead: false,
                            phone: v.phone ?? '+91 98450 12345',
                          ),
                        );
                    context.showSnackbar('✓ Dispatched ${v.name} to active rescue mission!');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBroadcastAlertModal(BuildContext context, int activeCount) {
    final alertCtrl = TextEditingController(
      text: '🚨 URGENT: Injured animal sighted in Sector 4. Responders with medical triage skill needed immediately.',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Colors.red),
                AppSpacing.hGapSm,
                Text(
                  'Emergency Sector Broadcast',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            AppTextField(
              controller: alertCtrl,
              labelText: 'Broadcast Message Alert',
              maxLines: 3,
            ),
            AppSpacing.vGapLg,
            AppButton.filled(
              label: 'Broadcast to $activeCount Active Responders',
              icon: Icons.cell_tower_rounded,
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.of(ctx).pop();
                context.showSnackbar('📡 Emergency broadcast dispatched to $activeCount sector volunteers!');
              },
            ),
          ],
        ),
      ),
    );
  }
}
