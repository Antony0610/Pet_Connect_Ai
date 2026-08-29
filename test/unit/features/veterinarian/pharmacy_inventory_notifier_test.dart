import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/pharmacy_inventory_notifier.dart';

void main() {
  group('PharmacyInventoryNotifier Unit Tests', () {
    late PharmacyInventoryNotifier notifier;

    setUp(() {
      notifier = PharmacyInventoryNotifier();
    });

    test('Initializes with baseline pharmacy formulary inventory', () {
      expect(notifier.state.isNotEmpty, isTrue);
      final apoquel = notifier.state.firstWhere((i) => i.id == 'inv-001');
      expect(apoquel.isLowStock, isTrue); // 4 units <= 10 min threshold
      expect(apoquel.statusText, equals('Low Stock'));
    });

    test('Adjusts stock level correctly and prevents negative inventory', () {
      final initial = notifier.state.firstWhere((i) => i.id == 'inv-001');
      expect(initial.stockQuantity, equals(4));

      // Dispense 2
      notifier.adjustStock('inv-001', -2);
      var updated = notifier.state.firstWhere((i) => i.id == 'inv-001');
      expect(updated.stockQuantity, equals(2));

      // Dispense 10 (should clamp to 0, not negative)
      notifier.adjustStock('inv-001', -10);
      updated = notifier.state.firstWhere((i) => i.id == 'inv-001');
      expect(updated.stockQuantity, equals(0));
      expect(updated.statusText, equals('Out of Stock'));
    });

    test('Reorders stock batch and updates threshold status to Optimal', () {
      // Reorder 50 units of Apoquel
      notifier.reorderStock('inv-001', 50);
      final updated = notifier.state.firstWhere((i) => i.id == 'inv-001');
      expect(updated.stockQuantity, equals(54));
      expect(updated.isLowStock, isFalse);
      expect(updated.statusText, equals('Optimal'));
    });

    test('Adds new SKU to inventory catalog', () {
      notifier.addItem(
        name: 'Convenia (Cefovecin) 80mg/mL',
        category: 'Pharmacy',
        sku: 'PH-9901',
        initialStock: 15,
        unit: 'vials',
        minThreshold: 5,
        isCritical: false,
        batchNumber: 'LOT-CNV-01',
        expirationDate: DateTime(2027, 6, 1),
      );

      final added = notifier.state.firstWhere((i) => i.sku == 'PH-9901');
      expect(added.name, contains('Convenia'));
      expect(added.stockQuantity, equals(15));
      expect(added.isLowStock, isFalse);
    });
  });
}
