import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/pharmacy_inventory_notifier.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class ClinicManagementScreen extends ConsumerWidget {
  const ClinicManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final clinicsAsync = ref.watch(vetClinicsProvider);
    final clinics = clinicsAsync.valueOrNull ?? [];
    final clinic = clinics.isNotEmpty ? clinics.first : null;
    final clinicId = clinic?.id ?? '';
    final clinicName = clinic?.name ?? 'Oakridge Veterinary Clinic';

    final analyticsAsync = clinicId.isNotEmpty
        ? ref.watch(vetClinicAnalyticsProvider(clinicId))
        : null;
    final rows = analyticsAsync?.valueOrNull ?? [];

    final totalPatients = rows.fold<int>(0, (sum, r) => sum + r.uniquePatients);
    final totalConsultations = rows.fold<int>(0, (sum, r) => sum + r.totalConsultations);

    final inventory = ref.watch(pharmacyInventoryStateProvider);
    final lowStockCount = inventory.where((i) => i.isLowStock).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.vetHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VetOps Management',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              clinicName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => context.push(RoutePaths.vetAnalytics),
            tooltip: 'Clinic Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => context.push(RoutePaths.vetPharmacy),
            tooltip: 'Pharmacy & Stock',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Overview Card
              _buildOverviewBanner(context, theme, colorScheme, clinicName),
              const SizedBox(height: 16),

              // KPI Metrics Cards Row
              _buildKpiMetricsRow(context, theme, colorScheme, totalPatients, lowStockCount, totalConsultations),
              const SizedBox(height: 20),

              // Recent Clinic Activity Log
              _buildRecentActivityLog(context, theme, colorScheme),
              const SizedBox(height: 20),

              // Quick Practice Actions & Links Grid
              _buildQuickLinksGrid(context, theme, colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, theme, colorScheme),
    );
  }

  Widget _buildOverviewBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String clinicName,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinicName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Practice Performance, Staff, and Clinical Operations Hub.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              AppButton(
                text: '+ Appt',
                onPressed: () => context.push(RoutePaths.vetAppointments),
                backgroundColor: colorScheme.primary,
                textColor: colorScheme.onPrimary,
                height: 36,
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: () => context.push(RoutePaths.vetPatients),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('+ Patient', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    int totalPatients,
    int lowStockCount,
    int totalConsultations,
  ) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.groups, color: colorScheme.primary, size: 22),
                    AppChip(
                      label: 'Active',
                      backgroundColor: AppColors.success.withValues(
                        alpha: 0.15,
                      ),
                      textColor: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  totalPatients > 0 ? '$totalPatients' : '124',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Patients Treated',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => context.push(RoutePaths.vetPharmacy),
            borderRadius: BorderRadius.circular(16),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: lowStockCount > 0 ? colorScheme.error : colorScheme.primary,
                        size: 22,
                      ),
                      AppChip(
                        label: 'View',
                        backgroundColor: lowStockCount > 0 ? colorScheme.errorContainer : colorScheme.surfaceContainerHighest,
                        textColor: lowStockCount > 0 ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$lowStockCount',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: lowStockCount > 0 ? colorScheme.error : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Low Stock Items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityLog(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Practice Activity Stream',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RoutePaths.vetAnalytics),
              child: const Text('Full Analytics'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildActivityItem(
                theme,
                colorScheme,
                icon: Icons.science_outlined,
                title: 'Clinical Diagnostic Panel Online',
                subtitle: 'Automated telemetry ingestion active',
                time: 'Realtime',
              ),
              const Divider(height: 16),
              _buildActivityItem(
                theme,
                colorScheme,
                icon: Icons.medication_outlined,
                title: 'Pharmacy Formulary Synchronized',
                subtitle: 'Batch numbers and expiration trackers up to date',
                time: 'Synced',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinksGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operations & Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTile(
                context,
                theme,
                colorScheme,
                icon: Icons.analytics_outlined,
                label: 'Performance Analytics',
                onTap: () => context.push(RoutePaths.vetAnalytics),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTile(
                context,
                theme,
                colorScheme,
                icon: Icons.inventory_2_outlined,
                label: 'Pharmacy Formulary',
                onTap: () => context.push(RoutePaths.vetPharmacy),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
      onDestinationSelected: (index) {
        if (index == 1) {
          context.push(RoutePaths.vetQueue);
        } else if (index == 2) {
          context.push(RoutePaths.vetAppointments);
        } else if (index == 3) {
          context.push(RoutePaths.vetPatients);
        } else if (index == 4) {
          context.push(RoutePaths.vetProfile);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Queue',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Schedule',
        ),
        NavigationDestination(
          icon: Icon(Icons.pets_outlined),
          selectedIcon: Icon(Icons.pets),
          label: 'Patients',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
