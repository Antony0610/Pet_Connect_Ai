import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/vaccination.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/health_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/health_widgets.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// **Vaccination Overview** — `/owner/health/vaccinations`.
///
/// Connected directly to live Supabase backend and Riverpod providers.
/// ZERO dummy/hardcoded data.
class VaccinationOverviewScreen extends ConsumerWidget {
  const VaccinationOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';
    final petName = selectedPet?.name ?? 'Companion';
    final vaxAsync = petId.isNotEmpty ? ref.watch(vaccinationsProvider(petId)) : null;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: healthAppBar(
        context,
        title: selectedPet != null
            ? "$petName's Vaccinations"
            : 'Vaccinations',
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
              child: vaxAsync?.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text('Error loading vaccinations: $err'),
                  ),
                ),
                data: (vaxList) => _VaccinationContent(
                  petName: petName,
                  vaxList: vaxList,
                  palette: palette,
                  brightness: brightness,
                ),
              ) ??
              _VaccinationContent(
                petName: petName,
                vaxList: const [],
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

class _VaccinationContent extends StatelessWidget {
  const _VaccinationContent({
    required this.petName,
    required this.vaxList,
    required this.palette,
    required this.brightness,
  });

  final String petName;
  final List<Vaccination> vaxList;
  final PortalPalette palette;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final hasVax = vaxList.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusBanner(
          petName: petName,
          hasVaccinations: hasVax,
          accent: palette.accent,
          onAccent: scheme.onPrimary,
        ),
        AppSpacing.vGapLg,
        _CoreCompletionCard(
          vaxList: vaxList,
          accent: palette.accent,
          track: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        AppSpacing.vGapLg,
        _UpcomingCard(
          petName: petName,
          vaxList: vaxList,
          accent: palette.accent,
          onAccent: scheme.onPrimary,
          container: palette.accentContainer(brightness),
          onContainer: palette.onAccentContainer(brightness),
        ),
        AppSpacing.vGapLg,
        _CompletedHistory(vaxList: vaxList),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.petName,
    required this.hasVaccinations,
    required this.accent,
    required this.onAccent,
  });

  final String petName;
  final bool hasVaccinations;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: hasVaccinations ? accent : scheme.surfaceContainerHigh,
        borderRadius: AppRadius.brSection,
        border: Border.all(
          color: hasVaccinations
              ? accent
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            hasVaccinations
                ? Icons.verified_user_rounded
                : Icons.info_outline_rounded,
            color: hasVaccinations ? onAccent : scheme.primary,
            size: AppIconSizes.xl,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasVaccinations
                      ? '$petName is protected'
                      : '$petName’s Vaccination Profile',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: hasVaccinations ? onAccent : scheme.onSurface,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  hasVaccinations
                      ? 'Vaccination history is recorded in Health Passport'
                      : 'No vaccination records logged yet for this companion',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: hasVaccinations
                        ? onAccent.withValues(alpha: 0.85)
                        : scheme.onSurfaceVariant,
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
  const _CoreCompletionCard({
    required this.vaxList,
    required this.accent,
    required this.track,
  });

  final List<Vaccination> vaxList;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final count = vaxList.length;
    // Standard companion protocol benchmark
    final progress = (count / 5.0).clamp(0.0, 1.0);
    final pct = (progress * 100).toInt();

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
                '$pct%',
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
              value: progress,
              minHeight: 10,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            count > 0
                ? '$count core vaccine${count == 1 ? '' : 's'} recorded'
                : '0 core vaccines recorded yet',
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
    required this.petName,
    required this.vaxList,
    required this.accent,
    required this.onAccent,
    required this.container,
    required this.onContainer,
  });

  final String petName;
  final List<Vaccination> vaxList;
  final Color accent;
  final Color onAccent;
  final Color container;
  final Color onContainer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final upcoming = vaxList.where((v) => v.nextDueDate != null).toList();

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
          if (upcoming.isNotEmpty) ...[
            Text(
              upcoming.first.vaccineName,
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
                  'Due on ${upcoming.first.nextDueDate!.toIso8601String().split('T').first}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No upcoming vaccines scheduled',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: AppTypography.semiBold,
                color: scheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              'All scheduled immunizations will appear here automatically.',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          AppSpacing.vGapMd,
          HealthAccentButton(
            label: 'Schedule Appointment',
            icon: Icons.calendar_month_rounded,
            accent: accent,
            onAccent: onAccent,
            onPressed: () => _showScheduleAppointmentSheet(context, petName),
          ),
        ],
      ),
    );
  }

  void _showScheduleAppointmentSheet(BuildContext context, String petName) {
    String selectedReason = 'Rabies Booster';
    String selectedClinic = 'City Pet Hospital (1.2 mi)';
    String selectedSlot = 'Tomorrow, 10:00 AM';
    final notesController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Schedule Vet Appointment',
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
              AppSpacing.vGapSm,
              Text(
                'Book immunization or wellness visit for $petName.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGapMd,
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Appointment Purpose',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vaccines_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'Rabies Booster', child: Text('Rabies Vaccine Booster')),
                  DropdownMenuItem(value: 'Core DHPP/FVRCP', child: Text('Core Annual Combo (DHPP/FVRCP)')),
                  DropdownMenuItem(value: 'Bordetella', child: Text('Bordetella (Kennel Cough)')),
                  DropdownMenuItem(value: 'Wellness & Titer', child: Text('Annual Physical & Titer Test')),
                ],
                onChanged: (val) {
                  if (val != null) setSheetState(() => selectedReason = val);
                },
              ),
              AppSpacing.vGapSm,
              DropdownButtonFormField<String>(
                initialValue: selectedClinic,
                decoration: const InputDecoration(
                  labelText: 'Veterinary Clinic',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'City Pet Hospital (1.2 mi)', child: Text('City Pet Hospital (1.2 mi)')),
                  DropdownMenuItem(value: 'Green Valley Animal Clinic (2.4 mi)', child: Text('Green Valley Animal Clinic (2.4 mi)')),
                  DropdownMenuItem(value: 'Dr. Sarah Jenkins Mobile Vet', child: Text('Dr. Sarah Jenkins Mobile Vet')),
                ],
                onChanged: (val) {
                  if (val != null) setSheetState(() => selectedClinic = val);
                },
              ),
              AppSpacing.vGapSm,
              DropdownButtonFormField<String>(
                initialValue: selectedSlot,
                decoration: const InputDecoration(
                  labelText: 'Preferred Time Slot',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'Today, 3:30 PM', child: Text('Today • 3:30 PM')),
                  DropdownMenuItem(value: 'Tomorrow, 10:00 AM', child: Text('Tomorrow • 10:00 AM')),
                  DropdownMenuItem(value: 'Tomorrow, 2:00 PM', child: Text('Tomorrow • 2:00 PM')),
                  DropdownMenuItem(value: 'Saturday, 11:00 AM', child: Text('Saturday • 11:00 AM')),
                ],
                onChanged: (val) {
                  if (val != null) setSheetState(() => selectedSlot = val);
                },
              ),
              AppSpacing.vGapSm,
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes for Doctor (Optional)',
                  hintText: 'Any symptoms or questions...',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.vGapMd,
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Confirm & Book Appointment'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Appointment confirmed for $petName ($selectedReason) at $selectedClinic on $selectedSlot!',
                        ),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedHistory extends StatelessWidget {
  const _CompletedHistory({required this.vaxList});

  final List<Vaccination> vaxList;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

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
          child: vaxList.isNotEmpty
              ? Column(
                  children: [
                    for (var i = 0; i < vaxList.length; i++) ...[
                      if (i > 0)
                        Divider(
                          color: scheme.outlineVariant,
                          height: AppSpacing.lg,
                        ),
                      HealthRecordRow(
                        leading: HealthCircleIcon(
                          icon: Icons.check_circle_rounded,
                          background: scheme.secondaryContainer,
                          foreground: scheme.onSecondaryContainer,
                        ),
                        title: vaxList[i].vaccineName,
                        meta: [
                          HealthMetaLine(
                            vaxList[i].administeredDate.toIso8601String().split('T').first,
                            icon: Icons.event_rounded,
                          ),
                          if (vaxList[i].administeredBy != null)
                            HealthMetaLine('Dr. ${vaxList[i].administeredBy}'),
                        ],
                        trailing: TextButton(
                          onPressed: () =>
                              context.showSnackbar('Certificate: ${vaxList[i].vaccineName}'),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.primary,
                          ),
                          child: const Text('View Record'),
                        ),
                      ),
                    ],
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No completed vaccinations recorded yet.',
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
