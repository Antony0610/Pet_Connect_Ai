import 'package:flutter/material.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/health_widgets.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Vaccination Overview** — `/owner/health/vaccinations`.
///
/// Frozen Stitch comp: an emerald "fully protected" status banner, a core
/// completion progress card, an "upcoming next" schedule card and a completed
/// history list where each row taps through to a certificate.
class VaccinationOverviewScreen extends StatelessWidget {
  const VaccinationOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(context, title: 'Vaccinations'),
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
                  _StatusBanner(
                    accent: palette.accent,
                    onAccent: scheme.onPrimary,
                  ),
                  AppSpacing.vGapLg,
                  _CoreCompletionCard(
                    accent: palette.accent,
                    track: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  AppSpacing.vGapLg,
                  _UpcomingCard(
                    accent: palette.accent,
                    onAccent: scheme.onPrimary,
                    container: palette.accentContainer(brightness),
                    onContainer: palette.onAccentContainer(brightness),
                  ),
                  AppSpacing.vGapLg,
                  const _CompletedHistory(),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.accent, required this.onAccent});

  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: AppRadius.brSection,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: onAccent,
            size: AppIconSizes.xl,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buddy is fully protected',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: onAccent,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  'All core vaccinations are up to date',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: onAccent.withValues(alpha: 0.85),
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

class _CoreCompletionCard extends StatelessWidget {
  const _CoreCompletionCard({required this.accent, required this.track});

  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Core Completion',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
              Text(
                '100%',
                style: context.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: 1,
              minHeight: 10,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            '5 of 5 core vaccines complete',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
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
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HealthCardHeader(
            icon: Icons.event_rounded,
            iconBackground: container,
            iconColor: onContainer,
            title: 'Upcoming Next',
          ),
          AppSpacing.vGapMd,
          Text(
            'DHPP Booster',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapXs,
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: AppIconSizes.xs,
                color: scheme.onSurfaceVariant,
              ),
              AppSpacing.hGapXs,
              Text(
                'Due in 3 months',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          HealthAccentButton(
            label: 'Schedule Appointment',
            icon: Icons.calendar_month_rounded,
            accent: accent,
            onAccent: onAccent,
            onPressed: () => context.showSnackbar('Opening scheduler…'),
          ),
        ],
      ),
    );
  }
}

class _CompletedHistory extends StatelessWidget {
  const _CompletedHistory();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    const records = [
      ('Rabies (1 Year)', 'Oct 12, 2023'),
      ('Bordetella', 'Aug 05, 2023'),
      ('Parvovirus (CPV)', 'May 20, 2023'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Completed History',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < records.length; i++) ...[
                if (i > 0)
                  Divider(color: scheme.outlineVariant, height: AppSpacing.lg),
                HealthRecordRow(
                  leading: HealthCircleIcon(
                    icon: Icons.check_circle_rounded,
                    background: scheme.secondaryContainer,
                    foreground: scheme.onSecondaryContainer,
                  ),
                  title: records[i].$1,
                  meta: [
                    HealthMetaLine(records[i].$2, icon: Icons.event_rounded),
                  ],
                  trailing: TextButton(
                    onPressed: () =>
                        context.showSnackbar('Opening certificate…'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                    ),
                    child: const Text('View Certificate'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
