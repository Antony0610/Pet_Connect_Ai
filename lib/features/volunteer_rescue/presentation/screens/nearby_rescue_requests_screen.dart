import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/rescue_mission.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class NearbyRescueRequestsScreen extends ConsumerStatefulWidget {
  const NearbyRescueRequestsScreen({super.key});

  @override
  ConsumerState<NearbyRescueRequestsScreen> createState() =>
      _NearbyRescueRequestsScreenState();
}

class _NearbyRescueRequestsScreenState
    extends ConsumerState<NearbyRescueRequestsScreen> {
  String _selectedFilter = 'All';
  final double _deviceLat = 12.9716; // User coordinate baseline (Bengaluru Central)
  final double _deviceLng = 77.5946;

  void _openCreateAlertDialog() async {
    final petNameCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final locCtrl = TextEditingController(text: 'Indiranagar 100ft Rd');
    final descCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 98450 12345');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast Emergency Lost Pet Alert'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: petNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pet Name',
                  hintText: 'e.g. Bella',
                  prefixIcon: Icon(Icons.pets),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: breedCtrl,
                decoration: const InputDecoration(
                  labelText: 'Breed / Species',
                  hintText: 'e.g. Golden Retriever / Canine',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last Seen Location',
                  hintText: 'e.g. Koramangala 4th Block',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Distinct Features & Circumstances',
                  hintText: 'e.g. Red collar with brass tag, frightened by fireworks.',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number',
                  hintText: '+91 98765 43210',
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
            child: const Text('Broadcast Alert'),
          ),
        ],
      ),
    );

    if (created == true && petNameCtrl.text.trim().isNotEmpty) {
      final now = DateTime.now();
      final newAlert = LostPetAlert(
        id: '',
        petId: '',
        ownerId: '',
        alertStatus: 'ACTIVE',
        lastSeenLocation: locCtrl.text.trim(),
        latitude: _deviceLat + (0.005 * (now.millisecond % 5)),
        longitude: _deviceLng + (0.005 * (now.millisecond % 4)),
        lastSeenTime: now,
        description: '${petNameCtrl.text.trim()} (${breedCtrl.text.trim()}): ${descCtrl.text.trim()}',
        contactPhone: phoneCtrl.text.trim(),
        rewardAmount: '500',
        createdAt: now,
        updatedAt: now,
      );

      final repo = ref.read(rescueRepositoryProvider);
      final result = await repo.createLostPetAlert(newAlert);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to broadcast alert: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(activeLostPetAlertsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Emergency alert broadcast for ${petNameCtrl.text.trim()}!')),
            );
          }
        },
      );
    }
  }

  void _acceptMission(LostPetAlert alert) async {
    final now = DateTime.now();
    final title = (alert.description != null && alert.description!.isNotEmpty)
        ? alert.description!.split(':').first
        : 'Rescue Target';

    final newMission = RescueMission(
      id: '',
      alertId: alert.id,
      leadVolunteerId: '',
      missionTitle: 'Rescue: $title',
      priority: 'HIGH',
      status: 'in_progress',
      searchRadiusMeters: 2500,
      notes: 'Dispatched to ${alert.lastSeenLocation}. Initial responder on route.',
      startedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final repo = ref.read(rescueRepositoryProvider);
    final result = await repo.createRescueMission(newMission);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to accept mission: ${failure.message}')),
          );
        }
      },
      (mission) {
        ref.invalidate(rescueMissionsProvider(null));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mission accepted for $title!')),
          );
          context.push(RoutePaths.rescueOperations);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final alertsAsync = ref.watch(activeLostPetAlertsProvider);
    final alerts = alertsAsync.valueOrNull ?? [];

    // Filter alerts
    final filteredAlerts = alerts.where((alert) {
      final desc = alert.description?.toLowerCase() ?? '';
      if (_selectedFilter == 'Critical') {
        return desc.contains('critical') || alert.alertStatus == 'ACTIVE';
      }
      if (_selectedFilter == 'Urgent') {
        return desc.contains('urgent');
      }
      if (_selectedFilter == 'Within 2km') {
        final dist = calculateDistanceKm(_deviceLat, _deviceLng, alert.latitude, alert.longitude);
        return dist <= 2.0;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Rescue Requests'),
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
            icon: const Icon(Icons.add_alert_outlined),
            tooltip: 'Broadcast Alert',
            onPressed: _openCreateAlertDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeLostPetAlertsProvider),
            tooltip: 'Refresh Requests',
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
                // ── Urgency Filter Bar ──────────────────────────────
                _buildFilterChips(theme, colorScheme),

                AppSpacing.vGapMd,

                // ── Requests Header & Sort Indicator ────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredAlerts.length} Active Nearby Requests',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      'Realtime GPS Radius',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                AppSpacing.vGapSm,

                // ── Emergency Pet Request Cards ─────────────────────
                if (filteredAlerts.isEmpty && alertsAsync.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filteredAlerts.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'No active rescue alerts in this sector.',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All reported animals are currently safe or dispatched.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredAlerts.map(
                    (alert) => _buildAlertCard(context, theme, colorScheme, alert),
                  ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, ColorScheme colorScheme) {
    final filters = ['All', 'Within 2km', 'Critical', 'Urgent'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: f,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedFilter = f),
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

  Widget _buildAlertCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    LostPetAlert alert,
  ) {
    final distKm = calculateDistanceKm(_deviceLat, _deviceLng, alert.latitude, alert.longitude);
    final title = (alert.description != null && alert.description!.isNotEmpty)
        ? alert.description!.split(':').first
        : 'Lost Pet Alert';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.pets, color: colorScheme.primary),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distKm.toStringAsFixed(1)} km away • ${alert.lastSeenLocation}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppChip(
                  label: alert.alertStatus,
                  backgroundColor: alert.alertStatus == 'ACTIVE'
                      ? colorScheme.error.withValues(alpha: 0.15)
                      : colorScheme.primary.withValues(alpha: 0.15),
                  textColor: alert.alertStatus == 'ACTIVE'
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              ],
            ),
            AppSpacing.vGapMd,
            Text(
              alert.description ?? 'No additional incident notes provided.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (alert.contactPhone != null && alert.contactPhone!.isNotEmpty) ...[
              AppSpacing.vGapSm,
              Text(
                'Contact: ${alert.contactPhone}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            AppSpacing.vGapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (alert.rewardAmount != null && alert.rewardAmount!.isNotEmpty)
                  AppChip(
                    label: 'Reward: \$${alert.rewardAmount}',
                    backgroundColor: AppColors.success.withValues(alpha: 0.15),
                    textColor: AppColors.success,
                  )
                else
                  AppChip(
                    label: 'GPS Tagged',
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    textColor: colorScheme.onSurfaceVariant,
                  ),
                AppButton(
                  text: 'Accept Mission',
                  icon: Icons.check_circle_outline,
                  onPressed: () => _acceptMission(alert),
                  height: 36,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
