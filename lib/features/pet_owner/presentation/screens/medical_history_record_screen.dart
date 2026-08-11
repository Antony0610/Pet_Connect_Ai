import 'package:flutter/material.dart';

import '../../../../core/theme/portal_theme.dart';
import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/health_widgets.dart';

/// **Medical History Record** — `/owner/health/medical`.
///
/// Frozen Stitch comp: a search field, category filter chips, an allergies and
/// a chronic-conditions card (both empty-state in the master), an AI summary
/// banner and a color-coded record-history timeline with a "load older" CTA.
class MedicalHistoryRecordScreen extends StatefulWidget {
  const MedicalHistoryRecordScreen({super.key});

  @override
  State<MedicalHistoryRecordScreen> createState() =>
      _MedicalHistoryRecordScreenState();
}

class _MedicalHistoryRecordScreenState
    extends State<MedicalHistoryRecordScreen> {
  static const _filters = ['All', 'Surgery', 'Checkup', 'Emergency'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(context, title: 'Medical History'),
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
                  _SearchBar(),
                  AppSpacing.vGapMd,
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => AppSpacing.hGapSm,
                      itemBuilder: (_, i) => AppChip(
                        label: _filters[i],
                        isSelected: i == _selected,
                        variant: i == _selected
                            ? AppChipVariant.filled
                            : AppChipVariant.outlined,
                        onTap: () => setState(() => _selected = i),
                      ),
                    ),
                  ),
                  AppSpacing.vGapLg,
                  const _MedicalCards(),
                  AppSpacing.vGapLg,
                  const _AiSummaryCard(),
                  AppSpacing.vGapLg,
                  const _RecordHistory(),
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

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return TextField(
      decoration: InputDecoration(
        hintText: 'Search records',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: AppRadius.brPill,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
    );
  }
}

class _MedicalCards extends StatelessWidget {
  const _MedicalCards();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    Widget card({
      required IconData icon,
      required Color iconBg,
      required Color iconFg,
      required String title,
      required IconData emptyIcon,
    }) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HealthCardHeader(
              icon: icon,
              iconBackground: iconBg,
              iconColor: iconFg,
              title: title,
            ),
            AppSpacing.vGapMd,
            HealthEmptyBox(icon: emptyIcon, label: 'None reported'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card(
          icon: Icons.coronavirus_rounded,
          iconBg: scheme.errorContainer,
          iconFg: scheme.onErrorContainer,
          title: 'Known Allergies',
          emptyIcon: Icons.check_circle_outline_rounded,
        ),
        AppSpacing.vGapMd,
        card(
          icon: Icons.monitor_heart_rounded,
          iconBg: scheme.tertiaryContainer,
          iconFg: scheme.onTertiaryContainer,
          title: 'Chronic Conditions',
          emptyIcon: Icons.check_circle_outline_rounded,
        ),
      ],
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard();

  @override
  Widget build(BuildContext context) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;
    final scheme = context.colorScheme;
    final container = palette.accentContainer(brightness);
    final onContainer = palette.onAccentContainer(brightness);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brSection,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            container.withValues(alpha: 0.6),
            scheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HealthCircleIcon(
            icon: Icons.auto_awesome_rounded,
            background: container,
            foreground: onContainer,
            size: 40,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Health Summary',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  'Buddy has a clean health record with routine care up to '
                  'date. The next recommended checkup is in 4 months.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _RecordHistory extends StatelessWidget {
  const _RecordHistory();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final records = <_TimelineRecord>[
      _TimelineRecord(
        color: scheme.primary,
        icon: Icons.medical_services_rounded,
        title: 'Neutering Procedure',
        date: 'Oct 12, 2023',
        category: 'Surgery',
      ),
      _TimelineRecord(
        color: scheme.tertiary,
        icon: Icons.health_and_safety_rounded,
        title: 'Annual Wellness Checkup',
        date: 'Jun 05, 2023',
        category: 'Checkup',
      ),
      _TimelineRecord(
        color: scheme.error,
        icon: Icons.emergency_rounded,
        title: 'Gastrointestinal Upset',
        date: 'Jan 22, 2023',
        category: 'Emergency',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Record History',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ),
        for (var i = 0; i < records.length; i++)
          _TimelineTile(record: records[i], isLast: i == records.length - 1),
        AppSpacing.vGapSm,
        Center(
          child: AppButton.outlined(
            label: 'Load Older Records',
            icon: Icons.history_rounded,
            onPressed: () => context.showSnackbar('Loading older records…'),
          ),
        ),
      ],
    );
  }
}

class _TimelineRecord {
  const _TimelineRecord({
    required this.color,
    required this.icon,
    required this.title,
    required this.date,
    required this.category,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String date;
  final String category;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.record, required this.isLast});

  final _TimelineRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: record.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  record.icon,
                  color: record.color,
                  size: AppIconSizes.sm,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: scheme.outlineVariant),
                ),
            ],
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            record.date,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    HealthCategoryChip(
                      label: record.category,
                      background: record.color.withValues(alpha: 0.15),
                      foreground: record.color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
