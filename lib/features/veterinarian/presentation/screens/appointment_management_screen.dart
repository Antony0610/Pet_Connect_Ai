import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen> {
  int _selectedDay = 24;
  String _filter = 'All';

  final List<Map<String, dynamic>> _appointments = [
    {
      'time': '09:00 AM',
      'duration': '30 min',
      'patientName': 'Luna',
      'breed': 'Siberian Husky',
      'reason': 'General Checkup & Vaccination',
      'doctor': 'Dr. Sarah Jenkins',
      'status': 'Confirmed',
      'statusColor': AppColors.success,
    },
    {
      'time': '11:15 AM',
      'duration': '30 min',
      'patientName': 'Max',
      'breed': 'Labrador Retriever',
      'reason': 'Vaccination & Microchip',
      'doctor': 'Dr. Miller',
      'status': 'In Progress',
      'statusColor': AppColors.info,
    },
    {
      'time': '02:00 PM',
      'duration': '45 min',
      'patientName': 'Bella',
      'breed': 'Persian Cat',
      'reason': 'Dental Check & Cleaning',
      'doctor': 'Dr. Sarah Jenkins',
      'status': 'Upcoming',
      'statusColor': AppColors.warning,
    },
  ];

  void _openAddAppointmentDialog() async {
    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController(text: 'Canine / Feline');
    final reasonCtrl = TextEditingController(text: 'Comprehensive Checkup');
    final timeCtrl = TextEditingController(text: '03:30 PM');
    String duration = '30 min';

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
                DropdownButtonFormField<String>(
                  initialValue: duration,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: '15 min', child: Text('15 min (Brief)')),
                    DropdownMenuItem(value: '30 min', child: Text('30 min (Standard)')),
                    DropdownMenuItem(value: '45 min', child: Text('45 min (Extended)')),
                    DropdownMenuItem(value: '60 min', child: Text('60 min (Procedure)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => duration = val);
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
      setState(() {
        _appointments.insert(0, {
          'time': timeCtrl.text.trim(),
          'duration': duration,
          'patientName': nameCtrl.text.trim(),
          'breed': breedCtrl.text.trim(),
          'reason': reasonCtrl.text.trim(),
          'doctor': 'Dr. Practitioner',
          'status': 'Confirmed',
          'statusColor': AppColors.success,
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appointment scheduled for ${nameCtrl.text.trim()} at ${timeCtrl.text.trim()}!',
            ),
          ),
        );
      }
    }
  }

  void _deleteAppointment(int index) {
    setState(() {
      _appointments.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment cancelled.')),
    );
  }

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
              'Schedule Management',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Active Appointments (${_appointments.length})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: _openAddAppointmentDialog,
            tooltip: 'Add Appointment',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAppointmentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Appointment'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    onPressed: _openAddAppointmentDialog,
                    backgroundColor: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                    height: 36,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Day Summary Bar
              Text(
                'Tuesday, Oct 24 • ${_appointments.length} Appointments Scheduled',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              // Appointment List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final appt = _appointments[index];
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
    );
  }

  DateTime _calendarDate = DateTime.now();

  Widget _buildMonthHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthStr = '${months[_calendarDate.month - 1]} ${_calendarDate.year}';

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
    final days = [21, 22, 23, 24, 25, 26, 27];
    final labels = ['Sa', 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(days.length, (i) {
        final dayNum = days[i];
        final selected = _selectedDay == dayNum;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDay = dayNum;
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
                  labels[i],
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
      }),
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
    Map<String, dynamic> appt,
  ) {
    final statusColor = appt['statusColor'] as Color;

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
                    '${appt['time']} (${appt['duration']})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppChip(
                label: appt['status'] as String,
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
                      '${appt['patientName']} (${appt['breed']})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appt['reason'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
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
                    Icons.person_outline,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    appt['doctor'] as String,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.assignment_outlined, size: 16),
                    label: const Text('Open Chart'),
                    onPressed: () => context.push('/vet/patients/p1'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                    tooltip: 'Cancel Appointment',
                    onPressed: () {
                      final idx = _appointments.indexOf(appt);
                      if (idx != -1) _deleteAppointment(idx);
                    },
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
