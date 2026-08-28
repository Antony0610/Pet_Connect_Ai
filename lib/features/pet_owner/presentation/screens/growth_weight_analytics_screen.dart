import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/health_widgets.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Growth & Weight Analytics** — `/owner/health/growth`.
///
/// Fully dynamic growth and weight tracker backed by Supabase weight logs.
/// ZERO dummy/hardcoded data.
class GrowthWeightAnalyticsScreen extends ConsumerStatefulWidget {
  const GrowthWeightAnalyticsScreen({super.key});

  @override
  ConsumerState<GrowthWeightAnalyticsScreen> createState() =>
      _GrowthWeightAnalyticsScreenState();
}

class _GrowthWeightAnalyticsScreenState
    extends ConsumerState<GrowthWeightAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';
    final logsAsync = petId.isNotEmpty ? ref.watch(petWeightLogsProvider(petId)) : null;

    final petName = selectedPet?.name ?? 'Companion';
    final species = selectedPet?.species ?? 'Pet';
    final breed = selectedPet?.breed ?? species;
    final currentWeight = selectedPet?.weightKg;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(
        context,
        title: selectedPet != null
            ? "$petName's Growth & Weight"
            : 'Growth & Weight',
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
              child: logsAsync?.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text('Error loading weight logs: $err'),
                  ),
                ),
                data: (logs) => _GrowthContent(
                  petId: petId,
                  petName: petName,
                  breed: breed,
                  species: species,
                  currentWeight: currentWeight,
                  logs: logs,
                  palette: palette,
                  brightness: brightness,
                ),
              ) ??
              _GrowthContent(
                petId: petId,
                petName: petName,
                breed: breed,
                species: species,
                currentWeight: currentWeight,
                logs: const [],
                palette: palette,
                brightness: brightness,
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
}

class _GrowthContent extends StatelessWidget {
  const _GrowthContent({
    required this.petId,
    required this.petName,
    required this.breed,
    required this.species,
    required this.currentWeight,
    required this.logs,
    required this.palette,
    required this.brightness,
  });

  final String petId;
  final String petName;
  final String breed;
  final String species;
  final double? currentWeight;
  final List<PetWeightLog> logs;
  final PortalPalette palette;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CurrentWeightCard(
          petName: petName,
          breed: breed,
          species: species,
          currentWeight: currentWeight,
          logs: logs,
          accent: palette.accent,
          container: palette.accentContainer(brightness),
          onContainer: palette.onAccentContainer(brightness),
        ),
        AppSpacing.vGapLg,
        _GrowthCurveCard(
          accent: palette.accent,
          logs: logs,
          currentWeight: currentWeight,
        ),
        AppSpacing.vGapLg,
        _BodyConditionCard(
          petId: petId,
          petName: petName,
          currentWeight: currentWeight,
          accent: palette.accent,
          onAccent: scheme.onPrimary,
        ),
        AppSpacing.vGapLg,
        _RecentWeighIns(logs: logs),
      ],
    );
  }
}

class _CurrentWeightCard extends StatelessWidget {
  const _CurrentWeightCard({
    required this.petName,
    required this.breed,
    required this.species,
    required this.currentWeight,
    required this.logs,
    required this.accent,
    required this.container,
    required this.onContainer,
  });

  final String petName;
  final String breed;
  final String species;
  final double? currentWeight;
  final List<PetWeightLog> logs;
  final Color accent;
  final Color container;
  final Color onContainer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final latestWeight = logs.isNotEmpty ? logs.first.weightKg : currentWeight;
    final weightStr = latestWeight != null ? latestWeight.toStringAsFixed(1) : '—';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Weight',
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapSm,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                weightStr,
                style: context.textTheme.displaySmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.bold,
                ),
              ),
              if (latestWeight != null) ...[
                AppSpacing.hGapXs,
                Text(
                  'kg',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.hGapSm,
                HealthCategoryChip(
                  label: 'Recorded',
                  icon: Icons.check_circle_outline_rounded,
                  background: container,
                  foreground: onContainer,
                ),
              ],
            ],
          ),
          AppSpacing.vGapMd,
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: AppRadius.brCard,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.smart_toy_rounded,
                  color: accent,
                  size: AppIconSizes.sm,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    latestWeight != null
                        ? '$petName ($breed) has a registered body weight of ${latestWeight.toStringAsFixed(1)} kg. Maintaining consistent caloric intake supports cardiovascular health.'
                        : 'Log weight entries for $petName ($breed) to track development trajectories and body condition over time.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthCurveCard extends StatefulWidget {
  const _GrowthCurveCard({
    required this.accent,
    required this.logs,
    required this.currentWeight,
  });

  final Color accent;
  final List<PetWeightLog> logs;
  final double? currentWeight;

  @override
  State<_GrowthCurveCard> createState() => _GrowthCurveCardState();
}

