import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_patient.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class PatientMedicalRecordScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientMedicalRecordScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientMedicalRecordScreen> createState() =>
      _PatientMedicalRecordScreenState();
}

class _PatientMedicalRecordScreenState extends ConsumerState<PatientMedicalRecordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final patientsAsync = ref.watch(vetPatientsProvider(null));
    final patients = patientsAsync.valueOrNull ?? [];
    final patient = patients.firstWhere(
      (p) => p.id == widget.patientId,
      orElse: () => VetPatient(
        id: widget.patientId,
        name: 'Patient Record',
        species: 'canine',
        breed: 'Golden Retriever',
        gender: 'Male Neutered',
        ownerName: 'Sarah J.',
        status: 'Stable',
        healthStatus: 'optimal',
        weightKg: 32.4,
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.vetPatients);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${patient.name}\'s Record',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${patient.breedLine} • ${patient.gender ?? "Unknown"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Secure medical record link generated for ${patient.ownerName}.',
                  ),
                ),
              );
            },
            tooltip: 'Share Record',
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => context.push('${RoutePaths.vetTreatmentPlan}?patientId=${patient.id}'),
            tooltip: 'Treatment Plan',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Patient Metadata Card
              _buildPatientHeroCard(context, theme, colorScheme, patient),
              const SizedBox(height: 16),

              // Smart Collar Live Telemetry Widget
              _buildLiveCollarWidget(context, theme, colorScheme, patient),
              const SizedBox(height: 16),

              // Record Section Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(text: 'History & Notes'),
                  Tab(text: 'Vaccines'),
                  Tab(text: 'Treatment Plan'),
                  Tab(text: 'AI Insights'),
                ],
              ),
              const SizedBox(height: 16),

              // AI Clinical Insight Banner
              _buildAiInsightBanner(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Clinical Timeline / Notes List
              Text(
                'Clinical History Timeline',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _buildTimelineCard(
                context,
                theme,
                colorScheme,
                title: 'Annual Comprehensive Exam',
                doctor: 'Clinical Practitioner • General Medicine',
                date: DateFormat('MMM d, yyyy').format(DateTime.now()),
                content:
                    'Patient examined with optimal vitals. Normal cardiac rhythm, clear pulmonary fields. Weight at ${patient.weightKg ?? 30.0} kg. Recommended routine preventative protocol.',
                badges: const ['Preventative Care', 'Exam Optimal'],
              ),
              const SizedBox(height: 12),
              _buildTimelineCard(
                context,
                theme,
                colorScheme,
                title: 'Clinical Follow-up & Lab Panel',
                doctor: 'Veterinary Diagnostic Laboratory',
                date: 'Recent Visit',
                content:
                    'Routine biochemistry and CBC panel unremarkable. Renal and hepatic markers within reference boundaries. Microchip #${patient.microchipId ?? "Verified"} confirmed.',
                badges: const ['Biochem Normal', 'CBC Verified'],
              ),
              const SizedBox(height: 20),

              // Health Passport Vaccines Summary
              _buildVaccinesSummaryCard(context, theme, colorScheme),
              const SizedBox(height: 24),

              // Primary Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.assignment),
                      label: const Text('Treatment Plan'),
                      onPressed: () => context.push('${RoutePaths.vetTreatmentPlan}?patientId=${patient.id}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Start Consultation',
                      onPressed: () => context.push('${RoutePaths.vetConsultation}?appointmentId=${patient.id}'),
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      height: 44,
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

  Widget _buildPatientHeroCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    VetPatient patient,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          patient.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppChip(
                          label: patient.status,
                          backgroundColor: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.breedLine} • Guardian: ${patient.ownerName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetaItem(theme, colorScheme, 'Weight', '${patient.weightKg ?? 30.0} kg'),
              _buildMetaItem(theme, colorScheme, 'Status', patient.healthStatus.toUpperCase()),
              _buildMetaItem(theme, colorScheme, 'Owner', patient.ownerName),
              _buildMetaItem(theme, colorScheme, 'Phone', patient.ownerPhone ?? 'On File'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveCollarWidget(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    VetPatient patient,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.watch_rounded, color: colorScheme.tertiary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Collar Live Telemetry HUD',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                  ),
                ),
                Text(
                  '78 BPM • Resting HR baseline normal • Active Collar Sync',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            color: colorScheme.tertiary,
            onPressed: () => context.push('/owner/collar-tracking'),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Clinical Intelligence Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vitals and metabolic profile are stable. No drug allergy contraindications detected in recent electronic prescription records.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String doctor,
    required String date,
    required String content,
    required List<String> badges,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            doctor,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: badges
                .map(
                  (b) => AppChip(
                    label: b,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    textColor: colorScheme.onSurface,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinesSummaryCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Immunization Passport',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppChip(
                label: 'Up to Date',
                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                textColor: AppColors.success,
              ),
            ],
          ),
          const Divider(height: 16),
          _buildVaccineRow(theme, colorScheme, 'DHPP Core Vaccine', 'Valid until Dec 2026'),
          const SizedBox(height: 6),
          _buildVaccineRow(theme, colorScheme, 'Rabies 3-Year Booster', 'Valid until Oct 2027'),
          const SizedBox(height: 6),
          _buildVaccineRow(theme, colorScheme, 'Bordetella Intranasal', 'Valid until Jun 2027'),
        ],
      ),
    );
  }

  Widget _buildVaccineRow(
    ThemeData theme,
    ColorScheme colorScheme,
    String name,
    String expiry,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: AppColors.success),
            const SizedBox(width: 8),
            Text(name, style: theme.textTheme.bodyMedium),
          ],
        ),
        Text(
          expiry,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
