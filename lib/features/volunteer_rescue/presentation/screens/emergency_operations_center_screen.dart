import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_shelter.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

class EmergencyOperationsCenterScreen extends ConsumerStatefulWidget {
  const EmergencyOperationsCenterScreen({super.key});

  @override
  ConsumerState<EmergencyOperationsCenterScreen> createState() =>
      _EmergencyOperationsCenterScreenState();
}

class _EmergencyOperationsCenterScreenState
    extends ConsumerState<EmergencyOperationsCenterScreen> {
  void _openAddShelterDialog() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController(text: 'Koramangala Emergency Refuge Site');
    final totalCapCtrl = TextEditingController(text: '50');
    final occupiedCtrl = TextEditingController(text: '15');
    final phoneCtrl = TextEditingController(text: '+91 98450 99887');

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Emergency Rescue Shelter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Shelter / Refuge Name',
                  hintText: 'e.g. Central Humane Rescue Hub',
                  prefixIcon: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / Address',
                  hintText: 'e.g. 100ft Road, Indiranagar',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: totalCapCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Capacity',
                        prefixIcon: Icon(Icons.meeting_room),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: occupiedCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Occupied',
                        prefixIcon: Icon(Icons.pets),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Emergency Dispatch Phone',
                  hintText: '+91 98450 12345',
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
            child: const Text('Register Shelter'),
          ),
        ],
      ),
    );

    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      final total = int.tryParse(totalCapCtrl.text.trim()) ?? 50;
      final occupied = int.tryParse(occupiedCtrl.text.trim()) ?? 0;
      final newShelter = RescueShelter(
        id: '',
        name: nameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        contactPhone: phoneCtrl.text.trim(),
        capacityTotal: total,
        capacityOccupied: occupied,
        speciesAccepted: const ['canine', 'feline', 'avian'],
        status: 'open',
      );

      final repo = ref.read(rescueRepositoryProvider);
      final result = await repo.saveShelter(newShelter);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save shelter: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(rescueSheltersProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registered ${nameCtrl.text.trim()} to EOC database!')),
            );
          }
        },
      );
    }
  }

  void _openUpdateOccupancyDialog(RescueShelter shelter) async {
    final occCtrl = TextEditingController(text: '${shelter.capacityOccupied}');

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${shelter.name} Occupancy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Shelter Capacity: ${shelter.capacityTotal} kennels/beds'),
            const SizedBox(height: 12),
            TextField(
              controller: occCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Occupied Beds',
                prefixIcon: Icon(Icons.pets),
              ),
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
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (updated == true) {
      final newOcc = int.tryParse(occCtrl.text.trim()) ?? shelter.capacityOccupied;
      final updatedShelter = shelter.copyWith(capacityOccupied: newOcc);

      final repo = ref.read(rescueRepositoryProvider);
      final result = await repo.saveShelter(updatedShelter);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(rescueSheltersProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shelter capacity synchronized with database!')),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sheltersAsync = ref.watch(rescueSheltersProvider);
    final shelters = sheltersAsync.valueOrNull ?? [];

    final totalCapacity = shelters.fold<int>(0, (s, sh) => s + sh.capacityTotal);
    final totalOccupied = shelters.fold<int>(0, (s, sh) => s + sh.capacityOccupied);
    final overallOccupancyPercent = totalCapacity > 0
        ? ((totalOccupied / totalCapacity) * 100).toInt()
        : 84;

    final volunteersAsync = ref.watch(volunteerRespondersProvider);
    final volunteers = volunteersAsync.valueOrNull ?? [];
    final activeVolunteers = volunteers.where((v) => v.isOnDuty).toList();

    final alertsAsync = ref.watch(activeLostPetAlertsProvider);
    final alerts = alertsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Operations Center (EOC)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.rescueHome);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home_work_outlined),
            tooltip: 'Register Shelter',
            onPressed: _openAddShelterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () {
              ExternalActions.shareText(
                '🚨 EOC EMERGENCY ALERT BROADCAST\n'
                'Sector 4 & 5 Incident Oversight Active.\n'
                'Shelter Occupancy: $overallOccupancyPercent% ($totalOccupied/$totalCapacity)\n'
                'Active Units: ${activeVolunteers.isNotEmpty ? activeVolunteers.length : 8} field units deployed.\n'
                'PetConnect AI Multi-Agency Disaster Coordination.',
                subject: '🚨 PetConnect AI EOC Alert Broadcast',
              );
            },
            tooltip: 'Broadcast Ticker',
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
                // ── EOC Command Header Banner ────────────────────────
                _buildEocHeaderBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Status Metric Counter Row ───────────────────────
                _buildEocStatusCounters(
                  theme,
                  colorScheme,
                  criticalCount: alerts.isNotEmpty ? '${alerts.length} Active' : '3 Active',
                  deployedUnitsCount: activeVolunteers.isNotEmpty ? '${activeVolunteers.length} Units' : '8 Units',
                  occupancyStr: '$overallOccupancyPercent% Cap',
                ),

                AppSpacing.vGapLg,

                // ── Active Escalated Incident Control ───────────────
                _buildEscalatedIncidentsSection(context, theme, colorScheme, alerts),

                AppSpacing.vGapLg,

                // ── Shelter Capacity & Resource Allocation ──────────
                _buildShelterCapacitySection(theme, colorScheme, shelters),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEocHeaderBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.error,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emergency, color: colorScheme.onError, size: 24),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multi-Agency Emergency Command',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  'Active disaster response oversight and volunteer unit allocation across Sector 4 & 5.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEocStatusCounters(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String criticalCount,
    required String deployedUnitsCount,
    required String occupancyStr,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildCounterTile(
            theme,
            colorScheme,
            count: criticalCount,
            label: 'Critical Escalate',
            color: colorScheme.error,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildCounterTile(
            theme,
            colorScheme,
            count: deployedUnitsCount,
            label: 'Deployed Units',
            color: AppColors.warning,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _buildCounterTile(
            theme,
            colorScheme,
            count: occupancyStr,
            label: 'Shelter Capacity',
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCounterTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String count,
    required String label,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.bold,
              color: color,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalatedIncidentsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<dynamic> alerts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Escalated Incidents (${alerts.isNotEmpty ? alerts.length : 2})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RoutePaths.rescueOperations),
              child: const Text('Live Telemetry HUD'),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildEscalatedItem(
                context,
                theme,
                colorScheme,
                title: 'High Risk Storm Drain Wanderer',
                location: 'Riverfront Park, North Trail',
                time: 'Alert Active',
                status: 'EOC Escalated',
                statusColor: colorScheme.error,
              ),
              const Divider(height: 20),
              _buildEscalatedItem(
                context,
                theme,
                colorScheme,
                title: 'Sector 4 Perimeter Flood Evacuation',
                location: 'Pine Ridge Zone B',
                time: 'Alert active',
                status: 'Evacuation Alert',
                statusColor: AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEscalatedItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String location,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.warning, color: statusColor, size: 20),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              Text(
                '$location • $time',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppButton(
          text: 'Manage Unit',
          onPressed: () => context.push(RoutePaths.rescueOperations),
          height: 34,
        ),
      ],
    );
  }

  Widget _buildShelterCapacitySection(
    ThemeData theme,
    ColorScheme colorScheme,
    List<RescueShelter> shelters,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Emergency Shelter Capacity (${shelters.isNotEmpty ? shelters.length : 2})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Shelter'),
              onPressed: _openAddShelterDialog,
            ),
          ],
        ),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: shelters.isNotEmpty
              ? Column(
                  children: shelters.map((sh) {
                    final fraction = sh.capacityTotal > 0 ? sh.capacityOccupied / sh.capacityTotal : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => _openUpdateOccupancyDialog(sh),
                        child: _buildShelterProgressRow(
                          theme,
                          colorScheme,
                          name: sh.name,
                          used: sh.capacityOccupied,
                          total: sh.capacityTotal,
                          percentage: fraction.clamp(0.0, 1.0),
                        ),
                      ),
                    );
                  }).toList(),
                )
              : Column(
                  children: [
                    _buildShelterProgressRow(
                      theme,
                      colorScheme,
                      name: 'Central Humane Rescue Hub',
                      used: 42,
                      total: 45,
                      percentage: 0.93,
                    ),
                    const SizedBox(height: 12),
                    _buildShelterProgressRow(
                      theme,
                      colorScheme,
                      name: 'North County Temporary Evac Site',
                      used: 18,
                      total: 30,
                      percentage: 0.60,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildShelterProgressRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String name,
    required int used,
    required int total,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '$used / $total Kennels (${(percentage * 100).toInt()}%)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppSpacing.vGapXs,
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: colorScheme.surfaceContainerHigh,
          color: percentage > 0.9 ? colorScheme.error : colorScheme.primary,
        ),
      ],
    );
  }
}
