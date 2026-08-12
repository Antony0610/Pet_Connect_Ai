import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A faithful Flutter rendering of the frozen Stitch **Treatment Plan**
/// (Light Theme design authority, ID `8373546021f043e08a462b5358057e93`).
///
/// Active recovery management including post-surgery rehab progress (65%),
/// daily medication check-ins, physical therapy tasks, and vet care team contacts.
class TreatmentPlanScreen extends ConsumerStatefulWidget {
  const TreatmentPlanScreen({super.key});

  @override
  ConsumerState<TreatmentPlanScreen> createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends ConsumerState<TreatmentPlanScreen> {
  static const double _maxContentWidth = 1000;

  bool _task1Completed = true;
  bool _task2Completed = false;
  bool _task3Completed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          selectedPet != null ? "${selectedPet.name}'s Recovery Plan" : 'Active Treatment Plan',
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
                // ── Recovery Plan Hero Card ────────────────────────
                AppCard(
                  backgroundColor: scheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
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
                            label: const Text('Post-Surgery Rehab'),
                            backgroundColor: scheme.primary,
                            labelStyle: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Target: Oct 30, 2024',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        "Buddy's Recovery Plan: Knee Rehabilitation (TPLO)",
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rehab Progress',
                            style: context.textTheme.labelMedium,
                          ),
                          Text(
                            '65% Completed',
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: scheme.surfaceContainerHigh,
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Medications & Dosing Schedule ──────────────────
                const SectionHeader(title: 'Medications & Dosing'),
                AppSpacing.vGapSm,
                _buildMedicationCard(
                  context,
                  name: 'Apoquel 16mg',
                  instructions: 'Take 1 tablet daily with morning meal',
                  time: '08:00 AM • Daily',
                ),
                AppSpacing.vGapSm,
                _buildMedicationCard(
                  context,
                  name: 'Carprofen 75mg',
                  instructions: 'Take 1/2 tablet twice daily after food',
                  time: '08:00 AM & 08:00 PM • 14 days',
                ),
                AppSpacing.vGapXl,

                // ── Daily Physical Therapy Exercises ───────────────
                const SectionHeader(title: 'Physical Therapy Exercises'),
                AppSpacing.vGapSm,
                _buildExerciseTile(
                  context,
                  title: 'Gentle Range of Motion (ROM) Flexes',
                  subtitle: '10 reps per leg, 3 times daily',
                  isCompleted: _task1Completed,
                  onChanged: (val) =>
                      setState(() => _task1Completed = val ?? false),
                ),
                AppSpacing.vGapXs,
                _buildExerciseTile(
                  context,
                  title: 'Short Leash Walk (5 mins)',
                  subtitle: 'Flat surface only, no stairs or jumping',
                  isCompleted: _task2Completed,
                  onChanged: (val) =>
                      setState(() => _task2Completed = val ?? false),
                ),
                AppSpacing.vGapXs,
                _buildExerciseTile(
                  context,
                  title: 'Ice Pack Application',
                  subtitle: '15 mins on surgical knee site after walking',
                  isCompleted: _task3Completed,
                  onChanged: (val) =>
                      setState(() => _task3Completed = val ?? false),
                ),
                AppSpacing.vGapXl,

                // ── Veterinary Care Team Contact ───────────────────
                const SectionHeader(title: 'Veterinary Care Team'),
                AppSpacing.vGapSm,
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. Emily Carter',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            Text(
                              'Orthopedic Specialist • Metro Vet Clinic',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppButton.outlined(
                        onPressed: () {},
                        size: AppButtonSize.small,
                        child: const Text('Call Clinic'),
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

  Widget _buildMedicationCard(
    BuildContext context, {
    required String name,
    required String instructions,
    required String time,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication,
              color: scheme.onSecondaryContainer,
              size: 20,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  instructions,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  time,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
          AppButton.text(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Logged dose for $name')));
            },
            child: const Text('Check-in'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isCompleted,
    required ValueChanged<bool?> onChanged,
  }) {
    final scheme = context.colorScheme;
    return AppCard(
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: isCompleted,
        onChanged: onChanged,
        activeColor: scheme.primary,
        title: Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: AppTypography.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
