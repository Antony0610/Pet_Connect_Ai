import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/health_widgets.dart';

/// **Health Passport Timeline** — `/owner/health/timeline`.
///
/// Frozen Stitch comp: category filter chips over a center-line vertical
/// timeline. Each event is color-coded by category (Medical=error,
/// AI=primary, Growth=tertiary, Vaccine=secondary) with an icon node, a card
/// with title/detail/timestamp and — for growth — a weight-trend line.
class HealthPassportTimelineScreen extends StatefulWidget {
  const HealthPassportTimelineScreen({super.key});

  @override
  State<HealthPassportTimelineScreen> createState() =>
      _HealthPassportTimelineScreenState();
}

class _HealthPassportTimelineScreenState
    extends State<HealthPassportTimelineScreen> {
  static const _filters = ['All', 'Medical', 'AI', 'Growth', 'Vaccines'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);

    final events = _events(context);
    final visible = _selected == 0
        ? events
        : events.where((e) => e.category == _filters[_selected]).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(context, title: 'Timeline'),
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
                  for (var i = 0; i < visible.length; i++)
                    _TimelineNode(
                      event: visible[i],
                      isLast: i == visible.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_TimelineEvent> _events(BuildContext context) {
    final scheme = context.colorScheme;
    return [
      _TimelineEvent(
        category: 'Medical',
        color: scheme.error,
        onColor: scheme.onError,
        icon: Icons.medical_services_rounded,
        title: 'Neutering Procedure',
        detail: 'Routine surgery completed successfully at PetCare Clinic.',
        timestamp: 'Oct 12, 2023 · 9:30 AM',
      ),
      _TimelineEvent(
        category: 'AI',
        color: scheme.primary,
        onColor: scheme.onPrimary,
        icon: Icons.smart_toy_rounded,
        title: 'AI Wellness Analysis',
        detail: "Buddy's vitals are trending positively. Activity up 12%.",
        timestamp: 'Sep 28, 2023 · 2:15 PM',
        gradient: true,
      ),
      _TimelineEvent(
        category: 'Growth',
        color: scheme.tertiary,
        onColor: scheme.onTertiary,
        icon: Icons.monitor_weight_rounded,
        title: 'Weight Check',
        detail: 'Logged at home assessment.',
        timestamp: 'Sep 15, 2023 · 8:00 AM',
        weight: '64.5 lbs',
        weightTrend: '-0.5 lbs',
      ),
      _TimelineEvent(
        category: 'Vaccines',
        color: scheme.secondary,
        onColor: scheme.onSecondary,
        icon: Icons.vaccines_rounded,
        title: 'Bordetella Vaccine',
        detail: 'Administered by Dr. Smith.',
        timestamp: 'Aug 05, 2023 · 11:00 AM',
      ),
    ];
  }

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.category,
    required this.color,
    required this.onColor,
    required this.icon,
    required this.title,
    required this.detail,
    required this.timestamp,
    this.gradient = false,
    this.weight,
    this.weightTrend,
  });

  final String category;
  final Color color;
  final Color onColor;
  final IconData icon;
  final String title;
  final String detail;
  final String timestamp;
  final bool gradient;
  final String? weight;
  final String? weightTrend;
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.event, required this.isLast});

  final _TimelineEvent event;
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 3),
                ),
                child: Icon(event.icon, color: event.onColor, size: AppIconSizes.sm),
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
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: _EventCard(event: event),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final _TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
            HealthCategoryChip(
              label: event.category,
              background: event.color.withValues(alpha: 0.15),
              foreground: event.color,
            ),
          ],
        ),
        AppSpacing.vGapXs,
        Text(
          event.detail,
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (event.weight != null) ...[
          AppSpacing.vGapSm,
          Row(
            children: [
              Text(
                event.weight!,
                style: context.textTheme.titleMedium?.copyWith(
                  color: event.color,
                  fontWeight: AppTypography.bold,
                ),
              ),
              AppSpacing.hGapSm,
              if (event.weightTrend != null)
                Text(
                  event.weightTrend!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
            ],
          ),
        ],
        AppSpacing.vGapSm,
        Text(
          event.timestamp,
          style: context.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (!event.gradient) {
      return AppCard(child: content);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brCard,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            event.color.withValues(alpha: 0.12),
            scheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: event.color.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: content,
    );
  }
}
