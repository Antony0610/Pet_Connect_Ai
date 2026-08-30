import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/services/health_passport_exporter.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/medication_adherence_provider.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/health_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/pet_emergency_qr_modal.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Health Passport Dashboard** — the `/owner/health` hub.
///
/// Frozen Stitch comp: a wellness-score gauge, an AI health insight, a
/// horizontal quick-action rail into the four sub-passports, a 2×2 stat grid,
/// a recent event and an article promo. Emerald in the comp maps to the Pet
/// Owner portal **accent**; every other color to the active [ColorScheme].
class HealthPassportDashboardScreen extends ConsumerWidget {
  const HealthPassportDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final selectedPet = ref.watch(selectedPetProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(
        context,
        title: selectedPet != null ? "${selectedPet.name}'s Health" : 'Health',
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Emergency Pet ID & QR',
            onPressed: () => _showEmergencyMedicalPass(context, selectedPet),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export Health Passport',
            onPressed: () => _exportHealthPassport(context, ref, selectedPet),
          ),
        ],
      ),
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
              child: _DashboardBody(
                petId: selectedPet?.id,
                petName: selectedPet?.name,
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

  void _showEmergencyMedicalPass(BuildContext context, Pet? pet) {
    if (pet != null) {
      PetEmergencyQrModal.show(context, pet);
    } else {
      context.showSnackbar('Please select a pet to generate an Emergency Pass.');
    }
  }

  Future<void> _exportHealthPassport(
    BuildContext context,
    WidgetRef ref,
    Pet? pet,
  ) async {
    if (pet == null) {
      context.showSnackbar('Please select a pet to export the Health Passport.');
      return;
    }

    final owner = ref.read(currentUserProfileProvider).valueOrNull;
    final vaccinations = ref.read(vaccinationsProvider(pet.id)).valueOrNull ?? [];
    final healthRecords = ref.read(healthRecordsProvider(pet.id)).valueOrNull ?? [];
    final weightLogs = ref.read(petWeightLogsProvider(pet.id)).valueOrNull ?? [];

    await HealthPassportExporter.exportAndShare(
      context: context,
      pet: pet,
      owner: owner,
      vaccinations: vaccinations,
      healthRecords: healthRecords,
      weightLogs: weightLogs,
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({this.petId, this.petName});

  final String? petId;
  final String? petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;
    final accent = palette.accent;
    final onAccent = context.colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WellnessCard(
          accent: accent,
          onAccent: onAccent,
          container: palette.accentContainer(brightness),
          onContainer: palette.onAccentContainer(brightness),
        ),
        AppSpacing.vGapMd,
        if (petId != null && petId!.isNotEmpty) ...[
          _MedicationAdherenceCard(petId: petId!),
          AppSpacing.vGapMd,
        ],
        _QuickActionRail(accent: accent),
        AppSpacing.vGapLg,
        const _StatGrid(),
        AppSpacing.vGapLg,
        const _RecentEventCard(),
        AppSpacing.vGapLg,
        const _ArticleCard(),
      ],
    );
  }
}class _MedicationAdherenceCard extends ConsumerWidget {
  const _MedicationAdherenceCard({required this.petId});

  final String petId;

  void _showAddReminderDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '08:00 AM');
    final notesCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Daily Care Reminder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reminder / Medication Title',
                  hintText: 'e.g. Ear drops, Joint Supplement',
                ),
              ),
              AppSpacing.vGapSm,
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosage / Portion',
                  hintText: 'e.g. 1 chewable tablet, 2 drops',
                ),
              ),
              AppSpacing.vGapSm,
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Scheduled Time',
                  hintText: 'e.g. 08:00 AM, 06:30 PM',
                ),
              ),
              AppSpacing.vGapSm,
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Instructions (Optional)',
                  hintText: 'e.g. Give with food',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final t = titleCtrl.text.trim();
              final d = dosageCtrl.text.trim();
              if (t.isEmpty) return;
              ref.read(medicationAdherenceProvider(petId).notifier).addItem(
                title: t,
                dosage: d.isNotEmpty ? d : 'As directed',
                scheduledTime: timeCtrl.text.trim(),
                instructions: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Reminder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final items = ref.watch(medicationAdherenceProvider(petId));
    final notifier = ref.read(medicationAdherenceProvider(petId).notifier);
    final completedCount = items.where((i) => i.isCompleted).length;
    final totalCount = items.length;
    final isAllDone = totalCount > 0 && completedCount == totalCount;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Icon(
                        Icons.medication_liquid_rounded,
                        color: scheme.primary,
                        size: 20,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Care & Medication',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            items.isNotEmpty
                                ? '$completedCount of $totalCount completed today'
                                : 'Routine preventative wellness',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isAllDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade800),
                      AppSpacing.hGapXs,
                      Text(
                        'ALL DONE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  tooltip: 'Add Care Reminder',
                  color: scheme.primary,
                  onPressed: () => _showAddReminderDialog(context, ref),
                ),
            ],
          ),
          AppSpacing.vGapMd,
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_outlined, size: 18, color: scheme.primary),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Text(
                          'No active medications required. Routine wellness is active.',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Reminder'),
                        onPressed: () => _showAddReminderDialog(context, ref),
                      ),
                      AppSpacing.hGapSm,
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => notifier.loadStandardWellnessProtocol(),
                        child: const Text('Load Protocol'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Material(
                  color: item.isCompleted
                      ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : scheme.surfaceContainerLowest,
                  borderRadius: AppRadius.brMd,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      notifier.toggleItem(item.id);
                    },
                    borderRadius: AppRadius.brMd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isCompleted,
                            activeColor: scheme.primary,
                            onChanged: (_) {
                              HapticFeedback.lightImpact();
                              notifier.toggleItem(item.id);
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    fontWeight: AppTypography.semiBold,
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: item.isCompleted
                                        ? scheme.onSurfaceVariant
                                        : scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${item.scheduledTime} • ${item.dosage}',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                            tooltip: 'Remove',
                            onPressed: () => notifier.removeItem(item.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Wellness score
// ═══════════════════════════════════════════════════════════════════

class _WellnessCard extends ConsumerWidget {
  const _WellnessCard({
    required this.accent,
    required this.onAccent,
    required this.container,
    required this.onContainer,
  });

  final Color accent;
  final Color onAccent;
  final Color container;
  final Color onContainer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';

    int score = 0;
    String statusLabel = 'No Pet Selected';
    String statusSubtitle = 'Select a pet to view health telemetry';

    if (selectedPet != null) {
      // 1. Baseline profile creation (50 pts)
      int computed = 50;

      // 2. Vaccinations (up to +25 pts)
      final vaxList = ref.watch(vaccinationsProvider(petId)).valueOrNull ?? [];
      if (vaxList.length >= 3) {
        computed += 25;
      } else if (vaxList.isNotEmpty) {
        computed += (vaxList.length * 8).clamp(8, 20);
      }

      // 3. Medical Records & Veterinary Checkups (up to +15 pts)
      final records = ref.watch(healthRecordsProvider(petId)).valueOrNull ?? [];
      if (records.isNotEmpty) {
        computed += 15;
      }

      // 4. Weight Tracking History (up to +10 pts)
      final weightLogs = ref.watch(petWeightLogsProvider(petId)).valueOrNull ?? [];
      if (weightLogs.isNotEmpty) {
        computed += 10;
      } else if (selectedPet.weightKg != null && selectedPet.weightKg! > 0) {
        computed += 5;
      }

      // 5. Clinical status adjustments
      final healthStatus = selectedPet.healthStatus.toLowerCase();
      if (healthStatus == 'optimal') {
        computed += 5;
      } else if (healthStatus == 'critical' || healthStatus == 'chronic') {
        computed -= 15;
      }

      score = computed.clamp(20, 100);

      if (score >= 85) {
        statusLabel = 'Optimal Health';
      } else if (score >= 70) {
        statusLabel = 'Good Condition';
      } else if (score >= 55) {
        statusLabel = 'Action Recommended';
      } else {
        statusLabel = 'Profile Onboarding';
      }

      final parts = <String>[];
      if (vaxList.isNotEmpty) parts.add('${vaxList.length} Vaccines');
      if (records.isNotEmpty) parts.add('${records.length} Records');
      if (weightLogs.isNotEmpty) parts.add('${weightLogs.length} Weights');
      statusSubtitle = parts.isNotEmpty
          ? parts.join(' • ')
          : 'Add vaccines & records to elevate score';
    }

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Overall Wellness Score',
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapLg,
          SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: _WellnessGaugePainter(
                progress: score / 100,
                track: scheme.outlineVariant.withValues(alpha: 0.4),
                accent: accent,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: context.textTheme.displayMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: AppTypography.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      'out of 100',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppSpacing.vGapLg,
          HealthCategoryChip(
            label: statusLabel,
            icon: Icons.verified_rounded,
            background: container,
            foreground: onContainer,
          ),
          AppSpacing.vGapSm,
          Text(
            statusSubtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapLg,
          HealthAccentButton(
            label: 'Share Milestone',
            icon: Icons.share_rounded,
            accent: accent,
            onAccent: onAccent,
            onPressed: () {
              if (selectedPet != null) {
                ExternalActions.shareMilestone(
                  context: context,
                  petName: selectedPet.name,
                  species: selectedPet.breed ?? selectedPet.species,
                  status: selectedPet.healthStatus,
                  weightKg: selectedPet.weightKg,
                );
              } else {
                context.showSnackbar('Please select a pet to share milestones.');
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Paints the wellness ring: a full track plus an accent arc for [progress].
class _WellnessGaugePainter extends CustomPainter {
  const _WellnessGaugePainter({
    required this.progress,
    required this.track,
    required this.accent,
  });

  final double progress;
  final Color track;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [accent.withValues(alpha: 0.7), accent],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_WellnessGaugePainter old) =>
      old.progress != progress || old.accent != accent || old.track != track;
}

// ═══════════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════════
// Quick actions
// ═══════════════════════════════════════════════════════════════════

class _QuickActionRail extends StatelessWidget {
  const _QuickActionRail({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickActionItemSpec(
        icon: Icons.vaccines_rounded,
        title: 'Vaccines',
        gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
        onTap: () => context.push(RoutePaths.ownerHealthVaccinations),
      ),
      QuickActionItemSpec(
        icon: Icons.history_rounded,
        title: 'Medical\nHistory',
        gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        onTap: () => context.push(RoutePaths.ownerHealthMedical),
      ),
      QuickActionItemSpec(
        icon: Icons.monitor_weight_rounded,
        title: 'Weight\nAnalytics',
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF0E7490)],
        onTap: () => context.push(RoutePaths.ownerHealthGrowth),
      ),
      QuickActionItemSpec(
        icon: Icons.medication_rounded,
        title: 'Treatment\nPlans',
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        onTap: () => context.push(RoutePaths.ownerHealthTreatment),
      ),
      QuickActionItemSpec(
        icon: Icons.folder_shared_rounded,
        title: 'Doc Vault',
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        onTap: () => context.push(RoutePaths.ownerHealthVault),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              Text(
                '${actions.length} Tools',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        QuickActionsGridContainer(
          items: actions,
          crossAxisCount: 3,
          tabletCrossAxisCount: 5,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Stat grid
// ═══════════════════════════════════════════════════════════════════

class _StatGrid extends ConsumerWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';
    final vaxAsync = petId.isNotEmpty ? ref.watch(vaccinationsProvider(petId)) : null;
    final treatmentsAsync = petId.isNotEmpty ? ref.watch(treatmentPlansProvider(petId)) : null;

    final vaxCount = vaxAsync?.valueOrNull?.length ?? 0;
    final vaxStr = vaxCount > 0 ? '$vaxCount Logged' : '0 Recorded';
    
    final medCount = treatmentsAsync?.valueOrNull?.where((t) => t.status.toLowerCase() == 'active').length ?? 0;
    final medStr = '$medCount Active';

    final weightStr = selectedPet?.weightKg != null
        ? '${selectedPet!.weightKg} kg'
        : '—';

    final stats = [
      _Stat(Icons.vaccines_rounded, 'Vaccinations', vaxStr),
      const _Stat(Icons.event_rounded, 'Next Appt', '—'),
      _Stat(Icons.monitor_weight_rounded, 'Weight', weightStr),
      _Stat(Icons.medication_rounded, 'Medication', medStr),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final s in stats) _StatTile(stat: s)],
    );
  }
}

class _Stat {
  const _Stat(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: scheme.primary, size: AppIconSizes.sm),
          AppSpacing.vGapXs,
          Text(
            stat.label,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            stat.value,
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Recent event + article
// ═══════════════════════════════════════════════════════════════════

class _RecentEventCard extends ConsumerWidget {
  const _RecentEventCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';
    final eventsAsync = petId.isNotEmpty ? ref.watch(healthTimelineEventsProvider(petId)) : null;
    final recordsAsync = petId.isNotEmpty ? ref.watch(healthRecordsProvider(petId)) : null;

    final recentEvent = eventsAsync?.valueOrNull?.firstOrNull;
    final recentRecord = recordsAsync?.valueOrNull?.firstOrNull;

    final title = recentEvent?.title ?? recentRecord?.title;
    final meta = recentEvent?.description ?? recentRecord?.diagnosis ?? (recentRecord != null ? 'Recorded by ${recentRecord.veterinarianName ?? 'Clinic'}' : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Recent Event',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        AppCard(
          onTap: () => context.goNamed(RouteNames.ownerHealthTimeline),
          child: title != null
              ? HealthRecordRow(
                  leading: HealthCircleIcon(
                    icon: Icons.health_and_safety_rounded,
                    background: scheme.secondaryContainer,
                    foreground: scheme.onSecondaryContainer,
                  ),
                  title: title,
                  meta: [if (meta != null) HealthMetaLine(meta)],
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      HealthCircleIcon(
                        icon: Icons.event_note_rounded,
                        background: scheme.surfaceContainerHigh,
                        foreground: scheme.onSurfaceVariant,
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Text(
                          'No health events recorded yet',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _ArticleCard extends ConsumerWidget {
  const _ArticleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final pet = ref.watch(selectedPetProvider);

    String articleTitle = 'Companion Preventative Care Guide';
    String articleSubtitle = 'Health Hub • Evidence-Based Care';

    if (pet != null) {
      final species = pet.species.toLowerCase();
      final ageStr = pet.breedLine;
      if (species.contains('cat')) {
        articleTitle = 'Feline Hydration & Renal Health Essentials';
        articleSubtitle = 'Tailored for ${pet.name} • Feline Care';
      } else if (species.contains('dog')) {
        if (ageStr.toLowerCase().contains('mo') || ageStr.toLowerCase().contains('puppy')) {
          articleTitle = 'Puppy Socialization & Nutrition Milestones';
          articleSubtitle = 'Tailored for ${pet.name} • Growth Guide';
        } else if (ageStr.contains(RegExp(r'([7-9]|1[0-9])\s*yr'))) {
          articleTitle = 'Maintaining Senior Dog Mobility & Vitality';
          articleSubtitle = 'Tailored for ${pet.name} • Senior Care';
        } else {
          articleTitle = 'Active Canine Joint Care & Nutrition';
          articleSubtitle = 'Tailored for ${pet.name} • Wellness Guide';
        }
      } else {
        articleTitle = '${pet.species} Preventative Care Essentials';
        articleSubtitle = 'Tailored for ${pet.name} • Health Hub';
      }
    }

    return AppCard(
      child: Row(
        children: [
          HealthCircleIcon(
            icon: Icons.menu_book_rounded,
            background: scheme.tertiaryContainer,
            foreground: scheme.onTertiaryContainer,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  articleTitle,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                Text(
                  articleSubtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          TextButton(
            onPressed: () => context.push(RoutePaths.ownerCommunitySaved),
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
            child: const Text('View Hub'),
          ),
        ],
      ),
    );
  }
}
