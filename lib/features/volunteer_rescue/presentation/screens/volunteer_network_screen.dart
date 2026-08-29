import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_mission_status_notifier.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// **Volunteer Network Screen** — `/rescue/network`.
///
/// Global distribution and volunteer readiness dashboard.
/// Allows searching nearby volunteers by specialized skills, direct emergency
/// rescue broadcast pings, and live responder dispatching.
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

  final List<Map<String, dynamic>> _volunteers = [
    {
      'name': 'Sarah Jenkins',
      'role': 'Tier 3 Lead Responder',
      'sector': 'Sector 4 (North Ridge)',
      'distance': '0.4 km away',
      'status': 'On Duty',
      'rescues': '128 Rescues',
      'skills': 'First Aid • K9 Handler',
      'phone': '+1 (555) 789-0123',
    },
    {
      'name': 'Marcus Vance',
      'role': 'Tier 2 Responder',
      'sector': 'Sector 5 (Riverfront)',
      'distance': '1.2 km away',
      'status': 'In Transit',
      'rescues': '64 Rescues',
      'skills': 'Water Rescue • Transport',
      'phone': '+1 (555) 890-2345',
    },
    {
      'name': 'Dr. Emily Watson',
      'role': 'Field Vet Consultant',
      'sector': 'Sector 4 (Mobile Unit)',
      'distance': '2.1 km away',
      'status': 'Available',
      'rescues': '210 Rescues',
      'skills': 'Veterinary Triage • First Aid',
      'phone': '+1 (555) 901-3456',
    },
    {
      'name': 'David Kim',
      'role': 'K9 Tracker & Foster',
      'sector': 'Sector 2 (East Lake)',
      'distance': '3.5 km away',
      'status': 'Available',
      'rescues': '45 Rescues',
      'skills': 'K9 Handler • Transport',
      'phone': '+1 (555) 012-4567',
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
    final query = _searchController.text.toLowerCase();

    final filtered = _volunteers.where((v) {
      final matchesQuery = query.isEmpty ||
          v['name'].toString().toLowerCase().contains(query) ||
          v['sector'].toString().toLowerCase().contains(query) ||
          v['skills'].toString().toLowerCase().contains(query);

      final matchesSkill = _selectedSkill == 'All Skills' ||
          v['skills'].toString().contains(_selectedSkill);

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
              context.go('/rescue');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Broadcast Emergency Alert',
            onPressed: () => _showBroadcastAlertModal(context),
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
                _buildNetworkStatsRow(theme, colorScheme),
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
                      icon: const Icon(Icons.notifications_active_outlined, size: 16),
                      label: const Text('Broadcast Ping'),
                      onPressed: () => _showBroadcastAlertModal(context),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,

                // ── Volunteer Cards ────────────────────────────────
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

  Widget _buildNetworkStatsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(child: _buildStatTile(theme, 'Active Responders', '42', Colors.green)),
        AppSpacing.hGapSm,
        Expanded(child: _buildStatTile(theme, 'Sector Coverage', '94%', colorScheme.primary)),
        AppSpacing.hGapSm,
        Expanded(child: _buildStatTile(theme, 'Avg Dispatch Time', '4.2m', Colors.orange)),
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
    Map<String, dynamic> v,
  ) {
    final nameStr = v['name'].toString();
    final roleStr = v['role'].toString();
    final phoneStr = v['phone'].toString();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  nameStr.isNotEmpty ? nameStr.substring(0, 1) : 'V',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameStr,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$roleStr • ${v['distance']}',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: AppRadius.brPill,
                ),
                child: Text(
                  v['status'].toString().toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            'Specialties: ${v['skills']}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              Expanded(
                child: AppButton.outlined(
                  label: 'Call Direct',
                  icon: Icons.phone,
                  onPressed: () => ExternalActions.callPhoneNumber(phoneStr),
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
                            name: nameStr,
                            role: roleStr,
                            distanceMeters: 600,
                            status: 'Dispatched',
                            isLead: false,
                            phone: phoneStr,
                          ),
                        );
                    context.showSnackbar('✓ Dispatched $nameStr to active rescue mission!');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBroadcastAlertModal(BuildContext context) {
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
              label: 'Broadcast to 42 Active Responders',
              icon: Icons.cell_tower_rounded,
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.of(ctx).pop();
                context.showSnackbar('📡 Emergency broadcast dispatched to 42 sector volunteers!');
              },
            ),
          ],
        ),
      ),
    );
  }
}
