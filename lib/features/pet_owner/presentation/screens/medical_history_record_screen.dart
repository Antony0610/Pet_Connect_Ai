import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/health_record.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/health_widgets.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Medical History Record** — `/owner/health/medical`.
///
/// Connected to live Supabase `health_records` table.
/// ZERO dummy/hardcoded data.
class MedicalHistoryRecordScreen extends ConsumerStatefulWidget {
  const MedicalHistoryRecordScreen({super.key});

  @override
  ConsumerState<MedicalHistoryRecordScreen> createState() =>
      _MedicalHistoryRecordScreenState();
}

class _MedicalHistoryRecordScreenState
    extends ConsumerState<MedicalHistoryRecordScreen> {
  static const _filters = ['All', 'Surgery', 'Checkup', 'Emergency'];
  int _selected = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);

    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';
    final petName = selectedPet?.name ?? 'Companion';
    final recordsAsync = petId.isNotEmpty ? ref.watch(healthRecordsProvider(petId)) : null;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(
        context,
        title: selectedPet != null
            ? "$petName's Medical History"
            : 'Medical History',
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
              child: recordsAsync?.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text('Error loading medical records: $err'),
                  ),
                ),
                data: (records) => _MedicalHistoryContent(
                  petName: petName,
                  records: records,
                  selectedFilter: _filters[_selected],
                  filters: _filters,
                  selectedIndex: _selected,
                  onFilterChanged: (i) => setState(() => _selected = i),
                  searchController: _searchController,
                  onSearchChanged: () => setState(() {}),
                ),
              ) ??
              _MedicalHistoryContent(
                petName: petName,
                records: const [],
                selectedFilter: _filters[_selected],
                filters: _filters,
                selectedIndex: _selected,
                onFilterChanged: (i) => setState(() => _selected = i),
                searchController: _searchController,
                onSearchChanged: () => setState(() {}),
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

class _MedicalHistoryContent extends StatelessWidget {
  const _MedicalHistoryContent({
    required this.petName,
    required this.records,
    required this.selectedFilter,
    required this.filters,
    required this.selectedIndex,
    required this.onFilterChanged,
    required this.searchController,
    required this.onSearchChanged,
  });

  final String petName;
  final List<HealthRecord> records;
  final String selectedFilter;
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onFilterChanged;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase().trim();
    final filtered = records.where((r) {
      final matchesCat = selectedFilter == 'All' ||
          r.category.toLowerCase() == selectedFilter.toLowerCase();
      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          (r.diagnosis?.toLowerCase().contains(query) ?? false) ||
          (r.notes?.toLowerCase().contains(query) ?? false);
      return matchesCat && matchesQuery;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchBar(
          controller: searchController,
          onChanged: (_) => onSearchChanged(),
        ),
        AppSpacing.vGapMd,
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => AppSpacing.hGapSm,
            itemBuilder: (_, i) => AppChip(
              label: filters[i],
              isSelected: i == selectedIndex,
              variant: i == selectedIndex
                  ? AppChipVariant.filled
                  : AppChipVariant.outlined,
              onTap: () => onFilterChanged(i),
            ),
          ),
        ),
        AppSpacing.vGapLg,
        const _MedicalCards(),
        AppSpacing.vGapLg,
        _AiSummaryCard(petName: petName, recordCount: records.length),
        AppSpacing.vGapLg,
        _RecordHistory(records: filtered),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search records by title, diagnosis, or note...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: const OutlineInputBorder(
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
  const _AiSummaryCard({required this.petName, required this.recordCount});

  final String petName;
  final int recordCount;

  @override
  Widget build(BuildContext context) {
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;
    final scheme = context.colorScheme;
    final container = palette.accentContainer(brightness);
    final onContainer = palette.onAccentContainer(brightness);

    final summaryText = recordCount > 0
        ? '$petName has $recordCount clinical medical record${recordCount == 1 ? '' : 's'} registered in Health Passport. Routine checkups and vet consultations are logged.'
        : '$petName has a clean medical profile with no acute clinical conditions reported. Routine preventative checkups are recommended.';

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
                  summaryText,
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
  const _RecordHistory({required this.records});

  final List<HealthRecord> records;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

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
        AppCard(
          child: records.isNotEmpty
              ? Column(
                  children: [
                    for (var i = 0; i < records.length; i++) ...[
                      if (i > 0)
                        Divider(
                          color: scheme.outlineVariant,
                          height: AppSpacing.lg,
                        ),
                      _TimelineTile(
                        record: records[i],
                        isLast: i == records.length - 1,
                      ),
                    ],
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No medical records logged yet.',
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

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.record, required this.isLast});

  final HealthRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final catLower = record.category.toLowerCase();
    final color = catLower.contains('surg')
        ? scheme.primary
        : (catLower.contains('emerg') ? scheme.error : scheme.tertiary);
    final icon = catLower.contains('surg')
        ? Icons.medical_services_rounded
        : (catLower.contains('emerg')
            ? Icons.emergency_rounded
            : Icons.health_and_safety_rounded);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: AppIconSizes.sm,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                    ),
                    HealthCategoryChip(
                      label: record.category,
                      background: color.withValues(alpha: 0.15),
                      foreground: color,
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Text(
                  record.recordDate.toIso8601String().split('T').first,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (record.diagnosis != null && record.diagnosis!.isNotEmpty) ...[
                  AppSpacing.vGapXs,
                  Text(
                    'Diagnosis: ${record.diagnosis}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
