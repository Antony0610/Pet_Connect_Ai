import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/appointment.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

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

    final appointmentsAsync = ref.watch(appointmentsProvider(const {}));
    final appointments = appointmentsAsync.valueOrNull ?? [];

    final today = DateTime.now();
    final todaysAppointments = appointments.where((a) {
      final localDate = a.appointmentDate.toLocal();
      if (_selectedView == 'Day') {
        return localDate.year == today.year &&
            localDate.month == today.month &&
            localDate.day == today.day;
      } else if (_selectedView == 'Week') {
        final diff = localDate.difference(today).inDays;
        return diff >= -1 && diff <= 7;
      } else {
        return localDate.year == today.year && localDate.month == today.month;
      }
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
            onPressed: () => context.push(RoutePaths.vetAppointmentSchedule),
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
                  : appointmentsAsync.hasError && todaysAppointments.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline_rounded,
                                      size: 26,
                                      color: Color(0xFFE11D48),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Unable to load appointments',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Please check your network connection and try again.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    onPressed: () => ref.invalidate(appointmentsProvider),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : todaysAppointments.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          Icons.event_available_rounded,
                                          size: 30,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
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
                                        onPressed: () => context.push(RoutePaths.vetAppointmentSchedule),
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
      bottomNavigationBar: const VetBottomNavBar(currentTab: VetTab.dashboard),
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
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
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
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = appt.status.toLowerCase() == 'completed'
        ? const Color(0xFF059669)
        : (appt.status.toLowerCase() == 'cancelled'
            ? const Color(0xFFE11D48)
            : const Color(0xFF2563EB));

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
            onTap: () => context.push(RoutePaths.vetConsultationPath(appt.id)),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.pets_rounded, color: colorScheme.primary, size: 20),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          appt.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.medical_information_rounded, size: 16),
                        label: const Text('Chart'),
                        onPressed: () => context.push('/vet/patients/${appt.petId.isNotEmpty ? appt.petId : "p1"}'),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        text: 'Start Visit',
                        onPressed: () => context.push(RoutePaths.vetConsultationPath(appt.id)),
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
}