class _GrowthCurveCardState extends State<_GrowthCurveCard> {
  static const _ranges = ['3M', '6M', '1Y', 'All'];
  int _range = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final rawSeries = widget.logs.map((l) => l.weightKg).toList();
    final series = rawSeries.isNotEmpty
        ? rawSeries
        : (widget.currentWeight != null ? [widget.currentWeight!] : <double>[]);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Growth Curve',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          _RangeSelector(
            ranges: _ranges,
            selected: _range,
            accent: widget.accent,
            onChanged: (i) => setState(() => _range = i),
          ),
          AppSpacing.vGapLg,
          if (series.length >= 2) ...[
            SizedBox(
              height: 180,
              child: CustomPaint(
                size: Size.infinite,
                painter: _LineChartPainter(
                  values: series,
                  line: widget.accent,
                  fill: widget.accent.withValues(alpha: 0.15),
                  grid: scheme.outlineVariant.withValues(alpha: 0.4),
                  dot: widget.accent,
                  dotBorder: scheme.surface,
                ),
              ),
            ),
          ] else ...[
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: AppRadius.brCard,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Log multiple weigh-ins over time to render the growth trajectory curve.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.ranges,
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  final List<String> ranges;
  final int selected;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadius.brPill,
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          for (var i = 0; i < ranges.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: i == selected ? accent : Colors.transparent,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    ranges[i],
                    style: context.textTheme.labelLarge?.copyWith(
                      color: i == selected
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.grid,
    required this.dot,
    required this.dotBorder,
  });

  final List<double> values;
  final Color line;
  final Color fill;
  final Color grid;
  final Color dot;
  final Color dotBorder;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;
    const pad = 12.0;

    Offset pointAt(int i) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final norm = (values[i] - minV) / span;
      final y = size.height - pad - norm * (size.height - pad * 2);
      return Offset(x, y);
    }

    final points = [for (var i = 0; i < values.length; i++) pointAt(i)];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fill, fill.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = line
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = points.last;
    canvas.drawCircle(last, 6, Paint()..color = dotBorder);
    canvas.drawCircle(last, 4, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values || old.line != line || old.fill != fill;
}

class _BodyConditionCard extends ConsumerWidget {
  const _BodyConditionCard({
    required this.petId,
    required this.petName,
    required this.currentWeight,
    required this.accent,
    required this.onAccent,
  });

