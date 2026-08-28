import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A faithful Flutter rendering of the frozen Stitch **AI Diagnostic Center**
/// (Light Theme design authority, ID `c883012ed473494bb6e61222ffe0e472`).
///
/// Diagnostic workspace providing symptom triage, risk severity classification,
/// AI recommendations, and direct veterinary escalation.
class AiDiagnosticCenterScreen extends ConsumerStatefulWidget {
  const AiDiagnosticCenterScreen({super.key});

  @override
  ConsumerState<AiDiagnosticCenterScreen> createState() =>
      _AiDiagnosticCenterScreenState();
}

class _AiDiagnosticCenterScreenState
    extends ConsumerState<AiDiagnosticCenterScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedCategory = 'Skin & Coat';
  String _selectedDuration = '< 24 Hours';

  final List<String> _categories = const [
    'Skin & Coat',
    'Digestive',
    'Behavior & Mood',
    'Mobility',
    'Eye & Ear',
  ];

  final List<String> _durations = const [
    '< 24 Hours',
    '1–3 Days',
    '1+ Week',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final allPets = ref.watch(petsProvider).asData?.value;
    final pet = selectedPet ?? (allPets != null && allPets.isNotEmpty ? allPets.first : null);
    final petName = pet?.name ?? 'Companion';

    final categoryData = _getCategoryDetails(_selectedCategory, petName, _selectedDuration);

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'AI Diagnostic Center',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Subtitle & Category Chips ──────────────────────
                Text(
                  'AI Triage Workspace: Select symptom category and duration to evaluate triage risk for $petName.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapMd,

                // Symptom Category Chips
                Text(
                  'Symptom Category',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                AppSpacing.vGapXs,
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: scheme.primary,
                          backgroundColor: scheme.surfaceContainerHigh,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurface,
                            fontWeight: AppTypography.semiBold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AppSpacing.vGapMd,

                // Symptom Duration Selector
                Text(
                  'Symptom Duration',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                AppSpacing.vGapXs,
                Row(
                  children: _durations.map((dur) {
                    final isSelected = _selectedDuration == dur;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        avatar: Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: isSelected ? scheme.onPrimary : scheme.primary,
                        ),
                        label: Text(dur),
                        selected: isSelected,
                        selectedColor: scheme.primary,
                        backgroundColor: scheme.surfaceContainerHigh,
                        labelStyle: TextStyle(
                          color: isSelected ? scheme.onPrimary : scheme.onSurface,
                          fontWeight: AppTypography.semiBold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedDuration = dur);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── Diagnostic Hero Result Card ────────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.healing,
                            color: scheme.primary,
                            size: AppIconSizes.md,
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'Active Assessment: $petName',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: Text(categoryData.riskLevel),
                            backgroundColor: scheme.tertiaryContainer,
                            labelStyle: TextStyle(
                              color: scheme.onTertiaryContainer,
                              fontWeight: AppTypography.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      Text(
                        'Primary Condition: ${categoryData.primaryCondition}',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        categoryData.summary,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      AppSpacing.vGapLg,

                      // ── Probability Breakdown List ───────────────
                      const SectionHeader(title: 'Differential Predictions'),
                      AppSpacing.vGapSm,
                      for (final diff in categoryData.differentials) ...[
                        _buildProbabilityRow(
                          context,
                          label: diff.label,
                          percent: diff.percent,
                        ),
                        AppSpacing.vGapXs,
                      ],
                      AppSpacing.vGapMd,

                      // ── Escalation Action Buttons ────────────────
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.filled(
                              onPressed: () =>
                                  context.goNamed(RouteNames.ownerAiReports),
                              child: const Text('Generate PDF Report'),
                            ),
                          ),
                          AppSpacing.hGapSm,
                          AppButton.outlined(
                            onPressed: () =>
                                context.goNamed(RouteNames.ownerAiChat),
                            child: const Text('Consult AI Chat'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Veterinary Escalation Banner ───────────────────
                AppCard(
                  backgroundColor: scheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_hospital_outlined,
                        color: scheme.primary,
                        size: 28,
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need Professional Confirmation?',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            Text(
                              'Share this diagnostic report directly with your clinic.',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppButton.text(
                        onPressed: () {
                          final shareText = '''
🩺 PetConnect AI Triage Assessment
Companion: $petName
Symptom Category: $_selectedCategory
Reported Duration: $_selectedDuration
Assessed Risk Level: ${categoryData.riskLevel}
Primary Condition: ${categoryData.primaryCondition}

Summary:
${categoryData.summary}

Differential Predictions:
${categoryData.differentials.map((d) => '• ${d.label}: ${d.percent}').join('\n')}
''';
                          ExternalActions.shareText(shareText, subject: 'AI Diagnostic Assessment: $petName');
                        },
                        child: const Text('Share Record'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProbabilityRow(
    BuildContext context, {
    required String label,
    required String percent,
  }) {
    final scheme = context.colorScheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
        Text(
          percent,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: AppTypography.bold,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }

  _CategoryDiagnosis _getCategoryDetails(String category, String petName, String duration) {
    final isProlonged = duration == '1+ Week';
    final isModerate = duration == '1–3 Days';

    final risk = isProlonged ? 'ELEVATED RISK' : (isModerate ? 'MODERATE RISK' : 'LOW RISK');

    switch (category) {
      case 'Digestive':
        return _CategoryDiagnosis(
          riskLevel: risk,
          primaryCondition: isProlonged ? 'Chronic Gastroenteritis / Food Allergy' : 'Mild Dietary Indiscretion',
          summary: isProlonged
              ? 'Symptom match score: 92% for $petName. Persistent digestive disturbance over 7 days requires in-person clinical bloodwork & fecal testing.'
              : (isModerate
                  ? 'Symptom match score: 87% for $petName. 1–3 day digestive upset. Maintain hydration and provide bland boiled chicken & rice diet.'
                  : 'Symptom match score: 85% for $petName. Recent food transition or rich snack ingestion suspected. Hydration levels appear stable.'),
          differentials: isProlonged
              ? const [
                  _Differential('Chronic Gastroenteropathy', '92%'),
                  _Differential('Inflammatory Bowel Disease', '74%'),
                  _Differential('Parasitic Enteritis', '58%'),
                ]
              : const [
                  _Differential('Dietary Indiscretion', '85%'),
                  _Differential('Acute Gastritis', '60%'),
                  _Differential('Food Sensitivity', '38%'),
                ],
        );
      case 'Behavior & Mood':
        return _CategoryDiagnosis(
          riskLevel: isProlonged ? 'MODERATE RISK' : 'LOW RISK',
          primaryCondition: isProlonged ? 'Chronic Anxiety / Neuro-Discomfort' : 'Environmental & Routine Adaptation',
          summary: isProlonged
              ? 'Symptom match score: 88% for $petName. Behavioral change lasting over 1 week warrants ruling out occult orthopedic or metabolic discomfort.'
              : 'Symptom match score: 82% for $petName. Restlessness or vocalization aligned with recent schedule change or mild separation stress.',
          differentials: const [
            _Differential('Separation Stress', '82%'),
            _Differential('Environmental Restlessness', '55%'),
            _Differential('Under-Enrichment', '35%'),
          ],
        );
      case 'Mobility':
        return _CategoryDiagnosis(
          riskLevel: risk,
          primaryCondition: isProlonged ? 'Osteoarthritis / Joint Inflammation' : 'Post-Exercise Muscular Fatigue',
          summary: isProlonged
              ? 'Symptom match score: 90% for $petName. Persistent gait irregularity > 7 days indicates chronic joint wear or ligament strain. Vet exam advised.'
              : 'Symptom match score: 80% for $petName. Minor stiffness following vigorous exercise; no localized joint heat or acute lameness reported.',
          differentials: isProlonged
              ? const [
                  _Differential('Osteoarthritis Progression', '90%'),
                  _Differential('Cruciate Ligament Strain', '72%'),
                  _Differential('Lumbosacral Spondylosis', '54%'),
                ]
              : const [
                  _Differential('Muscular Fatigue', '80%'),
                  _Differential('Joint Stiffness', '58%'),
                  _Differential('Soft Tissue Strain', '32%'),
                ],
        );
      case 'Eye & Ear':
        return _CategoryDiagnosis(
          riskLevel: risk,
          primaryCondition: isProlonged ? 'Secondary Bacterial Conjunctivitis / Otitis' : 'Mild Environmental Conjunctival Irritation',
          summary: isProlonged
              ? 'Symptom match score: 91% for $petName. Epiphora or otic discharge persisting > 7 days risks secondary infection. Topical meds needed.'
              : 'Symptom match score: 84% for $petName. Clear watery epiphora likely triggered by dust or pollen exposure. Corneal clarity intact.',
          differentials: isProlonged
              ? const [
                  _Differential('Secondary Bacterial Otitis/Conjunctivitis', '91%'),
                  _Differential('Corneal Ulceration Risk', '68%'),
                  _Differential('Foreign Body Irritation', '49%'),
                ]
              : const [
                  _Differential('Environmental Epiphora', '84%'),
                  _Differential('Otic Moisture Irritation', '62%'),
                  _Differential('Seasonal Allergy', '40%'),
                ],
        );
      case 'Skin & Coat':
      default:
        return _CategoryDiagnosis(
          riskLevel: risk,
          primaryCondition: isProlonged ? 'Secondary Pyoderma / Severe Atopy' : 'Seasonal Allergic Dermatitis',
          summary: isProlonged
              ? 'Symptom match score: 93% for $petName. Chronic itching and erythema > 1 week frequently leads to secondary staph/malassezia infection.'
              : 'Symptom match score: 88% for $petName. Environmental pollen or flea allergy suspected. No immediate emergency indicators present.',
          differentials: isProlonged
              ? const [
                  _Differential('Secondary Pyoderma / Yeast Dermatitis', '93%'),
                  _Differential('Severe Atopic Dermatitis', '78%'),
                  _Differential('Flea Infestation Reaction', '61%'),
                ]
              : const [
                  _Differential('Seasonal Dermatitis', '88%'),
                  _Differential('Flea Allergy Reaction', '64%'),
                  _Differential('Contact Sensitivity', '41%'),
                ],
        );
    }
  }
}

class _CategoryDiagnosis {
  const _CategoryDiagnosis({
    required this.riskLevel,
    required this.primaryCondition,
    required this.summary,
    required this.differentials,
  });

  final String riskLevel;
  final String primaryCondition;
  final String summary;
  final List<_Differential> differentials;
}

class _Differential {
  const _Differential(this.label, this.percent);
  final String label;
  final String percent;
}
