import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_dosage_calculator_modal.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/inputs/app_text_field.dart';

class ConsultationWorkspaceScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const ConsultationWorkspaceScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<ConsultationWorkspaceScreen> createState() =>
      _ConsultationWorkspaceScreenState();
}

class _ConsultationWorkspaceScreenState
    extends ConsumerState<ConsultationWorkspaceScreen> {
  final TextEditingController _subjectiveController = TextEditingController(
    text:
        'Owner reports lethargy and reduced appetite for 2 days. No vomiting or diarrhea.',
  );
  final TextEditingController _objectiveController = TextEditingController(
    text:
        'T: 38.5°C, HR: 88 bpm, RR: 24 brpm, Wt: 28.5 kg. Mild abdominal sensitivity.',
  );
  final TextEditingController _assessmentController = TextEditingController(
    text: 'Suspected mild gastroenteritis vs early Lyme flare.',
  );
  final TextEditingController _planController = TextEditingController(
    text:
        '1. Order SNAP 4Dx Plus test.\n2. Prescribe Probiotic & Bland Diet.\n3. Re-check in 48 hrs.',
  );

  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    super.dispose();
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
              'Active Consultation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Bella • Golden Retriever (28.5 kg)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Clinical SOAP Scribe',
            onPressed: () => _showAiSoapScribeModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Rx Dosage Calculator',
            onPressed: () {
              VetDosageCalculatorModal.show(
                context,
                initialWeightKg: 28.5,
                initialSpecies: 'Canine',
                onApplyDosage: (dosageInstruction) {
                  setState(() {
                    _planController.text =
                        '${_planController.text}\n• $dosageInstruction';
                  });
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () {
              context.showSnackbar('✓ Consultation draft saved to EMR');
            },
            tooltip: 'Save Draft',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Quick Context Banner
              _buildPatientBanner(context, theme, colorScheme),
              const SizedBox(height: 16),

              // AI Clinical Assistant Insights
              _buildAiAssistantSection(context, theme, colorScheme),
              const SizedBox(height: 20),

              // SOAP Notes Editor Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SOAP Clinical Notes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Auto-Scribe'),
                    onPressed: () => _showAiSoapScribeModal(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // S: Subjective
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'S',
                label: 'Subjective (History & Chief Complaint)',
                controller: _subjectiveController,
              ),
              const SizedBox(height: 12),

              // O: Objective
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'O',
                label: 'Objective (Vitals & Physical Exam)',
                controller: _objectiveController,
              ),
              const SizedBox(height: 12),

              // A: Assessment
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'A',
                label: 'Assessment (Differential Diagnoses)',
                controller: _assessmentController,
              ),
              const SizedBox(height: 12),

              // P: Plan
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'P',
                label: 'Plan (Diagnostics, Rx & Home Care)',
                controller: _planController,
              ),
              const SizedBox(height: 24),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      label: 'Rx Prescription',
                      icon: Icons.medication_outlined,
                      onPressed: () => context.push(RoutePaths.vetPrescription),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.filled(
                      label: 'Complete & Bill',
                      icon: Icons.check_circle_outline,
                      onPressed: () {
                        context.showSnackbar('✓ Consultation finalized and added to Health Passport');
                        context.push(RoutePaths.vetTreatmentPlan);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              'B',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Bella',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Text(
                        'CANINE • 3Y',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Owner: Sarah Jenkins • +1 (555) 789-0123',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Alerts: Penicillin allergy • Last Visit: 42 days ago',
                  style: TextStyle(fontSize: 11, color: colorScheme.error, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistantSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      color: colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Clinical Diagnostic Co-Pilot',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAiSuggestionItem(
            theme,
            colorScheme,
            title: 'Diagnostic Recommendation',
            desc: 'Consider SNAP 4Dx Plus test and baseline serum biochemistry (ALT, ALP, Creatinine).',
            icon: Icons.biotech_outlined,
            iconColor: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildAiSuggestionItem(
            theme,
            colorScheme,
            title: 'Contraindication Guard',
            desc: 'Patient has Penicillin allergy recorded. Avoid Amoxicillin/Clavamox formulations.',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestionItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String desc,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    );
  }

  Widget _buildSoapField(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String letter,
    required String label,
    required TextEditingController controller,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  letter,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: controller,
            maxLines: 3,
            hintText: 'Enter $label notes...',
          ),
        ],
      ),
    );
  }

  void _showAiSoapScribeModal(BuildContext context) {
    final scribeInputCtrl = TextEditingController(
      text: 'Bella presented with 2-day lethargy and decreased appetite. Temp 38.6, HR 92 bpm, palpation shows mild cranial abdominal discomfort. Likely dietary indiscretion or early gastritis. Order basic bloods, start Cerenia and gastroprotectant, feed boiled chicken and rice.',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                AppSpacing.hGapSm,
                Text(
                  'AI Clinical SOAP Scribe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapXs,
            const Text(
              'Paste raw clinical dictation or quick notes. AI will structure into SOAP fields.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            AppSpacing.vGapMd,
            AppTextField(
              controller: scribeInputCtrl,
              labelText: 'Clinical Notes / Dictation',
              maxLines: 4,
            ),
            AppSpacing.vGapLg,
            AppButton.filled(
              label: 'Structure & Insert into SOAP',
              icon: Icons.bolt_rounded,
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _subjectiveController.text = 'Patient presented with reported lethargy and decreased appetite over the past 48 hours. Owner notes no overt emesis witnessed.';
                  _objectiveController.text = 'T: 38.6°C, HR: 92 bpm, RR: 22 brpm, Wt: 28.5 kg. Normal heart and lung sounds. Mild discomfort on cranial abdominal palpation.';
                  _assessmentController.text = 'Acute mild gastroenteritis secondary to suspected dietary indiscretion. Low index of suspicion for systemic obstruction.';
                  _planController.text = '1. Order CBC and Serum Biochemistry profile.\n2. Cerenia (Maropitant) 1 mg/kg SQ once.\n3. Bland gastrointestinal diet for 3 days.\n4. Re-evaluate if anorexia persists >24h.';
                });
                Navigator.of(ctx).pop();
                context.showSnackbar('✓ SOAP structured and auto-filled into consultation workspace!');
              },
            ),
          ],
        ),
      ),
    );
  }
}
