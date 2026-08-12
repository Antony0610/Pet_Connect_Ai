import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class PatientQueueScreen extends ConsumerStatefulWidget {
  const PatientQueueScreen({super.key});

  @override
  ConsumerState<PatientQueueScreen> createState() => _PatientQueueScreenState();
}

class _PatientQueueScreenState extends ConsumerState<PatientQueueScreen> {
  String _searchQuery = '';
  String _selectedPriority = 'ALL';

  final List<Map<String, dynamic>> _queuePatients = [
    {
      'id': 'p1',
      'name': 'Buster',
      'breedAge': 'Golden Retriever • 5y',
      'priority': 'HIGH',
      'reason': 'Severe allergic reaction, facial swelling.',
      'waitTime': '25m',
      'owner': 'Sarah Jenkins',
      'avatarColor': Colors.amber,
    },
    {
      'id': 'p2',
      'name': 'Luna',
      'breedAge': 'Domestic Shorthair • 2y',
      'priority': 'MED',
      'reason': 'Limping on front left paw.',
      'waitTime': '15m',
      'owner': 'Michael Chen',
      'avatarColor': Colors.purple,
    },
    {
      'id': 'p3',
      'name': 'Winston',
      'breedAge': 'Pug • 6mo',
      'priority': 'ROUTINE',
      'reason': 'Annual vaccinations & checkup.',
      'waitTime': '5m',
      'owner': 'Emily Davis',
      'avatarColor': Colors.blue,
    },
    {
      'id': 'p4',
      'name': 'Oliver',
      'breedAge': 'Tabby Cat • 4y',
      'priority': 'HIGH',
      'reason': 'Post-op vitals anomaly drop.',
      'waitTime': '30m',
      'owner': 'Robert Wilson',
      'avatarColor': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = _queuePatients.where((patient) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          patient['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          patient['breedAge'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          patient['reason'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesPriority =
          _selectedPriority == 'ALL' ||
          patient['priority'] == _selectedPriority;

      return matchesQuery && matchesPriority;
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
              'Patient Queue',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Currently waiting: ${filtered.length} patients',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Queue refreshed')));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AppTextField(
                    hintText: 'Search patient, breed, reason...',
                    prefixIcon: Icons.search,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'ALL',
                          'All (${_queuePatients.length})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip('HIGH', 'HIGH Priority'),
                        const SizedBox(width: 8),
                        _buildFilterChip('MED', 'MED Priority'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ROUTINE', 'ROUTINE'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Queue Patients List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No patients in queue',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildQueueCard(
                          context,
                          theme,
                          colorScheme,
                          item,
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

  Widget _buildFilterChip(String key, String label) {
    final selected = _selectedPriority == key;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedPriority = key;
          });
        }
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildQueueCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> item,
  ) {
    final priority = item['priority'] as String;
    Color priorityColor;
    Color priorityContainer;

    if (priority == 'HIGH') {
      priorityColor = colorScheme.error;
      priorityContainer = colorScheme.errorContainer;
    } else if (priority == 'MED') {
      priorityColor = colorScheme.tertiary;
      priorityContainer = colorScheme.tertiaryContainer;
    } else {
      priorityColor = colorScheme.primary;
      priorityContainer = colorScheme.primaryContainer;
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: item['avatarColor'] as Color,
                child: const Icon(Icons.pets, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['breedAge'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppChip(
                label: '$priority Priority',
                backgroundColor: priorityContainer,
                textColor: priorityColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reason: ${item['reason']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Wait: ${item['waitTime']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              AppButton(
                text: priority == 'HIGH' ? 'Begin Triage' : 'Review Details',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Starting session for ${item['name']}'),
                    ),
                  );
                },
                backgroundColor: priorityColor,
                textColor: priority == 'HIGH'
                    ? colorScheme.onError
                    : (priority == 'MED'
                          ? colorScheme.onTertiary
                          : colorScheme.onPrimary),
                height: 36,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return NavigationBar(
      selectedIndex: 1,
      onDestinationSelected: (index) {
        if (index == 0) {
          context.go(RoutePaths.vetHome);
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
