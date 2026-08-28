import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/vet_dosage_calculator.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';

/// Modal dialog and bottom sheet allowing veterinarians to calculate precise drug dosages,
/// check feline/canine contraindications, and insert instructions into digital prescriptions.
class VetDosageCalculatorModal extends StatefulWidget {
  const VetDosageCalculatorModal({
    super.key,
    this.initialWeightKg = 15.0,
    this.initialSpecies = 'Canine',
    this.onApplyDosage,
  });

  final double initialWeightKg;
  final String initialSpecies;
  final ValueChanged<String>? onApplyDosage;

  static Future<void> show(
    BuildContext context, {
    double initialWeightKg = 15.0,
    String initialSpecies = 'Canine',
    ValueChanged<String>? onApplyDosage,
  }) async {
    await HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: VetDosageCalculatorModal(
          initialWeightKg: initialWeightKg,
          initialSpecies: initialSpecies,
          onApplyDosage: onApplyDosage,
        ),
      ),
    );
  }

  @override
  State<VetDosageCalculatorModal> createState() =>
      _VetDosageCalculatorModalState();
}

class _VetDosageCalculatorModalState extends State<VetDosageCalculatorModal> {
  late double _weightKg;
  late String _species;
  VetDrugProfile _selectedDrug = VetDosageCalculator.formulary.first;

  @override
  void initState() {
    super.initState();
    _weightKg = widget.initialWeightKg;
    _species = widget.initialSpecies;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final result = VetDosageCalculator.calculate(
      drug: _selectedDrug,
      weightKg: _weightKg,
      species: _species,
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.vGapMd,

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: scheme.primary),
                    AppSpacing.hGapSm,
                    Text(
                      'Veterinary Clinical Dosage Calculator',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            AppSpacing.vGapMd,

            // Species Toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Canine', label: Text('🐶 Canine (Dog)')),
                ButtonSegment(value: 'Feline', label: Text('🐱 Feline (Cat)')),
              ],
              selected: {_species},
              onSelectionChanged: (set) {
                HapticFeedback.selectionClick();
                setState(() => _species = set.first);
              },
            ),
            AppSpacing.vGapMd,

            // Weight Input & Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patient Weight',
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    '${_weightKg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _weightKg,
              min: 0.5,
              max: 60.0,
              divisions: 119,
              activeColor: scheme.primary,
              onChanged: (val) {
                setState(() => _weightKg = val);
              },
            ),
            AppSpacing.vGapSm,

            // Drug Selection Dropdown
            Text(
              'Select Formulary Medication',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapXs,
            DropdownButtonFormField<VetDrugProfile>(
              initialValue: _selectedDrug,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: VetDosageCalculator.formulary.map((drug) {
                return DropdownMenuItem(
                  value: drug,
                  child: Text(
                    drug.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
              onChanged: (drug) {
                if (drug != null) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDrug = drug);
                }
              },
            ),
            AppSpacing.vGapLg,

            // Results Card
            if (!result.isSafeForSpecies) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: AppRadius.brCard,
                  border: Border.all(color: scheme.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.error),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        result.warningMessage ?? 'Contraindicated drug for this species.',
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Calculated Dose',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${result.targetDoseMg} mg',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (result.liquidVolumeMl != null)
                      _buildDoseRow(
                        'Oral Liquid Volume (${_selectedDrug.liquidConcentrationMgPerMl} mg/mL):',
                        '${result.liquidVolumeMl} mL',
                        scheme,
                      ),
                    if (result.recommendedTabletStrengthMg != null)
                      _buildDoseRow(
                        'Tablet Protocol (${result.recommendedTabletStrengthMg} mg tabs):',
                        '${result.tabletsPerDose} tabs / dose',
                        scheme,
                      ),
                    _buildDoseRow('Administration Schedule:', result.frequency, scheme),
                    AppSpacing.vGapXs,
                    Text(
                      _selectedDrug.clinicalNotes ?? '',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            AppSpacing.vGapLg,

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    label: 'Copy Protocol',
                    icon: Icons.copy,
                    onPressed: () {
                      final summary = '${result.drugName}: ${result.targetDoseMg} mg (${result.frequency}) for ${_weightKg.toStringAsFixed(1)} kg $_species';
                      Clipboard.setData(ClipboardData(text: summary));
                      context.showSnackbar('✓ Dosage protocol copied to clipboard');
                    },
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: AppButton.filled(
                    label: 'Apply to Rx',
                    icon: Icons.check_circle_outline,
                    onPressed: result.isSafeForSpecies
                        ? () {
                            final instruction = '${result.drugName} ${result.targetDoseMg} mg. Administer ${result.frequency}.';
                            widget.onApplyDosage?.call(instruction);
                            Navigator.of(context).pop();
                            context.showSnackbar('✓ Dosage inserted into prescription');
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseRow(String label, String value, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
