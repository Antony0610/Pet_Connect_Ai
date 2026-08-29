import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/patient_queue_notifier.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

/// **Interactive Patient Triage Queue** — `/vet/queue`.
///
/// Live patient flow manager supporting clinical status transitions,
/// urgency triage prioritization, vital metrics telemetry, and direct
/// consultation workspace routing.
class PatientQueueScreen extends ConsumerStatefulWidget {
  const PatientQueueScreen({super.key});

  @override
  ConsumerState<PatientQueueScreen> createState() => _PatientQueueScreenState();
}

class _PatientQueueScreenState extends ConsumerState<PatientQueueScreen> {
  String _searchQuery = '';
  TriageStatus? _selectedStatusFilter;
  TriagePriority? _selectedPriorityFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allPatients = ref.watch(patientQueueStateProvider);

    final filtered = allPatients.where((patient) {
      final matchesQuery = _searchQuery.isEmpty ||
          patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          patient.breedAge.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          patient.ownerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          patient.reason.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatusFilter == null || patient.status == _selectedStatusFilter;

      final matchesPriority = _selectedPriorityFilter == null ||
          patient.priority == _selectedPriorityFilter;

      return matchesQuery && matchesStatus && matchesPriority;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RoutePaths.vetHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Triage Queue',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${filtered.length} active patient${filtered.length == 1 ? "" : "s"} in pipeline',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Admit Patient to Queue',
            onPressed: () => _showAddPatientDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search & Filter Controls ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  AppTextField(
                    hintText: 'Search patient, breed, owner, or symptom…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  AppSpacing.vGapSm,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All Stages',
                          isSelected: _selectedStatusFilter == null,
                          onSelected: () =>
                              setState(() => _selectedStatusFilter = null),
                        ),
                        AppSpacing.hGapXs,
                        for (final status in TriageStatus.values) ...[
                          _buildFilterChip(
                            label: status.label,
                            isSelected: _selectedStatusFilter == status,
                            onSelected: () =>
                                setState(() => _selectedStatusFilter = status),
                          ),
                          AppSpacing.hGapXs,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Active Patient Cards List ──────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 48,
                            color: colorScheme.primary.withValues(alpha: 0.6),
                          ),
                          AppSpacing.vGapSm,
                          Text(
                            'Queue is clear',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'No patients match the selected filter criteria.',
                            style: theme.textTheme.bodySmall?.copyWith(
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
                      separatorBuilder: (_, __) => AppSpacing.vGapSm,
                      itemBuilder: (ctx, index) {
                        final patient = filtered[index];
                        return _buildPatientQueueCard(context, patient);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPatientDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Check-In Patient'),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onSelected();
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPatientQueueCard(BuildContext context, TriagePatientItem patient) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (priorityColor, priorityBg) = _getPriorityColors(patient.priority);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    patient.species.toLowerCase().contains('cat')
                        ? Icons.pets
                        : Icons.pets_rounded,
                    color: priorityColor,
                  ),
                ),
              ),
              AppSpacing.hGapMd,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: priorityBg,
                            borderRadius: AppRadius.brPill,
                          ),
                          child: Text(
                            patient.priority.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      patient.breedAge,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,

          // Reason Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              patient.reason,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
              ),
            ),
          ),
          AppSpacing.vGapSm,

          // Vitals & Owner Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (patient.temperatureC != null) ...[
                    Icon(Icons.thermostat_rounded, size: 14, color: colorScheme.primary),
                    Text(
                      ' ${patient.temperatureC}°C',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.hGapSm,
                  ],
                  if (patient.heartRateBpm != null) ...[
                    const Icon(Icons.favorite_rounded, size: 14, color: Colors.redAccent),
                    Text(
                      ' ${patient.heartRateBpm} bpm',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => ExternalActions.callPhoneNumber(patient.ownerPhone),
                child: Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 14, color: colorScheme.primary),
                    AppSpacing.hGapXs,
                    Text(
                      patient.ownerName,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,

          // Action Buttons Bar
          Row(
            children: [
              // Advance Status Action
              if (patient.status != TriageStatus.discharged) ...[
                Expanded(
                  child: AppButton.outlined(
                    label: _getNextStageLabel(patient.status),
                    icon: _getNextStageIcon(patient.status),
                    onPressed: () async {
                      await HapticFeedback.mediumImpact();
                      ref
                          .read(patientQueueStateProvider.notifier)
                          .advanceStatus(patient.id);
                      if (context.mounted) {
                        context.showSnackbar(
                          '✓ ${patient.name} advanced to ${_getNextStageLabel(patient.status)}',
                        );
                      }
                    },
                  ),
                ),
                AppSpacing.hGapSm,
              ],

              // Direct Consultation Action
              Expanded(
                child: AppButton.filled(
                  label: 'Consultation',
                  icon: Icons.medical_services_outlined,
                  onPressed: () {
                    context.push(
                      '${RoutePaths.vetConsultation}?appointmentId=${patient.appointmentId}',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPatientDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final speciesCtrl = TextEditingController(text: 'Canine');
    final reasonCtrl = TextEditingController();
    final ownerNameCtrl = TextEditingController();
    final ownerPhoneCtrl = TextEditingController();
    var priority = TriagePriority.routine;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Admit Patient to Triage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapMd,
                AppTextField(controller: nameCtrl, labelText: 'Pet Name (e.g. Charlie)'),
                AppSpacing.vGapSm,
                AppTextField(controller: breedCtrl, labelText: 'Breed & Age (e.g. Beagle • 3y)'),
                AppSpacing.vGapSm,
                AppTextField(controller: reasonCtrl, labelText: 'Clinical Reason / Chief Complaint'),
                AppSpacing.vGapSm,
                AppTextField(controller: ownerNameCtrl, labelText: 'Owner Full Name'),
                AppSpacing.vGapSm,
                AppTextField(controller: ownerPhoneCtrl, labelText: 'Owner Contact Phone'),
                AppSpacing.vGapMd,
                const Text('Triage Urgency Priority:', style: TextStyle(fontWeight: FontWeight.bold)),
                AppSpacing.vGapXs,
                SegmentedButton<TriagePriority>(
                  segments: const [
                    ButtonSegment(value: TriagePriority.critical, label: Text('🚨 Critical')),
                    ButtonSegment(value: TriagePriority.urgent, label: Text('⚠️ Urgent')),
                    ButtonSegment(value: TriagePriority.routine, label: Text('🩺 Routine')),
                  ],
                  selected: {priority},
                  onSelectionChanged: (set) => setModalState(() => priority = set.first),
                ),
                AppSpacing.vGapLg,
                AppButton.filled(
                  label: 'Add to Triage Pipeline',
                  icon: Icons.check,
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    ref.read(patientQueueStateProvider.notifier).addPatient(
                          name: nameCtrl.text.trim(),
                          breedAge: breedCtrl.text.trim().isNotEmpty
                              ? breedCtrl.text.trim()
                              : 'Unknown Breed',
                          species: speciesCtrl.text.trim(),
                          priority: priority,
                          reason: reasonCtrl.text.trim().isNotEmpty
                              ? reasonCtrl.text.trim()
                              : 'General Examination',
                          ownerName: ownerNameCtrl.text.trim().isNotEmpty
                              ? ownerNameCtrl.text.trim()
                              : 'Verified Client',
                          ownerPhone: ownerPhoneCtrl.text.trim().isNotEmpty
                              ? ownerPhoneCtrl.text.trim()
                              : '+1 (555) 000-0000',
                        );
                    Navigator.of(ctx).pop();
                    context.showSnackbar('✓ Added ${nameCtrl.text.trim()} to patient queue');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static (Color, Color) _getPriorityColors(TriagePriority priority) {
    switch (priority) {
      case TriagePriority.critical:
        return (Colors.red.shade700, Colors.red.shade50);
      case TriagePriority.urgent:
        return (Colors.orange.shade800, Colors.orange.shade50);
      case TriagePriority.routine:
        return (Colors.blue.shade700, Colors.blue.shade50);
    }
  }

  static String _getNextStageLabel(TriageStatus current) {
    switch (current) {
      case TriageStatus.waiting:
        return 'Call to Triage';
      case TriageStatus.inTriage:
        return 'Send to Vet';
      case TriageStatus.inConsultation:
        return 'Discharge';
      case TriageStatus.discharged:
        return 'Completed';
    }
  }

  static IconData _getNextStageIcon(TriageStatus current) {
    switch (current) {
      case TriageStatus.waiting:
        return Icons.forward_to_inbox_rounded;
      case TriageStatus.inTriage:
        return Icons.arrow_forward_rounded;
      case TriageStatus.inConsultation:
        return Icons.done_all_rounded;
      case TriageStatus.discharged:
        return Icons.check_circle_outline;
    }
  }
}
