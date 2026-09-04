import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/health_widgets.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Medical History Record** — `/owner/health/medical`.
///
/// Connected to live Supabase `health_records` table.
/// ZERO dummy/hardcoded data.
class MedicalHistoryRecordScreen extends ConsumerStatefulWidget {
  const MedicalHistoryRecordScreen({super.key});

  @override
  ConsumerState<MedicalHistoryRecordScreen> createState() =>
      _MedicalHistoryRecordScreenState();
}

class _MedicalHistoryRecordScreenState
    extends ConsumerState<MedicalHistoryRecordScreen> {
  static const _filters = ['All', 'Surgery', 'Checkup', 'Emergency'];
  int _selected = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);

    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';
    final petName = selectedPet?.name ?? 'Companion';
    final recordsAsync = petId.isNotEmpty ? ref.watch(healthRecordsProvider(petId)) : null;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(
        context,
        title: selectedPet != null
            ? "$petName's Medical History"
            : 'Medical History',
        actions: [
          if (selectedPet != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Log Medical Record',
              onPressed: () => _showLogRecordModal(context, ref, selectedPet),
            ),
        ],
      ),
      floatingActionButton: selectedPet != null
          ? FloatingActionButton.extended(
              onPressed: () => _showLogRecordModal(context, ref, selectedPet),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log Record'),
            )
          : null,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                AppSpacing.md,
                margin,
                AppSpacing.xxl,
              ),
              child: recordsAsync?.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text('Error loading medical records: $err'),
                  ),
                ),
                data: (records) => _MedicalHistoryContent(
                  pet: selectedPet,
                  petName: petName,
                  records: records,
                  selectedFilter: _filters[_selected],
                  filters: _filters,
                  selectedIndex: _selected,
                  onFilterChanged: (i) => setState(() => _selected = i),
                  searchController: _searchController,
                  onSearchChanged: () => setState(() {}),
                ),
              ) ??
              _MedicalHistoryContent(
                pet: selectedPet,
                petName: petName,
                records: const [],
                selectedFilter: _filters[_selected],
                filters: _filters,
                selectedIndex: _selected,
                onFilterChanged: (i) => setState(() => _selected = i),
                searchController: _searchController,
                onSearchChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }

  void _showLogRecordModal(BuildContext context, WidgetRef ref, Pet pet) {
    final titleCtrl = TextEditingController();
    final diagCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    final vetCtrl = TextEditingController(text: 'Dr. Prithiviraj');
    var recordDate = DateTime.now();
    var category = 'Checkup';

    final categories = ['Checkup', 'Surgery', 'Emergency', 'Vaccination', 'Dentistry', 'Diagnostic'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Log Encounter: ${pet.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: recordDate,
                        firstDate: DateTime(2010),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => recordDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text('Date: ${DateFormat('yyyy-MM-dd').format(recordDate)}'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Encounter Title *',
                      hintText: 'e.g. Annual Wellness Review & Vitals',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: diagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis / Findings',
                      hintText: 'e.g. Optimal health, minor tartar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: treatmentCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Treatment / Prescriptions',
                      hintText: 'e.g. Cleansing protocol, dietary adjustment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Attending Clinician / Hospital',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an encounter title.')),
                        );
                        return;
                      }
                      try {
                        final client = ref.read(supabaseClientProvider);
                        await client.from('health_records').insert({
                          'pet_id': pet.id,
                          'title': title,
                          'category': category,
                          'diagnosis': diagCtrl.text.trim().isNotEmpty ? diagCtrl.text.trim() : null,
                          'treatment': treatmentCtrl.text.trim().isNotEmpty ? treatmentCtrl.text.trim() : null,
                          'veterinarian_name': vetCtrl.text.trim().isNotEmpty ? vetCtrl.text.trim() : null,
                          'record_date': DateFormat('yyyy-MM-dd').format(recordDate),
                          'created_at': DateTime.now().toIso8601String(),
                        });

                        ref.invalidate(healthRecordsProvider(pet.id));

                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ Logged clinical record for ${pet.name}!'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save record: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('Save Record to Passport'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MedicalHistoryContent extends StatelessWidget {
  const _MedicalHistoryContent({
    this.pet,
    required this.petName,
    required this.records,
    required this.selectedFilter,
    required this.filters,
    required this.selectedIndex,
    required this.onFilterChanged,
    required this.searchController,
    required this.onSearchChanged,
  });

  final Pet? pet;

  final String petName;
  final List<HealthRecord> records;
  final String selectedFilter;
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onFilterChanged;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase().trim();
    final filtered = records.where((r) {
      final matchesCat = selectedFilter == 'All' ||
          r.category.toLowerCase() == selectedFilter.toLowerCase();
      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          (r.diagnosis?.toLowerCase().contains(query) ?? false) ||
          (r.notes?.toLowerCase().contains(query) ?? false);
      return matchesCat && matchesQuery;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchBar(
          controller: searchController,
          onChanged: (_) => onSearchChanged(),
        ),
        AppSpacing.vGapMd,
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => AppSpacing.hGapSm,
            itemBuilder: (_, i) => AppChip(
              label: filters[i],
              isSelected: i == selectedIndex,
              variant: i == selectedIndex
                  ? AppChipVariant.filled
                  : AppChipVariant.outlined,
              onTap: () => onFilterChanged(i),
            ),
          ),
        ),
        AppSpacing.vGapLg,
        _MedicalCards(pet: pet),
        AppSpacing.vGapLg,
        _RecordHistory(records: filtered, petName: petName),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search records by title, diagnosis, or note...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.brPill,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
    );
  }
}

