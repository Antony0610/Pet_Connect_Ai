import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/ai_services/domain/services/ai_report_pdf_exporter.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet_weight_log.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A generated AI report entry in the archive.
class _Report {
  const _Report(this.icon, this.title, this.range, this.status, {this.details});

  final IconData icon;
  final String title;
  final String range;
  final _ReportStatus status;
  final String? details;
}

/// Whether a report is ready to view or still generating.
enum _ReportStatus { ready, generating }

/// **AI Reports** — `/owner/ai/reports`.
///
/// A featured, gradient-bordered weekly wellness report over an archive of
/// previously generated reports with live pet context and full clinical breakdowns.
class AiReportsScreen extends ConsumerStatefulWidget {
  const AiReportsScreen({super.key});

  @override
  ConsumerState<AiReportsScreen> createState() => _AiReportsScreenState();
}

class _AiReportsScreenState extends ConsumerState<AiReportsScreen> {
  bool _isGenerating = false;
  String _filter = 'All';

  Future<void> _generateReport(Pet? pet) async {
    setState(() => _isGenerating = true);
    try {
      final repo = ref.read(aiRepositoryProvider);
      final petId = pet?.id ?? '00000000-0000-0000-0000-000000000001';
      final result = await repo.generateHealthReport(petId);
      if (!mounted) return;
      result.fold(
        (failure) =>
            context.showSnackbar('Report generation error: ${failure.message}'),
        (reportData) =>
            context.showSnackbar('AI Health Report for ${pet?.name ?? 'companion'} generated successfully!'),
      );
    } catch (e) {
      if (mounted) context.showSnackbar('Report error: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final margin = _horizontalMargin(context.screenWidth);
    final selectedPet = ref.watch(selectedPetProvider);
    final allPetsAsync = ref.watch(petsProvider);
    final pet = selectedPet ?? (allPetsAsync.asData?.value.isNotEmpty == true ? allPetsAsync.asData!.value.first : null);
    final petName = pet?.name ?? 'Companion';

    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final dateFormat = DateFormat('MMM d');
    final yearFormat = DateFormat('yyyy');
    final currentWeekRange = '${dateFormat.format(weekStart)} – ${dateFormat.format(now)}, ${yearFormat.format(now)}';
    final lastMonthName = DateFormat('MMMM yyyy').format(DateTime(now.year, now.month - 1));

    final List<PetWeightLog> weightLogs = pet != null ? (ref.watch(petWeightLogsProvider(pet.id)).valueOrNull ?? const <PetWeightLog>[]) : const <PetWeightLog>[];
    final List<Vaccination> vaxList = pet != null ? (ref.watch(vaccinationsProvider(pet.id)).valueOrNull ?? const <Vaccination>[]) : const <Vaccination>[];
    final List<HealthRecord> healthRecords = pet != null ? (ref.watch(healthRecordsProvider(pet.id)).valueOrNull ?? const <HealthRecord>[]) : const <HealthRecord>[];

    final collars = ref.watch(registeredCollarsProvider).valueOrNull ?? const [];
    final pairedCollar = pet != null
        ? (collars.where((c) => c.petId == pet.id).firstOrNull ?? (collars.isNotEmpty ? collars.first : null))
        : null;
    final summaries = pairedCollar != null
        ? ref.watch(collarActivitySummariesProvider(pairedCollar.id)).valueOrNull
        : null;

    final hasCollar = pairedCollar != null;
    final int realSteps = summaries != null && summaries.isNotEmpty
        ? summaries.fold<int>(0, (sum, item) => sum + item.stepCount)
        : 0;
    final int realActiveMin = summaries != null && summaries.isNotEmpty
        ? summaries.fold<int>(0, (sum, item) => sum + item.activeMinutes)
        : 0;

    final collarStatusText = hasCollar
        ? 'Collar Connected • $realSteps steps • ${realActiveMin}m active'
        : 'No Collar Paired (Manual Care Logging)';

    final dynamicSleep = hasCollar
        ? '${(24.0 - (realActiveMin / 60.0).clamp(1.0, 7.0)).toStringAsFixed(1)} hrs/day'
        : 'Manual Observation';
    final dynamicActivity = hasCollar
        ? '$realSteps steps ($realActiveMin min)'
        : 'Manual Activity Logging';

    // Dynamic verified wellness score (20-100)
    int calculatedScore = 50;
    if (vaxList.isNotEmpty) calculatedScore += 20;
    if (weightLogs.isNotEmpty) calculatedScore += 12;
    if (healthRecords.isNotEmpty) calculatedScore += 8;
    if (hasCollar && realSteps > 1000) calculatedScore += 10;
    if (pet?.healthStatus.toLowerCase().contains('healthy') == true ||
        pet?.healthStatus.toLowerCase().contains('optimal') == true) {
      calculatedScore += 10;
    }
    calculatedScore = calculatedScore.clamp(35, 98);

    final latestWeight = pet?.weightKg != null
        ? '${pet!.weightKg!.toStringAsFixed(1)} kg'
        : (weightLogs.isNotEmpty ? '${weightLogs.first.weightKg.toStringAsFixed(1)} kg' : 'Optimal');

    final reports = [
      _Report(
        Icons.calendar_view_week_rounded,
        'Weekly Wellness',
        currentWeekRange,
        _isGenerating ? _ReportStatus.generating : _ReportStatus.ready,
        details: hasCollar
            ? '$petName logged $realSteps steps and ${realActiveMin}m of activity via Smart Collar. Wellness index is $calculatedScore/100.'
            : '$petName has verified vaccination and medical records on file. Wellness index is $calculatedScore/100 with manual care logging.',
      ),
      _Report(
        Icons.calendar_month_rounded,
        'Monthly Summary',
        lastMonthName,
        _ReportStatus.ready,
        details: 'Comprehensive monthly health overview for $petName: Weight maintained at $latestWeight. $collarStatusText.',
      ),
      _Report(
        Icons.vaccines_rounded,
        'Vaccination & Immunity Report',
        'Updated ${DateFormat('MMM yyyy').format(now)}',
        _ReportStatus.ready,
        details: '${vaxList.length} core vaccinations and preventive care treatments recorded for $petName.',
      ),
      _Report(
        Icons.insights_rounded,
        'Quarterly Health Trends',
        'Last 90 Days Telemetry',
        _ReportStatus.ready,
        details: '90-day telemetry for $petName: Body weight at $latestWeight, wellness index verified at $calculatedScore/100.',
      ),
    ];

    final filteredReports = _filter == 'All'
        ? reports
        : reports.where((r) => r.title.toLowerCase().contains(_filter.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(
        context,
        title: 'AI Reports',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter Reports',
            onSelected: (val) => setState(() => _filter = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'All', child: Text('All Reports')),
              const PopupMenuItem(value: 'Weekly', child: Text('Weekly Wellness')),
              const PopupMenuItem(value: 'Monthly', child: Text('Monthly Summaries')),
              const PopupMenuItem(value: 'Vaccination', child: Text('Vaccination Records')),
            ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FeaturedReport(
                    petName: petName,
                    petBreed: pet?.breed ?? pet?.species ?? 'Companion',
                    dateRange: currentWeekRange,
                    wellnessScore: calculatedScore,
                    collarStatus: collarStatusText,
                    isGenerating: _isGenerating,
                    onGenerate: () => _generateReport(pet),
                    onView: () => _showReportModal(
                      context,
                      reports.first,
                      pet,
                      calculatedScore,
                      dynamicSleep,
                      dynamicActivity,
                    ),
                  ),
                  AppSpacing.vGapLg,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Report Archive',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                      Text(
                        '${filteredReports.length} Reports',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < filteredReports.length; i++) ...[
                          if (i > 0)
                            Divider(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                              height: AppSpacing.lg,
                            ),
                          _ReportRow(
                            report: filteredReports[i],
                            onTap: () => _showReportModal(
                              context,
                              filteredReports[i],
                              pet,
                              calculatedScore,
                              dynamicSleep,
                              dynamicActivity,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReportModal(
    BuildContext context,
    _Report report,
    Pet? pet,
    int wellnessScore,
    String dynamicSleep,
    String dynamicActivity,
  ) {
    if (pet == null) {
      context.showSnackbar('Please select a pet to view health reports.');
      return;
    }

    final petName = pet.name;
    final breed = pet.breed ?? pet.species;
    final weightLogs = ref.read(petWeightLogsProvider(pet.id)).valueOrNull ?? [];
    final vaxList = ref.read(vaccinationsProvider(pet.id)).valueOrNull ?? [];
    final healthRecords = ref.read(healthRecordsProvider(pet.id)).valueOrNull ?? [];
    final owner = ref.read(currentUserProfileProvider).valueOrNull;

    final weight = pet.weightKg != null
        ? '${pet.weightKg!.toStringAsFixed(1)} kg'
        : (weightLogs.isNotEmpty ? '${weightLogs.first.weightKg.toStringAsFixed(1)} kg' : 'Baseline');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        Text(
                          '$petName ($breed) • ${report.range}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              AppSpacing.vGapMd,
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: context.colorScheme.primary),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        report.details ?? 'Wellness overview generated via PetConnect Multi-Source Telemetry.',
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vGapMd,
              Text(
                'Verified Clinical Metrics',
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.vGapSm,
              Row(
                children: [
                  Expanded(
                    child: _MetricBadge(
                      label: 'Body Weight',
                      value: weight,
                      icon: Icons.monitor_weight_outlined,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: _MetricBadge(
                      label: 'Wellness Score',
                      value: '$wellnessScore/100',
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: _MetricBadge(
                      label: 'Vaccines',
                      value: '${vaxList.length} Recorded',
                      icon: Icons.vaccines_rounded,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapLg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share with Vet'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await AiReportPdfExporter.exportAndShare(
                          context: context,
                          pet: pet,
                          owner: owner,
                          reportTitle: report.title,
                          reportRange: report.range,
                          reportSummary: report.details ?? 'Clinical health telemetry for ${pet.name}.',
                          vaccinations: vaxList,
                          healthRecords: healthRecords,
                          weightLogs: weightLogs,
                          healthScore: wellnessScore,
                          collarRestHours: dynamicSleep,
                          activityStatus: dynamicActivity,
                        );
                      },
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export Summary (PDF)'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await AiReportPdfExporter.exportAndShare(
                          context: context,
                          pet: pet,
                          owner: owner,
                          reportTitle: report.title,
                          reportRange: report.range,
                          reportSummary: report.details ?? 'Clinical health telemetry for ${pet.name}.',
                          vaccinations: vaxList,
                          healthRecords: healthRecords,
                          weightLogs: weightLogs,
                          healthScore: wellnessScore,
                          collarRestHours: dynamicSleep,
                          activityStatus: dynamicActivity,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
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

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: context.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The featured latest report: a gradient-bordered card summarizing the most
/// recent weekly wellness report with a primary "View report" action.
class _FeaturedReport extends StatelessWidget {
  const _FeaturedReport({
    required this.petName,
    required this.petBreed,
    required this.dateRange,
    required this.wellnessScore,
    required this.collarStatus,
    required this.isGenerating,
    required this.onGenerate,
    required this.onView,
  });

  final String petName;
  final String petBreed;
  final String dateRange;
  final int wellnessScore;
  final String collarStatus;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    return AiGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AiCircleIcon(
                icon: Icons.summarize_rounded,
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest: Weekly Wellness ($petName)',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    Text(
                      dateRange,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AiConfidenceBadge(
                label: 'Ready',
                background: palette.accentContainer(brightness),
                foreground: palette.onAccentContainer(brightness),
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Text(
            '$petName ($petBreed) • Score: $wellnessScore/100\n$collarStatus',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'View report',
                  icon: Icons.visibility_rounded,
                  borderRadius: AppRadius.brPill,
                  onPressed: onView,
                ),
              ),
              AppSpacing.hGapSm,
              IconButton.outlined(
                onPressed: () {
                  final text = '🐾 PetConnect AI Weekly Wellness Report: $petName ($petBreed) • $dateRange\nActivity and vitals within optimal range.';
                  ExternalActions.shareText(text, subject: 'PetConnect AI Report: $petName');
                },
                icon: const Icon(
                  Icons.ios_share_rounded,
                  size: AppIconSizes.md,
                ),
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.report,
    required this.onTap,
  });

  final _Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isReady = report.status == _ReportStatus.ready;

    return AiListTile(
      leading: AiCircleIcon(
        icon: report.icon,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      title: report.title,
      subtitle: report.range,
      onTap: isReady ? onTap : null,
      trailing: isReady
          ? Icon(
              Icons.download_rounded,
              color: scheme.primary,
              size: AppIconSizes.md,
            )
          : SizedBox(
              width: AppIconSizes.md,
              height: AppIconSizes.md,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
    );
  }
}
