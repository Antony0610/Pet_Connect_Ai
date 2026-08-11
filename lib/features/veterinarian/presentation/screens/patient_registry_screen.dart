import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

class PatientRegistryScreen extends StatefulWidget {
  const PatientRegistryScreen({super.key});

  @override
  State<PatientRegistryScreen> createState() => _PatientRegistryScreenState();
}

class _PatientRegistryScreenState extends State<PatientRegistryScreen> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _patients = [
    {
      'id': 'p1',
      'name': 'Buster',
      'breed': 'Golden Retriever',
      'status': 'Stable',
      'statusColor': Colors.green,
      'owner': 'Sarah J.',
      'lastVisit': 'Oct 12, 2023',
      'avatarColor': Colors.amber,
    },
    {
      'id': 'p2',
      'name': 'Luna',
      'breed': 'Siberian Husky',
      'status': 'Monitoring',
      'statusColor': Colors.amber,
      'owner': 'Mike T.',
      'lastVisit': 'Nov 05, 2023',
      'avatarColor': Colors.purple,
    },
    {
      'id': 'p3',
      'name': 'Winston',
      'breed': 'Pug',
      'status': 'Stable',
      'statusColor': Colors.green,
      'owner': 'David M.',
      'lastVisit': 'Oct 28, 2023',
      'avatarColor': Colors.blue,
    },
    {
      'id': 'p4',
      'name': 'Buddy',
      'breed': 'Golden Retriever',
      'status': 'Post-Op Alert',
      'statusColor': Colors.red,
      'owner': 'Sarah J.',
      'lastVisit': 'Today (10:00 AM)',
      'avatarColor': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = _patients.where((p) {
      return _searchQuery.isEmpty ||
          p['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          p['breed'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          p['owner'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
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
              'Patient Registry',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Clinic Directory (${_patients.length} Active)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () {},
            tooltip: 'Register Patient',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppTextField(
                hintText: 'Search patient by name, breed, or owner...',
                prefixIcon: Icons.search,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            // Alphabet Quick Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['ALL', 'A', 'B', 'C', 'D', 'E', 'F', 'L', 'M', 'W']
                    .map(
                      (char) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(label: Text(char), onPressed: () {}),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Patient Directory List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final patient = filtered[index];
                  return _buildPatientRegistryCard(
                    context,
                    theme,
                    colorScheme,
                    patient,
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

  Widget _buildPatientRegistryCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> patient,
  ) {
    final statusColor = patient['statusColor'] as Color;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: patient['avatarColor'] as Color,
                child: const Icon(Icons.pets, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      patient['breed'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppChip(
                label: patient['status'] as String,
                backgroundColor: statusColor.withOpacity(0.15),
                textColor: statusColor,
              ),
            ],
          ),
          const Divider(height: 20),
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
                    'Owner: ${patient['owner']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last: ${patient['lastVisit']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'View Full Medical Profile',
              onPressed: () => context.push('/vet/patients/${patient['id']}'),
              backgroundColor: colorScheme.primaryContainer,
              textColor: colorScheme.onPrimaryContainer,
              height: 38,
            ),
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
      selectedIndex: 3,
      onDestinationSelected: (index) {
        if (index == 0) {
          context.go(RoutePaths.vetHome);
        } else if (index == 1) {
          context.push(RoutePaths.vetQueue);
        } else if (index == 2) {
          context.push(RoutePaths.vetAppointments);
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
