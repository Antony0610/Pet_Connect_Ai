import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/treatment_plan.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Treatment Plan Screen** — `/owner/health/treatment`.
///
/// Connected to live Supabase `treatment_plans` table.
/// ZERO dummy/hardcoded data.
class TreatmentPlanScreen extends ConsumerStatefulWidget {
  const TreatmentPlanScreen({super.key});

  @override
  ConsumerState<TreatmentPlanScreen> createState() =>
      _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends ConsumerState<TreatmentPlanScreen> {
  static const double _maxContentWidth = 1000;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';
    final petName = selectedPet?.name ?? 'Companion';
    final plansAsync = petId.isNotEmpty ? ref.watch(treatmentPlansProvider(petId)) : null;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          selectedPet != null
              ? "$petName's Recovery Plan"
              : 'Active Treatment Plan',
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
            child: plansAsync?.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text('Error loading treatment plans: $err'),
                ),
              ),
              data: (plans) => _TreatmentPlanContent(
                petName: petName,
                plans: plans,
              ),
            ) ??
            _TreatmentPlanContent(
              petName: petName,
              plans: const [],
            ),
          ),
        ),
      ),
    );
  }
}

class _TreatmentPlanContent extends StatelessWidget {
  const _TreatmentPlanContent({
    required this.petName,
    required this.plans,
  });

  final String petName;
  final List<TreatmentPlan> plans;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.healing_rounded,
                  size: AppIconSizes.xl,
                  color: scheme.primary,
                ),
              ),
              AppSpacing.vGapLg,
              Text(
                'No Active Treatment Plans',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppSpacing.vGapSm,
              Text(
                'There are no ongoing medical rehab or treatment plans assigned for $petName. Post-op recovery schedules and prescribed therapies from your veterinary clinic will appear here.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activePlan = plans.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Recovery Plan Hero Card ────────────────────────
        AppCard(
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    avatar: Icon(
                      Icons.healing,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                    label: Text(activePlan.status.toUpperCase()),
                    backgroundColor: scheme.primary,
                    labelStyle: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const Spacer(),
                  if (activePlan.targetDate != null)
                    Text(
                      'Target: ${activePlan.targetDate!.toIso8601String().split('T').first}',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              AppSpacing.vGapSm,
              Text(
                activePlan.title,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              if (activePlan.notes != null && activePlan.notes!.isNotEmpty) ...[
                AppSpacing.vGapSm,
                Text(
                  activePlan.notes!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              AppSpacing.vGapMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rehab Progress',
                    style: context.textTheme.labelMedium,
                  ),
                  Text(
                    '${activePlan.progressPercent}% Completed',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapXs,
              LinearProgressIndicator(
                value: (activePlan.progressPercent / 100.0).clamp(0.0, 1.0),
                backgroundColor: scheme.surfaceContainerHigh,
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ],
          ),
        ),
        AppSpacing.vGapXl,

        // ── Plan Notes & Instructions ──────────────────
        if (activePlan.notes != null && activePlan.notes!.isNotEmpty) ...[
          const SectionHeader(title: 'Clinical Notes & Protocol'),
          AppSpacing.vGapSm,
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.medication_liquid_rounded,
                  color: scheme.primary,
                  size: AppIconSizes.md,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    activePlan.notes!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
