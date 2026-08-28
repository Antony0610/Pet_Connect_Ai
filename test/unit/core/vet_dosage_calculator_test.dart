import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/utils/vet_dosage_calculator.dart';

void main() {
  group('VetDosageCalculator Unit Tests', () {
    test('Calculates accurate Amoxicillin dosage and liquid volume', () {
      final clavamox = VetDosageCalculator.formulary.firstWhere(
        (d) => d.name.contains('Clavamox'),
      );

      // 10 kg dog at default dose 13.75 mg/kg => 137.5 mg
      final result = VetDosageCalculator.calculate(
        drug: clavamox,
        weightKg: 10.0,
        species: 'Canine',
      );

      expect(result.isSafeForSpecies, isTrue);
      expect(result.targetDoseMg, equals(137.5));
      expect(result.liquidVolumeMl, equals(2.2)); // 137.5 / 62.5 = 2.2 mL
      expect(result.warningMessage, isNull);
    });

    test('Identifies and blocks strict feline contraindications for Carprofen', () {
      final rimadyl = VetDosageCalculator.formulary.firstWhere(
        (d) => d.name.contains('Rimadyl'),
      );

      // Attempting to calculate Carprofen for a cat
      final result = VetDosageCalculator.calculate(
        drug: rimadyl,
        weightKg: 4.5,
        species: 'Feline',
      );

      expect(result.isSafeForSpecies, isFalse);
      expect(result.targetDoseMg, equals(0.0));
      expect(result.warningMessage, contains('CONTRAINDICATION'));
      expect(result.warningMessage, contains('Rimadyl'));
    });

    test('Calculates safe Gabapentin dosage for feline patient', () {
      final gabapentin = VetDosageCalculator.formulary.firstWhere(
        (d) => d.name.contains('Gabapentin'),
      );

      // 4.0 kg cat at default dose 10.0 mg/kg => 40.0 mg
      final result = VetDosageCalculator.calculate(
        drug: gabapentin,
        weightKg: 4.0,
        species: 'Feline',
      );

      expect(result.isSafeForSpecies, isTrue);
      expect(result.targetDoseMg, equals(40.0));
      expect(result.liquidVolumeMl, equals(0.8)); // 40.0 / 50.0 = 0.8 mL
    });
  });
}
