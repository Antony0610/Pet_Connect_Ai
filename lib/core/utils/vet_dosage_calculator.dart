/// Clinical definition of a veterinary drug profile.
class VetDrugProfile {
  const VetDrugProfile({
    required this.name,
    required this.category,
    required this.defaultDoseMgPerKg,
    required this.minDoseMgPerKg,
    required this.maxDoseMgPerKg,
    required this.frequency,
    required this.liquidConcentrationMgPerMl,
    required this.commonTabletStrengthsMg,
    required this.canineSafe,
    required this.felineSafe,
    this.clinicalNotes,
  });

  final String name;
  final String category;
  final double defaultDoseMgPerKg;
  final double minDoseMgPerKg;
  final double maxDoseMgPerKg;
  final String frequency; // e.g. 'Every 12 hours (BID)'
  final double? liquidConcentrationMgPerMl;
  final List<double> commonTabletStrengthsMg;
  final bool canineSafe;
  final bool felineSafe;
  final String? clinicalNotes;
}

/// Clinical calculation result with exact dose, volume, and safety warnings.
class VetDosageResult {
  const VetDosageResult({
    required this.drugName,
    required this.weightKg,
    required this.targetDoseMg,
    required this.frequency,
    this.liquidVolumeMl,
    this.recommendedTabletStrengthMg,
    this.tabletsPerDose,
    required this.isSafeForSpecies,
    this.warningMessage,
    this.clinicalInstructions,
  });

  final String drugName;
  final double weightKg;
  final double targetDoseMg;
  final String frequency;
  final double? liquidVolumeMl;
  final double? recommendedTabletStrengthMg;
  final double? tabletsPerDose;
  final bool isSafeForSpecies;
  final String? warningMessage;
  final String? clinicalInstructions;
}

/// High-accuracy Veterinary Pharmacology & Dosing Calculator.
class VetDosageCalculator {
  const VetDosageCalculator._();

  /// Standard formulary of common veterinary drugs.
  static const List<VetDrugProfile> formulary = [
    VetDrugProfile(
      name: 'Amoxicillin / Clavulanate (Clavamox)',
      category: 'Broad-Spectrum Antibiotic',
      defaultDoseMgPerKg: 13.75,
      minDoseMgPerKg: 12.5,
      maxDoseMgPerKg: 25.0,
      frequency: 'Every 12 hours (BID) with meals',
      liquidConcentrationMgPerMl: 62.5,
      commonTabletStrengthsMg: [62.5, 125.0, 250.0, 375.0],
      canineSafe: true,
      felineSafe: true,
      clinicalNotes: 'Indicated for skin pyoderma, respiratory, and urinary tract infections.',
    ),
    VetDrugProfile(
      name: 'Meloxicam (Metacam)',
      category: 'NSAID / Anti-inflammatory',
      defaultDoseMgPerKg: 0.1,
      minDoseMgPerKg: 0.05,
      maxDoseMgPerKg: 0.2,
      frequency: 'Every 24 hours (SID) with food',
      liquidConcentrationMgPerMl: 1.5,
      commonTabletStrengthsMg: [1.0, 2.5],
      canineSafe: true,
      felineSafe: true,
      clinicalNotes: 'Post-op pain & osteoarthritis. In felines: monitor renal values and use minimum effective dose.',
    ),
    VetDrugProfile(
      name: 'Gabapentin',
      category: 'Neuropathic Analgesic & Sedative',
      defaultDoseMgPerKg: 10.0,
      minDoseMgPerKg: 5.0,
      maxDoseMgPerKg: 20.0,
      frequency: 'Every 8 to 12 hours (TID/BID)',
      liquidConcentrationMgPerMl: 50.0,
      commonTabletStrengthsMg: [100.0, 300.0, 400.0],
      canineSafe: true,
      felineSafe: true,
      clinicalNotes: 'Useful for feline vet-visit anxiety (give 2 hours prior) and chronic neuropathic pain.',
    ),
    VetDrugProfile(
      name: 'Carprofen (Rimadyl)',
      category: 'Canine NSAID',
      defaultDoseMgPerKg: 2.2,
      minDoseMgPerKg: 2.0,
      maxDoseMgPerKg: 4.4,
      frequency: 'Every 12 hours (BID) or 4.4 mg/kg SID',
      liquidConcentrationMgPerMl: null,
      commonTabletStrengthsMg: [25.0, 75.0, 100.0],
      canineSafe: true,
      felineSafe: false,
      clinicalNotes: 'CANINE ONLY. Contraindicated in cats due to acute renal and hepatic toxicity.',
    ),
    VetDrugProfile(
      name: 'Metronidazole',
      category: 'Antiprotozoal & Antimicrobial',
      defaultDoseMgPerKg: 12.5,
      minDoseMgPerKg: 10.0,
      maxDoseMgPerKg: 15.0,
      frequency: 'Every 12 hours (BID)',
      liquidConcentrationMgPerMl: 50.0,
      commonTabletStrengthsMg: [250.0, 500.0],
      canineSafe: true,
      felineSafe: true,
      clinicalNotes: 'Acute colitis, Giardia, and anaerobic bacterial overgrowth. Administer with food.',
    ),
  ];

  /// Calculates clinical dosage for a given drug and patient weight.
  static VetDosageResult calculate({
    required VetDrugProfile drug,
    required double weightKg,
    required String species,
    double? customDoseMgPerKg,
  }) {
    final isCat = species.toLowerCase().contains('cat') || species.toLowerCase().contains('feline');
    final isSafe = isCat ? drug.felineSafe : drug.canineSafe;

    if (!isSafe) {
      return VetDosageResult(
        drugName: drug.name,
        weightKg: weightKg,
        targetDoseMg: 0.0,
        frequency: drug.frequency,
        isSafeForSpecies: false,
        warningMessage: '🚨 CONTRAINDICATION: ${drug.name} is strictly contraindicated for $species.',
      );
    }

    final doseRate = customDoseMgPerKg ?? drug.defaultDoseMgPerKg;
    final totalMg = double.parse((weightKg * doseRate).toStringAsFixed(2));

    double? volumeMl;
    if (drug.liquidConcentrationMgPerMl != null && drug.liquidConcentrationMgPerMl! > 0) {
      volumeMl = double.parse((totalMg / drug.liquidConcentrationMgPerMl!).toStringAsFixed(2));
    }

    double? bestStrength;
    double? tabletCount;
    if (drug.commonTabletStrengthsMg.isNotEmpty) {
      // Find closest tablet strength that cleanly satisfies the dose
      double chosenStrength = drug.commonTabletStrengthsMg.first;
      double minDiff = (totalMg - chosenStrength).abs();
      for (final s in drug.commonTabletStrengthsMg) {
        final diff = (totalMg - s).abs();
        if (diff < minDiff) {
          minDiff = diff;
          chosenStrength = s;
        }
      }
      bestStrength = chosenStrength;
      tabletCount = double.parse((totalMg / chosenStrength).toStringAsFixed(1));
    }

    return VetDosageResult(
      drugName: drug.name,
      weightKg: weightKg,
      targetDoseMg: totalMg,
      frequency: drug.frequency,
      liquidVolumeMl: volumeMl,
      recommendedTabletStrengthMg: bestStrength,
      tabletsPerDose: tabletCount,
      isSafeForSpecies: true,
      clinicalInstructions: 'Administer $totalMg mg ${drug.frequency}. ${drug.clinicalNotes ?? ""}',
    );
  }
}
