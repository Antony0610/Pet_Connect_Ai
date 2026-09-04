import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/treatment_plan.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:share_plus/share_plus.dart';

class VetTreatmentPlanScreen extends ConsumerStatefulWidget {
  final String? patientId;

  const VetTreatmentPlanScreen({super.key, this.patientId});

  @override
  ConsumerState<VetTreatmentPlanScreen> createState() =>
      _VetTreatmentPlanScreenState();
}

class _VetTreatmentPlanScreenState extends ConsumerState<VetTreatmentPlanScreen> {
  String _diagnosis = '';
  String _category = 'General Medicine';
  String _notes = '';
  int _progress = 0;
  String _stage1 = '';
  String _stage2 = '';
  String _stage3 = '';
  DateTime? _targetDate;

  void _openEditPlanDialog(String targetPetId, [TreatmentPlan? existingPlan]) async {
    final diagCtrl = TextEditingController(text: existingPlan?.title ?? _diagnosis);
    final notesCtrl = TextEditingController(text: existingPlan != null ? _notes : '');
    final stage1Ctrl = TextEditingController(
      text: existingPlan != null ? _stage1 : 'Initial symptom relief and medication',
    );
    final stage2Ctrl = TextEditingController(
      text: existingPlan != null ? _stage2 : 'Monitoring and environmental adjustments',
    );
    final stage3Ctrl = TextEditingController(
      text: existingPlan != null ? _stage3 : 'Clinical re-evaluation and tapering',
    );
    String selectedCat = existingPlan?.category ?? _category;
    int progressVal = existingPlan?.progressPercent ?? _progress;
    DateTime targetDateVal = existingPlan?.targetDate ?? _targetDate ?? DateTime.now().add(const Duration(days: 21));

    final categories = [
      'General Medicine',
      'Dermatology',
      'Surgery & Orthopedics',
      'Gastroenterology',
      'Cardiology',
      'Dentistry',
      'Preventive Care',
    ];

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(existingPlan != null ? 'Edit Clinical Treatment Plan' : 'Create Treatment Protocol'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: diagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis & Primary Condition *',
                      hintText: 'e.g. Acute Canine Gastroenteritis',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categories.contains(selectedCat) ? selectedCat : categories.first,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Specialty / Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Target Date Picker Row
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: targetDateVal,
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDlgState(() => targetDateVal = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available, color: Color(0xFF137A63), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Target Completion Date',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  DateFormat('EEEE, MMM dd, yyyy').format(targetDateVal),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_calendar_outlined, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stage1Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Stage 1 Milestone (Initial Therapy)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: stage2Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Stage 2 Milestone (Ongoing Care)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: stage3Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Stage 3 Milestone (Taper / Discharge)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Attending Clinician Directives & Goal',
                      hintText: 'e.g. Dietary reintroduction and electrolyte hydration',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recovery Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$progressVal%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF137A63))),
                    ],
                  ),
                  Slider(
                    value: progressVal.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: const Color(0xFF137A63),
                    label: '$progressVal%',
                    onChanged: (val) {
                      setDlgState(() => progressVal = val.toInt());
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save & Publish Plan'),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      final newDiag = diagCtrl.text.trim().isNotEmpty ? diagCtrl.text.trim() : 'Prescribed Care Protocol';
      final newNotes = notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : 'Monitor daily response.';
      final s1 = stage1Ctrl.text.trim().isNotEmpty ? stage1Ctrl.text.trim() : 'Active medication regimen';
      final s2 = stage2Ctrl.text.trim().isNotEmpty ? stage2Ctrl.text.trim() : 'Environmental management';
      final s3 = stage3Ctrl.text.trim().isNotEmpty ? stage3Ctrl.text.trim() : 'Follow-up consultation';

      setState(() {
        _diagnosis = newDiag;
        _notes = newNotes;
        _stage1 = s1;
        _stage2 = s2;
        _stage3 = s3;
        _category = selectedCat;
        _progress = progressVal;
        _targetDate = targetDateVal;
      });

      final plan = TreatmentPlan(
        id: existingPlan?.id ?? '',
        petId: targetPetId,
        title: newDiag,
        category: selectedCat,
        targetDate: targetDateVal,
        progressPercent: progressVal,
        status: progressVal >= 100 ? 'completed' : 'active',
        notes: '$newNotes\nStages: 1. $s1 | 2. $s2 | 3. $s3',
      );

      final repo = ref.read(vetRepositoryProvider);
      final result = await repo.saveTreatmentPlan(plan);
      await result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save to database: ${failure.message}')),
            );
          }
        },
        (_) async {
          // Log to progress history in SharedPreferences
          final prefs = ref.read(sharedPreferencesProvider);
          final historyKey = 'treatment_history_$targetPetId';
          final raw = prefs.getString(historyKey);
          final List<dynamic> list = raw != null ? (jsonDecode(raw) as List<dynamic>) : <dynamic>[];
          final profile = ref.read(currentUserProfileProvider).valueOrNull;
          final docName = profile?.fullName.isNotEmpty == true
              ? (profile!.fullName.startsWith('Dr.') ? profile.fullName : 'Dr. ${profile.fullName}')
              : 'Attending Clinician';

          list.insert(0, {
            'date': DateTime.now().toIso8601String(),
            'progress': progressVal,
            'notes': existingPlan != null ? 'Treatment protocol updated. Goal set to $progressVal%.' : 'Treatment protocol created and initiated.',
            'clinician': docName,
          });
          await prefs.setString(historyKey, jsonEncode(list));

          ref.invalidate(treatmentPlansProvider(targetPetId));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Treatment protocol saved & synchronized with pet passport!'),
                backgroundColor: Color(0xFF137A63),
              ),
            );
          }
        },
      );
    }
  }

  Future<void> _pickTargetDate(TreatmentPlan plan, String targetPetId) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: plan.targetDate ?? _targetDate ?? now.add(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
      final updatedPlan = plan.copyWith(targetDate: picked);
      final repo = ref.read(vetRepositoryProvider);
      await repo.saveTreatmentPlan(updatedPlan);

      // Log date update in history
      final prefs = ref.read(sharedPreferencesProvider);
      final historyKey = 'treatment_history_$targetPetId';
      final raw = prefs.getString(historyKey);
      final List<dynamic> list = raw != null ? (jsonDecode(raw) as List<dynamic>) : <dynamic>[];
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final docName = profile?.fullName.isNotEmpty == true
          ? (profile!.fullName.startsWith('Dr.') ? profile.fullName : 'Dr. ${profile.fullName}')
          : 'Attending Clinician';

      list.insert(0, {
        'date': DateTime.now().toIso8601String(),
        'progress': plan.progressPercent,
        'notes': 'Target completion date shifted to ${DateFormat("MMM dd, yyyy").format(picked)}.',
        'clinician': docName,
      });
      await prefs.setString(historyKey, jsonEncode(list));

      ref.invalidate(treatmentPlansProvider(targetPetId));
      if (mounted) {
        context.showSnackbar('✅ Target completion date updated to ${DateFormat("MMM dd, yyyy").format(picked)}');
      }
    }
  }

  void _openLogProgressDialog(TreatmentPlan plan, String targetPetId) async {
    int newProgress = plan.progressPercent;
    final noteCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.timeline_rounded, color: Color(0xFF137A63)),
              SizedBox(width: 8),
              Text('Log Clinical Progress'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recovery Progress:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$newProgress%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF137A63), fontSize: 16)),
                ],
              ),
              Slider(
                value: newProgress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: const Color(0xFF137A63),
                label: '$newProgress%',
                onChanged: (v) => setDlgState(() => newProgress = v.toInt()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Clinical Notes & Observations *',
                  hintText: 'e.g. Swelling reduced, appetite restored, continue oral therapy...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save & Record Log'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final noteText = noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : 'Progress evaluated at $newProgress%';
      final updatedPlan = plan.copyWith(
        progressPercent: newProgress,
        status: newProgress >= 100 ? 'completed' : 'active',
      );
      final repo = ref.read(vetRepositoryProvider);
      await repo.saveTreatmentPlan(updatedPlan);

      // Save to SharedPreferences history
      final prefs = ref.read(sharedPreferencesProvider);
      final historyKey = 'treatment_history_$targetPetId';
      final raw = prefs.getString(historyKey);
      final List<dynamic> list = raw != null ? (jsonDecode(raw) as List<dynamic>) : <dynamic>[];
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final docName = profile?.fullName.isNotEmpty == true
          ? (profile!.fullName.startsWith('Dr.') ? profile.fullName : 'Dr. ${profile.fullName}')
          : 'Attending Clinician';

      list.insert(0, {
        'date': DateTime.now().toIso8601String(),
        'progress': newProgress,
        'notes': noteText,
        'clinician': docName,
      });

      await prefs.setString(historyKey, jsonEncode(list));
      ref.invalidate(treatmentPlansProvider(targetPetId));
      setState(() {
        _progress = newProgress;
      });
      if (mounted) {
        context.showSnackbar('✅ Clinical progress log recorded successfully!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedPet = ref.watch(selectedPetProvider);
    final pets = ref.watch(petsProvider).valueOrNull ?? [];
    final fallbackId = selectedPet?.id ?? (pets.isNotEmpty ? pets.first.id : 'ca970bed-278a-45c3-99cd-1133bf0c23cc');
    final targetPetId = (widget.patientId != null &&
            widget.patientId!.isNotEmpty &&
            widget.patientId != 'p1')
        ? widget.patientId!
        : fallbackId;
    final plansAsync = ref.watch(treatmentPlansProvider(targetPetId));

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
              'Treatment Plan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _diagnosis.isNotEmpty ? '$_diagnosis ($_category)' : 'Clinical Protocol Workspace',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            onPressed: () => _openEditPlanDialog(targetPetId, plansAsync.valueOrNull?.firstOrNull),
            tooltip: 'Create / Edit Plan',
          ),
        ],
      ),
      body: SafeArea(
        child: plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading treatment plan: $e')),
          data: (existingPlans) {
            if (existingPlans.isEmpty) {
              return _buildEmptyPlanView(context, theme, colorScheme, targetPetId);
            }

            final plan = existingPlans.first;
            _diagnosis = plan.title;
            _category = plan.category;
            _progress = plan.progressPercent;
            _targetDate = plan.targetDate;

            final rawNotes = plan.notes ?? '';
            if (rawNotes.contains('Stages:')) {
              final parts = rawNotes.split('Stages:');
              _notes = parts.first.trim();
              final stageParts = parts.last.split('|');
              if (stageParts.isNotEmpty) _stage1 = stageParts[0].replaceAll(RegExp(r'^\s*1\.\s*'), '').trim();
              if (stageParts.length > 1) _stage2 = stageParts[1].replaceAll(RegExp(r'^\s*2\.\s*'), '').trim();
              if (stageParts.length > 2) _stage3 = stageParts[2].replaceAll(RegExp(r'^\s*3\.\s*'), '').trim();
            } else {
              _notes = rawNotes.isNotEmpty ? rawNotes : _notes;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Plan Title & Diagnosis Banner
                  _buildPlanHeader(context, theme, colorScheme, plan, targetPetId),
                  const SizedBox(height: 16),

                  // Step-by-Step Protocol Timeline
                  Text(
                    'Treatment Protocol Timeline',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProtocolStep(
                    context,
                    theme,
                    colorScheme,
                    stepNumber: '1',
                    badge: 'Active Stage • Current',
                    badgeColor: colorScheme.primary,
                    title: _stage1.isNotEmpty ? _stage1 : 'Therapeutic Stabilization',
                    desc: 'Administer prescribed regimen daily to manage acute symptoms and inflammation. Monitor for tolerance.',
                  ),
                  const SizedBox(height: 10),
                  _buildProtocolStep(
                    context,
                    theme,
                    colorScheme,
                    stepNumber: '2',
                    badge: 'Next Phase',
                    badgeColor: colorScheme.secondary,
                    title: _stage2.isNotEmpty ? _stage2 : 'Maintenance & Ongoing Care',
                    desc: 'Implement environmental and dietary controls based on clinical panel results.',
                  ),
                  const SizedBox(height: 10),
                  _buildProtocolStep(
                    context,
                    theme,
                    colorScheme,
                    stepNumber: '3',
                    badge: 'Milestone',
                    badgeColor: colorScheme.tertiary,
                    title: _stage3.isNotEmpty ? _stage3 : 'Clinical Discharge Evaluation',
                    desc: 'Clinical re-assessment and scheduled in-clinic follow-up to evaluate complete remission.',
                  ),
                  const SizedBox(height: 20),

                  // Home Care Owner Instructions Card
                  _buildHomeCareCard(context, theme, colorScheme, targetPetId),
                  const SizedBox(height: 16),

                  // Clinical Progress History Timeline
                  _buildProgressHistoryCard(context, theme, colorScheme, plan, targetPetId),
                  const SizedBox(height: 16),

                  // AI Prognosis & Recovery Tracking
                  _buildAiPrognosisCard(context, theme, colorScheme),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyPlanView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String targetPetId,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined, size: 48, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Treatment Protocol',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'There is currently no published clinical treatment plan for this patient. Create a structured care protocol to track recovery stages, milestones, and target completion dates.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openEditPlanDialog(targetPetId, null),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Create Treatment Protocol'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF137A63),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TreatmentPlan plan,
    String targetPetId,
  ) {
    final now = DateTime.now();
    final targetDate = plan.targetDate ?? _targetDate;
    final daysRemaining = targetDate?.difference(now).inDays;
    final countdownStr = daysRemaining != null
        ? (daysRemaining > 0
            ? '$daysRemaining days remaining'
            : (daysRemaining == 0 ? 'Target is Today' : 'Overdue by ${-daysRemaining} days'))
        : 'Set Target Date';

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppChip(
                label: plan.category.toUpperCase(),
                backgroundColor: colorScheme.primary,
                textColor: colorScheme.onPrimary,
              ),
              Row(
                children: [
                  Text(
                    '${plan.progressPercent}% Complete',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _openLogProgressDialog(plan, targetPetId),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_chart_rounded, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Log',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _notes.isNotEmpty ? _notes : 'Clinical protocol monitored by attending practitioner.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Target Date Chip with edit button
          InkWell(
            onTap: () => _pickTargetDate(plan, targetPetId),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    targetDate != null
                        ? 'Target: ${DateFormat("MMM dd, yyyy").format(targetDate)} • $countdownStr'
                        : 'Tap to set Target Completion Date',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 12, color: colorScheme.primary.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: plan.progressPercent / 100,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHistoryCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TreatmentPlan plan,
    String targetPetId,
  ) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final historyKey = 'treatment_history_$targetPetId';
    final raw = prefs.getString(historyKey);
    final List<dynamic> list = raw != null ? (jsonDecode(raw) as List<dynamic>) : <dynamic>[];

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
                  Icon(Icons.history_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Clinical Progress History',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _openLogProgressDialog(plan, targetPetId),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Entry', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No milestone progress entries logged yet.\nTap "Add Entry" to record clinician observations.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length > 5 ? 5 : list.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (ctx, idx) {
                final item = list[idx] as Map<String, dynamic>;
                final dateStr = item['date'] != null
                    ? DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.tryParse(item['date'] as String? ?? '') ?? DateTime.now())
                    : 'Recently';
                final progress = item['progress'] ?? plan.progressPercent;
                final notes = item['notes']?.toString() ?? 'Clinical observation recorded.';
                final clinician = item['clinician']?.toString() ?? 'Attending Clinician';

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$progress%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notes,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$clinician • $dateStr',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProtocolStep(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String stepNumber,
    required String badge,
    required Color badgeColor,
    required String title,
    required String desc,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: badgeColor,
            child: Text(
              stepNumber,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppChip(
                      label: badge,
                      backgroundColor: badgeColor.withValues(alpha: 0.15),
                      textColor: badgeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeCareCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String targetPetId,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.home_repair_service_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Guardian Care Guidelines',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Medication & Bathing Protocol:',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Administer prescribed medication per dosing schedule. Maintain skin cleansing protocol and monitor appetite and activity daily.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Download PDF Sheet'),
            onPressed: () async {
              try {
                final dateFormat = DateFormat('MMM dd, yyyy');
                final nowStr = dateFormat.format(DateTime.now());
                final primaryColor = PdfColor.fromHex('#137A63');
                final secondaryColor = PdfColor.fromHex('#4F378A');
                final lightBg = PdfColor.fromHex('#F8FAFC');
                final borderColor = PdfColor.fromHex('#CBD5E1');

                final doc = pw.Document(title: 'Veterinary Home Care Treatment Protocol');
                doc.addPage(
                  pw.MultiPage(
                    pageFormat: PdfPageFormat.a4,
                    margin: const pw.EdgeInsets.all(28),
                    header: (pw.Context ctx) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        margin: const pw.EdgeInsets.only(bottom: 14),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: primaryColor, width: 2.5),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'CLINICAL HOME CARE TREATMENT PROTOCOL',
                                  style: pw.TextStyle(
                                    color: primaryColor,
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'PetConnect AI Veterinary Network | Attending Clinic Prescription Sheet',
                                  style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8.5),
                                ),
                              ],
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('#E6F4F1'),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                border: pw.Border.all(color: primaryColor, width: 0.8),
                              ),
                              child: pw.Text(
                                'ISSUED: $nowStr',
                                style: pw.TextStyle(color: primaryColor, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    footer: (pw.Context ctx) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(top: 14),
                        padding: const pw.EdgeInsets.only(top: 8),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('PetConnect AI Veterinary Protocol Sheet | For Guardian Reference', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                          ],
                        ),
                      );
                    },
                    build: (pw.Context ctx) {
                      return [
                        // ── 1. DIAGNOSIS & CASE SUMMARY ───────────────────────
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: lightBg,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                            border: pw.Border.all(color: borderColor, width: 0.8),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('PRIMARY DIAGNOSIS / CLINICAL CONDITION', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                                  pw.SizedBox(height: 2),
                                  pw.Text(_diagnosis, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                                  pw.SizedBox(height: 2),
                                  pw.Text('Specialty: $_category', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                                ],
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('#E0E7FF'),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                  border: pw.Border.all(color: secondaryColor, width: 0.8),
                                ),
                                child: pw.Text('$_progress% Complete', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: secondaryColor)),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),

                        // ── 2. CLINICAL PROTOCOL STAGES ──────────────────────
                        pw.Text('CLINICAL PROTOCOL PHASES & TARGETS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.SizedBox(height: 6),
                        pw.TableHelper.fromTextArray(
                          border: pw.TableBorder.all(color: borderColor, width: 0.5),
                          headerStyle: const pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8.5),
                          headerDecoration: pw.BoxDecoration(color: primaryColor),
                          cellStyle: const pw.TextStyle(fontSize: 8),
                          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          headers: ['Stage', 'Milestone Objective', 'Status'],
                          data: [
                            ['Phase 1', _stage1, _progress >= 33 ? 'Completed' : 'Active Stage'],
                            ['Phase 2', _stage2, _progress >= 66 ? 'Completed' : (_progress >= 33 ? 'Active Stage' : 'Pending')],
                            ['Phase 3', _stage3, _progress >= 100 ? 'Achieved' : 'Scheduled Goal'],
                          ],
                        ),
                        pw.SizedBox(height: 12),

                        // ── 3. DAILY MONITORING CHECKLIST ────────────────────
                        pw.Text('DAILY CLINICAL MONITORING CHECKLIST', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: secondaryColor)),
                        pw.SizedBox(height: 6),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: lightBg,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                            border: pw.Border.all(color: borderColor, width: 0.6),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(children: [pw.Text('[ ] ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Body Temperature: Normal baseline is 101.0-102.5 deg F (38.3-39.2 deg C)', style: const pw.TextStyle(fontSize: 8.5))]),
                              pw.SizedBox(height: 4),
                              pw.Row(children: [pw.Text('[ ] ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Hydration & Appetite: Ensure complete water intake and normal food consumption', style: const pw.TextStyle(fontSize: 8.5))]),
                              pw.SizedBox(height: 4),
                              pw.Row(children: [pw.Text('[ ] ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Incision / Wound / Skin Inspection: Check daily for redness, swelling, or changes', style: const pw.TextStyle(fontSize: 8.5))]),
                              pw.SizedBox(height: 4),
                              pw.Row(children: [pw.Text('[ ] ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Elimination Habits: Confirm regular urination and normal stool consistency', style: const pw.TextStyle(fontSize: 8.5))]),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),

                        // ── 4. ATTENDING VETERINARIAN NOTES ────────────────────
                        pw.Text('ATTENDING CLINICAL DIRECTIVES & PROTOCOL NOTES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.SizedBox(height: 6),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: lightBg,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                            border: pw.Border.all(color: borderColor, width: 0.6),
                          ),
                          child: pw.Text(_notes, style: const pw.TextStyle(fontSize: 9, height: 1.35, color: PdfColors.grey900)),
                        ),
                        pw.SizedBox(height: 12),

                        // ── 5. FOLLOW-UP & EMERGENCY RED FLAGS ───────────────
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#FEF2F2'),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                            border: pw.Border.all(color: PdfColor.fromHex('#FCA5A5'), width: 0.8),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('[!] CRITICAL RED FLAGS - CONTACT CLINIC IMMEDIATELY IF OBSERVED:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#991B1B'))),
                              pw.SizedBox(height: 3),
                              pw.Text('- Persistent vomiting or refusal to drink water for >12 hours.\n- Pale, blue, or muddy gum color.\n- Labored respiration, extreme lethargy, or inability to stand.', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#7F1D1D'))),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                );

                final bytes = await doc.save();
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}/Home_Care_Treatment_Protocol.pdf');
                await file.writeAsBytes(bytes, flush: true);

                // Persist treatment plan PDF to pet_documents & health_records
                final client = ref.read(supabaseClientProvider);
                final user = client.auth.currentUser;
                await client.from('pet_documents').insert({
                  'pet_id': targetPetId,
                  'document_name': 'Treatment Protocol - $_diagnosis.pdf',
                  'document_type': 'Treatment Plan',
                  'file_path': file.path,
                  'file_size': bytes.length,
                  'mime_type': 'application/pdf',
                  if (user != null) 'uploaded_by': user.id,
                  'created_at': DateTime.now().toIso8601String(),
                }).catchError((_) => null);

                await client.from('health_records').insert({
                  'pet_id': targetPetId,
                  'record_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'category': 'Treatment Plan',
                  'title': 'Treatment Protocol: $_diagnosis',
                  'notes': _notes,
                  'diagnosis': _diagnosis,
                  'treatment': 'Step-by-step clinical protocol (Recovery progress: $_progress%)',
                  'veterinarian_name': 'Dr. Prithiviraj',
                  'created_at': DateTime.now().toIso8601String(),
                }).catchError((_) => null);

                // ignore: deprecated_member_use
                await Share.shareXFiles(
                  [XFile(file.path, mimeType: 'application/pdf')],
                  text: '📋 Attached is the Veterinary Treatment Protocol (PDF).',
                  subject: 'Treatment Protocol (PDF)',
                );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not generate treatment protocol PDF.')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiPrognosisCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: colorScheme.tertiary, size: 22),
              const SizedBox(width: 8),
              Text(
                'AI Prognosis Tracking',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Clinical Remission Index:', style: theme.textTheme.bodySmall),
              Text(
                '$_progress% (On Target)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Therapeutic Tolerance:', style: theme.textTheme.bodySmall),
              AppChip(
                label: 'Optimal',
                backgroundColor: colorScheme.tertiaryContainer,
                textColor: colorScheme.onTertiaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Expected clinical remission within target timeframe with ongoing adherence.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
