import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class PatientRegistryScreen extends StatefulWidget {
  const PatientRegistryScreen({super.key});

  @override
  State<PatientRegistryScreen> createState() => _PatientRegistryScreenState();
}

class _PatientRegistryScreenState extends State<PatientRegistryScreen> {
  String _searchQuery = '';
  String _selectedLetter = 'ALL';

  final List<Map<String, dynamic>> _patients = [
    {
      'id': 'p1',
      'name': 'Buster',
      'breed': 'Golden Retriever',
      'status': 'Stable',
      'statusColor': AppColors.success,
      'owner': 'Sarah J.',
      'lastVisit': 'Oct 12, 2023',
      'avatarColor': AppColors.warning,
    },
    {
      'id': 'p2',
      'name': 'Luna',
      'breed': 'Siberian Husky',
      'status': 'Monitoring',
      'statusColor': AppColors.warning,
      'owner': 'Mike T.',
      'lastVisit': 'Nov 05, 2023',
      'avatarColor': AppColors.info,
    },
    {
      'id': 'p3',
      'name': 'Winston',
      'breed': 'Pug',
      'status': 'Stable',
      'statusColor': AppColors.success,
      'owner': 'David M.',
      'lastVisit': 'Oct 28, 2023',
      'avatarColor': AppColors.info,
    },
    {
      'id': 'p4',
      'name': 'Buddy',
      'breed': 'Golden Retriever',
      'status': 'Post-Op Alert',
      'statusColor': AppColors.lightError,
      'owner': 'Sarah J.',
      'lastVisit': 'Today (10:00 AM)',
      'avatarColor': AppColors.info,
    },
  ];

  void _openRegisterPatientDialog() async {
    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String status = 'Stable';

    final registered = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Register New Patient'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pet / Patient Name',
                    hintText: 'e.g. Cooper, Daisy, Thor',
                    prefixIcon: Icon(Icons.pets),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Species & Breed',
                    hintText: 'e.g. Beagle / Canine',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Owner / Guardian Name',
                    hintText: 'e.g. Sarah Jenkins',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Owner Phone Number',
                    hintText: 'e.g. +1 (555) 019-2834',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Initial Clinical Status',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Stable', child: Text('Stable (Optimal)')),
                    DropdownMenuItem(value: 'Monitoring', child: Text('Monitoring (Routine Care)')),
                    DropdownMenuItem(value: 'Post-Op Alert', child: Text('Post-Op Alert (Critical Care)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => status = val);
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
              child: const Text('Register Patient'),
            ),
          ],
        ),
      ),
    );

    if (registered == true && nameCtrl.text.trim().isNotEmpty) {
      final statusColor = status == 'Stable'
          ? AppColors.success
          : (status == 'Monitoring' ? AppColors.warning : AppColors.lightError);

      setState(() {
        _patients.insert(0, {
          'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
          'name': nameCtrl.text.trim(),
          'breed': breedCtrl.text.trim().isNotEmpty ? breedCtrl.text.trim() : 'Companion',
          'status': status,
          'statusColor': statusColor,
          'owner': ownerCtrl.text.trim().isNotEmpty ? ownerCtrl.text.trim() : 'Patient Guardian',
          'lastVisit': 'Today (New Intake)',
          'avatarColor': AppColors.info,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient "${nameCtrl.text.trim()}" registered successfully!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = _patients.where((p) {
      final name = p['name'].toString().toLowerCase();
      final breed = p['breed'].toString().toLowerCase();
      final owner = p['owner'].toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          name.contains(q) ||
          breed.contains(q) ||
          owner.contains(q);
      final matchesLetter = _selectedLetter == 'ALL' ||
          p['name'].toString().toUpperCase().startsWith(_selectedLetter);
      return matchesQuery && matchesLetter;
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
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _openRegisterPatientDialog,
            tooltip: 'Register New Patient',
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
                        child: ChoiceChip(
                          label: Text(char),
                          selected: _selectedLetter == char,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedLetter = char);
                          },
                        ),
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
                      patient['breed'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppChip(
                label: patient['status'] as String,
                backgroundColor: statusColor.withValues(alpha: 0.15),
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
