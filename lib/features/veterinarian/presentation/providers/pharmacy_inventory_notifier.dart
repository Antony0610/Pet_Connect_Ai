import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clinical pharmacy inventory entry with live stock levels and thresholds.
class PharmacyInventoryEntry {
  const PharmacyInventoryEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.stockQuantity,
    required this.unit,
    required this.minThreshold,
    required this.isCritical,
    required this.batchNumber,
    required this.expirationDate,
  });

  final String id;
  final String name;
  final String category;
  final String sku;
  final int stockQuantity;
  final String unit;
  final int minThreshold;
  final bool isCritical;
  final String batchNumber;
  final DateTime expirationDate;

  bool get isLowStock => stockQuantity <= minThreshold;

  String get statusText {
    if (stockQuantity <= 0) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    final daysToExpiry = expirationDate.difference(DateTime.now()).inDays;
    if (daysToExpiry <= 30) return 'Exp. Soon';
    return 'Optimal';
  }

  PharmacyInventoryEntry copyWith({
    String? name,
    String? category,
    String? sku,
    int? stockQuantity,
    String? unit,
    int? minThreshold,
    bool? isCritical,
    String? batchNumber,
    DateTime? expirationDate,
  }) {
    return PharmacyInventoryEntry(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      minThreshold: minThreshold ?? this.minThreshold,
      isCritical: isCritical ?? this.isCritical,
      batchNumber: batchNumber ?? this.batchNumber,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}

/// State notifier managing live pharmacy inventory stock counts, reorders,
/// and low-stock alerts.
class PharmacyInventoryNotifier
    extends StateNotifier<List<PharmacyInventoryEntry>> {
  PharmacyInventoryNotifier() : super(_initialInventory);

  static final List<PharmacyInventoryEntry> _initialInventory = [
    PharmacyInventoryEntry(
      id: 'inv-001',
      name: 'Apoquel 16mg (Oclacitinib)',
      category: 'Pharmacy',
      sku: 'PH-1024',
      stockQuantity: 4,
      unit: 'bottles',
      minThreshold: 10,
      isCritical: true,
      batchNumber: 'LOT-9924-A',
      expirationDate: DateTime.now().add(const Duration(days: 180)),
    ),
    PharmacyInventoryEntry(
      id: 'inv-002',
      name: 'Rabies Core Vaccine (1-Year)',
      category: 'Biologics',
      sku: 'BIO-883',
      stockQuantity: 28,
      unit: 'doses',
      minThreshold: 15,
      isCritical: false,
      batchNumber: 'LOT-5541-R',
      expirationDate: DateTime.now().add(const Duration(days: 25)),
    ),
    PharmacyInventoryEntry(
      id: 'inv-003',
      name: 'Heartgard Plus (Blue - Large)',
      category: 'Preventatives',
      sku: 'PRV-092',
      stockQuantity: 18,
      unit: 'packs',
      minThreshold: 8,
      isCritical: false,
      batchNumber: 'LOT-3382-H',
      expirationDate: DateTime.now().add(const Duration(days: 365)),
    ),
    PharmacyInventoryEntry(
      id: 'inv-004',
      name: 'Carprofen 75mg (Rimadyl)',
      category: 'Pharmacy',
      sku: 'PH-2041',
      stockQuantity: 45,
      unit: 'bottles',
      minThreshold: 12,
      isCritical: false,
      batchNumber: 'LOT-7719-C',
      expirationDate: DateTime.now().add(const Duration(days: 420)),
    ),
    PharmacyInventoryEntry(
      id: 'inv-005',
      name: 'Propofol 10mg/mL Injectable',
      category: 'Surgical',
      sku: 'SURG-014',
      stockQuantity: 6,
      unit: 'vials',
      minThreshold: 10,
      isCritical: true,
      batchNumber: 'LOT-1192-P',
      expirationDate: DateTime.now().add(const Duration(days: 90)),
    ),
    PharmacyInventoryEntry(
      id: 'inv-006',
      name: 'Clavamox Drops 62.5mg/mL',
      category: 'Pharmacy',
      sku: 'PH-3301',
      stockQuantity: 32,
      unit: 'bottles',
      minThreshold: 10,
      isCritical: false,
      batchNumber: 'LOT-8821-X',
      expirationDate: DateTime.now().add(const Duration(days: 280)),
    ),
  ];

  /// Adjusts the stock quantity by a given delta (e.g. -1 for dispensing, +10 for restocking).
  void adjustStock(String itemId, int delta) {
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(
            stockQuantity: (item.stockQuantity + delta).clamp(0, 99999),
          )
        else
          item,
    ];
  }

  /// Dispatches a restock order by adding newly arrived units to existing inventory.
  void reorderStock(String itemId, int addedUnits) {
    adjustStock(itemId, addedUnits);
  }

  /// Adds a new SKU or medical item to the pharmacy inventory.
  void addItem({
    required String name,
    required String category,
    required String sku,
    required int initialStock,
    required String unit,
    required int minThreshold,
    required bool isCritical,
    required String batchNumber,
    required DateTime expirationDate,
  }) {
    final newItem = PharmacyInventoryEntry(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: category,
      sku: sku,
      stockQuantity: initialStock,
      unit: unit,
      minThreshold: minThreshold,
      isCritical: isCritical,
      batchNumber: batchNumber,
      expirationDate: expirationDate,
    );

    state = [newItem, ...state];
  }

  /// Removes an obsolete SKU from the inventory catalog.
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }
}

/// Provider managing the active clinic pharmacy inventory.
final pharmacyInventoryStateProvider = StateNotifierProvider<
    PharmacyInventoryNotifier, List<PharmacyInventoryEntry>>(
  (ref) => PharmacyInventoryNotifier(),
);
