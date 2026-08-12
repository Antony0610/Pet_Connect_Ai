import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
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
              'Active Consultation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Bella • Golden Retriever',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () => context.push('/vet/patients/p1'),
            tooltip: 'View History',
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Consultation Draft Saved')),
              );
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
                  Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.flash_on, size: 14),
                        label: const Text('Templates'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // S - Subjective
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'S',
                label: 'Subjective (Owner Observations & History)',
                controller: _subjectiveController,
              ),
              const SizedBox(height: 12),

              // O - Objective
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'O',
                label: 'Objective (Vitals & Physical Exam)',
                controller: _objectiveController,
              ),
              const SizedBox(height: 12),

              // A - Assessment
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'A',
                label: 'Assessment (Diagnosis / Differential)',
                controller: _assessmentController,
              ),
              const SizedBox(height: 12),

              // P - Plan
              _buildSoapField(
                context,
                theme,
                colorScheme,
                letter: 'P',
                label: 'Plan (Treatment, Rx & Follow-Up)',
                controller: _planController,
              ),
              const SizedBox(height: 20),

              // Action Toolbar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.vaccines, size: 18),
                      label: const Text('Issue Rx'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Prescription Modal')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      text: 'Finalize Visit',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Consultation Finalized & Saved!'),
                          ),
                        );
                        context.go(RoutePaths.vetHome);
                      },
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      height: 42,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.pets, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bella (Golden Retriever)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Female, Spayed • 4y 2m • 28.5 kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppChip(
            label: 'Penicillin Allergy',
            backgroundColor: colorScheme.errorContainer,
            textColor: colorScheme.onErrorContainer,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'VetOps AI Clinical Assistant',
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
            title: 'Lyme Disease Risk',
            desc:
                'Endemic area; tick preventative lapsed 6 weeks ago. Suggest SNAP 4Dx Plus test.',
            icon: Icons.priority_high,
            iconColor: AppColors.warning,
          ),
          const SizedBox(height: 8),
          _buildAiSuggestionItem(
            theme,
            colorScheme,
            title: 'Routine Blood Panel',
            desc: 'Due for annual CBC/Chem panel based on age and baseline.',
            icon: Icons.science_outlined,
            iconColor: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Generate Draft Treatment Plan'),
              onPressed: () {},
            ),
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
}
