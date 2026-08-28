import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_timeline_event.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/health_widgets.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Health Passport Timeline** — `/owner/health/timeline`.
///
/// Connected to live Supabase `health_timeline_events` & `health_records`.
/// ZERO dummy/hardcoded data.
class HealthPassportTimelineScreen extends ConsumerStatefulWidget {
  const HealthPassportTimelineScreen({super.key});

  @override
  ConsumerState<HealthPassportTimelineScreen> createState() =>
      _HealthPassportTimelineScreenState();
}

class _HealthPassportTimelineScreenState
    extends ConsumerState<HealthPassportTimelineScreen> {
  static const _filters = ['All', 'Medical', 'AI', 'Growth', 'Vaccines'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';
    final petName = selectedPet?.name ?? 'Companion';

    final eventsAsync = petId.isNotEmpty ? ref.watch(healthTimelineEventsProvider(petId)) : null;
    final recordsAsync = petId.isNotEmpty ? ref.watch(healthRecordsProvider(petId)) : null;

    final eventsList = eventsAsync?.valueOrNull ?? <HealthTimelineEvent>[];
    final recordsList = recordsAsync?.valueOrNull ?? <HealthRecord>[];

    // Combine timeline events and medical records
    final combinedEvents = <_DisplayEvent>[
      ...eventsList.map((e) => _DisplayEvent(
        category: e.category,
        title: e.title,
        detail: e.description ?? '',
        timestamp: e.eventDate.toIso8601String().split('T').first,
        icon: _iconForCategory(e.category),
        color: _colorForCategory(e.category, scheme),
      )),
      ...recordsList.map((r) => _DisplayEvent(
        category: r.category,
        title: r.title,
        detail: r.diagnosis ?? r.notes ?? 'Recorded by ${r.veterinarianName ?? 'Clinic'}',
        timestamp: r.recordDate.toIso8601String().split('T').first,
        icon: Icons.medical_services_rounded,
        color: scheme.primary,
      )),
    ];

    final visible = _selected == 0
        ? combinedEvents
        : combinedEvents.where((e) => e.category.toLowerCase() == _filters[_selected].toLowerCase()).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(
        context,
        title: selectedPet != null
            ? "$petName's Timeline"
            : 'Timeline',
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
                  if (visible.isNotEmpty) ...[
                    for (var i = 0; i < visible.length; i++)
                      _TimelineNode(
                        event: visible[i],
                        isLast: i == visible.length - 1,
                      ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.timeline_rounded,
                              size: AppIconSizes.xl,
                              color: scheme.primary,
                            ),
                          ),
                          AppSpacing.vGapLg,
                          Text(
                            'No Timeline Events Yet',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          AppSpacing.vGapSm,
                          Text(
                            'No health events or checkups have been logged yet for $petName. Completed vaccinations, vet visits, and weigh-ins will automatically appear in this timeline.',
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('vax') || lower.contains('vaccin')) return Icons.vaccines_rounded;
    if (lower.contains('grow') || lower.contains('weight')) return Icons.monitor_weight_rounded;
    if (lower.contains('ai')) return Icons.smart_toy_rounded;
    return Icons.medical_services_rounded;
  }

  static Color _colorForCategory(String category, ColorScheme scheme) {
    final lower = category.toLowerCase();
    if (lower.contains('vax') || lower.contains('vaccin')) return scheme.secondary;
    if (lower.contains('grow') || lower.contains('weight')) return scheme.tertiary;
    if (lower.contains('ai')) return scheme.primary;
    return scheme.error;
  }

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

class _DisplayEvent {
  const _DisplayEvent({
    required this.category,
    required this.title,
    required this.detail,
    required this.timestamp,
    required this.icon,
    required this.color,
  });

  final String category;
  final String title;
  final String detail;
  final String timestamp;
  final IconData icon;
  final Color color;
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.event, required this.isLast});

  final _DisplayEvent event;
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
                  color: event.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(event.icon, color: event.color, size: AppIconSizes.sm),
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
                child: Column(
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
                      event.timestamp,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGapSm,
                    Text(
                      event.detail,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
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
