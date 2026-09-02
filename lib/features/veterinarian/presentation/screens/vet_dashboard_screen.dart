import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/patient_queue_notifier.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

class VetDashboardScreen extends ConsumerWidget {
  const VetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final clinicsAsync = ref.watch(vetClinicsProvider);
    final clinics = clinicsAsync.valueOrNull ?? [];
    final clinicId = clinics.isNotEmpty ? clinics.first.id : null;
    final clinicName = clinics.isNotEmpty ? clinics.first.name : 'Veterinary Clinic';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_services_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VetOps Workspace',
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
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_rounded),
            tooltip: 'Vet Community',
            onPressed: () => context.push(RoutePaths.vetCommunity),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Messages',
            onPressed: () => context.push(RoutePaths.vetCommunityMessages),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(RoutePaths.vetProfile),
            tooltip: 'Vet Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Sign out of Veterinarian Portal?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Sign Out', style: TextStyle(color: colorScheme.error)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(signOutProvider)(const NoParams());
                if (context.mounted) context.go(RoutePaths.login);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              _buildHeaderBanner(context, theme, colorScheme, ref, clinicName),
              const SizedBox(height: 16),

              // Summary Metrics Row
              _buildMetricsRow(context, theme, colorScheme, ref),
              const SizedBox(height: 20),

              // Quick Actions Grid (Reference Style)
              _buildQuickActions(context, theme, colorScheme),
              const SizedBox(height: 20),

              // High Priority AI Alert
              _buildAiAlertCard(context, theme, colorScheme, ref),
              const SizedBox(height: 20),

              // Upcoming Consultations
              _buildUpcomingConsultations(context, theme, colorScheme, ref, clinicId),
              const SizedBox(height: 20),

              // Recent Updates
              _buildRecentUpdates(context, theme, colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, theme, colorScheme),
    );
  }

  Widget _buildHeaderBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
    String clinicName,
  ) {
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final doctorName = (userProfile != null && userProfile.fullName.isNotEmpty)
        ? (userProfile.fullName.startsWith('Dr.') ? userProfile.fullName : 'Dr. ${userProfile.fullName}')
        : (userProfile != null && userProfile.email.isNotEmpty ? 'Dr. ${userProfile.email.split('@').first}' : 'Dr. Practitioner');

    return AppCard(
      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $doctorName',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Active at $clinicName • Ready for triage and clinical consultations.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets_rounded,
              color: colorScheme.onPrimary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
  ) {
    final queuePatients = ref.watch(patientQueueStateProvider);
    final waitingCount = queuePatients.where((p) => p.status == TriageStatus.waiting || p.status == TriageStatus.inTriage).length;
    final criticalCount = queuePatients.where((p) => p.priority == TriagePriority.critical || p.priority == TriagePriority.urgent).length;
    final totalAlerts = queuePatients.where((p) => p.priority != TriagePriority.routine).length;

    return Row(
      children: [
        // Queue Metric Card
        Expanded(
          child: InkWell(
            onTap: () => context.push(RoutePaths.vetQueue),
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
                        Icons.groups_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      AppChip(
                        label: 'Live',
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        textColor: colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$waitingCount',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Waiting in Queue',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Alerts Metric Card
        Expanded(
          child: InkWell(
            onTap: () => context.push(RoutePaths.vetQueue),
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
                        color: criticalCount > 0 ? colorScheme.error : AppColors.warning,
                        size: 24,
                      ),
                      AppChip(
                        label: criticalCount > 0 ? 'Urgent' : 'Active',
                        backgroundColor: criticalCount > 0 ? colorScheme.errorContainer : colorScheme.surfaceContainerHighest,
                        textColor: criticalCount > 0 ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$totalAlerts / $criticalCount',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: criticalCount > 0 ? colorScheme.error : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Alerts / Critical',
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

  Widget _buildQuickActions(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final actions = [
      QuickActionItemSpec(
        icon: Icons.groups_rounded,
        title: 'Triage\nQueue',
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        badgeText: 'LIVE',
        onTap: () => context.push(RoutePaths.vetQueue),
      ),
      QuickActionItemSpec(
        icon: Icons.calendar_today_rounded,
        title: 'Daily\nSchedule',
        gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        onTap: () => context.push(RoutePaths.vetAppointments),
      ),
      QuickActionItemSpec(
        icon: Icons.folder_shared_rounded,
        title: 'Patient\nRegistry',
        gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
        onTap: () => context.push(RoutePaths.vetPatients),
      ),
      QuickActionItemSpec(
        icon: Icons.medication_rounded,
        title: 'Digital\nPrescription',
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        onTap: () => context.push(RoutePaths.vetPrescription),
      ),
      QuickActionItemSpec(
        icon: Icons.inventory_2_rounded,
        title: 'Pharmacy\nInventory',
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0E7490)],
        onTap: () => context.push(RoutePaths.vetPharmacy),
      ),
      QuickActionItemSpec(
        icon: Icons.analytics_rounded,
        title: 'Practice\nAnalytics',
        gradientColors: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
        onTap: () => context.push(RoutePaths.vetAnalytics),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;
            final crossAxisCount = isDesktop ? 6 : 3;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isDesktop ? 1.05 : 0.85,
              ),
              itemBuilder: (context, index) {
                return QuickActionButton.fromSpec(actions[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAiAlertCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
  ) {
    final queuePatients = ref.watch(patientQueueStateProvider);
    final critical = queuePatients.where((p) => p.priority == TriagePriority.critical).toList();
    final urgent = queuePatients.where((p) => p.priority == TriagePriority.urgent).toList();
    final alertPatient = critical.isNotEmpty ? critical.first : (urgent.isNotEmpty ? urgent.first : null);

    if (alertPatient == null) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline_rounded, color: colorScheme.onPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Triage Steady',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'No critical physiological anomalies currently flagged by AI Telemetry.',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_heart_rounded,
                  color: colorScheme.onError,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'High Priority Triage Alert',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
              ),
              Text(
                'Live Sensor',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${alertPatient.name} (${alertPatient.breedAge}) • ${alertPatient.priority.label.toUpperCase()}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chief Complaint: ${alertPatient.reason}. Smart Telemetry Collar indicates elevated vitals. Urgent clinical exam recommended.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Attend in Queue',
                  onPressed: () => context.push(RoutePaths.vetQueue),
                  backgroundColor: colorScheme.error,
                  textColor: colorScheme.onError,
                  height: 40,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.push('/vet/patients/${alertPatient.id}'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: BorderSide(color: colorScheme.error),
                ),
                child: Text(
                  'View Record',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingConsultations(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
    String? clinicId,
  ) {
    final appointmentsAsync = ref.watch(appointmentsProvider({'clinicId': clinicId}));
    final appointments = appointmentsAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Consultations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RoutePaths.vetAppointments),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (appointments.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Scheduled Consultations for Today',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tap "View All" or use Quick Actions to book appointments.',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => context.push(RoutePaths.vetAppointments),
                  child: const Text('Book'),
                ),
              ],
            ),
          )
        else
          ...appointments.take(3).map(
            (apt) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => context.push('${RoutePaths.vetConsultation}?appointmentId=${apt.id}'),
                borderRadius: BorderRadius.circular(12),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.secondaryContainer,
                        child: Icon(Icons.pets, color: colorScheme.onSecondaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apt.reason,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${apt.durationMinutes} min • Status: ${apt.status}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppChip(
                            label: '${apt.appointmentDate.hour}:${apt.appointmentDate.minute.toString().padLeft(2, '0')}',
                            backgroundColor: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            apt.priority.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentUpdates(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical Practice Feed',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Diagnostic Pathology model active & ready.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    'Online',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Telemedicine and prescription dispatch module operational.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    'Active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
