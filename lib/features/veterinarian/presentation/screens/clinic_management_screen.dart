import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class ClinicManagementScreen extends StatelessWidget {
  const ClinicManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              'Clinic Performance & Practice Ops',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
              _buildOverviewBanner(context, theme, colorScheme),
              const SizedBox(height: 16),

              // KPI Metrics Cards Row
              _buildKpiMetricsRow(context, theme, colorScheme),
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
                  'Oakridge Veterinary Clinic',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Today\'s clinic performance at a glance.',
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
                onPressed: () =>
                    context.push(RoutePaths.vetAppointmentSchedule),
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
                      label: '+12%',
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      textColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '124',
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
                        color: colorScheme.error,
                        size: 22,
                      ),
                      AppChip(
                        label: 'View',
                        backgroundColor: colorScheme.errorContainer,
                        textColor: colorScheme.onErrorContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '4',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                  Text(
                    'Low Stock Alerts',
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
              'Recent Clinic Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('View Log')),
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
                title: 'Lab results available for Bella',
                subtitle: 'Dr. Smith • Blood Panel',
                time: '10m ago',
              ),
              const Divider(height: 16),
              _buildActivityItem(
                theme,
                colorScheme,
                icon: Icons.medical_services_outlined,
                title: 'Surgery prep completed for Charlie',
                subtitle: 'Tech. Johnson • Orthopedic',
                time: '1h ago',
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
                style: theme.textTheme.labelSmall?.copyWith(
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
          'Quick Practice Operations',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOperationCard(
                context,
                theme,
                colorScheme,
                icon: Icons.inventory_2_outlined,
                title: 'Pharmacy & Stock',
                onTap: () => context.push(RoutePaths.vetPharmacy),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildOperationCard(
                context,
                theme,
                colorScheme,
                icon: Icons.insights,
                title: 'Analytics & Reports',
                onTap: () => context.push(RoutePaths.vetAnalytics),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOperationCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
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
          context.push(RoutePaths.vetPharmacy);
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
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Inventory',
        ),
      ],
    );
  }
}
