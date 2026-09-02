import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_patient.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_bottom_nav_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/portal_notification_badge_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class PatientRegistryScreen extends ConsumerStatefulWidget {
  const PatientRegistryScreen({super.key});

  @override
  ConsumerState<PatientRegistryScreen> createState() => _PatientRegistryScreenState();
}

class _PatientRegistryScreenState extends ConsumerState<PatientRegistryScreen> {
  String _searchQuery = '';
  String _selectedLetter = 'ALL';

  Future<void> _openRegisterPatientDialog(String? clinicId) async {
    final nameCtrl = TextEditingController();
    final speciesCtrl = TextEditingController(text: 'dog');
    final breedCtrl = TextEditingController(text: 'Mixed Breed');
    final ownerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '15.0');
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
                  controller: speciesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Species (dog, cat, etc.)',
                    hintText: 'e.g. dog / cat / bird',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Breed / Variety',
                    hintText: 'e.g. Golden Retriever',
                    prefixIcon: Icon(Icons.badge_outlined),
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
                    hintText: 'e.g. +91 98450 12345',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'e.g. 28.5',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
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
      final newPatient = VetPatient(
        id: '',
        name: nameCtrl.text.trim(),
        species: speciesCtrl.text.trim().toLowerCase(),
        breed: breedCtrl.text.trim(),
        ownerName: ownerCtrl.text.trim().isNotEmpty ? ownerCtrl.text.trim() : 'Guardian',
        ownerPhone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
        status: status,
        weightKg: double.tryParse(weightCtrl.text.trim()) ?? 10.0,
        healthStatus: status == 'Stable' ? 'optimal' : (status == 'Monitoring' ? 'fair' : 'critical'),
        lastVisitDate: DateTime.now(),
      );

      final repo = ref.read(vetRepositoryProvider);
      final result = await repo.registerPatient(newPatient);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to register patient: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(vetPatientsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Patient ${nameCtrl.text.trim()} registered to clinical database!',
                ),
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final clinicsAsync = ref.watch(vetClinicsProvider);
    final clinics = clinicsAsync.valueOrNull ?? [];
    final clinicId = clinics.isNotEmpty ? clinics.first.id : null;

    final patientsAsync = ref.watch(vetPatientsProvider(clinicId));
    final allPatients = patientsAsync.valueOrNull ?? [];

    final filtered = allPatients.where((p) {
      final matchesQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.breed?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          p.ownerName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesLetter = _selectedLetter == 'ALL' ||
          p.name.toUpperCase().startsWith(_selectedLetter);

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
              '${filtered.length} Active Records in Clinic Database',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          PortalNotificationBadgeButton(
            onPressed: () => context.push(RoutePaths.vetNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(vetPatientsProvider),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => _openRegisterPatientDialog(clinicId),
            tooltip: 'Register New Patient',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRegisterPatientDialog(clinicId),
        icon: const Icon(Icons.add),
        label: const Text('Register Patient'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppTextField(
                hintText: 'Search patient by name, breed, or guardian...',
                prefixIcon: Icons.search,
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // A-Z Alphabet Filter Strip
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: 27,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final letter = index == 0
                      ? 'ALL'
                      : String.fromCharCode(64 + index);
                  final selected = _selectedLetter == letter;

                  return ChoiceChip(
                    label: Text(letter),
                    selected: selected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedLetter = letter);
                    },
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Patients List
            Expanded(
              child: patientsAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: AppCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pets,
                                    size: 48,
                                    color: colorScheme.primary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No Patient Records Found',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Register companion animals to access digital medical records, treatment plans, and telemetry.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text('Register Patient'),
                                    onPressed: () => _openRegisterPatientDialog(clinicId),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final patient = filtered[index];
                            return _buildPatientCard(
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
      bottomNavigationBar: const VetBottomNavBar(currentTab: VetTab.patients),
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    VetPatient patient,
  ) {
    final statusColor = patient.status == 'Stable'
        ? AppColors.success
        : (patient.status == 'Monitoring'
            ? AppColors.warning
            : colorScheme.error);

    return InkWell(
      onTap: () => context.push('/vet/patients/${patient.id}'),
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        patient.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppChip(
                        label: patient.status,
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        textColor: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patient.breedLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Owner: ${patient.ownerName}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (patient.weightKg != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.monitor_weight_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${patient.weightKg} kg',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