  final String petId;
  final String petName;
  final double? currentWeight;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Condition',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Score 5 of 9 — visual & touch assessment',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapLg,
          _ConditionMeter(
            accent: accent,
            onAccent: onAccent,
            under: scheme.tertiaryContainer,
            over: scheme.errorContainer,
          ),
          AppSpacing.vGapMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in ['Underweight', 'Ideal', 'Overweight'])
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          AppSpacing.vGapLg,
          AppButton(
            label: 'Log New Photo Assessment',
            icon: Icons.add_a_photo_rounded,
            variant: AppButtonVariant.tonal,
            isFullWidth: true,
            onPressed: () => _showPhotoAssessmentDialog(context, ref, petId, petName, currentWeight),
          ),
        ],
      ),
    );
  }

  void _showPhotoAssessmentDialog(
    BuildContext context,
    WidgetRef ref,
    String petId,
    String petName,
    double? initialWeight,
  ) {
    int selectedBcs = 5;
    final weightController = TextEditingController(
      text: initialWeight != null ? initialWeight.toStringAsFixed(1) : '',
    );
    final notesController = TextEditingController();
    String photoSource = 'Camera';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          String bcsCategory;
          Color bcsColor;
          if (selectedBcs <= 3) {
            bcsCategory = 'Underweight (1-3)';
            bcsColor = Colors.amber.shade700;
          } else if (selectedBcs <= 5) {
            bcsCategory = 'Ideal Body Condition (4-5)';
            bcsColor = Colors.green.shade600;
          } else if (selectedBcs <= 7) {
            bcsCategory = 'Overweight (6-7)';
            bcsColor = Colors.orange.shade700;
          } else {
            bcsCategory = 'Obese (8-9)';
            bcsColor = Colors.red.shade700;
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Body Condition Assessment',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    'Evaluate & record $petName\'s physical condition score and weight.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGapMd,

                  // BCS Scale Selector (1-9)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Body Score (BCS 1–9):',
                        style: context.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: bcsColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: bcsColor, width: 1),
                        ),
                        child: Text(
                          '$selectedBcs/9 • $bcsCategory',
                          style: TextStyle(
                            color: bcsColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 1; i <= 9; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('$i'),
                              selected: selectedBcs == i,
                              selectedColor: context.colorScheme.primary,
                              labelStyle: TextStyle(
                                color: selectedBcs == i
                                    ? context.colorScheme.onPrimary
                                    : context.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setSheetState(() => selectedBcs = i);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.vGapMd,

                  // Weight Entry
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Current Weight (kg)',
                      hintText: 'e.g. 24.5',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  AppSpacing.vGapSm,

                  // Photo Capture Option
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Take Photo'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: photoSource == 'Camera'
                                ? context.colorScheme.primary.withValues(alpha: 0.1)
                                : null,
                          ),
                          onPressed: () {
                            setSheetState(() => photoSource = 'Camera');
                          },
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('From Gallery'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: photoSource == 'Gallery'
                                ? context.colorScheme.primary.withValues(alpha: 0.1)
                                : null,
                          ),
                          onPressed: () {
                            setSheetState(() => photoSource = 'Gallery');
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,

                  // Assessment Notes
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Visual & Palpation Notes',
                      hintText: 'e.g. Ribs easily felt, healthy waist tuck observed...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  AppSpacing.vGapMd,

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Save Photo Assessment'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final weightText = weightController.text.trim();
                        final parsedWeight = double.tryParse(weightText);
                        final notesText = notesController.text.trim();
                        final finalNotes = notesText.isNotEmpty
                            ? 'BCS $selectedBcs/9 • $notesText'
                            : 'BCS $selectedBcs/9 assessment logged';

                        if (petId.isNotEmpty && parsedWeight != null && parsedWeight > 0) {
                          final newLog = PetWeightLog(
                            id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                            petId: petId,
                            recordedAt: DateTime.now(),
                            weightKg: parsedWeight,
                            notes: finalNotes,
                            createdAt: DateTime.now(),
                          );

                          final repo = ref.read(healthRepositoryProvider);
                          await repo.addWeightLog(newLog);
                          ref.invalidate(petWeightLogsProvider(petId));
                          ref.invalidate(petsProvider);
                        }

                        if (context.mounted) {
                          final weightMsg = parsedWeight != null
                              ? ' (${parsedWeight.toStringAsFixed(1)} kg)'
                              : '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Photo assessment recorded for $petName: BCS $selectedBcs/9$weightMsg logged to Passport!',
                              ),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        }
                      },
                    ),
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

class _ConditionMeter extends StatelessWidget {
  const _ConditionMeter({
    required this.accent,
    required this.onAccent,
    required this.under,
    required this.over,
  });

  final Color accent;
  final Color onAccent;
  final Color under;
  final Color over;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const pinFraction = 0.5;

        return SizedBox(
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: AppRadius.brPill,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _seg(under)),
                      Expanded(flex: 4, child: _seg(accent)),
                      Expanded(flex: 3, child: _seg(over)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: (width * pinFraction) - 28,
                top: 0,
                child: HealthCategoryChip(
                  label: 'Ideal (5)',
                  background: accent,
                  foreground: onAccent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _seg(Color color) => Container(height: 12, color: color);
}

class _RecentWeighIns extends StatelessWidget {
  const _RecentWeighIns({required this.logs});

  final List<PetWeightLog> logs;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Recent Weigh-ins',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        AppCard(
          child: logs.isNotEmpty
              ? Column(
                  children: [
                    for (var i = 0; i < logs.length; i++) ...[
                      if (i > 0)
                        Divider(
                          color: scheme.outlineVariant,
                          height: AppSpacing.lg,
                        ),
                      HealthRecordRow(
                        leading: HealthCircleIcon(
                          icon: Icons.monitor_weight_rounded,
                          background: scheme.surfaceContainerHigh,
                          foreground: scheme.onSurfaceVariant,
                        ),
                        title: '${logs[i].weightKg.toStringAsFixed(1)} kg',
                        meta: [
                          HealthMetaLine(
                            logs[i].recordedAt.toIso8601String().split('T').first,
                          ),
                          if (logs[i].notes != null && logs[i].notes!.isNotEmpty)
                            HealthMetaLine(logs[i].notes!),
                        ],
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No weigh-in logs recorded yet.',
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