class _MedicalCards extends ConsumerWidget {
  const _MedicalCards({this.pet});

  final Pet? pet;

  void _showEditAllergiesDialog(BuildContext context, WidgetRef ref, Pet pet) {
    final textController = TextEditingController();
    final allergies = List<String>.from(pet.allergies);

    const suggestions = [
      'Chicken',
      'Beef',
      'Dairy',
      'Flea Saliva',
      'Pollen',
      'Dust Mites',
      'Penicillin',
      'NSAIDs',
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final scheme = context.colorScheme;

          void addAllergy(String item) {
            final trimmed = item.trim();
            if (trimmed.isNotEmpty && !allergies.any((a) => a.toLowerCase() == trimmed.toLowerCase())) {
              setDialogState(() {
                allergies.add(trimmed);
              });
              textController.clear();
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.coronavirus_rounded, color: scheme.error),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'Edit Allergies - ${pet.name}',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Documented Allergic Sensitivities:',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGapSm,
                    if (allergies.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: allergies.map((allergy) {
                          return Chip(
                            backgroundColor: scheme.errorContainer,
                            label: Text(
                              allergy,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: scheme.onErrorContainer,
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                            deleteIcon: const Icon(Icons.close_rounded, size: 16),
                            deleteIconColor: scheme.onErrorContainer,
                            onDeleted: () {
                              setDialogState(() {
                                allergies.remove(allergy);
                              });
                            },
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        'No allergies recorded.',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    AppSpacing.vGapMd,
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: 'Add custom allergen...',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: addAllergy,
                          ),
                        ),
                        AppSpacing.hGapSm,
                        IconButton.filled(
                          onPressed: () => addAllergy(textController.text),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    AppSpacing.vGapMd,
                    Text(
                      'Common suggestions:',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: suggestions.map((sug) {
                        final exists = allergies.any((a) => a.toLowerCase() == sug.toLowerCase());
                        return ActionChip(
                          label: Text(sug, style: const TextStyle(fontSize: 12)),
                          avatar: Icon(
                            exists ? Icons.check_rounded : Icons.add_rounded,
                            size: 14,
                            color: exists ? Colors.green : null,
                          ),
                          onPressed: exists ? null : () => addAllergy(sug),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    final client = ref.read(supabaseClientProvider);
                    await client.from('pets').update({
                      'allergies': allergies,
                      'updated_at': DateTime.now().toIso8601String(),
                    }).eq('id', pet.id);

                    ref.invalidate(petsProvider);

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Allergies updated for ${pet.name}!'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update allergies: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditConditionsDialog(BuildContext context, WidgetRef ref, Pet pet) {
    final textController = TextEditingController();
    final conditions = List<String>.from(pet.chronicConditions);

    const suggestions = [
      'Atopic Dermatitis',
      'Osteoarthritis',
      'Chronic Kidney Disease (CKD)',
      'Diabetes Mellitus',
      'Epilepsy',
      'Hypothyroidism',
      'Asthma',
      'Heart Murmur',
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final scheme = context.colorScheme;

          void addCondition(String item) {
            final trimmed = item.trim();
            if (trimmed.isNotEmpty && !conditions.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
              setDialogState(() {
                conditions.add(trimmed);
              });
              textController.clear();
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.monitor_heart_rounded, color: scheme.tertiary),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'Edit Chronic Conditions - ${pet.name}',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Documented Chronic Diagnoses:',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGapSm,
                    if (conditions.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: conditions.map((cond) {
                          return Chip(
                            backgroundColor: scheme.tertiaryContainer,
                            label: Text(
                              cond,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: scheme.onTertiaryContainer,
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                            deleteIcon: const Icon(Icons.close_rounded, size: 16),
                            deleteIconColor: scheme.onTertiaryContainer,
                            onDeleted: () {
                              setDialogState(() {
                                conditions.remove(cond);
                              });
                            },
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        'No chronic conditions recorded.',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    AppSpacing.vGapMd,
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: 'Add condition or chronic diagnosis...',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: addCondition,
                          ),
                        ),
                        AppSpacing.hGapSm,
                        IconButton.filled(
                          onPressed: () => addCondition(textController.text),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    AppSpacing.vGapMd,
                    Text(
                      'Common suggestions:',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: suggestions.map((sug) {
                        final exists = conditions.any((c) => c.toLowerCase() == sug.toLowerCase());
                        return ActionChip(
                          label: Text(sug, style: const TextStyle(fontSize: 12)),
                          avatar: Icon(
                            exists ? Icons.check_rounded : Icons.add_rounded,
                            size: 14,
                            color: exists ? Colors.green : null,
                          ),
                          onPressed: exists ? null : () => addCondition(sug),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    final client = ref.read(supabaseClientProvider);
                    await client.from('pets').update({
                      'chronic_conditions': conditions,
                      'updated_at': DateTime.now().toIso8601String(),
                    }).eq('id', pet.id);

                    ref.invalidate(petsProvider);

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chronic conditions updated for ${pet.name}!'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update conditions: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final allergies = pet?.allergies ?? [];
    final conditions = pet?.chronicConditions ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Known Allergies Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Icon(
                      Icons.coronavirus_rounded,
                      color: scheme.onErrorContainer,
                      size: AppIconSizes.sm,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      'Known Allergies',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ),
                  if (pet != null)
                    TextButton.icon(
                      onPressed: () => _showEditAllergiesDialog(context, ref, pet!),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(allergies.isEmpty ? 'Add' : 'Edit'),
                    ),
                ],
              ),
              AppSpacing.vGapMd,
              if (allergies.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: allergies.map((allergy) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer.withValues(alpha: 0.6),
                        border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: scheme.error),
                          AppSpacing.hGapXs,
                          Text(
                            allergy,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onErrorContainer,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                const HealthEmptyBox(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'No known allergies reported',
                ),
            ],
          ),
        ),
        AppSpacing.vGapMd,

        // Chronic Conditions Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Icon(
                      Icons.monitor_heart_rounded,
                      color: scheme.onTertiaryContainer,
                      size: AppIconSizes.sm,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      'Chronic Conditions',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ),
                  if (pet != null)
                    TextButton.icon(
                      onPressed: () => _showEditConditionsDialog(context, ref, pet!),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(conditions.isEmpty ? 'Add' : 'Edit'),
                    ),
                ],
              ),
              AppSpacing.vGapMd,
              if (conditions.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: conditions.map((cond) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer.withValues(alpha: 0.6),
                        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.5)),
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.medical_information_rounded, size: 14, color: scheme.tertiary),
                          AppSpacing.hGapXs,
                          Text(
                            cond,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onTertiaryContainer,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                const HealthEmptyBox(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'No chronic conditions diagnosed',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordHistory extends StatelessWidget {
  const _RecordHistory({
    required this.records,
    required this.petName,
  });

  final List<HealthRecord> records;
  final String petName;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Record History',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        AppCard(
          child: records.isNotEmpty
              ? Column(
                  children: [
                    for (var i = 0; i < records.length; i++) ...[
                      if (i > 0)
                        Divider(
                          color: scheme.outlineVariant,
                          height: AppSpacing.lg,
                        ),
                      _TimelineTile(
                        record: records[i],
                        petName: petName,
                        isLast: i == records.length - 1,
                      ),
                    ],
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No medical records logged yet.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.record,
    required this.petName,
    required this.isLast,
  });

  final HealthRecord record;
  final String petName;
  final bool isLast;

  void _showRecordDetailsDialog(BuildContext context) {
    final scheme = context.colorScheme;
    final dateStr = DateFormat('MMMM dd, yyyy').format(record.recordDate);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(Icons.description_outlined, color: scheme.onPrimaryContainer, size: 20),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    HealthCategoryChip(
                      label: record.category,
                      background: scheme.primary.withValues(alpha: 0.15),
                      foreground: scheme.primary,
                    ),
                    if (record.veterinarianName != null && record.veterinarianName!.isNotEmpty) ...[
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Text(
                          'Attending: Dr. ${record.veterinarianName}',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontWeight: AppTypography.semiBold,
                            color: scheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.vGapMd,
                if (record.diagnosis != null && record.diagnosis!.isNotEmpty) ...[
                  Text(
                    'Clinical Diagnosis:',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGapXs,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Text(
                      record.diagnosis!,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                  AppSpacing.vGapMd,
                ],
                if (record.treatment != null && record.treatment!.isNotEmpty) ...[
                  Text(
                    'Treatment / Protocol Administered:',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGapXs,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Text(
                      record.treatment!,
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  AppSpacing.vGapMd,
                ],
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  Text(
                    'Clinical Notes:',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGapXs,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Text(
                      record.notes!,
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                  AppSpacing.vGapMd,
                ],
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              final shareSummary = '''
PETCONNECT AI - CLINICAL ENCOUNTER SUMMARY
Patient: $petName
Date: $dateStr
Category: ${record.category}
Title: ${record.title}
Attending Veterinarian: ${record.veterinarianName ?? 'Not specified'}
Diagnosis: ${record.diagnosis ?? 'None documented'}
Treatment / Rx: ${record.treatment ?? 'None documented'}
Clinical Notes: ${record.notes ?? 'None'}
Verified through PetConnect AI Health Passport
''';
              ExternalActions.shareText(shareSummary, subject: '$petName Clinical Record: ${record.title}');
            },
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('Share Record'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final catLower = record.category.toLowerCase();
    final color = catLower.contains('surg')
        ? scheme.primary
        : (catLower.contains('emerg') ? scheme.error : scheme.tertiary);
    final icon = catLower.contains('surg')
        ? Icons.medical_services_rounded
        : (catLower.contains('emerg')
            ? Icons.emergency_rounded
            : Icons.health_and_safety_rounded);

    return InkWell(
      borderRadius: AppRadius.brMd,
      onTap: () => _showRecordDetailsDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppIconSizes.sm,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.title,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ),
                        HealthCategoryChip(
                          label: record.category,
                          background: color.withValues(alpha: 0.15),
                          foreground: color,
                        ),
                      ],
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      record.recordDate.toIso8601String().split('T').first,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (record.diagnosis != null && record.diagnosis!.isNotEmpty) ...[
                      AppSpacing.vGapXs,
                      Text(
                        'Diagnosis: ${record.diagnosis}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.hGapSm,
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
