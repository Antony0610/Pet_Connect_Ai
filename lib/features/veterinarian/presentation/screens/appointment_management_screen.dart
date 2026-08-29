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

class AppointmentManagementScreen extends ConsumerStatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  ConsumerState<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends ConsumerState<AppointmentManagementScreen> {
  DateTime _calendarDate = DateTime.now();
  int _selectedDay = DateTime.now().day;
  String _filter = 'All';

  Future<void> _openAddAppointmentDialog(String? clinicId) async {
    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController(text: 'Canine / Feline');
    final reasonCtrl = TextEditingController(text: 'Comprehensive Checkup');
    final timeCtrl = TextEditingController(text: '10:00 AM');
    int duration = 30;
    String priority = 'routine';

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Clinical Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Patient Name',
                    hintText: 'e.g. Bella, Milo, Rocky',
                    prefixIcon: Icon(Icons.pets),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Breed / Species',
                    hintText: 'e.g. Golden Retriever',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Visit',
                    hintText: 'e.g. Vaccination, Post-Op Check',
                    prefixIcon: Icon(Icons.medical_information_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Appointment Time',
                    hintText: 'e.g. 10:30 AM',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: duration,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 min (Brief)')),
                    DropdownMenuItem(value: 30, child: Text('30 min (Standard)')),
                    DropdownMenuItem(value: 45, child: Text('45 min (Extended)')),
                    DropdownMenuItem(value: 60, child: Text('60 min (Procedure)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => duration = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Triage Priority',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'routine', child: Text('Routine')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    DropdownMenuItem(value: 'critical', child: Text('Critical / Emergency')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => priority = val);
                  },
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
              child: const Text('Schedule Appointment'),
            ),
          ],
        ),
      ),
    );

    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      final now = DateTime(_calendarDate.year, _calendarDate.month, _selectedDay);
      final currentTimestamp = DateTime.now();
      final newAppt = Appointment(
        id: '',
        petId: '',
        clinicId: clinicId ?? '',
        veterinarianId: '',
        appointmentDate: now,
        durationMinutes: duration,
        reason: '${nameCtrl.text.trim()} (${breedCtrl.text.trim()}): ${reasonCtrl.text.trim()}',
        status: 'confirmed',
        priority: priority,
        notes: 'Scheduled for ${timeCtrl.text.trim()}',
        createdAt: currentTimestamp,
        updatedAt: currentTimestamp,
      );

      final repo = ref.read(vetRepositoryProvider);
      final result = await repo.createAppointment(newAppt);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to schedule appointment: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(appointmentsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Appointment scheduled for ${nameCtrl.text.trim()} at ${timeCtrl.text.trim()}!',
                ),
              ),
            );
          }
        },
      );
    }
  }

  Future<void> _updateStatus(String appointmentId, String newStatus) async {
    final repo = ref.read(vetRepositoryProvider);
    final result = await repo.updateAppointmentStatus(appointmentId, newStatus);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: ${failure.message}')),
          );
        }
      },
      (_) {
        ref.invalidate(appointmentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Appointment marked as $newStatus.')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final clinicsAsync = ref.watch(vetClinicsProvider);
    final clinics = clinicsAsync.valueOrNull ?? [];
    final clinicId = clinics.isNotEmpty ? clinics.first.id : null;

    final appointmentsAsync = ref.watch(appointmentsProvider({'clinicId': clinicId}));
    final allAppointments = appointmentsAsync.valueOrNull ?? [];

    final filteredAppointments = allAppointments.where((appt) {
      // Filter by day if desired
      final matchesDay = appt.appointmentDate.day == _selectedDay &&
          appt.appointmentDate.month == _calendarDate.month &&
          appt.appointmentDate.year == _calendarDate.year;

      if (_filter == 'Upcoming') {
        return (appt.status.toLowerCase() == 'confirmed' ||
                appt.status.toLowerCase() == 'upcoming') &&
            (matchesDay || allAppointments.length < 5);
      } else if (_filter == 'Completed') {
        return appt.status.toLowerCase() == 'completed' &&
            (matchesDay || allAppointments.length < 5);
      }
      return matchesDay || allAppointments.length < 5;
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
              'Schedule Management',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Active Appointments (${filteredAppointments.length})',
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
            icon: const Icon(Icons.add_task),
            onPressed: () => _openAddAppointmentDialog(clinicId),
            tooltip: 'Add Appointment',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddAppointmentDialog(clinicId),
        icon: const Icon(Icons.add),
        label: const Text('Add Appointment'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(appointmentsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar Month Navigator Header
                _buildMonthHeader(context, theme, colorScheme),
                const SizedBox(height: 12),

                // Calendar Days Grid Bar
                _buildCalendarDaysGrid(context, theme, colorScheme),
                const SizedBox(height: 16),

                // Filter Chips Row + New Appointment CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Upcoming'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Completed'),
                      ],
                    ),
                    AppButton(
                      text: '+ New',
                      onPressed: () => _openAddAppointmentDialog(clinicId),
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      height: 36,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Day Summary Bar
                Text(
                  '${DateFormat('EEEE, MMM d').format(DateTime(_calendarDate.year, _calendarDate.month, _selectedDay))} • ${filteredAppointments.length} Appointments',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Appointment List
                if (appointmentsAsync.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filteredAppointments.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.event_available_outlined, size: 48, color: colorScheme.primary.withValues(alpha: 0.6)),
                          const SizedBox(height: 12),
                          Text(
                            'No appointments found for this selection',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "+ New" or the button below to book an appointment.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Schedule Appointment'),
                            onPressed: () => _openAddAppointmentDialog(clinicId),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAppointments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final appt = filteredAppointments[index];
                      return _buildAppointmentCard(
                        context,
                        theme,
                        colorScheme,
                        appt,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final monthStr = DateFormat('MMMM yyyy').format(_calendarDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          monthStr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Month',
              onPressed: () {
                setState(() {
                  _calendarDate = DateTime(_calendarDate.year, _calendarDate.month - 1);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Month',
              onPressed: () {
                setState(() {
                  _calendarDate = DateTime(_calendarDate.year, _calendarDate.month + 1);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarDaysGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final now = DateTime.now();
    final daysInWeek = List.generate(7, (i) {
      final d = now.subtract(Duration(days: now.weekday - 1)).add(Duration(days: i));
      return d;
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: daysInWeek.map((d) {
        final dayNum = d.day;
        final selected = _selectedDay == dayNum && _calendarDate.month == d.month;
        final label = DateFormat('E').format(d).substring(0, 2);

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDay = dayNum;
              _calendarDate = d;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dayNum',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _filter == label;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _filter = label;
          });
        }
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }

  Widget _buildAppointmentCard(
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

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$timeStr (${appt.durationMinutes} min)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppChip(
                label: appt.status.toUpperCase(),
                backgroundColor: statusColor.withValues(alpha: 0.15),
                textColor: statusColor,
              ),
            ],
          ),
          const Divider(height: 20),
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
                    ),
                    if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        appt.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Priority: ${appt.priority.toUpperCase()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.video_call_outlined, size: 16),
                    label: const Text('Start Consult'),
                    onPressed: () => context.push('${RoutePaths.vetConsultation}?appointmentId=${appt.id}'),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (val) {
                      if (val == 'complete') {
                        _updateStatus(appt.id, 'completed');
                      } else if (val == 'cancel') {
                        _updateStatus(appt.id, 'cancelled');
                      } else if (val == 'in_progress') {
                        _updateStatus(appt.id, 'in_progress');
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'in_progress', child: Text('Mark In Progress')),
                      const PopupMenuItem(value: 'complete', child: Text('Mark Completed')),
                      const PopupMenuItem(value: 'cancel', child: Text('Cancel Appointment')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
