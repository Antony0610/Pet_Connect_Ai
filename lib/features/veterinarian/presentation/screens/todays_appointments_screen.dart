import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

class TodaysAppointmentsScreen extends StatefulWidget {
  const TodaysAppointmentsScreen({super.key});

  @override
  State<TodaysAppointmentsScreen> createState() =>
      _TodaysAppointmentsScreenState();
}

class _TodaysAppointmentsScreenState extends State<TodaysAppointmentsScreen> {
  String _selectedView = 'Day';

  final List<Map<String, dynamic>> _scheduleSlots = [
    {'time': '09:00 AM', 'isBooked': false},
    {
      'time': '10:00 AM',
      'isBooked': true,
      'patientName': 'Luna',
      'breed': 'Siberian Husky',
      'duration': '10:30 - 11:00',
      'status': 'Checked-in',
      'statusColor': Colors.green,
      'reason': 'Routine Checkup',
      'type': 'General',
    },
    {
      'time': '11:00 AM',
      'isBooked': true,
      'patientName': 'Max',
      'breed': 'Labrador Retriever',
      'duration': '11:15 - 11:45',
      'status': 'In Progress',
      'statusColor': Colors.teal,
      'reason': 'Vaccination & Microchip',
      'type': 'Vaccine',
    },
    {'time': '12:00 PM', 'isBooked': false},
    {'time': '01:00 PM', 'isBooked': false},
    {
      'time': '02:00 PM',
      'isBooked': true,
      'patientName': 'Bella',
      'breed': 'Persian Cat',
      'duration': '14:00 - 14:45',
      'status': 'Upcoming',
      'statusColor': Colors.amber,
      'reason': 'Dental Check & Cleaning',
      'type': 'Dental',
    },
  ];

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
              'Today\'s Schedule',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Tuesday, October 24, 2023',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
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
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _scheduleSlots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final slot = _scheduleSlots[index];
                  return _buildTimeSlotCard(context, theme, colorScheme, slot);
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
          context.push(RoutePaths.vetAppointmentSchedule);
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

  Widget _buildTimeSlotCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> slot,
  ) {
    final isBooked = slot['isBooked'] as bool;
    final time = slot['time'] as String;

    if (!isBooked) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              time,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: colorScheme.surfaceContainerLow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Time Slot',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: colorScheme.primary,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final status = slot['status'] as String;
    final statusColor = slot['statusColor'] as Color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                slot['duration'],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => context.push('/vet/consultation/c1'),
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
                              '${slot['patientName']} (${slot['breed']})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              slot['reason'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppChip(
                        label: status,
                        backgroundColor: statusColor.withOpacity(0.15),
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
                        onPressed: () => context.push('/vet/patients/p1'),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        text: 'Start Visit',
                        onPressed: () => context.push('/vet/consultation/c1'),
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
