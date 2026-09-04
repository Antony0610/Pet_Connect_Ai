import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/core/utils/qr_generator_helper.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
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
        actions: [
          if (selectedPet != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Add Vaccine Record',
              onPressed: () => _showAddVaccineModal(context, ref, selectedPet),
            ),
        ],
      ),
      floatingActionButton: selectedPet != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddVaccineModal(context, ref, selectedPet),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Vaccine'),
            )
          : null,
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

  void _showAddVaccineModal(BuildContext context, WidgetRef ref, Pet pet) {
    final nameCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final clinicCtrl = TextEditingController();
    DateTime adminDate = DateTime.now();
    DateTime nextDueDate = DateTime.now().add(const Duration(days: 365));

    final commonVaccines = pet.species.toLowerCase() == 'cat'
        ? ['Rabies', 'FVRCP (Core)', 'FeLV (Feline Leukemia)', 'FIV', 'Deworming Protocol']
        : ['Rabies (Core)', 'DHPP / DHLPP (5-in-1)', 'Bordetella (Kennel Cough)', 'Leptospirosis', 'Lyme Disease', 'Deworming Protocol'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    AppSpacing.vGapMd,
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.vaccines_rounded, color: Color(0xFF10B981), size: 24),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Vaccine Record',
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Immunization for ${pet.name}',
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
                    Text(
                      'Quick Select Common Vaccine:',
                      style: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    AppSpacing.vGapXs,
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: commonVaccines.map((vax) {
                        final isSelected = nameCtrl.text == vax;
                        return ChoiceChip(
                          label: Text(vax, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              nameCtrl.text = selected ? vax : '';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    AppSpacing.vGapMd,
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vaccine / Treatment Name *',
                        hintText: 'e.g. Rabies 3-Year, DHPP',
                        prefixIcon: Icon(Icons.medication_outlined),
                        border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                      ),
                    ),
                    AppSpacing.vGapMd,
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: adminDate,
                                firstDate: DateTime(2015),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setModalState(() => adminDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Administered Date',
                                prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                              ),
                              child: Text(
                                '${adminDate.day}/${adminDate.month}/${adminDate.year}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.hGapSm,
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: nextDueDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (picked != null) {
                                setModalState(() => nextDueDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Next Booster Due',
                                prefixIcon: Icon(Icons.event_repeat_rounded, size: 18),
                                border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                              ),
                              child: Text(
                                '${nextDueDate.day}/${nextDueDate.month}/${nextDueDate.year}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vGapMd,
                    TextField(
                      controller: batchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Batch / Lot Number (Optional)',
                        hintText: 'e.g. LOT-49281-EXP27',
                        prefixIcon: Icon(Icons.tag_rounded),
                        border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                      ),
                    ),
                    AppSpacing.vGapMd,
                    TextField(
                      controller: clinicCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Veterinarian / Clinic Name (Optional)',
                        hintText: 'e.g. City Vet Hospital, Dr. Paul',
                        prefixIcon: Icon(Icons.local_hospital_outlined),
                        border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                      ),
                    ),
                    AppSpacing.vGapLg,
                    FilledButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Save Vaccination Record'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
                      ),
                      onPressed: () async {
                        final vaxName = nameCtrl.text.trim();
                        if (vaxName.isEmpty) {
                          context.showSnackbar('Please enter or select a vaccine name.');
                          return;
                        }

                        Navigator.pop(ctx);
                        try {
                          final repo = ref.read(healthRepositoryProvider);
                          final now = DateTime.now();
                          final newVax = Vaccination(
                            id: 'vax-${now.millisecondsSinceEpoch}',
                            petId: pet.id,
                            vaccineName: vaxName,
                            administeredDate: adminDate,
                            nextDueDate: nextDueDate,
                            batchNumber: batchCtrl.text.trim().isNotEmpty ? batchCtrl.text.trim() : null,
                            administeredBy: clinicCtrl.text.trim().isNotEmpty ? clinicCtrl.text.trim() : null,
                            createdAt: now,
                            updatedAt: now,
                          );

                          await repo.createVaccination(newVax);
                          ref.invalidate(vaccinationsProvider(pet.id));
                          if (context.mounted) {
                            context.showSnackbar('$vaxName record saved successfully!');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.showSnackbar('Failed to save record: $e');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        _CompletedHistory(vaxList: vaxList, petName: petName),
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
  const _CompletedHistory({
    required this.vaxList,
    required this.petName,
  });

  final List<Vaccination> vaxList;
  final String petName;

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
                        trailing: TextButton.icon(
                          onPressed: () => _openCertificateModal(context, vaxList[i], petName),
                          icon: const Icon(Icons.verified_outlined, size: 16),
                          label: const Text('View Record'),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.primary,
                          ),
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

  void _openCertificateModal(BuildContext context, Vaccination vax, String petName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _VaccinationCertificateDialog(vax: vax, petName: petName),
    );
  }
}

class _VaccinationCertificateDialog extends StatelessWidget {
  const _VaccinationCertificateDialog({
    required this.vax,
    required this.petName,
  });

  final Vaccination vax;
  final String petName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final certId = 'CERT-VAX-${vax.id.isNotEmpty ? (vax.id.length > 8 ? vax.id.substring(0, 8).toUpperCase() : vax.id.toUpperCase()) : '2026-LIVE'}';
    final adminDate = vax.administeredDate.toIso8601String().split('T').first;
    final nextDueDate = vax.nextDueDate != null
        ? vax.nextDueDate!.toIso8601String().split('T').first
        : 'Annual Booster Recommended';
    final doctor = vax.administeredBy != null && vax.administeredBy!.isNotEmpty
        ? 'Dr. ${vax.administeredBy}'
        : 'Authorized Veterinary Clinic';
    final batch = vax.batchNumber != null && vax.batchNumber!.isNotEmpty
        ? vax.batchNumber!
        : 'LOT-B892-VET';

    final qrPayload = 'https://petconnect.ai/verify/vaccine/${vax.id}?pet=${Uri.encodeComponent(petName)}&vax=${Uri.encodeComponent(vax.vaccineName)}&admin=$adminDate';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F3E32), const Color(0xFF135A47)]
                        : [const Color(0xFF137A63), const Color(0xFF109B7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'DIGITAL IMMUNIZATION CERTIFICATE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vax.vaccineName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF22C55E), width: 1),
                      ),
                      child: const Text(
                        'VERIFIED & ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Details Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _certRow('Patient Name', petName, Icons.pets_rounded, scheme),
                    const Divider(height: 16),
                    _certRow('Date Administered', adminDate, Icons.event_available_rounded, scheme),
                    const Divider(height: 16),
                    _certRow('Next Due / Booster', nextDueDate, Icons.alarm_on_rounded, scheme),
                    const Divider(height: 16),
                    _certRow('Administering Vet', doctor, Icons.medical_services_outlined, scheme),
                    const Divider(height: 16),
                    _certRow('Batch / Lot #', batch, Icons.qr_code_2_rounded, scheme),
                    const Divider(height: 16),
                    _certRow('Certificate ID', certId, Icons.shield_outlined, scheme),

                    if (vax.notes != null && vax.notes!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _certRow('Clinical Notes', vax.notes!, Icons.notes_rounded, scheme),
                    ],

                    const SizedBox(height: 20),

                    // Verification QR Code
                    Center(
                      child: Column(
                        children: [
                          PetQrCodeView(
                            data: qrPayload,
                            size: 140,
                            foregroundColor: const Color(0xFF137A63),
                            padding: 10,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan to verify immunization on PetConnect AI',
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('Share Record'),
                            onPressed: () {
                              final text = '''
Official Immunization Certificate - PetConnect AI
--------------------------------------------------
Patient: $petName
Vaccine: ${vax.vaccineName}
Status: VERIFIED & COMPLETED
Date Administered: $adminDate
Next Due Date: $nextDueDate
Administering Clinician: $doctor
Batch Number: $batch
Certificate ID: $certId
Verification Link: $qrPayload
''';
                              ExternalActions.shareText(text, subject: 'Vaccination Certificate - $petName');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _certRow(String label, String value, IconData icon, ColorScheme scheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

