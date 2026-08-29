import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/appointment.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class TodaysAppointmentsScreen extends ConsumerStatefulWidget {
  const TodaysAppointmentsScreen({super.key});

  @override
  ConsumerState<TodaysAppointmentsScreen> createState() =>
      _TodaysAppointmentsScreenState();
}

class _TodaysAppointmentsScreenState
    extends ConsumerState<TodaysAppointmentsScreen> {
  String _selectedView = 'Day';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final clinicsAsync = ref.watch(vetClinicsProvider);
    final clinics = clinicsAsync.valueOrNull ?? [];
    final clinicId = clinics.isNotEmpty ? clinics.first.id : null;

    final appointmentsAsync = ref.watch(appointmentsProvider({'clinicId': clinicId}));
    final appointments = appointmentsAsync.valueOrNull ?? [];

    final today = DateTime.now();
    final todaysAppointments = appointments.where((a) {
      return a.appointmentDate.year == today.year &&
          a.appointmentDate.month == today.month &&
          a.appointmentDate.day == today.day;
    }).toList();

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
              'Today\'s Schedule',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('EEEE, MMMM d, y').format(today),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(appointmentsProvider),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.push(RoutePaths.vetAppointments),
            tooltip: 'Schedule Management',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // View Mode Segmented Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: _buildSegmentButton('Day')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSegmentButton('Week')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSegmentButton('Month')),
                ],
              ),
            ),

            // Schedule Timeline Grid
            Expanded(
              child: appointmentsAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : todaysAppointments.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: AppCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_available_outlined,
                                    size: 48,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No Consultations Scheduled For Today',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Clinical slots are open for walk-in triage or online bookings.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Schedule Appointment'),
                                    onPressed: () => context.push(RoutePaths.vetAppointments),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: todaysAppointments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final appt = todaysAppointments[index];
                            return _buildAppointmentSlotCard(
                              context,
                              theme,
                              colorScheme,
                              appt,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, theme, colorScheme),
    );
  }

  Widget _buildSegmentButton(String label) {
    final selected = _selectedView == label;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedView = label;
        });
        if (label == 'Month' || label == 'Week') {
          context.push(RoutePaths.vetAppointments);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentSlotCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Appointment appt,
  ) {
    final statusColor = appt.status.toLowerCase() == 'completed'
        ? AppColors.success
        : (appt.status.toLowerCase() == 'cancelled'
            ? colorScheme.error
            : AppColors.info);

    final timeStr = DateFormat('hh:mm a').format(appt.appointmentDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${appt.durationMinutes} min',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => context.push('${RoutePaths.vetConsultation}?appointmentId=${appt.id}'),
            borderRadius: BorderRadius.circular(16),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.pets, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appt.reason,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Priority: ${appt.priority.toUpperCase()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppChip(
                        label: appt.status.toUpperCase(),
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        textColor: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.medical_information, size: 16),
                        label: const Text('Chart'),
                        onPressed: () => context.push('/vet/patients/${appt.petId.isNotEmpty ? appt.petId : "p1"}'),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        text: 'Start Visit',
                        onPressed: () => context.push('${RoutePaths.vetConsultation}?appointmentId=${appt.id}'),
                        backgroundColor: colorScheme.primary,
                        textColor: colorScheme.onPrimary,
                        height: 36,
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      selectedIndex: 2,
      onDestinationSelected: (index) {
        if (index == 0) {
          context.go(RoutePaths.vetHome);
        } else if (index == 1) {
          context.push(RoutePaths.vetQueue);
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
