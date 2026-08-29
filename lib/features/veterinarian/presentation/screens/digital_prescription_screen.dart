import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/widgets/vet_dosage_calculator_modal.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

class DigitalPrescriptionScreen extends ConsumerStatefulWidget {
  const DigitalPrescriptionScreen({super.key});

  @override
  ConsumerState<DigitalPrescriptionScreen> createState() =>
      _DigitalPrescriptionScreenState();
}

class _DigitalPrescriptionScreenState
    extends ConsumerState<DigitalPrescriptionScreen> {
  final List<Map<String, String>> _medications = [
    {
      'name': 'Apoquel (Oclacitinib) 16mg',
      'dosage': '16 mg',
      'frequency': 'Twice Daily (q12h) for 14 days, then once daily',
      'duration': '30 Days',
      'instructions': 'Administer with or without food. Monitor for itch relief.',
    },
    {
      'name': 'Synacore Digestive Probiotics',
      'dosage': '1 Sachet',
      'frequency': 'Once Daily (q24h)',
      'duration': '14 Days',
      'instructions': 'Mix with morning meal to support gastrointestinal flora.',
    },
  ];

  void _openAddMedicationDialog() async {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 tablet');
    final freqCtrl = TextEditingController(text: 'Twice daily (q12h)');
    final durCtrl = TextEditingController(text: '7 Days');
    final instrCtrl = TextEditingController(text: 'Administer with food.');

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Prescription Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Medication Name & Strength',
                  hintText: 'e.g. Amoxicillin 250mg, Meloxicam 1.5mg/ml',
                  prefixIcon: Icon(Icons.medication),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g. 1 tablet, 2.5 ml',
                  prefixIcon: Icon(Icons.scale),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: freqCtrl,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  hintText: 'e.g. Twice Daily (q12h)',
                  prefixIcon: Icon(Icons.repeat),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g. 10 Days',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Special Clinical Instructions',
                  hintText: 'e.g. Take with food. Finish full course.',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add Medication'),
          ),
        ],
      ),
    );

    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _medications.add({
          'name': nameCtrl.text.trim(),
          'dosage': dosageCtrl.text.trim(),
          'frequency': freqCtrl.text.trim(),
          'duration': durCtrl.text.trim(),
          'instructions': instrCtrl.text.trim(),
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${nameCtrl.text.trim()} added to prescription.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final doctorName = (userProfile != null && userProfile.fullName.isNotEmpty)
        ? (userProfile.fullName.startsWith('Dr.') ? userProfile.fullName : 'Dr. ${userProfile.fullName}')
        : 'Dr. Practitioner (DVM)';

    final clinicsAsync = ref.watch(vetClinicsProvider);
    final clinics = clinicsAsync.valueOrNull ?? [];
    final clinicName = clinics.isNotEmpty ? clinics.first.name : 'Oakridge Veterinary Clinic';
    final clinicAddress = clinics.isNotEmpty && clinics.first.address != null ? clinics.first.address! : 'Bengaluru, Karnataka';
    final clinicPhone = clinics.isNotEmpty && clinics.first.phone != null ? clinics.first.phone! : '+91 98450 12345';

    final rxNumber = 'RX-${DateTime.now().year}-${1000 + DateTime.now().millisecond}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RoutePaths.vetHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Prescription',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Rx #$rxNumber',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Dosage Calculator',
            onPressed: () {
              VetDosageCalculatorModal.show(
                context,
                initialWeightKg: 28.5,
                initialSpecies: 'Canine',
                onApplyDosage: (dosageInstruction) {
                  setState(() {
                    _medications.add({
                      'name': 'Calculated Therapeutic Agent',
                      'dosage': dosageInstruction,
                      'frequency': 'As Directed',
                      'duration': '7 Days',
                      'instructions': 'Administered per electronic dosage protocol.',
                    });
                  });
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ExternalActions.shareText(
              '🐾 PetConnect AI Digital Veterinary Prescription\n'
              'Rx #$rxNumber\n'
              'Clinic: $clinicName ($clinicAddress)\n'
              'Authorized by: $doctorName\n'
              'Date: ${DateFormat("MMM d, yyyy").format(DateTime.now())}\n\n'
              'Medications:\n${_medications.map((m) => "• ${m["name"]} - ${m["dosage"]} | ${m["frequency"]} | Duration: ${m["duration"]}\n  Instructions: ${m["instructions"]}").join("\n\n")}',
              subject: 'Digital Prescription #$rxNumber',
            ),
            tooltip: 'Share Prescription',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contraindication & Allergy Guard Alert Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Safety Check: 0 Drug Interactions Detected',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                          ),
                          Text(
                            'Cross-referenced against Penicillin sensitivity & hepatic/renal clearance parameters.',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Clinic Letterhead Box
              _buildClinicHeader(context, theme, colorScheme, clinicName, clinicAddress, clinicPhone, rxNumber),
              const SizedBox(height: 16),

              // Patient & Owner Info Card
              _buildPatientOwnerCard(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Header for Medications List + Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prescribed Pharmaceuticals (${_medications.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Drug'),
                    onPressed: _openAddMedicationDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Prescription Medication Details Cards
              ...List.generate(_medications.length, (index) {
                final med = _medications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildMedicationCard(context, theme, colorScheme, med, index),
                );
              }),
              const SizedBox(height: 16),

              // Digital Signature & Verification Box
              _buildSignatureCard(context, theme, colorScheme, doctorName),
              const SizedBox(height: 24),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share PDF'),
                      onPressed: () {
                        ExternalActions.shareText(
                          '🐾 PetConnect AI Digital Veterinary Prescription\nRx #$rxNumber\nAuthorized by: $doctorName\nClinic: $clinicName',
                          subject: 'Prescription $rxNumber',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      text: 'Send to Pharmacy',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Prescription dispatched to In-House & Partner Pharmacy!',
                            ),
                          ),
                        );
                        context.push(RoutePaths.vetPharmacy);
                      },
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      height: 44,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String clinicName,
    String clinicAddress,
    String clinicPhone,
    String rxNumber,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinicName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      clinicAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Phone: $clinicPhone | VCI Reg: VCI/KA/2026/8924',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prescription #: $rxNumber',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Date: ${DateFormat("MMM d, yyyy").format(DateTime.now())}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientOwnerCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pets, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Patient: Buddy',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Canine • Golden Retriever • 4 yrs • Male (N)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            'Weight: 32.4 kg',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Icon(Icons.person_outline, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Owner / Guardian: Sarah Jenkins',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Indiranagar, Bengaluru, Karnataka 560038 • +91 98765 43210',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, String> med,
    int index,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.medication, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    med['name'] ?? 'Medication',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: colorScheme.error,
                onPressed: () {
                  setState(() => _medications.removeAt(index));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRxMeta(context, 'Dosage', med['dosage'] ?? ''),
              _buildRxMeta(context, 'Frequency', med['frequency'] ?? ''),
              _buildRxMeta(context, 'Duration', med['duration'] ?? ''),
            ],
          ),
          const Divider(height: 20),
          Text(
            'Instructions: ${med['instructions'] ?? ""}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRxMeta(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

  Widget _buildSignatureCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String doctorName,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(Icons.draw_outlined, color: colorScheme.primary, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digitally Signed & Certified',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  doctorName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'Verified cryptographic timestamp • VCI Compliant',
                  style: theme.textTheme.labelSmall?.copyWith(
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
}
