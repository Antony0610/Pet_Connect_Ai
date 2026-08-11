import 'package:flutter/material.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';

/// A generated AI report entry in the archive.
class _Report {
  const _Report(this.icon, this.title, this.range, this.status);

  final IconData icon;
  final String title;
  final String range;
  final _ReportStatus status;
}

/// Whether a report is ready to view or still generating.
enum _ReportStatus { ready, generating }

/// **AI Reports** — `/owner/ai/reports`.
///
/// A featured, gradient-bordered weekly wellness report over an archive of
/// previously generated reports. Token-driven; one tree serves both themes.
class AiReportsScreen extends StatelessWidget {
  const AiReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final margin = _horizontalMargin(context.screenWidth);

    const reports = [
      _Report(
        Icons.calendar_view_week_rounded,
        'Weekly Wellness',
        'Aug 1 – Aug 7, 2026',
        _ReportStatus.ready,
      ),
      _Report(
        Icons.calendar_month_rounded,
        'Monthly Summary',
        'July 2026',
        _ReportStatus.ready,
      ),
      _Report(
        Icons.vaccines_rounded,
        'Vaccination Report',
        'Updated Jun 2026',
        _ReportStatus.ready,
      ),
      _Report(
        Icons.insights_rounded,
        'Quarterly Trends',
        'Generating…',
        _ReportStatus.generating,
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(
        context,
        title: 'AI Reports',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Generate report',
            onPressed: () => context.showSnackbar('Generating a new report…'),
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
                  const _FeaturedReport(),
                  AppSpacing.vGapLg,
                  Text(
                    'Report Archive',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < reports.length; i++) ...[
                          if (i > 0)
                            Divider(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                              height: AppSpacing.lg,
                            ),
                          _ReportRow(report: reports[i]),
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

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

/// The featured latest report: a gradient-bordered card summarizing the most
/// recent weekly wellness report with a primary "View report" action.
class _FeaturedReport extends StatelessWidget {
  const _FeaturedReport();

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
                      'Latest: Weekly Wellness',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    Text(
                      'Aug 1 – Aug 7, 2026',
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
            'Buddy had an active, healthy week — activity up 15%, consistent '
            'sleep and stable weight. Full breakdown inside.',
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
                  onPressed: () => context.showSnackbar('Opening report…'),
                ),
              ),
              AppSpacing.hGapSm,
              IconButton.outlined(
                onPressed: () => context.showSnackbar('Sharing report…'),
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
  const _ReportRow({required this.report});

  final _Report report;

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
      onTap: isReady
          ? () => context.showSnackbar('Opening ${report.title}…')
          : null,
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
