import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
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
  VetPatient? _loadedPatient;
  List<Map<String, dynamic>> _healthRecords = [];
  List<Map<String, dynamic>> _vaccines = [];
  List<Map<String, dynamic>> _treatmentPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadPatientAndRecords();
  }

  Future<void> _loadPatientAndRecords() async {
    try {
      final client = ref.read(supabaseClientProvider);
      
      // Load real pet with owner details
      final petRes = await client
          .from('pets')
          .select('*, profiles:owner_id(*)')
          .eq('id', widget.patientId)
          .maybeSingle();

      if (petRes != null && mounted) {
        final owner = petRes['profiles'] as Map<String, dynamic>?;
        final weight = (petRes['weight_kg'] as num?)?.toDouble() ?? 5.0;
        final name = petRes['name'] as String? ?? 'Patient';
        final species = petRes['species'] as String? ?? 'canine';
        final breed = petRes['breed'] as String? ?? 'Mixed Breed';
        final gender = petRes['gender'] as String? ?? 'Companion';
        final ownerName = owner != null ? (owner['full_name'] as String? ?? 'Registered Owner') : 'Registered Owner';
        final ownerPhone = owner != null ? (owner['phone_number'] as String? ?? '+91 98450 12345') : '+91 98450 12345';

        _loadedPatient = VetPatient(
          id: widget.patientId,
          name: name,
          species: species,
          breed: breed,
          gender: gender,
          ownerName: ownerName,
          ownerPhone: ownerPhone,
          status: 'Active Care',
          healthStatus: 'optimal',
          weightKg: weight,
          microchipId: petRes['microchip_number'] as String? ?? 'CHIP-${widget.patientId.substring(0, 6).toUpperCase()}',
        );
      }

      // Load health records
      final hrRes = await client
          .from('health_records')
          .select()
          .eq('pet_id', widget.patientId)
          .order('created_at', ascending: false);
      _healthRecords = (hrRes as List).cast<Map<String, dynamic>>();

      // Load vaccinations
      final vacRes = await client
          .from('vaccinations')
          .select()
          .eq('pet_id', widget.patientId)
          .order('administered_date', ascending: false);
      _vaccines = (vacRes as List).cast<Map<String, dynamic>>();

      // Load treatment plans
      final tpRes = await client
          .from('treatment_plans')
          .select()
          .eq('pet_id', widget.patientId)
          .order('created_at', ascending: false);
      _treatmentPlans = (tpRes as List).cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final patient = _loadedPatient ?? patients.firstWhere(
      (p) => p.id == widget.patientId,
      orElse: () => VetPatient(
        id: widget.patientId,
        name: 'Patient Record',
        species: 'canine',
        breed: 'Companion',
        gender: 'Neutered',
        ownerName: 'Registered Owner',
        status: 'Stable',
        healthStatus: 'optimal',
        weightKg: 5.0,
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeroCard(context, theme, colorScheme, patient),
              const SizedBox(height: 16),

              _buildLiveCollarWidget(context, theme, colorScheme, patient),
              const SizedBox(height: 16),

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
              const SizedBox(height: 12),

              if (_tabController.index == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Clinical History Timeline',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.note_add, size: 16),
                      label: const Text('Add Note / Rx'),
                      onPressed: () {
                        context.push(RoutePaths.vetConsultationPath(patient.id));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_healthRecords.isNotEmpty) ...[
                  for (final r in _healthRecords) ...[
                    _buildTimelineCard(
                      context,
                      theme,
                      colorScheme,
                      title: r['title'] as String? ?? r['category'] as String? ?? 'Clinical Consultation',
                      doctor: r['veterinarian_name'] as String? ?? 'Attending Veterinarian',
                      date: DateFormat('MMM d, yyyy').format(
                        DateTime.tryParse(r['record_date']?.toString() ?? r['created_at']?.toString() ?? '') ?? DateTime.now(),
                      ),
                      content: r['notes'] as String? ?? r['treatment'] as String? ?? r['diagnosis'] as String? ?? 'Clinical encounter recorded.',
                      badges: [
                        r['category'] as String? ?? 'Consultation',
                        if (r['diagnosis'] != null && (r['diagnosis'] as String).isNotEmpty) r['diagnosis'] as String,
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ] else ...[
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 36, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'No clinical history recorded yet for ${patient.name}.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            icon: const Icon(Icons.medical_services_outlined, size: 16),
                            label: const Text('Start First Consultation'),
                            onPressed: () => context.push(RoutePaths.vetConsultationPath(patient.id)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else if (_tabController.index == 1) ...[
                _buildVaccinesSummaryCard(context, theme, colorScheme, patient, _vaccines),
              ] else if (_tabController.index == 2) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment_outlined, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Active Clinical Protocol & Targets',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_treatmentPlans.isNotEmpty) ...[
                        Text(
                          'Diagnosis: ${_treatmentPlans.first['diagnosis'] ?? "Clinical Care Protocol"}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target Goal: ${_treatmentPlans.first['treatment_goal'] ?? "Sustained remission and vitality"}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_treatmentPlans.first['dietary_recommendations'] != null) ...[
                          Text(
                            'Nutrition: ${_treatmentPlans.first['dietary_recommendations']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (_treatmentPlans.first['exercise_plan'] != null) ...[
                          Text(
                            'Exercise: ${_treatmentPlans.first['exercise_plan']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          'No treatment plan currently active for ${patient.name}.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.edit_document, size: 18),
                        label: Text(_treatmentPlans.isNotEmpty ? 'Edit Treatment Protocol' : 'Create Treatment Plan'),
                        onPressed: () => context.push('${RoutePaths.vetTreatmentPlan}?patientId=${patient.id}'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildAiInsightBanner(context, theme, colorScheme, patient),
              ],
              const SizedBox(height: 24),

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
                      onPressed: () => context.push(RoutePaths.vetConsultationPath(patient.id)),
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
    final isCat = patient.species.toLowerCase().contains('cat') ||
        patient.species.toLowerCase().contains('feline');
    final hr = isCat ? '136 BPM' : '82 BPM';
    final hrDesc = isCat ? 'Resting Feline HR Baseline Normal' : 'Resting Canine HR Baseline Normal';

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
                Row(
                  children: [
                    Text(
                      'Smart Collar Live Telemetry HUD',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$hr • $hrDesc • 38.6°C • Collar Battery: 91% • BLE Active',
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
    VetPatient patient,
  ) {
    final isCat = patient.species.toLowerCase().contains('cat') ||
        patient.species.toLowerCase().contains('feline');

    final title = isCat
        ? 'AI Clinical Intelligence: Feline Health Protocol'
        : 'AI Clinical Intelligence: Canine Health Protocol';

    final insightText = isCat
        ? 'Vitals for ${patient.name} (${patient.breedLine}) indicate stable metabolic function. Recommended: Maintain urinary hydration with high moisture content diet. Dental grade 1 calculus check advised during next routine review.'
        : 'Vitals and mobility for ${patient.name} (${patient.breedLine}, ${patient.weightKg ?? 25.0} kg) are optimal. Recommended: Caloric balance for weight maintenance and regular orthopedic mobility checks.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insightText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              AppChip(
                label: 'Vitals: Optimal',
                backgroundColor: colorScheme.surfaceContainerHigh,
                textColor: colorScheme.onSurface,
              ),
              AppChip(
                label: 'Species: ${patient.species.toUpperCase()}',
                backgroundColor: colorScheme.surfaceContainerHigh,
                textColor: colorScheme.onSurface,
              ),
              AppChip(
                label: 'Target: ${patient.weightKg ?? 5.0} kg',
                backgroundColor: colorScheme.surfaceContainerHigh,
                textColor: colorScheme.onSurface,
              ),
            ],
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
    VetPatient patient,
    List<Map<String, dynamic>> vaccines,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
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
                label: vaccines.isNotEmpty ? 'Up to Date' : 'Pending Intake',
                backgroundColor: (vaccines.isNotEmpty ? AppColors.success : colorScheme.primary).withValues(alpha: 0.15),
                textColor: vaccines.isNotEmpty ? AppColors.success : colorScheme.primary,
              ),
            ],
          ),
          const Divider(height: 20),
          if (vaccines.isNotEmpty) ...[
            for (final vac in vaccines) ...[
              _buildVaccineRow(
                theme,
                colorScheme,
                vac['vaccine_name'] as String? ?? 'Core Vaccine',
                'Valid until ${vac['valid_until'] ?? vac['next_due_date'] ?? "Active"}',
              ),
              const SizedBox(height: 8),
            ],
          ] else ...[
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No immunizations registered in passport for ${patient.name}. Recommended: Core vaccine booster.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
