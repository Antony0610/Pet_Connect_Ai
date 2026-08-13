import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
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

  final List<String> _categories = const [
    'Skin & Coat',
    'Digestive',
    'Behavior & Mood',
    'Mobility',
    'Eye & Ear',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

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
                  'AI Triage Workspace: Select symptom category to view probability assessments.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,
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
                            'Active Assessment: Buddy',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: const Text('LOW RISK'),
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
                        'Primary Condition: Seasonal Allergic Dermatitis',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Symptom match score: 88%. Environmental pollen or flea allergy suspected. No immediate emergency indicators present.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      AppSpacing.vGapLg,

                      // ── Probability Breakdown List ───────────────
                      const SectionHeader(title: 'Differential Predictions'),
                      AppSpacing.vGapSm,
                      _buildProbabilityRow(
                        context,
                        label: 'Seasonal Dermatitis',
                        percent: '88%',
                      ),
                      AppSpacing.vGapXs,
                      _buildProbabilityRow(
                        context,
                        label: 'Flea Allergy Reaction',
                        percent: '64%',
                      ),
                      AppSpacing.vGapXs,
                      _buildProbabilityRow(
                        context,
                        label: 'Contact Sensitivity',
                        percent: '41%',
                      ),
                      AppSpacing.vGapLg,

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
                        onPressed: () {},
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
}
